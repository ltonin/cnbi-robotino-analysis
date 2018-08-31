clearvars; clc; close all;

sublist = {'ai6', 'ai7', 'ai8', 'aj1', 'aj3', 'aj4', 'aj7', 'aj8', 'aj9', 'b4', 'ac7', 'ah7', 'e8'};

trajpattern     = '_robot_trajectory.mat';
frechetpattern  = '_robot_frechet.mat';
timepattern     = '_robot_timing.mat';
labelpattern    = '_robot_label.mat';
recordpattern   = '_robot_record.mat';
trajpath        = 'analysis/robot/trajectory/';
frechetpath     = 'analysis/robot/frechet/';
timepath        = 'analysis/robot/timing/';
labelpath       = 'analysis/robot/label/'; 
recordpath      = 'analysis/robot/record/'; 
manualpattern   = '00_robot_trajectory.mat';

figdir   = 'figure/';

% Create figure directory
util_mkdir('./', figdir);

IntegratorName  = {'discrete', 'continuous'};
TargetName      = {'Target1', 'Target2', 'Target3', 'Target4', 'Target5'};
FieldSize       = [900 600];    % [cm]
MapResolution   = 10;            % [cm]
TargetPos(1, :) = [150 150];
TargetPos(2, :) = [238 362];
TargetPos(3, :) = [450 450];
TargetPos(4, :) = [662 362];
TargetPos(5, :) = [750 150];
TargetRadius    = 25;           % [cm]

DoPlot = false;

Timeout = 60;
mTargetPos    = ceil(TargetPos/MapResolution);
mTargetRadius = ceil(TargetRadius/MapResolution);
mFieldSize    = ceil(FieldSize/MapResolution);

NumSubjects = length(sublist);

trajectory = [];
frechet    = [];
timing     = [];
Rk  = []; Ik  = []; Dk  = []; Ck  = []; Sk  = []; Xk = []; Yk =[]; Tk = [];
sTk = [];
cnumruns   = 0;
cnumtrials = 0;

for sId = 1:NumSubjects
    csubject  = sublist{sId};
    cfilename_traj    = [trajpath csubject trajpattern]; 
    cfilename_frechet = [frechetpath csubject frechetpattern]; 
    cfilename_time    = [timepath csubject timepattern]; 
    cfilename_label   = [labelpath csubject labelpattern]; 
    cfilename_record  = [recordpath csubject recordpattern]; 
    util_bdisp(['[io] - Importing  data for subject: ' csubject]); 
    
    % Trajectory
    cdata_traj = load(cfilename_traj);
    trajectory = cat(1, trajectory, cdata_traj.trajectory);
    
    % Frechet
    cdata_frechet = load(cfilename_frechet);
    frechet = cat(1, frechet, cdata_frechet.frechet);
    
    % Timing
    cdata_time = load(cfilename_time);
    timing = cat(1, timing, cdata_time.timing);
    
    % Record
    cdata_record = load(cfilename_record);
    Xk  = cat(1, Xk,  cdata_record.reached);

    % Labels 
    clabel  = load(cfilename_label);
    
    Rk  = cat(1, Rk,  clabel.labels.trial.Rk + cnumruns);
    Ik  = cat(1, Ik,  clabel.labels.trial.Ik);
    Dk  = cat(1, Dk,  clabel.labels.trial.Dk);
    Ck  = cat(1, Ck,  clabel.labels.trial.Ck);
    Sk  = cat(1, Sk,  sId*ones(length(clabel.labels.trial.Rk), 1));
    Yk  = cat(1, Yk,  clabel.labels.trial.Yk);
    Tk  = cat(1, Tk,  clabel.labels.trial.Tk + cnumtrials);
    
    sTk = cat(1, sTk, clabel.labels.sample.Tk + cnumtrials);
    cnumruns = max(Rk);
    cnumtrials = max(Tk);
end

Vk = timing < Timeout;
ValidityCond = Vk & Xk; 

Runs = unique(Rk);
NumRuns = length(Runs);
Integrators    = unique(Ik);
NumIntegrators = length(Integrators);
NumTrials      = length(Tk);
Targets        = unique(Ck);
NumTargets     = length(Targets);
Days           = unique(Dk);
NumDays        = length(Days);
Subjects       = unique(Sk);
NumSubjects    = length(Subjects);
RunPerInt      = unique(Yk);
NumRunPerInt   = length(RunPerInt);

