clearvars; clc;

subject = 'aj1';

pattern = '_bci_probability.mat';
path    = 'analysis/bci/';
figdir     = 'figure/';
Ts = 1/16;
TotalTime = 20;
alpha = 0.03;
t = 0:Ts:TotalTime - Ts;

TaskEvent = 773;
FixEvent  = 786;

AbsoluteThreshold = 0.7;
threshold = AbsoluteThreshold - 0.5;


%% Load probability
filename = [path subject pattern]; 
util_bdisp(['[io] - Importing bci probability for subject: ' subject]); 

% Loading data
data = load(filename);

%% Exponential smoothing transfer function
z = tf('z', Ts); 
H = alpha*z/(z + (alpha -1));

%% Data distributions
Ck = data.labels.sample.Ck;
Tk = data.labels.sample.Tk;
Fk = data.labels.sample.Fk;

TaskDistribution = data.probability.raw(Ck == TaskEvent) - 0.5;
RestDistribution = data.probability.raw(Fk == FixEvent) - 0.5;

%% Getting random sample from distributions
util_bdisp('[proc] - Getting random samples'); 
rnd_task_idx = randi(length(t), length(t), 1); 
rnd_fix_idx  = randi(length(t), length(t), 1); 
task_distribution  = TaskDistribution(rnd_task_idx);
rest_distribution  = RestDistribution(rnd_fix_idx);

%% New framework simulation
util_bdisp('[proc] - Dynamical system framework'); 
support.dt = 0.0625;
support.chi = 1.0;
support.phi = 0.6;
support.forcefree.omega  = 0.1;
support.forcefree.psi    = 0.5;
support.forcebci = [];

DSTask = cnbirob_dynamic_response(task_distribution, support) - 0.5;
DSRest = cnbirob_dynamic_response(rest_distribution, support) - 0.5;
    
%% Random simulation
NSimulations = 10;
util_bdisp(['[proc] - Simulation for the two frameworks (N=' num2str(NSimulations) ')']); 
ExpTaskSim = zeros(length(t), NSimulations);
ExpRestSim = zeros(length(t), NSimulations);
DSTaskSim  = zeros(length(t), NSimulations);
DSRestSim  = zeros(length(t), NSimulations);
for i = 1:NSimulations
    sim_rnd_task_idx = randi(length(t), length(t), 1);
    ExpTaskSim(:, i) = lsim(H, TaskDistribution(sim_rnd_task_idx), t);
    DSTaskSim(:, i)  = cnbirob_dynamic_response(TaskDistribution(sim_rnd_task_idx), support) - 0.5;
    
    sim_rnd_fix_idx  = randi(length(t), length(t), 1);
    ExpRestSim(:, i) = lsim(H, RestDistribution(sim_rnd_fix_idx), t);
    DSRestSim(:, i)  = cnbirob_dynamic_response(RestDistribution(sim_rnd_fix_idx), support) - 0.5;
end

%% First crossing threshold
util_bdisp('[proc] - Crossing thresholds for the two frameworks'); 

ExpFirstCrossingRest = nan(NSimulations, 1);
ExpFirstCrossingTask = nan(NSimulations, 1);
DSFirstCrossingRest  = nan(NSimulations, 1);
DSFirstCrossingTask  = nan(NSimulations, 1);

for i = 1:NSimulations
    % Exponential
    cfirstcross_task = find(ExpTaskSim(:, i) >= threshold, 1, 'first');
    if isempty(cfirstcross_task) == false
     ExpFirstCrossingTask(i) = cfirstcross_task;
    end
    
    cfirstcross_rest = find(ExpRestSim(:, i) >= threshold, 1, 'first');
    if isempty(cfirstcross_rest) == false
        ExpFirstCrossingRest(i) = cfirstcross_rest;
    end
    
    % Dynamical system
    cfirstcross_task = find(DSTaskSim(:, i) >= threshold, 1, 'first');
    if isempty(cfirstcross_task) == false
     DSFirstCrossingTask(i) = cfirstcross_task;
    end
    
    cfirstcross_rest = find(DSRestSim(:, i) >= threshold, 1, 'first');
    if isempty(cfirstcross_rest) == false
        DSFirstCrossingRest(i) = cfirstcross_rest;
    end
end

%% Average crossing threshold
ExpRestCrossingAvg = nanmean(t(ExpFirstCrossingRest(isnan(ExpFirstCrossingRest) == false)));
ExpRestCrossingStd = nanstd(t(ExpFirstCrossingRest(isnan(ExpFirstCrossingRest) == false)));

ExpTaskCrossingAvg = nanmean(t(ExpFirstCrossingTask(isnan(ExpFirstCrossingTask) == false)));
ExpTaskCrossingStd = nanstd(t(ExpFirstCrossingTask(isnan(ExpFirstCrossingTask) == false)));

DSRestCrossingAvg = nanmean(t(DSFirstCrossingRest(isnan(DSFirstCrossingRest) == false)));
DSRestCrossingStd = nanstd(t(DSFirstCrossingRest(isnan(DSFirstCrossingRest) == false)));

