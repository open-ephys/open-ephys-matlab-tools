% Define a path to the recorded data
path = 'C:\Users\Pavel\OneDrive\Documents\Open Ephys\2022-06-29_20-51-10';

% Create a session (loads all data at the path)
session = Session(path);

% Get the number of record nodes for this session
nRecordNodes = length(session.recordNodes);

% Iterate over the record nodes to access their data
for i = 1:nRecordNodes
    
    node = session.recordNodes{i};
    
end


