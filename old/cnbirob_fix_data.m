clearvars; clc;

subject = 'ai6';

pattern     = [subject '*.online.mi.mi_bhbf.*.mobile'];
targetdata  = 'odometry';
datapath    = ['analysis/robot/' targetdata '/'];
savedir     = ['analysis/robot/' targetdata '/'];
Targets      = [26113 26114 26115 26116 26117];


files = util_getfile(datapath, '.mat', pattern);
tobefixed = {};

for fId = 1:length(files)
    cdata = load(files{fId});
    ctrial = 0;
    
    for tgId = 1:length(Targets)
       ctrial = ctrial + sum(cdata.header.EVENT.TYP == Targets(tgId));
    end
    
    if ctrial ~= 10
        warning('chk:tr', ['Wrong amount of trials in run ' num2str(fId) ': ' files{fId}]);
        tobefixed = cat(1, tobefixed, files{fId});
    end
end

for fId = 1:length(tobefixed)
    cfilename = tobefixed{fId};
    
    switch(cfilename)
        case 'analysis/robot/odometry//ai6.20180417.170726.online.mi.mi_bhbf.dynamic.mobile.mat'
            cdata = load(cfilename);
            cevents = cdata.header.EVENT;
            cevents.TYP = [Targets(5); cevents.TYP];
            cevents.POS = [1; cevents.POS];
            cevents.DUR = [nan; cevents.DUR];
            cdata.header.EVENT = cevents;
            
        otherwise
    end
    bkpfile = [cfilename '.BKP'];
    movefile(cfilename, bkpfile);
    sdata = cdata.(targetdata);
    sheader = cdata.header;
    save(cfilename, '-struct', 'cdata');
end