%% Loading manual trajectories
util_bdisp('[proc] - Loading manual trajectory data');
manual = load([trajpath manualpattern]); 
mtrajectory = manual.trajectory;
mCk = manual.labels.raw.sample.Ck;

%% Create hit-map from trajectories
util_bdisp('[proc] - Create hit-map from trajectories');
HitMap = zeros([mFieldSize NumTrials]);

for trId = 1:NumTrials
    cindex = sTk == trId; 
    HitMap(:, :, trId) = cnbirob_traj2map(trajectory(cindex, :), FieldSize, MapResolution);
end

%% Create resampled trajectories
util_bdisp('[proc] - Create resampled trajectories');
MaxLength = 0;
for trId = 1:NumTrials
    MaxLength = max(MaxLength, sum(sTk == trId));
end

rtrajectory = nan(MaxLength, 2, NumTrials);
for trId = 1:NumTrials
    cindex = sTk == trId;
    clength = sum(cindex);
    cpath = trajectory(cindex, :);
    rtrajectory(:, :, trId) =  interp1(1:clength, cpath, linspace(1, clength, MaxLength));
end

%% Average Frechet per Run (per Target)
rFrechet = [];
rIk = []; rDk = []; rSk = []; rYk = []; rCk = [];
for rId = 1:NumRuns
    for cId = 1:NumTargets
        cindex = Rk == Runs(rId) & Ck == Targets(cId); % & ValidityCond;
        rFrechet = cat(1, rFrechet, nanmean(frechet(cindex)));
        rIk = cat(1, rIk, unique(Ik(cindex)));
        rDk = cat(1, rDk, unique(Dk(cindex)));
        rSk = cat(1, rSk, unique(Sk(cindex)));
        rYk = cat(1, rYk, unique(Yk(cindex)));
        rCk = cat(1, rCk, unique(Ck(cindex)));
    end
end



%% Average Frechet per integrator
util_bdisp('[proc] - Computing average frechet per integrator');
FrechetIntAvg = nan(NumIntegrators, 1);
FrechetIntMed = nan(NumIntegrators, 1);
FrechetIntStd = nan(NumIntegrators, 1);
FrechetIntSte = nan(NumIntegrators, 1);
for iId = 1:NumIntegrators   
    cindex = rIk == Integrators(iId);
    FrechetIntAvg(iId) = nanmean(rFrechet(cindex));
    FrechetIntMed(iId) = nanmedian(rFrechet(cindex));
    FrechetIntStd(iId) = nanstd(rFrechet(cindex));
    FrechetIntSte(iId) = nanstd(rFrechet(cindex))./sqrt(sum(cindex));
end

%% Average Frechet per subject 
util_bdisp('[proc] - Computing average frechet per integrator and per subject');
FrechetSubAvg = nan(NumSubjects, NumIntegrators);
FrechetSubMed = nan(NumSubjects, NumIntegrators);
FrechetSubStd = nan(NumSubjects, NumIntegrators);
FrechetSubSte = nan(NumSubjects, NumIntegrators);

for iId = 1:NumIntegrators
    for sId = 1:NumSubjects       
        cindex = rIk == Integrators(iId) & rSk == Subjects(sId);
        FrechetSubAvg(sId, iId) = nanmean(rFrechet(cindex));
        FrechetSubMed(sId, iId) = nanmedian(rFrechet(cindex));
        FrechetSubStd(sId, iId) = nanstd(rFrechet(cindex));
        FrechetSubSte(sId, iId) = nanstd(rFrechet(cindex))./sqrt(sum(cindex));
    end
end

%% Average Evolution Frechet 
util_bdisp('[proc] - Computing average evolution frechet per integrator');
FrechetEvoAvg = nan(NumRunPerInt, NumIntegrators);
FrechetEvoMed = nan(NumRunPerInt, NumIntegrators);
FrechetEvoStd = nan(NumRunPerInt, NumIntegrators);
FrechetEvoSte = nan(NumRunPerInt, NumIntegrators);

for iId = 1:NumIntegrators
    for rId = 1:NumRunPerInt
        cindex = rIk == Integrators(iId) & rYk == RunPerInt(rId);
        FrechetEvoAvg(rId, iId) = nanmean(rFrechet(cindex));
        FrechetEvoMed(rId, iId) = nanmedian(rFrechet(cindex));
        FrechetEvoStd(rId, iId) = nanstd(rFrechet(cindex));
        FrechetEvoSte(rId, iId) = nanstd(rFrechet(cindex))./sqrt(sum(cindex));
    end
