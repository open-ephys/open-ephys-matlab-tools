% "Import" matlab-tools
addpath(genpath("."));

% Define a path to the recorded data
path = 'C:\Users\Pavel\OneDrive\Documents\Open Ephys\2022-06-30_16-34-51'; %SourceSim
%path = 'C:\Users\Pavel\OneDrive\Documents\Open Ephys\2022-06-29_20-51-10'; %FileReader

% Create a session (loads all data at the path)
session = Session(path);

% Get the number of record nodes for this session
nRecordNodes = length(session.recordNodes);

% Iterate over the record nodes to access their data
for i = 1:nRecordNodes
    
    node = session.recordNodes{i};
    
    event_streams = node.recordings{1,1}.ttlEvents.keys();
    some_stream = event_streams{1};
    some_events = node.recordings{1,1}.ttlEvents(some_stream);
      
    %Events are stored as a pandas DataFrame equivalent for each stream
    some_events.disp
    
end

%TODO: Use when processing spikes
% ndim = ndims(spikes.waveforms);
% if ndim > 2
%     [~,numElectrodes,~] = size(spikes.waveforms);
% else
%     numElectrodes = 1;
% end