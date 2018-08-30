clearvars; clc;

subject = 'e8';

pattern  = '*.online.mi.mi_bhbf.*.mobile.gdf';
experiment  = 'micontinuous';
datapath    = ['/mnt/data/Research/' experiment '/' subject '_' experiment '/'];
savedir     = 'analysis/robot/';

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
record = load([savedir subject '_robot_records.mat']);

timing = [];
Ck = [];
Rk = [];
Ik = [];
Dk = [];
Dl = [];
Yk = [];

currday = 0;
lastday = [];
currintrun = [0 0];

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
    ctrials = record.records.trial.Ck(record.records.trial.Rk == fId);
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
        case 'ai6'
            timing = [timing(1:20); nan; timing(21:end)];
            Rk = [Rk(1:20); Rk(21); Rk(21:end)];
            Ik = [Ik(1:20); Ik(21); Ik(21:end)];
            Dk = [Dk(1:20); Dk(21); Dk(21:end)];
            Yk = [Yk(1:20); Yk(21); Yk(21:end)];
            Ck = [Ck(1:20); 5; Ck(21:end)];
        case 'ai8'
            timing = [timing(1:11); timing(13:end)];
            Rk = [Rk(1:11); Rk(13:end)];
            Ik = [Ik(1:11); Ik(13:end)];
            Dk = [Dk(1:11); Dk(13:end)];
            Ck = [Ck(1:11); Ck(13:end)];
            Yk = [Yk(1:11); Yk(13:end)];

        case 'aj3'
            timing([21 23]) = timing([23 21]);
            timing = [timing(1:22); timing(25:end)]; 
            Ck([21 23]) = Ck([23 21]);
            Ck = [Ck(1:22); Ck(25:end)]; 
            Rk = [Rk(1:22); Rk(25:end)];
            Ik = [Ik(1:22); Ik(25:end)];
            Dk = [Dk(1:22); Dk(25:end)];
            Yk = [Yk(1:22); Yk(25:end)];
        case 'ah7'
            timing = timing(2:end);
        case 'e8'
            timing = [timing(1:12); timing(14:45); timing(47:end)];
        otherwise
            error('chk:sbj', ['Unknown fixing rules for subject ' subject]);
    end
end

util_bdisp(['[io] - Import record data for subject ' subject]);
load(['analysis/robot/' subject '_robot_records.mat']); 

% Compute valid trials based on timeout
Vk = timing <= Timeout;

% Collecting the data
labels.Ck = Ck;
labels.Rk = Rk;
labels.Ik = Ik;
labels.Dk = Dk;
labels.Yk = Yk;
labels.Xk = records.trial.Xk;
labels.Dl = Dl;
labels.Vk = Vk;



% Saving timing
cfilename = fullfile(savedir, [subject '_robot_timing.mat']);
util_bdisp(['[out] - Saving timing data in ' cfilename]);
save(cfilename, 'timing', 'labels');

% Saving valid
cfilename = fullfile(savedir, [subject '_robot_valid.mat']);
util_bdisp(['[out] - Saving valid data (<Timeout) in ' cfilename]);
save(cfilename, 'Vk', 'Timeout');
