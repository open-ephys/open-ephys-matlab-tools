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

classdef OpenEphysRecording < Recording

    properties (Constant)

        NUM_HEADER_BYTES = 1024;
        SAMPLES_PER_RECORD = 1024;
        BYTES_PER_SAMPLE = 2;
        RECORD_MARKER = [0 1 2 3 4 5 6 7 8 255];
        EVENT_RECORD_SIZE = 32;

    end

    properties

        experimentId;
        recordSize;

    end

    methods 

        function self = OpenEphysRecording(directory, experimentIndex, recordingIndex) 
         
            self = self@Recording(directory, experimentIndex, recordingIndex);

            self.recordSize = 4 + 8 + self.SAMPLES_PER_RECORD * self.BYTES_PER_SAMPLE + length(self.RECORD_MARKER);

            if experimentIndex == 0
                self.experimentId = '';
            else
                self.experimentId = ['_', num2str(experimentIndex + 1)];
            end

            self = self.loadContinuous();
            self = self.loadEvents();
            self = self.loadSpikes();

            %self.show();

        end

        function self = loadContinuous(self)

            files = self.findContinuousFiles();

            processorIds = files.keys

            for i = 1:length(processorIds)

                streamFiles = files(processorIds{i})';
                
                [timestamps, ~, ~] = self.loadContinuousFile(streamFiles{1});

                stream = {};

                stream.metadata = {};
                stream.metadata.names = [];
                stream.metadata.processorId = processorIds(i);

                f = cellfun(@(x) regexp(x, '[\\/]', 'split'), streamFiles, 'UniformOutput', false); f = vertcat(f{:}); f = f(:,end);
                f = cellfun(@(x) regexp(x, '[_.]', 'split'), f, 'UniformOutput', false); f = vertcat(f{:});

                stream.samples = zeros(length(timestamps), length(streamFiles));

                for j = 1:length(f)
            
                    [timestamps, samples, header] = self.loadContinuousFile(streamFiles{j});

                    stream.samples(j,1:length(samples)) = samples;

                end

                self.continuous(processorIds{i}) = stream;

            end

        end

        function self = loadEvents(self)

            filename = fullfile(self.directory, ['all_channels' self.experimentId '.events'])

            [timestamps, processorId, state, channel, header] = self.loadEventsFile(filename, self.recordingIndex);

            self.ttlEvents('all') = DataFrame(channel + 1, timestamps, processorId, state, 'VariableNames', {'channel','timestamp','nodeID','state'}); 

        end

        function self = loadSpikes(self)

            fileTypes = {'single electrode', 'stereotrode', 'tetrode'};

            for i = 1:length(fileTypes)
                files = self.findSpikeFiles(fileTypes{i});
                for j = 1:length(files)
                    [timestamps, waveforms, header] = self.loadSpikeFile(files{j}, self.recordingIndex);

                    spikes = {};

                    spikes.waveforms = waveforms';
                    spikes.timestamps = timestamps;
        
                    self.spikes(header('electrode')) = spikes;

                end
            end

        end

        function files = findContinuousFiles(self)

            %Find all continuous files that belong to this experiment, return as a map indexed by processor id
            paths = glob(fullfile(self.directory, '*continuous'))
            f = cellfun(@(x) regexp(x, '[\\/]', 'split'), paths, 'UniformOutput', false); f = vertcat(f{:});
            f = cellfun(@(x) regexp(x, '[._]', 'split'), f(:,end), 'UniformOutput', false);

            files = containers.Map();

            for i = 1:length(f)
                processorId = f{i}{1};
                channel = str2num(f{i}{2});
                if length(f{i}) > 3
                    experimentIndex = str2num(f{i}{3});
                else
                    experimentIndex = 0;
                end
                if experimentIndex == self.experimentIndex
                    if isKey(files, processorId)
                        pFiles = files(processorId);
                        pFiles{end+1} = paths{i};
                        files(processorId) = pFiles;
                    else
                        files(processorId) = { paths{i} };
                    end
                end
                %fprintf("Found processorId: %d, channel: %d experimentIdx: %d\n", processorId, channel, experimentIdx);
            end

        end

        function files = findSpikeFiles(self, fileType)

            searchString = containers.Map();
            searchString('single electrode') = 'SE';
            searchString('stereotrode') = 'ST';
            searchString('tetrode') = 'TT';

            if self.experimentIndex == 0
                paths = glob(fullfile(self.directory, [searchString(fileType), '*spikes']));
            else
                paths = glob(fullfile(self.directory, [searchString(fileType), '*', self.experimentIndex, '*spikes']));
            end

            %TODO: Only return files belonging to experiment id...
            files = paths;

        end

        function [timestamps, samples, header] = loadContinuousFile(self, filename)

            fid = fopen(filename);
            hdr = fread(fid, self.NUM_HEADER_BYTES, 'char*1');

            numRecords = self.getNumRecords(filename);
            header = self.readHeader(filename);

            timestamps = [];
            samples = [];
            recordingNumbers = [];
            for i = 1:numRecords
                timestamp = fread(fid, 1, 'int64',0,'l');
                timestamps = [timestamps, timestamp];
                N = fread(fid, 1, 'uint16',0,'l');
                recordingNumber = fread(fid, 1, 'uint16', 0, 'l');
                recordingNumbers = [recordingNumbers, recordingNumber];
                samples = [samples; fread(fid, N, 'int16',0,'b')];
                recordmarker = fread(fid, 10, 'char*1');
            end
            fclose(fid);
            
            %TODO: Implement memory mapping for faster loading (not yet working)
            % data = memmapfile(filename, 'Writable', false, 'Format', 'int16', 'Offset', self.NUM_HEADER_BYTES);

            % samples = reshape(data.Data, [floor(self.recordSize / 2), numRecords]);

            % validRecords = samples(end-4,:) == self.recordingIndex * 256;

            % sampleMask = zeros(floor(self.recordSize / 2));
            % sampleMask(7:end-6) = 1;
            % sampleMask = repmat(sampleMask, numRecords, 1);

            % recordMask = zeros(floor(self.recordSize / 2), numRecords);
            % recordMask(validRecords,:) = 1;

            % mask = sampleMask * recordMask;

            % firstRecord = min(find(mask))

        end

        function [timestamps, processorId, state, channel, header ] = loadEventsFile(self, filename, recordingIndex)

            header = self.readHeader(filename);

            timestamps = memmapfile(filename, 'Writable', false, 'Offset', 1024, 'Format', 'int64');

            timestamps = timestamps.Data(1:2:end);

            data = memmapfile(filename, 'Writable', false, 'Offset', 1024);
            data = reshape(data.Data, floor(self.EVENT_RECORD_SIZE / 2), length(timestamps));
            
            recordingNumber = data(15,:);

            mask = recordingNumber == recordingIndex;
            processorId = data(12,mask)';
            state = data(13,mask)';
            channel = data(14,mask)';

        end
        
            
        function [timestamps, waveforms, header] = loadSpikeFile(self, filename, recordingNumber)

            header = self.readHeader(filename);

            fid = fopen(filename);
            fread(fid, 1043, 'char*1');
            numChannels = fread(fid, 1, 'uint16', 0, 'l');
            numSamples = fread(fid, 1, 'uint16', 0, 'l');
            fclose(fid);

            SPIKE_RECORD_SIZE = 42 + 2 * numChannels * numSamples + 4 * numChannels + 2 * numChannels + 2;

            POST_BYTES = 4 * numChannels + 2 * numChannels + 2;

            s = dir(filename);
            numSpikes = floor(( s.bytes - self.NUM_HEADER_BYTES ) / SPIKE_RECORD_SIZE);

            timestamps = zeros(numSpikes,1);

            fid = fopen(filename);
            fread(fid, self.NUM_HEADER_BYTES+1, 'char*1');

            for i  = 1:length(timestamps)
                timestamps(i) = fread(fid, 1, 'int64');
                fseek(fid, self.NUM_HEADER_BYTES + 1 + SPIKE_RECORD_SIZE * i, -1);
            end

            data = memmapfile(filename, 'Writable', false, 'Offset', self.NUM_HEADER_BYTES, 'Format', 'uint16');
            data = reshape(data.Data, floor(SPIKE_RECORD_SIZE / 2), numSpikes);

            mask = data(end,:) == recordingNumber;

            [r,~] = size(data);
            waveforms = single(data(22:(r - floor(POST_BYTES/2)), mask==1));
            waveforms = waveforms - 32768;
            waveforms = waveforms / 20000;
            waveforms = waveforms * 1000;

        end

        function numRecords = getNumRecords(self, filename)

            fr = matlab.io.datastore.DsFileReader(filename);

            s = dir(filename);

            numRecords = ( s.bytes - self.NUM_HEADER_BYTES ) / self.recordSize;

            assert(mod(numRecords,1) == 0);

        end

        function header = readHeader(self, filename)

            %Return header as a containers.Map (matlab dictionary)
            header = containers.Map();
            fr = matlab.io.datastore.DsFileReader(filename);
            rawHeader = strrep(native2unicode(read(fr, self.NUM_HEADER_BYTES))', 'header.', '');
            rawHeader = strsplit(rawHeader,'\n');
            for i = 1:length(rawHeader)
                keyVal = strsplit(rawHeader{i},"=");
                if length(keyVal) > 1
                    key = strtrim(keyVal{1});
                    value = strtrim(erase(keyVal{2},";"));
                    header(key) = value;
                end
            end

        end

    end

    
end