clearvars; clc;

subject = 'ai7';
savedir     = 'analysis/robot';

% Create analysis directory
util_mkdir('./', savedir);

% Target - Reached results
Target(:, 1)   = [5 2 3 5 4 3 1 4 1 2];
Reached(:, 1)  = [1 1 1 1 1 1 0 1 1 1];
Target(:, 2)   = [2 5 4 2 5 1 3 3 1 4];
Reached(:, 2)  = [1 1 1 1 0 1 1 1 0 0];
Target(:, 3)   = [1 3 5 2 3 5 2 4 4 1];
Reached(:, 3)  = [0 1 1 1 1 1 0 1 1 0];
Target(:, 4)   = [2 4 3 3 1 2 1 5 5 4];
Reached(:, 4)  = [1 1 1 1 1 1 1 1 1 1];
Target(:, 5)   = [4 2 1 5 2 5 3 4 3 1];
Reached(:, 5)  = [1 1 0 1 0 1 1 1 1 1];
Target(:, 6)   = [3 4 2 5 1 4 3 2 5 1];
Reached(:, 6)  = [1 1 1 1 0 1 1 1 1 0];
Target(:, 7)   = [1 5 1 2 2 3 5 3 4 4];
Reached(:, 7)  = [1 0 1 1 1 1 1 1 1 1];
Target(:, 8)   = [1 1 2 5 3 4 5 3 4 2];
Reached(:, 8)  = [1 1 1 1 1 1 0 1 1 0];

[NumTargets, NumRuns] = size(Target);

% Integrator type
IntegratorType = [2 1 1 2 2 1 1 2];
IntegratorName = {'ema', 'dynamic'};

% Day
DayId = [1 1 2 2 2 2 3 3];

records.trial.Rk = reshape(repmat(1:NumRuns, [NumTargets 1]), NumRuns*NumTargets, 1);
records.trial.Ck = reshape(Target, numel(Target), 1);
records.trial.Xk = reshape(Reached, numel(Reached), 1);
records.trial.Ik = reshape(repmat(IntegratorType, [NumTargets 1]), NumRuns*NumTargets, 1);
records.trial.Il = IntegratorName;
records.trial.Dk = reshape(repmat(DayId, [NumTargets 1]), NumRuns*NumTargets, 1);
records.trial.Tk = (1:NumRuns*NumTargets)';

records.run.Rk = 1:NumRuns;
records.run.Ik = IntegratorType;
records.run.Dk = DayId;

save([savedir '/' subject '_robot_records.mat'], 'records');