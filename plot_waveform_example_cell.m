
opt = struct;

opt.session = 'm80_200317'; % dataset to process
opt.clu_id = 426;

opt.gain = 500;
opt.samp_freq = 30000;
opt.samp_before = 30; % samples before each spike to read
opt.samp_after = 60; % samples after each spike to read
opt.num_spikes_to_read = 200; % downsample num spikes for speed

%% deal with some path names
top_data_dir = 'D:\mike_neuropix_data';
opt.data_dir = dir(fullfile(top_data_dir,sprintf('%s_g*',opt.session)));
opt.data_dir = fullfile(top_data_dir,opt.data_dir.name);
[~,main_name]=fileparts(opt.data_dir);
opt.spike_dir = fullfile(opt.data_dir,strcat(main_name,'_imec0'));

%% get channel this unit is on
cluster_info = tdfread(fullfile(opt.spike_dir,'cluster_info.tsv'));
main_chan = cluster_info.ch(cluster_info.id==opt.clu_id)+1;
opt.ch_to_read = main_chan;
% opt.ch_to_read = main_chan-4:main_chan+4; 

%% get samples of spikes for this neuron
spike_samp = get_spike_samp(opt.data_dir,opt.clu_id);

%% read raw data: spikes

% options for spike snippets
opt_spk = opt;
opt_spk.trigger = sort(randsample(spike_samp,opt.num_spikes_to_read)); % in samples

num_samp_spk = 1+opt_spk.samp_before+opt_spk.samp_after;

dat_spk = read_raw_data_snippets(opt_spk);


%% plot spike waveforms

t_spk = 1000*(-opt_spk.samp_before:opt_spk.samp_after)/opt.samp_freq;

mean_waveform = squeeze(mean(dat_spk,2));

hfig = figure;
hfig.Name = sprintf('%s c%d',opt.session,opt.clu_id);
baseline = mean(mean_waveform(1:opt_spk.samp_before/2));
plot(t_spk,(mean_waveform-baseline)/opt.gain*1000,'Color','k','LineWidth',1.5);
title(sprintf('ch %d',opt.ch_to_read-1));   
xlabel('ms')
ylabel('uV')