end

%% Average Frechet per Target
FrechetTargetAvg = nan(NumTargets, NumIntegrators);
FrechetTargetMed = nan(NumTargets, NumIntegrators);
FrechetTargetStd = nan(NumTargets, NumIntegrators);
FrechetTargetSte = nan(NumTargets, NumIntegrators);

for cId = 1:NumTargets
   for iId = 1:NumIntegrators
        cindex = rCk == Targets(cId) & rIk == Integrators(iId);
        FrechetTargetAvg(cId, iId) = nanmean(rFrechet(cindex));
        FrechetTargetMed(cId, iId) = nanmedian(rFrechet(cindex));
        FrechetTargetStd(cId, iId) = nanstd(rFrechet(cindex));
        FrechetTargetSte(cId, iId) = nanstd(rFrechet(cindex))./sqrt(sum(cindex));
   end
end

%% TRIAL BASED
% %% Average Frechet per integrator
% util_bdisp('[proc] - Computing average frechet per integrator');
% FrechetIntAvg = zeros(NumIntegrators, 1);
% FrechetIntMed = zeros(NumIntegrators, 1);
% FrechetIntStd = zeros(NumIntegrators, 1);
% FrechetIntSte = zeros(NumIntegrators, 1);
% for iId = 1:NumIntegrators   
%     cindex = Ik == Integrators(iId) & ValidityCond;
%     FrechetIntAvg(iId) = nanmean(frechet(cindex));
%     FrechetIntMed(iId) = nanmedian(frechet(cindex));
%     FrechetIntStd(iId) = nanstd(frechet(cindex));
%     FrechetIntSte(iId) = nanstd(frechet(cindex))./sqrt(sum(cindex));
% end
% 
% %% Average Frechet per subject 
% util_bdisp('[proc] - Computing average frechet per integrator and per subject');
% FrechetSubAvg = zeros(NumSubjects, NumIntegrators);
% FrechetSubMed = zeros(NumSubjects, NumIntegrators);
% FrechetSubStd = zeros(NumSubjects, NumIntegrators);
% FrechetSubSte = zeros(NumSubjects, NumIntegrators);
% 
% for iId = 1:NumIntegrators
%     for sId = 1:NumSubjects       
%         cindex = Ik == Integrators(iId) & Sk == Subjects(sId) & ValidityCond;
%         FrechetSubAvg(sId, iId) = nanmean(frechet(cindex));
%         FrechetSubMed(sId, iId) = nanmedian(frechet(cindex));
%         FrechetSubStd(sId, iId) = nanstd(frechet(cindex));
%         FrechetSubSte(sId, iId) = nanstd(frechet(cindex))./sqrt(sum(cindex));
%     end
% end
% 
% %% Average Evolution Frechet 
% util_bdisp('[proc] - Computing average evolution frechet per integrator');
% FrechetEvoAvg = nan(NumRunPerInt, NumIntegrators);
% FrechetEvoMed = nan(NumRunPerInt, NumIntegrators);
% FrechetEvoStd = nan(NumRunPerInt, NumIntegrators);
% FrechetEvoSte = nan(NumRunPerInt, NumIntegrators);
% 
% for iId = 1:NumIntegrators
%     for rId = 1:NumRunPerInt
%         cindex = Ik == Integrators(iId) & Yk == RunPerInt(rId) & ValidityCond;
%         FrechetEvoAvg(rId, iId) = nanmean(frechet(cindex));
%         FrechetEvoMed(rId, iId) = nanmedian(frechet(cindex));
%         FrechetEvoStd(rId, iId) = nanstd(frechet(cindex));
%         FrechetEvoSte(rId, iId) = nanstd(frechet(cindex))./sqrt(sum(cindex));
%     end
% end
% 
% %% Average Frechet per Target
% FrechetTargetAvg = zeros(NumTargets, NumIntegrators);
% FrechetTargetMed = zeros(NumTargets, NumIntegrators);
% FrechetTargetStd = zeros(NumTargets, NumIntegrators);
% FrechetTargetSte = zeros(NumTargets, NumIntegrators);
% 
% for cId = 1:NumTargets
%    for iId = 1:NumIntegrators
%         cindex = Ck == Targets(cId) & Ik == Integrators(iId) & ValidityCond;
%         FrechetTargetAvg(cId, iId) = nanmean(frechet(cindex));
%         FrechetTargetMed(cId, iId) = nanmedian(frechet(cindex));
%         FrechetTargetStd(cId, iId) = nanstd(frechet(cindex));
%         FrechetTargetSte(cId, iId) = nanstd(frechet(cindex))./sqrt(sum(cindex));
%    end
% end

