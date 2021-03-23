SAMPLE_RATE = 40000;
SAMPLE_RANGE = 1:SAMPLE_RATE; %1st second of data
p = generatePlotView();

%Test recording w/ startTimestamp = 0
%sessionDir = 'SimpleSession';

%Test recordings w/ startTimestamp ~= 0
sessionDir = 'DelayedRecording';
session = Session(sessionDir);

for i = 1:length(session.recordNodes)
    
    node = session.recordNodes{i};

    rec = node.recordings{1};

    switch node.format

    case 'Binary'

        streams = rec.continuous.keys;
        neuralData = rec.continuous(streams{1});
        eventData = rec.continuous(streams{2});
        
        t = neuralData.metadata.startTimestamp:(neuralData.metadata.startTimestamp + SAMPLE_RATE - 1);

        plot(p(1), t, neuralData.samples(1,SAMPLE_RANGE)); hold(p(1), 'on');

        spikeProcessors = rec.spikes.keys;
        spikeProcessor = rec.spikes(spikeProcessors{1}); 

        t = find(spikeProcessor.timestamps > neuralData.metadata.startTimestamp & spikeProcessor.timestamps < neuralData.metadata.startTimestamp + SAMPLE_RATE);
        t = spikeProcessor.timestamps(t);
        tx = [t.';t.';nan(1,length(t))];
        ymin = double(min(neuralData.samples(1,SAMPLE_RANGE))).*ones(1,length(t));
        ymax = double(max(neuralData.samples(1,SAMPLE_RANGE))).*ones(1,length(t));
        ty = [ymin;ymax;nan(1,length(t))];
        plot(p(1), tx(:),ty(:));
        
        t = neuralData.metadata.startTimestamp:(neuralData.metadata.startTimestamp + SAMPLE_RATE - 1);

        plot(p(2), t, eventData.samples(1,SAMPLE_RANGE)); hold(p(2), 'on');

        eventProcessors = rec.ttlEvents.keys;
        eventProcessor = eventProcessors{1};

        events = rec.ttlEvents(eventProcessor);
        
        t = find(events.timestamp > neuralData.metadata.startTimestamp & events.timestamp < neuralData.metadata.startTimestamp + SAMPLE_RATE);
        t = events.timestamp(t);
        tx = [t.';t.';nan(1,length(t))];
        ymin = double(min(eventData.samples(1,SAMPLE_RANGE))).*ones(1,length(t));
        ymax = double(max(eventData.samples(1,SAMPLE_RANGE))).*ones(1,length(t));
        ty = [ymin;ymax;nan(1,length(t))];
        plot(p(2), tx(:),ty(:));

        plot(p(3), spikeProcessor.waveforms(1,:));

    case 'OpenEphys'
        
        streams = rec.continuous.keys;
        neuralData = rec.continuous(streams{1});
        eventData = rec.continuous(streams{2});

        t = neuralData.metadata.startTimestamp:(neuralData.metadata.startTimestamp + SAMPLE_RATE - 1);
        
        plot(p(4), t, neuralData.samples(1,SAMPLE_RANGE)); hold(p(4), 'on');

        spikeProcessors = rec.spikes.keys;
        spikeProcessor = rec.spikes(spikeProcessors{1}); 

        t = find(spikeProcessor.timestamps > neuralData.metadata.startTimestamp & spikeProcessor.timestamps < neuralData.metadata.startTimestamp + SAMPLE_RATE);
        t = spikeProcessor.timestamps(t);
        tx = [t.';t.';nan(1,length(t))];
        ymin = double(min(neuralData.samples(1,SAMPLE_RANGE))).*ones(1,length(t));
        ymax = double(max(neuralData.samples(1,SAMPLE_RANGE))).*ones(1,length(t));
        ty = [ymin;ymax;nan(1,length(t))];
        plot(p(4), tx(:),ty(:));

        t = neuralData.metadata.startTimestamp:(neuralData.metadata.startTimestamp + SAMPLE_RATE - 1);
        plot(p(5), t, eventData.samples(1,SAMPLE_RANGE)); hold(p(5), 'on');

        eventProcessors = rec.ttlEvents.keys;
        eventProcessor = eventProcessors{1};

        events = rec.ttlEvents(eventProcessor);
            
        t = find(events.timestamp > neuralData.metadata.startTimestamp & events.timestamp < neuralData.metadata.startTimestamp + SAMPLE_RATE);
        t = events.timestamp(t);
        tx = [t.';t.';nan(1,length(t))];
        ymin = double(min(eventData.samples(1,SAMPLE_RANGE))).*ones(1,length(t));
        ymax = double(max(eventData.samples(1,SAMPLE_RANGE))).*ones(1,length(t));
        ty = [ymin;ymax;nan(1,length(t))];
        plot(p(5), tx(:),ty(:));

        plot(p(6), spikeProcessor.waveforms(1,:));
        
    case 'KWIK'
        
        streams = rec.continuous.keys;
        %KWIK format only has one stream?
        data = rec.continuous(streams{1});

        t = data.metadata.startTimestamp:(data.metadata.startTimestamp + SAMPLE_RATE - 1);
        
        plot(p(7), t, data.samples(SAMPLE_RANGE,17)); hold(p(7), 'on');
        
        spikeProcessors = rec.spikes.keys;
        spikeProcessor = rec.spikes(spikeProcessors{1}); 
        
        t = find(spikeProcessor.timestamps > data.metadata.startTimestamp & spikeProcessor.timestamps < data.metadata.startTimestamp + SAMPLE_RATE);
        t = spikeProcessor.timestamps(t);
        tx = [t.';t.';nan(1,length(t))];
        ymin = double(min(data.samples(SAMPLE_RANGE,17))).*ones(1,length(t));
        ymax = double(max(data.samples(SAMPLE_RANGE,17))).*ones(1,length(t));
        ty = [ymin;ymax;nan(1,length(t))];
        plot(p(7), tx(:),ty(:));
        
        t = data.metadata.startTimestamp:(data.metadata.startTimestamp + SAMPLE_RATE - 1);
        plot(p(8), t, data.samples(SAMPLE_RANGE,1)); hold(p(8), 'on');
        
        eventProcessors = rec.ttlEvents.keys;
        eventProcessor = eventProcessors{1};
        
        events = rec.ttlEvents(eventProcessor);
        
        t = find(events.timestamp > data.metadata.startTimestamp & events.timestamp < data.metadata.startTimestamp + SAMPLE_RATE);
        t = events.timestamp(t);
        tx = [t.';t.';nan(1,length(t))];
        ymin = double(min(eventData.samples(1,SAMPLE_RANGE))).*ones(1,length(t));
        ymax = double(max(eventData.samples(1,SAMPLE_RANGE))).*ones(1,length(t));
        ty = [ymin;ymax;nan(1,length(t))];
        plot(p(8), tx(:),ty(:));
        
        plot(p(9), spikeProcessor.waveforms(:,:,1));
        
    case 'NWB'
        
        streams = rec.continuous.keys;
        neuralData = rec.continuous(streams{1});
        eventData = rec.continuous(streams{2});
        
        t = linspace(neuralData.metadata.startTimestamp, neuralData.metadata.startTimestamp + 1, SAMPLE_RATE);
        
        plot(p(10), t, neuralData.samples(1,SAMPLE_RANGE)); hold(p(10), 'on');
        
        spikeProcessors = rec.spikes.keys;
        spikeProcessor = rec.spikes(spikeProcessors{1});
        
        t = find(spikeProcessor.timestamps > t(1) & spikeProcessor.timestamps < t(end));
        t = spikeProcessor.timestamps(t);
        
        tx = [t.';t.';nan(1,length(t))];    
        ymin = double(min(neuralData.samples(1,SAMPLE_RANGE))).*ones(1,length(t));
        ymax = double(max(neuralData.samples(1,SAMPLE_RANGE))).*ones(1,length(t));
        ty = [ymin;ymax;nan(1,length(t))];
        plot(p(10), tx(:),ty(:));
        
        t = linspace(neuralData.metadata.startTimestamp, neuralData.metadata.startTimestamp + 1, SAMPLE_RATE);
        
        plot(p(11), t, eventData.samples(1,SAMPLE_RANGE)); hold(p(11), 'on');
        
        eventProcessors = rec.ttlEvents.keys;
        eventProcessor = eventProcessors{1};
        
        events = rec.ttlEvents(eventProcessor);
        t = find(events.timestamp > t(1) & events.timestamp < t(end));
        t = events.timestamp(t);   
        tx = [t.';t.';nan(1,length(t))];
        ymin = double(min(eventData.samples(1,SAMPLE_RANGE))).*ones(1,length(t));
        ymax = double(max(eventData.samples(1,SAMPLE_RANGE))).*ones(1,length(t));
        ty = [ymin;ymax;nan(1,length(t))];
        plot(p(11), tx(:),ty(:));
        
        plot(p(12), spikeProcessor.waveforms(:,1));
        
        
    otherwise
        disp('A valid format has not been detected!')
    end
    
end


function p = generatePlotView()

    f = figure();
    set(gcf, 'Units', 'Normalized', 'OuterPosition', [0.25, 0.25, 0.50, 0.50]);

    p(1)=subplot(3,4,1); %BinaryNeuralData
    p(2)=subplot(3,4,5); %BinaryEventData
    p(3)=subplot(3,4,9); %BinarySpikeData

    p(4)=subplot(3,4,2); %OpenEphysNeuralData
    p(5)=subplot(3,4,6); %OpenEphysEventData
    p(6)=subplot(3,4,10); %OpenEphysSpikeData

    p(7)=subplot(3,4,3); %KWIKNeuralData
    p(8)=subplot(3,4,7); %KWIKEventData
    p(9)=subplot(3,4,11); %KWIKSpikeData

    p(10)=subplot(3,4,4); %NWBNeuralData
    p(11)=subplot(3,4,8); %NWBEventData
    p(12)=subplot(3,4,12); %NWBSpikeData

end