% "Import" matlab-tools
addpath(genpath("."));

% Define size for demo figure 
FIGURE_X_SIZE = 1800;
FIGURE_Y_SIZE = 1000;

% Define a base path to the recorded data
dataPath = '/Users/pavelkulik/Documents/Open Ephys';
dataPath = 'C:\Users\Pavel\OneDrive\Documents\Open Ephys';

% Get the path to the most recent recording
path = fullfile(dataPath, Utils().getLatestRecording(dataPath).name);

% Create a session (loads all data from the most recent recording)
session = Session(path);

% Get the number of record nodes for this session
nRecordNodes = length(session.recordNodes);

% Iterate over the record nodes to access data
for i = 1:nRecordNodes

    node = session.recordNodes{i};

    f = figure();
    f.set('Position', [0 0 FIGURE_X_SIZE FIGURE_Y_SIZE]);

    for j = 1:length(node.recordings)

        % Get the first recording 
        recording = node.recordings{1,j};
    
        % Iterate over all data streams in the recording 
        streamNames = recording.continuous.keys();

        for k = 1:length(streamNames)

            streamName = streamNames{k};
    
            % 1. Get the continuous data from the current stream/recording
            data = recording.continuous(streamName);
    
            % 2. Plot the continuous data 
            plot(data.timestamps, data.samples, 'LineWidth', 1.5); hold on;
           
            % 3. Overlay all available event data
            eventProcessors = recording.ttlEvents.keys();
            for p = 1:length(eventProcessors)
                processor = eventProcessors{p};
                events = recording.ttlEvents(processor);
                if ~isempty(events)
                    for n = 1:length(events.channel)
                        if events.state(n) == 1
                            line([events.timestamp(n), events.timestamp(n)], [-10000,10000], 'Color', 'b', 'LineWidth', 0.2);
                        end
                    end
                end
            end

            % TODO: Demo Spike Data
            % electrodes = recording.spikes.keys();
    
        end
         

    end
    
end

%TODO: Use when processing spikes
% ndim = ndims(spikes.waveforms);
% if ndim > 2
%     [~,numElectrodes,~] = size(spikes.waveforms);
% else
%     numElectrodes = 1;
% end