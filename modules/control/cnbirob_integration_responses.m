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
FixDistribution = data.probability.raw(Fk == FixEvent) - 0.5;

%% Plot responses
fig = figure;
fig_set_position(fig, 'All');

subplot(2, 2, 1);
rnd_task_idx = randi(length(t), length(t), 1);
lsim(H, TaskDistribution(rnd_task_idx), t);
ylim([-0.5 0.5]);
plot_hline(threshold, 'r');
plot_hline(-threshold, 'r');
ytick = get(gca, 'YTick');
yticklb =0:1/(length(ytick)-1):1;
set(gca, 'YTickLabel', num2str(yticklb')); 
title('Task input');

subplot(2, 2, 2);
hold on;
xvalues   = -0.5:0.001:0.5;
binranges = -0.5:0.1:0.5;
bincount = histc(TaskDistribution(rnd_task_idx), binranges);
pd = fitdist(TaskDistribution(rnd_task_idx),'Kernel','Kernel','epanechnikov', 'BandWidth', 0.05);
ypdf = pdf(pd, xvalues);
bar(binranges, bincount, 'histc');
plot(xvalues, (max(bincount)./max(ypdf))*ypdf, 'r', 'LineWidth', 3);
xlim([-0.5 0.5]);
ylim([0 max(bincount)+10]);
hold off
grid on;
title('Task distribution');

subplot(2, 2, 3);
rnd_fix_idx = randi(length(t), length(t), 1);
lsim(H, FixDistribution(rnd_fix_idx), t);
ylim([-0.5 0.5]);
plot_hline(threshold, 'r');
plot_hline(-threshold, 'r');
title('Fixation input');

subplot(2, 2, 4);
hold on;
xvalues   = -0.5:0.001:0.5;
binranges = -0.5:0.1:0.5;
bincount = histc(FixDistribution(rnd_fix_idx), binranges);
pd = fitdist(FixDistribution(rnd_fix_idx),'Kernel','Kernel','epanechnikov', 'BandWidth', 0.05);
ypdf = pdf(pd, xvalues);
bar(binranges, bincount, 'histc');
plot(xvalues, (max(bincount)./max(ypdf))*ypdf, 'r', 'LineWidth', 3);
xlim([-0.5 0.5]);
ylim([0 max(bincount)+10]);
hold off
grid on;
title('Fixation distribution');

%% Save figure
filename = [figdir '/' subject '_control_exponential_smoothing.pdf'];
util_bdisp(['Saving figure in ' filename]);
fig_figure2pdf(fig, filename);