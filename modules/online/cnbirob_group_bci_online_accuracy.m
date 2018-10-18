clearvars; clc; close all;

sublist = {'ai6', 'ai7', 'ai8', 'aj1', 'aj3', 'aj4', 'aj7', 'aj8', 'aj9',  'e8', 'ah7', 'ac7', 'b4'};

pattern = '_bci_online.mat';
path    = 'analysis/bci/';

figdir   = 'figure/';

NumSubjects = length(sublist);

result = [];
Ck = []; Rk = []; Ik = []; Dk = []; Sk = []; Yk = [];
cnumruns = 0;
cintruns = [0 0];
for sId = 1:NumSubjects
    
    csubject  = sublist{sId};
    cfilename = [path csubject pattern]; 
    util_bdisp(['[io] - Importing bci online data for subject: ' csubject]); 
    
    % BCI online data
    cdata = load(cfilename);
    result   = cat(1, result, cdata.result);
    
    % BCI online labels
    Ck = cat(1, Ck, cdata.labels.Ck);
    Rk = cat(1, Rk, cdata.labels.Rk + cnumruns);
    Yk = cat(1, Yk, cdata.labels.Yk);
    Ik = cat(1, Ik, cdata.labels.Ik);
    Dk = cat(1, Dk, cdata.labels.Dk);
    Sk = cat(1, Sk, sId*ones(length(cdata.labels.Ck), 1));
    
    cnumruns = max(Rk);
end

%% Compute accuracy per run
Runs = unique(Rk);
NumRuns = length(Runs);

Integrators = unique(Ik);
NumIntegrators = length(Integrators);

Accuracy = nan(NumRuns, 1);
rSk = nan(NumRuns, 1);
rIk = nan(NumRuns, 1);
rDk = nan(NumRuns, 1);
rYk = nan(NumRuns, 1);
for rId = 1:NumRuns
    cindex = Rk == Runs(rId);
    Accuracy(rId) = sum(result(cindex))./sum(cindex);
    
    rSk(rId) = unique(Sk(cindex));
    rIk(rId) = unique(Ik(cindex));
    rDk(rId) = unique(Dk(cindex));
    rYk(rId) = unique(Yk(cindex));
end

%% Average accuracy per subject
AccuracySubAvg = nan(NumSubjects, NumIntegrators);
AccuracySubMed = nan(NumSubjects, NumIntegrators);
AccuracySubStd = nan(NumSubjects, NumIntegrators);
AccuracySubSte = nan(NumSubjects, NumIntegrators);

for sId = 1:NumSubjects
    for iId = 1:NumIntegrators
        cindex = rSk == sId & rIk == Integrators(iId);
        AccuracySubAvg(sId, iId) = nanmean(Accuracy(cindex));
        AccuracySubMed(sId, iId) = nanmedian(Accuracy(cindex));
        AccuracySubStd(sId, iId) = nanstd(Accuracy(cindex));
        AccuracySubSte(sId, iId) = nanstd(Accuracy(cindex))./sqrt(sum(cindex));
    end
end

%% Evolution of accuracy
NumIntRun = max(rYk);
AccuracyEvoAvg = nan(NumIntRun, NumIntegrators);
AccuracyEvoMed = nan(NumIntRun, NumIntegrators);
AccuracyEvoStd = nan(NumIntRun, NumIntegrators);
AccuracyEvoSte = nan(NumIntRun, NumIntegrators);
for rId = 1:NumIntRun
    for iId = 1:NumIntegrators
        cindex = rYk == rId & rIk == Integrators(iId);
        AccuracyEvoAvg(rId, iId) = nanmean(Accuracy(cindex));
        AccuracyEvoMed(rId, iId) = nanmedian(Accuracy(cindex));
        AccuracyEvoStd(rId, iId) = nanstd(Accuracy(cindex));
        AccuracyEvoSte(rId, iId) = nanstd(Accuracy(cindex))./sqrt(sum(cindex));
    end
end

%% Statistical tests

util_bdisp('[stat] - Statical tests on overall accuracy');
AccPVal = ranksum(Accuracy(rIk == 1), Accuracy(rIk == 2));
disp(['       - Overall accuracy significance: p<' num2str(AccPVal, 3)]);

util_bdisp('[stat] - Statical tests on accuracy evolution');
AccEvoPVal = nan(NumIntRun, 1);
for rId = 1:NumIntRun
    cindex = rYk == rId;
    AccEvoPVal(rId) = ranksum(Accuracy(cindex & rIk == 1), Accuracy(cindex & rIk == 2)); 
    disp(['       - Run ' num2str(rId) ' significance: p<' num2str(AccEvoPVal(rId), 3)]); 
end

%% Figure
fig1 = figure;
fig_set_position(fig1, 'Top');

NumRows = 1;
NumCols = 3;
color = [0 0 0; 0 0.4470 0.7410; 0.8500 0.3250 0.0980];

% Overall accuracy
subplot(NumRows, NumCols, 1);
cavg = [mean(Accuracy); mean(Accuracy(rIk == 1)); mean(Accuracy(rIk == 2))];
cstd = [std(Accuracy)./sqrt(length(Accuracy)); std(Accuracy(rIk == 1))./sqrt(sum(rIk == 1)); std(Accuracy(rIk == 2))./sqrt(sum(rIk == 2))];
superbar(100*cavg, 'E',  100*cstd, 'ErrorbarStyle', 'T', 'BarWidth', 0.3, 'BarFaceColor', color, 'BarEdgeColor', [.4 .4 .4], 'BarLineWidth', .1, 'ErrorbarLineWidth', .1, 'P', [NaN NaN NaN; NaN NaN AccPVal; NaN AccPVal NaN], 'PLineWidth', 0.5)
xlim([0.5 3.5]);
ylim([0 120]);
set(gca, 'XTick', 1:3);
set(gca, 'XTickLabel', {'overall', 'discrete', 'continuous'});
xlabel('Modality');
ylabel('[%]');
title('Average accuracy (+/- SEM)');
grid on;

% Accuracy Evolution
% Average evolution accuracy per run
subplot(NumRows, NumCols, [2 3]);
errorbar(100*AccuracyEvoAvg, 100*AccuracyEvoSte, 'o-');
xlim([0.5 NumIntRun + 0.5]);
ylim([0 110]);
grid on;
set(gca, 'XTick', 1:NumIntRun);
ylabel('[%]');
xlabel('Run');
title('Average accuracy per run (+/- SEM)');
legend('discrete', 'continuous', 'location', 'best');

suptitle('BCI online accuracy');

%% Saving figure
figfilename = [figdir '/group_bci_online_accuracy.pdf'];
util_bdisp(['[fig] - Saving figure in: ' figfilename]);
fig_figure2pdf(fig1, figfilename) 


