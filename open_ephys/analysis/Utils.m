classdef Utils
    %UTILS Contains general helper functions as needed
    
    properties
    end
    
    methods(Static)
        function singleton = Utils()
        end

        function log(varargin)

            % fprintf("[open-ephys-matlab-tools] ");
            for i = 1:length(varargin)
                fprintf('%s ', varargin{i});
            end
            fprintf("\n");

        end
        
        function latest_recordings = getLatestRecordings(dataPath, n)

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

