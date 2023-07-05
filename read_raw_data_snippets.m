function dat = read_raw_data_snippets(opt)

% Input:
% opt = struct;
% opt.data_dir = 'D:\DATA\malcolm_data\neuropix_data\MC12_20210101_optotag_g0'; % dataset to process
% opt.ch_to_read = 62:74; % which channels to read
% opt.trigger = spike_samp; % in samples
% opt.samp_before = 30; % samples before each trigger to read
% opt.samp_after = 60; % samples after each trigger to read

% Output:
% dat = array of size NumChannels * NumTrigger * NumSamp

%% location of data
[~,main_name]=fileparts(opt.data_dir);
spike_dir = fullfile(opt.data_dir,strcat(main_name,'_imec0'));

%% read np data

% fprintf('Reading data... ');
% tic

np_file = fullfile(spike_dir,strcat(main_name,'_t0.imec0.ap.bin'));
fp = fopen(np_file);

num_samp = opt.samp_before+opt.samp_after+1; % number of samples per snippet
dat = nan(numel(opt.ch_to_read),numel(opt.trigger),num_samp);
for i = 1:numel(opt.ch_to_read) 
    for j = 1:numel(opt.trigger)
        start_samp = 2*((opt.ch_to_read(i)-1) + 385*(opt.trigger(j)-opt.samp_before-1));
        fseek(fp,start_samp,'bof');
        dat(i,j,:) = fread(fp,[1 num_samp],'*int16',384*2);
    end   
end
% toc
fclose(fp);

end