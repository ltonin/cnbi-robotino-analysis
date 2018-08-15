clearvars; clc;

subject = 'ai7';

datapath = 'analysis/robot/';
savedir  = 'analysis/robot/';

%% Loading target record data
load([datapath '/' subject '_robot_records.mat']); 


Rk = records.trial.Rk;
Ik = records.trial.Ik;
Ck = records.trial.Ck;
Xk = records.trial.Xk;
Dk = records.trial.Dk;

rIk = records.run.Ik;
rDk = records.run.Dk;

Runs = unique(Rk);
NumRuns = length(Runs);

Integrators = unique(Ik);
NumIntegrators = length(Integrators);

Targets = unique(Ck);
NumTargets = length(Targets);

NumTargetRuns = length(Ck)/NumRuns;

NumRunIntegrators = NumRuns/NumIntegrators;

%% Compute Total Accuracy per Integrator
AccuracyIntegrator = zeros(NumIntegrators, 1);
for iId = 1:NumIntegrators
    cindex = Ik == Integrators(iId);
    AccuracyIntegrator(iId) = sum(Xk(cindex))./sum(cindex);
end

%% Compute Total Accuracy per Run
AccuracyRun = zeros(NumRuns, 1);

for rId = 1:NumRuns
    cindex = Rk == Runs(rId);

    caccuracy = sum(Xk(cindex))./sum(cindex);
    AccuracyRun(rId) = caccuracy;
end

%% Compute accuracy per Target per Run
AccuracyTarget = zeros(NumTargets, NumRuns);
for rId = 1:NumRuns
    for tId = 1:NumTargets
        cindex = Ck == Targets(tId) & Rk == Runs(rId);
        AccuracyTarget(tId, rId) = sum(Xk(cindex))./sum(cindex);
    end
end



%% Plot
fig1 = figure;
fig_set_position(fig1, 'All');

NumRows = 3;
NumCols = 2;
ControlLb = {'discrete', 'continuous'};
TargetLb  = {'T1', 'T2', 'T3', 'T4', 'T5'};

% Total accuracy per integrator
subplot(NumRows, NumCols, 1);
boxplot(100*AccuracyRun, rIk, 'labels', ControlLb);
ylim([0 110]);
grid on;
ylabel('Accuracy [%]');
xlabel('Control');
title('Total accuracy per modality');

% Total accuracy per run
subplot(NumRows, NumCols, 2);
hold on;
for iId = 1:NumIntegrators
    plot(100*AccuracyRun(rIk == Integrators(iId)), '-o');
end
hold off;
ylim([0 110]);
set(gca, 'XTick', 1:NumRunIntegrators);
grid on;

changeDayId = find(diff(rDk))/2 + 0.7;

plot_vline(1, 'k', 'Day1');
for dId = 1:length(changeDayId)
    plot_vline(changeDayId(dId), 'k', ['Day ' num2str(dId+1)]);
end

legend(ControlLb, 'location', 'southeast');
ylabel('Accuracy [%]');
xlabel('Run');
title('Total accuracy per modality over runs');

% Accuracy per target per integrator
for iId = 1:NumIntegrators
    subplot(NumRows, NumCols, 2 + iId);
    boxplot(100*AccuracyTarget(:, rIk == Integrators(iId))', 1:5, 'labels', TargetLb)
    ylim([-10 110]);
    grid on;
    ylabel('Accuracy [%]');
    xlabel('Target');
    title(['Accuracy per target (' ControlLb{iId} ' control)']);
end

% Accuracy per target over run
for iId = 1:NumIntegrators
    subplot(NumRows, NumCols, 4 + iId)
   
    plot(100*AccuracyTarget(:, rIk == Integrators(iId))', 'o-');

    ylim([0 110]);
    set(gca, 'XTick', 1:NumRunIntegrators);
    grid on;    
    ylabel('Accuracy [%]');
    xlabel('Run');
    title(['Accuracy per target over runs (' ControlLb{iId} ' control)']);
    legend(TargetLb, 'location', 'southeast');
    
    changeDayId = find(diff(rDk))/2 + 0.7;

    plot_vline(1, 'k', 'Day1');
    for dId = 1:length(changeDayId)
        plot_vline(changeDayId(dId), 'k', ['Day ' num2str(dId+1)]);
    end
end



suptitle(['Subject: ' subject ' - Target accuracy'])





