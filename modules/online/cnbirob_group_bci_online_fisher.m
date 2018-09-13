clearvars; clc;

sublist = {'ai6', 'ai7', 'ai8', 'aj1', 'aj3', 'aj4', 'aj7', 'aj8', 'aj9',  'e8', 'ah7', 'ac7', 'b4'};

pattern = '_bci_online_fisher.mat';
path    = 'analysis/bci/';

figdir   = 'figure/';

NumSubjects = length(sublist);

freqgrid  = 4:2:96;
muband    = 6:14;
betaband  = 16:28;
muband_id   = intersect(freqgrid, muband);
betaband_id = intersect(freqgrid, betaband);
% LocationIdx  = {[4 9 14]; [2 7 12 6 11 16]};
LocationIdx  = {[4 9 14]; [2 7 12 6 11 16 3 8 13 5 10 15]};

NumBands = 2;
NumLocs  = length(LocationIdx);

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

%% Get Fisher for selected features
selfisher = nan(NumRuns, 1);
for rId = 1:NumRuns
    
    cfeatureIdx = proc_cnbifeature2bin(classifier(rId).features, freqgrid);
    cfisher = fisher(:, rId);
    
    selfisher(rId) = mean(cfisher(cfeatureIdx));
end

%% Get fisher for selected bands
rfisher = reshape(fisher, [NumFreqs NumChans NumRuns]);
bandfisher = nan(2, NumRuns);
for rId = 1:NumRuns
    crfisher_mu   = rfisher(muband_id, :, rId);
    crfisher_beta = rfisher(betaband_id, :, rId);
    
%     crfisher_mu   = sort(reshape(crfisher_mu, numel(crfisher_mu), 1), 'descend');
%     crfisher_beta = sort(reshape(crfisher_beta, numel(crfisher_beta), 1), 'descend');
%     
%     crfisher_mu   = crfisher_mu(1:10);
%     crfisher_beta = crfisher_beta(1:10);
    
    
    bandfisher(1, rId) = nanmean(nanmean(crfisher_mu));
    bandfisher(2, rId) = nanmean(nanmean(crfisher_beta));
end

%% Get fisher for selected bands and channels
locfisher = nan(NumBands, NumLocs, NumRuns);
for rId = 1:NumRuns
    for lId = 1:NumLocs
        locfisher(1, lId, rId) = nanmean(nanmean(rfisher(muband_id, LocationIdx{lId}, rId)));
        locfisher(2, lId, rId) = nanmean(nanmean(rfisher(betaband_id, LocationIdx{lId}, rId)));
    end
end

%% Average selected fisher per subject
SelFisherSubAvg = nan(NumSubjects, NumIntegrators);
SelFisherSubMed = nan(NumSubjects, NumIntegrators);
SelFisherSubStd = nan(NumSubjects, NumIntegrators);
SelFisherSubSte = nan(NumSubjects, NumIntegrators);

for sId = 1:NumSubjects
    for iId = 1:NumIntegrators
        cindex = Sk == sId & Ik == Integrators(iId);
        SelFisherSubAvg(sId, iId) = nanmean(selfisher(cindex));
        SelFisherSubMed(sId, iId) = nanmedian(selfisher(cindex));
        SelFisherSubStd(sId, iId) = nanstd(selfisher(cindex));
        SelFisherSubSte(sId, iId) = nanstd(selfisher(cindex))./sqrt(sum(cindex));
    end
end

%% Evolution selected Fisher over run
NumIntRun = max(Yk);
SelFisherEvoAvg = nan(NumIntRun, NumIntegrators);
SelFisherEvoMed = nan(NumIntRun, NumIntegrators);
SelFisherEvoStd = nan(NumIntRun, NumIntegrators);
SelFisherEvoSte = nan(NumIntRun, NumIntegrators);
for rId = 1:NumIntRun
    for iId = 1:NumIntegrators
        cindex = Yk == rId & Ik == Integrators(iId);
        SelFisherEvoAvg(rId, iId) = nanmean(selfisher(cindex));
        SelFisherEvoMed(rId, iId) = nanmedian(selfisher(cindex));
        SelFisherEvoStd(rId, iId) = nanstd(selfisher(cindex));
        SelFisherEvoSte(rId, iId) = nanstd(selfisher(cindex))./sqrt(sum(cindex));
    end
end

