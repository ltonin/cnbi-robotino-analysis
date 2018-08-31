% clearvars; clc;
% 
% subject = 'e8';

datafile    = [subject '_robot_trajectory.mat'];
labelfile   = [subject '_robot_label.mat'];
manualfile  = '00_robot_trajectory.mat';
datapath    = 'analysis/robot/trajectory/';
labelpath   = 'analysis/robot/label/';
savedir     = 'analysis/robot/frechet';

% Create analysis directory
util_mkdir('./', savedir);

%% Loading subject trajectories
util_bdisp(['[io] - Loading trajectory data for subject ' subject ': ' datapath datafile]);
datatrajectory = load([datapath datafile]); 

%% Loading labels
util_bdisp(['[io] - Loading labels for subject ' subject ': ' labelpath labelfile]);
datalabel = load([labelpath labelfile]); 

%% Loading manual trajectories
util_bdisp(['[io] - Loading manual trajectory data: ' datapath manualfile]);
datamanual = load([datapath manualfile]); 

%% Getting information
Trials = unique(datalabel.labels.sample.Tk);
NumTrials = length(Trials);

Ck = datalabel.labels.sample.Ck;
Tk = datalabel.labels.sample.Tk;
strajectory = datatrajectory.trajectory;

mCk = datamanual.labels.raw.sample.Ck;
mtrajectory = datamanual.trajectory;

%% Frechet distance
util_bdisp('[proc] - Computing Frechet distance');
fdistance = zeros(NumTrials, 1);
for trId = 1:NumTrials
    util_disp_progress(trId, NumTrials, ' ')
    
    cindex  = Tk == Trials(trId);
    ctarget = unique(Ck(cindex));
    
    if strcmpi(subject, 'ai6') && (trId == 21)
        disp(['[proc] - Skipping trial 21 for subject ' subject ' (nan values)']);
        continue
    elseif strcmpi(subject, 'ah7') && (trId == 51)
        disp(['[proc] - Skipping trial 51 for subject ' subject ' (nan values)']);
        continue
    elseif strcmpi(subject, 'ah7') && (trId == 52)
        disp(['[proc] - Skipping trial 52 for subject ' subject ' (nan values)']);
        continue
    elseif strcmpi(subject, 'b4') && (trId <= 10)
        disp(['[proc] - Skipping trial <=10 (first run) for subject ' subject ' (nan values)']);
        continue
    end
    
    crefpath = mtrajectory(mCk == ctarget, :);
    cpath    = strajectory(cindex, :);
    fdistance(trId) = proc_frechet_distance(crefpath, cpath);
end

%% Saving subject data
filename = fullfile(savedir, [subject '_robot_frechet.mat']);
util_bdisp(['[out] - Saving subject data in: ' filename]);
frechet     = fdistance;
save(filename, 'frechet');

