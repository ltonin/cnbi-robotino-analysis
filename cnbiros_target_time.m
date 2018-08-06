clearvars; clc;

subject = 'aj1';

pattern  = [subject '*.online.mi.mi_bhbf.*.mobile'];
datapath = 'analysis/robot/odometry/';
savedir  = 'analysis/robot/odometry/';


IntegratorName = {'ema', 'dynamic'};
Targets      = [26113 26114 26115 26116 26117];
TargetName   = {'Target1', 'Target2', 'Target3', 'Target4', 'Target5'};
ResumeEvent  = 25352;
CmdEvent     = [25348 25349];
CmdLabel     = {'Right', 'Left'};
NumTargets   = length(Targets);
SampleRate   = 512;

files = util_getfile(datapath, '.mat', pattern);

%% Concatenate all files
util_bdisp('[io] - Concatenate data and events');
[odometry, events, labels] = cnbirob_concatenate_data(files, 'odometry');

Integrators = unique(labels.Ik);
NumIntegrators = length(Integrators);
Runs = unique(labels.Rk);
NumRuns = length(Runs);
NumSamples = length(odometry);

%% Create events labels
util_bdisp('[proc] - Extract events')
[~, TargetEvt] = proc_get_event2(Targets, NumSamples, events.POS, events.TYP, events.DUR);

%% Extract trials

NumTrials = length(TargetEvt.TYP);
Rk = zeros(NumTrials, 1);
Ik = zeros(NumTrials, 1);
Dk = zeros(NumTrials, 1);
Tk = zeros(NumTrials, 1);
Time = zeros(NumTrials, 1);

NumTrialRun = NumTrials/NumRuns;

for trId = 1:NumTrials
    cpos = TargetEvt.POS(trId);
    
    Time(trId) = TargetEvt.DUR(trId);
    
    Rk(trId) = labels.Rk(cpos);
    Ik(trId) = labels.Ik(cpos);
    Dk(trId) = labels.Dk(cpos);
    Tk(trId) = find(Targets == TargetEvt.TYP(trId));
    
end

rIk = Ik(1:NumTrialRun:end);
rDk = Dk(1:NumTrialRun:end);

NumRunIntegrators = NumRuns/NumIntegrators;

%% Loading target record data
load(['analysis/robot/' subject '_robot_records.mat']); 
Xk = records.trial.Xk;

%% Compute Total Time per Integrator
TimeIntegrator = zeros(NumIntegrators, 1);
for iId = 1:NumIntegrators
    cindex = Ik == Integrators(iId) & Xk;
    TimeIntegrator(iId) = sum(Time(cindex))./sum(cindex);
end

%% Compute Total Time per Run
TimeRun = zeros(NumRuns, 1);

for rId = 1:NumRuns
    cindex = Rk == Runs(rId) & Xk;

    ctime = mean(Time(cindex));
    TimeRun(rId) = ctime;
end

%% Compute time per Target per Run
TimeTarget = zeros(NumTargets, NumRuns);
for rId = 1:NumRuns
    for tId = 1:NumTargets
        cindex = Tk == tId & Rk == Runs(rId) & Xk;
        TimeTarget(tId, rId) = mean(Time(cindex));
    end
end


%% Plot
fig1 = figure;
fig_set_position(fig1, 'All');

NumRows = 3;
NumCols = 2;
ControlLb = {'discrete', 'continuous'};
TargetLb  = {'T1', 'T2', 'T3', 'T4', 'T5'};

% Total time per integrator
subplot(NumRows, NumCols, 1);
boxplot(TimeRun/SampleRate, rIk, 'labels', ControlLb);
ylim([20 50]);
grid on;
ylabel('Time [s]');
xlabel('Control');
title('Average time per modality');

% Total time per run
subplot(NumRows, NumCols, 2);
hold on;
for iId = 1:NumIntegrators
    plot(TimeRun(rIk == Integrators(iId))/SampleRate, '-o');
end
hold off;
set(gca, 'XTick', 1:NumRunIntegrators);
grid on;
ylim([20 50]);
changeDayId = find(diff(rDk))/2 + 0.7;

plot_vline(1, 'k', 'Day1');
for dId = 1:length(changeDayId)
    plot_vline(changeDayId(dId), 'k', ['Day ' num2str(dId+1)]);
end

legend(ControlLb, 'location', 'southeast');
ylabel('Time [s]');
xlabel('Run');
title('Average time per modality over runs');

% Time per target per integrator
for iId = 1:NumIntegrators
    subplot(NumRows, NumCols, 2 + iId);
    boxplot(TimeTarget(:, rIk == Integrators(iId))'/SampleRate, 1:5, 'labels', TargetLb)
    grid on;
    ylim([10 90]);
    ylabel('Time [s]');
    xlabel('Target');
    title(['Time per target (' ControlLb{iId} ' control)']);
end

% Time per target over run
for iId = 1:NumIntegrators
    subplot(NumRows, NumCols, 4 + iId)
   
    plot(TimeTarget(:, rIk == Integrators(iId))'/SampleRate, 'o-');

    set(gca, 'XTick', 1:NumRunIntegrators);
    ylim([10 90]);
    grid on;    
    ylabel('Time [s]');
    xlabel('Run');
    title(['Time per target over runs (' ControlLb{iId} ' control)']);
    legend(TargetLb, 'location', 'southeast');
    
    changeDayId = find(diff(rDk))/2 + 0.7;

    plot_vline(1, 'k', 'Day1');
    for dId = 1:length(changeDayId)
        plot_vline(changeDayId(dId), 'k', ['Day ' num2str(dId+1)]);
    end
end



suptitle(['Subject: ' subject ' - Target time'])