% %% Statistical tests
% % Statistical test per integrator
% util_bdisp('[stat] - Statistical per integrator:');
% cindex = ValidityCond;
% PValIntRun = ranksum(frechet(cindex & Ik == 1), frechet(cindex & Ik == 2));
% disp(['       - Significance between control modalities: p=' num2str(PValIntRun, 3)]);
% 
% % Statistical tests evolution over run
% util_bdisp('[stat] - Statistical per run:');
% PValEvoRun = zeros(NumRunPerInt, 1);
% for rId = 1:NumRunPerInt
%     cindex = Yk == RunPerInt(rId) & ValidityCond;
%     PValEvoRun(rId) = ranksum(frechet(cindex & Ik == 1), frechet(cindex & Ik == 2));
%     disp(['       - Significance between control modalities run ' num2str(rId) ' : p=' num2str(PValEvoRun(rId), 3)])
% end
% 
% % Statistical tests per target
% util_bdisp('[stat] - Statistical per Target:');
% PValTarg = zeros(NumTargets, 1);
% for cId = 1:NumTargets
%     cindex = Ck == Targets(cId) & ValidityCond;
%     PValTarg(cId) = ranksum(frechet(cindex & Ik == 1), frechet(cindex & Ik == 2));
%     disp(['       - Significance between control modalities (Target ' num2str(cId) ') : p=' num2str(PValTarg(cId), 3)])
% end
% 
% 
% % Statistical tests per subject 
% util_bdisp('[stat] - Statistical per subject:');
% PValSubj = zeros(NumSubjects, 1);
% for sId = 1:NumSubjects
%     cindex = Sk == Subjects(sId) & ValidityCond;
%     PValSubj(sId) = ranksum(frechet(cindex & Ik == 1), frechet(cindex & Ik == 2));
%     disp(['       - Significance between control modalities (Subject ' sublist{sId} ') : p=' num2str(PValSubj(sId), 3)])
% end

%% Statistical tests
% Statistical test per integrator
util_bdisp('[stat] - Statistical per integrator:');
PValIntRun = ranksum(rFrechet(rIk == 1), rFrechet(rIk == 2));
disp(['       - Significance between control modalities: p=' num2str(PValIntRun, 3)]);

% Statistical tests evolution over run
util_bdisp('[stat] - Statistical per run:');
PValEvoRun = zeros(NumRunPerInt, 1);
for rId = 1:NumRunPerInt
    cindex = rYk == RunPerInt(rId);
    PValEvoRun(rId) = ranksum(rFrechet(cindex & rIk == 1), rFrechet(cindex & rIk == 2));
    disp(['       - Significance between control modalities run ' num2str(rId) ' : p=' num2str(PValEvoRun(rId), 3)])
end

% Statistical tests per target
util_bdisp('[stat] - Statistical per Target:');
PValTarg = zeros(NumTargets, 1);
for cId = 1:NumTargets
    cindex = rCk == Targets(cId);
    PValTarg(cId) = ranksum(rFrechet(cindex & rIk == 1), rFrechet(cindex & rIk == 2));
    disp(['       - Significance between control modalities (Target ' num2str(cId) ') : p=' num2str(PValTarg(cId), 3)])
end


% Statistical tests per subject 
util_bdisp('[stat] - Statistical per subject:');
PValSubj = zeros(NumSubjects, 1);
for sId = 1:NumSubjects
    cindex = rSk == Subjects(sId);
    PValSubj(sId) = ranksum(rFrechet(cindex & rIk == 1), rFrechet(cindex & rIk == 2));
    disp(['       - Significance between control modalities (Subject ' sublist{sId} ') : p=' num2str(PValSubj(sId), 3)])
end

%% Plot

fig1 = figure;
fig_set_position(fig1, 'All');

NumRows = 3;
NumCols = 4;
color = [0 0.4470 0.7410; 0.8500 0.3250 0.0980];

