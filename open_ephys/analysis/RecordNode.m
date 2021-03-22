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

classdef RecordNode < handle 

%{
    A 'RecordNode' object represents a directory containing data from
    one Open Ephys Record Node.
    
    Each Record Node placed in the signal chain will write data to its own
    directory.
    
    A RecordNode object contains a list of Recordings that can be accessed via:
        
        recordnode.recordings[n]
        
    where N is the index of the Recording (e.g., 0, 1, 2, ...)
%}

    properties

        directory
        format
        recordings

    end

    methods 

        function self = RecordNode(directory) 

            self.directory = directory;

            self.format = '';
            self.detectFormat();
            self.detectRecordings();

        end

        function self = detectFormat(self)

            if BinaryRecording.detectFormat(self.directory)
                self.format = 'Binary';
            elseif OpenEphysRecording.detectFormat(self.directory)
                self.format = 'OpenEphys';
            elseif KwikRecording.detectFormat(self.directory)
                self.format = 'KWIK';
            elseif NwbRecording.detectFormat(self.directory)
                self.format = 'NWB';
            end

        end

        function self = detectRecordings(self)

            switch self.format
                
            case 'Binary'
                self.recordings = BinaryRecording.detectRecordings(self.directory);
            case 'OpenEphys'
                self.recordings = OpenEphysRecording.detectRecordings(self.directory);
            case 'KWIK'
                self.recordings = KwikRecording.detectRecordings(self.directory);
            case 'NWB'
                self.recordings = NwbRecording.detectRecordings(self.directory);

            otherwise
                disp('A valid format has not been detected!');
            end

        end

    end

end