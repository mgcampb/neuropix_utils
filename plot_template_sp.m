function hfig = plot_template_sp(sp,cid)
%PLOT_WAVEFORM_SP Plot KS template from the "temps" argument of sp
%   Detailed explanation goes here

hfig = figure('Position',[600 200 200 800]);

if cid+1>size(sp.temps,1)
    fprintf('\tmerged unit, no template');
else
    tmp = squeeze(sp.temps(cid+1,:,:))';

    [max_amp,max_chan] = max(max(abs(tmp),[],2));

    max_amp = ceil(max_amp/10)*10;

    if mod(max_chan,2)==0
        offset = -8;
    else
        offset = -7;
    end

    for i = 1:16
        subplot(8,2,i);
        plot_idx = max_chan+offset+i;
        if plot_idx>0 && plot_idx<size(tmp,1)
            plot(tmp(plot_idx,:)); 
        end
        ylim([-max_amp max_amp]);
        axis off;
        title(sprintf('%d',plot_idx));
    end
end

end

