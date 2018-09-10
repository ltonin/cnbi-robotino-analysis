clearvars;

subject = 'e8';
savedir = 'analysis/survey/';

% Create analysis directory
util_mkdir('./', savedir);

Survey(:, 1) = [4 3 3 4 2 2 2 3];
Survey(:, 2) = [4 4 2 4 1 3 1 4];

[NumQuestions, NumSurvey] = size(Survey);

% Survey type
SurveyType = [1 2];
SurveyName = {'discrete', 'continuous'};

% Day Index
DayId = [1 1];

questions = reshape(Survey, numel(Survey), 1);

% Get labels
labels.survey.Qk = repmat((1:NumQuestions)', [NumSurvey 1]);    
labels.survey.Ik = reshape(repmat(SurveyType, [NumQuestions 1]), numel(Survey), 1);
labels.survey.Dk = reshape(repmat(DayId, [NumQuestions 1]), numel(Survey), 1);

% Saving survey data
save([savedir '/' subject '_survey.mat'], 'questions', 'labels');