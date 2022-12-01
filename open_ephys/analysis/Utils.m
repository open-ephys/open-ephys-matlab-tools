classdef Utils
    %UTILS Contains helper functions 
    %   Detailed explanation goes here
    
    properties
    end
    
    methods(Static)
        function singleton = Utils()
        end

        function log(varargin)
            fprintf("[DEBUG] ");
            for i = 1:length(varargin)
                fprintf('%s ', varargin{i});
            end
            fprintf("\n");
        end
        
        function latest_recordings = getLatestRecordings(dataPath, n)
            %getLatestRecording Gets the latest recording in the basePath
            %   Returns the path to the latest recording 
            files = dir(dataPath);
            files = files(~cellfun(@(x) strcmp(x(1), '.'), {files.name}));
            if isempty(files)
                error('No files found in the data path');
            end
            [~,idx] = sort([files.datenum]);
            files = files(idx);
            latest_recordings = files(end-n+1:end);
        end
    end
end

