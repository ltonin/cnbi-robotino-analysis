clearvars;

subject = 'aj3';
savedir = 'analysis/robot/record/';

% Create analysis directory
util_mkdir('./', savedir);

% Target - Reached results
Target(:, 1)   = [5 3 2 5 4 1 1 4 2 3];
Reached(:, 1)  = [1 1 1 0 1 1 0 1 1 1];
Target(:, 2)   = [5 4 2 4 5 3 3 1 1 2];
Reached(:, 2)  = [1 1 1 1 1 1 1 1 1 1];
Target(:, 3)   = [3 4 1 3 5 2 2 5 1 4];
Reached(:, 3)  = [1 1 0 1 0 0 0 0 1 1];
Target(:, 4)   = [5 1 4 5 1 2 3 3 2 4];
Reached(:, 4)  = [1 1 1 1 0 1 1 1 1 1];
Target(:, 5)   = [3 2 3 5 4 1 5 4 2 1];
Reached(:, 5)  = [1 1 1 1 1 1 1 1 1 1];
Target(:, 6)   = [1 1 4 4 2 2 3 5 5 3];
Reached(:, 6)  = [0 0 1 1 1 1 1 1 1 1];
Target(:, 7)   = [2 5 4 1 3 4 3 1 2 5];
Reached(:, 7)  = [1 1 1 1 1 1 1 1 1 1];
Target(:, 8)   = [5 5 4 2 4 3 3 2 1 1];
Reached(:, 8)  = [1 1 1 1 1 1 1 1 1 1];
Target(:, 9)   = [3 2 4 5 3 2 5 4 1 1];
Reached(:, 9)  = [1 1 1 1 1 0 1 0 0 1];
Target(:, 10)  = [5 4 1 3 5 2 2 3 1 4];
Reached(:, 10) = [1 1 0 1 1 1 1 0 1 1];

[NumTargets, NumRuns] = size(Target);

% Integrator type
IntegratorType = [2 1 2 1 2 1 2 1 2 1];
IntegratorName = {'ema', 'dynamic'};

% Day
DayId = [1 1 2 2 2 2 3 3 3 3];

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