%% Average band fisher per subject
BandFisherSubAvg = nan(NumSubjects, NumIntegrators, 2);
BandFisherSubMed = nan(NumSubjects, NumIntegrators, 2);
BandFisherSubStd = nan(NumSubjects, NumIntegrators, 2);
BandFisherSubSte = nan(NumSubjects, NumIntegrators, 2);

for sId = 1:NumSubjects
    for iId = 1:NumIntegrators
        cindex = Sk == sId & Ik == Integrators(iId);
        BandFisherSubAvg(sId, iId, :) = nanmean(bandfisher(:, cindex), 2);
        BandFisherSubMed(sId, iId, :) = nanmedian(bandfisher(:, cindex), 2);
        BandFisherSubStd(sId, iId, :) = nanstd(bandfisher(:, cindex), [], 2);
        BandFisherSubSte(sId, iId, :) = nanstd(bandfisher(:, cindex), [], 2)./sqrt(sum(cindex));
    end
end

%% Evolution band Fisher over run
NumIntRun = max(Yk);
BandFisherEvoAvg = nan(NumIntRun, NumIntegrators, 2);
BandFisherEvoMed = nan(NumIntRun, NumIntegrators, 2);
BandFisherEvoStd = nan(NumIntRun, NumIntegrators, 2);
BandFisherEvoSte = nan(NumIntRun, NumIntegrators, 2);
for rId = 1:NumIntRun
    for iId = 1:NumIntegrators
        cindex = Yk == rId & Ik == Integrators(iId);
        BandFisherEvoAvg(rId, iId, :) = nanmean(bandfisher(:, cindex), 2);
        BandFisherEvoMed(rId, iId, :) = nanmedian(bandfisher(:, cindex), 2);
        BandFisherEvoStd(rId, iId, :) = nanstd(bandfisher(:, cindex), [], 2);
        BandFisherEvoSte(rId, iId, :) = nanstd(bandfisher(:, cindex), [], 2)./sqrt(sum(cindex));
    end
end


%% Average band-loc fisher per subject
LocFisherSubAvg = nan(NumSubjects, NumIntegrators, NumLocs, NumBands);
LocFisherSubMed = nan(NumSubjects, NumIntegrators, NumLocs, NumBands);
LocFisherSubStd = nan(NumSubjects, NumIntegrators, NumLocs, NumBands);
LocFisherSubSte = nan(NumSubjects, NumIntegrators, NumLocs, NumBands);

for sId = 1:NumSubjects
    for iId = 1:NumIntegrators
        cindex = Sk == sId & Ik == Integrators(iId);
        for lId = 1:NumLocs
            LocFisherSubAvg(sId, iId, lId, :) = nanmean(locfisher(:, lId, cindex), 3);
            LocFisherSubMed(sId, iId, lId, :) = nanmedian(locfisher(:, lId, cindex), 3);
            LocFisherSubStd(sId, iId, lId, :) = nanstd(locfisher(:, lId, cindex), [], 3);
            LocFisherSubSte(sId, iId, lId, :) = nanstd(locfisher(:, lId, cindex), [], 3)./sqrt(sum(cindex));
        end
    end
end


%% Evolution band-loc Fisher over run
NumIntRun = max(Yk);
LocFisherEvoAvg = nan(NumIntRun, NumIntegrators, NumLocs, NumBands);
LocFisherEvoMed = nan(NumIntRun, NumIntegrators, NumLocs, NumBands);
LocFisherEvoStd = nan(NumIntRun, NumIntegrators, NumLocs, NumBands);
LocFisherEvoSte = nan(NumIntRun, NumIntegrators, NumLocs, NumBands);
for rId = 1:NumIntRun
    for iId = 1:NumIntegrators
        cindex = Yk == rId & Ik == Integrators(iId);
        for lId = 1:NumLocs
            LocFisherEvoAvg(rId, iId, lId, :) = nanmean(locfisher(:, lId, cindex), 3);
            LocFisherEvoMed(rId, iId, lId, :) = nanmedian(locfisher(:, lId, cindex), 3);
            LocFisherEvoStd(rId, iId, lId, :) = nanstd(locfisher(:, lId, cindex), [], 3);
            LocFisherEvoSte(rId, iId, lId, :) = nanstd(locfisher(:, lId, cindex), [], 3)./sqrt(sum(cindex));
        end
    end
end


%% Statistical tests

