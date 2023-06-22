% MIT License

% Copyright (c) 2021 Open Ephys

% Permission is hereby granted, free of charge, to any person obtaining a copy
% of this software and associated documentation files (the "Software"), to deal
% in the Software without restriction, including without limitation the rights
% to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
% copies of the Software, and to permit persons to whom the Software is
% furnished to do so, subject to the following conditions:

% The above copyright notice and this permission notice shall be included in all
% copies or substantial portions of the Software.

% THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
% IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
% FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
% AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
% LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
% OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
% SOFTWARE.

classdef BinaryRecording < Recording

    properties

        info

    end

    methods 

        function self = BinaryRecording(directory, experimentIndex, recordingIndex) 
            
            self = self@Recording(directory, experimentIndex, recordingIndex);
            self.format = 'Binary';

            self.info = jsondecode(fileread(fullfile(self.directory,'structure.oebin')));

            self = self.loadContinuous();
            self = self.loadEvents();
            self = self.loadSpikes();
            
            self = self.loadMessages();

        end

        function self = loadContinuous(self)

            for i = 1:length(self.info.continuous)

                directory = fullfile(self.directory, 'continuous', self.info.continuous(i).folder_name);

                stream = {};

                stream.metadata.sampleRate = self.info.continuous(i).sample_rate;
                stream.metadata.numChannels = self.info.continuous(i).num_channels;
                stream.metadata.processorId = self.info.continuous(i).source_processor_id;
                stream.metadata.streamName = self.info.continuous(i).folder_name(1:end-1);
                
                stream.metadata.names = {};
                for j = 1:length(self.info.continuous(i).channels)
                    stream.metadata.names{j} = self.info.continuous(i).channels(j).channel_name;
                end

                %Utils.log("Searching for start timestamp for stream: ");
                %Utils.log("    ", stream.metadata.streamName);

                stream.metadata.id = num2str(stream.metadata.streamName);

                stream.timestamps = readNPY(fullfile(directory, 'timestamps.npy'));

                stream.sampleNumbers = readNPY(fullfile(directory, 'sample_numbers.npy'));

                data = memmapfile(fullfile(directory, 'continuous.dat'), 'Format', 'int16');

                stream.samples = reshape(data.Data, [stream.metadata.numChannels, length(data.Data) / stream.metadata.numChannels]);

                stream.metadata.startTimestamp = stream.timestamps(1);

                self.continuous(stream.metadata.id) = stream;

            end

        end

        function self = loadEvents(self)

            ttlDirectories = glob(fullfile(self.directory, 'events', '*', 'TTL*'));

            streamIdx = 0;

            for i = 1:length(ttlDirectories)

                files = regexp(ttlDirectories{i},filesep,'split');

                % Assumes full stream name always in the form
                % <PROCESSOR_NAME>_<PROCESSOR_ID>.<STREAM_ID>
                fullStreamName = files{length(files)-2};

                stream = regexp(fullStreamName,'\.','split');
                
                processor = stream{1};
                streamName = stream{2};

                processorId = str2double(processor(length(processor)-2:end));

                lines = readNPY(fullfile(ttlDirectories{i}, 'states.npy'));
                sampleNumbers = readNPY(fullfile(ttlDirectories{i}, 'sample_numbers.npy'));
                timestamps = readNPY(fullfile(ttlDirectories{i}, 'timestamps.npy'));

                numEvents = length(lines);

                self.ttlEvents(fullStreamName) = DataFrame(abs(lines), sampleNumbers, timestamps, processorId*ones(numEvents,1), repmat(string(fullStreamName),numEvents,1), lines > 0, ...
                    'VariableNames', {'line','sample_number','timestamp','processor_id', 'stream_name', 'state'});
                
                streamIdx = streamIdx + 1;

            end

            if length(self.ttlEvents.keys) > 0
                %TODO: Concatenate data frames?
            end

        end
        
        function self = loadMessages(self)
            
            msgDirectory = glob(fullfile(self.directory, 'events', 'MessageCenter'));

            messages = fullfile(msgDirectory, 'text.npy');
            messages = dir(messages{:});

            if messages.bytes > 128

                % Utils.log("Found message events");

                text = readNPY(fullfile(msgDirectory{1}, 'text.npy'));
                sampleNumbers = readNPY(fullfile(msgDirectory{1}, 'sample_numbers.npy'));
                timestamps = readNPY(fullfile(msgDirectory{1}, 'timestamps.npy'));

                self.messages('MessageCenter') = DataFrame(timestamps, sampleNumbers, text, ...
                    'VariableNames', {'timestamps','sample_number','text'});

            end
            
        end
        

        function self = loadSpikes(self)

            for i = 1:length(self.info.spikes)

                directory = fullfile(self.directory, 'spikes', self.info.spikes(i).folder);

                spikes = {};

                spikes.id = self.info.spikes(i).folder(1:end-1);

                spikes.timestamps = readNPY(fullfile(directory, 'timestamps.npy'));
                spikes.electrodes = readNPY(fullfile(directory, 'electrode_indices.npy'));
                spikes.clusters = readNPY(fullfile(directory, 'clusters.npy'));
                spikes.sample_numbers = readNPY(fullfile(directory, 'sample_numbers.npy'));
                
                spikes.waveforms = permute(readNPY(fullfile(directory, 'waveforms.npy')), [3 2 1]);
                
                self.spikes(spikes.id) = spikes;  

            end

        end

        function syncMessages = loadSyncMessages(self)

            syncMessages = containers.Map();

            rawMessages = splitlines(fileread(fullfile(self.directory, 'sync_messages.txt')));

            for i = 1:length(rawMessages)-1

                message = strsplit(rawMessages{i});

                if message{1} == "Software"

                    % Found system time for start of the recording
                    % "Software Time (milliseconds since midnight Jan 1st 1970 UTC): 1660948389101"
                    syncMessages("Software") = str2double(message{end});

                else

                    % Found a processor string

                    %(e.g. "Start Time for File Reader (100) - Source_Sim-110.0 @ 30000 Hz: 80182")
                    % Stream name will be: File_Reader-100.Source_Sim-110.0

                    idx = find(strcmp(message, '@'));
                    node_name = strjoin({strjoin(message(4:(idx-4)),'_'),message{idx-3}(2:end-1)},'-');

                    stream_name = message{idx-1};

                    start_timestamp = str2double(message{end});

                    syncMessages(strjoin({node_name, stream_name},'.')) = start_timestamp;

                end

            end

        end

    end

    methods (Static)
        
        function detectedFormat = detectFormat(directory)

            detectedFormat = false;

            binaryFiles = glob(fullfile(directory, 'experiment*', 'recording*'));
        
            if length(binaryFiles) > 0
                detectedFormat = true;
            end

        end

        function recordings = detectRecordings(directory)

            recordings = {};

            experimentDirectories = glob(fullfile(directory, 'experiment*'));
            %sort

            for expIdx = 1:length(experimentDirectories)

                recordingDirectories = glob(fullfile(experimentDirectories{expIdx}, 'recording*'));
                %sort

                for recIdx = 1:length(recordingDirectories)
                    recordings{end+1} = BinaryRecording(recordingDirectories{recIdx}, expIdx, recIdx);
                end

            end
            
        end
        
    end

end