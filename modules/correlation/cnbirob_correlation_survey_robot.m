clearvars; clc; close all;

sublist = {'ai6', 'ai7', 'ai8', 'aj1', 'aj3', 'aj4', 'aj7', 'aj8', 'aj9', 'e8', 'ah7', 'ac7', 'b4'};

survey.pattern = '_survey.mat';
survey.path    = 'analysis/survey/';
rob.time.pattern   = '_robot_timing.mat';
rob.time.path      = 'analysis/robot/timing/';
rob.label.pattern  = '_robot_label.mat';
rob.label.path     = 'analysis/robot/label/'; 
rob.record.pattern = '_robot_record.mat';
rob.record.path    = 'analysis/robot/record/'; 

figdir   = 'figure/';

QuestionText{1} = {'Q1'; 'control'; 'Did you generally feel in control over the robot?'};
QuestionText{2} = {'Q2'; 'precision'; 'How precisely could you determine the robot''s direction?'};
QuestionText{3} = {'Q3'; 'turning'; 'How easy was it to make the robot turn left or right?'};
QuestionText{4} = {'Q4'; 'forward'; 'How easy was it to let the robot go forward?'};
QuestionText{5} = {'Q5'; 'effort'; 'How much effort did it require to control the robot?'};
QuestionText{6} = {'Q6'; 'focus'; 'Did you rather focus on the robot or on the visual feedback on the screen?'};
QuestionText{7} = {'Q7'; 'attention'; 'How often did you shift your attention between screen and robot?'};
QuestionText{8} = {'Q8'; 'like'; 'How much did you like the overall behaviour of this control modality'};

NumSubjects = length(sublist);
Timeout = 60;

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

%% Survey import data
scores = [];
Qk = []; Ik = []; Dk = []; Sk = [];

for sId = 1:NumSubjects
    csubject  = sublist{sId};
    survey.filename = [survey.path csubject survey.pattern]; 
    util_bdisp(['[io] - Importing survey data for subject: ' csubject]); 
    
    csurvey = load(survey.filename);
    
    % Scores
    scores = cat(1, scores, csurvey.questions);
    
    % Labels
    Qk = cat(1, Qk, csurvey.labels.survey.Qk);
    Ik = cat(1, Ik, csurvey.labels.survey.Ik);
    Dk = cat(1, Dk, csurvey.labels.survey.Dk);
    Sk = cat(1, Sk, sId*ones(length(csurvey.labels.survey.Qk), 1));
end

Integrators = unique(Ik);
NumIntegrators = length(Integrators);
Days = unique(Dk);
NumDays = length(Days);
Questions = unique(Qk);
NumQuestions = length(Questions);

Score = [];
rIk = []; rDk = []; rSk = [];
for sId = 1:NumSubjects
    for dId = 1:NumDays
        for iId = 1:NumIntegrators
            cindex = Sk == sId & Dk == Days(dId) & Ik == Integrators(iId);
            
            if sum(cindex) == 0
                continue;
            end
            
            Score = cat(1, Score, scores(cindex)');
            
            rIk = cat(1, rIk, unique(Ik(cindex)));
            rDk = cat(1, rDk, unique(Dk(cindex)));
            rSk = cat(1, rSk, unique(Sk(cindex)));
            
        end
    end
end

survey.score = Score;
survey.labels.run.Ik = rIk;
survey.labels.run.Dk = rDk;
survey.labels.run.Sk = rSk;
survey.settings.questions    = Questions;
survey.settings.nquestions   = NumQuestions;
survey.settings.questiontext = QuestionText;
survey.settings.integrators  = Integrators;
survey.settings.nintegrators = NumIntegrators;

%% Check that all labels are the same
if(isequal(survey.labels.run.Dk, rob.labels.run.Dk) == false)
    warning('Labels ''Dk'' are different');
end
if(isequal(survey.labels.run.Sk, rob.labels.run.Sk) == false)
    warning('Labels ''Sk'' are different');
end
if(isequal(survey.labels.run.Ik, rob.labels.run.Ik) == false)
    warning('Labels ''Ik'' are different');
end

Dk = survey.labels.run.Dk;
Sk = survey.labels.run.Sk;
Ik = survey.labels.run.Ik;
Integrators    = survey.settings.integrators;
NumIntegrators = survey.settings.nintegrators;
Questions    = survey.settings.questions;
NumQuestions = survey.settings.nquestions;
QuestionText = survey.settings.questiontext;

%% Compute correlation between robot accuracy and question scores
CorrIntAccScore = nan(NumQuestions, NumIntegrators);
PValIntAccScore = nan(NumQuestions, NumIntegrators);
for qId = 1:NumQuestions
    for iId = 1:NumIntegrators
        cindex = Ik == Integrators(iId);
        [c, p] = corr(rob.accuracy(cindex), survey.score(cindex, qId), 'rows', 'pairwise');
        CorrIntAccScore(qId, iId) = c;
        PValIntAccScore(qId, iId) = p;
    end
end

CorrAccScore = nan(NumQuestions, 1);
PValAccScore = nan(NumQuestions, 1);
for qId = 1:NumQuestions
    [c, p] = corr(rob.accuracy, survey.score(:, qId), 'rows', 'pairwise');
    CorrAccScore(qId) = c;
    PValAccScore(qId) = p;
end

%% Figure
fig1 = figure;
fig_set_position(fig1, 'All');
NumRows = 2;
NumCols = 1;
color = [0 0.4470 0.7410; 0.8500 0.3250 0.0980];

subplot(NumRows, NumCols, 1)
superbar(CorrAccScore, 'BarFaceColor', reshape(color, [1 size(color)]), 'BarEdgeColor', [.4 .4 .4], 'BarLineWidth', .1, 'P', PValAccScore, 'PStarShowNS', false);
ylim([0 0.8])
grid on;
set(gca, 'XTick', 1:NumQuestions);
set(gca, 'XTickLabel', cellfun(@(c)c{1}, QuestionText, 'UniformOutput', 0));
xlabel('Question');
ylabel('rho')
title('Correlation between robot accuracy and survey score (overall)');


subplot(NumRows, NumCols, 2)
hb = superbar(CorrIntAccScore, 'BarFaceColor', reshape(color, [1 size(color)]), 'BarEdgeColor', [.4 .4 .4], 'BarLineWidth', .1, 'P', PValIntAccScore, 'PStarShowNS', false);
ylim([-0.2 0.8])
grid on;
set(gca, 'XTick', 1:NumQuestions);
set(gca, 'XTickLabel', cellfun(@(c)c{1}, QuestionText, 'UniformOutput', 0));
xlabel('Question');
ylabel('rho')
title('Correlation between robot accuracy and survey score (per modality)');
legend([hb(1, 1) hb(1, 2)], 'discrete', 'continuous');

%% Saving figure
figfilename = [figdir '/group_correlation_robot_survey.pdf'];
util_bdisp(['[fig] - Saving figure in: ' figfilename]);
fig_figure2pdf(fig1, figfilename) 
