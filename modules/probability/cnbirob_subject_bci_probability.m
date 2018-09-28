clearvars; clc;

subject = 'aj1';

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
Rk = []; Ik = []; Dk = []; Dl = []; Yk = [];
psd = [];
classifier = [];
runId = 1;
currday = 0;
lastday = [];
freqgrid = [];
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
    
    cnsamples = size(cdata.psd, 1);
    
    Rk = cat(1, Rk, runId*ones(cnsamples, 1));
    Ik = cat(1, Ik, cintegrator*ones(cnsamples, 1));
    Dk = cat(1, Dk, currday*ones(cnsamples, 1));
    Yk = cat(1, Yk, currintrun(cintegrator)*ones(cnsamples, 1));
    
    runId = runId+1;
    
    % Concatenate events
    TYP = cat(1, TYP, cdata.events.TYP);
    DUR = cat(1, DUR, cdata.events.DUR);
    POS = cat(1, POS, cdata.events.POS + size(psd, 1));
    
    % Getting psd
    psd = cat(1, psd, cdata.psd);
    
    % Getting classifier
    classifier = cat(1, classifier, cdata.classifier);
    
    % Getting frequency grid
    cfreqgrid = cdata.settings.spectrogram.freqgrid;
    
    if isempty(freqgrid) == false
        if(isequal(freqgrid, cfreqgrid) == false)
            error('chk:frq', ['Different frequency grid between run ' num2str(fId) ' and ' num2str(fId-1)]);
        else
            freqgrid = cfreqgrid;
        end
    else
        freqgrid = cfreqgrid;
    end
        
end

events.TYP = TYP;
events.POS = POS;
events.DUR = DUR;
F = proc_reshape_ts_bc(log(psd));
NumSamples = size(F, 1);
NumChans = size(F, 2);
NumFreqs = size(F, 3);

%% Get general events
[~, TrialEvents] = proc_get_event2(781, NumSamples, events.POS, events.TYP, events.DUR);
[~, CueEvents] = proc_get_event2(ClassEvents, NumSamples, events.POS, events.TYP, events.DUR);
[~, FixEvents] = proc_get_event2(786, NumSamples, events.POS, events.TYP, events.DUR);

TrialFix  = FixEvents.TYP;
TrialCues = CueEvents.TYP;
NumTrials = length(TrialEvents.TYP);

Ck = zeros(NumSamples, 1);
Tk = zeros(NumSamples, 1);
for trId = 1:NumTrials
    cstart = TrialEvents.POS(trId);
    cstop  = cstart + TrialEvents.DUR(trId) - 1;
    cclass = CueEvents.TYP(trId);
    Ck(cstart:cstop) = cclass;
    Tk(cstart:cstop) = trId;
end

Fk = zeros(NumSamples, 1);
for trId = 1:NumTrials
    cstart = FixEvents.POS(trId);
    cstop  = cstart + FixEvents.DUR(trId) -1;
    Fk(cstart:cstop) = 786;
    
end

%% Single sample classification
rpp = nan(NumSamples, 2);
for sId = 1:NumSamples
    cclassifier = classifier(Rk(sId));
    
    % Importing feature indexes used by the classifier
    FeatureIdx = proc_cnbifeature2bin(cclassifier.features, freqgrid);
    GauClassifier = cclassifier.gau;
    
    [~, rpp(sId, :)] = gauClassifier(GauClassifier.M, GauClassifier.C, F(sId, FeatureIdx));
end

%% Exponential smoothing
rejection = 0.55;
alpha = 0.03;
epp = 0.5*ones(NumSamples, 1);

for sId = 2:NumSamples
    crpp = rpp(sId, 1);
    pepp = epp(sId-1);
    
    % Reset
    if ismember(sId, TrialEvents.POS) == true
        epp(sId) = 0.5;
        continue;
    end
    
    % Rejection
    if(crpp <= rejection && crpp >= (1 - rejection))
        crpp = pepp;
    end
    
    % Integration
    epp(sId) = alpha.*crpp + (1-alpha).*pepp;
    
end


%% Trial based epp
MaxTrialLength = max(TrialEvents.DUR);
EppTrial = nan(32, NumTrials);
EppTrial_Fix = nan(48, NumTrials);
for trId = 1:NumTrials
    cepp = epp(Tk == trId);
    EppTrial(1:32, trId) = cepp(1:32);

    
    cstart = FixEvents.POS(trId);
    cstop  = cstart + FixEvents.DUR(trId) -1;
    cepp_fix = epp(cstart:cstart+48-1);
    EppTrial_Fix(1:48, trId) = cepp_fix(1:48);
end

%% Data
probability.raw = rpp;
labels.sample.Ck = Ck;
labels.sample.Rk = Rk;
labels.sample.Ik = Ik;
labels.sample.Dk = Dk;
labels.sample.Yk = Yk;
labels.sample.Fk = Fk;
labels.sample.Tk = Tk;
%% Saving data
cfilename = fullfile(savedir, [subject '_bci_probability.mat']);
util_bdisp(['[out] - Saving bci probability in ' cfilename]);
save(cfilename, 'probability', 'labels');

