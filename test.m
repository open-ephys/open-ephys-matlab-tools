testBinaryFormat = false;
if testBinaryFormat
    
    path = 'SampleData/BinaryFormat/Record Node 118';

    rec = BinaryRecording(path, 1, 1);

    figure('Name', 'BinaryFormatContinuous', 'numbertitle', 'off');
    streams = rec.continuous.keys;
    for i = 1:length(streams)

        stream = rec.continuous(streams{i});
        subplot(length(streams),1,i);
        plot(stream.samples(1,:)); hold on;

        if i == 1 %Stream 1 is 16CH neural data -- overlay detected spikes 
            spikeProcessors = rec.spikes.keys;
            for j = 1:length(spikeProcessors)
                spikeProcessor = rec.spikes(spikeProcessors{j}); 
                t = spikeProcessor.timestamps;
                tx = [t.';t.';nan(1,length(t))];
                ymin = double(min(stream.samples(1,:))).*ones(1,length(t));
                ymax = double(max(stream.samples(1,:))).*ones(1,length(t));
                ty = [ymin;ymax;nan(1,length(t))];
                plot(tx(:),ty(:));
                break; %only plot single electrode data
            end
        else   %Stream 2 is a 16CH sine wave -- overlay detected events (sine wave peaks)
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

    figure('Name', 'BinaryFormatSpike', 'numbertitle', 'off');
    %Plot all spikes from first spike
    spikeProcessors = rec.spikes.keys;
    for i = 1:length(spikeProcessors)
        spikeProcessor = rec.spikes(spikeProcessors{i});
        plot(spikeProcessor.waveforms(1,:));
        sample = spikeProcessor.waveforms(1,:);
        break;
    end

end

testOpenEphysFormat = false;
if testOpenEphysFormat
    
    path = 'SampleData/OpenEphysFormat/Record Node 118';

    rec = OpenEphysRecording(path, 0, 0);

    figure;
    streams = rec.continuous.keys;
    for i = 1:length(streams)

        stream = rec.continuous(streams{i});
        subplot(length(streams),1,i);
        plot(stream.samples(1,:)); hold on;

        if i == 1 %Stream 1 is neural data -- overlay detected spikes 
            spikeProcessors = rec.spikes.keys;
            for j = 1:length(spikeProcessors)
                spikeProcessor = rec.spikes(spikeProcessors{j}); 
                t = spikeProcessor.timestamps - min(spikeProcessor.timestamps);
                tx = [t.';t.';nan(1,length(t))];
                ymin = double(min(stream.samples(1,:))).*ones(1,length(t));
                ymax = double(max(stream.samples(1,:))).*ones(1,length(t));
                ty = [ymin;ymax;nan(1,length(t))];
                plot(tx(:),ty(:));
                break; %only plot single electrode data
            end
        else   %Stream 2 is a sine wave -- overlay detected events (sine wave peaks)
            eventProcessors = rec.ttlEvents.keys;
            for j = 1:length(eventProcessors)
                events = rec.ttlEvents(eventProcessors{j});
                t = events.timestamp - min(events.timestamp);
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
        plot(spikeProcessor.waveforms(1,:));
        sample = spikeProcessor.waveforms(1,:);
        break;
    end

end

testKwikFormat = false;
if testKwikFormat
    
    path = 'SampleData/KwikFormat/Record Node 118';

    rec = KwikRecording(path, 0, 0);

    figure;

    stream = rec.continuous.keys;
    stream = rec.continuous(stream{1}); %KWIK only produces a single stream? 

    subplot(2,1,1);
    plot(stream.timestamps, stream.samples(:,17)); hold on;
        
    spikeProcessors = rec.spikes.keys;
    for j = 1:length(spikeProcessors)
        spikeProcessor = rec.spikes(spikeProcessors{j}); 
        t = spikeProcessor.timestamps;
        tx = [t.';t.';nan(1,length(t))];
        ymin = double(min(stream.samples(:,1))).*ones(1,length(t));
        ymax = double(max(stream.samples(:,1))).*ones(1,length(t));
        ty = [ymin;ymax;nan(1,length(t))];
        plot(tx(:),ty(:));
        break; %only plot single-electrodes
    end


    subplot(2,1,2);
    plot(stream.timestamps, stream.samples(:,1)); hold on;

    eventProcessors = rec.ttlEvents.keys;
    for j = 1:length(eventProcessors)
        events = rec.ttlEvents(eventProcessors{j});
        t = events.timestamp;
        tx = [t.';t.';nan(1,length(t))];
        ymin = double(min(stream.samples(:,1))).*ones(1,length(t));
        ymax = double(max(stream.samples(:,1))).*ones(1,length(t));
        ty = [ymin;ymax;nan(1,length(t))];
        plot(tx(:),ty(:));
    end

    figure;
    %Plot the first spike waveform
    spikeProcessors = rec.spikes.keys;
    for i = 1:length(spikeProcessors)
        spikeProcessor = rec.spikes(spikeProcessors{i});
        plot(spikeProcessor.waveforms(:,1));
    end

end

testNwbFormat = true;
if testNwbFormat
    
    path = 'NwbFormat_single_electrode/Record Node 118';
    path = 'NwbFormat/Record Node 118';

    rec = NwbRecording(path, 0, 0);

    figure('Name', 'NWBFormatContinuous', 'numbertitle', 'off');
    streams = rec.continuous.keys;
    for i = 1:length(streams)

        stream = rec.continuous(streams{i});
        subplot(length(streams),1,i);
        plot(40000.*stream.timestamps, stream.samples(1,:)); hold on;

        if i == 1 %Stream 1 is neural data -- overlay detected spikes 
            spikeProcessors = rec.spikes.keys;
            for j = 1:length(spikeProcessors)
                spikeProcessor = rec.spikes(spikeProcessors{j}); 
                t = spikeProcessor.timestamps;
                %Convert timestamps from seconds back to sample counts
                t = 40000.*t; %TODO: Should be able to pull sample rate automatically
                tx = [t.';t.';nan(1,length(t))];
                ymin = double(min(stream.samples(1,:))).*ones(1,length(t));
                ymax = double(max(stream.samples(1,:))).*ones(1,length(t));
                ty = [ymin;ymax;nan(1,length(t))];
                plot(tx(:),ty(:));
                break; %only plot single electrode data
            end
        else   %Stream 2 is a sine wave -- overlay detected events (sine wave peaks)
            eventProcessors = rec.ttlEvents.keys;
            for j = 1:length(eventProcessors)
                events = rec.ttlEvents(eventProcessors{j});
                t = events.timestamp;
                %Convert timestamps from seconds back to sample counts
                t = 40000.*t; %TODO: Should be able to pull sample rate automatically
                tx = [t.';t.';nan(1,length(t))];
                ymin = double(min(stream.samples(1,:))).*ones(1,length(t));
                ymax = double(max(stream.samples(1,:))).*ones(1,length(t));
                ty = [ymin;ymax;nan(1,length(t))];
                plot(tx(:),ty(:));
            end

        end
    end

    figure('Name', 'NWBFormatSpike', 'numbertitle', 'off');
    %Plot the first spike waveform
    spikeProcessors = rec.spikes.keys;
    for i = 1:length(spikeProcessors)
        spikeProcessor = rec.spikes(spikeProcessors{i});
        plot(spikeProcessor.waveforms(:,1));
        sample = spikeProcessor.waveforms(:,1);
        break;
    end

end