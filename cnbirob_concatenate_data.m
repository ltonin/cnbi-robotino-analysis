function [data, events, labels] = cnbirob_concatenate_data(filepaths, datafield, varargin)

    % Input parser
    DefaultHeaderField  = 'header';
    
    p = inputParser;
    validfiles  = @(x) iscell(x);
    addRequired(p, 'filepaths', validfiles);
    addRequired(p, 'datafield', @ischar);
    addParameter(p, 'headerfield', DefaultHeaderField, @ischar);
    parse(p, filepaths, datafield, varargin{:});
  
    HeaderField = p.Results.headerfield;

    data = [];
    Rk  = [];
    Ik  = [];
    Dk  = [];
    Dl  = [];
    TYP = [];
    POS = [];
    DUR = [];
    
    nfiles = length(filepaths);
    currday = 0;
    lastday = [];
    

    
    for fId = 1:nfiles
        cfile = filepaths{fId};
        cdata = load(cfile);
        
        % Check if the provided datafield exists in the data
        if(isfield(cdata, datafield) == false) 
            error('chk:dat', [' ''' datafield ''' does not exist in: ' cfile]);
        end
        
        % Check if the provided headerfield exists in the data
        if(isfield(cdata, HeaderField) == false) 
            error('chk:dat', [' ''' HeaderField ''' does not exist in: ' cfile]);
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
        
        % Get day id and label
        if strcmpi(cinfo.date, lastday) == false
            currday = currday + 1;
            Dl = cat(1, Dl, cinfo.date);
            lastday = cinfo.date;
        end
        
        % Concatenate events
        ctyp = cdata.(HeaderField).EVENT.TYP;       
        cdur = cdata.(HeaderField).EVENT.DUR;
        cpos = cdata.(HeaderField).EVENT.POS + size(data, 1);
        
        TYP = cat(1, TYP, ctyp);
        DUR = cat(1, DUR, cdur);
        POS = cat(1, POS, cpos);
        
        
        % Concatenate data
        data = cat(1, data, cdata.(datafield));
        
        % Concatenate labels
        Rk = cat(1, Rk, fId*ones(size(cdata.(datafield), 1), 1));
        Ik = cat(1, Ik, cintegrator*ones(size(cdata.(datafield), 1), 1));
        Dk = cat(1, Dk, currday*ones(size(cdata.(datafield), 1), 1));     
        
    end

    events.TYP = TYP;
    events.POS = POS;
    events.DUR = DUR;
    labels.Rk  = Rk;
    labels.Ik  = Ik;
    labels.Dk  = Dk;
    labels.Dl  = Dl;
end



