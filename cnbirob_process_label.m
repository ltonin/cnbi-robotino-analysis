% clearvars; clc;
% 
% subject = 'ai7';

pattern_gdf_imported = '_robot_timing.mat';
pattern_rec_imported = '_robot_record.mat';
pattern_trk_imported = '_robot_trajectory.mat';

datapath = 'analysis/robot/';
savedir  = 'analysis/robot/label/';

% Create analysis directory
util_mkdir('./', savedir);

util_bdisp(['[proc] - Processing labels for subject ' subject]);

filename_gdf = [datapath 'timing/' subject pattern_gdf_imported];
filename_rec = [datapath 'record/' subject pattern_rec_imported];
filename_trk = [datapath 'trajectory/' subject pattern_trk_imported];

disp(['       - Loading gdf imported data from: ' filename_gdf]);
cdata_gdf = load(filename_gdf);

disp(['       - Loading records imported data from: ' filename_rec]);
cdata_rec = load(filename_rec);

disp(['       - Loading tracking imported data from: ' filename_trk]);
cdata_trk = load(filename_trk);


%% Extracting labels
util_bdisp('[proc] - Extracting labels to be compared');
Ck_gdf = cdata_gdf.labels.raw.trial.Ck;
Ck_rec = cdata_rec.labels.raw.trial.Ck;
Ck_trk = cdata_trk.labels.raw.trial.Ck;

Rk_gdf = cdata_gdf.labels.raw.trial.Rk;
Rk_rec = cdata_rec.labels.raw.trial.Rk;
Rk_trk = cdata_trk.labels.raw.trial.Rk;

Ik_gdf = cdata_gdf.labels.raw.trial.Ik;
Ik_rec = cdata_rec.labels.raw.trial.Ik;
Ik_trk = cdata_trk.labels.raw.trial.Ik;

Dk_gdf = cdata_gdf.labels.raw.trial.Dk;
Dk_rec = cdata_rec.labels.raw.trial.Dk;
Dk_trk = cdata_trk.labels.raw.trial.Dk;

Tk_gdf = cdata_gdf.labels.raw.trial.Tk;
Tk_rec = cdata_rec.labels.raw.trial.Tk;
Tk_trk = cdata_trk.labels.raw.trial.Tk;

Yk_gdf = cdata_gdf.labels.raw.trial.Yk;
Yk_trk = cdata_trk.labels.raw.trial.Yk;

%% Comparing labels for Ck

% Ck
Ck_isequal = compare_labels(Ck_gdf, Ck_rec, Ck_trk, 'gdf', 'rec', 'trk', 'Ck');

if Ck_isequal == true
    Ck = Ck_gdf;
else
    switch(subject)
        case 'ai7'
            Ck = Ck_rec;
            disp(['                   - Using Ck record labels for subject ' subject]);
         case 'aj9'
            Ck = Ck_rec;
            disp(['                   - Using Ck record labels for subject ' subject]);
    end
end

%% Comparing labels for Rk

Rk_isequal = compare_labels(Rk_gdf, Rk_rec, Rk_trk, 'gdf', 'rec', 'trk', 'Rk');

if Rk_isequal == true
    Rk = Rk_gdf;
else
    switch(subject)
    end
end

%% Comparing labels for Ik

Ik_isequal = compare_labels(Ik_gdf, Ik_rec, Ik_trk, 'gdf', 'rec', 'trk', 'Ik');

if Ik_isequal == true
    Ik = Ik_gdf;
else
    switch(subject)
    end
end

%% Comparing labels for Dk

Dk_isequal = compare_labels(Dk_gdf, Dk_rec, Dk_trk, 'gdf', 'rec', 'trk', 'Ik');

if Dk_isequal == true
    Dk = Dk_gdf;
else
    switch(subject)
    end
end

%% Comparing labels for Tk

Tk_isequal = compare_labels(Tk_gdf, Tk_rec, Tk_trk, 'gdf', 'rec', 'trk', 'Tk');

if Tk_isequal == true
    Tk = Tk_gdf;
else
    switch(subject)
    end
end

%% Comparing labels for Yk

Yk_isequal = compare_labels(Yk_gdf, Yk_trk, Yk_trk, 'gdf', 'rec', 'trk', 'Yk');

if Yk_isequal == true
    Yk = Yk_gdf;
else
    switch(subject)
    end
end


%% Saving labels

labels.trial.Ck = Ck;
labels.trial.Rk = Rk;
labels.trial.Dk = Dk;
labels.trial.Ik = Ik;
labels.trial.Tk = Tk;
labels.trial.Yk = Yk;


% Saving timing
cfilename = fullfile(savedir, [subject '_robot_label.mat']);
util_bdisp(['[out] - Saving labels in ' cfilename]);
save(cfilename, 'labels');



function res = compare_labels(a, b, c, na, nb, nc, labelname)
    warning('off','backtrace')
    res1 = isequal(a, b);
    res2 = isequal(a, c);
    if(~res1)
        id = find(a ~= b);
        warning(['[warning] - Different trials for ' labelname ' labels between ' na ' and ' nb ': ' num2str(id)]);
    end
    
    if(~res2)
        id = find(a ~= c);
        warning(['[warning] - Different trials for ' labelname ' labels between ' na ' and ' nc ': ' num2str(id)]);
    end
    
    res = res1 & res2;
end
