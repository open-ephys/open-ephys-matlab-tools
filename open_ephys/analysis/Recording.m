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

classdef (Abstract) Recording

    %RECORDING - Abstract class representing data from a single Recording
    % RECORDING - Classes for different data formats should inherit from this class.
    %
    % Recording objects contain three properties:
    % - continuous
    % - events
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

        directory
        experimentIndex
        recordingIndex

        continuous
        ttlEvents
        spikes

    end

    methods

        function self = Recording(directory, experimentIndex, recordingIndex)
            
            self.directory = directory;
            self.experimentIndex = experimentIndex;
            self.recordingIndex = recordingIndex;

            self.continuous = containers.Map();
            self.ttlEvents = containers.Map();
            self.spikes = containers.Map();

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