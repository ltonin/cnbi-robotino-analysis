clearvars; clc;

subject = 'aj1';

pattern  = [subject '*.online.mi.mi_bhbf.*.mobile'];
datapath = 'analysis/robot/tracking/';
savedir  = 'analysis/robot/tracking/';


IntegratorName = {'ema', 'dynamic'};
TargetName   = {'Target1', 'Target2', 'Target3', 'Target4', 'Target5'};


files = util_getfile(datapath, '.mat', pattern);


%% Concatenate all files
util_bdisp('[io] - Concatenate tracking data');

[tracking, labels] = cnbirob_concatenate_tracking_data(files, 'tracking');

Integrators = unique(labels.Ik);
NumIntegrators = length(Integrators);
Runs = unique(labels.Rk);
NumRuns = length(Runs);
NumSamples = length(tracking);
Trials = unique(labels.Tk);
NumTrials = length(Trials);
Days = unique(labels.Dk);
NumDays = length(Days);

%% Loading target record data
load(['analysis/robot/' subject '_robot_records.mat']); 
Xk = records.trial.Xk;

%% Plot

colors = [     0    0.4470    0.7410
          0.8500    0.3250    0.0980
          0.9290    0.6940    0.1250
          0.4940    0.1840    0.5560
          0.4660    0.6740    0.1880];

fig = figure;
fig_set_position(fig, 'All');
for dId = 1:NumDays
    
    for iId = 1:NumIntegrators
        subplot(NumIntegrators, NumDays, dId + NumDays*(iId-1));
        
        hold on;
        for tId = 1:NumTrials
            if Xk(tId) == 0
                continue;
            end
            cindex = labels.Dk == Days(dId) & labels.Ik == Integrators(iId) & labels.Tk == Trials(tId);
            plot(tracking(cindex, 1), tracking(cindex, 2), 'color', colors(unique(labels.Ck(cindex)), :));
            
            
        end
        hold off;
        cnbirob_util_draw_field(30, 'k');
        xlim([0 900]);
        ylim([0 600]);
        axis equal
        grid on;
    end
end
            




