clearvars; clc;

subject = 'aj7';
savedir     = 'analysis/robot';

% Create analysis directory
util_mkdir('./', savedir);

% Target - Reached results
Target(:, 1)   = [5 4 4 3 3 1 2 1 2 5];
Reached(:, 1)  = [1 1 1 1 1 1 1 1 1 1];
Target(:, 2)   = [1 2 4 2 1 3 3 5 5 4];
Reached(:, 2)  = [1 1 1 1 1 1 1 1 1 1];
Target(:, 3)   = [5 3 5 1 2 1 4 4 3 2];
Reached(:, 3)  = [1 1 1 1 1 1 1 1 1 1];
Target(:, 4)   = [3 2 4 1 4 2 3 5 1 5];
Reached(:, 4)  = [1 1 1 1 1 1 1 1 1 1];
Target(:, 5)   = [4 2 1 3 4 5 1 3 2 5];
Reached(:, 5)  = [1 1 1 1 1 1 1 1 1 1];
Target(:, 6)   = [2 2 4 5 3 3 1 1 4 5];
Reached(:, 6)  = [1 1 1 0 1 1 1 1 1 1];

[NumTargets, NumRuns] = size(Target);

% Integrator type
IntegratorType = [1 2 2 2 1 1];
IntegratorName = {'ema', 'dynamic'};

% Day
DayId = [2 2 3 3 3 3];

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
