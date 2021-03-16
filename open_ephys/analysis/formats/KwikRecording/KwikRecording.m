%{
MIT License

Copyright (c) 2021 Open Ephys

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
%}

classdef KwikRecording < Recording

    properties

        path

    end

    methods 

        function self = KwikRecording(directory, experimentIndex, recordingIndex) 
            
            self = self@Recording(directory, experimentIndex, recordingIndex);

            self.loadContinuous();
            self.loadEvents();
            self.loadSpikes();

        end

        function self = loadContinuous(self)


            kwdFiles = glob(fullfile(self.directory, ['experiment' num2str(self.experimentIndex + 1) '*.kwd']));

            for i = 1:length(kwdFiles)

                stream = {};

                %h5disp(kwdFiles{i});

                info = h5info(kwdFiles{i});

                stream.samples = h5read(kwdFiles{i}, ['/recordings/' num2str(self.recordingIndex) '/data'])';

                timestamps = h5read(kwdFiles{i}, ['/recordings/' num2str(self.recordingIndex) '/application_data/timestamps']);

                startTime = timestamps(1,1);

                stream.timestamps = startTime:(startTime + length(stream.samples) - 1);

                self.continuous(num2str(i)) = stream;

            end

        end

        function self = loadEvents(self)

            eventsFile = fullfile(self.directory, ['experiment' num2str(self.experimentIndex + 1) '.kwe']);

            %h5disp(eventsFile);
        
            recordings = h5read(eventsFile, '/event_types/TTL/events/recording');
            timestamps = h5read(eventsFile, '/event_types/TTL/events/time_samples');
            
            mask = recordings == self.recordingIndex;
            
            eventChannels = h5read(eventsFile, '/event_types/TTL/events/user_data/event_channels');
            eventID = h5read(eventsFile, '/event_types/TTL/events/user_data/eventID');
            nodeID = h5read(eventsFile, '/event_types/TTL/events/user_data/nodeID');

            self.ttlEvents(['experiment' num2str(self.experimentIndex + 1)]) = DataFrame(eventChannels(mask), timestamps(mask), nodeID(mask), eventID(mask), 'VariableNames', {'channel','timestamp','nodeID','state'}); 
            

        end

        function self = loadSpikes(self)

            spikesFile = fullfile(self.directory, ['experiment' num2str(self.experimentIndex + 1) '.kwx']);

            %h5disp(spikesFile);

            fileInfo = h5info(spikesFile);

            channelGroups = fileInfo.Groups;

            names = {};
            for i = 1:length(channelGroups.Groups)
                names{end+1} = channelGroups.Groups(i).Name;
            end

            channelCounts = [1 2 4];

            for count = 1:length(channelCounts)

                spikes = {};

                timestamps = {};
                waveforms = {};
                electrodes = {};

                spikes.metadata = {};
                spikes.metadata.names = names; %electrodeData keys
                
                for group = 1:length(channelGroups.Groups)

                    channelGroup = channelGroups.Groups(group);

                    if channelGroup.Datasets(3).ChunkSize(1) == channelCounts(count)

                        name = regexp(channelGroup.Name, '[\\/]', 'split'); name = name{end};

                        recordings = h5read(spikesFile, ['/channel_groups/' name '/recordings']);

                        mask = recordings == self.recordingIndex;

                        timeSamples = h5read(spikesFile, ['/channel_groups/' name '/time_samples']);
                        timestamps{end+1} = timeSamples(mask);

                        waveformsFiltered = h5read(spikesFile, ['/channel_groups/' name '/waveforms_filtered']);
                        waveforms{end+1} = waveformsFiltered(:,:,mask);

                        electrodes{end+1} = (group - 1) * ones(length(timestamps{end}));

                    end

                end

                spikes.timestamps = [timestamps{:}];
                spikes.waveforms = [waveforms{:}];
                spikes.electrodes = [electrodes{:}];

                [~,order] = sort(spikes.timestamps);

                spikes.timestamps = spikes.timestamps(order);
                spikes.waveforms = spikes.waveforms(:,:,order);
                spikes.electrodes = spikes.electrodes(order);

                self.spikes(num2str(count)) = spikes;

            end

        end

    end

end