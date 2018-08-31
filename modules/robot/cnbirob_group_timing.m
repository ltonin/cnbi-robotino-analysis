clearvars;  close all;

sublist = {'ai6', 'ai7', 'ai8', 'aj1', 'aj3', 'aj4', 'aj7', 'aj8', 'aj9', 'b4', 'e8', 'ac7', 'ah7'};

datapattern     = '_robot_timing.mat';
datapath        = 'analysis/robot/timing/';
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

Rk  = []; Ik  = []; Dk  = []; Ck  = []; Sk  = []; Xk = []; Yk =[];
timing = [];
cnumruns = 0;
for sId = 1:NumSubjects
    csubject  = sublist{sId};
    cfilename_data   = [datapath csubject datapattern]; 
    cfilename_label  = [labelpath csubject labelpattern]; 
    cfilename_record = [recordpath csubject recordpattern]; 
    util_bdisp(['[io] - Importing timing data for subject: ' csubject]); 
    
    % Timing
    cdata   = load(cfilename_data);
    timing = cat(1, timing, cdata.timing);
    
    % Record
    crecord = load(cfilename_record);
    Xk  = cat(1, Xk,  crecord.reached);
    
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
ValidityCond = Vk & Xk; 

Runs = unique(Rk);
NumRuns = length(Runs);
Integrators = unique(Ik);
NumIntegrators = length(Integrators);
Subjects = unique(Sk);
Targets = unique(Ck);
NumTargets = length(Targets);
RunInt = unique(Yk);
NumRunInt = length(RunInt);


%% Average Time per Run (per Target)
rTiming = [];
rIk = []; rDk = []; rSk = []; rYk = []; rCk = [];
for rId = 1:NumRuns
    for cId = 1:NumTargets
        cindex = Rk == Runs(rId) & Ck == Targets(cId); % & ValidityCond;
        rTiming = cat(1, rTiming, nanmean(timing(cindex)));
        rIk = cat(1, rIk, unique(Ik(cindex)));
        rDk = cat(1, rDk, unique(Dk(cindex)));
        rSk = cat(1, rSk, unique(Sk(cindex)));
        rYk = cat(1, rYk, unique(Yk(cindex)));
        rCk = cat(1, rCk, unique(Ck(cindex)));
    end
end

%% Average RunTiming per integrator
util_bdisp('[proc] - Computing average time per integrator');
AvgIntRunTime = nan(NumIntegrators, 1);
StdIntRunTime = nan(NumIntegrators, 1);
SteIntRunTime = nan(NumIntegrators, 1);
for iId = 1:NumIntegrators   
    cindex = rIk == Integrators(iId);
    AvgIntRunTime(iId) = nanmean(rTiming(cindex));
    StdIntRunTime(iId) = nanstd(rTiming(cindex));
    SteIntRunTime(iId) = nanstd(rTiming(cindex))./sqrt(sum(cindex));
end

%% Average RunTiming per subject 
util_bdisp('[proc] - Computing average time per integrator and per subject');
AvgSubRunTime = nan(NumSubjects, NumIntegrators);
StdSubRunTime = nan(NumSubjects, NumIntegrators);
SteSubRunTime = nan(NumSubjects, NumIntegrators);

for iId = 1:NumIntegrators
    for sId = 1:NumSubjects       
        cindex = rIk == Integrators(iId) & rSk == Subjects(sId);
        AvgSubRunTime(sId, iId) = nanmean(rTiming(cindex));
        StdSubRunTime(sId, iId) = nanstd(rTiming(cindex));
        SteSubRunTime(sId, iId) = nanstd(rTiming(cindex))./sqrt(sum(cindex));
    end
end

%% Average Evolution RunTiming 
util_bdisp('[proc] - Computing average evolution time per integrator');
AvgEvoRunTime = nan(NumRunInt, NumIntegrators);
StdEvoRunTime = nan(NumRunInt, NumIntegrators);
SteEvoRunTime = nan(NumRunInt, NumIntegrators);

for iId = 1:NumIntegrators
    for rId = 1:NumRunInt
        cindex = rIk == Integrators(iId) & rYk == RunInt(rId);
        AvgEvoRunTime(rId, iId) = nanmean(rTiming(cindex));
        StdEvoRunTime(rId, iId) = nanstd(rTiming(cindex));
        SteEvoRunTime(rId, iId) = nanstd(rTiming(cindex))./sqrt(sum(cindex));
    end
end

%% Average TargetTime per Subject
AvgTargetTime = nan(NumTargets, NumIntegrators);
MedTargetTime = nan(NumTargets, NumIntegrators);
StdTargetTime = nan(NumTargets, NumIntegrators);
SteTargetTime = nan(NumTargets, NumIntegrators);

for cId = 1:NumTargets
   for iId = 1:NumIntegrators
        cindex = rCk == Targets(cId) & rIk == Integrators(iId);
        AvgTargetTime(cId, iId) = nanmean(rTiming(cindex));
        MedTargetTime(cId, iId) = nanmedian(rTiming(cindex));
        StdTargetTime(cId, iId) = nanstd(rTiming(cindex));
        SteTargetTime(cId, iId) = nanstd(rTiming(cindex))./sqrt(sum(cindex));
   end
