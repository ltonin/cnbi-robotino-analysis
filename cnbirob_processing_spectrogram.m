% clearvars; clc;
% 
% subject = 'aj1';

pattern = '*line.mi.*.gdf';

experiment  = 'micontinuous';
datapath    = ['/mnt/data/Research/' experiment '/' subject '_' experiment '/'];
savedir     = 'analysis/psd/laplacian/';

%% Processing parameters
mlength    = 1;
wlength    = 0.5;
pshift     = 0.25;                  
wshift     = 0.0625;                
selfreqs   = 4:2:96;
selchans   = 1:16;                  
load('extra/laplacian16.mat');

winconv = 'backward'; 

%% Get datafiles
files = cnbirob_util_getdata(datapath, pattern);
NumFiles = length(files);

%% Create/Check for savepath
util_mkdir(pwd, savedir);

%% Processing files
for fId = 1:NumFiles
    cfilename = files{fId};
    util_bdisp(['[io] - Loading file ' num2str(fId) '/' num2str(NumFiles)]);
    disp(['       File: ' cfilename]);
    
    % Get information from filename
    cinfo = util_getfile_info(cfilename);
    
    % Loading data
    [s, h] = sload(cfilename);
    s = s(:, selchans);
    
    % Computed DC removal
    s_dc = s-repmat(mean(s),size(s,1),1);
    
    % Compute Spatial filter
    s_lap = s_dc*lap;
    
    % Compute spectrogram
    [psd, freqgrid] = proc_spectrogram(s_lap, wlength, wshift, pshift, h.SampleRate, mlength);
    
    % Selecting desired frequencies
    [freqs, idfreqs] = intersect(freqgrid, selfreqs);
    psd = psd(:, idfreqs, :);
    
    % Extracting events
    cevents     = h.EVENT;
    cextraevents = [];
    
    events.TYP = cevents.TYP;
    events.POS = proc_pos2win(cevents.POS, wshift*h.SampleRate, winconv, mlength*h.SampleRate);
    events.DUR = floor(cevents.DUR/(wshift*h.SampleRate)) + 1;
    events.conversion = winconv;
    
    % Integrator type
    integrator = 'none';
    if isempty(cinfo.extra) == false
        integrator = cinfo.extra{1};
    end
    
    % Modality
    modality = cinfo.modality;
    if length(cinfo.extra) == 2
        if strcmpi(cinfo.extra{2}, 'mobile')
            modality = 'mobile';
        end
    end
    
    % Date
    date = cinfo.date;
    
    % Get classifier from log file
    classifier = [];
    if strcmpi(modality, 'online') || strcmpi(modality, 'mobile')
        clogfile = [datapath '/'  cinfo.date '/' cinfo.subject '.' cinfo.date '.log'];
        
        [~, cfile, cext] = fileparts(cfilename);
        ctarget = char(regexp(cfile, '(\w*)\.(\d*)\.(\d*)', 'match'));
        
        clogstr = cnbirob_read_logfile(clogfile, ctarget);
        
        try
            canalysis = load([datapath '/' cinfo.date '/' clogstr.classifier]);
        catch 
            error('chk:classifier', ['Classifier ''' clogstr.classifier ''' not found in ' datapath '/' cinfo.date '/']);
        end
        
        classifier.filename    = clogstr.classifier;
        classifier.gau         = canalysis.analysis.tools.net.gau;
        classifier.features    = canalysis.analysis.tools.features;
        classifier.rejection   = clogstr.rejection;
        classifier.integration = clogstr.integration;
        classifier.thresholds  = clogstr.thresholds;
        classifier.classes     = canalysis.analysis.settings.task.classes_old;
        
        disp(['       Imported classifier belonging to this file: ' clogstr.classifier]);
  
    end
    
    % Create settings structure
    settings.data.filename          = cfilename;
    settings.data.nsamples          = size(s, 1);
    settings.data.nchannels         = size(s, 2);
    settings.data.samplerate        = h.SampleRate;
    settings.spatial.laplacian      = lap;
    settings.spectrogram.wlength    = wlength;
    settings.spectrogram.wshift     = wshift;
    settings.spectrogram.pshift     = pshift;
    settings.spectrogram.freqgrid   = freqs;
    settings.modality.legend        = {'offline','online','mobile'};
    settings.modality.name          = modality;
    settings.integrator.legend      = {'none', 'ema', 'dynamic'};
    settings.integrator.name        = integrator;
    settings.date                   = date;
    
    [~, name] = fileparts(cfilename);
    sfilename = [savedir '/' name '.mat'];
    util_bdisp(['[out] - Saving psd in: ' sfilename]);
    save(sfilename, 'psd', 'freqs', 'events', 'settings', 'classifier'); 
end