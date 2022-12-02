% "Import" matlab-tools
addpath(genpath("."));

% Define demo figure size
set(0,'units','pixels'); 
s = get(0,'screensize');
SCREEN_X = s(3);
SCREEN_Y = s(4);
FIGURE_X_SIZE = SCREEN_X / 2;
FIGURE_Y_SIZE = SCREEN_Y;

RECORDING_FORMATS_TO_TEST = ["Binary", "Open Ephys", "NWB2"];

% Update this path to point to your own recording
% data_path = 'C:/Users/Pavel/OneDrive/Documents/Open Ephys/';
data_path = 'C:/open-ephys/0.6.3_smokeTest/';
latest_recordings = Utils.getLatestRecordings(data_path,length(RECORDING_FORMATS_TO_TEST));

for idx = 1:length(RECORDING_FORMATS_TO_TEST)
    
    % Define path to the recording
    rec_path = join([data_path, latest_recordings(idx).name]);

    % Show plot
    show = false;

    % Create a session (loads all data from the most recent recording)
    session = Session(rec_path);

    % Get the number of record nodes for this session
    nRecordNodes = length(session.recordNodes);

    % Generate a figure if plotting is on
    if show
        f = figure();
        f.set('Position', [SCREEN_X / 2 0 FIGURE_X_SIZE FIGURE_Y_SIZE]);
    end
    
    % Iterate over the record nodes to access data
    for i = 1:nRecordNodes

        node = session.recordNodes{i};

        for j = 1:length(node.recordings)

            % Get the first recording 
            recording = node.recordings{1,j};

            % Iterate over all data streams in the recording 
            streamNames = recording.continuous.keys();

            for k = 1%:length(streamNames)

                streamName = streamNames{k};

                % 1. Get the continuous data from the current stream/recording
                data = recording.continuous(streamName);

                % 2. Plot first channel of continuous data 
                if show 
                    subplot(3,1,i); 
                    plot(data.timestamps, data.samples(1,:), 'LineWidth', 1.5);
                    title(recording.format); hold on;
                end

                % 3. Overlay all available event data
                eventProcessors = recording.ttlEvents.keys();
                for p = 1:length(eventProcessors)
                    processor = eventProcessors{p};
                    events = recording.ttlEvents(processor);
                    if ~isempty(events)
                        for n = 1:length(events.channel)
                            if show && events.state(n) == 1
                                line([events.timestamp(n), events.timestamp(n)], [-10000,10000], 'Color', 'b', 'LineWidth', 0.2);
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
                        for spike = 1:length(spikes.timestamps)
                            % Get the timestamps for this spike
                            timestamp = spikes.timestamps(spike);
                            if show, line([timestamp, timestamp], [-10000,10000], 'Color', 'r', 'LineWidth', 0.2); end
                            % Get the waveforms(s) for this spike
                            waveforms = spikes.waveforms(:,:,spike);
                        end
                    end

                end

            end

        end
    end
    
end