DSTaskCrossingAvg = nanmean(t(DSFirstCrossingTask(isnan(DSFirstCrossingTask) == false)));
DSTaskCrossingStd = nanstd(t(DSFirstCrossingTask(isnan(DSFirstCrossingTask) == false)));

ExpTaskCrossingPerc = 100*sum(isnan(ExpFirstCrossingTask) == false)./length(ExpFirstCrossingTask);
ExpRestCrossingPerc = 100*sum(isnan(ExpFirstCrossingRest) == false)./length(ExpFirstCrossingRest);
DSTaskCrossingPerc = 100*sum(isnan(DSFirstCrossingTask) == false)./length(DSFirstCrossingTask);
DSRestCrossingPerc = 100*sum(isnan(DSFirstCrossingRest) == false)./length(DSFirstCrossingRest);

util_bdisp(['[out] + Exponential framework - Percentage crossing threshold (' num2str(threshold) '):']);
disp(['      |- During task: ' num2str(ExpTaskCrossingPerc, 3) '%']);
disp(['      |- During rest: ' num2str(ExpRestCrossingPerc, 3) '%']);

util_bdisp(['[out] + Dynamical system framework - Percentage crossing threshold (' num2str(threshold) '):']);
disp(['      |- During task: ' num2str(DSTaskCrossingPerc, 3) '%']);
disp(['      |- During rest: ' num2str(DSRestCrossingPerc, 3) '%']);

util_bdisp(['[out] + Exponential framework - Average crossing threshold (' num2str(threshold) '):']);
disp(['      |- During task: ' num2str(ExpTaskCrossingAvg, 3) ' +/- ' num2str(ExpTaskCrossingStd) ' s']);
disp(['      |- During rest: ' num2str(ExpRestCrossingAvg, 3) ' +/- ' num2str(ExpRestCrossingStd) ' s']);

util_bdisp(['[out] + Dynamical system framework - Average crossing threshold (' num2str(threshold) '):']);
disp(['      |- During task: ' num2str(DSTaskCrossingAvg, 3) ' +/- ' num2str(DSTaskCrossingStd) ' s']);
disp(['      |- During rest: ' num2str(DSRestCrossingAvg, 3) ' +/- ' num2str(DSRestCrossingStd) ' s']);
      

%% Plot responses
fig = figure;
fig_set_position(fig, 'All');

% Exponential
subplot(2, 3, 1);
lsim(H, task_distribution, t);
ylim([-0.6 0.6]);
plot_hline(threshold, 'r');
plot_hline(-threshold, 'r');
ytick = get(gca, 'YTick');
yticklb =0:1/(length(ytick)-1):1;
set(gca, 'YTickLabel', num2str(yticklb')); 
title('Task input - Exponential');

% Dynamical system
subplot(2, 3, 2);
plot(t, DSTask);
ylim([-0.6 0.6]);
plot_hline(threshold, 'r');
plot_hline(-threshold, 'r');
ytick = get(gca, 'YTick');
yticklb =0:1/(length(ytick)-1):1;
set(gca, 'YTickLabel', num2str(yticklb')); 
title('Task input - Dynamical');

% Distribution
subplot(2, 3, 3);
hold on;
xvalues   = -0.5:0.001:0.5;
binranges = -0.5:0.1:0.5;
bincount = histc(task_distribution, binranges);
pd = fitdist(task_distribution,'Kernel','Kernel','epanechnikov', 'BandWidth', 0.05);
ypdf = pdf(pd, xvalues);
bar(binranges, bincount, 'histc');
plot(xvalues, (max(bincount)./max(ypdf))*ypdf, 'r', 'LineWidth', 3);
xlim([-0.5 0.5]);
ylim([0 max(bincount)+10]);
hold off
grid on;
title('Task distribution');

% Exponential
subplot(2, 3, 4);
lsim(H, rest_distribution, t);
hold off;
ylim([-0.6 0.6]);
plot_hline(threshold, 'r');
plot_hline(-threshold, 'r');
title('Rest input - Exponential');

% Dynamical system
subplot(2, 3, 5);
plot(t, DSRest);
ylim([-0.6 0.6]);
plot_hline(threshold, 'r');
plot_hline(-threshold, 'r');
title('Rest input - Dynamical');

% Distribution
subplot(2, 3, 6);
hold on;
xvalues   = -0.5:0.001:0.5;
binranges = -0.5:0.1:0.5;
bincount = histc(rest_distribution, binranges);
pd = fitdist(rest_distribution,'Kernel','Kernel','epanechnikov', 'BandWidth', 0.05);
ypdf = pdf(pd, xvalues);
bar(binranges, bincount, 'histc');
plot(xvalues, (max(bincount)./max(ypdf))*ypdf, 'r', 'LineWidth', 3);
xlim([-0.5 0.5]);
ylim([0 max(bincount)+10]);
hold off
grid on;
title('Fixation distribution');

% %% Save figure
% filename = [figdir '/' subject '_control_framework.pdf'];
% util_bdisp(['Saving figure in ' filename]);
% fig_figure2pdf(fig, filename);