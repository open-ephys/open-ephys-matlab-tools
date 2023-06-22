% "Import" matlab-tools
addpath(genpath("."));

% Test parameters used (either manually or via python-tools script)
RECORDING_FORMATS_TO_TEST = ["Binary", "NWB2", "Open Ephys"];
RECORDED_DATA = ["Raw", "BP (300-6k) + Spikes", "BP (1-10) + Events (Peaks)"];
SAMPLING_RATE = 40000; % samples / sec
RECORDING_TIME = 4; % seconds

% Download example data set from the link below and update DATA_PATH variable to point to it.
% https://www.dropbox.com/scl/fo/kxrbi4e5bjceofj3v02i6/h?dl=0&rlkey=7gu4t2h3bn4vjpj5qf02luwna

% UPDATE THIS TO YOUR LOCAL DATA PATH ( note the trailing '\' is required )
DATA_PATH = 'D:\load_all_formats\';

% Pulls the latest NUM_TESTS recordings by folder datetime 
NUM_TESTS = length(RECORDING_FORMATS_TO_TEST);
latest_recordings = Utils.getLatestRecordings(DATA_PATH,NUM_TESTS);

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
    f = figure();
    f.set('Position', [SCREEN_X / 2 0 FIGURE_X_SIZE FIGURE_Y_SIZE]);
end

count = 1;

for idx = 1:length(RECORDING_FORMATS_TO_TEST)
    
    % Define path to the recording
    rec_path = join([DATA_PATH, latest_recordings(idx).name]);

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
                    subplot(length(RECORDING_FORMATS_TO_TEST)*length(RECORDED_DATA),1,count);
                    % Utils.log("First timestamp: ", num2str(data.timestamps(1,:)));
                    plot(data.timestamps(1:length(data.sampleNumbers)), data.samples(1,:), 'LineWidth', 1.5);
                    title(recording.format, RECORDED_DATA(i)); hold on;
                end

                % 3. Overlay all available event data
                eventProcessors = recording.ttlEvents.keys();
                for p = 1:length(eventProcessors)
                    processor = eventProcessors{p};
                    events = recording.ttlEvents(processor);
                    Utils.log("Found recording format: ", recording.format);
                    if ~isempty(events)
                        for n = 1:length(events.line)
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

                count = count + 1;

            end

        end
    end
    
end

% Save result 
exportgraphics(gcf(), fullfile("examples", "load_all_formats.pdf"));