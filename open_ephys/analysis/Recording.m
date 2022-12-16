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

        function self = addSyncLine(self, line, processorId, streamIdx, streamName, isMain)

            % Specifies an event channel to use for timestamp synchronization. Each
            % sync channel in a recording should receive its input from the same
            % physical digital input line.

            % For synchronization to work, there must be one (and only one) main
            % sync channel, to which all timestamps will be aligned.

            % Parameters
            % ----------
            % line : int
            %     event channel number
            % processorId : int
            %     ID for the processor receiving sync events
            % streamName : string
            %     name of the stream the line belongs to
            %     default = 0
            % main : bool
            %     if True, this processors timestamps will be treated as the main clock

            if isMain
                %TODO: Check for existing main and either overwrite or show
                %warning
            end

            syncChannel = {};
            syncChannel.line = line;
            syncChannel.processorId = processorId;
            syncChannel.streamName = streamName;
            syncChannel.isMain = isMain;
            syncChannel.streamName = streamName;

            streams = self.continuous.keys();

            for i = 1:length(streams)
                stream = self.continuous(streams{i});
                if strcmp(stream.metadata.streamName, syncChannel.streamName)
                    syncChannel.sampleRate = stream.metadata.sampleRate;
                    Utils.log("Setting sync channel ", num2str(i), " to ", stream.metadata.streamName, " @ ", num2str(stream.metadata.sampleRate));
                end
            end

            for i = 1:length(self.syncLines)

                if self.syncLines{i}.processorId == processorId && strcmp(self.syncLines{i}.streamName, streamName)

                    Utils.log("Found existing sync line, overwriting with new line!");
                    self.syncLines{streamIdx} = syncChannel;
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
                Utils.log("At least two sync channels must be specified using 'addSyncChannel' before global timestamps can be computed");
                return;
            end

            % Identify main sync line
            mainIdx = 0;
            for i = 1:length(self.syncLines)
                if self.syncLines{i}.isMain
                    main = self.syncLines{i};
                    mainIdx = i;
                    break;
                end
            end

            if length(self.syncLines) < 2
                Utils.log("Computing global timestamps requires at least two auxiliary sync channels!");
                return;
            elseif mainIdx == 0
                Utils.log("No main line designated by user, assuming first available sync is main...");
                mainIdx = 1;
                main = self.syncLines{mainIdx};
            end

            Utils.log("Found main stream: ", num2str(mainIdx));

            eventProcessors = self.ttlEvents.keys;

            % Get events for main sync line
            for i = 1:length(eventProcessors)

                events = self.ttlEvents(eventProcessors{i});

                if events.line(1) == main.line && ...
                        strcmp(eventProcessors{i}, main.streamName)

                    mainStartSample = events.sample_number(1);
                    mainTotalSamples = events.sample_number(end) - mainStartSample;

                end

            end

            % Update sync parameters for main sync
            self.syncLines{mainIdx}.start = mainStartSample;
            self.syncLines{mainIdx}.scaling = 1;
            self.syncLines{mainIdx}.offset = mainStartSample;

            % Update sync parameters for auxiliary lines
            for i = 1:length(self.syncLines)

                if ~(i == mainIdx)

                    for j = 1:length(eventProcessors)

                        events = self.ttlEvents(eventProcessors{j});

                        if events.line(1) == self.syncLines{i}.line && ...
                            events.processor_id(1) == self.syncLines{i}.processorId && ...
                            events.stream_name(1) == self.syncLines{i}.streamName

                            auxStartSample = events.sample_number(1);
                            auxTotalSamples = events.sample_number(end) - auxStartSample;
                            self.syncLines{i}.start = auxStartSample;
                            self.syncLines{i}.scaling = double(mainTotalSamples) / double(auxTotalSamples);
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

                    if strcmp(stream.metadata.streamName, sync.streamName)

                        stream.globalTimestamps = (stream.sampleNumbers - sync.start) * sync.scaling + sync.offset;

                        if self.format ~= "NWB"

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