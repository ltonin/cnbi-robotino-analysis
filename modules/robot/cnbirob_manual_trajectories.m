clearvars; clc;

subject = '00';

pattern         = [subject '*.manual'];
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

DoPlot = true;

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

%% Saving subject data
filename = fullfile(savedir, [subject '_robot_trajectory.mat']);
util_bdisp(['[out] - Saving subject data in: ' filename]);
trajectory = tracking;
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
save(filename, 'trajectory', 'labels');

%% Plotting

if DoPlot == false
    return
end



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
        
        cstyle = 'og';
        
        plot(cpath(:, 1), cpath(:, 2), cstyle, 'MarkerSize', 0.05);
    end
        
    
    % Plotting average for correct
    for tgId = 1:NumTargets
        cindex = Ik == Integrators(iId) & Ck == Targets(tgId); 
        
        cpath = nanmean(rtracking(:, :, cindex), 3); 
        
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

