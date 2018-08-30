% clearvars; clc;
% 
% subject = 'e8';

pattern         = [subject '*.online.mi.mi_bhbf.*.mobile'];
datapath        = 'analysis/robot/tracking/';
savedir         = 'analysis/robot/';
IntegratorName  = {'discrete', 'continuous'};
TargetName      = {'Target1', 'Target2', 'Target3', 'Target4', 'Target5'};
FieldSize       = [900 600];    % [cm]
MapResolution   = 2.5;            % [cm]
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

%% Getting processed datafiles
files = util_getfile(datapath, '.mat', pattern);

%% Concatenate all files
util_bdisp(['[io] - Concatenate tracking data for subject ' subject]);
[tracking, lbls] = cnbirob_concatenate_tracking_data(files, 'tracking');

%% Extracting label information
util_bdisp('[proc] - Extracting label information');
Integrators     = unique(lbls.Ik);
NumIntegrators  = length(Integrators);
Runs            = unique(lbls.Rk);
NumRuns         = length(Runs);
NumSamples      = length(tracking);
Trials          = unique(lbls.Tk);
NumTrials       = length(Trials);
Days            = unique(lbls.Dk);
NumDays         = length(Days);
Targets         = unique(lbls.Ck);
NumTargets      = length(Targets);

%% Loading target record data
util_bdisp('[proc] - Loading target record data');
load(['analysis/robot/' subject '_robot_records.mat']); 
Xk = records.trial.Xk;

%% Loading valid data (<Timeout)
util_bdisp('[proc] - Loading target record data');
cdata = load(['analysis/robot/' subject '_robot_valid.mat']); 
Vk = cdata.Vk;

%% Loading manual trajectories
util_bdisp('[proc] - Loading manual trajectory data');
manual = load('analysis/robot/00_robot_trajectory.mat'); 


%% Create trial-based label vectors
util_bdisp('[proc] - Create trial-based label vectors');
Ik = zeros(NumTrials, 1);
Rk = zeros(NumTrials, 1);
Dk = zeros(NumTrials, 1);
Ck = zeros(NumTrials, 1);
Tk = zeros(NumTrials, 1);

for trId = 1:NumTrials
    cidx = find(lbls.Tk == Trials(trId), 1);
    Ik(trId) = lbls.Ik(cidx);
    Rk(trId) = lbls.Rk(cidx);
    Dk(trId) = lbls.Dk(cidx);
    Ck(trId) = lbls.Ck(cidx);
    Tk(trId) = Trials(trId);
end

%% Create hit-map from trajectories
util_bdisp('[proc] - Create hit-map from trajectories');
HitMap = zeros([mFieldSize NumTrials]);

for trId = 1:NumTrials
    cindex = lbls.Tk == Tk(trId); 
    HitMap(:, :, trId) = cnbirob_traj2map(tracking(cindex, :), FieldSize, MapResolution);
end

%% Create resampled trajectories
util_bdisp('[proc] - Create resampled trajectories');
maxlength = 0;
for trId = 1:NumTrials
    maxlength = max(maxlength, sum(lbls.Tk == Trials(trId)));
end

rtracking = zeros(maxlength, 2, NumTrials);
for trId = 1:NumTrials
    cindex = lbls.Tk == Trials(trId);
    clength = sum(cindex);
    cpath = tracking(cindex, :);
    rtracking(:, :, trId) =  interp1(1:clength, cpath, linspace(1, clength, maxlength));
    
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

%% Frechet distance
util_bdisp('[proc] - Computing Frechet distance');
fdistance = zeros(NumTrials, 1);
for trId = 1:NumTrials
    util_disp_progress(trId, NumTrials, ' ')
    
    if strcmpi(subject, 'ai6') && (trId == 21)
        disp(['[proc] - Skipping trial 21 for subject ' subject ' (nan values)']);
        continue
    elseif strcmpi(subject, 'ah7') && (trId == 51)
        disp(['[proc] - Skipping trial 51 for subject ' subject ' (nan values)']);
        continue
    elseif strcmpi(subject, 'ah7') && (trId == 52)
        disp(['[proc] - Skipping trial 52 for subject ' subject ' (nan values)']);
        continue
    elseif strcmpi(subject, 'b4') && (trId <= 10)
        disp(['[proc] - Skipping trial <=10 (first run) for subject ' subject ' (nan values)']);
        continue
    end
    
    ctarget = Ck(trId); 
    cindex = lbls.Tk == Tk(trId);
    
    crefpath = mtracking(:, :, ctarget);
    cpath    = tracking(cindex, :);
    fdistance(trId) = proc_frechet_distance(crefpath, cpath);
end

%% Statistics
util_bdisp('[proc] - Computing statistics');
fdistance_pval = zeros(NumTargets, 1);
for tgId = 1:NumTargets
    cindex1 = Xk == 1 & Vk == 1 & Ik == 1 & Ck == tgId;
    cindex2 = Xk == 1 & Vk == 1 & Ik == 2 & Ck == tgId;
    if sum(cindex1)==0 || sum(cindex2)==0
        disp(['[stat] - Skipping target ' Targets(tgId) ': no data available']);
        continue;
    end
    fdistance_pval(tgId) = ranksum(fdistance(cindex1), fdistance(cindex2));
    
    disp(['[stat] - Wilcoxon test on frechet distance for target ' num2str(tgId) ': p=' num2str(fdistance_pval(tgId),3)]); 
end

