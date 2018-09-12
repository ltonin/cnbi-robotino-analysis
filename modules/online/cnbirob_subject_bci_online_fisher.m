% clearvars; clc;
% 
% subject = 'aj1';

pattern   = [subject '*.online.mi.mi_bhbf'];
datapath    = 'analysis/psd/laplacian/';
savedir     = 'analysis/bci/';

ClassEvents  = [773 771];
ResultEvents = [897 898];
CFeedbackEvent = 781;
files = util_getfile(datapath, '.mat', pattern);
nfiles = length(files);

% Create analysis directory
util_mkdir('./', savedir);

TYP = []; POS = []; DUR = [];
Ck = []; Rk = []; Ik = []; Xk = []; Dk = []; Dl = []; Yk = [];
F = [];
classifier = [];
runId = 1;
currday = 0;
lastday = [];
currintrun = [0 0];
for fId = 1:nfiles
    
    cfile = files{fId};
    
    util_bdisp(['[io] - Import ' num2str(fId) '/' num2str(nfiles) ' file:']);
    disp(['  - mat: ' cfile]);
    
    cdata = load(cfile, 'psd', 'events', 'settings', 'classifier');
    
    % Check if the file belongs to online modality (otherwise continue to
    % the next file)
    cmodality_name = cdata.settings.modality.name;
    if(strcmpi(cmodality_name, 'online') == false)
        disp(['  - Skipping file -> current modality: ' cmodality_name]);
        continue;
    end
    cmodality = 2;
    
    cintegrator_name = cdata.settings.integrator.name;
    switch(cintegrator_name)
        case 'ema'
            cintegrator = 1;
        case 'dynamic'
            cintegrator = 2;
        otherwise
            cintegrator = -1;
    end
    currintrun(cintegrator) = currintrun(cintegrator) + 1;
    
    
    
    % Extract event info (Cue)
    cCkId = [];
    for cId = 1:length(ClassEvents)
        cCkId = cat(1, cCkId, find(cdata.events.TYP == ClassEvents(cId)));
    end
    
    % Extract event info (Result)
    cXkId = [];
    for xId = 1:length(ResultEvents)
        cXkId = cat(1, cXkId, find(cdata.events.TYP == ResultEvents(xId)));
    end
    
    % Extract trial duration
    cdur = cdata.events.DUR(cdata.events.TYP == CFeedbackEvent);
    
    if (length(cXkId) ~= length(cCkId)) || (length(cCkId) ~= length(cdur))
        keyboard
    end
    
    % Get day id and label
    if strcmpi(cdata.settings.date, lastday) == false
        currday = currday + 1;
        Dl = cat(1, Dl, cdata.settings.date);
        lastday = cdata.settings.date;
    end
    
    ntrials = length(cCkId);
    
    Ck = cat(1, Ck, cdata.events.TYP(sort(cCkId)));
    Rk = cat(1, Rk, runId*ones(ntrials, 1));
    Ik = cat(1, Ik, cintegrator*ones(ntrials, 1));
    Xk = cat(1, Xk, cdata.events.TYP(sort(cXkId)));
    Dk = cat(1, Dk, currday*ones(ntrials, 1));
    Yk = cat(1, Yk, currintrun(cintegrator)*ones(ntrials, 1));
    
    runId = runId+1;
    
    % Concatenate events
    TYP = cat(1, TYP, cdata.events.TYP);
    DUR = cat(1, DUR, cdata.events.DUR);
    POS = cat(1, POS, cdata.events.POS + size(F, 1));
    
    % Getting psd
    F = cat(1, F, cdata.psd);
    
    % Getting classifier
    classifier = cat(1, classifier, cdata.classifier);
end

events.TYP = TYP;
events.POS = POS;
events.DUR = DUR;
U = log(F);
NumSamples = size(U, 1);
NumChans = size(U, 2);
NumFreqs = size(U, 3);

%% Get general events
[~, TrialEvents] = proc_get_event2(781, NumSamples, events.POS, events.TYP, events.DUR);

NumTrials = length(TrialEvents.TYP);

sCk = zeros(NumSamples, 1);
sRk = zeros(NumSamples, 1);
sIk = zeros(NumSamples, 1);
sDk = zeros(NumSamples, 1);
sYk = zeros(NumSamples, 1);
for trId = 1:NumTrials
    cstart = TrialEvents.POS(trId);
    cstop  = cstart + TrialEvents.DUR(trId) - 1;
    cclass = Ck(trId);
    sCk(cstart:cstop) = cclass;
    sRk(cstart:cstop) = Rk(trId);
    sIk(cstart:cstop) = Ik(trId);
    sDk(cstart:cstop) = Dk(trId);
    sYk(cstart:cstop) = Yk(trId);
end

%% Computing fisher score
Runs = unique(Rk);
NumRuns = length(Runs);
fisher = nan(NumChans*NumFreqs, NumRuns);
rIk = zeros(NumRuns, 1);
rDk = zeros(NumRuns, 1);
rYk = zeros(NumRuns, 1);
for rId = 1:NumRuns
    cindex = sRk == Runs(rId);
    
    fisher(:, rId) = proc_fisher2(U(cindex, :, :), sCk(cindex));
    
    rIk(rId) = unique(sIk(cindex));
    rDk(rId) = unique(sDk(cindex));
    rYk(rId) = unique(sDk(cindex));
end

labels.trial.Ck = Ck;
labels.trial.Rk = Rk;
labels.trial.Ik = Ik;
labels.trial.Xk = Xk;
labels.trial.Dk = Dk;
labels.trial.Yk = Yk;

labels.sample.Ck = sCk;
labels.sample.Rk = sRk;
labels.sample.Ik = sIk;
labels.sample.Dk = sDk;
labels.sample.Yk = sYk;

labels.run.Ik = rIk;
labels.run.Dk = rDk;
labels.run.Yk = rYk;

% Saving data
cfilename = fullfile(savedir, [subject '_bci_online_fisher.mat']);
util_bdisp(['[out] - Saving bci online fisher in ' cfilename]);
save(cfilename, 'fisher', 'labels', 'classifier');

