clearvars; clc; close all;

sublist = {'ai6', 'ai7', 'ai8', 'aj1', 'aj3', 'aj4', 'aj7', 'aj8', 'aj9', 'e8', 'ah7', 'ac7', 'b4'};

pattern         = '_robot_trajectory.mat';
datapath        = 'analysis/robot/';
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

mTargetPos    = ceil(TargetPos/MapResolution);
mTargetRadius = ceil(TargetRadius/MapResolution);
mFieldSize    = ceil(FieldSize/MapResolution);

NumSubjects = length(sublist);

trajectory = [];
frechet    = [];

Rk  = []; Ik  = []; Dk  = []; Tk  = []; Ck  = []; Sk  = []; Xk = []; Vk = [];
sRk = []; sIk = []; sDk = []; sTk = []; sCk = []; sSk = [];
cnumtrials = 0;

for sId = 1:NumSubjects
    csubject  = sublist{sId};
    cfilename = [datapath csubject pattern]; 
    util_bdisp(['[io] - Importing trajectory data for subject: ' csubject]); 
    
    cdata = load(cfilename);
    
    ctraj = cdata.trajectory;
    
    trajectory = cat(1, trajectory, ctraj);
    
    frechet = cat(1, frechet, cdata.frechet);
    
    % Labels 
    
    sRk = cat(1, sRk, cdata.labels.sample.Rk);
    sIk = cat(1, sIk, cdata.labels.sample.Ik);
    sDk = cat(1, sDk, cdata.labels.sample.Dk);
    sCk = cat(1, sCk, cdata.labels.sample.Ck);
    sSk = cat(1, sSk, sId*ones(length(cdata.labels.sample.Rk), 1));

    Rk  = cat(1, Rk,  cdata.labels.trial.Rk);
    Ik  = cat(1, Ik,  cdata.labels.trial.Ik);
    Dk  = cat(1, Dk,  cdata.labels.trial.Dk);
    Ck  = cat(1, Ck,  cdata.labels.trial.Ck);
    Xk  = cat(1, Xk,  cdata.labels.trial.Xk);
    Vk  = cat(1, Vk,  cdata.labels.trial.Vk);
    Sk  = cat(1, Sk,  sId*ones(length(cdata.labels.trial.Rk), 1));
    
    sTk = cat(1, sTk, cdata.labels.sample.Tk + cnumtrials);
    Tk  = cat(1, Tk,  cdata.labels.trial.Tk + cnumtrials);
    cnumtrials = max(Tk);
end

Integrators    = unique(Ik);
NumIntegrators = length(Integrators);
NumTrials      = length(Tk);
Targets        = unique(Ck);
NumTargets     = length(Targets);
Days           = unique(Dk);
NumDays        = length(Days);

%% Loading manual trajectories
util_bdisp('[proc] - Loading manual trajectory data');
manual = load('analysis/robot/00_robot_trajectory.mat'); 

%% Create hit-map from trajectories
util_bdisp('[proc] - Create hit-map from trajectories');
HitMap = zeros([mFieldSize NumTrials]);

for trId = 1:NumTrials
    cindex = sTk == Tk(trId); 
    HitMap(:, :, trId) = cnbirob_traj2map(trajectory(cindex, :), FieldSize, MapResolution);
end

%% Create resampled trajectories
util_bdisp('[proc] - Create resampled trajectories');
maxlength = 0;
for trId = 1:NumTrials
    maxlength = max(maxlength, sum(sTk == Tk(trId)));
end

rtrajectory = zeros(maxlength, 2, NumTrials);
for trId = 1:NumTrials
    cindex = sTk == Tk(trId);
    clength = sum(cindex);
    cpath = trajectory(cindex, :);
    rtrajectory(:, :, trId) =  interp1(1:clength, cpath, linspace(1, clength, maxlength));
    
end

%% Create resampled trajectories for manual
util_bdisp('[proc] - Create resampled trajectories for manual');
maxlength = 0;

for trId = 1:max(manual.labels.trial.Tk)
    maxlength = max(maxlength, sum(manual.labels.sample.Tk == manual.labels.trial.Tk(trId)));
end

ttracking = zeros(maxlength, 2, max(manual.labels.trial.Tk));
for trId = 1:max(manual.labels.trial.Tk)
    cindex = manual.labels.sample.Tk == manual.labels.trial.Tk(trId);
    clength = sum(cindex);
    cpath = manual.trajectory(cindex, :);
    ttracking(:, :, trId) =  interp1(1:clength, cpath, linspace(1, clength, maxlength));
    
end

