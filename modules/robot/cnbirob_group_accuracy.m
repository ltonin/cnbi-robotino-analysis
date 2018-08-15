clearvars; clc; close all;

sublist = {'ai6', 'ai7', 'ai8', 'aj1', 'aj3', 'aj4', 'aj7', 'aj8', 'aj9'};

pattern         = '_robot_records.mat';
datapath        = 'analysis/robot/';

IntegratorName  = {'discrete', 'continuous'};
TargetName      = {'Target1', 'Target2', 'Target3', 'Target4', 'Target5'};
NumSubjects = length(sublist);

Rk  = []; Ik  = []; Dk  = []; Tk  = []; Ck  = []; Sk  = []; Xk = [];
rIk = []; rDk = []; rSk = [];
cnumtrials = 0;
cnumruns = 0;

for sId = 1:NumSubjects
    csubject  = sublist{sId};
    cfilename = [datapath csubject pattern]; 
    util_bdisp(['[io] - Importing records data for subject: ' csubject]); 
    
    cdata = load(cfilename);
    
    % Labels
    Rk  = cat(1, Rk,  cdata.records.trial.Rk + cnumruns);
    Ik  = cat(1, Ik,  cdata.records.trial.Ik);
    Dk  = cat(1, Dk,  cdata.records.trial.Dk);
    Ck  = cat(1, Ck,  cdata.records.trial.Ck);
    Xk  = cat(1, Xk,  cdata.records.trial.Xk);
    Sk  = cat(1, Sk,  sId*ones(length(cdata.records.trial.Rk), 1));
    Tk  = cat(1, Tk,  cdata.records.trial.Tk + cnumtrials);
    cnumtrials = max(Tk);
    cnumruns = max(Rk);
    
    rIk = cat(2, rIk, cdata.records.run.Ik);
    rDk = cat(2, rDk, cdata.records.run.Dk);
    rSk = cat(2, rSk, sId*ones(1, length(cdata.records.run.Ik)));
end

Runs = unique(Rk);
NumRuns = length(Runs);
Integrators = unique(Ik);
NumIntegrators = length(Integrators);
Subjects = unique(Sk);
Targets = unique(Ck);
NumTargets = length(Targets);

%% Accuracy per run
rAccuracy = zeros(NumRuns, 1);
for rId = 1:NumRuns
    cindex = Rk == Runs(rId);
    rAccuracy(rId) = sum(Xk(cindex))./sum(cindex); 
end

%% Accuracy per target per run
tAccuracy = zeros(NumTargets, NumRuns);
for rId = 1:NumRuns
    for tId = 1:NumTargets
        cindex = Rk == Runs(rId) & Ck == Targets(tId);
        tAccuracy(tId, rId) = sum(Xk(cindex))./sum(cindex);
    end
end



%% Computing accuracy per subject and integrator
SubAvgAccuracy = zeros(NumSubjects, NumIntegrators);
SubStdAccuracy = zeros(NumSubjects, NumIntegrators);
for sId = 1:NumSubjects
    for iId = 1:NumIntegrators
        cindex = rIk == Integrators(iId) & rSk == Subjects(sId);
        SubAvgAccuracy(sId, iId) = nanmean(rAccuracy(cindex));
        SubStdAccuracy(sId, iId) = nanstd(rAccuracy(cindex));
    end
end

%% Statistical tests
SubPVal = zeros(NumSubjects, 1);
for sId = 1:NumSubjects
        cindex = rSk == Subjects(sId);
        SubPVal(sId) = ranksum(rAccuracy(cindex & rIk == 1), rAccuracy(cindex & rIk == 2));
        disp(['[stat] - Subject ' sublist{sId} ' significance: p<' num2str(SubPVal(sId), 3)]); 
end

PVal = ranksum(rAccuracy(rIk == 1), rAccuracy(rIk == 2), 'tail', 'left');
disp(['[stat] - Overall accuracy significance: p<' num2str(PVal, 3)]);


%% Plot

% Fig1 - Accuracy per subject and average accuracy
fig1 = figure;
fig_set_position(fig1, 'Top');

subplot(1, 3, [1 2]);
plot_barerrors(100*SubAvgAccuracy, 100*SubStdAccuracy);
grid on;
    
subplot(1, 3, 3);
boxplot(100*rAccuracy, rIk);
grid on;
