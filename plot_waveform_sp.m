function hfig = plot_waveform_sp(sp,cid)
%PLOT_WAVEFORM_SP Plot waveform from the "mean_waveform" argument of sp
%   Detailed explanation goes here

hfig = figure('Position',[200 200 200 800]);

assert(all(sp.mean_waveforms_cluster_id'==sp.waveform_metrics.cluster_id));

kp = sp.mean_waveforms_cluster_id==cid;
wv = squeeze(sp.mean_waveforms(kp,:,:));


max_chan = sp.waveform_metrics.peak_channel(kp) + 1;
max_amp = sp.waveform_metrics.amplitude(kp);

max_amp = ceil(max_amp/10)*10;

if mod(max_chan,2)==0
    offset = -8;
else
    offset = -7;
end

for i = 1:16
    subplot(8,2,i);
    plot_idx = max_chan+offset+i;
    if plot_idx>0 && plot_idx<size(wv,1)
        plot(wv(plot_idx,:)); 
    end
    ylim([-max_amp max_amp]);
    axis off;
    title(sprintf('%d',plot_idx));
end

end

