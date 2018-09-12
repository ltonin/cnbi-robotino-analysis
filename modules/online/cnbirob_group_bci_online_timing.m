clearvars; clc; close all;

sublist = {'ai6', 'ai7', 'ai8', 'aj1', 'aj3', 'aj4', 'aj7', 'aj8', 'aj9',  'e8', 'ah7', 'ac7', 'b4'};

pattern = '_bci_online.mat';
path    = 'analysis/bci/';

figdir   = 'figure/';

NumSubjects = length(sublist);
SampleRate = 16;
duration = [];
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
    duration = cat(1, duration, cdata.duration);
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

%% Compute Duration per run
Runs = unique(Rk);
NumRuns = length(Runs);

Integrators = unique(Ik);
NumIntegrators = length(Integrators);

Duration = nan(NumRuns, 1);
rSk = nan(NumRuns, 1);
rIk = nan(NumRuns, 1);
rDk = nan(NumRuns, 1);
rYk = nan(NumRuns, 1);
for rId = 1:NumRuns
    cindex = Rk == Runs(rId) & result == true;
    Duration(rId) = mean(duration(cindex)./SampleRate);
    
    rSk(rId) = unique(Sk(cindex));
    rIk(rId) = unique(Ik(cindex));
    rDk(rId) = unique(Dk(cindex));
    rYk(rId) = unique(Yk(cindex));
end

%% Average duration per subject
DurationSubAvg = nan(NumSubjects, NumIntegrators);
DurationSubMed = nan(NumSubjects, NumIntegrators);
DurationSubStd = nan(NumSubjects, NumIntegrators);
DurationSubSte = nan(NumSubjects, NumIntegrators);

for sId = 1:NumSubjects
    for iId = 1:NumIntegrators
        cindex = rSk == sId & rIk == Integrators(iId);
        DurationSubAvg(sId, iId) = nanmean(Duration(cindex));
        DurationSubMed(sId, iId) = nanmedian(Duration(cindex));
        DurationSubStd(sId, iId) = nanstd(Duration(cindex));
        DurationSubSte(sId, iId) = nanstd(Duration(cindex))./sqrt(sum(cindex));
    end
end

%% Evolution of duration
NumIntRun = max(rYk);
DurationEvoAvg = nan(NumIntRun, NumIntegrators);
DurationEvoMed = nan(NumIntRun, NumIntegrators);
DurationEvoStd = nan(NumIntRun, NumIntegrators);
DurationEvoSte = nan(NumIntRun, NumIntegrators);
for rId = 1:NumIntRun
    for iId = 1:NumIntegrators
        cindex = rYk == rId & rIk == Integrators(iId);
        DurationEvoAvg(rId, iId) = nanmean(Duration(cindex));
        DurationEvoMed(rId, iId) = nanmedian(Duration(cindex));
        DurationEvoStd(rId, iId) = nanstd(Duration(cindex));
        DurationEvoSte(rId, iId) = nanstd(Duration(cindex))./sqrt(sum(cindex));
    end
end

%% Statistical tests

util_bdisp('[stat] - Statical tests on overall duration');
DurPVal = ranksum(Duration(rIk == 1), Duration(rIk == 2));
disp(['       - Overall duration significance: p<' num2str(DurPVal, 3)]);

util_bdisp('[stat] - Statical tests on duration evolution');
DurEvoPVal = nan(NumIntRun, 1);
for rId = 1:NumIntRun
    cindex = rYk == rId;
    DurEvoPVal(rId) = ranksum(Duration(cindex & rIk == 1), Duration(cindex & rIk == 2)); 
    disp(['       - Run ' num2str(rId) ' significance: p<' num2str(DurEvoPVal(rId), 3)]); 
end

%% Figure
fig1 = figure;
fig_set_position(fig1, 'Top');

NumRows = 1;
NumCols = 3;
color = [0 0.4470 0.7410; 0.8500 0.3250 0.0980];

% Overall duration
subplot(NumRows, NumCols, 1);
cavg = [mean(Duration(rIk == 1)); mean(Duration(rIk == 2))];
cstd = [std(Duration(rIk == 1))./sqrt(sum(rIk == 1)); std(Duration(rIk == 2))./sqrt(sum(rIk == 2))];
superbar(cavg, 'E', cstd, 'ErrorbarStyle', 'T', 'BarWidth', 0.3, 'BarFaceColor', color, 'BarEdgeColor', [.4 .4 .4], 'BarLineWidth', .1, 'ErrorbarLineWidth', .1, 'P', [NaN DurPVal; DurPVal NaN], 'PLineWidth', 0.5)
xlim([0.5 2.5]);
ylim([0 7]);
set(gca, 'XTick', 1:2);
set(gca, 'XTickLabel', {'discrete', 'continuous'});
xlabel('Modality');
ylabel('[s]');
title('Average duration (+/- SEM)');
grid on;

% Duration Evolution
subplot(NumRows, NumCols, [2 3]);
errorbar(DurationEvoAvg, DurationEvoSte, 'o-');
xlim([0.5 NumIntRun + 0.5]);
ylim([0 7]);
grid on;
set(gca, 'XTick', 1:NumIntRun);
ylabel('[s]');
xlabel('Run');
title('Average duration per run (+/- SEM)');
legend('discrete', 'continuous', 'location', 'best');

suptitle('BCI online duration');

%% Saving figure
figfilename = [figdir '/group_bci_online_timing.pdf'];
util_bdisp(['[fig] - Saving figure in: ' figfilename]);
fig_figure2pdf(fig1, figfilename) 


