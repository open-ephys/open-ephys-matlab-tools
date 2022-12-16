% "Import" matlab-tools
addpath(genpath("."));

TEST_NAME = "synchronization";

SAMPLING_RATE = 40000; % samples / sec

% Update this path to point to your own recording
DATA_PATH = 'C:/open-ephys/sync_test_data_2/';

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

        % 1. Get the first recording 
        recording = node.recordings{1,j};

        % 2. Iterate over all continuous data streams in the recording 
        streamNames = recording.continuous.keys();

        for k = 1:length(streamNames)

            streamName = streamNames{k};    

            % Get the continuous data from the current stream
            data = recording.continuous(streamName);

            % Plot first channel of continuous data 
            if show 
                subplot(length(streamNames), 1, k);
                plot(data.timestamps, data.samples(1,:), 'LineWidth', 1.5);
                title(strrep(streamName,"_"," "), recording.format); hold on;
            end
            
            % 3. Plot sync signals
            eventChannels = recording.ttlEvents.keys();
            for p = 1:length(eventChannels)
                channel = eventChannels{p};
                
                % Match event channel to continuous stream by name
                if strcmp(channel, streamName)
                    events = recording.ttlEvents(channel);
                    
                    % Set first stream detected as main stream to
                    % synchronize to
                    isMain = false;
                    if contains(channel, 'AP')
                        isMain = true;
                    end
                    
                    if ~isempty(events)
                        
                        % Add sync channel to recording object
                        recording.addSyncLine( ...
                            events.line(1), ...
                            events.processor_id(1), ...
                            events.stream_name(1), ...
                            channel, ...
                            isMain);
                            
                        for n = 1:length(events.line)
                            if show && events.state(n) == 1
                                line([events.timestamp(n), events.timestamp(n)], ...
                                [1.2*min(data.samples(1,:)),1.2*max(data.samples(1,:))],...
                                'Color', 'red', 'LineWidth', 1.0);
                            end
                        end
                        
                    end
                end
                
            end
           
            
        end
        
        % Compute the global timestamps from the sync channels
        recording.computeGlobalTimestamps();
        
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
                    if show && mod(spike,8) == 0, line([timestamp, timestamp],...
                            [-4000,2000],...
                            'Color', 'red', 'LineWidth', 1.0);
                    end
                    % Get the waveforms(s) for this spike
                    waveforms = spikes.waveforms(:,:,spike);
                end
                %Utils.log(electrodes{e}, " has ", num2str(nSpikes), " spikes.");
            end

        end

    end
end
    

% Save result 
exportgraphics(gcf(), fullfile("examples", TEST_NAME + ".pdf"));