util_bdisp('[stat] - Statical tests on fisher');
SelFisherPVal = ranksum(selfisher(Ik == 1), selfisher(Ik == 2));
disp(['       - Overall selected fisher significance: p<' num2str(SelFisherPVal, 3)]);
BandFisherMuPVal = ranksum(bandfisher(1, Ik == 1), bandfisher(1, Ik == 2));
disp(['       - Overall band fisher (mu) significance: p<' num2str(BandFisherMuPVal, 3)]);
BandFisherBetaPVal = ranksum(bandfisher(2, Ik == 1), bandfisher(2, Ik == 2));
disp(['       - Overall band fisher (beta) significance: p<' num2str(BandFisherBetaPVal, 3)]);

util_bdisp('[stat] - Statical tests on fisher evolution');
SelFisherEvoPVal = nan(NumIntRun, 1);
BandFisherMuEvoPVal = nan(NumIntRun, 1);
BandFisherBetaEvoPVal = nan(NumIntRun, 1);
for rId = 1:NumIntRun
    cindex = Yk == rId;
    SelFisherEvoPVal(rId) = ranksum(selfisher(cindex & Ik == 1), selfisher(cindex & Ik == 2)); 
    disp(['       - Run ' num2str(rId) ' selected fisher significance: p<' num2str(SelFisherEvoPVal(rId), 3)]); 
    BandFisherMuEvoPVal(rId) = ranksum(bandfisher(1, cindex & Ik == 1), bandfisher(1, cindex & Ik == 2)); 
    disp(['       - Run ' num2str(rId) ' band fisher (mu) significance: p<' num2str(BandFisherMuEvoPVal(rId), 3)]); 
    BandFisherBetaEvoPVal(rId) = ranksum(bandfisher(2, cindex & Ik == 1), bandfisher(2, cindex & Ik == 2)); 
    disp(['       - Run ' num2str(rId) ' band fisher (beta) significance: p<' num2str(BandFisherBetaEvoPVal(rId), 3)]); 
end

util_bdisp('[stat] - Statical tests on location fisher');
MedFisherMuPVal = ranksum(squeeze(locfisher(1, 1, Ik == 1)), squeeze(locfisher(1, 1, Ik == 2)));
disp(['       - Overall band medial fisher (mu) significance: p<' num2str(MedFisherMuPVal, 3)]);
MedFisherBetaPVal = ranksum(squeeze(locfisher(2, 1, Ik == 1)), squeeze(locfisher(2, 1, Ik == 2)));
disp(['       - Overall band medial fisher (beta) significance: p<' num2str(MedFisherBetaPVal, 3)]);
LatFisherMuPVal = ranksum(squeeze(locfisher(1, 2, Ik == 1)), squeeze(locfisher(1, 2, Ik == 2)));
disp(['       - Overall band lateral fisher (mu) significance: p<' num2str(LatFisherMuPVal, 3)]);
LatFisherBetaPVal = ranksum(squeeze(locfisher(2, 2, Ik == 1)), squeeze(locfisher(2, 2, Ik == 2)));
disp(['       - Overall band lateral fisher (beta) significance: p<' num2str(LatFisherBetaPVal, 3)]);


util_bdisp('[stat] - Statical tests on location fisher evolution');
MedFisherMuEvoPVal   = nan(NumIntRun, 1);
MedFisherBetaEvoPVal = nan(NumIntRun, 1);
LatFisherMuEvoPVal   = nan(NumIntRun, 1);
LatFisherBetaEvoPVal = nan(NumIntRun, 1);
for rId = 1:NumIntRun
    cindex = Yk == rId;
    MedFisherMuEvoPVal(rId) = ranksum(squeeze(locfisher(1, 1, cindex & Ik == 1)), squeeze(locfisher(1, 1, cindex & Ik == 2))); 
    disp(['       - Run ' num2str(rId) ' medial fisher (mu) significance: p<' num2str(MedFisherMuEvoPVal(rId), 3)]); 
    MedFisherBetaEvoPVal(rId) = ranksum(squeeze(locfisher(2, 1, cindex & Ik == 1)), squeeze(locfisher(2, 1, cindex & Ik == 2))); 
    disp(['       - Run ' num2str(rId) ' medial fisher (beta) significance: p<' num2str(MedFisherBetaEvoPVal(rId), 3)]); 
    LatFisherMuEvoPVal(rId) = ranksum(squeeze(locfisher(1, 2, cindex & Ik == 1)), squeeze(locfisher(1, 2, cindex & Ik == 2))); 
    disp(['       - Run ' num2str(rId) ' lateral fisher (mu) significance: p<' num2str(LatFisherMuEvoPVal(rId), 3)]); 
    LatFisherBetaEvoPVal(rId) = ranksum(squeeze(locfisher(2, 2, cindex & Ik == 1)), squeeze(locfisher(2, 2, cindex & Ik == 2))); 
    disp(['       - Run ' num2str(rId) ' lateral fisher (beta) significance: p<' num2str(LatFisherBetaEvoPVal(rId), 3)]); 