% %% Statistics
% util_bdisp('[proc] - Computing statistics');
% fdistance_pval = zeros(NumTargets, 1);
% for tgId = 1:NumTargets
%     cindex1 = Xk == 1 & Vk == 1 & Ik == 1 & Ck == tgId;
%     cindex2 = Xk == 1 & Vk == 1 & Ik == 2 & Ck == tgId;
%     if sum(cindex1)==0 || sum(cindex2)==0
%         disp(['[stat] - Skipping target ' Targets(tgId) ': no data available']);
%         continue;
%     end
%     fdistance_pval(tgId) = ranksum(fdistance(cindex1), fdistance(cindex2));
%     
%     disp(['[stat] - Wilcoxon test on frechet distance for target ' num2str(tgId) ': p=' num2str(fdistance_pval(tgId),3)]); 
% end
% 
% %% Saving subject data
% filename = fullfile(savedir, [subject '_robot_trajectory.mat']);
% util_bdisp(['[out] - Saving subject data in: ' filename]);
% trajectory  = tracking;
% mtrajectory = mtracking;
% frechet     = fdistance;
% labels.sample.Rk = lbls.Rk;
% labels.sample.Ik = lbls.Ik;
% labels.sample.Dk = lbls.Dk;
% labels.sample.Tk = lbls.Tk;
% labels.sample.Ck = lbls.Ck;
% labels.trial.Ik  = Ik;
% labels.trial.Rk  = Rk;
% labels.trial.Dk  = Dk;
% labels.trial.Ck  = Ck;
% labels.trial.Tk  = Tk;
% labels.trial.Xk  = Xk;
% labels.trial.Vk  = Vk;
% save(filename, 'trajectory', 'mtrajectory', 'frechet', 'labels');
% 
% %% Plotting
% 
% if DoPlot == false
%     return
% end
% 
% util_bdisp('[out] - Plotting subject trajectories');
% fig1 = figure;
% fig_set_position(fig1, 'Top');
% for iId = 1:NumIntegrators
%     cindex  = Ik == Integrators(iId);% & Xk == true & Vk == true;
%     
%     subplot(1, 2, iId);
%     imagesc(flipud(nanmean(HitMap(:, :, cindex), 3)'), [0 0.1]);
%     
%     % Plotting average for correct
%     hold on;
%     for tgId = 1:NumTargets
%         cindex = Ik == Integrators(iId) & Ck == Targets(tgId); 
%         
%         cpath = nanmean(rtracking(:, :, cindex & Xk == true & Vk == true), 3); 
%         cpath(:, 2) = abs(cpath(:, 2) - FieldSize(2));
%         cpath = ceil(cpath/MapResolution);
%         if isempty(cpath) == false
%             plot(cpath(:, 1), cpath(:, 2), 'ko', 'MarkerSize', 1);
%         end
%         
%     end
%     hold off;
%     
%     % Plotting manual
%     hold on;
%     for tgId = 1:NumTargets
%         cpath = mtracking(:, :, tgId); 
%         cpath(:, 2) = abs(cpath(:, 2) - FieldSize(2));
%         cpath = ceil(cpath/MapResolution);
%         if isempty(cpath) == false
%             plot(cpath(:, 1), cpath(:, 2), 'g', 'MarkerSize', 1);
%         end
%         
%     end
%     hold off;
%     
%     axis image
%     xlabel('[cm]');
%     ylabel('[cm]');
%     title([subject ' - ' IntegratorName{iId}]);
%     cnbirob_draw_field(mTargetPos, mTargetRadius, mFieldSize, 'flipped', true)
%     set(gca, 'XTickLabel', '')
%     set(gca, 'YTickLabel', '')
% end
% 
% fig2 = figure;
% fig_set_position(fig2, 'All');
% for iId = 1:NumIntegrators
%     for tgId = 1:NumTargets
%         cindex = Ik == Integrators(iId)  & Ck == Targets(tgId);
%         
%         subplot(2, NumTargets, tgId + NumTargets*(iId-1));
%         imagesc(flipud(nanmean(HitMap(:, :, cindex), 3)'), [0 0.5]);
%         
%         hold on;
%         cpath = nanmean(rtracking(:, :, cindex & Xk == true & Vk == true), 3); 
%         cpath(:, 2) = abs(cpath(:, 2) - FieldSize(2));
%         cpath = ceil(cpath/MapResolution);
%         if isempty(cpath) == false
%             plot(cpath(:, 1), cpath(:, 2), 'ko', 'MarkerSize', 1);
%         end
%         hold off;
%         
%         
%         % Plotting manual
%         hold on;
%         cmpath = mtracking(:, :, tgId); 
%         cmpath(:, 2) = abs(cmpath(:, 2) - FieldSize(2));
%         cmpath = ceil(cmpath/MapResolution);
%         if isempty(cmpath) == false
%             plot(cmpath(:, 1), cmpath(:, 2), 'g', 'MarkerSize', 1);
%         end
%         hold off;
%        
%         
%         axis image
%         xlabel('[cm]');
%         ylabel('[cm]');
%         title(TargetName{tgId});
%         cnbirob_draw_field(mTargetPos, mTargetRadius, mFieldSize, 'flipped', true)
%         set(gca, 'XTickLabel', '')
%         set(gca, 'YTickLabel', '')
%     end
% end
% suptitle(['Subject ' subject]);
% 
% %% Fig 3
% fig3 = figure;
% fig_set_position(fig3, 'Top');
% for iId = 1:NumIntegrators
%     subplot(1, NumIntegrators, iId);
%     
%     hold on;
%     
%     for trId = 1:NumTrials
%         cindex = Ik == Integrators(iId) & Tk == Trials(trId);
%         
%         if sum(cindex) == 0
%             continue;
%         end
%         
%         cpath = rtracking(:, :, cindex);
%         
%         cstyle = 'or';
%         if Xk(trId) == true
%             cstyle = 'og';
%         end
%         
%         plot(cpath(:, 1), cpath(:, 2), cstyle, 'MarkerSize', 0.05);
%     end
%         
%     
%     % Plotting average for correct
%     for tgId = 1:NumTargets
%         cindex = Ik == Integrators(iId) & Ck == Targets(tgId); 
%         
%         cpath = nanmean(rtracking(:, :, cindex & Xk == true & Vk == true), 3); 
%         
%         if isempty(cpath) == false
%             plot(cpath(:, 1), cpath(:, 2), 'ko', 'MarkerSize', 1);
%         end
%         
%     end
%     hold off;
%     
%     % Plotting manual
%     hold on;
%     for tgId = 1:NumTargets
%         cpath = mtracking(:, :, tgId); 
%         
%         if isempty(cpath) == false
%             plot(cpath(:, 1), cpath(:, 2), 'k--', 'MarkerSize', 1);
%         end
%         
%     end
%     hold off;
%     
%     % Draw field
%     cnbirob_draw_field(TargetPos, TargetRadius, FieldSize);
%     axis image
%     xlim([1 FieldSize(1)]);
%     ylim([1 FieldSize(2)]);
%     grid on;
%     xlabel('[cm]');
%     ylabel('[cm]');
%     title([subject ' - ' IntegratorName{iId}]);
%     set(gca, 'XTickLabel', '')
%     set(gca, 'YTickLabel', '')
%     
% end
% 
% %% Fig4
% fig4 = figure;
% fig_set_position(fig4, 'Top');
% 
% boxplot(fdistance(Xk == 1 & Vk == 1), {Ck(Xk == 1 & Vk == 1) Ik(Xk == 1 & Vk == 1)}, 'factorseparator', 1, 'labels', num2cell(Ck(Xk==1 & Vk == 1)), 'labelverbosity', 'minor');
% grid on;
% xlabel('Target');
% ylabel('[cm]');
% title(['Subject ' subject ' - Frechet distance per target']);

