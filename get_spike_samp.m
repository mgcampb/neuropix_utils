function spike_samp = get_spike_samp(data_dir,clu_id)

%% location of data
[~,main_name]=fileparts(data_dir);
spike_dir = fullfile(data_dir,strcat(main_name,'_imec0'));

%% find sample rate that was entered into KS2 (probably 30KHz)
ks_params_file = fullfile(spike_dir,'params.py');
fp_ks = fopen(ks_params_file);
dat=textscan(fp_ks,'%s %s','Delimiter','=');
names=dat{1};
vals=dat{2};
loc=contains(names,'sample_rate');
ks_sampling_rate = str2double(vals{loc});
fclose(fp_ks);

%% load spike times
% fprintf('loading spike data...\n');
sp = loadKSdir(spike_dir);
% cut off the last 100 ms (was causing issues with waveform)
keep = sp.st<max(sp.st)-0.1;
sp.st = sp.st(keep);
sp.clu = sp.clu(keep);

% convert spike times to samples
st_in_samp=sp.st*ks_sampling_rate;
spike_samp = st_in_samp(sp.clu==clu_id);

end