end

%% Figure
fig1 = figure;
fig_set_position(fig1, 'All');

NumRows = 3;
NumCols = 3;
color = [0 0.4470 0.7410; 0.8500 0.3250 0.0980];

% Overall selected fisher
subplot(NumRows, NumCols, 1);
cavg = [mean(selfisher(Ik == 1)); mean(selfisher(Ik == 2))];
cstd = [std(selfisher(Ik == 1))./sqrt(sum(Ik == 1)); std(selfisher(Ik == 2))./sqrt(sum(Ik == 2))];
superbar(cavg, 'E',  cstd, 'ErrorbarStyle', 'T', 'BarWidth', 0.3, 'BarFaceColor', color, 'BarEdgeColor', [.4 .4 .4], 'BarLineWidth', .1, 'ErrorbarLineWidth', .1, 'P', [NaN SelFisherPVal; SelFisherPVal NaN], 'PLineWidth', 0.5)
xlim([0.5 2.5]);
ylim([0 1.2]);
set(gca, 'XTick', 1:2);
set(gca, 'XTickLabel', {'discrete', 'continuous'});
xlabel('Modality');
ylabel('[]');
title('Average fisher on selected features (+/- SEM)');
grid on;

% Average evolution selected fisher per run
subplot(NumRows, NumCols, [2 3]);
errorbar(SelFisherEvoAvg, SelFisherEvoSte, 'o-');
xlim([0.5 NumIntRun + 0.5]);
ylim([0 1.2]);
grid on;
set(gca, 'XTick', 1:NumIntRun);
ylabel('[]');
xlabel('Run');
title('Average fisher on selected features per run (+/- SEM)');
legend('discrete', 'continuous', 'location', 'best');

suptitle('BCI online fisher');

% Overall band fisher (mu)
subplot(NumRows, NumCols, NumCols + 1);
cavg = [mean(bandfisher(1, Ik == 1), 2); mean(bandfisher(1, Ik == 2), 2)];
cstd = [std(bandfisher(1, Ik == 1), [], 2)./sqrt(sum(Ik == 1)); std(bandfisher(1, Ik == 2), [], 2)./sqrt(sum(Ik == 2))];
superbar(cavg, 'E',  cstd, 'ErrorbarStyle', 'T', 'BarWidth', 0.3, 'BarFaceColor', color, 'BarEdgeColor', [.4 .4 .4], 'BarLineWidth', .1, 'ErrorbarLineWidth', .1, 'P', [NaN SelFisherPVal; SelFisherPVal NaN], 'PLineWidth', 0.5)
xlim([0.5 2.5]);
ylim([0 0.3]);
set(gca, 'XTick', 1:2);
set(gca, 'XTickLabel', {'discrete', 'continuous'});
xlabel('Modality');
ylabel('[]');
title('Average fisher on mu band features (+/- SEM)');
grid on;

% Average evolution band fisher (mu) per run
subplot(NumRows, NumCols, NumCols + [2 3]);
errorbar(BandFisherEvoAvg(:, :, 1), BandFisherEvoSte(:, :, 1), 'o-');
xlim([0.5 NumIntRun + 0.5]);
ylim([0 0.3]);
grid on;
set(gca, 'XTick', 1:NumIntRun);
ylabel('[]');
xlabel('Run');
title('Average fisher on mu band per run (+/- SEM)');
legend('discrete', 'continuous', 'location', 'best');