mtracking = zeros(maxlength, 2, NumTargets);
for tgId = 1:NumTargets
    cindex = manual.labels.trial.Ck == Targets(tgId);
    mtracking(:, :, tgId) = nanmean(ttracking(:, :, cindex), 3);
end

%% Find the minimum distance from target
target_mindist = zeros(NumTrials, 1);
target_maxdist = zeros(NumTrials, 1);
for trId = 1:NumTrials
   ctrgpos = TargetPos(Ck(trId), :);
   ctraj = trajectory(sTk == trId, :);
   cdistances = sqrt( (ctraj(:, 1) - ctrgpos(1)).^2 + (ctraj(:, 2) - ctrgpos(2)).^2); 
   target_mindist(trId) = nanmin(cdistances);
   target_maxdist(trId) = nanmax(cdistances);
end

%% Frechet distance evolution over days
util_bdisp('[proc] - Computing evolution over days of Frechet distance');

frechet_evo_avg = zeros(NumTargets, NumDays, NumIntegrators); 
frechet_evo_std = zeros(NumTargets, NumDays, NumIntegrators); 
npoints = zeros(NumTargets, NumDays, NumIntegrators); 
for tgId = 1:NumTargets 
    for dId = 1:NumDays
        for iId = 1:NumIntegrators
            cindex = Ck == Targets(tgId) & Xk == 1 & Vk == 1 & Dk == Days(dId) & Ik == iId; 
            frechet_evo_avg(tgId, dId, iId) = nanmean(frechet(cindex)); 
            frechet_evo_std(tgId, dId, iId) = nanstd(frechet(cindex)); 
            npoints(tgId, dId, iId) = sum(cindex);
        end
    end
end

%% Frechet distance per target
AvgFrechetTarget = zeros(NumTargets, NumIntegrators);
MedFrechetTarget = zeros(NumTargets, NumIntegrators);
StdFrechetTarget = zeros(NumTargets, NumIntegrators);
SteFrechetTarget = zeros(NumTargets, NumIntegrators);
for cId = 1:NumTargets
    for iId = 1:NumIntegrators
        cindex = Ck == Targets(cId) & Ik == Integrators(iId) & Xk == 1 & Vk == 1;
        AvgFrechetTarget(cId, iId) = nanmean(frechet(cindex));
        MedFrechetTarget(cId, iId) = nanmedian(frechet(cindex));
        StdFrechetTarget(cId, iId) = nanstd(frechet(cindex));
        SteFrechetTarget(cId, iId) = nanstd(frechet(cindex))./sqrt(sum(cindex));
    end
end

%% Statistics
util_bdisp('[proc] - Computing statistics');
frechet_pval = zeros(NumTargets, 1);
for tgId = 1:NumTargets
    frechet_pval(tgId) = ranksum(frechet(Xk == 1 & Vk == 1 & Ik == 1 & Ck == tgId), frechet(Xk == 1 & Vk ==1 & Ik == 2 & Ck == tgId));
    
    disp(['[stat] - Wilcoxon test on frechet distance for target ' num2str(tgId) ': p=' num2str(frechet_pval(tgId),3)]); 
end

%% Plotting
util_bdisp('[out] - Plotting trajectories');

