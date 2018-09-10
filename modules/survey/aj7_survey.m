clearvars;

subject = 'aj7';
savedir = 'analysis/survey/';

% Create analysis directory
util_mkdir('./', savedir);

Survey(:, 1) = [5 4 4 3 3 5 5 2];
Survey(:, 2) = [5 4 4 4 3 5 5 5];
Survey(:, 3) = [4 4 4 4 2 4 3 2];
Survey(:, 4) = [5 5 4 4 2 5 5 5];

[NumQuestions, NumSurvey] = size(Survey);

% Survey type
SurveyType = [1 2 1 2];
SurveyName = {'discrete', 'continuous'};

% Day Index
DayId = [1 1 2 2];

questions = reshape(Survey, numel(Survey), 1);

% Get labels
labels.survey.Qk = repmat((1:NumQuestions)', [NumSurvey 1]);    
labels.survey.Ik = reshape(repmat(SurveyType, [NumQuestions 1]), numel(Survey), 1);
labels.survey.Dk = reshape(repmat(DayId, [NumQuestions 1]), numel(Survey), 1);

% Saving survey data
save([savedir '/' subject '_survey.mat'], 'questions', 'labels');