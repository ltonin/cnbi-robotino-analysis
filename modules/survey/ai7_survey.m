clearvars;

subject = 'ai7';
savedir = 'analysis/survey/';

% Create analysis directory
util_mkdir('./', savedir);

Survey(:, 1) = [4 4 2 3 1 2 4 2];
Survey(:, 2) = [4 4 2 4 1 4 4 4];
Survey(:, 3) = [2 2 3 4 1 3 2 2];
Survey(:, 4) = [4 4 2 2 2 3 2 4];
Survey(:, 5) = [4 4 4 4 3 3 4 4];
Survey(:, 6) = [4 4 2 2 2 3 4 3];

[NumQuestions, NumSurvey] = size(Survey);

% Survey type
SurveyType = [1 2 1 2 1 2];
SurveyName = {'discrete', 'continuous'};

% Day Index
DayId = [1 1 2 2 3 3];

questions = reshape(Survey, numel(Survey), 1);

% Get labels
labels.survey.Qk = repmat((1:NumQuestions)', [NumSurvey 1]);    
labels.survey.Ik = reshape(repmat(SurveyType, [NumQuestions 1]), numel(Survey), 1);
labels.survey.Dk = reshape(repmat(DayId, [NumQuestions 1]), numel(Survey), 1);

% Saving survey data
save([savedir '/' subject '_survey.mat'], 'questions', 'labels');