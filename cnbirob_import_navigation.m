clearvars; clc;

subject = 'aj1';

gdfpattern  = '*.online.mi.mi_bhbf.*.mobile.gdf';
rospattern  = '*.online.mi.mi_bhbf.*.mobile.bag';
rosfolder   = 'robot';
gdffolder   = '';
experiment  = 'micontinuous';
datapath    = ['/mnt/data/Research/' experiment '/' subject '_' experiment '/'];
savedir     = './analysis/';

rosfiles = cnbirob_util_getdata(datapath, rospattern, rosfolder);
gdffiles = cnbirob_util_getdata(datapath, gdfpattern, gdffolder);

if(length(rosfiles) ~= length(gdffiles))
    error('chk:nfiles', 'Different number of ros and gdf files');
end
nfiles = length(rosfiles);

for fId = 1:nfiles
    
    crosfile = rosfiles{fId};
    cgdffile = gdffiles{fId};
    
    util_bdisp(['[io] - Import ' num2str(fId) '/' num2str(nfiles) ' file:']);
    disp(['  - bag: ' crosfile]);
    disp(['  - gdf: ' cgdffile]);
    
    % Import the bag file
    bag = rosbag(crosfile);
    
    % Import header of the gdf file and get the SampleRate
    [~, h] = sload(cgdffile);
    SampleRate = h.SampleRate;
    
    % Read events from bag file
    util_bdisp(['[io] - Reading events from bag']);
    ros.EVENT = rosbag_event_read(bag, SampleRate);
    
    
end



