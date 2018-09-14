clearvars; clc;

sublist = {'ai6', 'ai7', 'ai8', 'aj1', 'aj3', 'aj4', 'aj7', 'aj8', 'aj9',  'e8', 'ah7', 'ac7', 'b4'};

pattern = '_bci_online_fisher.mat';
path    = 'analysis/bci/';

figdir   = 'figure/';

NumSubjects = length(sublist);

freqgrid  = 4:2:96;
muband    = 6:14;
betaband  = 16:28;
[~, muband_id]   = intersect(freqgrid, muband);
[~, betaband_id] = intersect(freqgrid, betaband);

NumBands = 2;

Ck = []; Rk = []; Ik = []; Dk = []; Sk = []; Yk = [];
cnumruns = 0;
cintruns = [0 0];

fisher = [];
classifier = [];
for sId = 1:NumSubjects
    csubject  = sublist{sId};
    cfilename = [path csubject pattern]; 
    util_bdisp(['[io] - Importing bci online fisher for subject: ' csubject]); 
    
    % Loading data
    cdata = load(cfilename);

    
    % Labels
    cruns = (1:size(cdata.fisher, 2))';
    Rk = cat(1, Rk, cruns + size(fisher, 2));
    Yk = cat(1, Yk, cdata.labels.run.Yk);
    Ik = cat(1, Ik, cdata.labels.run.Ik);
    Dk = cat(1, Dk, cdata.labels.run.Dk);
    Sk = cat(1, Sk, sId*ones(size(cdata.fisher, 2), 1));
    
    fisher     = cat(2, fisher, cdata.fisher);
    classifier = cat(1, classifier, cdata.classifier);
    
end

NumRuns = size(fisher, 2);
NumChans = 16;
NumFreqs = length(freqgrid);
Integrators = unique(Ik);
NumIntegrators = length(Integrators);

%% Get Heat map of the selected features
HeatMap = nan(NumFreqs, NumChans, NumRuns);
ValueMap = nan(NumFreqs, NumChans, NumRuns);
for rId = 1:NumRuns
    cfeatureIdx = proc_cnbifeature2bin(classifier(rId).features, freqgrid);
    [cfreqidx, cchanidx] = ind2sub([NumFreqs NumChans], cfeatureIdx);
    HeatMap(cfreqidx, cchanidx, rId) = 1;
    
    for fId = 1:length(cfreqidx) 
        ValueMap(cfreqidx(fId), cchanidx(fId), rId) = fisher(cfeatureIdx(fId), rId);
    end
end

%% Figure
fig1 = figure;
fig_set_position(fig1, 'All');

NumRows = 2;
NumCols = 2;
load('chanlocs64.mat');
index16 = [38 10 11 47 46 45 13 12 48 49 50 18 19 32 56 55];
maplimits = [0 40];

% HeatMap - Mu topoplot
subplot(NumRows, NumCols, 1);
cdata = squeeze(nansum(nansum(HeatMap(muband_id, :, :), 1), 3));
cdata = cnbirob_util_convert_channels(cdata);
topoplot(cdata, chanlocs, 'headrad', 'rim','maplimits', maplimits, 'emarker2', {index16,'o','k',5,1}, 'electrodes', 'off', 'colormap', parula);
axis image;
title('Number of selected features in mu band');
colorbar

% HeatMap - Beta topoplot
subplot(NumRows, NumCols, 2);
cdata = squeeze(nansum(nansum(HeatMap(betaband_id, :, :), 1), 3));
cdata = cnbirob_util_convert_channels(cdata);
topoplot(cdata, chanlocs, 'headrad', 'rim', 'maplimits', maplimits, 'emarker2', {index16,'o','k',5,1}, 'electrodes', 'off', 'colormap', parula);
axis image;
title('Number of selected features in beta band');
colorbar

maplimits = [0 20];
% ValueMap - Mu topoplot
subplot(NumRows, NumCols, 3);
cdata = squeeze(nansum(nansum(ValueMap(muband_id, :, :), 1), 3));
cdata = cnbirob_util_convert_channels(cdata);
topoplot(cdata, chanlocs, 'headrad', 'rim','maplimits', maplimits, 'emarker2', {index16,'o','k',5,1}, 'electrodes', 'off', 'colormap', parula);
axis image;
title('Value of selected features in mu band');
colorbar

% ValueMap - Beta topoplot
subplot(NumRows, NumCols, 4);
cdata = squeeze(nansum(nansum(ValueMap(betaband_id, :, :), 1), 3));
cdata = cnbirob_util_convert_channels(cdata);
topoplot(cdata, chanlocs, 'headrad', 'rim', 'maplimits', maplimits, 'emarker2', {index16,'o','k',5,1}, 'electrodes', 'off', 'colormap', parula);
axis image;
title('Value of selected features in beta band');
colorbar

%% Saving figure
figfilename = [figdir '/group_bci_online_features.pdf'];
util_bdisp(['[fig] - Saving figure in: ' figfilename]);
fig_figure2pdf(fig1, figfilename) 

