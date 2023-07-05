function [laser_on_samp, laser_off_samp, laser_dur_ms] = get_laser_samp(data_dir)

%% libraries
addpath(genpath('C:\code\spikes'));
addpath(genpath('C:\code\npy-matlab'));
addpath(genpath('C:\code\HGRK_analysis_tools'));

%% location of data
[~,main_name]=fileparts(data_dir);
NIDAQ_file = fullfile(data_dir,strcat(main_name,'_t0.nidq.bin'));
NIDAQ_config = fullfile(data_dir,strcat(main_name,'_t0.nidq.meta'));
spike_dir = fullfile(data_dir,strcat(main_name,'_imec0'));

%% hack for when we entered 30000 into KS2 for NP samp rate instead of true calibrated value (usually something like 30000.27)

% find true NP ap sample rate
np_ap_meta_file = fullfile(spike_dir,strcat(main_name,'_t0.imec0.ap.meta'));
fp_np = fopen(np_ap_meta_file);
dat=textscan(fp_np,'%s %s','Delimiter','=');
names=dat{1};
vals=dat{2};
loc=contains(names,'imSampRate');
true_sampling_rate=str2double(vals{loc});
fclose(fp_np);

%% load nidaq data
fprintf('loading nidaq data...\n');

% get nidaq params
dat=textscan(fopen(NIDAQ_config),'%s %s','Delimiter','=');
names=dat{1};
vals=dat{2};
loc=contains(names,'niSampRate');
daq_sampling_rate=str2double(vals{loc});

nSavedChans = str2double(vals(strcmp(names,'nSavedChans')));

% load nidaq data
fpNIDAQ=fopen(NIDAQ_file);
daq_data=fread(fpNIDAQ,[nSavedChans,Inf],'*int16');
daq_time = (1:size(daq_data,2))/daq_sampling_rate;
fclose(fpNIDAQ);


%% CORRECT FOR DRIFT BETWEEN IMEC AND NIDAQ BOARDS

% TWO-PART CORRECTION
% 1. Get sync pulse times relative to NIDAQ and Imec boards.  
% 2. Quantify difference between the two sync pulse times and correct in
% spike.st. 
% PART 1: GET SYNC TIMES RELATIVE TO EACH BOARD
% We already loaded most of the NIDAQ data above. Here, we access the sync
% pulses used to sync Imec and NIDAQ boards together. The times a pulse is
% emitted and registered by the NIDAQ board are stored in syncDatNIDAQ below.

fprintf('correcting drift...\n');
syncDatNIDAQ=daq_data(1,:)>1000;

% convert NIDAQ sync data into time data by dividing by the sampling rate
ts_NIDAQ = strfind(syncDatNIDAQ,[0 1])/daq_sampling_rate; 

% ts_NIDAQ: these are the sync pulse times relative to the NIDAQ board
% Now, we do the same, but from the perspective of the Imec board. 
LFP_config = dir(fullfile(spike_dir,'*.lf.meta'));
LFP_config = fullfile(LFP_config.folder,LFP_config.name);
LFP_file = dir(fullfile(spike_dir,'*.lf.bin'));
LFP_file = fullfile(LFP_file.folder,LFP_file.name);
dat=textscan(fopen(LFP_config),'%s %s','Delimiter','=');
names=dat{1};
vals=dat{2};
loc=contains(names,'imSampRate');
lfp_sampling_rate=str2double(vals{loc});

% for loading only a portion of the LFP data
fpLFP = fopen(LFP_file);
fseek(fpLFP, 0, 'eof'); % go to end of file
fpLFP_size = ftell(fpLFP); % report size of file
fpLFP_size = fpLFP_size/(2*384); 
fclose(fpLFP);

% get the sync pulse times relative to the Imec board
fpLFP=fopen(LFP_file);
fseek(fpLFP,384*2,0);
ftell(fpLFP);
datLFP=fread(fpLFP,[1,round(fpLFP_size/4)],'*int16',384*2); % this step used to take forever
fclose(fpLFP);
syncDatLFP=datLFP(1,:)>10; 
ts_LFP = strfind(syncDatLFP,[0 1])/lfp_sampling_rate;

% ts_LFP: these are the sync pulse times relative to the Imec board
% PART 2: TIME CORRECTION
fit = polyfit(ts_NIDAQ(1:size(ts_LFP,2)),ts_LFP,1);

% convert NIDAQ time to Imec time
% daq_time_corr = fit(1)*daq_time+fit(2); % Use intercept or not??
daq_time_corr = fit(1)*daq_time;

%% get laser times

fprintf('processing nidaq data...\n');
if nSavedChans == 6
    ch_laser = 3;
elseif nSavedChans == 9
    ch_laser = 5;
end

% LASER
laser_voltage = double(daq_data(ch_laser,:));
% binarize signal
laser_voltage(laser_voltage <= max(laser_voltage)*0.8) = 0;
laser_voltage(laser_voltage > max(laser_voltage)*0.8) = 1;
laser_onset_idx = find(diff(laser_voltage)>0.5)+1;
laser_onset_ts = daq_time_corr(laser_onset_idx)';
laser_offset_idx = find(diff(laser_voltage)<-0.5)+1;
laser_offset_ts = daq_time_corr(laser_offset_idx)';
laser_dur = laser_offset_ts-laser_onset_ts;
laser_dur_ms = round(laser_dur*1000);
% laser_dur_ms(~ismember(laser_dur_ms,[5 12 20 30]))=nan;

laser_on_samp = round(laser_onset_ts * true_sampling_rate);
laser_off_samp = round(laser_offset_ts * true_sampling_rate);

end