% Overall band fisher (beta)
subplot(NumRows, NumCols, 2*NumCols + 1);
cavg = [mean(bandfisher(2, Ik == 1), 2); mean(bandfisher(2, Ik == 2), 2)];
cstd = [std(bandfisher(2, Ik == 1), [], 2)./sqrt(sum(Ik == 1)); std(bandfisher(2, Ik == 2), [], 2)./sqrt(sum(Ik == 2))];
superbar(cavg, 'E',  cstd, 'ErrorbarStyle', 'T', 'BarWidth', 0.3, 'BarFaceColor', color, 'BarEdgeColor', [.4 .4 .4], 'BarLineWidth', .1, 'ErrorbarLineWidth', .1, 'P', [NaN SelFisherPVal; SelFisherPVal NaN], 'PLineWidth', 0.5)
xlim([0.5 2.5]);
ylim([0 0.16]);
set(gca, 'XTick', 1:2);
set(gca, 'XTickLabel', {'discrete', 'continuous'});
xlabel('Modality');
ylabel('[]');
title('Average fisher on mu band features (+/- SEM)');
grid on;

% Average evolution band fisher (beta) per run
subplot(NumRows, NumCols, 2*NumCols + [2 3]);
errorbar(BandFisherEvoAvg(:, :, 2), BandFisherEvoSte(:, :, 2), 'o-');
xlim([0.5 NumIntRun + 0.5]);
ylim([0 0.16]);
grid on;
set(gca, 'XTick', 1:NumIntRun);
ylabel('[]');
xlabel('Run');
title('Average fisher on mu band per run (+/- SEM)');
legend('discrete', 'continuous', 'location', 'best');

suptitle('BCI online fisher');

%% Figure 2
fig2 = figure;
fig_set_position(fig2, 'All');

NumRows = 2;
NumCols = 4;

% Overall medial fisher (mu)
subplot(NumRows, NumCols, 1);
cavg = [mean(locfisher(1, 1, Ik == 1), 3); mean(locfisher(1, 1, Ik == 2), 3)];
cstd = [std(locfisher(1, 1, Ik == 1), [], 3)./sqrt(sum(Ik == 1)); std(locfisher(1, 1, Ik == 2), [], 3)./sqrt(sum(Ik == 2))];
superbar(cavg, 'E',  cstd, 'ErrorbarStyle', 'T', 'BarWidth', 0.3, 'BarFaceColor', color, 'BarEdgeColor', [.4 .4 .4], 'BarLineWidth', .1, 'ErrorbarLineWidth', .1, 'P', [NaN MedFisherMuPVal; MedFisherMuPVal NaN], 'PLineWidth', 0.5)
xlim([0.5 2.5]);
ylim([0 0.36]);
set(gca, 'XTick', 1:2);
set(gca, 'XTickLabel', {'discrete', 'continuous'});
xlabel('Modality');
ylabel('[]');
title('Mu medial features (+/- SEM)');
grid on;

% Overall lateral fisher (mu)
subplot(NumRows, NumCols, 2);
cavg = [mean(locfisher(1, 2, Ik == 1), 3); mean(locfisher(1, 2, Ik == 2), 3)];
cstd = [std(locfisher(1, 2, Ik == 1), [], 3)./sqrt(sum(Ik == 1)); std(locfisher(1, 2, Ik == 2), [], 3)./sqrt(sum(Ik == 2))];
superbar(cavg, 'E',  cstd, 'ErrorbarStyle', 'T', 'BarWidth', 0.3, 'BarFaceColor', color, 'BarEdgeColor', [.4 .4 .4], 'BarLineWidth', .1, 'ErrorbarLineWidth', .1, 'P', [NaN LatFisherMuPVal; LatFisherMuPVal NaN], 'PLineWidth', 0.5)
xlim([0.5 2.5]);
ylim([0 0.36]);
set(gca, 'XTick', 1:2);
set(gca, 'XTickLabel', {'discrete', 'continuous'});
xlabel('Modality');
ylabel('[]');
title('Mu lateral features (+/- SEM)');
grid on;

% Average evolution medial fisher (mu) per run
subplot(NumRows, NumCols, 3);
errorbar(LocFisherEvoAvg(:, :, 1, 1), LocFisherEvoSte(:, :, 1, 1), 'o-');
xlim([0.5 NumIntRun + 0.5]);
ylim([0.14 0.36]);
grid on;
set(gca, 'XTick', 1:NumIntRun);
ylabel('[]');
xlabel('Run');
title('Mu medial per run (+/- SEM)');
legend('discrete', 'continuous', 'location', 'best');

