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

classdef NetworkControl

    %NETWORKCONTROL - A class that communicates with the Open Ephys NetworkEvents plugin
    % NETWORKCONTROL - See: https://github.com/open-ephys-plugins/NetworkEvents for more info.
    %
    %It can be used to start/stop acquisition, start/stop recording, and 
    %send TTL events to an instance of the Open Ephys GUI, either locally
    %or over a network connection.
    %
    % SYNTAX:
    %   gui = NetworkControl( '127.0.0.1', 5556 )
    %
    % PROPERTIES:
    %   ipAddress - IP Adress of machine running OpenEphys
    %   port - port as indicated by active NetworkEvents plugin in OpenEphys
    %   url - full tcp address 
    %   context - ZMQ context running in REQ-REP patter
    %   socket - the socket for this context 
    %
    % EXAMPLES:
    %   gui.startAcquisition()
    %   Response: StartedAcquisition
    %   
    %   gui.isAcquiring()
    %   True
    %   
    %   gui.record()
    %   Response: StartedRecording
    %
    %   gui.isRecording()
    %   True
    %
    %   gui.sendTTL(5, 1)
    %   Response: TTLHandled: Channel=5 on=1
    %
    %   gui.stopRecording()
    %   Response: StoppedRecording
    %
    %   gui.isRecording()
    %   False
    %  
    %   gui.stopAcquisition()
    %   Response: StoppedAcquisition

    properties

        ipAddress
        port

        url
        context
        socket 

    end

    methods
        
        function self = NetworkControl(varargin)

            if nargin == 0
                self.ipAddress = '127.0.0.1';
                self.port = 5556;
            elseif nargin == 2
                self.ipAddress = varargin{1};
                self.port = varargin{2};
            else
                fprintf("Error: NetworkControl takes either 0 or 2 input parameters\n");
                return;
            end
            
            self.url = ['tcp://' self.ipAddress ':' num2str(self.port)];

            self.context = zmq.core.ctx_new();
            self.socket  = zmq.core.socket(self.context, 'ZMQ_REQ');

            zmq.core.connect(self.socket, self.url);

        end

        function delete(self)

            zmq.core.disconnect(self.socket, self.url);
            zmq.core.close(self.socket);

        end

        function startAcquisition(self)

            zmq.core.send(self.socket, uint8('StartAcquisition'));
            reply = char(zmq.core.recv(self.socket));

        end

        function stopAcquisition(self)

            zmq.core.send(self.socket, uint8('StopAcquisition'));
            reply = char(zmq.core.recv(self.socket));

        end

        function record(self)

            zmq.core.send(self.socket, uint8('StartRecord'));
            reply = char(zmq.core.recv(self.socket));

        end

        function startRecording(self)
            
            self.record();

        end

        function stopRecording(self)

            zmq.core.send(self.socket, uint8('StopRecord'));
            reply = char(zmq.core.recv(self.socket));

        end

        function reply = isRecording(self)

            zmq.core.send(self.socket, uint8('IsRecording'));
            reply = char(zmq.core.recv(self.socket)) == '1';

        end

        function reply = isAcquiring(self)

            zmq.core.send(self.socket, uint8('IsAcquiring'));
            reply = char(zmq.core.recv(self.socket)) == '1';

        end

        function sendTTL(self, channel, state)

            zmq.core.send(['TTL Channel=' num2str(channel) ' on=' num2str(state)]);
            reply = char(zmq.core.recv(self.socket));

        end

        function wait(self, timeInSeconds)

            pause(timeInSeconds);

        end

        function getResponse(self)

            zmq.core.send(self.socket, uint8('StopAcquisition'));
            reply = char(zmq.core.recv(self.socket));

        end

    end

end