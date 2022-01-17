
%
%  Author:  Ratheesh K Meleppat
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function addSegmentationPath()

    % Get the current directory
    currentDirectory = pwd;
    
    % Get all subdirectories (including the current directory)
    subDirectories = subdir(currentDirectory);

    % Add all subdirectories to the path
    for iDir = 1:length(subDirectories)
        addpath(subDirectories{iDir});
    end
end