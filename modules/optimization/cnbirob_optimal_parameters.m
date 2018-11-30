clc; clearvars; 
subject = 'ai7';

datapath = ['analysis/bci/' subject '_bci_probability.mat'];
savedir  = './analysis/optimization/';
figdir   = './figure/';

util_mkdir(pwd, savedir);

%% Default integration parameters
support.forcebci.coeff= [0 6.4 0 0.4 0];    % as in paper
support.dt= 1/16;                           % integration time (16Hz by default)
support.phi= 0.5;                           % contribution of fFREE compared to fBCI
support.chi= 2;                             % to eliminate phi

%% Default optimization parameters
Psi      = 0:0.05:1;
Omega    = 0:0.025:0.5;
NumPsi   = length(Psi);
NumOmega = length(Omega);

Thresholds = [0.0 1.0];     % for both feet (771) and both hands (773)

%% Loading data
util_bdisp(['[io] - Loading probabilities for subject: ' subject]);
data = load(datapath);

%% Extracting useful info
util_bdisp('[proc] - Extracting useful informations');

% Probabilities
probs = data.probability.raw(:, 1);

% Labels (per sample)
Ck = data.labels.sample.Ck;
Rk = data.labels.sample.Rk;
Fk = data.labels.sample.Fk;
Tk = data.labels.sample.Tk;

% Fixation and continuous feedback events
FixPos  = data.events.POS(data.events.TYP == 786);
FixDur  = data.events.DUR(data.events.TYP == 786);
TaskDur = data.events.DUR(data.events.TYP == 781);

Classes     = setdiff(unique(Ck), 0); % Removing the zeros
NumClasses  = length(Classes);
Runs        = setdiff(unique(Rk), 0); % Removing the zeros
NumRuns     = length(Runs);
Trials      = setdiff(unique(Tk), 0); % Removing the zeros
NumTrials   = length(Trials);

% Computing run label per trial
tRk = zeros(NumTrials, 1);
for trId = 1:NumTrials
    cindex = Tk == Trials(trId);
    tRk(trId) = unique(Rk(Tk == Trials(trId)));
end

%% Integration with different psi and omega per each trial
util_bdisp('[proc] - Integration for different psi and omega');

PerfRest = zeros(NumPsi, NumOmega, NumTrials);
TimeRest = nan(NumPsi, NumOmega, NumTrials);
PerfTask = zeros(NumPsi, NumOmega, NumTrials);
TimeTask = nan(NumPsi, NumOmega, NumTrials);
for trId = 1:NumTrials
    util_disp_progress(trId, NumTrials);
    % Get samples index for task and current correct task class
    cindex_task = Tk == Trials(trId);
    cclass = unique(Ck(cindex_task));
    [~, cclassidx] = ismember(cclass, Classes);
    
    % Get samples index for rest (fixation)
    cstart = FixPos(trId);
    cstop  = cstart + FixDur(trId) - 1;
    cindex_rest = cstart:cstop;
     
    % Get raw probability for task and rest
    rpp_task = probs(cindex_task);
    rpp_rest = probs(cindex_rest);
    
    % Integrate for each psi and omega
    for psId = 1:NumPsi
        for omId = 1:NumOmega
            support.forcefree.psi = Psi(psId);
            support.forcefree.omega = Omega(omId);
            
            % Integrate task probabilities and check crossing thresholds
            ipp_task = ctrl_integrator_dynamic_response(rpp_task, support);
            [crossed_task, index_task, correct_task] = ctrl_crossing_threshold(ipp_task, Thresholds, cclassidx);
            
            % Integrate rest probabilities and check crossing thresholds index
            ipp_rest = ctrl_integrator_dynamic_response(rpp_rest, support);
            [crossed_rest, index_rest] = ctrl_crossing_threshold(ipp_rest, Thresholds);

            % Save values for task and rest
            PerfTask(psId, omId, trId) = correct_task;
            TimeTask(psId, omId, trId) = index_task*support.dt;
            
            PerfRest(psId, omId, trId) = crossed_rest;
            TimeRest(psId, omId, trId) = index_rest*support.dt;
            
        end
    end
end

%% Average task and time per run
util_bdisp('[proc] - Computing average metrics');
PerfTaskRun = zeros(NumPsi, NumOmega, NumRuns);
PerfRestRun = zeros(NumPsi, NumOmega, NumRuns);
TimeTaskRun = zeros(NumPsi, NumOmega, NumRuns);
TimeRestRun = zeros(NumPsi, NumOmega, NumRuns);
DurTaskRun  = zeros(NumPsi, NumOmega, NumRuns);
DurRestRun  = zeros(NumPsi, NumOmega, NumRuns);

% Compute percentage of time (with respect to the original duration)
DurTask = TimeTask./(support.dt.*(permute(repmat(TaskDur, [1, NumPsi, NumOmega]), [2 3 1])));
DurRest = TimeRest./(support.dt.*(permute(repmat(FixDur,  [1, NumPsi, NumOmega]), [2 3 1])));

for rId = 1:NumRuns
   PerfTaskRun(:, :, rId) = nansum(PerfTask(:, :, tRk == rId), 3)./sum(tRk == rId); 
   TimeTaskRun(:, :, rId) = nanmean(TimeTask(:, :, tRk == rId), 3);
   DurTaskRun(:, :, rId)  = nanmean(DurTask(:, :, tRk == rId), 3);
   PerfRestRun(:, :, rId) = nansum(PerfRest(:, :, tRk == rId), 3)./sum(tRk == rId); 
   TimeRestRun(:, :, rId) = nanmean(TimeRest(:, :, tRk == rId), 3);
   DurRestRun(:, :, rId)  = nanmean(DurRest(:, :, tRk == rId), 3);
end

