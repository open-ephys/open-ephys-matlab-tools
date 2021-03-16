function plotContinuousWithSpikes(handle, stream, spikes)

    t = spikes.timestamps;
    tx = [t.';t.';nan(1,length(t))];
    ymin = double(min(stream.samples(1,:))).*ones(1,length(t));
    ymax = double(max(stream.samples(1,:))).*ones(1,length(t));
    ty = [ymin;ymax;nan(1,length(t))];

    plot(handle, stream.samples(1,:)); hold on;
    plot(handle, tx(:),ty(:));

end

function plotContinuousWithEvents(handle, stream, events)


    t = events.timestamp;
    tx = [t.';t.';nan(1,length(t))];
    ymin = double(min(stream.samples(1,:))).*ones(1,length(t));
    ymax = double(max(stream.samples(1,:))).*ones(1,length(t));
    ty = [ymin;ymax;nan(1,length(t))];

    plot(handle, stream.samples(1,:)); hold on;
    plot(handle, tx(:),ty(:));
    
end
            break; %TODO: plot stereotrodes and tetrodes (only show single-electrodes for now)
            end
        else   %Stream 2 is a sine wave -- overlay detected events (sine wave peaks)
            eventProcessors = rec.ttlEvents.keys;
            for j = 1:length(eventProcessors)
                events = rec.ttlEvents(eventProcessors{j});
                t = events.timestamp;
                tx = [t.';t.';nan(1,length(t))];
                ymin = double(min(stream.samples(1,:))).*ones(1,length(t));
                ymax = double(max(stream.samples(1,:))).*ones(1,length(t));
                ty = [ymin;ymax;nan(1,length(t))];
                plot(tx(:),ty(:));
            end

        end
    end

    figure;
    %Plot the first spike waveform
    spikeProcessors = rec.spikes.keys;
    for i = 1:length(spikeProcessors)
        spikeProcessor = rec.spikes(spikeProcessors{i});
        if ndims(spikeProcessor.waveforms) <= 2
            plot(spikeProcessor.waveforms(1,:));
        end
    end
    
end