end

%% TRIAL BASED RESULTS
% %% Average RunTiming per integrator
% util_bdisp('[proc] - Computing average time per integrator');
% AvgIntRunTime = zeros(NumIntegrators, 1);
% StdIntRunTime = zeros(NumIntegrators, 1);
% SteIntRunTime = zeros(NumIntegrators, 1);
% for iId = 1:NumIntegrators   
%     cindex = Ik == Integrators(iId) & ValidityCond;
%     AvgIntRunTime(iId) = nanmean(timing(cindex));
%     StdIntRunTime(iId) = nanstd(timing(cindex));
%     SteIntRunTime(iId) = nanstd(timing(cindex))./sqrt(sum(cindex));
% end
% 
% %% Average RunTiming per subject 
% util_bdisp('[proc] - Computing average time per integrator and per subject');
% AvgSubRunTime = zeros(NumSubjects, NumIntegrators);
% StdSubRunTime = zeros(NumSubjects, NumIntegrators);
% SteSubRunTime = zeros(NumSubjects, NumIntegrators);
% 
% for iId = 1:NumIntegrators
%     for sId = 1:NumSubjects       
%         cindex = Ik == Integrators(iId) & Sk == Subjects(sId) & ValidityCond;
%         AvgSubRunTime(sId, iId) = nanmean(timing(cindex));
%         StdSubRunTime(sId, iId) = nanstd(timing(cindex));
%         SteSubRunTime(sId, iId) = nanstd(timing(cindex))./sqrt(sum(cindex));
%     end
% end
% 
% %% Average Evolution RunTiming 
% util_bdisp('[proc] - Computing average evolution time per integrator');
% AvgEvoRunTime = zeros(NumRunInt, NumIntegrators);
% StdEvoRunTime = zeros(NumRunInt, NumIntegrators);
% SteEvoRunTime = zeros(NumRunInt, NumIntegrators);
% 
% for iId = 1:NumIntegrators
%     for rId = 1:NumRunInt
%         cindex = Ik == Integrators(iId) & Yk == RunInt(rId) & ValidityCond;
%         AvgEvoRunTime(rId, iId) = nanmean(timing(cindex));
%         StdEvoRunTime(rId, iId) = nanstd(timing(cindex));
%         SteEvoRunTime(rId, iId) = nanstd(timing(cindex))./sqrt(sum(cindex));
%     end
% end
% 
% %% Average TargetTime per Subject
% AvgTargetTime = zeros(NumTargets, NumIntegrators);
% MedTargetTime = zeros(NumTargets, NumIntegrators);
% StdTargetTime = zeros(NumTargets, NumIntegrators);
% SteTargetTime = zeros(NumTargets, NumIntegrators);
% 
% for cId = 1:NumTargets
%    for iId = 1:NumIntegrators
%         cindex = Ck == Targets(cId) & Ik == Integrators(iId) & ValidityCond;
%         AvgTargetTime(cId, iId) = nanmean(timing(cindex));
%         MedTargetTime(cId, iId) = nanmedian(timing(cindex));
%         StdTargetTime(cId, iId) = nanstd(timing(cindex));
%         SteTargetTime(cId, iId) = nanstd(timing(cindex))./sqrt(sum(cindex));
%    end
% end

% %% Statistical tests
% % Statistical test per integrator
% util_bdisp('[stat] - Statistical per integrator:');
% PValIntRun = ranksum(timing(Ik == 1 & ValidityCond), timing(Ik == 2 & ValidityCond));
% disp(['       - Significance between control modalities: p=' num2str(PValIntRun, 3)]);
% 
% % Statistical tests evolution over run
% util_bdisp('[stat] - Statistical per run:');
% PValEvoRun = zeros(NumRunInt, 1);
% for rId = 1:NumRunInt
%     cindex = Yk == RunInt(rId) & ValidityCond;
%     PValEvoRun(rId) = ranksum(timing(cindex & Ik == 1), timing(cindex & Ik == 2));
%     disp(['       - Significance between control modalities run ' num2str(rId) ' : p=' num2str(PValEvoRun(rId), 3)])
% end
% 
% % Statistical tests per target
% util_bdisp('[stat] - Statistical per Target:');
% PValTarg = zeros(NumTargets, 1);
% for cId = 1:NumTargets
%     cindex = Ck == Targets(cId) & ValidityCond;
%     PValTarg(cId) = ranksum(timing(cindex & Ik == 1), timing(cindex & Ik == 2));
%     disp(['       - Significance between control modalities (Target ' num2str(cId) ') : p=' num2str(PValTarg(cId), 3)])
% end
% 
% % Statistical tests per subject 
% util_bdisp('[stat] - Statistical per subject:');
% PValSubj = zeros(NumSubjects, 1);
% for sId = 1:NumSubjects
%     cindex = Sk == Subjects(sId) & ValidityCond;
%     PValSubj(sId) = ranksum(timing(cindex & Ik == 1), timing(cindex & Ik == 2));
%     disp(['       - Significance between control modalities (Subject ' sublist{sId} ') : p=' num2str(PValSubj(sId), 3)])
% end
%% Statistical tests
% Statistical test per integrator
util_bdisp('[stat] - Statistical per integrator:');
PValIntRun = ranksum(rTiming(rIk == 1), rTiming(rIk == 2));
disp(['       - Significance between control modalities: p=' num2str(PValIntRun, 3)]);

