clearvars; clc; close all;

sublist = {'ai6', 'ai7', 'ai8', 'aj1', 'aj3', 'aj4', 'aj7', 'aj8', 'aj9'};

pattern  = '_robot_timing.mat';
datapath = 'analysis/robot/';
figdir   = 'figure/';

IntegratorName  = {'discrete', 'continuous'};
TargetName      = {'Target1', 'Target2', 'Target3', 'Target4', 'Target5'};
NumSubjects = length(sublist);

% Create figure directory
util_mkdir('./', figdir);

Rk  = []; Ik  = []; Dk  = []; Ck  = []; Sk  = []; Xk = []; Yk =[];
timing = [];
cnumruns = 0;
for sId = 1:NumSubjects
    csubject  = sublist{sId};
    cfilename = [datapath csubject pattern]; 
    util_bdisp(['[io] - Importing timing data for subject: ' csubject]); 
    
    cdata = load(cfilename);
    
    % Labels
    Rk  = cat(1, Rk,  cdata.labels.Rk + cnumruns);
    
    Ik  = cat(1, Ik,  cdata.labels.Ik);
    Dk  = cat(1, Dk,  cdata.labels.Dk);
    Ck  = cat(1, Ck,  cdata.labels.Ck);
    Xk  = cat(1, Xk,  cdata.labels.Xk);
    Sk  = cat(1, Sk,  sId*ones(length(cdata.labels.Rk), 1));
    Yk  = cat(1, Yk,  cdata.labels.Yk);
    cnumruns = max(Rk);
    
    timing = cat(1, timing, cdata.timing);
end

Runs = unique(Rk);
NumRuns = length(Runs);
Integrators = unique(Ik);
NumIntegrators = length(Integrators);
Subjects = unique(Sk);
Targets = unique(Ck);
NumTargets = length(Targets);
RunInt = unique(Yk);
NumRunInt = length(RunInt);

%% Computing labels per run
util_bdisp('[proc] - Computing labels per run');
rIk = [];
rSk = [];
rYk = [];
rDk = [];
for rId = 1:NumRuns
    cindex = Rk == Runs(rId);
    rIk = cat(1, rIk, unique(Ik(Rk==rId)));
    rSk = cat(1, rSk, unique(Sk(Rk==rId)));
    rYk = cat(1, rYk, unique(Yk(Rk==rId)));
end

%% Average RunTiming
util_bdisp('[proc] - Computing average time per run (averaging targets)');
AvgRunTime = zeros(NumRuns, 1);
for rId = 1:NumRuns
   cindex = Rk == Runs(rId) & Xk == 1;
   AvgRunTime(rId) = nanmean(timing(cindex));
end

%% Average RunTiming per integrator
util_bdisp('[proc] - Computing average time per integrator');
AvgIntRunTime = zeros(NumIntegrators, 1);
StdIntRunTime = zeros(NumIntegrators, 1);
SteIntRunTime = zeros(NumIntegrators, 1);
for iId = 1:NumIntegrators   
    cindex = rIk == Integrators(iId);
    AvgIntRunTime(iId) = nanmean(AvgRunTime(cindex));
    StdIntRunTime(iId) = nanstd(AvgRunTime(cindex));
    SteIntRunTime(iId) = nanstd(AvgRunTime(cindex))./sqrt(sum(cindex));
end

%% Average RunTiming per subject 
util_bdisp('[proc] - Computing average time per integrator and per subject');
AvgSubRunTime = zeros(NumSubjects, NumIntegrators);
StdSubRunTime = zeros(NumSubjects, NumIntegrators);
SteSubRunTime = zeros(NumSubjects, NumIntegrators);

for iId = 1:NumIntegrators
    for sId = 1:NumSubjects
        cindex = rIk == Integrators(iId) & rSk == Subjects(sId);
        AvgSubRunTime(sId, iId) = nanmean(AvgRunTime(cindex));
        StdSubRunTime(sId, iId) = nanstd(AvgRunTime(cindex));
        SteSubRunTime(sId, iId) = nanstd(AvgRunTime(cindex))./sqrt(sum(cindex));
    end
end

%% Average Evolution RunTiming 
util_bdisp('[proc] - Computing average evolution time per integrator');
AvgEvoRunTime = zeros(NumRunInt, NumIntegrators);
StdEvoRunTime = zeros(NumRunInt, NumIntegrators);
SteEvoRunTime = zeros(NumRunInt, NumIntegrators);

for iId = 1:NumIntegrators
    for rId = 1:NumRunInt
        cindex = rIk == Integrators(iId) & rYk == RunInt(rId);
        AvgEvoRunTime(rId, iId) = nanmean(AvgRunTime(cindex));
        StdEvoRunTime(rId, iId) = nanstd(AvgRunTime(cindex));
        SteEvoRunTime(rId, iId) = nanstd(AvgRunTime(cindex))./sqrt(sum(cindex));
    end
end

%% Average TargetTime per Subject

AvgTargetTime = zeros(NumTargets, NumIntegrators);
MedTargetTime = zeros(NumTargets, NumIntegrators);
StdTargetTime = zeros(NumTargets, NumIntegrators);
SteTargetTime = zeros(NumTargets, NumIntegrators);

