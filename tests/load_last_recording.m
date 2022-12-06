% "Import" matlab-tools
addpath(genpath("."));

SAMPLING_RATE = 40000; % samples / sec

% Update this path to point to your own recording
DATA_PATH = 'C:/Users/Pavel/OneDrive/Documents/Open Ephys/';
%DATA_PATH = 'C:/open-ephys/0.6.3_smokeTest/';

% Pulls the latest NUM_TESTS recordings by folder datetime 
%NUM_TESTS = length(RECORDING_FORMATS_TO_TEST);
latest_recording = Utils.getLatestRecordings(DATA_PATH,1);

% Flag to plot data after test 
show = true;
if show
    % Define visualization figure
    set(0,'units','pixels'); 
    s = get(0,'screensize');
    SCREEN_X = s(3);
    SCREEN_Y = s(4);
    FIGURE_X_SIZE = SCREEN_X / 2;
    FIGURE_Y_SIZE = SCREEN_Y;

    set(0,'DefaultFigureWindowStyle','docked');
    f = figure();
    %f.set('Position', [SCREEN_X / 2 0 FIGURE_X_SIZE FIGURE_Y_SIZE]);
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

        % Get the first recording 
        recording = node.recordings{1,j};

        % Iterate over all data streams in the recording 
        streamNames = recording.continuous.keys();

        for k = 1:length(streamNames)

            streamName = streamNames{k};
            disp(streamName)

            % 1. Get the continuous data from the current stream/recording
            data = recording.continuous(streamName);

            % 2. Plot first channel of continuous data 
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
                    for n = 1:length(events.channel)
                        if show && events.state(n) == 1
                            line([events.timestamp(n), events.timestamp(n)], [-4000,2000], 'Color', 'red', 'LineWidth', 0.2);
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
            
        end

    end
end
    

% Save result 
exportgraphics(gcf(), fullfile("tests", "load_last_recording.pdf"));