% Statistical tests evolution over run
util_bdisp('[stat] - Statistical per run:');
PValEvoRun = zeros(NumRunInt, 1);
for rId = 1:NumRunInt
    cindex = rYk == RunInt(rId);
    PValEvoRun(rId) = ranksum(rTiming(cindex & rIk == 1), rTiming(cindex & rIk == 2));
    disp(['       - Significance between control modalities run ' num2str(rId) ' : p=' num2str(PValEvoRun(rId), 3)])
end

% Statistical tests per target
util_bdisp('[stat] - Statistical per Target:');
PValTarg = zeros(NumTargets, 1);
for cId = 1:NumTargets
    cindex = rCk == Targets(cId);
    PValTarg(cId) = ranksum(rTiming(cindex & rIk == 1), rTiming(cindex & rIk == 2));
    disp(['       - Significance between control modalities (Target ' num2str(cId) ') : p=' num2str(PValTarg(cId), 3)])
end


% Statistical tests per subject 
util_bdisp('[stat] - Statistical per subject:');
PValSubj = zeros(NumSubjects, 1);
for sId = 1:NumSubjects
    cindex = rSk == Subjects(sId);
    PValSubj(sId) = ranksum(rTiming(cindex & rIk == 1), rTiming(cindex & rIk == 2));
    disp(['       - Significance between control modalities (Subject ' sublist{sId} ') : p=' num2str(PValSubj(sId), 3)])
end

%% Figure - RunTiming
util_bdisp('[fig] - Plotting figure');
fig1 = figure;
fig_set_position(fig1, 'All');

% Average timining per subject
NumRows = 3;
NumCols = 4;
ColorBar = [0 0.4470 0.7410; 0.8500 0.3250 0.0980];

subplot(NumRows, NumCols, [1 2 3]);
superbar(AvgSubRunTime, 'E', SteSubRunTime, 'BarFaceColor', reshape(ColorBar, [1 size(ColorBar)]), 'BarEdgeColor', [.4 .4 .4], 'BarLineWidth', .1, 'ErrorbarStyle', 'T', 'ErrorbarLineWidth', .1);
grid on;
ylim([0 80]);
set(gca, 'XTick', 1:NumSubjects);
set(gca, 'XTickLabel', sublist);
xlabel('Subject');
ylabel('[s]');
title('Average time per subject (+/- SEM)');

% Average timing per integrator
subplot(NumRows, NumCols, 4);
superbar(AvgIntRunTime, 'E',  SteIntRunTime, 'ErrorbarStyle', 'T', 'BarWidth', 0.3, 'BarFaceColor', ColorBar, 'BarEdgeColor', [.4 .4 .4], 'BarLineWidth', .1, 'ErrorbarLineWidth', .1, 'P', [NaN PValIntRun; PValIntRun NaN])
grid on;
ylim([0 50]);
xlim([0.5 2.5]);
set(gca, 'XTick', 1:NumIntegrators);
set(gca, 'XTickLabel', IntegratorName);
xlabel('Control');
ylabel('[s]');
title('Average time per control (+/- SEM)');

% Average evolution timing per run
subplot(NumRows, NumCols, NumCols + [1 2]);
errorbar(AvgEvoRunTime, SteEvoRunTime);
xlim([0.5 5.5]);
ylim([0 50]);
grid on;
set(gca, 'XTick', 1:NumRunInt);
ylabel('[%]');
xlabel('Run');
title('Average time per run (+/- SEM)');

% Average per target
subplot(NumRows, NumCols, NumCols + [3 4]);
ctick = [0 pi/4 pi/2 3*pi/4 pi];
polarplot(ctick', flipud(MedTargetTime), '-o');
set(gca, 'ThetaLim', [0 180])
set(gca, 'ThetaTick', [0 45 90 135 180])
set(gca, 'ThetaTickLabel', {'Target 5', 'Target 4', 'Target 3', 'Target 2', 'Target 1'})
title('Median time per target');
ax = gca;
ax.RAxis.Label.String = '[s]';

% Distribution per target
subplot(NumRows, NumCols, 2*NumCols + [1 2]);
condition = ValidityCond;
boxplot(timing(condition), {Ck(condition) Ik(condition)}, 'factorseparator', 1, 'labels', num2cell(Ik(condition)), 'labelverbosity', 'minor', 'labels', IntegratorName(Ik(condition)));
grid on;
ylabel('[s]');
xlabel('Target')
title('Distribution time per target');
ylim([10 80]);


%% Saving figure
figfilename1 = [figdir '/group_timing.pdf'];
util_bdisp(['[fig] - Saving figure in: ' figfilename1]);
fig_figure2pdf(fig1, figfilename1) 