% clearvars; clc;
% 
% subject = 'e8';

pattern  = '*.online.mi.mi_bhbf.*.mobile.gdf';
experiment  = 'micontinuous';
datapath    = ['/mnt/data/Research/' experiment '/' subject '_' experiment '/'];
recorddir   = 'analysis/robot/record/';
savedir     = 'analysis/robot/timing/';

TargetEvents = [26113 26114 26115 26116 26117];
ResumeEvent = 25352;
PauseEvent  = 25353;
NumTargets = length(TargetEvents);
SampleRate  = 512;
Timeout = 60;

files = cnbirob_util_getdata(datapath, pattern);
nfiles = length(files);

% Create analysis directory
util_mkdir('./', savedir);

% Load record data to adjust task events
util_bdisp('[io] - Loading record data to fix missing target events');
record = load([recorddir subject '_robot_record.mat']);

timing = [];
Ck = [];
Rk = [];
Ik = [];
Dk = [];
Dl = [];
Tk = [];
Yk = [];

currday = 0;
lastday = [];
currintrun = [0 0];
prev_trial = 0;

for fId = 1:nfiles
    
    cfile = files{fId};
    
    util_bdisp(['[io] - Import ' num2str(fId) '/' num2str(nfiles) ' file:']);
    disp(['  - gdf: ' cfile]);
    
    % Import the header of gdf file
    [~, h] = sload(cfile);
    
    % Create index for the target events (Felix subjects without task event)
    disp('[proc] - Computing timing and labels');    
    TrialStartId = h.EVENT.TYP == ResumeEvent;
    TrialStopId  = h.EVENT.TYP == PauseEvent;
    
    if(sum(TrialStartId) ~= sum(TrialStopId))
        error('chk:evt', 'Different number of trial start and stop');
    end
    
    TrialDur = h.EVENT.POS(TrialStopId) - h.EVENT.POS(TrialStartId) + 1;
    
    % Getting the current trial tasks
    ctrials = record.labels.raw.trial.Ck(record.labels.raw.trial.Rk == fId);
    cntrials = length(ctrials);
    
    % Concatenate target durations (timings)
    timing = cat(1, timing, TrialDur/h.SampleRate);
    
    % Get file info from filename
    cinfo = util_getfile_info(cfile);

    % Get integrator type
    switch(cinfo.extra{1})
        case 'ema'
            cintegrator = 1;
        case 'dynamic'
            cintegrator = 2;
        otherwise
            error('chk:int', ['Cannot retrieve integrator type from file: ' cfile])
    end
    currintrun(cintegrator) = currintrun(cintegrator) + 1;

    % Get day id and label
    if strcmpi(cinfo.date, lastday) == false
        currday = currday + 1;
        Dl = cat(1, Dl, cinfo.date);
        lastday = cinfo.date;
    end
    
    
    Ck = cat(1, Ck, ctrials);
    Rk = cat(1, Rk, fId*ones(cntrials, 1));
    Ik = cat(1, Ik, cintegrator*ones(cntrials, 1));
    Dk = cat(1, Dk, currday*ones(cntrials, 1));
    Yk = cat(1, Yk, currintrun(cintegrator)*ones(cntrials, 1));
    Tk = cat(1, Tk, (1:cntrials)' + prev_trial);
    prev_trial = Tk(end);
end

util_bdisp('[proc] - Check the correctness of the imported trial sequence');
TrialPerRun = 10;
ExpectedNumTrials = nfiles*TrialPerRun;
RealNumTrials = size(timing, 1);

if(ExpectedNumTrials == RealNumTrials)
    disp('[proc] - Imported trials are correct');
else 
    warning('chk:data', ['Expected trial number: ' num2str(ExpectedNumTrials) ' - Real trial number: ' num2str(RealNumTrials) '. Fixing...']);
    switch(subject)
        case 'ah7'
            timing = timing(2:end);
        case 'e8'
            timing = [timing(1:12); timing(14:45); timing(47:end)];
        otherwise
            error('chk:sbj', ['Unknown fixing rules for subject ' subject]);
    end
end

% Collecting the data
labels.raw.trial.Ck = Ck;
labels.raw.trial.Rk = Rk;
labels.raw.trial.Ik = Ik;
labels.raw.trial.Dk = Dk;
labels.raw.trial.Dl = Dl;
labels.raw.trial.Tk = Tk;
labels.raw.trial.Yk = Yk;

% Saving timing
cfilename = fullfile(savedir, [subject '_robot_timing.mat']);
util_bdisp(['[out] - Saving timing data in ' cfilename]);
save(cfilename, 'timing', 'labels');
