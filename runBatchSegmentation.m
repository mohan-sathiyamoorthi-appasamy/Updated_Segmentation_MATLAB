%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%  runBatchSegmentation.m
%
%  This is the M-file for running Duke's Automatic Graph-Cut Ophthalmic
%  Segmentation Software in batch mode. 
%
%  *Note: This script will automatically add the files to the path. Please
%   do NOT save the files to the path. 
%
%--------------------------------------------------------------------------
%
%  function runBatchSegmentation( ...
%      directory, ...
%      fileExtension, ...
%      algorithmType, ...
%      studyType, ...
%      folderLevel, ...
%      folderIndices, ...
%      fileIndices, ...
%      params, ...
%      skipSegmentationFolders)
%
%  INPUT PARAMETERS:
%
%       directory - Topmost directory filepath containing all images to be
%                   segmented in batch mode
%
%       fileExtension - Image type ('.tif' or '.dcm')
%
%       algorithmType - String containing the algorithm type
%
%           'normal'    'drusen'       'pediatric' 
%           'dme'       'rpe_cells'    'photoreceptors'
%
%       studyType - The study name to use for extracting parameters out of
%                   the filename
%
%           'A2A'       - AREDS A2A SDOCT study
%           'Same'      - Same parameters throughout the entire study. If
%                         this is used, change the parameter values in 
%                         "getParameters_Same.m"
%
%       folderLevel - (Optional) Folder level containing the images to be 
%                     segmented. [Default = 1]
%
%           Example: 
%               'C:\MyDocuments' 
%                   'C:\MyDocuments\Folder1'
%                       'C:\MyDocuments\Folder1\A'
%                       'C:\MyDocuments\Folder1\B'
%                       'C:\MyDocuments\Folder1\C'
%                   'C:\MyDocuments\Folder2'
%                       'C:\MyDocuments\Folder2\D'
%
%               For directory = 'C:\MyDocuments',
%
%                   [ ]: segments all images in all subfolders
%                        * Warning! if this is specified, any
%                          already-segmented RGB images will also be
%                          segmented if skipSegmentationFolders = 0.
%
%                   [0]: segments images in the 'MyDocuments' folder
%                   [1]: segments images in 'Folder1' and 'Folder2'
%                   [2]: segments images in folders 'A','B','C', and 'D'
%
%       folderIndices - (Optional) Indices of the folders to segment at a 
%                       specified folder level. Default = [].
%
%           Example: For folderLevel = 2,
%           
%               [ ]:     segments images in 'A','B','C', and 'D'
%               [2]:     segments images in 'B'
%               [1:3]:   segments images in 'A','B', and 'C'
%               [1,2,4]: segments images in 'A','B', and 'D'
%           
%       fileIndices - (Optional)Indices of the files to segment within a
%                     folder. Default = [].
%
%           Example:
%           
%               [ ]:     segments all images in the folder
%               [2]:     segments the second image in the folder
%               [1:3]:   segments the first three images in the flder
%               [1,2,4]: segments images 1, 2, and 4 in the folder
%
%       params - (Optional) Instance of the SegmentImageParameters class
%                Default = the object for the specified algorithmType
%
%       skipSegmentationFolders - (Optional) Determines whether to segment 
%                                 images contained in the segmentation 
%                                 folder. [Default = 1]
%
%           [0]: Images in folders titled 'Segmentation' will be segmented
%
%           [1]: Images in folders titled 'Segmentation' will not be 
%                segmented. This is generally preferred since images in the
%                'Segmentation' folder are RGB images containing the layer
%                markings
%
%--------------------------------------------------------------------------
%
%  Author:          Stephanie Chiu   
%  Institution:     Duke University
%  Date Created:    2010.01.28
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function runBatchSegmentation( ...
    directory, ...
    fileExtension, ...
    algorithmType, ...
    studyType, ...
    folderLevel, ...
    folderIndices, ...
    fileIndices, ...
    params, ...
    skipSegmentationFolders)


    %----------------------------------------------------------------------
    %  Constant variables
    %----------------------------------------------------------------------
    
    SAVE_DIRECTORY_NAME = 'Segmentation';
    FILE_EXTENSION_PATTERN = strcat('*', fileExtension);


    %----------------------------------------------------------------------
    %  Initialize missing input parameters
    %----------------------------------------------------------------------

    if nargin < 5
        folderLevel = 1;
    end
    if nargin < 6
        folderIndices = [];
    end
    if nargin < 7
        fileIndices = [];
    end
    if nargin < 8
        params = [];
    end
    if nargin < 9 || isempty(skipSegmentationFolders)
        skipSegmentationFolders = 1;
    end
    
    %----------------------------------------------------------------------
    %  Validate input parameters
    %----------------------------------------------------------------------
    
    % Validate directory
    if ~exist(directory, 'dir')
        error('Directory does not exist');
    end
    
    % Validate folder indices
    folders = subdir(directory, folderLevel);
    nFolders = length(folders);
    
    if ~isempty(folderIndices)
        folderIndices(folderIndices < 1) = [];
        folderIndices(folderIndices > nFolders) = [];
        folders = folders(folderIndices);
        nFolders = length(folderIndices);
    end
    originalFileIndices = fileIndices;
        
    % Return if there were no folders to segment
    if nFolders == 0
        disp('There were no subfolders to segment');
        return;
    end
    
    origParams = params;
        
    %----------------------------------------------------------------------
    %  Open workers for parallel processing
    %----------------------------------------------------------------------
    
    if matlabpool('size') == 0
        matlabpool open;
    end
    
    
    %----------------------------------------------------------------------
    %  Add the path 
    %----------------------------------------------------------------------
    
    addSegmentationPath();
    
    %----------------------------------------------------------------------
    %  Loop through the specified folders
    %----------------------------------------------------------------------
    
    a=tic;
    for iFolder = 1:nFolders
        folder = folders{iFolder};
        fileIndices = originalFileIndices;

        [path,name,ext] = fileparts(lower(folder));
        if ~isempty(ext)
            name = strcat(name,ext);
        end
        
        % Skip folders titled 'Segmentation'
        if skipSegmentationFolders && strcmpi(SAVE_DIRECTORY_NAME,name)
            continue;
        end            
            
        % Determine which files to segment
        files = dir(fullfile(folder, FILE_EXTENSION_PATTERN));
        files = {files.name};
        nFiles = length(files);
        
        if ~isempty(fileIndices)
            fileIndices(fileIndices < 1) = [];
            fileIndices(fileIndices > nFiles) = [];
            files = files(fileIndices);
        else
            fileIndices = 1:length(files);
        end
        nFiles = length(fileIndices);
        
        % Continue to the next folder if there are no files to segment in
        % the current folder
        if nFiles == 0
            continue;
        end
        
        % Create the directory to save the results in
        saveDirectory = fullfile(folder, SAVE_DIRECTORY_NAME);
        
        if ~exist(saveDirectory, 'dir')
            mkdir(saveDirectory);
        end
    
        %------------------------------------------------------------------
        %  Get the segmentation parameters
        %------------------------------------------------------------------
        
        % Get the paramters based on the algorithm type
        params = origParams;
        if isempty(params)
            eval(sprintf('params = %s_getParameters();',lower(algorithmType)));
        end
        
        % Get the parameters based on the study type
        eval(sprintf('studyParams = getParameters_%s(folder,fileExtension);',lower(studyType)));
        
        if isempty(params.AXIAL_RESOLUTION)
            params.AXIAL_RESOLUTION = studyParams.AXIAL_RESOLUTION;
        end
        
        if isempty(params.LATERAL_RESOLUTION)
            params.LATERAL_RESOLUTION = studyParams.LATERAL_RESOLUTION;
        end        

        %%% Fix this later!!
        params.INVERT_IMAGE = studyParams.INVERT_IMAGE;
        
        if isprop(params,'otherParams')
            if isfield(params.otherParams,'EYE') && isempty(params.otherParams.EYE)
                params.otherParams.EYE = studyParams.EYE;
            end

            if isfield(params.otherParams,'SCAN_ORIENTATION') && isempty(params.otherParams.SCAN_ORIENTATION)
                params.otherParams.SCAN_ORIENTATION = studyParams.SCAN_ORIENTATION;
            end

            if isfield(params.otherParams,'SEGMENT_CYSTS') && isempty(params.otherParams.SEGMENT_CYSTS)
                params.otherParams.SEGMENT_CYSTS = studyParams.SEGMENT_CYSTS;
            end
        end
        
        %------------------------------------------------------------------
        %  Loop through each image in the folder and segment the layers
        %------------------------------------------------------------------
        
        parfor iFile = 1:nFiles
            file = fullfile(folder, files{iFile});
            
            % Determine filenames to save images and data as
            [path, name] = fileparts(file);
            imageFilename = fullfile(saveDirectory, strcat(name, '.tif'));
            bScanFilename = fullfile(saveDirectory, strcat(name, '.mat'));
            
            % Load the bScan object if it already exists
            if exist(bScanFilename,'file')
                bScan = load(bScanFilename);
                bScan = bScan.bScan;
            else
                bScan = BScan(file,fileIndices(iFile));                
            end
            
            % Save the image as a tif if it is a dicom file
            if strcmpi(fileExtension, '.dcm')
                imwrite(uint8(bScan.Image), fullfile(path, strcat(name, '.tif')));
            end

            % Segment the image
            try
                bScan.segmentImage(params);
            catch
                % Do nothing upon failure
            end
            
            % Save the results
            bScan.saveSegmentedImage(imageFilename,0,0,2,1,params.LINE_THICKNESS);
            bScan.saveBscan(bScanFilename);
        end
        disp(folder);
    end
    time = toc(a);
    disp(time);
    matlabpool close;
end