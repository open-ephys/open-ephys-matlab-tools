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

        end

        function self = loadContinuous(self)

            syncMessages = self.loadSyncMessages();

            for i = 1:length(self.info.continuous)

                directory = fullfile(self.directory, 'continuous', self.info.continuous(i).folder_name);

                stream = {};

                stream.metadata.sampleRate = self.info.continuous(i).sample_rate;
                stream.metadata.numChannels = self.info.continuous(i).num_channels;
                stream.metadata.processorId = self.info.continuous(i).source_processor_id;
                stream.metadata.subprocessorId = self.info.continuous(i).source_processor_sub_idx;
                
                stream.metadata.names = {};
                for j = 1:length(self.info.continuous(i).channels)
                    stream.metadata.names{j} = self.info.continuous(i).channels(j).channel_name;
                end

                stream.metadata.id = [num2str(stream.metadata.processorId) '.' num2str(stream.metadata.subprocessorId)];

                stream.metadata.startTimestamp = syncMessages(stream.metadata.id);

                stream.timestamps = readNPY(fullfile(directory, 'timestamps.npy'));

                data = memmapfile(fullfile(directory, 'continuous.dat'), 'Format', 'int16');

                stream.samples = reshape(data.Data, [stream.metadata.numChannels, length(data.Data) / stream.metadata.numChannels]);

                self.continuous(stream.metadata.id) = stream;

            end

        end

        function self = loadEvents(self)

            eventDirectories = glob(fullfile(self.directory, 'events', '*', 'TTL*'));

            for i = 1:length(eventDirectories)

                files = regexp(eventDirectories{i},filesep,'split');

                node = regexp(files{length(files)-2},'-','split');
                fullId = strsplit(node{1,length(node)},'.');
                processorId = str2num(fullId{1});
                subprocessorId = str2num(fullId{2});
                
                channels = readNPY(fullfile(eventDirectories{i}, 'channels.npy'));
                timestamps = readNPY(fullfile(eventDirectories{i}, 'timestamps.npy'));
                channelStates = readNPY(fullfile(eventDirectories{i}, 'channel_states.npy'));

                channelStates = (channelStates + 1) / 2;

                id = [num2str(fullId{1}) '.' num2str(fullId{2})];

                self.ttlEvents(id) = DataFrame(channels, timestamps, processorId*ones(length(channels),1), subprocessorId*ones(length(channels),1), channelStates, ...
                    'VariableNames', {'channel','timestamp','processorId','subprocessorId', 'state'});

            end

            if length(self.ttlEvents.keys) > 0
                %TODO: Concatenate data frames?
            end

        end

        function self = loadSpikes(self)

            for i = 1:length(self.info.spikes)

                directory = fullfile(self.directory, 'spikes', self.info.spikes(i).folder_name);

                spikes = {};

                spikes.id = self.info.spikes(i).folder_name;

                spikes.timestamps = readNPY(fullfile(directory, 'spike_times.npy'));
                spikes.electrodes = readNPY(fullfile(directory, 'spike_electrode_indices.npy'));
                spikes.waveforms = readNPY(fullfile(directory, 'spike_waveforms.npy'));

                %self.info.spikes(i).folder_nam = Spike_Detector-101.0/spike_group_1/
                folderName = fileparts(self.info.spikes(i).folder_name);
                processorName = folderName(1);
                id = strsplit(processorName(1), "-");
                
                ndim = ndims(spikes.waveforms);

                if ndim > 2
                    [~,numElectrodes,~] = size(spikes.waveforms);
                else
                    numElectrodes = 1;
                end
                
                self.spikes(spikes.id) = spikes;  

            end

        end

        function syncMessages = loadSyncMessages(self)

            syncMessages = containers.Map();

            rawMessages = splitlines(fileread(fullfile(self.directory, 'sync_messages.txt')));

            for i = 1:length(rawMessages)-1

                message = strsplit(rawMessages{i});
                data = strsplit(message{end}, "@");
                sampleFrequency = str2num(data{2}(1:end-2)); %Removes trailing 'Hz'
                startTimestamp = str2num(data{1});
                if message{1} == "Software" %found software time
                    syncMessages("Software") = [startTimestamp, sampleFrequency];
                else %extract unique processor id
                    n = 1; while message{n} ~= "Id:" n = n + 1; end
                    syncMessages(strcat(message{n+1}, ".", message{n+3})) = startTimestamp;
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