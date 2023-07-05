function hfig = plot_waveform_with_and_without_laser(session,clu_id)

opt = struct;

opt.session = session; % dataset to process
opt.clu_id = clu_id;
opt.laser_dur_all = [5 12 20 30];

opt.gain = 500;
opt.samp_freq = 30000;

%% deal with some path names
top_data_dir = 'D:\DATA\malcolm_data\neuropix_data\';
opt.data_dir = dir(fullfile(top_data_dir,sprintf('%s_g*',opt.session)));
opt.data_dir = fullfile(top_data_dir,opt.data_dir.name);
[~,main_name]=fileparts(opt.data_dir);
opt.spike_dir = fullfile(opt.data_dir,strcat(main_name,'_imec0'));

%% get channel this unit is on
cluster_info = tdfread(fullfile(opt.spike_dir,'cluster_info.tsv'));
main_chan = cluster_info.ch(cluster_info.id==opt.clu_id)+1;
% opt.ch_to_read = main_chan-6:main_chan+6;
opt.ch_to_read = main_chan-4:main_chan+4; 

%% get samples of spikes for this neuron
spike_samp = get_spike_samp(opt.data_dir,opt.clu_id);

%% get laser pulses in samples
[laser_on_samp, laser_off_samp, laser_dur_ms] = get_laser_samp(opt.data_dir);

%% read raw data: spikes

% options for spike snippets
opt_spk = opt;
opt_spk.trigger = spike_samp; % in samples
opt_spk.samp_before = 30; % samples before each trigger to read
opt_spk.samp_after = 60; % samples after each trigger to read
num_samp_spk = 1+opt_spk.samp_before+opt_spk.samp_after;

dat_spk = read_raw_data_snippets(opt_spk);


%% read raw data: laser

% options for laser snippets
opt_laser = opt;
opt_laser.trigger = laser_on_samp; % in samples
opt_laser.samp_before = 200; % samples before each trigger to read
opt_laser.samp_after = 1200; % samples after each trigger to read
num_samp_laser = 1+opt_laser.samp_before+opt_laser.samp_after;

dat_laser = read_raw_data_snippets(opt_laser);

%% plot spike waveforms

t_spk = 1000*(-opt_spk.samp_before:opt_spk.samp_after)/opt.samp_freq;
% figure;
% axmax = 0;
% for i = 1:size(dat_spk,1)
%     subplot(4,4,i);
%     tmp = mean(squeeze(dat_spk(i,:,:)));
%     baseline = mean(tmp(1:opt_spk.samp_before/2));
%     plot(t_spk,(tmp-baseline)/opt.gain*1000);
%     title(opt.ch_to_read(i));
%     axmax = max(axmax,max(abs(ylim())));
% end
% for i = 1:size(dat_spk,1)
%     subplot(4,4,i); hold on;
%     ylim([-axmax axmax]);
%     % ylim([-50 50]);
% end

%% plot laser artifact

