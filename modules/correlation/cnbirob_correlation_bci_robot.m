clearvars; clc; close all;

sublist = {'ai6', 'ai7', 'ai8', 'aj1', 'aj3', 'aj4', 'aj7', 'aj8', 'aj9'};

bci.pattern = '_bci_online.mat';
bci.path    = 'analysis/bci/';
rob.time.pattern   = '_robot_timing.mat';
rob.time.path      = 'analysis/robot/timing/';
rob.label.pattern  = '_robot_label.mat';
rob.label.path     = 'analysis/robot/label/'; 
rob.record.pattern = '_robot_record.mat';
rob.record.path    = 'analysis/robot/record/'; 

figdir   = 'figure/';

NumSubjects = length(sublist);
SampleRate = 16;
Timeout = 60;

%% BCI import data
duration = [];
result = [];
Ck = []; Rk = []; Ik = []; Dk = []; Sk = [];
cnumruns = 0;

for sId = 1:NumSubjects
    
    csubject  = sublist{sId};
    bci.filename = [bci.path csubject bci.pattern]; 
    util_bdisp(['[io] - Importing bci online data for subject: ' csubject]); 
    
    % BCI online data
    cdata = load(bci.filename);
    duration = cat(1, duration, cdata.duration);
    result   = cat(1, result, cdata.result);
    
    % BCI online labels
    Ck = cat(1, Ck, cdata.labels.Ck);
    Rk = cat(1, Rk, cdata.labels.Rk + cnumruns);
    Ik = cat(1, Ik, cdata.labels.Ik);
    Dk = cat(1, Dk, cdata.labels.Dk);
    Sk = cat(1, Sk, sId*ones(length(cdata.labels.Ck), 1));
    
    cnumruns = max(Rk);
end

% Compute accuracy and duration per run
Runs = unique(Rk);
NumRuns = length(Runs);

Integrators = unique(Ik);
NumIntegrators = length(Integrators);

Accuracy = nan(NumRuns, 1);
Duration = nan(NumRuns, 1);
rSk = nan(NumRuns, 1);
rIk = nan(NumRuns, 1);
rDk = nan(NumRuns, 1);
for rId = 1:NumRuns
    cindex = Rk == Runs(rId);
    Accuracy(rId) = sum(result(cindex))./sum(cindex);
    Duration(rId) = nanmean(duration(cindex & result == true)./SampleRate);
    
    rSk(rId) = unique(Sk(cindex));
    rIk(rId) = unique(Ik(cindex));
    rDk(rId) = unique(Dk(cindex));
end

bci.accuracy = Accuracy;
bci.duration = Duration;
bci.settings.runs         = Runs;
bci.settings.nruns        = NumRuns;
bci.settings.integrators  = Integrators;
bci.settings.nintegrators = NumIntegrators;
bci.labels.run.Ik = rIk;
bci.labels.run.Dk = rDk;
bci.labels.run.Sk = rSk;

%% Robot import data
duration = [];
result   = [];
Ck = []; Rk = []; Ik = []; Dk = []; Sk = [];
cnumruns = 0;

for sId = 1:NumSubjects
    csubject  = sublist{sId};
    rob.filename.time   = [rob.time.path csubject rob.time.pattern]; 
    rob.filename.label  = [rob.label.path csubject rob.label.pattern]; 
    rob.filename.record = [rob.record.path csubject rob.record.pattern]; 
    util_bdisp(['[io] - Importing robot data for subject: ' csubject]); 
    
    % Reached
    creached   = load(rob.filename.record);
    result = cat(1, result, creached.reached);
    
    % Timing
    cduration = load(rob.filename.time);
    duration  = cat(1, duration, cduration.timing);
    
    % Labels
    clabel  = load(rob.filename.label);
    Rk  = cat(1, Rk,  clabel.labels.trial.Rk + cnumruns);
    Ik  = cat(1, Ik,  clabel.labels.trial.Ik);
    Dk  = cat(1, Dk,  clabel.labels.trial.Dk);
    Ck  = cat(1, Ck,  clabel.labels.trial.Ck);
    Sk  = cat(1, Sk,  sId*ones(length(clabel.labels.trial.Rk), 1));
    cnumruns = max(Rk);
end

% Compute accuracy and duration per run
ValidityCond = duration < Timeout;

Runs = unique(Rk);
NumRuns = length(Runs);
Integrators = unique(Ik);
NumIntegrators = length(Integrators);
Days = unique(Dk);
NumDays = length(Days);

rIk = []; rDk = []; rSk = [];
Accuracy = [];
Duration = [];
for sId = 1:NumSubjects
    for dId = 1:NumDays
        for iId = 1:NumIntegrators
            cindex = Sk == sId & Dk == Days(dId) & Ik == Integrators(iId);
            
            if sum(cindex) == 0
                continue;
            end
            
            Accuracy = cat(1, Accuracy, sum(result(cindex & ValidityCond))./sum(cindex  & ValidityCond));
            Duration = cat(1, Duration, nanmean(duration(cindex & result == true & ValidityCond)));
            
            rIk = cat(1, rIk, unique(Ik(cindex)));
            rDk = cat(1, rDk, unique(Dk(cindex)));
            rSk = cat(1, rSk, unique(Sk(cindex)));
        end
    end
