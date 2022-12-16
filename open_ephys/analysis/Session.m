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

classdef Session < handle

    %SESSION - class representing an OpenEphys session.
    % SESSION - Each 'Session' object represents a top-level directory containing data from
    % one or more Record Nodes.

    % A new directory is automatically started when launching Open Ephys, or after
    % pressing the '+' button in the record options section of the control panel. 
    %
    % SYNTAX:
    %   session = Session( 'path/to/recording/directory' )
    %
    % PROPERTIES:
    %   directory - the root directory that contains the record nodes 
    %   recordNodes - an array of all the record nodes corresponding to this session
    %
    % EXAMPLES:
    %   session = Session( '/home/open-ephys/2021-03-24_15-17-19' )
    %   session.show()
    %   
    %   node = session.recordNodes{1} 

    properties

        directory
        recordNodes

    end

    methods 

        function self = Session(directory) 

            self.directory = directory;

            Utils.log("Searching directory: ", directory);

            self.recordNodes = {};
            self.detectRecordNodes();

        end

        function self = detectRecordNodes(self)

            paths = glob(fullfile(self.directory, 'Record Node *'));

            for i = 1:length(paths)
                self.recordNodes{end+1} = RecordNode(paths{i});
            end


        end

        function show(self)

            for i = 1:length(self.recordNodes)

                node = self.recordNodes{i};
                fprintf("(%d) %s : %s Format \n", i, node.name, node.format);

            end

        end

    end

end