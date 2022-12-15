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

classdef OpenEphysHTTPServer < handle

    properties (Constant)
    end

    properties

        address
        options

    end

    methods 

        function self = OpenEphysHTTPServer(host, port)
            
            self.address = strcat('http://', host, ':', num2str(port));
            self.options = weboptions(...
                'MediaType', 'application/json',...
                'RequestMethod', 'put');
            
        end

    end

    methods

        function resp = send(self, varargin)

%             Send a request to the server.
%             
%             Parameters
%             ----------
%             endpoint : String
%                The API endpoint for the request.
%                Must begin with "/api/"
%             payload (optional): Dictionary
%                The payload to send with the request.
%             
%                If a payload is specified, a PUT request
%                will be used; otherwise it will be a GET request.

            
            endpoint = varargin{1};
            if nargin > 2
                payload = varargin{2};
            end

            try

                if nargin == 2
                    resp = webread(strcat(self.address, endpoint));
                else
                    resp = webwrite(strcat(self.address, endpoint), payload, self.options);
                end
                
            catch ME
%             TODO: Catch matlab equivalents of these
%             except requests.exceptions.Timeout:
%                 # Maybe set up for a retry, or continue in a retry loop
%                 print("Timeout")
%             except requests.exceptions.TooManyRedirects:
%                 # Tell the user their URL was bad and try a different one
%                 print("Bad URL")
%             except requests.exceptions.RequestException as e:
%                 # Open Ephys server needs to be enabled
%                 print("Open Ephys HTTP Server likely not enabled")

                resp = "GUI was closed!";
            end
                
        end

        function resp = load(self, path)

%           Load a configuration file.
% 
%           Parameters
%           ----------
%           path : String
%               The path to the configuration file.

            payload = struct('path', path);

            resp = self.send('/api/load', payload);
            pause(1);
            
        end

        function processors = get_processor_list(self)

%           Returns all available processors in the GUI's Processor List

            data = self.send('/api/processors/list');
            processors = string(char({data.processors.name}));

        end

        function processors = get_processors(self, varargin)
    
%           Get the list of processors.
    
%           Parameters
%           ----------
%           filter_by_name : String (Optional)
%               Filter the list by processor name.
    
            data = self.send('/api/processors');
            processors = data.processors;
            if nargin > 1
                indices = cellfun(@(v)strcmp(v,varargin{1}),{processors.name});
                processors = processors(indices);
            end
    
        end

        function resp = clear_signal_chain(self)

%           Clear the signal chain.

            resp = self.send('/api/processors/clear');

        end
        
        function resp = add_processor(self, name, varargin)

%           Add a processor to the signal chain.
% 
%           Parameters
%           ----------
%           name : String
%               The name of the processor to add (e.g. "Record Node")
%           source : Integer
%               The 3-digit processor ID of the source (e.g. 101)
%           dest : Integer
%               The 3-digit processor ID of the destination (e.g. 102)

            endpoint = '/api/processors/add';
            payload = struct('name', name);

%           If only processor name is specified, set source to most recently added processor
            if nargin == 2
                existingProcessors = self.get_processors();
                if ~isempty(existingProcessors)
                    index = find([existingProcessors.id] == max([existingProcessors.id]));
                    mostRecentProcessor = existingProcessors(index);
                    payload.source_id = mostRecentProcessor.id;
                end
            elseif nargin > 2
                payload.source_id = varargin{1};
                if nargin == 4
                    payload.dest_id = varargin{2};
                end
            end
            
            resp = self.send(endpoint, payload);
            
        end
        
        
        function resp = delete_processor(self, id)

%           Delete a processor.
% 
%           Parameters
%           ----------
%           processor_id : Integer
%               The 3-digit processor ID (e.g. 101)
% 
            endpoint = '/api/processors/delete';
            payload = struct('id', id);

            resp = self.send(endpoint, payload);
            
        end
        
    
        function resp = get_parameters(self, processor_id, stream_index)

%           Get parameters for a stream.
% 
%           Parameters
%           ----------
%           processor_id : Integer
%               The 3-digit processor ID (e.g. 101)
%           stream_index : Integer
%               The index of the stream (e.g. 0).
% 
            endpoint = strcat('/api/processors/', num2str(processor_id), '/streams/', num2str(stream_index), '/parameters');
            resp = self.send(endpoint).parameters;
            
        end
       
        function resp = set_parameter(self, processor_id, stream_index, param_name, value)

%           Update a parameter value
% 
%           Parameters
%           ----------
%           processor_id : Integer
%               The 3-digit processor ID (e.g. 101)
%           stream_index : Integer
%               The index of the stream (e.g. 0)
%           param_name : String
%               The parameter name (e.g. low_cut)
%           value : Any
%               The parameter value (must match the parameter type).
%               Hint: Float parameters must be sent with a decimal 
%               included (e.g. 1000.0 instead of 1000)
% 
            endpoint = strcat('/api/processors/', num2str(processor_id), '/streams/', num2str(stream_index), '/parameters/', param_name);
            
%           TOFIX:, matlab automatically casts doubles to int if no
%           integers after the decimal point of a float.
            if isa(value, 'double')
                payload = struct('value', [], 'class', {'double'});
                payload.value = value + 0.00000000001;
            else
                payload = struct('value', value);
            end
            resp = self.send(endpoint, payload);
            
        end
       

        function resp = get_recording_info(self, varargin)
            