% Average evolution lateral fisher (mu) per run
subplot(NumRows, NumCols, 4);
errorbar(LocFisherEvoAvg(:, :, 2, 1), LocFisherEvoSte(:, :, 2, 1), 'o-');
xlim([0.5 NumIntRun + 0.5]);
ylim([0.14 0.36]);
grid on;
set(gca, 'XTick', 1:NumIntRun);
ylabel('[]');
xlabel('Run');
title('Mu lateral per run (+/- SEM)');
legend('discrete', 'continuous', 'location', 'best');

% % % % beta
% Overall medial fisher (beta)
subplot(NumRows, NumCols, NumCols + 1);
cavg = [mean(locfisher(2, 1, Ik == 1), 3); mean(locfisher(2, 1, Ik == 2), 3)];
cstd = [std(locfisher(2, 1, Ik == 1), [], 3)./sqrt(sum(Ik == 1)); std(locfisher(2, 1, Ik == 2), [], 3)./sqrt(sum(Ik == 2))];
superbar(cavg, 'E',  cstd, 'ErrorbarStyle', 'T', 'BarWidth', 0.3, 'BarFaceColor', color, 'BarEdgeColor', [.4 .4 .4], 'BarLineWidth', .1, 'ErrorbarLineWidth', .1, 'P', [NaN MedFisherBetaPVal; MedFisherBetaPVal NaN], 'PLineWidth', 0.5)
xlim([0.5 2.5]);
ylim([0 0.2]);
set(gca, 'XTick', 1:2);
set(gca, 'XTickLabel', {'discrete', 'continuous'});
xlabel('Modality');
ylabel('[]');
title('Beta medial features (+/- SEM)');
grid on;

% Overall lateral fisher (beta)
subplot(NumRows, NumCols, NumCols + 2);
cavg = [mean(locfisher(2, 2, Ik == 1), 3); mean(locfisher(2, 2, Ik == 2), 3)];
cstd = [std(locfisher(2, 2, Ik == 1), [], 3)./sqrt(sum(Ik == 1)); std(locfisher(2, 2, Ik == 2), [], 3)./sqrt(sum(Ik == 2))];
superbar(cavg, 'E',  cstd, 'ErrorbarStyle', 'T', 'BarWidth', 0.3, 'BarFaceColor', color, 'BarEdgeColor', [.4 .4 .4], 'BarLineWidth', .1, 'ErrorbarLineWidth', .1, 'P', [NaN LatFisherBetaPVal; LatFisherBetaPVal NaN], 'PLineWidth', 0.5)
xlim([0.5 2.5]);
ylim([0 0.2]);
set(gca, 'XTick', 1:2);
set(gca, 'XTickLabel', {'discrete', 'continuous'});
xlabel('Modality');
ylabel('[]');
title('Beta lateral features (+/- SEM)');
grid on;

% Average evolution medial fisher (beta) per run
subplot(NumRows, NumCols, NumCols + 3);
errorbar(LocFisherEvoAvg(:, :, 1, 2), LocFisherEvoSte(:, :, 1, 2), 'o-');
xlim([0.5 NumIntRun + 0.5]);
ylim([0.08 0.2]);
grid on;
set(gca, 'XTick', 1:NumIntRun);
ylabel('[]');
xlabel('Run');
title('Beta medial per run (+/- SEM)');
legend('discrete', 'continuous', 'location', 'best');

% Average evolution lateral fisher (beta) per run
subplot(NumRows, NumCols, NumCols + 4);
errorbar(LocFisherEvoAvg(:, :, 2, 2), LocFisherEvoSte(:, :, 2, 2), 'o-');
xlim([0.5 NumIntRun + 0.5]);
ylim([0.08 0.2]);
grid on;
set(gca, 'XTick', 1:NumIntRun);
ylabel('[]');
xlabel('Run');
title('Beta lateral per run (+/- SEM)');
legend('discrete', 'continuous', 'location', 'best');


suptitle('BCI online fisher per locations');

%% Saving figure
figfilename1 = [figdir '/group_bci_online_fisher.pdf'];
util_bdisp(['[fig] - Saving figure in: ' figfilename1]);
fig_figure2pdf(fig1, figfilename1) 

figfilename2 = [figdir '/group_bci_online_fisher_locations.pdf'];
util_bdisp(['[fig] - Saving figure in: ' figfilename2]);
fig_figure2pdf(fig2, figfilename2) 
