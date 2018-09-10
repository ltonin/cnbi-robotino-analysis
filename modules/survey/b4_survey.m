clearvars;

subject = 'b4';
savedir = 'analysis/survey/';

% Create analysis directory
util_mkdir('./', savedir);

Survey(:, 1) = [3 2 3 2 2 5 5 3];
Survey(:, 2) = [3 4 4 4 3 5 5 4];

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