for cId = 1:NumTargets
   for iId = 1:NumIntegrators
        cindex = Ck == Targets(cId) & Xk == 1 & Ik == Integrators(iId);
        AvgTargetTime(cId, iId) = nanmean(timing(cindex));
        MedTargetTime(cId, iId) = nanmedian(timing(cindex));
        StdTargetTime(cId, iId) = nanstd(timing(cindex));
        SteTargetTime(cId, iId) = nanstd(timing(cindex))./sqrt(sum(cindex));
   end
end


%% Statistical tests

% Statistical test per integrator
util_bdisp('[stat] - Statistical per integrator:');
PValIntRun = ranksum(AvgRunTime(rIk == 1), AvgRunTime(rIk == 2));
disp(['       - Significance between control modalities: p=' num2str(PValIntRun, 3)])

% Statistical tests evolution over run
util_bdisp('[stat] - Statistical per run:');
PValEvoRun = zeros(NumRunInt);
for rId = 1:NumRunInt
    cindex = rYk == RunInt(rId);
    PValEvoRun(rId) = ranksum(AvgRunTime(cindex & rIk == 1), AvgRunTime(cindex & rIk == 2));
    disp(['       - Significance between control modalities run ' num2str(rId) ' : p=' num2str(PValEvoRun(rId), 3)])
end

% Statistical tests per target
for cId = 1:NumTargets
    cindex = Ck == Targets(cId) & Xk == 1;
    ranksum(timing(cindex & Ik == 1), timing(cindex & Ik == 2))
end


%% Figure - RunTiming
util_bdisp('[fig] - Plotting figure');
fig1 = figure;
fig_set_position(fig1, 'All');

% Average timining per subject
NumRows = 2;
NumCols = 3;
ColorBar = [0 0.4470 0.7410; 0.8500 0.3250 0.0980];

subplot(NumRows, NumCols, [1 2 3]);
superbar(AvgSubRunTime, 'E', SteSubRunTime, 'BarFaceColor', reshape(ColorBar, [1 size(ColorBar)]), 'BarEdgeColor', [.4 .4 .4], 'BarLineWidth', .1, 'ErrorbarStyle', 'T', 'ErrorbarLineWidth', .1);
grid on;
ylim([0 80]);
set(gca, 'XTick', 1:NumSubjects);
set(gca, 'XTickLabel', sublist);
xlabel('Subject');
ylabel('[s]');
title('Average run time per subject (+/- SEM)');

% Average timing per integrator
subplot(NumRows, NumCols, NumCols+1);
superbar(AvgIntRunTime, 'E',  SteIntRunTime, 'ErrorbarStyle', 'T', 'BarWidth', 0.3, 'BarFaceColor', ColorBar, 'BarEdgeColor', [.4 .4 .4], 'BarLineWidth', .1, 'ErrorbarLineWidth', .1, 'P', [NaN PValIntRun; PValIntRun NaN])
grid on;
ylim([0 50]);
xlim([0.5 2.5]);
set(gca, 'XTick', 1:NumIntegrators);
set(gca, 'XTickLabel', IntegratorName);
xlabel('Control');
ylabel('[s]');
title('Average run time per control (+/- SEM)');

% Average evolution timing per run
subplot(NumRows, NumCols, NumCols + [2 3]);
errorbar(AvgEvoRunTime, SteEvoRunTime);
xlim([0.5 5.5]);
ylim([0 50]);
grid on;
set(gca, 'XTick', 1:NumRunInt);
ylabel('[%]');
xlabel('Run');
title('Average time per run (+/- SEM)');

fig2 = figure;
fig_set_position(fig2, 'Top');

subplot(1, 3, [1 2]);
boxplot(timing(Xk==1), {Ck(Xk==1) Ik(Xk==1)}, 'factorseparator', 1, 'labels', num2cell(Ik(Xk==1)), 'labelverbosity', 'minor', 'labels', IntegratorName(Ik(Xk==1)));
grid on;
ylabel('[s]');
xlabel('Target')
title('Distribution time per target');
ylim([10 80]);

subplot(1, 3, 3);
ctick = [0 pi/4 pi/2 3*pi/4 pi];
polarplot(ctick', flipud(MedTargetTime), '-o');
set(gca, 'ThetaLim', [0 180])
set(gca, 'RTickLabel', {'0s'; '10s'; '20s'; '30s'})
set(gca, 'ThetaTick', [0 45 90 135 180])
set(gca, 'ThetaTickLabel', {'Target 5', 'Target 4', 'Target 3', 'Target 2', 'Target 1'})
title('Median time per target')

%% Saving figure
figfilename1 = [figdir '/group_timining_run.pdf'];
util_bdisp(['[fig] - Saving figure in: ' figfilename1]);
fig_figure2pdf(fig1, figfilename1) 

figfilename2 = [figdir '/group_timining_target.pdf'];
util_bdisp(['[fig] - Saving figure in: ' figfilename2]);
fig_figure2pdf(fig2, figfilename2) 