% t_laser = 1000*(-opt_laser.samp_before:opt_laser.samp_after)/opt.samp_freq;
% figure;
% hold on;
% for i = 1:size(dat_laser,1)
%     tmp = mean(squeeze(dat_laser(i,:,:)));
%     baseline = mean(tmp(1:opt_laser.samp_before/2));
%     plot(t_laser,(tmp-baseline)/opt.gain*1000);
%     % title(opt.ch_to_read(i));
%     % ylim([-50 50]);
% end
% plot([0 0],ylim(),'k--');
% for i = 1:numel(opt.laser_dur_all)
%     plot([opt.laser_dur_all(i) opt.laser_dur_all(i)],ylim(),'k--');
% end
% xlabel('time from laser start (ms)');
% ylabel('uV');
% legend(strcat('ch',num2str(opt.ch_to_read')),'Location','southeast');
% title('Laser artifact');

%% get mean waveform across channels for each length of laser pulse

mean_laser = nan(numel(opt.laser_dur_all),num_samp_laser);
for i = 1:numel(opt.laser_dur_all)
    tmp = mean(squeeze(mean(dat_laser(:,laser_dur_ms==opt.laser_dur_all(i),:))));
    baseline = mean(tmp(1:opt_laser.samp_before/2));
    mean_laser(i,:) = (tmp-baseline);
end


% figure; hold on;
% for i = 1:numel(opt.laser_dur_all)
%     plot(t_laser,mean_laser(i,:)/opt.gain*1000);
% end
% plot([0 0],ylim(),'k--');
% for i = 1:numel(opt.laser_dur_all)
%     plot([opt.laser_dur_all(i) opt.laser_dur_all(i)],ylim(),'k--');
% end
% xlabel('time from laser start (ms)');
% ylabel('uV');
% legend(strcat(num2str(opt.laser_dur_all'),' ms'),'Location','southeast');
% title('Laser artifact');

%% subtract mean laser artifact

laser_on = zeros(size(spike_samp));
for i = 1:numel(spike_samp)
    nearest_onset = find(laser_on_samp<=spike_samp(i),1,'last');
    nearest_offset = find(laser_off_samp>=spike_samp(i),1,'first');
    if nearest_onset == nearest_offset
        laser_on(i) = 1;
    end
end

laser_spk_idx = find(laser_on);
dat_spk_subtr = dat_spk;
for i = 1:sum(laser_on)
    spk_samp_this = spike_samp(laser_spk_idx(i));
    nearest_laser_on_idx = find(laser_on_samp<=spk_samp_this,1,'last');
    nearest_laser_on_samp = laser_on_samp(nearest_laser_on_idx);
    laser_dur_this = find(opt.laser_dur_all == laser_dur_ms(nearest_laser_on_idx));
    if ~isnan(laser_dur_this)
        mean_laser_zero_pad = [mean_laser(laser_dur_this,:) zeros(1,100)];
        start_samp = spk_samp_this-nearest_laser_on_samp+opt_laser.samp_before-opt_spk.samp_before;
        for j = 1:numel(opt.ch_to_read)
            dat_spk_this = squeeze(dat_spk_subtr(j,laser_spk_idx(i),:));
            subtr_this = mean_laser_zero_pad(start_samp:start_samp+num_samp_spk-1)';
            dat_spk_subtr(j,laser_spk_idx(i),:) = dat_spk_this-subtr_this;
        end
    end
end

%% plot spike waveforms before laser artifact subtraction

% hfig = figure;
% hfig.Name = sprintf('%s c%d noSubtract',opt.session,opt.clu_id);
% axmax = 0;
% for i = 1:size(dat_spk,1)
%     subplot(4,4,i); hold on;
%     
%     tmp = mean(squeeze(dat_spk(i,laser_on==0,:)));
%     baseline = mean(tmp(1:opt_spk.samp_before/2));
%     plot(t_spk,(tmp-baseline)/opt.gain*1000);
%     
%     tmp = mean(squeeze(dat_spk(i,laser_on==1,:)));
%     baseline = mean(tmp(1:opt_spk.samp_before/2));
%     plot(t_spk,(tmp-baseline)/opt.gain*1000);    
%     
%     axmax = max(axmax,max(abs(ylim())));
%     
%     title(opt.ch_to_read(i)-1);
%     
% end
% for i = 1:size(dat_spk,1)
%     subplot(4,4,i); hold on;
%     ylim([-axmax axmax]);
%     % ylim([-50 50]);
% end

%% plot spike waveforms after laser artifact subtraction

hfig = figure;
hfig.Name = sprintf('%s c%d Subtract',opt.session,opt.clu_id);
axmax = 0;
for i = 1:size(dat_spk,1)
    subplot(3,3,i); hold on;
    
    tmp = mean(squeeze(dat_spk_subtr(i,laser_on==0,:)));
    baseline = mean(tmp(1:opt_spk.samp_before/2));
    plot(t_spk,(tmp-baseline)/opt.gain*1000,'LineWidth',1.5);
    
    tmp = mean(squeeze(dat_spk_subtr(i,laser_on==1,:)));
    baseline = mean(tmp(1:opt_spk.samp_before/2));
    plot(t_spk,(tmp-baseline)/opt.gain*1000,'LineWidth',1.5);
    
    
    axmax = max(axmax,max(abs(ylim())));
    
    title(opt.ch_to_read(i)-1);
    
end
for i = 1:size(dat_spk,1)
    subplot(3,3,i); hold on;
    ylim([-axmax axmax]);
    % ylim([-50 50]);
end
subplot(3,3,7)
xlabel('ms')
ylabel('uV')

end