clearvars; clc;

subject = 'aj1';

pattern  = '*.online.mi.mi_bhbf.*.mobile.bag';
folder   = 'robot';
experiment  = 'micontinuous';
datapath    = ['/mnt/data/Research/' experiment '/' subject '_' experiment '/'];
savedir     = 'analysis/robot/odometry/';

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
    
    % Load odometry
    util_bdisp('[io] - Loading odometry data and events');
    [odometry, header] = rosbag_odometry_load(bag, SampleRate, 'Topic', '/odom');

    % Save odometry
    [~, cname] = fileparts(cfile);
    cname = fullfile(savedir, [cname '.mat']);
    
    util_bdisp(['[out] - Saving the odometry and the headear in: ' cname]);
    save(cname, 'odometry', 'header');
    
end



