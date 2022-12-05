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

classdef (Abstract) Recording < handle

    %RECORDING - Abstract class representing data from a single Recording
    % RECORDING - Classes for different data formats should inherit from this class.
    %
    % Recording objects contain three properties:
    % - continuous
    % - ttlEvents
    % - spikes
    %
    % SYNTAX:
    %   recordNode = RecordNode( 'path/to/record/node' )
    %
    % PROPERTIES:
    %   directory - the root directory that contains the recorded continuous, events and spike data
    %   experimentIndex - the index of an experiment within a session
    %   recordingIndex - the index of a recording within an experiment 
    %
    %   continuous is a list of data streams
    %       - samples (memory-mapped array of dimensions samples x channels)
    %       - timestamps (array of length samples)
    %       - metadata (contains information about the data source)
    
    %   spikes is a list of spike sources
    %       - waveforms (spikes x channels x samples)
    %       - timestamps (one per spikes)
    %       - electrodes (index of electrode from which each spike originated)
    %       - metadata (contains information about each electrode)
    %
    %   ttlEvent data is stored in a n x 4 array containing four columns:
    %       - timestamp
    %       - channel
    %       - nodeId (processor ID)
    %       - state (1 or 0)

    properties

        format

        directory
        experimentIndex
        recordingIndex

        continuous
        ttlEvents
        spikes

        messages

        syncLines

    end

    methods

        function self = Recording(directory, experimentIndex, recordingIndex)
            
            self.directory = directory;
            self.experimentIndex = experimentIndex;
            self.recordingIndex = recordingIndex;

            self.continuous = containers.Map();
            self.ttlEvents = containers.Map();
            self.spikes = containers.Map();

            self.messages = containers.Map();

            self.syncLines = {};

        end

        function self = addSyncChannel(self, channel, processorId, subprocessorId, main)

            % Specifies an event channel to use for timestamp synchronization. Each
            % sync channel in a recording should receive its input from the same
            % physical digital input line.

            % For synchronization to work, there must be one (and only one) 'main'
            % sync channel, to which all timestamps will be aligned.

            % Parameters
            % ----------
            % channel : int
            %     event channel number
            % processorId : int
            %     ID for the processor receiving sync events
            % subprocessorId : int
            %     index of the subprocessor receiving sync events
            %     default = 0
            % main : bool
            %     if True, this processor's timestamps will be treated as the
            %     main clock

            if main
                %TODO: Check for existing main
            end

            syncChannel = {};
            syncChannel.channel = channel;
            syncChannel.processorId = processorId;
            syncChannel.subprocessorId = subprocessorId;
            syncChannel.main = main;

            for i = 1:length(self.syncLines)

                if self.syncLines{i}.processorId == processorId && self.syncLines{i}.subprocessorId == subprocessorId

                    fprintf("Found existing sync line, overwriting with new line!\n");
                    self.syncLines{i} = syncChannel;
                    break;

                end

                if i == length(self.syncLines)
                    self.syncLines{end+1} = syncChannel;
                end

            end

            if isempty(self.syncLines)
                self.syncLines{end+1} = syncChannel;
            end

        end

        function self = computeGlobalTimestamps(self)

            % After sync channels have been added, this function computes the
            % the global timestamps for all processors with a shared sync line

            if isempty(self.syncLines)
                fprintf("At least two sync channels must be specified using 'addSyncChannel' before global timestamps can be computed\n");
                return;
            end

            % Identify main sync line
            mainIdx = 0;
            for i = 1:length(self.syncLines)
                if self.syncLines{i}.main
                    main = self.syncLines{i};
                    mainIdx = i;
                    break;
                end
            end

            if ~mainIdx || length(self.syncLines) < 2
                fprintf("Computing global timestamps requires one main sync channel and at least one auxiliary sync channel!\n");
                return;
            end

            mainEvents = 0;
            eventProcessors = self.ttlEvents.keys;

            % Get events for main sync line
            for i = 1:length(eventProcessors)

                events = self.ttlEvents(eventProcessors{i});

                if events.channel(1) == main.channel && ...
                        events.processorId(1) == main.processorId && ...
                        events.subprocessorId(1) == main.subprocessorId % && events.state(1) == 1

                    mainEvents = events;
                    mainStartSample = events.timestamp(1);
                    mainTotalSamples = events.timestamp(end) - mainStartSample;

                end

            end

            % Update sync parameters for main sync
            self.syncLines{mainIdx}.start = mainStartSample;
            self.syncLines{mainIdx}.scaling = 1;
            self.syncLines{mainIdx}.offset = mainStartSample;

            % Get main sync line sample rate from continuous stream
            continuousProcessors = self.continuous.keys;
            for i = 1:length(continuousProcessors)

                stream = self.continuous(continuousProcessors{i});
                if stream.metadata.processorId == main.processorId && stream.metadata.subprocessorId == main.subprocessorId
                    self.syncLines{mainIdx}.sampleRate = stream.metadata.sampleRate;
                    break;
                end

            end

            % Update sync parameters for auxiliary lines
            for i = 1:length(self.syncLines)

                if ~(i == mainIdx)

                    eventProcessors = self.ttlEvents.keys;

                    for j = 1:length(eventProcessors)

                        events = self.ttlEvents(eventProcessors{j});

                        if events.channel(1) == self.syncLines{i}.channel && ...
                            events.processorId(1) == self.syncLines{i}.processorId && ...
                            events.subprocessorId(1) == self.syncLines{i}.subprocessorId % && events.state(1) == 1

                            auxStartSample = events.timestamp(1);
                            auxTotalSamples = events.timestamp(end) - auxStartSample;

                            self.syncLines{i}.start = auxStartSample;
                            self.syncLines{i}.scaling = mainTotalSamples / auxTotalSamples;
                            self.syncLines{i}.offset = mainStartSample;
                            self.syncLines{i}.sampleRate = self.syncLines{mainIdx}.sampleRate;

                        end

                    end

                end

            end

            % Compute global timestamps for all channels
            for i = 1:length(self.syncLines)

                sync = self.syncLines{i};

                streams = self.continuous.keys;

                for j = 1:length(streams)

                    stream = self.continuous(streams{j});

                    if stream.metadata.processorId == sync.processorId && ...
                            stream.metadata.subprocessorId == sync.subprocessorId

                        stream.globalTimestamps = stream.timestamps - sync.start * sync.scaling + sync.offset;

                        if self.format ~= "NWB"

                            sync.sampleRate
                            stream.globalTimestamps = double(stream.globalTimestamps) / sync.sampleRate;

                        end

                        self.continuous(streams{j}) = stream;

                    end

                end

            end

        end

    end

    methods (Abstract)

        loadSpikes(self)

        loadEvents(self)

        loadContinuous(self)

        %toString(self)

    end

    methods(Abstract, Static)

        detectFormat(directory) 
        
        detectRecordings(directory) 

    end

end