end

rob.accuracy = Accuracy;
rob.duration = Duration;
rob.labels.run.Ik = rIk;
rob.labels.run.Dk = rDk;
rob.labels.run.Sk = rSk;
rob.settings.runs         = Runs;
rob.settings.nruns        = NumRuns;
rob.settings.integrators  = Integrators;
rob.settings.nintegrators = NumIntegrators;

%% Check that all labels are the same
if(isequal(bci.labels.run.Dk, rob.labels.run.Dk) == false)
    warning('Labels ''Dk'' are different');
end
if(isequal(bci.labels.run.Sk, rob.labels.run.Sk) == false)
    warning('Labels ''Sk'' are different');
end
if(isequal(bci.labels.run.Ik, rob.labels.run.Ik) == false)
    warning('Labels ''Ik'' are different');
end

Dk = bci.labels.run.Dk;
Sk = bci.labels.run.Sk;
Ik = bci.labels.run.Ik;
Integrators    = bci.settings.integrators;
NumIntegrators = bci.settings.nintegrators;

%% Figure
fig1 = figure;
fig_set_position(fig1, 'All');

NumRows = 2;
NumCols = 2;
color = [0 0.4470 0.7410; 0.8500 0.3250 0.0980];

% BCI accuracy vs. Robot accuracy
subplot(NumRows, NumCols, 1);
hold on;
cgca = zeros(NumIntegrators, 1);
for iId = 1:NumIntegrators
    cindex = Ik == Integrators(iId);
    cgca(iId) = plot(bci.accuracy(cindex), rob.accuracy(cindex), 'o', 'MarkerFaceColor', color(iId, :));
    xlim([0 1]);
    ylim([0 1]);
    lsline;
    
    cpos = get(gca,'Position');
    cpos(2) = (cpos(2) - 0.05) - (iId-1)*0.035;
    [ccorr, cpval] = corr(bci.accuracy(cindex), rob.accuracy(cindex), 'rows', 'pairwise');
    annotation('textbox', cpos, 'String', ['r=' num2str(ccorr, '%3.2f') ', p=' num2str(cpval, '%3.3f')], 'LineStyle', 'none', 'Color', color(iId, :), 'FontWeight', 'bold');

end
grid on;
hold off;
xlabel('BCI accuracy [%]');
ylabel('Robot accuracy [%]');
legend(cgca, 'discrete', 'continuous', 'location', 'best');

% BCI accuracy vs. Robot timing
subplot(NumRows, NumCols, 2);
hold on;
cgca = zeros(NumIntegrators, 1);
for iId = 1:NumIntegrators
    cindex = Ik == Integrators(iId);
    cgca(iId) = plot(bci.accuracy(cindex), rob.duration(cindex), 'o', 'MarkerFaceColor', color(iId, :));
    xlim([0 1]);
    lsline;
    
    cpos = get(gca,'Position');
    cpos(2) = (cpos(2) - 0.05) - (iId-1)*0.035;
    [ccorr, cpval] = corr(bci.accuracy(cindex), rob.duration(cindex), 'rows', 'pairwise');
    annotation('textbox', cpos, 'String', ['r=' num2str(ccorr, '%3.2f') ', p=' num2str(cpval, '%3.3f')], 'LineStyle', 'none', 'Color', color(iId, :), 'FontWeight', 'bold');

end
grid on;
hold off;
xlabel('BCI accuracy [%]');
ylabel('Robot timing [s]');
legend(cgca, 'discrete', 'continuous', 'location', 'best');

% BCI timing vs. Robot timing
subplot(NumRows, NumCols, 3);
hold on;
cgca = zeros(NumIntegrators, 1);
for iId = 1:NumIntegrators
    cindex = Ik == Integrators(iId);
    cgca(iId) = plot(bci.duration(cindex), rob.duration(cindex), 'o', 'MarkerFaceColor', color(iId, :));
    lsline;
    
    cpos = get(gca,'Position');
    cpos(2) = (cpos(2) - 0.05) - (iId-1)*0.035;
    [ccorr, cpval] = corr(bci.duration(cindex), rob.duration(cindex), 'rows', 'pairwise');
    annotation('textbox', cpos, 'String', ['r=' num2str(ccorr, '%3.2f') ', p=' num2str(cpval, '%3.3f')], 'LineStyle', 'none', 'Color', color(iId, :), 'FontWeight', 'bold');

end
grid on;
hold off;
xlabel('BCI timing [s]');
ylabel('Robot timing [s]');
legend(cgca, 'discrete', 'continuous', 'location', 'best');

