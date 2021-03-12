addpath('..');

testBinaryFormat = false;
if testBinaryFormat
    
    path = 'BinaryFormat/Record Node 118';

    rec = BinaryRecording(path, 1, 1);

    figure;
    %Plot the first channel in each subprocessor
    streams = rec.continuous.keys;
    for i = 1:length(streams)
        stream = rec.continuous(streams{i});
        subplot(length(streams),1,i);
        plot(stream.samples(1,:));
    end

    figure;
    %Plot the first spike waveform
    spikeProcessors = rec.spikes.keys;
    for i = 1:length(spikeProcessors)
        spikeProcessor = rec.spikes(spikeProcessors{i});
        plot(spikeProcessor.waveforms(1,:));
    end

    %TODO: Plot continuous, events and spikes on top of each other as one figure

end

testOpenEphysFormat = true;
if testOpenEphysFormat
    
    path = 'OpenEphysFormat/Record Node 118';

    rec = OpenEphysRecording(path, 0, 0);

    figure;
    %Plot the first channel in each subprocessor
    streams = rec.continuous.keys;
    for i = 1:length(streams)
        stream = rec.continuous(streams{i});
        subplot(length(streams),1,i);
        plot(stream.samples(:,end));
    end

    figure;
    %Plot the first spike waveform
    spikeProcessors = rec.spikes.keys;
    for i = 1:length(spikeProcessors)
        spikeProcessor = rec.spikes(spikeProcessors{i});
        plot(spikeProcessor.waveforms(1,:));
    end

    %TODO: Plot continuous, events and spikes on top of each other as one figure

end