%% Saving subject data
filename = fullfile(savedir, [subject '_robot_trajectory.mat']);
util_bdisp(['[out] - Saving subject data in: ' filename]);
trajectory  = tracking;
mtrajectory = mtracking;
frechet     = fdistance;
labels.sample.Rk = lbls.Rk;
labels.sample.Ik = lbls.Ik;
labels.sample.Dk = lbls.Dk;
labels.sample.Tk = lbls.Tk;
labels.sample.Ck = lbls.Ck;
labels.trial.Ik  = Ik;
labels.trial.Rk  = Rk;
labels.trial.Dk  = Dk;
labels.trial.Ck  = Ck;
labels.trial.Tk  = Tk;
labels.trial.Xk  = Xk;
labels.trial.Vk  = Vk;
save(filename, 'trajectory', 'mtrajectory', 'frechet', 'labels');

%% Plotting

if DoPlot == false
    return
end

util_bdisp('[out] - Plotting subject trajectories');
fig1 = figure;
fig_set_position(fig1, 'Top');
for iId = 1:NumIntegrators
    cindex  = Ik == Integrators(iId);% & Xk == true & Vk == true;
    
    subplot(1, 2, iId);
    imagesc(flipud(nanmean(HitMap(:, :, cindex), 3)'), [0 0.1]);
    
    % Plotting average for correct
    hold on;
    for tgId = 1:NumTargets
        cindex = Ik == Integrators(iId) & Ck == Targets(tgId); 
        
        cpath = nanmean(rtracking(:, :, cindex & Xk == true & Vk == true), 3); 
        cpath(:, 2) = abs(cpath(:, 2) - FieldSize(2));
        cpath = ceil(cpath/MapResolution);
        if isempty(cpath) == false
            plot(cpath(:, 1), cpath(:, 2), 'ko', 'MarkerSize', 1);
        end
        
    end
    hold off;
    
    % Plotting manual
    hold on;
    for tgId = 1:NumTargets
        cpath = mtracking(:, :, tgId); 
        cpath(:, 2) = abs(cpath(:, 2) - FieldSize(2));
        cpath = ceil(cpath/MapResolution);
        if isempty(cpath) == false
            plot(cpath(:, 1), cpath(:, 2), 'g', 'MarkerSize', 1);
        end
        
    end
    hold off;
    
    axis image
    xlabel('[cm]');
    ylabel('[cm]');
    title([subject ' - ' IntegratorName{iId}]);
    cnbirob_draw_field(mTargetPos, mTargetRadius, mFieldSize, 'flipped', true)
    set(gca, 'XTickLabel', '')
    set(gca, 'YTickLabel', '')
end

fig2 = figure;
fig_set_position(fig2, 'All');
for iId = 1:NumIntegrators
    for tgId = 1:NumTargets
        cindex = Ik == Integrators(iId)  & Ck == Targets(tgId);
        
        subplot(2, NumTargets, tgId + NumTargets*(iId-1));
        imagesc(flipud(nanmean(HitMap(:, :, cindex), 3)'), [0 0.5]);
        
        hold on;
        cpath = nanmean(rtracking(:, :, cindex & Xk == true & Vk == true), 3); 
        cpath(:, 2) = abs(cpath(:, 2) - FieldSize(2));
        cpath = ceil(cpath/MapResolution);
        if isempty(cpath) == false
            plot(cpath(:, 1), cpath(:, 2), 'ko', 'MarkerSize', 1);
        end
        hold off;
        
        
        % Plotting manual
        hold on;
        cmpath = mtracking(:, :, tgId); 
        cmpath(:, 2) = abs(cmpath(:, 2) - FieldSize(2));
        cmpath = ceil(cmpath/MapResolution);
        if isempty(cmpath) == false
            plot(cmpath(:, 1), cmpath(:, 2), 'g', 'MarkerSize', 1);
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
suptitle(['Subject ' subject]);

%% Fig 3
fig3 = figure;
fig_set_position(fig3, 'Top');
for iId = 1:NumIntegrators
    subplot(1, NumIntegrators, iId);
    
    hold on;
    
    for trId = 1:NumTrials
        cindex = Ik == Integrators(iId) & Tk == Trials(trId);
        
        if sum(cindex) == 0
            continue;
        end
        
        cpath = rtracking(:, :, cindex);
        
        cstyle = 'or';
        if Xk(trId) == true
            cstyle = 'og';
        end
        
        plot(cpath(:, 1), cpath(:, 2), cstyle, 'MarkerSize', 0.05);
    end
        
    
    % Plotting average for correct
    for tgId = 1:NumTargets
        cindex = Ik == Integrators(iId) & Ck == Targets(tgId); 
        
        cpath = nanmean(rtracking(:, :, cindex & Xk == true & Vk == true), 3); 
        
        if isempty(cpath) == false
            plot(cpath(:, 1), cpath(:, 2), 'ko', 'MarkerSize', 1);
        end
        
    end
    hold off;
    
    % Plotting manual
    hold on;
    for tgId = 1:NumTargets
        cpath = mtracking(:, :, tgId); 
        
        if isempty(cpath) == false
            plot(cpath(:, 1), cpath(:, 2), 'k--', 'MarkerSize', 1);
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
    title([subject ' - ' IntegratorName{iId}]);
    set(gca, 'XTickLabel', '')
    set(gca, 'YTickLabel', '')
    
end

%% Fig4
fig4 = figure;
fig_set_position(fig4, 'Top');

boxplot(fdistance(Xk == 1 & Vk == 1), {Ck(Xk == 1 & Vk == 1) Ik(Xk == 1 & Vk == 1)}, 'factorseparator', 1, 'labels', num2cell(Ck(Xk==1 & Vk == 1)), 'labelverbosity', 'minor');
grid on;
xlabel('Target');
ylabel('[cm]');
title(['Subject ' subject ' - Frechet distance per target']);