% Average frechet per subject
subplot(NumRows, NumCols, [1 2 3]);
superbar(FrechetSubAvg, 'E', FrechetSubSte, 'BarFaceColor', reshape(color, [1 size(color)]), 'BarEdgeColor', [.4 .4 .4], 'BarLineWidth', .1, 'ErrorbarStyle', 'T', 'ErrorbarLineWidth', .1);
grid on;
%ylim([0 120]);
set(gca, 'XTick', 1:NumSubjects);
set(gca, 'XTickLabel', sublist);
xlabel('Subject');
ylabel('[cm]');
title('Average frechet per subject (+/- SEM)');

% Average frechet per integrator
subplot(NumRows, NumCols, 4);
superbar(FrechetIntAvg, 'E',  FrechetIntSte, 'ErrorbarStyle', 'T', 'BarWidth', 0.3, 'BarFaceColor', color, 'BarEdgeColor', [.4 .4 .4], 'BarLineWidth', .1, 'ErrorbarLineWidth', .1, 'P', [NaN PValIntRun; PValIntRun NaN], 'PLineWidth', 0.5, 'PStarThreshold', 0.06)
xlim([0.5 2.5]);
%ylim([0 120]);
set(gca, 'XTick', 1:2);
set(gca, 'XTickLabel', {'discrete', 'continuous'});
xlabel('Modality');
ylabel('[cm]');
title('Average target frechet (+/- SEM)');
grid on;


% Average evolution accuracy per run
subplot(NumRows, NumCols, NumCols + [1 2]);
errorbar(FrechetEvoAvg, FrechetEvoSte, 'o-');
xlim([0.5 5.5]);
%ylim([0 120]);
grid on;
set(gca, 'XTick', 1:NumRunPerInt);
ylabel('[cm]');
xlabel('Run');
title('Average frechet per run (+/- SEM)');