% Getting the grand average (all over the runs)
PerfTaskAvg = nansum(PerfTaskRun, 3)./NumRuns;
TimeTaskAvg = nanmean(TimeTaskRun, 3);
DurTaskAvg  = nanmean(DurTaskRun, 3);

PerfRestAvg = nansum(PerfRestRun, 3)./NumRuns;
TimeRestAvg = nanmean(TimeRestRun, 3);
DurRestAvg  = nanmean(DurRestRun, 3);

% "Cost function" between task and rest
CostPerfRun = (PerfTaskRun + (1-PerfRestRun))./2;
CostPerfAvg = mean(CostPerfRun, 3);

%% Saving data
optimization.events = data.events;
optimization.labels = data.labels;
optimization.labels.trial.Rk = tRk;

optimization.parameters.forcebci        = support.forcebci;
optimization.parameters.chi             = support.chi;
optimization.parameters.dt              = support.dt;
optimization.parameters.phi             = support.phi;
optimization.parameters.forcefree.psi   = Psi;
optimization.parameters.forcefree.omega = Omega;
optimization.parameters.thresholds      = Thresholds;

optimization.accuracy.task.trial = PerfTask;
optimization.accuracy.rest.trial = PerfRest;
optimization.accuracy.task.run   = PerfTaskRun;
optimization.accuracy.rest.run   = PerfRestRun;
optimization.accuracy.task.avg   = PerfTaskAvg;
optimization.accuracy.rest.avg   = PerfRestAvg;

optimization.time.task.trial = TimeTask;
optimization.time.rest.trial = TimeRest;
optimization.time.task.run   = TimeTaskRun;
optimization.time.rest.run   = TimeRestRun;
optimization.time.task.avg   = TimeTaskAvg;
optimization.time.rest.avg   = TimeRestAvg;

optimization.duration.task.trial = DurTask;
optimization.duration.rest.trial = DurRest;
optimization.duration.task.run   = DurTaskRun;
optimization.duration.rest.run   = DurRestRun;
optimization.duration.task.avg   = DurTaskAvg;
optimization.duration.rest.avg   = DurRestAvg;

optimization.cost.run   = CostPerfRun;
optimization.cost.avg   = CostPerfAvg;


dfilename = [savedir '/' subject '_control_optimization.mat'];
util_bdisp(['[out] - Saving data in: ' dfilename]);
save(dfilename, 'optimization'); 

%% Figure - Average accuracy/duration maps
fig1 = figure;
fig_set_position(fig1, 'All');

NumRows = 2;
NumCols = 3;

subplot(NumRows, NumCols, 1); 
imagesc(PerfTaskAvg, [0 1]);  
title('Task correct crossing threshold [%]'); 
xlabel('omega'); 
ylabel('psi'); 
set(gca, 'XTick', 1:2:NumOmega, 'XTickLabel', Omega(1:2:end)); 
set(gca, 'YTick', 1:NumPsi, 'YTickLabel', Psi); 

subplot(NumRows, NumCols, 2); 
imagesc(PerfRestAvg, [0 1]); 
title('Rest crossing threshold [%]'); 
xlabel('omega'); 
ylabel('psi'); 
set(gca, 'XTick', 1:2:NumOmega, 'XTickLabel', Omega(1:2:end)); 
set(gca, 'YTick', 1:NumPsi, 'YTickLabel', Psi);

subplot(NumRows, NumCols, 3); 
imagesc(CostPerfAvg); 
title('''Cost map'''); 
xlabel('omega'); 
ylabel('psi'); 
set(gca, 'XTick', 1:2:NumOmega, 'XTickLabel', Omega(1:2:end)); 
set(gca, 'YTick', 1:NumPsi, 'YTickLabel', Psi);

subplot(NumRows, NumCols, 4); 
imagesc(DurTaskAvg, [0 1]);  
title('Task duration [%]'); 
xlabel('omega'); 
ylabel('psi'); 
set(gca, 'XTick', 1:2:NumOmega, 'XTickLabel', Omega(1:2:end)); 
set(gca, 'YTick', 1:NumPsi, 'YTickLabel', Psi); 

subplot(NumRows, NumCols, 5); 
imagesc(DurRestAvg); 
title('Rest duration [%]'); 
xlabel('omega'); 
ylabel('psi'); 
set(gca, 'XTick', 1:2:NumOmega, 'XTickLabel', Omega(1:2:end));
set(gca, 'YTick', 1:NumPsi, 'YTickLabel', Psi);

suptitle([subject ' - Accuracy/Duration maps']);

%% Figure - Per run cost maps
fig2 = figure;
fig_set_position(fig2, 'Top');
NumRows = 2;
NumCols = ceil(NumRuns/NumRows);

for rId = 1:NumRuns
    subplot(NumRows, NumCols, rId);
    imagesc(CostPerfRun(:, :, rId), [0 1]);  
    title(['Run ' num2str(rId)]); 
    xlabel('omega'); 
    ylabel('psi'); 
    set(gca, 'XTick', 1:2:NumOmega, 'XTickLabel', Omega(1:2:end)); 
    set(gca, 'YTick', 1:NumPsi, 'YTickLabel', Psi); 
    axis square
end
suptitle([subject ' - ''Cost'' maps per run']);

%% Saving figures
ffilename1 = [figdir '/' subject '_optimization_maps_average.pdf'];
util_bdisp(['[out] - Saving figure in: ' ffilename1]);
fig_export(fig1, ffilename1, '-pdf', 'landscape', '-bestfit');

ffilename2 = [figdir '/' subject '_optimization_costmaps_run.pdf'];
util_bdisp(['[out] - Saving figure in: ' ffilename2]);
fig_export(fig2, ffilename2, '-pdf', 'landscape', '-bestfit');

