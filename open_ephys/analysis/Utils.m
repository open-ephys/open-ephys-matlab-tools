classdef Utils
    %UTILS Contains helper functions 
    %   Detailed explanation goes here
    
    properties
    end
    
    methods
        function obj = Utils()
        end
        
        function latest_recording = getLatestRecording(~, dataPath)
            %getLatestRecording Gets the latest recording in the basePath
            %   Returns the path to the latest recording 
            files = dir(dataPath);
            files = files(~cellfun(@(x) strcmp(x(1), '.'), {files.name}));
            if isempty(files)
                error('No files found in the data path');
            end
            [~,idx] = sort([files.datenum]);
            files = files(idx);
            latest_recording = files(end);
        end
    end
end

