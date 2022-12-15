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

            self.format = 'NWB2';

            self.loadContinuous();
            self.loadEvents();
            self.loadSpikes();
            
            self.loadMessages();

        end

        function self = loadContinuous(self)

            dataFile = fullfile(self.directory, ['experiment' num2str(self.experimentIndex) '.nwb']);

            streamInfo = h5info(dataFile, '/acquisition');

            for i = 1:length(streamInfo.Groups)

                groupName = strsplit(streamInfo.Groups(i).Name, '/');

                type = streamInfo.Groups(i).Attributes(5).Value;

                if ~strcmp(type, 'ElectricalSeries')
                    continue;
                end
                 
                stream.name = groupName{end};

                stream.samples = h5read(dataFile, [streamInfo.Groups(i).Name '/data']);
                stream.timestamps = h5read(dataFile, [streamInfo.Groups(i).Name '/timestamps']);
                stream.sampleNumbers = h5read(dataFile, [streamInfo.Groups(i).Name '/sync']);

                stream.metadata = {};

                stream.metadata.startTimestamp = stream.timestamps(1);
                stream.metadata.electrodes = h5read(dataFile, [streamInfo.Groups(i).Name '/electrodes']);
                stream.metadata.conversion = h5read(dataFile, [streamInfo.Groups(i).Name '/channel_conversion']);

                self.continuous(stream.name) = stream;

            end

        end
        
        function self = loadMessages(self)
            
            dataFile = fullfile(self.directory, ['experiment' num2str(self.experimentIndex) '.nwb']);

            streamInfo = h5info(dataFile, '/acquisition');
            
            for i = 1:length(streamInfo.Groups)

                groupName = strsplit(streamInfo.Groups(i).Name, '/');

                if ~strcmp(groupName{end}, 'messages')
                    continue;
                end

                timestamps = h5read(dataFile,[streamInfo.Groups(i).Name '/timestamps']);
                text = h5read(dataFile,[streamInfo.Groups(i).Name '/data']);
                sampleNumbers = h5read(dataFile,[streamInfo.Groups(i).Name '/sync']);
            
                self.messages('MessageCenter') = DataFrame(timestamps, sampleNumbers, text, ...
                    'VariableNames', {'timestamps','sample_number','text'});

            end
            
        end
        

        function self = loadEvents(self)

            dataFile = fullfile(self.directory, ['experiment' num2str(self.experimentIndex) '.nwb']);

            streamInfo = h5info(dataFile, '/acquisition');

            for i = 1:length(streamInfo.Groups)

                groupName = strsplit(streamInfo.Groups(i).Name, '/');

                streamName = groupName{end};

                type = streamInfo.Groups(i).Attributes(5).Value;

                if ~strcmp(type, 'TimeSeries')
                    continue;
                end

                eventInfo = streamInfo;

                type = strsplit(streamName, '.');
                nodeId = strsplit(type{1},'-'); nodeId = nodeId{end};

                timestamps = h5read(dataFile,[eventInfo.Groups(i).Name '/timestamps']);
                data = h5read(dataFile,[eventInfo.Groups(i).Name '/data']);
                sampleNumbers = h5read(dataFile,[eventInfo.Groups(i).Name '/sync']);
                fullWord = h5read(dataFile,[eventInfo.Groups(i).Name '/full_word']);
            
                self.ttlEvents(streamName) = DataFrame(str2double(nodeId)*ones(length(timestamps),1), sampleNumbers, timestamps, abs(data), data > 0, ...
                    'VariableNames', {'nodeId', 'sample_number', 'timestamp','line','state'});

            end

        end

        function self = loadSpikes(self)

            dataFile = fullfile(self.directory, ['experiment' num2str(self.experimentIndex) '.nwb']);

            streamInfo = h5info(dataFile, '/acquisition');

            for i = 1:length(streamInfo.Groups)

                groupName = strsplit(streamInfo.Groups(i).Name, '/');

                streamName = groupName{end};

                type = streamInfo.Groups(i).Attributes(5).Value;
                if ~strcmp(type, 'SpikeEventSeries')
                    continue;
                end

                spikeInfo = streamInfo;

                %nodeId = strsplit(type{1},'-'); nodeId = nodeId{end};

                spikes = {};

                spikes.timestamps = h5read(dataFile,[spikeInfo.Groups(i).Name '/timestamps']);
                spikes.waveforms = h5read(dataFile,[spikeInfo.Groups(i).Name '/data']);
                spikes.electrodes = h5read(dataFile,[spikeInfo.Groups(i).Name '/electrodes']);
                spikes.conversion = h5read(dataFile,[spikeInfo.Groups(i).Name '/channel_conversion']);
                spikes.sync = h5read(dataFile,[spikeInfo.Groups(i).Name '/sync']);

                self.spikes(streamName) = spikes;

            end


%             dataFile = fullfile(self.directory, ['experiment' num2str(self.experimentIndex) '.nwb']);
% 
%             spikeInfo = h5info(dataFile, ['/acquisition/timeseries/recording' num2str(self.recordingIndex) '/spikes']);
% 
%             channelGroups = spikeInfo.Groups;
% 
%             names = {};
%             for i = 1:length(channelGroups)
%                 names{end+1} = channelGroups(i).Name;
%             end
% 
%             channelCounts = [1 2 4];
% 
%             for count = 1:length(channelCounts)
% 
%                 spikes = {};
% 
%                 timestamps = {};
%                 waveforms = {};
%                 electrodes = {};
% 
%                 spikes.metadata = {};
%                 spikes.metadata.names = names; %electrodeData keys
% 
%                 if length(channelGroups) > 1
%                 
%                     for group = 1:length(channelGroups)
% 
%                         channelGroup = channelGroups(group);
% 
%                         if channelGroup.Datasets(1).ChunkSize(2) == channelCounts(count)
% 
%                             waveforms{end+1} = h5read(dataFile, [channelGroup.Name '/data']);
%                             timestamps{end+1} = h5read(dataFile, [channelGroup.Name '/timestamps']);
%                             electrodes{end+1} = zeros(length(timestamps{end}),1);
% 
%                         end
% 
%                     end
% 
%                 else
% 
%                     if channelGroups.Datasets(1).ChunkSize(2) == channelCounts(count)
% 
%                         waveforms{end+1} = h5read(dataFile, [channelGroups.Name '/data']);
%                         timestamps{end+1} = h5read(dataFile, [channelGroups.Name '/timestamps']);
%                         electrodes{end+1} = zeros(length(timestamps{end}),1);
% 
%                     end
% 
%                 end
% 
%                 spikes.timestamps = [timestamps{:}];
%                 spikes.waveforms = [waveforms{:}];
%                 spikes.electrodes = [electrodes{:}];
% 
%                 [~,order] = sort(spikes.timestamps);
% 
%                 spikes.timestamps = spikes.timestamps(order);
%                 
%                 spikes.waveforms = spikes.waveforms(:,:,order);
%                 %waveforms = permute(spikes.waveforms,[1 3 2]);
%                 %spikes.waveforms = reshape(waveforms, [], size(spikes.waveforms,2), 1);
% 
%                 spikes.electrodes = spikes.electrodes(order);
% 
%                 self.spikes(num2str(count)) = spikes;
% 
%             end
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

                %streamInfo = h5info(nwbFiles{i}, '/acquisition/');

                recordingIndex = 1;

                recordings{end+1} = NwbRecording(directory, experimentIndex, recordingIndex);

            end

        end
        
    end

end