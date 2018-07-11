function cnbirob_util_getdata(datapath, pattern, subfolder)

%% First level directory access
    % Getting all the files in the given datapath
    entries = dir(datapath);
    folders = {};
    % Storing the id of the files that are not folders or that are '.', '..'
    for eId = 1:length(entries)
        cname   = entries(eId).name;
        cfolder = entries(eId).folder;
        ctype   = entries(eId).isdir;
        if( strcmp(cname, '.') == false && strcmp(cname, '..') == false && ctype == true )
            folders = cat(1, folders, [cfolder '/' cname '/']);
        end
    end
    nfolders = length(folders);
 
%% Iterate inside each sub-directory
   
    keyboard
end