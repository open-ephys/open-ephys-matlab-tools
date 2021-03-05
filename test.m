addpath('..');

testBinaryFormat = true;
if testBinaryFormat
    
    path = '../BinaryRecordingSampleData/Record Node 103';

    br = BinaryRecording(path, 1, 1);

    figure;
    %Plot the first channel in each subprocessor
    streams = br.continuous.keys;
    for i = 1:length(streams)
        stream = br.continuous(streams{i});
        subplot(length(streams),1,i);
        plot(stream.samples(1,:));
    end

    figure;
    %Plot the first spike waveform
    spikeProcessors = br.spikes.keys;
    for i = 1:length(spikeProcessors)
        spikeProcessor = br.spikes(spikeProcessors{i});
        plot(spikeProcessor.waveforms(1,:));
    end

    %TODO: Plot continuous, events and spikes on top of each other as one figure

end