%% Figure 1 - Heat map average
fig1 = figure;
fig_set_position(fig1, 'Top');
for iId = 1:NumIntegrators
    cindex  = Ik == Integrators(iId);% & Xk == false;
    
    subplot(1, 2, iId);
    imagesc(flipud(mean(HitMap(:, :, cindex), 3)'), [0 0.1]);
    
    % Plotting average for correct
    hold on;
    for tgId = 1:NumTargets
        cindex = Ik == Integrators(iId) & Ck == Targets(tgId) & Xk == true & Vk == 1;
        cpath = nanmean(rtrajectory(:, :, cindex), 3); 
        cpath = cpath/MapResolution;
        cpath(:, 2) = abs(cpath(:, 2) - mFieldSize(2));
        
        if isempty(cpath) == false
            plot(cpath(:, 1), cpath(:, 2), 'ko', 'MarkerSize', 0.1);
        end
        
    end
    hold off;
    
     % Plotting manual
    hold on;
    for tgId = 1:NumTargets
        cpath = mtracking(:, :, tgId); 
        cpath(:, 2) = abs(cpath(:, 2) - FieldSize(2));
        cpath = cpath/MapResolution;
        if isempty(cpath) == false
            plot(cpath(:, 1), cpath(:, 2), 'k--', 'MarkerSize', 1);
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

%% Figure 2 - Heat map average per target
fig2 = figure;
fig_set_position(fig2, 'All');
for iId = 1:NumIntegrators
    for tgId = 1:NumTargets
        cindex = Ik == Integrators(iId)  & Ck == Targets(tgId) & Xk == true & Vk == 1;
        
        subplot(2, NumTargets, tgId + NumTargets*(iId-1));
        imagesc(flipud(nanmean(HitMap(:, :, cindex), 3)'), [0 0.5]);
        
        hold on;
        cpath = nanmean(rtrajectory(:, :, cindex & Xk == true & Vk == 1), 3); 
        cpath(:, 2) = abs(cpath(:, 2) - FieldSize(2));
        cpath = cpath/MapResolution;
        if isempty(cpath) == false
            plot(cpath(:, 1), cpath(:, 2), 'ko', 'MarkerSize', 0.01);
        end
        hold off;
        
        % Plotting manual
        hold on;
        cmpath = mtracking(:, :, tgId); 
        cmpath(:, 2) = abs(cmpath(:, 2) - FieldSize(2));
        cmpath = cmpath/MapResolution;
        if isempty(cmpath) == false
            plot(cmpath(:, 1), cmpath(:, 2), 'k--', 'MarkerSize', 1);
        end
        hold off;
        
        axis image
        xlabel('[cm]');
        ylabel('[cm]');
        title(TargetName{tgId});
        cnbirob_draw_field(mTargetPos, mTargetRadius, mFieldSize, 'flipped', true)
        set(gca, 'XTickLabel', '')
        set(gca, 'YTickLabel', '')
    end
end

%% Fig 3
fig3 = figure;
fig_set_position(fig3, 'Top');
for iId = 1:NumIntegrators
    subplot(1, NumIntegrators, iId);
    
    hold on;
    
    for trId = 1:NumTrials
        cindex = Ik == Integrators(iId) & Tk == trId;
        
        if sum(cindex) == 0
            continue;
        end
        
        cpath = rtrajectory(:, :, cindex);
        
        cstyle = '.r';
        if Xk(trId) == true
            cstyle = '.g';
        end
        
        plot(cpath(:, 1), cpath(:, 2), cstyle, 'MarkerSize', 0.01);
    end
    
    hold off;
    
    hold on;
    
    % Plotting average for correct
    for tgId = 1:NumTargets
        cindex = Ik == Integrators(iId) & Ck == Targets(tgId); 
        
        cpath = nanmean(rtrajectory(:, :, cindex & Xk == true & Vk == 1), 3); 
        
        if isempty(cpath) == false
            plot(cpath(:, 1), cpath(:, 2), 'k', 'LineWidth', 2);
        end
        
    end
    hold off;
    
    % Plotting manual
    hold on;
    for tgId = 1:NumTargets
        cpath = mtracking(:, :, tgId); 
        
        if isempty(cpath) == false
            plot(cpath(:, 1), cpath(:, 2), 'k--', 'LineWidth', 1);
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

%% Fig4
fig4 = figure;
fig_set_position(fig4, 'All');

subplot(1, 4, [1 2]);
condition = Xk == 1 & Vk == 1;
boxplot(frechet(condition), {Ck(condition) Ik(condition)}, 'factorseparator', 1, 'labels', num2cell(Ck(condition)), 'labelverbosity', 'minor');
grid on;
xlabel('Target');
ylabel('[cm]');
title('Frechet distance per target');

subplot(1, 4, [3 4]);
ctick = [0 pi/4 pi/2 3*pi/4 pi];
polarplot(ctick', flipud(MedFrechetTarget), '-o');
set(gca, 'ThetaLim', [0 180])
set(gca, 'RTickLabel', {'0cm'; '50cm'; '100cm'})
set(gca, 'ThetaTick', [0 45 90 135 180])
set(gca, 'ThetaTickLabel', {'Target 5', 'Target 4', 'Target 3', 'Target 2', 'Target 1'})
title('Median frechet distance per target')

%% Saving figures
figfilename1 = [figdir '/group_trajectory_hitmap.pdf'];
util_bdisp(['[fig] - Saving figure in: ' figfilename1]);
fig_figure2pdf(fig1, figfilename1) 

figfilename2 = [figdir '/group_trajectory_hitmap_target.pdf'];
util_bdisp(['[fig] - Saving figure in: ' figfilename2]);
fig_figure2pdf(fig2, figfilename2) 

figfilename3 = [figdir '/group_trajectory.pdf'];
util_bdisp(['[fig] - Saving figure in: ' figfilename3]);
fig_figure2pdf(fig3, figfilename3) 

figfilename4 = [figdir '/group_trajectory_frechet.pdf'];
util_bdisp(['[fig] - Saving figure in: ' figfilename4]);
fig_figure2pdf(fig4, figfilename4) 



