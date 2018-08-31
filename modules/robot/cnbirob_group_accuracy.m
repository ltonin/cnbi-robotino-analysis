clearvars; clc; close all;

sublist = {'ai6', 'ai7', 'ai8', 'aj1', 'aj3', 'aj4', 'aj7', 'aj8', 'aj9',  'e8', 'ah7', 'ac7', 'b4'};

datapattern     = '_robot_timing.mat';
timepath        = 'analysis/robot/timing/';
labelpattern    = '_robot_label.mat';
labelpath       = 'analysis/robot/label/'; 
recordpattern   = '_robot_record.mat';
recordpath      = 'analysis/robot/record/'; 

figdir   = 'figure/';

Timeout = 60;

IntegratorName  = {'discrete', 'continuous'};
TargetName      = {'Target1', 'Target2', 'Target3', 'Target4', 'Target5'};
NumSubjects = length(sublist);

% Create figure directory
util_mkdir('./', figdir);

timing = [];
Rk  = []; Ik  = []; Dk  = []; Tk  = []; Ck  = []; Sk  = []; Xk = []; Yk = [];

cnumtrials = 0;
cnumruns = 0;

for sId = 1:NumSubjects
    csubject  = sublist{sId};
    cfilename_time   = [timepath csubject datapattern]; 
    cfilename_label  = [labelpath csubject labelpattern]; 
    cfilename_record = [recordpath csubject recordpattern]; 
    util_bdisp(['[io] - Importing records data for subject: ' csubject]); 
    
    % Reached
    creached   = load(cfilename_record);
    Xk = cat(1, Xk, creached.reached);
    
    % Timing
    ctime   = load(cfilename_time);
    timing = cat(1, timing, ctime.timing);
    
    % Labels
    clabel  = load(cfilename_label);
    Rk  = cat(1, Rk,  clabel.labels.trial.Rk + cnumruns);
    Ik  = cat(1, Ik,  clabel.labels.trial.Ik);
    Dk  = cat(1, Dk,  clabel.labels.trial.Dk);
    Ck  = cat(1, Ck,  clabel.labels.trial.Ck);
    Sk  = cat(1, Sk,  sId*ones(length(clabel.labels.trial.Rk), 1));
    Yk  = cat(1, Yk,  clabel.labels.trial.Yk);
    cnumruns = max(Rk);
    
end

Vk = timing < Timeout;
ValidityCond = Vk; 

Runs = unique(Rk);
NumRuns = length(Runs);
RunPerInt = unique(Yk);
NumRunPerInt = length(RunPerInt);
Integrators = unique(Ik);
NumIntegrators = length(Integrators);
Subjects = unique(Sk);
Targets = unique(Ck);
NumTargets = length(Targets);


%% Accuracy per run (and labels)
rIk = nan(NumRuns, 1);
rDk = nan(NumRuns, 1);
rSk = nan(NumRuns, 1);
rYk = nan(NumRuns, 1);
Accuracy = nan(NumRuns, 1);
for rId = 1:NumRuns
    cindex = Rk == Runs(rId);
    Accuracy(rId) = sum(Xk(cindex & ValidityCond))./sum(cindex);
    
    rIk(rId) = unique(Ik(cindex));
    rDk(rId) = unique(Dk(cindex));
    rSk(rId) = unique(Sk(cindex));
    rYk(rId) = unique(Yk(cindex));
end



%% Mean/Median and std/ste per subject
AccuracySubAvg = nan(NumSubjects, NumIntegrators);
AccuracySubMed = nan(NumSubjects, NumIntegrators);
AccuracySubStd = nan(NumSubjects, NumIntegrators);
AccuracySubSte = nan(NumSubjects, NumIntegrators);

for sId = 1:NumSubjects
    for iId = 1:NumIntegrators
        cindex = rIk == Integrators(iId) & rSk == Subjects(sId);
        AccuracySubAvg(sId, iId) = mean(Accuracy(cindex));
        AccuracySubMed(sId, iId) = median(Accuracy(cindex));
        AccuracySubStd(sId, iId) = std(Accuracy(cindex));
        AccuracySubSte(sId, iId) = std(Accuracy(cindex))./sqrt(sum(cindex));
    end
end

%% Evolution mean/med and std/ste
AccuracyEvoAvg = nan(NumRunPerInt, NumIntegrators);
AccuracyEvoMed = nan(NumRunPerInt, NumIntegrators);
AccuracyEvoStd = nan(NumRunPerInt, NumIntegrators);
AccuracyEvoSte = nan(NumRunPerInt, NumIntegrators);

for yId = 1:NumRunPerInt
    for iId = 1:NumIntegrators
        cindex = rYk == RunPerInt(yId) & rIk == Integrators(iId);
        AccuracyEvoAvg(yId, iId) = mean(Accuracy(cindex));
        AccuracyEvoMed(yId, iId) = median(Accuracy(cindex));
        AccuracyEvoStd(yId, iId) = std(Accuracy(cindex));
        AccuracyEvoSte(yId, iId) = std(Accuracy(cindex))./sqrt(sum(cindex));
    end
end

%% Accuracy per target (per subject)
tAccuracy = [];
tCk = []; tSk = []; tIk = [];
for cId = 1:NumTargets
    for sId = 1:NumSubjects
        for iId = 1:NumIntegrators
            cindex = Ck == Targets(cId) & Sk == Subjects(sId) & Ik == Integrators(iId);
            tAccuracy = cat(1, tAccuracy, sum(Xk(cindex & ValidityCond))./sum(cindex));

            tCk = cat(1, tCk, unique(Ck(cindex)));
            tSk = cat(1, tSk, unique(Sk(cindex)));
            tIk = cat(1, tIk, unique(Ik(cindex)));
        end
    end
