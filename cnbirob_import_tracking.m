clearvars; clc;

subject = 'aj1';

pattern  = '*.online.mi.mi_bhbf.*.mobile.csv';
folder   = 'tracking/trajectories';
experiment  = 'micontinuous';
datapath    = ['/mnt/data/Research/' experiment '/' subject '_' experiment '/'];
savedir     = 'analysis/robot/tracking/';


files = cnbirob_util_getdata(datapath, pattern, folder);
nfiles = length(files);

% Create analysis directory
util_mkdir('./', savedir);

for fId = 1:nfiles
    
    cfile = files{fId};
    
    util_bdisp(['[io] - Import ' num2str(fId) '/' num2str(nfiles) ' file:']);
    disp(['  - csv: ' cfile]);
    
    % Import cvs file
    fid = fopen(cfile, 'r');
    if(fid == -1)
        error('chk:file', ['[error] - Cannot open the file: ' cfile])
    end
    
    cdata = textscan(fid, '%f %f %d %d');
    
    fclose(fid);
    
    % Re-arrange tracking data
    tracking  = [cdata{1} cdata{2}];
    labels.Tk = cdata{3} + 1;
    labels.Ck = cdata{4};
    
    % Saving tracking data
    [~, cname] = fileparts(cfile);
    cname = fullfile(savedir, [cname '.mat']);
    
    util_bdisp(['[out] - Saving the tracking in: ' cname]);
    save(cname, 'tracking', 'labels');
end



