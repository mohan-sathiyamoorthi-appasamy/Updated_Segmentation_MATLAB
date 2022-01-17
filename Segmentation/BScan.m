%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%  BScan.m
%
%  Bscan class
%
%  Represents a single OCT Bscan
%
%--------------------------------------------------------------------------
%
%  Author:          Stephanie Chiu (stephanie.chiu@duke.edu)
%  Organization:    Duke University
%  Date:            2009.12.09
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

classdef BScan < handle
    
    %**********************************************************************
    %  Properties
    %**********************************************************************
    
    properties
        FilePath = '';
        FileDirectory = '';
        FileName = '';
        FileExtension = '';
        Image = [];
        Width = 0;
        Height = 0;
        Number = 0;
        Layers = [];
        ClosedContourImage = [];
        CorrectedClosedContourImage = [];
        ManualClosedContourImage = [];
        SegmentationTime = 0;
        SegmentationParams = [];
        AddedLayers = [];
        CorrectedLayers = [];
        ManualLayers = [];
        SoftwareVersion = '19.7';
        DicomInfo = [];
        Fovea = [];
        Comments = [];
        Foci1 = [];
        Foci2 = [];
    end
    
    %**********************************************************************
    %  Methods
    %**********************************************************************
    
    methods
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %  BScan() Constructor
        %
        %  Creates an instance of the BScan class
        %
        %------------------------------------------------------------------
        %
        %  function bScan = BScan(filepath, scanNumber)
        %
        %  INPUT PARAMETERS:
        %
        %       filepath - (Optional) File path of the image to load. An
        %                  empty filepath returns an empty object.
        %                  [Default = empty]
        %
        %       scanNumber - (Optional) The scan number associated with
        %                    this image, useful when keeping track of a
        %                    stack of images
        %
        %  RETURN VARIABLES:
        %
        %       bScan - Instance of the BScan class
        %
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        function bScan = BScan(filepath, scanNumber)
           
            %--------------------------------------------------------------
            %  Return an empty BScan object
            %--------------------------------------------------------------
            
            if nargin < 1 || isempty(filepath)
                return;
            end
            
            %--------------------------------------------------------------
            %  Initialize missing parameters
            %--------------------------------------------------------------
            
            if nargin < 2
                scanNumber = 0;
            end
            
            %--------------------------------------------------------------
            %  Validate input parameters
            %--------------------------------------------------------------
                        
            if ~exist(filepath,'file')
                error('''filepath'' does not exist: %s', file);
            end
            
            
            %--------------------------------------------------------------
            %  Load the image
            %--------------------------------------------------------------
            
            [fileDirectory,fileName,fileExtension] = fileparts(filepath);
            
            %
            %  Load a dicon image        
            %
            if strcmpi('.dcm', fileExtension)
                image = dicomread(filepath);
                
                % Rotate dicome images
                image = imrotate(image,-90);
           
                % Keep track of dicom metadata
                bScan.DicomInfo = dicominfo(filepath);
                
            %
            %  Load all other image types
            %
            else
                image = imread(filepath);
            end
            
            %--------------------------------------------------------------
            %  Process the image
            %--------------------------------------------------------------
                        
            %
            %  Convert the image to a 2-D, grayscale, normalized image
            %
            nDimensions = size(image,3);
            if nDimensions == 2
                image = image(:,:,1);
            elseif nDimensions >= 3
                image = image(:,:,1:3);
                image = rgb2gray(image);
            end
            image = uint8(normalizeValues(image,0,255));
            
            %--------------------------------------------------------------
            %  Pediatric image special case
            %--------------------------------------------------------------

            [dirPsth,dirName] = fileparts(fileDirectory);
            dirName = lower(dirName);            
            imageHeight = size(image,1);
            
            if ~isempty(strfind(dirName,'_hh1'));
                halfHeight = round(imageHeight/2);
                image = image(1:halfHeight,:);
            end
            

            %--------------------------------------------------------------
            %  Set BScan properties
            %--------------------------------------------------------------
            
            defaultBScan = BScan();
            bScan.SoftwareVersion = defaultBScan.SoftwareVersion;
            bScan.FilePath = filepath;
            bScan.Number = scanNumber;
            bScan.Image = uint8(image);
            bScan.FileDirectory = fileDirectory;
            bScan.FileName = fileName;
            bScan.FileExtension = fileExtension;
            [bScan.Height, bScan.Width] = size(bScan.Image);
        end
        
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %  segmentImage() Method
        %
        %  Segments the image, populating the bScan.Layers property upon
        %  completion
        %
        %------------------------------------------------------------------
        %
        %  function segmentImage(bScan, params)
        %
        %  INPUT PARAMETERS:
        %
        %       params - SegmentImageParameters object containing all of
        %                the constants used in this function.
        %
        %           Example: To run the normal algorithm, call
        %                    params = normal_getParameters();
        %
        %  RETURN VARIABLES:
        %
        %       bScan - Instance of the BScan class
        %
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        function error = segmentImage(bScan, params)
            
            
            %--------------------------------------------------------------
            %  Do not segment the image if it is empty
            %--------------------------------------------------------------
            
            if isempty(bScan.Image)
                return;
            end
            
            
            %--------------------------------------------------------------
            %  Segment the image
            %--------------------------------------------------------------
            
            bScan.Layers = [];
            bScan.CorrectedLayers = [];
            bScan.AddedLayers = [];
            
            % Invert the image if specified
            image = bScan.Image;
            if params.INVERT_IMAGE
                image = flipud(image);
            end
            
            %
            %  Run the appropriate algorithm and keep track of the
            %  segmentation time
            %
            try
                tic            
                layers = eval(sprintf('%s_segmentImage(%s,%s);', ...
                    lower(params.ALGORITHM_TYPE), ...
                    'image', ...
                    'params'));
                time = toc;
                error = 0;
            catch exception
                error = exception;
                layers = NaN(params.graphCutParams.NUM_LAYERS,bScan.Width);
                time = [];
            end
            
            % Uninvert the image if specified
            if params.INVERT_IMAGE
                layers = bScan.Height - layers;
            end
            
            %
            %  Take care of special case segmentation
            %
            if iscell(layers)      
                bScan.ClosedContourImage = layers{2};
                layers = layers{1};
            else
                bScan.ClosedContourImage = [];
            end
            
            %
            %  Set BScan properties
            %
            bScan.Layers = layers;
            bScan.SegmentationTime = time;
            bScan.SegmentationParams = params;
        end
        
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %  getLayers() Method
        %
        %  Gets the segmented layers
        %
        %------------------------------------------------------------------
        %
        %  function layers = getLayers(bScan, layerType, layerIndices)
        %
        %  INPUT PARAMETERS:
        %
        %       layerType - (Optional) The layer type to get [Default = 0]
        %
        %           [-1] No segmented layers
        %       	[ 0] Automatically segmented layers
        %           [ 1] Corrected automatic layers
        %           [ 2] Manually segmented layers
        %
        %       layerIndices - (Optional) The indices of the layers to get
        %                      [Default = empty (to get all layers)]
        %
        %  RETURN VARIABLES:
        %
        %       layers - matrix of dimension [nLayers x imageWidth]
        %                containing the y-coordinates of the layers
        %
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        function layers = getLayers(bScan, layerType, layerIndices)
            
            %--------------------------------------------------------------
            % Initialize missing parameters
            %--------------------------------------------------------------
            
            if nargin < 2
                layerType = 0;
            end
            if nargin < 3
                layerIndices = [];
            end
                  
            %--------------------------------------------------------------  
            % Get layers
            %--------------------------------------------------------------
            
            switch layerType
                
                case -1
                    layers = [];
                
                % Get automatically segmented layers
                case 0
                    layers = bScan.Layers;
                    
                % Get manually corrected layers    
                case 1
                    if ~isempty(bScan.CorrectedLayers)
                        layers = bScan.CorrectedLayers;
                    else
                        layers = bScan.Layers;
                    end
                    
                % Get manually segmented layers
                case 2
                    layers = bScan.ManualLayers;
            end
            
            nLayers = size(layers,1);
            if ~isempty(layerIndices)
                layerIndices(layerIndices < 1) = [];
                layerIndices(layerIndices > nLayers) = [];
                layers = layers(layerIndices,:);
            end
        end
        
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %  getClosedContourImage() Method
        %
        %  Gets the closed contour image
        %
        %------------------------------------------------------------------
        %
        %  function closedContourImage = getClosedContourImage( ...
        %       bScan, closedContourType, boundaryType)
        %
        %  INPUT PARAMETERS:
        %
        %       closedContourType - (Optional) The closed conour type to 
        %                           get [Default = 0]
        %
        %           [-1] No segmented closed contour image
        %       	[ 0] Automatically segmented closed contour image
        %           [ 1] Corrected automatic closed contour image
        %           [ 2] Manually segmented closed contour image
        %
        %       boundaryType - (Optional) The type of boundary to get
        %                      [Default = 0]
        %
        %           [0] Filled in closed contour structures
        %           [1] Edges of the closed contour structures
        %
        %  RETURN VARIABLES:
        %
        %       closedContourImage - matrix of dimension [imageHeight x 
        %                            imageWidth] containing the closed
        %                            contour structures
        %
        %           If boundaryType = 0, a label image is returned with 
        %           different integer values for each closed contour
        %           structure
        %
        %           If boundaryType = 1, a logical matrix is returned with
        %           ones at the edges of the closed contour structures
        %
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        function closedContourImage = getClosedContourImage( ...
            bScan, closedContourType, boundaryType)
            
            %--------------------------------------------------------------
            % Initialize missing parameters
            %--------------------------------------------------------------
            
            if nargin < 2
                closedContourType = 0;
            end
            if nargin < 3
                boundaryType = 0;
            end
                  
            %--------------------------------------------------------------  
            % Get closed contour image
            %--------------------------------------------------------------
            
            switch closedContourType
                
                case -1
                    closedContourImage = [];
                
                % Get automatically segmented layers
                case 0
                    closedContourImage = bScan.ClosedContourImage;
                    
                % Get manually corrected layers    
                case 1
                    if ~isempty(bScan.CorrectedClosedContourImage)
                        closedContourImage = bScan.CorrectedClosedContourImage;
                    else
                        closedContourImage = bScan.ClosedContourImage;
                    end
                    
                % Get manually segmented layers
                case 2
                    closedContourImage = bScan.ManualClosedContourImage;
            end
                  
            %--------------------------------------------------------------  
            % Process the image to match the specified boundary type
            %--------------------------------------------------------------
            
            if boundaryType == 1 && ~isempty(closedContourImage)
                
                % Get the boundary edges for RPE cells
                if strcmpi(bScan.SegmentationParams.ALGORITHM_TYPE,'rpe_cells')
                    closedContourImage = ~logical(closedContourImage);
                    
                % Get the boundary edges for all other closed structures
                else
                    closedContourImage = edge(closedContourImage,'sobel',0.1); 
                end
            end
        end
        
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %  getSegmentedImage() Method
        %
        %  Gets the image showing the segmented layers
        %
        %------------------------------------------------------------------
        %
        %  function image = getSegmentedImage(bScan, layerType, ...
        %       closedContourType, boundaryType, imageType, ...
        %       lineThickness, layerIndices)
        %
        %  INPUT PARAMETERS:
        %
        %       layerType - (Optional) The layer type to get [Default = 0]
        %
        %           [-1] No segmented layers
        %       	[ 0] Automatically segmented layers
        %           [ 1] Corrected automatic layers
        %           [ 2] Manually segmented layers
        %
        %       closedContourType - (Optional) The layer type to get 
        %                           [Default = 0]
        %
        %           [-1] No segmented closed contours
        %       	[ 0] Automatically segmented closed contours
        %           [ 1] Corrected automatic closed contours
        %           [ 2] Manually segmented closed contours
        %
        %       boundaryType - (Optional) The type of closed contour 
        %                      boundary to get [Default = 0]
        %
        %           [0] Filled in closed contour structures
        %           [1] Edges of the closed contour structures
        %           [2] Filled in closed contour structures filled in with
        %               different colors
        %
        %       imageType - (Optional) The background image to get
        %                   [Default = 1]
        %
        %           [ 0] No background image
        %           [ 1] Raw background image
        %
        %       lineThickness - (Optional) Thickness of the line in pixels
        %                       [Default = 1]
        %
        %       layerIndices - (Optional) The indices of the layers to get
        %                      [Default = empty (to get all layers)]
        %
        %  RETURN VARIABLES:
        %
        %       image - RGB image of size [imageHeight x imageWidth x 3]
        %               with the segmented layers overlaid
        %
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        function image = getSegmentedImage( ...
            bScan, ...
            layerType, ...
            closedContourType, ...
            boundaryType, ...
            imageType, ...
            lineThickness, ...
            layerIndices)
            
            %--------------------------------------------------------------
            % Initialize missing parameters
            %--------------------------------------------------------------
            
            if nargin < 2 || isempty(layerType)
                layerType = 0;
            end            
            if nargin < 3 || isempty(closedContourType)
                closedContourType = 0;
            end
            if nargin < 4 || isempty(boundaryType)
                boundaryType = 0;
            end            
            if nargin < 5 || isempty(imageType)
                imageType = 1;
            end            
            if nargin < 6 || isempty(lineThickness)
                lineThickness = 1;
            end    
            if nargin < 7
                layerIndices = [];
            end

                    
            %--------------------------------------------------------------
            % Validate input parameters
            %--------------------------------------------------------------
            
            if isempty(bScan.Image)
                return;
            end
                    
            %--------------------------------------------------------------
            % Get the segmented image
            %--------------------------------------------------------------           
            
            % Generate the raw image in RGB format
            switch imageType
                case 0
                    image = NaN(bScan.Height,bScan.Width,3);
                case 1
                    image = cat(3, bScan.Image, bScan.Image, bScan.Image);
            end
            imageSize = size(image);
                    
            %--------------------------------------------------------------
            % Get the boundaries
            %-------------------------------------------------------------- 
            
            % Get the layers
            layers = bScan.getLayers(layerType, layerIndices);
            
            % Get the closed contour image
            closedContourImage = bScan.getClosedContourImage(closedContourType, boundaryType);
                
            % Make edges thicker
            if ~isempty(closedContourImage) && boundaryType == 1 && lineThickness > 1
                closedContourImage = imdilate(closedContourImage, strel('disk',lineThickness-1));
            end      

            %--------------------------------------------------------------
            % Add the boundaries to the image
            %-------------------------------------------------------------- 
            
            % Add the layers to the image
            if ~isempty(layers)
                layers = round(layers);

                % Make sure all coordinates are in bounds
                layers(layers < 1) = NaN;
                layers(layers > bScan.Height) = NaN;

                % Mark each layer on the image with a different color
                for iLayer = 1:size(layers,1)

                    layer = layers(iLayer,:);

                    % Expand the indices to match the thickness specified
                    bottomThickness = floor((lineThickness - 1) / 2);
                    topThickness = lineThickness - bottomThickness - 1;

                    bottomLayer = repmat(layer, bottomThickness, 1);
                    bottomLayer = bottomLayer + repmat((1:bottomThickness)', 1, bScan.Width);

                    topLayer = repmat(layer, topThickness, 1);
                    topLayer = topLayer - repmat((1:topThickness)', 1, bScan.Width);

                    % Get the indices of the layer for each color channel
                    xCoord = repmat(1:bScan.Width, lineThickness, 1);
                    yCoord = [topLayer;layer;bottomLayer];

                    % Remove any invalid indices
                    invalidIndices = find(isnan(yCoord(:)) | yCoord(:) < 1 | yCoord(:) > bScan.Height);
                    xCoord(invalidIndices) = [];
                    yCoord(invalidIndices) = [];

                    zCoord_red = ones(size(xCoord));
                    zCoord_green = 2*zCoord_red;
                    zCoord_blue = 3*zCoord_red;

                    redIndices = sub2ind(imageSize, yCoord, xCoord, zCoord_red);
                    greenIndices = sub2ind(imageSize, yCoord, xCoord, zCoord_green);
                    blueIndices = sub2ind(imageSize, yCoord, xCoord, zCoord_blue);

                    % Add the layer to the rgbImage using the appropriate color
                    layerNumber = mod(iLayer,5);

                    switch (layerNumber)
                        case {1}    % blue
                            redColorValue = 0;
                            greenColorValue = 0;
                            blueColorValue = 255;
                        case {2}    % magenta
                            redColorValue = 255;
                            greenColorValue = 0;
                            blueColorValue = 255;
                        case {3}    % cyan
                            redColorValue = 0;
                            greenColorValue = 255;
                            blueColorValue = 255;
                        case {4}    % yellow
                            redColorValue = 255;
                            greenColorValue = 255;
                            blueColorValue = 0;
                        case {0}    % green
                            redColorValue = 0;
                            greenColorValue = 255;
                            blueColorValue = 0;
                    end

                    image(redIndices) = redColorValue;
                    image(greenIndices) = greenColorValue;
                    image(blueIndices) = blueColorValue;
                end
            end
            
            % Add the closed contours to the image
            if ~isempty(closedContourImage)
                
                if boundaryType == 2
                    clusters = bwconncomp(logical(closedContourImage));
                    labels = labelmatrix(clusters);
                    closedContourImage = label2rgb(labels);
                    whiteIndices = sum(closedContourImage,3) == 255*3;
                    whiteIndices = cat(3,whiteIndices,whiteIndices,whiteIndices);
                    closedContourImage(whiteIndices) = 0;
                    image(~whiteIndices) = 0;
                    image = uint8(image) + uint8(closedContourImage);
                else
                    [yCoord, xCoord] = find(closedContourImage);
                    zCoord_red = ones(size(xCoord));
                    zCoord_green = 2*zCoord_red;
                    zCoord_blue = 3*zCoord_red;

                    redIndices = sub2ind(imageSize, yCoord, xCoord, zCoord_red);
                    greenIndices = sub2ind(imageSize, yCoord, xCoord, zCoord_green);
                    blueIndices = sub2ind(imageSize, yCoord, xCoord, zCoord_blue);

                    image(redIndices) = 255;
                    image(greenIndices) = 0;
                    image(blueIndices) = 255;
                end
            end
            
            image = uint8(image);
        end
        
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %  saveSegmentedImage() Method
        %
        %  Saves an RGB image showing segmented layers at the specified
        %  filepath
        %
        %------------------------------------------------------------------
        %
        %  function saveSegmentedImage(bScan, filepath, layerType, ...
        %       closedContourType, boundaryType, imageType, lineThickness, ...
        %       layerIndices)
        %
        %  INPUT PARAMETERS:
        %
        %       filepath - (Optional) Full file path indicating the 
        %                  filename to save the image as. [Default = 
        %                  current directory with original image name]
        %
        %       layerType - (Optional) The layer type to get [Default = 0]
        %
        %           [-1] No segmented layers
        %       	[ 0] Automatically segmented layers
        %           [ 1] Corrected automatic layers
        %           [ 2] Manually segmented layers
        %
        %       closedContourType - (Optional) The layer type to get 
        %                           [Default = 0]
        %
        %           [-1] No segmented closed contours
        %       	[ 0] Automatically segmented closed contours
        %           [ 1] Corrected automatic closed contours
        %           [ 2] Manually segmented closed contours
        %
        %       boundaryType - (Optional) The type of closed contour 
        %                      boundary to get [Default = 0]
        %
        %           [0] Filled in closed contour structures
        %           [1] Edges of the closed contour structures
        %           [2] Filled in closed contour structures filled in with
        %               different colors
        %
        %       imageType - (Optional) The background image to get
        %                   [Default = 1]
        %
        %           [ 0] No background image
        %           [ 1] Raw background image
        %
        %       lineThickness - (Optional) Thickness of the line in pixels
        %                       [Default = 1]
        %
        %       layerIndices - (Optional) The indices of the layers to get
        %                      [Default = empty (to get all layers)]
        %
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        function saveSegmentedImage(bScan, filepath, layerType, ...
                closedContourType, boundaryType, imageType, lineThickness, ...
                layerIndices)
            
            %--------------------------------------------------------------
            % Initialize missing parameters
            %--------------------------------------------------------------
            
            if nargin < 2
                filepath = [];
            end
            if nargin < 3
                layerType = [];
            end
            if nargin < 4
                closedContourType = [];
            end
            if nargin < 5
                boundaryType = [];
            end
            if nargin < 6
                imageType = [];
            end
            if nargin < 7
                lineThickness = [];
            end
            if nargin < 8
                layerIndices = [];
            end

            
            %--------------------------------------------------------------
            % Validate input parameters
            %--------------------------------------------------------------
            
            if isempty(bScan.Image)
                return;
            end
            
            % Create the filepath if it does not exist
            if isempty(filepath)           	
                filepath = strcat(bScan.FileName, bScan.FileExtension); 
                
            % Create the directory path if it does not exist
            else
                [path,name,extension] = fileparts(filepath);                
                if ~isdir(path)
                    mkdir(path)
                end
                if isempty(extension)
                    filepath = strcat(filepath,'.tif');
                end
            end
            
            %--------------------------------------------------------------
            % Get and save the segmented image
            %--------------------------------------------------------------
            
            image = bScan.getSegmentedImage( ...
                layerType, ...
                closedContourType, ...
                boundaryType, ...
                imageType, ...
                lineThickness, ...
                layerIndices);
            
            imwrite(image,filepath);
        end
        
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %  saveBscan() Method
        %
        %  Saves the bscan in '.mat' file
        %
        %------------------------------------------------------------------
        %
        %  function saveBscan(bScan, filepath)
        %
        %  INPUT PARAMETERS:
        %
        %       filepath - (Optional) Full file path indicating the 
        %                  filename to save the image as. [Default = 
        %                  current directory with original image name]
        %
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        function saveBscan(bScan, filepath)
            
            %--------------------------------------------------------------
            % Initialize missing parameters
            %--------------------------------------------------------------
            
            if nargin < 2
                filepath = '';
            end
            
            %--------------------------------------------------------------
            % Create filepath if it does not exist
            %--------------------------------------------------------------
            
            if isempty(filepath)           	
                filepath = strcat(bScan.FileName, '.mat'); 
            end
            
            %--------------------------------------------------------------
            % Save the BScan
            %--------------------------------------------------------------
            
            save(filepath, 'bScan');
        end
        
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %  setCorrectedLayers() Method
        %
        %  This function is used in the GUI to update layers which have
        %  been corrected or added.  Updates the AddedLayers and 
        %  CorrectedLayers properties
        %
        %------------------------------------------------------------------
        %
        %  function setCorrectedLayers(bScan, correctedLayers, addedLayer)
        %
        %  INPUT PARAMETERS:
        %
        %       correctedLayers - A nLayers x imageWidth matrix where each
        %                         row contains the corrected y positions of
        %                         each layer. nLayers must be at least the
        %                         original number of layers, but new rows
        %                         may be added to this matrix
        %
        %       addedLayers - The row indices containing newly added layers
        %
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        function setCorrectedLayers(bScan, correctedLayers, addedLayer)
             
            %--------------------------------------------------------------
            % Verify input parameters
            %--------------------------------------------------------------
            
            % Verify the number of corrected layers contains at least the
            % original number of layers
            nLayers = size(correctedLayers, 1);
            if nLayers < size(bScan.Layers, 1)
                error('There must be at least %d layers', size(bScan.Layers,1));
            end
            
            if size(correctedLayers, 2) ~= size(bScan.Layers, 2)
                error('Each layer must be %d pixels long', size(bScan.Layers,2));
            end
            
            % Verify the number of layers added
            nLayerDifference = nLayers - ...
                ( size(bScan.Layers, 1) + length(bScan.AddedLayers) );

             
            %--------------------------------------------------------------
            % Update the CorrectedLayers and AddedLayers properties
            %--------------------------------------------------------------
            
            if nLayerDifference
                if nLayerDifference ~= 1
                    error('Length of addedLayers is invalid');
                end
                
                alreadyAddedLayers = bScan.AddedLayers;
                layersToIncrement = alreadyAddedLayers >= addedLayer;
                alreadyAddedLayers(layersToIncrement) = alreadyAddedLayers(layersToIncrement) + 1;
                bScan.AddedLayers = sort([alreadyAddedLayers, addedLayer]);
                
                % Make sure the layers do not cross
                invalidIndices = find( ...
                    (correctedLayers(addedLayer,:) - ...
                     correctedLayers(max(1,addedLayer-1),:)) < 0);
                             
                correctedLayers(addedLayer, invalidIndices) = ...
                    correctedLayers(max(1,addedLayer-1),invalidIndices); 
                
                invalidIndices = find( ...
                    (correctedLayers(min(nLayers, addedLayer+1),:) - ...
                     correctedLayers(addedLayer,:)) < 0);
                             
                correctedLayers(addedLayer, invalidIndices) = ...
                    correctedLayers(min(nLayers, addedLayer+1),invalidIndices);        
            end
           
            bScan.CorrectedLayers = correctedLayers;
        end
        
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %  setFovea() Method
        %
        %  This function is used in the GUI to update the fovea 
        %  coordinates.  Updates the Fovea property
        %
        %------------------------------------------------------------------
        %
        %  function setFovea(bScan, foveaCoordinates)
        %
        %  INPUT PARAMETERS:
        %
        %       foveaCoordinates - A vector of length 2 containing the row 
        %                          and column coordinates of the fovea on 
        %                          the bScan.
        %
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        function setFovea(bScan, foveaCoordinates)
            
            %--------------------------------------------------------------
            % Verify input parameters
            %--------------------------------------------------------------
            
            if length(foveaCoordinates) ~= 2
                error('foveaCoordinates must be a vector with length 2');
            end            
            if sum(foveaCoordinates < 1)
                error('foveaCoordinates cannot be less than 1');
            end
            if foveaCoordinates(1) > bScan.Height
                error('fovea row coordinate is out of range');
            end
            if foveaCoordinates(2) > bScan.Width
                error('fovea column coordinate is out of range');
            end
            
            %--------------------------------------------------------------
            % Set the fovea
            %--------------------------------------------------------------
            
            bScan.Fovea = [foveaCoordinates(1), foveaCoordinates(2)];
        end
    end
end