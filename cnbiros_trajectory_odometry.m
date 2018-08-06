%% NOT WORKING -> IT NEEDS TRANSFORMATION FROM INITIAL POSE

clearvars; clc;

subject = 'aj1';

pattern  = [subject '*.online.mi.mi_bhbf.*.mobile'];
datapath = 'analysis/robot/odometry/';
savedir  = 'analysis/robot/odometry/';


IntegratorName = {'ema', 'dynamic'};
TargetEvent  = [26113 26114 26115 26116 26117];
TargetName   = {'Target1', 'Target2', 'Target3', 'Target4', 'Target5'};
ResumeEvent  = 25352;
CmdEvent     = [25348 25349];
CmdLabel     = {'Right', 'Left'};
NumTargets   = length(TargetEvent);

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
[TargetLb, TargetEvt] = proc_get_event2(TargetEvent, NumSamples, events.POS, events.TYP, events.DUR);

%% Extract trials

Rk = labels.Rk;
Ik = labels.Ik;
Dk = labels.Dk;
Ck = zeros(NumSamples, 1);
Tk = zeros(NumSamples, 1);

NumTrials = length(TargetEvt.TYP);
for trId = 1:NumTrials
    
    cstart = TargetEvt.POS(trId);
    cstop  = cstart + TargetEvt.DUR(trId) - 1;
    
    Ck(cstart:cstop) = find(TargetEvent == TargetEvt.TYP(trId), 1);
    Tk(cstart:cstop) = trId;
    
end

%% TMP PLOT

fig1 = figure;
fig_set_position(fig1, 'Top');

for iId = 1:NumIntegrators
    
    subplot(1, NumIntegrators, iId);
    
    hold on;
    for trId = 1:NumTrials

        cindex = Ik == Integrators(iId) & Tk == trId & Dk == 2 & Ck == 3;

        if(sum(cindex) == 0)
            continue;
        end
        
        cx = odometry(cindex, 2);
        cy = -odometry(cindex, 1);

        
        
%         cx = cx - cx(1);
%         cy = cy - cy(1);

        
        plot(cx, cy, 'o');
        plot(cx(1), cy(1), 'sk', 'MarkerSize', 10);
        
    end
    hold off;
end
