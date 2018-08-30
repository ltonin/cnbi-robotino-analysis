clearvars; clc; close all;

sublist = {'ai6', 'ai7', 'ai8', 'aj1', 'aj3', 'aj4', 'aj7', 'aj8', 'aj9',  'e8', 'ah7', 'ac7', 'b4'};

pattern         = '_robot_records.mat';
datapath        = 'analysis/robot/';
figdir   = 'figure/';

IntegratorName  = {'discrete', 'continuous'};
TargetName      = {'Target1', 'Target2', 'Target3', 'Target4', 'Target5'};
NumSubjects = length(sublist);

% Create figure directory
util_mkdir('./', figdir);

Rk  = []; Ik  = []; Dk  = []; Tk  = []; Ck  = []; Sk  = []; Xk = []; Vk = [];
rIk = []; rDk = []; rSk = []; rRk = [];
cnumtrials = 0;
cnumruns = 0;

for sId = 1:NumSubjects
    csubject  = sublist{sId};
    cfilename = [datapath csubject pattern]; 
    util_bdisp(['[io] - Importing records data for subject: ' csubject]); 
    
    cdata = load(cfilename);
    cvalid = load([datapath csubject '_robot_valid.mat']);
    
    % Labels
    Rk  = cat(1, Rk,  cdata.records.trial.Rk + cnumruns);
    
    Ik  = cat(1, Ik,  cdata.records.trial.Ik);
    Dk  = cat(1, Dk,  cdata.records.trial.Dk);
    Ck  = cat(1, Ck,  cdata.records.trial.Ck);
    Xk  = cat(1, Xk,  cdata.records.trial.Xk);
    Vk  = cat(1, Vk,  cvalid.Vk);
    Sk  = cat(1, Sk,  sId*ones(length(cdata.records.trial.Rk), 1));
    Tk  = cat(1, Tk,  cdata.records.trial.Tk + cnumtrials);
    cnumtrials = max(Tk);
    cnumruns = max(Rk);
    
    rRk = cat(1, rRk, cdata.records.run.Rk');
    rIk = cat(2, rIk, cdata.records.run.Ik);
    rDk = cat(2, rDk, cdata.records.run.Dk);
    rSk = cat(2, rSk, sId*ones(1, length(cdata.records.run.Ik)));
end

Runs = unique(Rk);
NumRuns = length(Runs);
Integrators = unique(Ik);
NumIntegrators = length(Integrators);
Subjects = unique(Sk);
Targets = unique(Ck);
NumTargets = length(Targets);

%% Accuracy per run
rAccuracy = zeros(NumRuns, 1);
for rId = 1:NumRuns
    
    cindex = Rk == Runs(rId) & Vk == 1;
    rAccuracy(rId) = sum(Xk(cindex))./sum(cindex);  
end

%% Accuracy over run
yRk = rRk;
for sId = 1:NumSubjects
    for iId = 1:NumIntegrators
        cindex = rSk == sId & rIk == Integrators(iId);
        %crunids = rRk(cindex);
        yRk(cindex) = 1:sum(cindex); 
    end
end

AvgAccuracyRun = nan(5, 2);
StdAccuracyRun = nan(5, 2);
SteAccuracyRun = nan(5, 2);
for iId = 1:NumIntegrators
    for rId = 1:5
        cindex = rIk == iId & yRk' == rId;
        AvgAccuracyRun(rId, iId) = mean(rAccuracy(cindex));
        StdAccuracyRun(rId, iId) = std(rAccuracy(cindex));
        SteAccuracyRun(rId, iId) = std(rAccuracy(cindex))./sqrt(sum(cindex));
    end
end
%% Accuracy per target per run
tAccuracy = zeros(NumTargets, NumRuns);
for rId = 1:NumRuns
    for tId = 1:NumTargets
        cindex = Rk == Runs(rId) & Ck == Targets(tId)  & Vk == 1;
        tAccuracy(tId, rId) = sum(Xk(cindex))./sum(cindex);
    end
end



%% Computing accuracy per subject and integrator
SubAvgAccuracy = zeros(NumSubjects, NumIntegrators);
SubStdAccuracy = zeros(NumSubjects, NumIntegrators);
SubSteAccuracy = zeros(NumSubjects, NumIntegrators);
for sId = 1:NumSubjects
    for iId = 1:NumIntegrators
        cindex = rIk == Integrators(iId) & rSk == Subjects(sId);
        SubAvgAccuracy(sId, iId) = nanmean(rAccuracy(cindex));
        SubStdAccuracy(sId, iId) = nanstd(rAccuracy(cindex));
        SubSteAccuracy(sId, iId) = nanstd(rAccuracy(cindex))./sqrt(sum(cindex));
    end
end

%% Computing accuracy per target per subject per integrator
tsiAccuracy = [];
xCk = []; xSk = []; xIk = [];
for tgId = 1:NumTargets
    for sId = 1:NumSubjects
        for iId = 1:NumIntegrators
           cindex = Sk == sId & Ik == iId & Ck == Targets(tgId)  & Vk == 1;
           tsiAccuracy = cat(1, tsiAccuracy, sum(Xk(cindex))./sum(cindex));
           xCk = cat(1, xCk, tgId);
           xSk = cat(1, xSk, sId);
           xIk = cat(1, xIk, iId);
        end
    end
end

%% Statistical tests
util_bdisp('[stat] - Statical tests on accuracy per subject');
SubPVal = zeros(NumSubjects, 1);
for sId = 1:NumSubjects
        cindex = rSk == Subjects(sId);
        SubPVal(sId) = ranksum(rAccuracy(cindex & rIk == 1), rAccuracy(cindex & rIk == 2));
        disp(['       - Subject ' sublist{sId} ' significance: p<' num2str(SubPVal(sId), 3)]); 
end

util_bdisp('[stat] - Overall accuracy between control conditions:');
PVal = ranksum(rAccuracy(rIk == 1), rAccuracy(rIk == 2));
disp(['       - Overall accuracy significance: p<' num2str(PVal, 3)]);

util_bdisp('[stat] - Statical tests on accuracy over run');
for rId = 1:5
    cindex = yRk' == rId;
    cpval = ranksum(rAccuracy(cindex & rIk == 1), rAccuracy(cindex & rIk == 2));
    disp(['       - Run ' num2str(rId) ' significance: p<' num2str(cpval, 3)]); 
end

util_bdisp('[stat] - Statical tests on accuracy over target:');
PValTarget = zeros(NumTargets, 1);
for cId = 1:NumTargets
    cindex = xCk == Targets(cId);
    PValTarget(cId) = ranksum(tsiAccuracy(cindex & xIk == 1), tsiAccuracy(cindex & xIk == 2), 'tail', 'left');
    disp(['       - Target ' num2str(cId) ' significance: p<' num2str(PValTarget(cId), 3)]); 
end

%% Plot

% Fig1 - Accuracy per subject and average accuracy
fig1 = figure;
fig_set_position(fig1, 'All');

color = [0 0.4470 0.7410; 0.8500 0.3250 0.0980];
subplot(2, 4, [1 2 3]);
%plot_barerrors(100*SubAvgAccuracy, 100*SubSteAccuracy);
%barwitherr(100*SubSteAccuracy, 100*SubAvgAccuracy);
superbar(100*SubAvgAccuracy, 'E', 100*SubSteAccuracy, 'BarFaceColor', reshape(color, [1 size(color)]), 'BarEdgeColor', [.4 .4 .4], 'BarLineWidth', .1, 'ErrorbarStyle', 'T', 'ErrorbarLineWidth', .1);
grid on;
ylim([0 110]);
plot_hline(100/NumTargets, 'k--');
set(gca, 'XTick', 1:NumSubjects);
set(gca, 'XTickLabel', sublist);
xlabel('Subject');
ylabel('[%]');
title('Average target accuracy per subject (+/- SEM)');
    
subplot(2, 4, 4);
cavg = [mean(rAccuracy(rIk == 1)); mean(rAccuracy(rIk == 2))];
cstd = [std(rAccuracy(rIk == 1))./sqrt(sum(rIk == 1)); std(rAccuracy(rIk == 2))./sqrt(sum(rIk == 2))];
%errorbar(100*cavg, 100*cstd, 'o-');
superbar(100*cavg, 'E',  100*cstd, 'ErrorbarStyle', 'T', 'BarWidth', 0.3, 'BarFaceColor', color, 'BarEdgeColor', [.4 .4 .4], 'BarLineWidth', .1, 'ErrorbarLineWidth', .1, 'P', [NaN PVal; PVal NaN], 'PLineWidth', 0.5)
xlim([0.5 2.5]);
plot_hline(100/NumTargets, 'k--');
set(gca, 'XTick', 1:2);
set(gca, 'XTickLabel', {'discrete', 'continuous'});

% ylim([50 100]);

xlabel('Modality');
ylabel('[%]');
title('Average target accuracy (+/- SEM)');
grid on;

subplot(2, 4, [5 6]);
errorbar(100*AvgAccuracyRun, 100*SteAccuracyRun, 'o-');
xlim([0.5 5.5]);
ylim([0 110]);
grid on;
set(gca, 'XTick', 1:5);
ylabel('[%]');
xlabel('Run');
title('Average accuracy per run (+/- SEM)');

subplot(2, 4, [7 8]);
cavg = zeros(2, NumTargets);
for tgId = 1:NumTargets 
    cindex = Ck == Targets(tgId);
    %cavg(:, tgId) = [sum(Xk(cindex & Ik == 1))./sum(cindex & Ik == 1) sum(Xk(cindex & Ik == 2))./sum(cindex & Ik == 2)]; 
    cavg(:, tgId) = [mean(tsiAccuracy(xCk == tgId & xIk == 1)) mean(tsiAccuracy(xCk == tgId & xIk == 2))]; 
end
ctick = [0 pi/4 pi/2 3*pi/4 pi];
polarplot(ctick', fliplr(cavg)', '-o');
set(gca, 'ThetaLim', [0 180])
set(gca, 'RTickLabel', {'0%'; '20%'; '40%'; '60%'; '80%'; '100%'})
set(gca, 'ThetaTick', [0 45 90 135 180])
set(gca, 'ThetaTickLabel', {'Target 5', 'Target 4', 'Target 3', 'Target 2', 'Target 1'})
title('Average accuracy per target')

%% Saving figure
figfilename = [figdir '/group_accuracy.pdf'];
util_bdisp(['[fig] - Saving figure in: ' figfilename]);
fig_figure2pdf(fig1, figfilename) 

