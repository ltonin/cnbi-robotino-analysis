clearvars; clc;

subject = 'ai8';
savedir     = 'analysis/robot';

% Create analysis directory
util_mkdir('./', savedir);

% Target - Reached results
Target(:, 1)   = [3 2 5 4 5 1 2 4 1 3];
Reached(:, 1)  = [0 1 1 1 1 0 0 0 0 0];
Target(:, 2)   = [2 3 5 3 5 2 4 1 4 1];
Reached(:, 2)  = [1 1 0 1 1 0 1 0 1 0];

[NumTargets, NumRuns] = size(Target);

% Integrator type
IntegratorType = [1 2];
IntegratorName = {'ema', 'dynamic'};

% Day
DayId = [3 3];

records.trial.Rk = reshape(repmat(1:NumRuns, [NumTargets 1]), NumRuns*NumTargets, 1);
records.trial.Tk = reshape(Target, numel(Target), 1);
records.trial.Xk = reshape(Reached, numel(Reached), 1);
records.trial.Ik = reshape(repmat(IntegratorType, [NumTargets 1]), NumRuns*NumTargets, 1);
records.trial.Il = IntegratorName;
records.trial.Dk = reshape(repmat(DayId, [NumTargets 1]), NumRuns*NumTargets, 1);

records.run.Rk = 1:NumRuns;
records.run.Ik = IntegratorType;
records.run.Dk = DayId;

save([savedir '/' subject '_robot_records.mat'], 'records');
