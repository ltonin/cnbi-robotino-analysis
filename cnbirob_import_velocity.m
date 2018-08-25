clearvars; clc;

subject = 'ai6';

pattern  = '*.online.mi.mi_bhbf.*.mobile.bag';
folder   = 'robot';
experiment  = 'micontinuous';
datapath    = ['/mnt/data/Research/' experiment '/' subject '_' experiment '/'];
savedir     = 'analysis/robot/velocity/';

SampleRate  = 512;

files = cnbirob_util_getdata(datapath, pattern, folder);
nfiles = length(files);

% Create analysis directory
util_mkdir('./', savedir);

for fId = 1:nfiles
    
    cfile = files{fId};
    
    util_bdisp(['[io] - Import ' num2str(fId) '/' num2str(nfiles) ' file:']);
    disp(['  - bag: ' cfile]);
    
    % Import the bag file
    bag = rosbag(cfile);
    
    % Load velocity
    util_bdisp('[io] - Loading velocity data and events');
    [velocity, header] = rosbag_velocity_load(bag, SampleRate, 'Topic', '/cmd_vel');

    % Save velocity
    [~, cname] = fileparts(cfile);
    cname = fullfile(savedir, [cname '.mat']);
    
    util_bdisp(['[out] - Saving the velocity and the headear in: ' cname]);
    save(cname, 'velocity', 'header');
    
end



