clearvars;

subject = 'aj8';
savedir = 'analysis/robot/record/';

% Create analysis directory
util_mkdir('./', savedir);

% Target - Reached results
Target(:, 1)   = [3 2 5 1 4 2 1 5 3 4];
Reached(:, 1)  = [1 1 1 1 1 1 1 1 1 1];
Target(:, 2)   = [4 4 1 2 5 2 3 3 1 5];
Reached(:, 2)  = [1 1 0 1 0 1 1 1 0 0];

[NumTargets, NumRuns] = size(Target);

% Integrator type
IntegratorType = [2 1];
IntegratorName = {'ema', 'dynamic'};

% Day
DayId = [1 1];

% Get reached
reached = reshape(Reached, numel(Reached), 1);

% Get raw labels
labels.raw.trial.Rk = reshape(repmat(1:NumRuns, [NumTargets 1]), NumRuns*NumTargets, 1);
labels.raw.trial.Ck = reshape(Target, numel(Target), 1);
labels.raw.trial.Ik = reshape(repmat(IntegratorType, [NumTargets 1]), NumRuns*NumTargets, 1);
labels.raw.trial.Il = IntegratorName;
labels.raw.trial.Dk = reshape(repmat(DayId, [NumTargets 1]), NumRuns*NumTargets, 1);
labels.raw.trial.Tk = (1:NumRuns*NumTargets)';

labels.raw.run.Rk = 1:NumRuns;
labels.raw.run.Ik = IntegratorType;
labels.raw.run.Dk = DayId;

save([savedir '/' subject '_robot_record.mat'], 'reached', 'labels');