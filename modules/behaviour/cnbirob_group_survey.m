clearvars; clc; close all;

sublist = {'ai6', 'ai7', 'ai8', 'aj1', 'aj3', 'aj4', 'aj7', 'aj8', 'aj9',  'e8', 'ah7', 'ac7', 'b4'};

surveypatter = '_survey.mat';
surveypath   = 'analysis/survey/';

figdir   = 'figure/';

QuestionText{1} = {'Q1'; 'control'; 'Did you generally feel in control over the robot?'};
QuestionText{2} = {'Q2'; 'precision'; 'How precisely could you determine the robot''s direction?'};
QuestionText{3} = {'Q3'; 'turning'; 'How easy was it to make the robot turn left or right?'};
QuestionText{4} = {'Q4'; 'forward'; 'How easy was it to let the robot go forward?'};
QuestionText{5} = {'Q5'; 'effort'; 'How much effort did it require to control the robot?'};
QuestionText{6} = {'Q6'; 'focus'; 'Did you rather focus on the robot or on the visual feedback on the screen?'};
QuestionText{7} = {'Q7'; 'attention'; 'How often did you shift your attention between screen and robot?'};
QuestionText{8} = {'Q8'; 'like'; 'How much did you like the overall behaviour of this control modality'};

IntegratorName  = {'discrete', 'continuous'};
NumSubjects = length(sublist);

% Create figure directory
util_mkdir('./', figdir);


scores = [];
Qk = []; Ik = []; Dk = [];

for sId = 1:NumSubjects
    csubject  = sublist{sId};
    cfilename_survey = [surveypath csubject surveypatter]; 
    util_bdisp(['[io] - Importing survey data for subject: ' csubject]); 
    
    csurvey = load(cfilename_survey);
    
    % Scores
    scores = cat(1, scores, csurvey.questions);
    
    % Labels
    Qk = cat(1, Qk, csurvey.labels.survey.Qk);
    Ik = cat(1, Ik, csurvey.labels.survey.Ik);
    Dk = cat(1, Dk, csurvey.labels.survey.Dk);
end

Questions      = unique(Qk);
NumQuestions   = length(Questions);
Integrators    = unique(Ik);
NumIntegrators = length(Integrators);
Days           = unique(Dk);
NumDays        = length(Days);

%% Average score per question and integrators
util_bdisp('[proc] - Average score per question and integrators');
ScoreQstAvg = nan(NumQuestions, NumIntegrators);
ScoreQstMed = nan(NumQuestions, NumIntegrators);
ScoreQstStd = nan(NumQuestions, NumIntegrators);
ScoreQstSte = nan(NumQuestions, NumIntegrators);

for qId = 1:NumQuestions
    for iId = 1:NumIntegrators
        cindex = Qk == Questions(qId) & Ik == Integrators(iId);
        ScoreQstAvg(qId, iId) = nanmean(scores(cindex));
        ScoreQstMed(qId, iId) = nanmedian(scores(cindex));
        ScoreQstStd(qId, iId) = nanstd(scores(cindex));
        ScoreQstSte(qId, iId) = nanstd(scores(cindex))./sqrt(sum(cindex));
    end
end

%% Statistical tests per question
util_bdisp('[stat] - Statical tests on question scores:');
PValScore = nan(NumQuestions, 1);
for qId = 1:NumQuestions
    cindex = Qk == Questions(qId);
    PValScore(qId) = ranksum(scores(cindex & Ik == 1), scores(cindex & Ik == 2)); 
    disp(['       - Question ' num2str(qId) ' significance: p<' num2str(PValScore(qId), 3)]); 
end

%% Plots

% Fig1 - Scores per question and integrator
fig1 = figure;
fig_set_position(fig1, 'Top');

NumRows = 1;
NumCols = 1;
color = [0 0.4470 0.7410; 0.8500 0.3250 0.0980];

% Scores per question and integrator
subplot(NumRows, NumCols, 1);

PValScorePlot = nan(numel(ScoreQstAvg), numel(ScoreQstAvg));
for i = 1:NumQuestions
    PValScorePlot(i, NumQuestions+i) = PValScore(i);
    PValScorePlot(NumQuestions+i, i) = PValScore(i);
end

superbar(ScoreQstAvg, 'E', ScoreQstSte, 'BarFaceColor', reshape(color, [1 size(color)]), 'BarEdgeColor', [.4 .4 .4], 'BarLineWidth', .1, 'ErrorbarStyle', 'T', 'ErrorbarLineWidth', .1, 'P', PValScorePlot);
grid on;
% ylim([0 5]);
set(gca, 'XTick', 1:NumQuestions);
set(gca, 'XTickLabel', cellfun(@(c)c{1}, QuestionText, 'UniformOutput', 0));
xlabel('Question');
ylabel('');
title('Average question score (+/- SEM)');

%% Saving figure
figfilename = [figdir '/group_survey.pdf'];
util_bdisp(['[fig] - Saving figure in: ' figfilename]);
fig_figure2pdf(fig1, figfilename) 
