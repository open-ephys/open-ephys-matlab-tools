% "Import" matlab-tools
addpath(genpath("."));

% Update this path to point to your own recording directory
DATA_PATH = 'D:\test-suite\data\';

% Pulls the latest NUM_REC recordings by folder datetime
NUM_REC = 1;
latest_recording = Utils.getLatestRecordings(DATA_PATH,NUM_REC);

% Flag to plot data after test 
show = true;
if show
    % Define visualization figure
    set(0,'units','pixels'); 
    s = get(0,'screensize');
    SCREEN_X = s(3);
    SCREEN_Y = s(4);
    FIGURE_X_SIZE = SCREEN_X / 2;
    FIGURE_Y_SIZE = SCREEN_Y / 3;

    f = figure();
    f.set('Position', [SCREEN_X / 2 0 FIGURE_X_SIZE FIGURE_Y_SIZE]);
end
    
% Define path to the recording
rec_path = join([DATA_PATH, latest_recording.name]);

% Create a session (loads all data from the most recent recording)
session = Session(rec_path);

% Get the number of record nodes for this session
nRecordNodes = length(session.recordNodes);

% Iterate over the record nodes to access data
for i = 1:nRecordNodes

    node = session.recordNodes{i};

    for j = 1:length(node.recordings)

        % 1. Get the first recording 
        recording = node.recordings{1,j};

        % 2. Iterate over all continuous data streams in the recording 
        streamNames = recording.continuous.keys();

        for k = 1:length(streamNames)

            streamName = streamNames{k};
            disp(streamName)

            % Get the continuous data from the current stream
            data = recording.continuous(streamName);

            % Plot first channel of continuous data 
            if show 
                plot(data.timestamps, data.samples(1,:), 'LineWidth', 1.5);
                title(recording.format, recording.format); hold on;
            end
            
            % 3. Overlay all available event data
            eventProcessors = recording.ttlEvents.keys();
            for p = 1:length(eventProcessors)
                processor = eventProcessors{p};
                events = recording.ttlEvents(processor);
                if ~isempty(events)
                    for n = 1:length(events.line)
                        if show && events.state(n) == 1
                            line([events.timestamp(n), events.timestamp(n)], [-4000,2000], 'Color', 'red', 'LineWidth', 0.2);
                        end
                    end
                end
            end
            
        end
        

        % 4. Overlay spike data from first electrode
        if recording.spikes.Count
            %Utils.log(recording.format, " has spikes");
            electrodes = recording.spikes.keys;
            for e = 1:length(electrodes)
                % Get all spikes for this electrode
                spikes = recording.spikes(electrodes{e});
                nSpikes = length(spikes.timestamps);
                for spike = 1:nSpikes
                    % Get the timestamps for this spike
                    timestamp = spikes.timestamps(spike);
                    if show && mod(spike,8) == 0, line([timestamp, timestamp], [-4000,2000], 'Color', 'red', 'LineWidth', 0.2); end
                    % Get the waveforms(s) for this spike
                    waveforms = spikes.waveforms(:,:,spike);
                end
                %Utils.log(electrodes{e}, " has ", num2str(nSpikes), " spikes.");
            end

        end
        
        % 5. Print any message events
        if recording.messages.Count > 0
            disp("Found Message Center events!");
            % recording.messages('MessageCenter');
        end

    end
end
    

% Save result 
exportgraphics(gcf(), fullfile("examples", "load_last_recording.pdf"));