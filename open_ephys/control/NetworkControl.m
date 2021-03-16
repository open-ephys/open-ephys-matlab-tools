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

classdef NetworkControl

    properties

        ipAddress
        port

        url
        context
        socket 

    end

    methods
        
        function self = NetworkControl()

            self.ipAddress = '127.0.0.1';
            self.port = 5556;
            
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

            if state == 1
                zmq.core.send(self.socket, uint8(['TTL Channel=' num2str(channel) ' on=1']));
            else
                zmq.core.send(self.socket, uint8(['TTL Channel=' num2str(channel) ' on=0']));
            end
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