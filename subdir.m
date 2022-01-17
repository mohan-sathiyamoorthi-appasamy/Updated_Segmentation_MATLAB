%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%  subdir.m
%
%  Obtains a list of all subdirectories, including the current directory
%
%--------------------------------------------------------------------------
%
%  function [subDirectories, levels] = subdir( ...
%      directory, folderLevel, currentLevel)
%
%  INPUT PARAMETERS:
%
%       directory - A string containing the path of the main directory
%
%       folderLevel - (Optional) Specifies which subfolder level to
%                     retreive
%
%           Example: 
%               'C:\MyDocuments' 
%                   'C:\MyDocuments\Folder1'
%                       'C:\MyDocuments\Folder1\A'
%                       'C:\MyDocuments\Folder1\B'
%                   'C:\MyDocuments\Folder2'
%                       'C:\MyDocuments\Folder2\C'
%                       'C:\MyDocuments\Folder2\D'
%
%               For directory = 'C:\MyDocuments',
%
%                   [ ]:  retreives all subfolders
%                   [0]:  retrieves 'MyDocuments'
%                   [1]:  retrieves 'Folder1' and 'Folder2'
%                   [2]:  retrieves 'A', 'B', 'C', and 'D'
%
%       currentLevel - (Omit) This is an internal variable.
%
%  RETURN VARIABLES:
%
%       subDirectories - A cell array containing the full filepaths to all 
%                        subdirectories within the specified directory, or
%                        a subset of the subdirectories if a folderLevel
%                        was specified
%
%       levels - An array of same length as subDirectories with a number
%                corresponding to 
%
%--------------------------------------------------------------------------
%
%  Author:          Stephanie Chiu   
%  Institution:     Duke University
%  Date Created:    2010.01.28
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [subDirectories, levels] = subdir( ...
    directory, folderLevel, currentLevel)

    %----------------------------------------------------------------------
    %  Initialize missing input parameters
    %----------------------------------------------------------------------

    if nargin < 2
        folderLevel = [];
    end
    if nargin < 3
        currentLevel = 0;
    end
    
    %----------------------------------------------------------------------
    %  Validate input parameters
    %----------------------------------------------------------------------
    
    if isempty(directory) || ~exist(directory, 'dir')
        subDirectories = [];
        return;
    end
    if folderLevel < 0
        error('Folder level cannot be negative');
    end
    
    %----------------------------------------------------------------------
    %  Get Folder Level 0
    %----------------------------------------------------------------------
    
    if folderLevel == 0
        subDirectories = {directory};
        levels = 0;
        return;
    end
    
    %----------------------------------------------------------------------
    %  Get Folder Level 1
    %----------------------------------------------------------------------
    
    currentLevel = currentLevel + 1;
    
    % Get subdirectories
    subDirectories = dir(directory);
    subDirectories = {subDirectories([subDirectories.isdir]).name}';
    nSubDirectories = size(subDirectories,1);
    
    % Remove invalid subdirectories
    invalidDirectories = false(nSubDirectories,1);
    for iDir = 1:nSubDirectories
        subDir = subDirectories{iDir};
        if isempty(subDir) || strcmpi('.',subDir) || strcmpi('..',subDir)
            invalidDirectories(iDir) = true;
        else
            subDirectories{iDir} = fullfile(directory, subDir);
        end
    end
    subDirectories(invalidDirectories) = [];
    nSubDirectories = size(subDirectories,1);
    levels = repmat(currentLevel,nSubDirectories,1);
    
    %----------------------------------------------------------------------
    %  Get Folder Levels 2 and above using recursion
    %----------------------------------------------------------------------
    
    if isempty(folderLevel) || currentLevel < folderLevel
        for iDir = 1:nSubDirectories
            [newDirectories,newLevels] = subdir(subDirectories{iDir},folderLevel,currentLevel);
            subDirectories = [subDirectories; newDirectories];
            levels = [levels; newLevels];
        end
    end
    
    %----------------------------------------------------------------------
    %  Final processing of subfolders in the last iteration
    %----------------------------------------------------------------------
    
    if currentLevel == 1
        
        % Add Folder Level 0
        if isempty(folderLevel)
            subDirectories = [directory; subDirectories];
            levels = [0; levels];
            
        % Get only the specified folder level
        else
            invalidDirectories = (levels ~= folderLevel);
            subDirectories(invalidDirectories) = [];
            levels(invalidDirectories) = [];
        end
    end
end