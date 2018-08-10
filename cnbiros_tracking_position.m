clearvars; clc;

subject = 'aj1';

pattern         = [subject '*.online.mi.mi_bhbf.*.mobile'];
datapath        = 'analysis/robot/tracking/';
savedir         = 'analysis/robot/tracking/';
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

mTargetPos    = ceil(TargetPos/MapResolution);
mTargetRadius = ceil(TargetRadius/MapResolution);
mFieldSize    = ceil(FieldSize/MapResolution);

%% Getting processed datafiles
files = util_getfile(datapath, '.mat', pattern);

%% Concatenate all files
util_bdisp('[io] - Concatenate tracking data');
[tracking, labels] = cnbirob_concatenate_tracking_data(files, 'tracking');

%% Extracting label information
Integrators     = unique(labels.Ik);
NumIntegrators  = length(Integrators);
Runs            = unique(labels.Rk);
NumRuns         = length(Runs);
NumSamples      = length(tracking);
Trials          = unique(labels.Tk);
NumTrials       = length(Trials);
Days            = unique(labels.Dk);
NumDays         = length(Days);
Targets         = unique(labels.Ck);
NumTargets      = length(Targets);

%% Loading target record data
load(['analysis/robot/' subject '_robot_records.mat']); 
Xk = records.trial.Xk;

%% Create trial-based label vectors
Ik = zeros(NumTrials, 1);
Rk = zeros(NumTrials, 1);
Dk = zeros(NumTrials, 1);
Ck = zeros(NumTrials, 1);
Tk = zeros(NumTrials, 1);

for trId = 1:NumTrials
    cidx = find(labels.Tk == Trials(trId), 1);
    Ik(trId) = labels.Ik(cidx);
    Rk(trId) = labels.Rk(cidx);
    Dk(trId) = labels.Dk(cidx);
    Ck(trId) = labels.Ck(cidx);
    Tk(trId) = Trials(trId);
end

%% Create hit-map from trajectories
HitMap = zeros([mFieldSize NumTrials]);

for trId = 1:NumTrials
    cindex = labels.Tk == Tk(trId); 
    HitMap(:, :, trId) = cnbirob_traj2map(tracking(cindex, :), FieldSize, MapResolution);
end

%% Create resampled trajectories

maxlength = 0;
for trId = 1:NumTrials
    maxlength = max(maxlength, sum(labels.Tk == Trials(trId)));
end

rtracking = zeros(maxlength, 2, NumTrials);
for trId = 1:NumTrials
    cindex = labels.Tk == Trials(trId);
    clength = sum(cindex);
    cpath = tracking(cindex, :);
    rtracking(:, :, trId) =  interp1(1:clength, cpath, linspace(1, clength, maxlength));
    
end

%% Plotting

fig1 = figure;
fig_set_position(fig1, 'Top');
for iId = 1:NumIntegrators
    cindex  = Ik == Integrators(iId) & Xk == true;
    
    subplot(1, 2, iId);
    imagesc(flipud(mean(HitMap(:, :, cindex), 3)'), [0 0.1]);
    
    % Plotting average for correct
    hold on;
    for tgId = 1:NumTargets
        cindex = Ik == Integrators(iId) & Ck == Targets(tgId); 
        
        cpath = mean(rtracking(:, :, cindex & Xk == true), 3); 
        cpath(:, 2) = abs(cpath(:, 2) - FieldSize(2));
        cpath = ceil(cpath/MapResolution);
        if isempty(cpath) == false
            plot(cpath(:, 1), cpath(:, 2), 'ko', 'MarkerSize', 1);
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
        imagesc(flipud(mean(HitMap(:, :, cindex), 3)'), [0 0.5]);
        
        hold on;
        cpath = mean(rtracking(:, :, cindex & Xk == true), 3); 
        cpath(:, 2) = abs(cpath(:, 2) - FieldSize(2));
        cpath = ceil(cpath/MapResolution);
        if isempty(cpath) == false
            plot(cpath(:, 1), cpath(:, 2), 'ko', 'MarkerSize', 1);
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
        
        cpath = mean(rtracking(:, :, cindex & Xk == true), 3); 
        
        if isempty(cpath) == false
            plot(cpath(:, 1), cpath(:, 2), 'ko', 'MarkerSize', 1);
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