% BCI timing vs. Robot accuracy
subplot(NumRows, NumCols, 4);
hold on;
cgca = zeros(NumIntegrators, 1);
for iId = 1:NumIntegrators
    cindex = Ik == Integrators(iId);
    cgca(iId) = plot(bci.duration(cindex), rob.accuracy(cindex), 'o', 'MarkerFaceColor', color(iId, :));
    lsline;
    
    cpos = get(gca,'Position');
    cpos(2) = (cpos(2) - 0.05) - (iId-1)*0.035;
    [ccorr, cpval] = corr(bci.duration(cindex), rob.accuracy(cindex), 'rows', 'pairwise');
    annotation('textbox', cpos, 'String', ['r=' num2str(ccorr, '%3.2f') ', p=' num2str(cpval, '%3.3f')], 'LineStyle', 'none', 'Color', color(iId, :), 'FontWeight', 'bold');

end
grid on;
hold off;
xlabel('BCI timing [s]');
ylabel('Robot accuracy [%]');
legend(cgca, 'discrete', 'continuous', 'location', 'best');


%% Figure
fig2 = figure;
fig_set_position(fig2, 'Top');

NumRows = 1;
NumCols = 3;
color = [0 0.4470 0.7410; 0.8500 0.3250 0.0980];

% BCI ratio vs. Robot accuracy
subplot(NumRows, NumCols, 1);
hold on;
cgca = zeros(NumIntegrators, 1);
for iId = 1:NumIntegrators
    cindex = Ik == Integrators(iId);
    cgca(iId) = plot(bci.accuracy(cindex)./(1 + bci.duration(cindex)), rob.accuracy(cindex), 'o', 'MarkerFaceColor', color(iId, :));
    ylim([0 1]);
    lsline;
    
    cpos = get(gca,'Position');
    cpos(2) = (cpos(2) - 0.05) - (iId-1)*0.035;
    [ccorr, cpval] = corr(bci.accuracy(cindex)./(1 + bci.duration(cindex)), rob.accuracy(cindex), 'rows', 'pairwise');
    annotation('textbox', cpos, 'String', ['r=' num2str(ccorr, '%3.2f') ', p=' num2str(cpval, '%3.3f')], 'LineStyle', 'none', 'Color', color(iId, :), 'FontWeight', 'bold');

end
grid on;
hold off;
xlabel('BCI ratio []');
ylabel('Robot accuracy [%]');
legend(cgca, 'discrete', 'continuous', 'location', 'best');

% BCI ratio vs. Robot timing
subplot(NumRows, NumCols, 2);
hold on;
cgca = zeros(NumIntegrators, 1);
for iId = 1:NumIntegrators
    cindex = Ik == Integrators(iId);
    cgca(iId) = plot(bci.accuracy(cindex)./(1 + bci.duration(cindex)), rob.duration(cindex), 'o', 'MarkerFaceColor', color(iId, :));
    lsline;
    
    cpos = get(gca,'Position');
    cpos(2) = (cpos(2) - 0.05) - (iId-1)*0.035;
    [ccorr, cpval] = corr(bci.accuracy(cindex)./(1 + bci.duration(cindex)), rob.duration(cindex), 'rows', 'pairwise');
    annotation('textbox', cpos, 'String', ['r=' num2str(ccorr, '%3.2f') ', p=' num2str(cpval, '%3.3f')], 'LineStyle', 'none', 'Color', color(iId, :), 'FontWeight', 'bold');

end
grid on;
hold off;
xlabel('BCI ratio []');
ylabel('Robot timing [s]');
legend(cgca, 'discrete', 'continuous', 'location', 'best');

% BCI ratio vs. Robot ratio
subplot(NumRows, NumCols, 3);
hold on;
cgca = zeros(NumIntegrators, 1);
for iId = 1:NumIntegrators
    cindex = Ik == Integrators(iId);
    cgca(iId) = plot(bci.accuracy(cindex)./(1 + bci.duration(cindex)), rob.accuracy(cindex)./(1 + rob.duration(cindex)), 'o', 'MarkerFaceColor', color(iId, :));
    lsline;
    
    cpos = get(gca,'Position');
    cpos(2) = (cpos(2) - 0.05) - (iId-1)*0.035;
    [ccorr, cpval] = corr(bci.accuracy(cindex)./(1 + bci.duration(cindex)), rob.accuracy(cindex)./(1 + rob.duration(cindex)), 'rows', 'pairwise');
    annotation('textbox', cpos, 'String', ['r=' num2str(ccorr, '%3.2f') ', p=' num2str(cpval, '%3.3f')], 'LineStyle', 'none', 'Color', color(iId, :), 'FontWeight', 'bold');

end
grid on;
hold off;
xlabel('BCI ratio []');
ylabel('Robot ratio []');
legend(cgca, 'discrete', 'continuous', 'location', 'best');

%% Saving figures
figfilename1 = [figdir '/group_correlation_bci_robot_accuracy_time.pdf'];
util_bdisp(['[fig] - Saving figure in: ' figfilename1]);
fig_figure2pdf(fig1, figfilename1) 

figfilename2 = [figdir '/group_correlation_bci_robot_ratio.pdf'];
util_bdisp(['[fig] - Saving figure in: ' figfilename2]);
fig_figure2pdf(fig2, figfilename2) 