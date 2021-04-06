% MIT License
% 
% Copyright (c) 2021 Open Ephys
% 
% Permission is hereby granted, free of charge, to any person obtaining a copy
% of this software and associated documentation files (the "Software"), to deal
% in the Software without restriction, including without limitation the rights
% to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
% copies of the Software, and to permit persons to whom the Software is
% furnished to do so, subject to the following conditions:
% 
% The above copyright notice and this permission notice shall be included in all
% copies or substantial portions of the Software.
% 
% THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
% IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
% FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
% AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
% LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
% OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
% SOFTWARE.

classdef NwbRecording < Recording

    methods 

        function self = NwbRecording(directory, experimentIndex, recordingIndex) 
            
            self = self@Recording(directory, experimentIndex, recordingIndex);
            self.format = 'NWB';

            self.loadContinuous();
            self.loadEvents();
            self.loadSpikes();

        end

        function self = loadContinuous(self)

            dataFile = fullfile(self.directory, ['experiment_' num2str(self.experimentIndex) '.nwb']);

            streamInfo = h5info(dataFile, ['/acquisition/timeseries/recording' num2str(self.recordingIndex) '/continuous']);

            for i = 1:length(streamInfo.Groups)

                stream = {};

                stream.metadata = {};

                stream.samples = h5read(dataFile, [streamInfo.Groups(i).Name '/data']);
                stream.timestamps = h5read(dataFile, [streamInfo.Groups(i).Name '/timestamps']);

                stream.metadata.startTimestamp = stream.timestamps(1);

                name = strsplit(streamInfo.Groups(i).Name, '_'); 
                processorId = name{end};

                self.continuous(processorId) = stream;

            end

        end

        function self = loadEvents(self)

            dataFile = fullfile(self.directory, ['experiment_' num2str(self.experimentIndex) '.nwb']);

            eventInfo = h5info(dataFile, ['/acquisition/timeseries/recording' num2str(self.recordingIndex) '/events/ttl1']);

            name = strsplit(eventInfo.Attributes(5).Value, '_');
            nodeId = name{end};

            timestamps = h5read(dataFile, ['/acquisition/timeseries/recording' num2str(self.recordingIndex) '/events/ttl1/timestamps']);
            channels = h5read(dataFile, ['/acquisition/timeseries/recording' num2str(self.recordingIndex) '/events/ttl1/control']);
            channelStates = h5read(dataFile, ['/acquisition/timeseries/recording' num2str(self.recordingIndex) '/events/ttl1/data']);
            
            channelStates = (channelStates + 1) / 2;

            self.ttlEvents(nodeId) = DataFrame(channels, timestamps, str2double(nodeId)*ones(length(channels),1), channelStates, 'VariableNames', {'channel','timestamp','nodeID','state'});

        end

        function self = loadSpikes(self)

            dataFile = fullfile(self.directory, ['experiment_' num2str(self.experimentIndex) '.nwb']);

            spikeInfo = h5info(dataFile, ['/acquisition/timeseries/recording' num2str(self.recordingIndex) '/spikes']);

            channelGroups = spikeInfo.Groups;

            names = {};
            for i = 1:length(channelGroups)
                names{end+1} = channelGroups(i).Name;
            end

            channelCounts = [1 2 4];

            for count = 1:length(channelCounts)

                spikes = {};

                timestamps = {};
                waveforms = {};
                electrodes = {};

                spikes.metadata = {};
                spikes.metadata.names = names; %electrodeData keys

                if length(channelGroups) > 1
                
                    for group = 1:length(channelGroups)

                        channelGroup = channelGroups(group);

                        if channelGroup.Datasets(1).ChunkSize(2) == channelCounts(count)

                            waveforms{end+1} = h5read(dataFile, [channelGroup.Name '/data']);
                            timestamps{end+1} = h5read(dataFile, [channelGroup.Name '/timestamps']);
                            electrodes{end+1} = zeros(length(timestamps{end}),1);

                        end

                    end

                else

                    if channelGroups.Datasets(1).ChunkSize(2) == channelCounts(count)

                        waveforms{end+1} = h5read(dataFile, [channelGroups.Name '/data']);
                        timestamps{end+1} = h5read(dataFile, [channelGroups.Name '/timestamps']);
                        electrodes{end+1} = zeros(length(timestamps{end}),1);

                    end

                end

                spikes.timestamps = [timestamps{:}];
                spikes.waveforms = [waveforms{:}];
                spikes.electrodes = [electrodes{:}];

                [~,order] = sort(spikes.timestamps);

                spikes.timestamps = spikes.timestamps(order);
                
                spikes.waveforms = spikes.waveforms(:,:,order);
                %waveforms = permute(spikes.waveforms,[1 3 2]);
                %spikes.waveforms = reshape(waveforms, [], size(spikes.waveforms,2), 1);

                spikes.electrodes = spikes.electrodes(order);

                self.spikes(num2str(count)) = spikes;

            end
        end

    end

    methods (Static)
        
        function detectedFormat = detectFormat(directory)

            detectedFormat = false;

            nwbFiles = glob(fullfile(directory, '*.nwb'));
        
            if length(nwbFiles) > 0
                detectedFormat = true;
            end

        end

        function recordings = detectRecordings(directory)

            recordings = {};

            nwbFiles = glob(fullfile(directory, 'experiment*.nwb'));
            %sort

            for i = 1:length(nwbFiles)

                experimentIndex = i;

                streamInfo = h5info(nwbFiles{i}, '/acquisition/timeseries/');

                for j = 1:length(streamInfo.Groups)

                    recordingIndex = j;

                    recordings{end+1} = NwbRecording(directory, experimentIndex, recordingIndex);
                    
                end


            end

        end
        
    end

end