end

%% Statistical tests
util_bdisp('[stat] - Statical tests on accuracy per subject');
SubPVal = zeros(NumSubjects, 1);
for sId = 1:NumSubjects
        cindex = rSk == Subjects(sId);
        SubPVal(sId) = ranksum(Accuracy(cindex & rIk == 1), Accuracy(cindex & rIk == 2));
        disp(['       - Subject ' sublist{sId} ' significance: p<' num2str(SubPVal(sId), 3)]); 
end

util_bdisp('[stat] - Overall accuracy between control conditions:');
PVal = ranksum(Accuracy(rIk == 1), Accuracy(rIk == 2));
disp(['       - Overall accuracy significance: p<' num2str(PVal, 3)]);

util_bdisp('[stat] - Statical tests on accuracy over run');
for rId = 1:NumRunPerInt
    cindex = rYk == RunPerInt(rId);
    cpval = ranksum(Accuracy(cindex & rIk == 1), Accuracy(cindex & rIk == 2));
    disp(['       - Run ' num2str(rId) ' significance: p<' num2str(cpval, 3)]); 
end


util_bdisp('[stat] - Statical tests on accuracy over target:');
PValTarget = zeros(NumTargets, 1);
for cId = 1:NumTargets
    cindex = tCk == Targets(cId);
    PValTarget(cId) = ranksum(tAccuracy(cindex & tIk == 1), tAccuracy(cindex & tIk == 2), 'tail', 'left');
    disp(['       - Target ' num2str(cId) ' significance: p<' num2str(PValTarget(cId), 3)]); 
end


%% Plot

% Fig1 - Accuracy per subject and average accuracy
fig1 = figure;
fig_set_position(fig1, 'All');

NumRows = 3;
NumCols = 4;
color = [0 0.4470 0.7410; 0.8500 0.3250 0.0980];

% Average accuracy per subject
subplot(NumRows, NumCols, [1 2 3]);
superbar(100*AccuracySubAvg, 'E', 100*AccuracySubSte, 'BarFaceColor', reshape(color, [1 size(color)]), 'BarEdgeColor', [.4 .4 .4], 'BarLineWidth', .1, 'ErrorbarStyle', 'T', 'ErrorbarLineWidth', .1);
grid on;
ylim([0 110]);
plot_hline(100/NumTargets, 'k--');
set(gca, 'XTick', 1:NumSubjects);
set(gca, 'XTickLabel', sublist);
xlabel('Subject');
ylabel('[%]');
title('Average target accuracy per subject (+/- SEM)');

% Average accuracy per integrator
subplot(NumRows, NumCols, 4);
cavg = [mean(Accuracy(rIk == 1)); mean(Accuracy(rIk == 2))];
cstd = [std(Accuracy(rIk == 1))./sqrt(sum(rIk == 1)); std(Accuracy(rIk == 2))./sqrt(sum(rIk == 2))];
superbar(100*cavg, 'E',  100*cstd, 'ErrorbarStyle', 'T', 'BarWidth', 0.3, 'BarFaceColor', color, 'BarEdgeColor', [.4 .4 .4], 'BarLineWidth', .1, 'ErrorbarLineWidth', .1, 'P', [NaN PVal; PVal NaN], 'PLineWidth', 0.5, 'PStarThreshold', 0.06)
xlim([0.5 2.5]);
ylim([0 110]);
plot_hline(100/NumTargets, 'k--');
set(gca, 'XTick', 1:2);
set(gca, 'XTickLabel', {'discrete', 'continuous'});
xlabel('Modality');
ylabel('[%]');
title('Average target accuracy (+/- SEM)');
grid on;

% Average evolution accuracy per run
subplot(NumRows, NumCols, NumCols + [1 2]);
errorbar(100*AccuracyEvoAvg, 100*AccuracyEvoStd, 'o-');
xlim([0.5 5.5]);
ylim([0 110]);
grid on;
set(gca, 'XTick', 1:NumRunPerInt);
ylabel('[%]');
xlabel('Run');
title('Average accuracy per run (+/- SEM)');

% Average per target
subplot(NumRows, NumCols, NumCols + [3 4]);
cavg = zeros(2, NumTargets);
for tgId = 1:NumTargets 
    cindex = tCk == Targets(tgId);
    cavg(:, tgId) = [mean(tAccuracy(cindex & tIk == 1)) mean(tAccuracy(cindex & tIk == 2))]; 
end
ctick = [0 pi/4 pi/2 3*pi/4 pi];
polarplot(ctick', fliplr(cavg)', '-o');
set(gca, 'ThetaLim', [0 180])
set(gca, 'RTickLabel', {'0%'; '20%'; '40%'; '60%'; '80%'; '100%'})
set(gca, 'ThetaTick', [0 45 90 135 180])
set(gca, 'ThetaTickLabel', {'Target 5', 'Target 4', 'Target 3', 'Target 2', 'Target 1'})
title('Average accuracy per target')

% Distribution per target
subplot(NumRows, NumCols, 2*NumCols + [1 2]);
boxplot(100*tAccuracy, {tCk tIk}, 'factorseparator', 1, 'labels', num2cell(tIk), 'labelverbosity', 'minor', 'labels', IntegratorName(tIk));
grid on;
ylabel('[%]');
xlabel('Target')
title('Distribution accuracy per target');
ylim([0 110]);

%% Saving figure
figfilename = [figdir '/group_accuracy.pdf'];
util_bdisp(['[fig] - Saving figure in: ' figfilename]);
fig_figure2pdf(fig1, figfilename) 

