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

Ck = []; Rk = []; Ik = []; Xk = []; Dk = []; Dl = []; Yk = [];
duration = [];
runId = 1;
currday = 0;
lastday = [];
currintrun = [0 0];
for fId = 1:nfiles
    
    cfile = files{fId};
    
    util_bdisp(['[io] - Import ' num2str(fId) '/' num2str(nfiles) ' file:']);
    disp(['  - mat: ' cfile]);
    
    cdata = load(cfile, 'events', 'settings');
    
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
    duration = cat(1, duration, cdur);
    
    runId = runId+1;
end

result = zeros(length(Xk), 1);
result(Xk == 897) = 1;

labels.Ck = Ck;
labels.Rk = Rk;
labels.Ik = Ik;
labels.Xk = Xk;
labels.Dk = Dk;
labels.Yk = Yk;

% Saving data
cfilename = fullfile(savedir, [subject '_bci_online.mat']);
util_bdisp(['[out] - Saving bci online data in ' cfilename]);
save(cfilename, 'result', 'duration', 'labels');

