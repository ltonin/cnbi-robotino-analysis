function [data, labels] = cnbirob_concatenate_tracking_data(filepaths, datafield, varargin)

    % Input parser    
    p = inputParser;
    validfiles  = @(x) iscell(x);
    addRequired(p, 'filepaths', validfiles);
    addRequired(p, 'datafield', @ischar);
    parse(p, filepaths, datafield, varargin{:});
  

    data = [];
    Rk  = [];
    Ik  = [];
    Dk  = [];
    Dl  = [];
    Tk  = [];
    Ck  = [];
    Yk  = [];
    
    nfiles = length(filepaths);
    currday = 0;
    lastday = [];
    prev_trial = 0;
    currintrun = [0 0];
    
    for fId = 1:nfiles
        cfile = filepaths{fId};
        cdata = load(cfile);
        
        % Check if the provided datafield exists in the data
        if(isfield(cdata, datafield) == false) 
            error('chk:dat', [' ''' datafield ''' does not exist in: ' cfile]);
        end
        
        % Get file info from filename
        cinfo = util_getfile_info(cfile);
        
        % Get integrator type
        switch(cinfo.extra{1})
            case 'ema'
                cintegrator = 1;
            case 'dynamic'
                cintegrator = 2;
            otherwise
                cintegrator = -1;
        end
        currintrun(cintegrator) = currintrun(cintegrator) + 1;
        
        % Get day id and label
        if strcmpi(cinfo.date, lastday) == false
            currday = currday + 1;
            Dl = cat(1, Dl, cinfo.date);
            lastday = cinfo.date;
        end
        
        
        % Concatenate data
        data = cat(1, data, cdata.(datafield));
        
        % Concatenate labels
        Rk = cat(1, Rk, fId*ones(size(cdata.(datafield), 1), 1));
        Ik = cat(1, Ik, cintegrator*ones(size(cdata.(datafield), 1), 1));
        Dk = cat(1, Dk, currday*ones(size(cdata.(datafield), 1), 1));     
        Ck = cat(1, Ck, cdata.labels.raw.sample.Ck);
        Yk = cat(1, Yk, currintrun(cintegrator)*ones(length(cdata.labels.raw.sample.Ck), 1));
        Tk = cat(1, Tk, cdata.labels.raw.sample.Tk + prev_trial);
        prev_trial = Tk(end);
        
    end

    labels.Rk  = Rk;
    labels.Ik  = Ik;
    labels.Dk  = Dk;
    labels.Dl  = Dl;
    labels.Tk  = Tk;
    labels.Ck  = Ck;
    labels.Yk  = Yk;
end



