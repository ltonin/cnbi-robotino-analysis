clearvars; clc;

sublist = {'ai6', 'ai7', 'ai8', 'aj1', 'aj3', 'aj4', 'aj7', 'aj8', 'aj9',  'e8', 'ah7', 'ac7', 'b4'};

pattern = '_bci_online_fisher.mat';
path    = 'analysis/bci/';

figdir   = 'figure/';

NumSubjects = length(sublist);

Ck = []; Rk = []; Ik = []; Dk = []; Sk = []; Yk = [];
cnumruns = 0;
cintruns = [0 0];

fisher = [];
classifier = [];
for sId = 1:NumSubjects
    csubject  = sublist{sId};
    cfilename = [path csubject pattern]; 
    util_bdisp(['[io] - Importing bci online fisher for subject: ' csubject]); 
    
    % Loading data
    cdata = load(cfilename);

    
    % Labels
    cruns = (1:size(cdata.fisher, 2))';
    Rk = cat(1, Rk, cruns + size(fisher, 2));
    Yk = cat(1, Yk, cdata.labels.run.Yk);
    Ik = cat(1, Ik, cdata.labels.run.Ik);
    Dk = cat(1, Dk, cdata.labels.run.Dk);
    Sk = cat(1, Sk, sId*ones(size(cdata.fisher, 2), 1));
    
    fisher     = cat(2, fisher, cdata.fisher);
    classifier = cat(1, classifier, cdata.classifier);
    
end