% clearvars; clc;
% 
% subject = '00';

pattern         = [subject '*.online.mi.mi_bhbf.*.mobile'];
datapath        = 'analysis/robot/tracking/';
savedir         = 'analysis/robot/trajectory/';

% Create analysis directory
util_mkdir('./', savedir);

%% Getting processed datafiles
files = util_getfile(datapath, '.mat', pattern);

%% Concatenate all tracking files
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
Yk = zeros(NumTrials, 1);

for trId = 1:NumTrials
    cidx = find(lbls.Tk == Trials(trId), 1);
    Ik(trId) = lbls.Ik(cidx);
    Rk(trId) = lbls.Rk(cidx);
    Dk(trId) = lbls.Dk(cidx);
    Ck(trId) = lbls.Ck(cidx);
    Tk(trId) = Trials(trId);
    Yk(trId) = lbls.Yk(cidx);
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
trajectory  = tracking;
rtrajectory = rtracking;

labels.raw.sample.Rk = lbls.Rk;
labels.raw.sample.Ik = lbls.Ik;
labels.raw.sample.Dk = lbls.Dk;
labels.raw.sample.Tk = lbls.Tk;
labels.raw.sample.Ck = lbls.Ck;
labels.raw.trial.Ik  = Ik;
labels.raw.trial.Rk  = Rk;
labels.raw.trial.Dk  = Dk;
labels.raw.trial.Ck  = Ck;
labels.raw.trial.Tk  = Tk;
labels.raw.trial.Yk  = Yk;

save(filename, 'trajectory', 'rtrajectory', 'labels');