%           Get recording information.
% 
%           Parameters
%           ----------
%           key : String
%               The key to get.
%  

            data = self.send('/api/recording');
            if nargin == 1
                resp = data;
            elseif isfield(data, varargin{1})
                resp = data.(varargin{1});
            else
                resp = "Invalid key";
            end
        end
    
        function resp = set_parent_dir(self, path)
            
%           Set the parent directory.
% 
%           Parameters
%           ----------
%           path : String
%               The path to the parent directory.

            payload = struct('parent_directory', path);
            data = self.send('/api/recording', payload);
            resp = data;

        end
        
        function resp = set_prepend_text(self, text)
            
%           Set the prepend text.
% 
%           Parameters
%           ----------
%           text : String
%               The text to prepend.
%
            payload = struct('prepend_text', text);
            data = self.send('/api/recording', payload);
            resp = data;

        end

        function resp = set_base_text(self, text)
            
%           Set the base text.
% 
%           Parameters
%           ----------
%           text : String
%               The text to base name of the recording directory (see GUI docs).
%
            payload = struct('base_text', text);
            data = self.send('/api/recording', payload);
            resp = data;

        end
        
        function resp = set_append_text(self, text)
            
%           Set the append text.
% 
%           Parameters
%           ----------
%           text : String
%               The text to append.
%
            payload = struct('append_text', text);
            data = self.send('/api/recording', payload);
            resp = data;

        end
        

        function resp = set_start_new_dir(self)
            
%           Set if GUI should start a new directory for the next recording.

            payload = struct('start_new_directory', 'true');
            data = self.send('/api/recording', payload);
            resp = data;
            
        end
        
        function resp = set_file_path(self, node_id, file_path)
            
%           Set the file path.

%           Parameters
%           ----------
%           node_id : Integer
%               The node ID.
%           file_path : String
%               The file path.

            endpoint = strcat('/api/processors/', num2str(node_id), '/config');
            payload = struct('text', strcat("file=", num2str(file_path)));
            data = self.send(endpoint, payload);
            
            resp = data;
            
        end
        
        function resp = set_file_index(self, node_id, file_index)

%           Set the file index.
% 
%           Parameters
%           ----------
%           node_id : Integer
%               The node ID.
%           file_index : Integer
%               The file index.

            endpoint = strcat('/api/processors/', num2str(node_id), '/config');
            payload = struct('text', strcat("index=", num2str(file_index)));
            data = self.send(endpoint, payload);
            
            resp = data;

        end
        
        function resp = set_record_engine(self, node_id, engine)

%           Set the record engine for a record node.
%
%           Parameters
%           ----------
%           node_id : Integer
%               The node ID.
%           engine: Integer
%               The record engine index.

            endpoint = strcat('/api/processors/', num2str(node_id), '/config');
            payload = struct('text', strcat("engine=", engine));
            data = self.send(endpoint, payload);
            
            resp = data; 
            
        end
        
        function resp = set_record_path(self, node_id, directory)
            
%           Set the record path for a Record Node
%
%           Parameters
%           ----------
%           node_id: Integer
%               The node ID.
%           directory : String
%               The record path.

            endpoint = strcat('/api/recording/', num2str(node_id));
            payload = struct('parent_directory', directory);
            data = self.send(endpoint, payload);
            
            resp = data; 
            
        end
        function resp = status(self)
            
%           Returns the current status of the GUI (IDLE, ACQUIRE, or RECORD)

            data = self.send('/api/status');
            
            resp = data;
            
        end
        
        function resp = acquire(self, varargin)
            
%           Start acquisition.
%
%           Parameters
%           ----------
%           duration : Integer (optional)
%               The acquisition duration in seconds. If given, the 
%               GUI will acquire data for the specified interval 
%               and then stop. 
%               
%               By default, acquisition will continue until it
%               is stopped by another command. 

            payload = struct('mode', 'ACQUIRE');
            data = self.send('/api/status', payload);
            
            if nargin == 2
                payload = struct('mode', 'IDLE');
                pause(varargin{1});
                data = self.send('/api/status', payload);
            end
            
            resp = data;
            
        end
        
        function resp = record(self, varargin)
            
%           Start recording.
%
%           Parameters
%           ----------
%           duration : Integer (optional)
%               The record duration in seconds. If given, the 
%               GUI will record data for the specified interval 
%               and then stop. 
%               
%               By default, recoridng will continue until it
%               is stopped by another command. 

            payload = struct('mode', 'RECORD');
            data = self.send('/api/status', payload);
            
            if nargin == 2
                payload = struct('mode', 'IDLE');
                pause(varargin{1});
                data = self.send('/api/status', payload);
            end
            
            resp = data;
            
        end
        
        function resp = idle(self, varargin)
            
%           Start recording.
%
%           Parameters
%           ----------
%           duration : Integer (optional)
%               The idle duration in seconds. If given, the 
%               GUI will idle for the specified interval 
%               and then return to its previous state. 
%               
%               By default, this command will stop
%               acquisition/recording and return immediately.

            mode = self.status().mode;

            payload = struct('mode', 'IDLE');
            data = self.send('/api/status', payload);
            
            if nargin == 2
                payload = struct('mode', mode);
                pause(varargin{1});
                data = self.send('/api/status', payload);
            end

            resp = data;
            
        end
        
        function resp = message(self, message)
            
%           Broadcast a message to all processors during acquisition
%
%           Parameters
%           ----------
%           message : String 
%               The message to send.

            payload = struct('text', message);
            data = self.send('/api/message', payload);
            
            resp = data;
            
        end
        
        function resp = quit(self)

%           Quit the GUI

            payload = struct('command', 'quit');
            data = self.send('/api/window', payload);
            
            resp = data;
        end
        
    end
    
end