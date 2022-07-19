% "Import" matlab-tools
%addpath(genpath("."));

% Define a base path to the recorded data
dataPath = '/Users/pavelkulik/Documents/Open Ephys';

% Get the path to the most recent recording
path = fullfile(dataPath, Utils().getLatestRecording(dataPath).name);

% Create a session (loads all data from the most recent recording)
session = Session(path);

% Get the number of record nodes for this session
nRecordNodes = length(session.recordNodes);

% Iterate over the record nodes to access data
for i = 1:nRecordNodes

    node = session.recordNodes{i};

    f = figure(); colors = {'b', 'r'};
    f.set('Position', [0 0 1800 1000]);

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
            plot(data.timestamps, data.samples); hold on;
           
            % 3. Overlay any corresponding event data for this stream/recording
            events = recording.ttlEvents(streamName);
            if ~isempty(events)
                for n = 1:length(events.channel)
                    plot(events.timestamp(n), 1e4, 'r+'); hold on;
                end
            end

            % TODO: Spike Data
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