% Average per target
subplot(NumRows, NumCols, NumCols + [3 4]);
ctick = [0 pi/4 pi/2 3*pi/4 pi];
polarplot(ctick', flipud(FrechetTargetAvg), '-o');
set(gca, 'ThetaLim', [0 180]);
set(gca, 'ThetaTick', [0 45 90 135 180])
set(gca, 'ThetaTickLabel', {'Target 5', 'Target 4', 'Target 3', 'Target 2', 'Target 1'})
title('Average frechet per target');
ax = gca;
ax.RAxis.Label.String = '[cm]';

% Distribution per target
subplot(NumRows, NumCols, 2*NumCols + [1 2]);
condition = ValidityCond;
% boxplot(frechet(condition), {Ck(condition) Ik(condition)}, 'factorseparator', 1, 'labels', num2cell(Ik(condition)), 'labelverbosity', 'minor', 'labels', IntegratorName(Ik(condition)));
boxplot(frechet, {Ck Ik}, 'factorseparator', 1, 'labels', num2cell(Ik), 'labelverbosity', 'minor', 'labels', IntegratorName(Ik));
grid on;
ylabel('[cm]');
xlabel('Target')
title('Distribution frechet per target');

%% Maps plots - Trajectory maps
fig2 = figure;
fig_set_position(fig2, 'Top');

NumRows = 1;
NumCols = 2;
for iId = 1:NumIntegrators
    cindex  = Ik == Integrators(iId);% & ValidityCond;
    
    subplot(NumRows, NumCols, iId);
    imagesc(flipud(nanmean(HitMap(:, :, cindex), 3)'), [0 0.1]);
    
    % Plotting average for correct
    hold on;
    for cId = 1:NumTargets
        cindex = Ik == Integrators(iId) & Ck == Targets(cId) & ValidityCond;
        cpath = nanmean(rtrajectory(:, :, cindex), 3); 
        cpath = cpath/MapResolution;
        cpath(:, 2) = abs(cpath(:, 2) - mFieldSize(2));
        
        if isempty(cpath) == false
            plot(cpath(:, 1), cpath(:, 2), 'k-', 'LineWidth', 1);
        end
        
    end
    
    % Plotting manual
    for cId = 1:NumTargets
        cindex = mCk == Targets(cId);
        cpath = mtrajectory(cindex, :); 
        cpath(:, 2) = abs(cpath(:, 2) - FieldSize(2));
        cpath = cpath/MapResolution;
        if isempty(cpath) == false
            plot(cpath(:, 1), cpath(:, 2), 'k--', 'LineWidth', 1);
        end
        
    end
    hold off;
    
    axis image
    xlabel('[cm]');
    ylabel('[cm]');
    title([IntegratorName{iId}]);
    cnbirob_draw_field(mTargetPos, mTargetRadius, mFieldSize, 'flipped', true)
    set(gca, 'XTickLabel', '')
    set(gca, 'YTickLabel', '')
end

%% Maps plots - Trajectory maps per target
fig3 = figure;
fig_set_position(fig3, 'All');
for iId = 1:NumIntegrators
    for cId = 1:NumTargets
        cindex = Ik == Integrators(iId)  & Ck == Targets(cId);% & ValidityCond;
        
        subplot(2, NumTargets, cId + NumTargets*(iId-1));
        imagesc(flipud(nanmean(HitMap(:, :, cindex), 3)'), [0 0.5]);
        
        hold on;
        % Plotting average for correct
        cpath = nanmean(rtrajectory(:, :, cindex  & ValidityCond), 3); 
        cpath(:, 2) = abs(cpath(:, 2) - FieldSize(2));
        cpath = cpath/MapResolution;
        if isempty(cpath) == false
            plot(cpath(:, 1), cpath(:, 2), 'k-', 'LineWidth', 1);
        end
        
        % Plotting manual
        cmpath = mtrajectory(mCk == Targets(cId), :); 
        cmpath(:, 2) = abs(cmpath(:, 2) - FieldSize(2));
        cmpath = cmpath/MapResolution;
        if isempty(cmpath) == false
            plot(cmpath(:, 1), cmpath(:, 2), 'k--', 'LineWidth', 1);
        end
        hold off;
        
        axis image
        xlabel('[cm]');
        ylabel('[cm]');
        title(TargetName{cId});
        cnbirob_draw_field(mTargetPos, mTargetRadius, mFieldSize, 'flipped', true)
        set(gca, 'XTickLabel', '')
        set(gca, 'YTickLabel', '')
    end
end

%% Maps plots - Trajectory lines
fig4 = figure;
fig_set_position(fig4, 'Top');
for iId = 1:NumIntegrators
    subplot(NumRows, NumIntegrators, iId);
    
    hold on;
    
    % Plotting all trajectory with different colors for correct and wrong
    for trId = 1:NumTrials
        cindex = Ik == Integrators(iId) & Tk == trId;
        
        if sum(cindex) == 0
            continue;
        end
        
        cpath = rtrajectory(:, :, cindex);
        
        cstyle = 'r';
        if ValidityCond(trId) == true
            cstyle = 'g';
        end
        
        h = plot(cpath(:, 1), cpath(:, 2), cstyle);
    end
    
    % Plotting average for correct
    for cId = 1:NumTargets
        cindex = Ik == Integrators(iId) & Ck == Targets(cId); 
        
        cpath = nanmean(rtrajectory(:, :, cindex & ValidityCond), 3); 
        
        if isempty(cpath) == false
            plot(cpath(:, 1), cpath(:, 2), 'k-', 'LineWidth', 2);
        end
        
    end
    
    % Plotting manual
    for cId = 1:NumTargets
        cpath = mtrajectory(mCk == Targets(cId), :); 
        
        if isempty(cpath) == false
            plot(cpath(:, 1), cpath(:, 2), 'k--', 'LineWidth', 2);
        end
        
    end
    hold off;
    
    % Draw field
    cnbirob_draw_field(TargetPos, TargetRadius, FieldSize);
    axis image
    xlim([1 FieldSize(1)]);
    ylim([1 FieldSize(2)]);
    grid on;
    xlabel('[cm]');
    ylabel('[cm]');
    title(IntegratorName{iId});
    set(gca, 'XTickLabel', '')
    set(gca, 'YTickLabel', '')
    
end

%% Saving figures
figfilename1 = [figdir '/group_trajectory_frechet.pdf'];
util_bdisp(['[fig] - Saving figure in: ' figfilename1]);
fig_figure2pdf(fig1, figfilename1) 

figfilename2 = [figdir '/group_trajectory_hitmap.pdf'];
util_bdisp(['[fig] - Saving figure in: ' figfilename2]);
fig_figure2pdf(fig2, figfilename2) 

figfilename3 = [figdir '/group_trajectory_hitmap_target.pdf'];
util_bdisp(['[fig] - Saving figure in: ' figfilename3]);
fig_figure2pdf(fig3, figfilename3) 

figfilename4 = [figdir '/group_trajectory_lines.pdf'];
util_bdisp(['[fig] - Saving figure in: ' figfilename4]);
fig_figure2pdf(fig4, figfilename4) 



