% "Import" matlab-tools
addpath(genpath("."));

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

    % Get the first recording 
    recording = node.recordings{1};

    % Iterate over all data streams in the recording 
    streamNames = recording.continuous.keys();
    for j = 1:length(streamNames)

        stream = recording.continuous(streamNames{j});

        % Plot the data from the current stream
        % figure; plot(1:length(stream.samples), stream.samples);
       
        % TODO: Get event data
        event_streams = node.recordings{1,1}.ttlEvents.keys();
        if length(event_streams) > 0
            some_stream = event_streams{1};
            some_events = node.recordings{1,1}.ttlEvents(some_stream);
        end

    end
      
    %Events are stored as a pandas DataFrame equivalent for each stream
    %some_events.disp
    
end

%TODO: Use when processing spikes
% ndim = ndims(spikes.waveforms);
% if ndim > 2
%     [~,numElectrodes,~] = size(spikes.waveforms);
% else
%     numElectrodes = 1;
% end