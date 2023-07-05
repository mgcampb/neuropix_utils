function [mean_waveform, t_spk] = get_waveform(session,clu_id,opt)
% returns mean waveform in V and time of each sample in msec
% MGC 2/17/2021

% fields for opt:
% gain: gain of AP band in NP recoridng, usually 500
% samp_freq: target sampling frequency of NP recording, usually 30000
% samp_before: number of samples before each spike to reach
% samp_after: number of samples after
% num_spikes: num spikes for calculating mean waveform (random sample)
if ~exist('opt','var')
    opt = struct;
    opt.gain = 500;
    opt.samp_freq = 30000;
    opt.samp_before = 30; % samples before each spike to read
    opt.samp_after = 60; % samples after each spike to read
    opt.num_spikes = 200; % downsample num spikes for speed
end

opt.session = session; % dataset to process
opt.clu_id = clu_id; % cell id to process

%% deal with some path names
top_data_dir = opt.data_dir;
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
opt.num_spikes = min(opt.num_spikes,numel(spike_samp));
opt.trigger = sort(randsample(spike_samp,opt.num_spikes)); % in samples

dat_spk = read_raw_data_snippets(opt);

%% output mean waveform and time stamps
mean_waveform = squeeze(mean(dat_spk,2));
t_spk = 1000*(-opt.samp_before:opt.samp_after)/opt.samp_freq;
