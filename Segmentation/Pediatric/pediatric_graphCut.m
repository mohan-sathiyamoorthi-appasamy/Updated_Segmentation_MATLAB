%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%  normal_graphCut.m
%
%  Performs graph cut segmentation on a normal retinal image, for up to
%  eight imageLayers
%
%--------------------------------------------------------------------------
%
%  function layers = normal_graphCut( ...
%      image, ...
%      axialRes, ...
%      lateralRes, ...
%      rpeTop, ...
%      ilm, ...
%      invalidIndices, ...
%      recalculateWeights, ...
%      params)
%
%  INPUT PARAMETERS:
%
%       image - A [imageHeight x imageWidth] image to segment
%
%       axialRes - Axial (vertical) resolution of the image in um/pixel
%
%       lateralRes - Lateral (horizontal) resoution of the image in
%                    um/pixel
%
%       rpeTop - A vector of size (1 x imageWidth) estimating the location
%                of the inner aspect of the RPE, generated by the
%                normal_getBwImage() function
%
%       ilm - A vector of size (1 x imageWidth) estimating the 
%                   location of inner limiting membrane
%
%       invalidIndices - A vector of image indices that should be ignored
%                        and not considered during graph cut
%
%       recalculateWeights - (Optional) true to recalculate,false otherwise.
%                            the weighting matrix takes several seconds to
%                            be created. Performance can be increased by
%                            avoiding recalculation. Note that weights only 
%                            need to be recalculated when the image 
%                            changes.  If you call graphCut on the same 
%                            image multiple times, the latter calls can be
%                            set to 'false'.  [Default = true]
%
%       params - (Optional) GraphCutParameters object containing all of the
%                constants used in this function.  Default values are set
%                in the normal_getParameters() function
%
%  RETURN VARIABLES:
%
%       layers - A [nLayers x imageWidth] matrix where each column contains
%                the y-coordinates of a layer
%
%--------------------------------------------------------------------------
%
%  Author:          Stephanie Chiu   
%  Institution:     Duke University     
%  Date Created:    2009.12.19
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function layers = pediatric_graphCut( ...
    image, ...
    axialRes, ...
    lateralRes, ...
    rpeTop, ...
    ilm, ...
    invalidIndices, ...
    recalculateWeights, ...
    params)
    
    
    %----------------------------------------------------------------------
    %  Persistent variables
    %----------------------------------------------------------------------
    
    persistent weightingMatrices;
    
    
    %----------------------------------------------------------------------
    %  Initialize missing parameters
    %----------------------------------------------------------------------
    
    if nargin < 4
        rpeTop = [];
    end    
    if nargin < 5
        ilm = [];
    end    
    if nargin < 6
        invalidIndices = [];
    end
    if nargin < 7
        recalculateWeights = 1;
    end
    if nargin < 8
        params = [];
    end
    
    
    %----------------------------------------------------------------------
    %  Validate input parameters
    %----------------------------------------------------------------------
    
    if isempty(params)
        params = pediatric_getParameters();
        params = params.graphCutParams;
    end
    
    numLayers = params.NUM_LAYERS;
    
    if numLayers < 1
        error('Number of layers must be greater than zero');
    end
    
    if params.MAX_NUM_LAYERS < numLayers
        error('Max number of layers cannot be less than the number of layers');
    end
    if numLayers < 1 || numLayers > params.MAX_NUM_LAYERS
        error('Layer indices must be greater than zero');
    end
    
    if isempty(image)
        error('Image cannot be empty');
    end

    
    %----------------------------------------------------------------------
    %  Normalize image
    %----------------------------------------------------------------------

    image = double(image);
    image = normalizeValues(image);  
    imageHeight = size(image,1);
    

    %------------------------------------------------------------------
    %  Add a column to each side of the images.  These are used to
    %  initialize the graph cut starting points
    %------------------------------------------------------------------

    image = addColumns(image, 1);

    if ~isempty(rpeTop)
        rpeTop = addColumns(rpeTop, 1);
    end

    if ~isempty(ilm)
        ilm = addColumns(ilm, 1);
    end

    if ~isempty(invalidIndices)
        invalidIndices = invalidIndices + imageHeight;
    end
    
    
    %------------------------------------------------------------------
    %  Determine which layers to segment
    %------------------------------------------------------------------

    layerIndices = params.LAYER_INDICES;
    matrixIndices = params.MATRIX_INDICES;
    maxIndex = 0;
    uniqueLayerIndices = [];
    for index = 1:length(layerIndices)
        if ~sum(uniqueLayerIndices == layerIndices(index))
            uniqueLayerIndices = [uniqueLayerIndices, layerIndices(index)];
        end
    end
    for index = 1:numLayers
        lastIndex = find(layerIndices == uniqueLayerIndices(index),1,'last');
        if ~isempty(lastIndex) && lastIndex > maxIndex
            maxIndex = lastIndex;
        end
    end
    if maxIndex > 0
        layerIndices = layerIndices(1:maxIndex);
        if ~isempty(matrixIndices)
            matrixIndices = matrixIndices(1:maxIndex);
        end
    end
    
    
    %------------------------------------------------------------------
    %  Generate a weighting matrix for the image
    %------------------------------------------------------------------

    if recalculateWeights
        weightingMatrices = pediatric_weightingMatrix( ...
            image, ...
            axialRes, ...
            lateralRes, ...
            matrixIndices, ...
            params.weightingMatrixParams);
    end
      
    
    %----------------------------------------------------------------------
    %  Segment each layer one at a time
    %----------------------------------------------------------------------
    
    imageSize = size(image);
    nLayers = max(layerIndices);
    layers = NaN(nLayers, imageSize(2));
    foveaParams = struct('Index', 0, 'Range', 0, 'Percentage', 0);
    
    % Loop through each layer and segment it
    for iLayer = 1:length(layerIndices)
        
        layerIndex = layerIndices(iLayer);
        
        % Get parameters for the current layer to segment
        regionIndices = pediatric_getGraphCutRegion( ...        
            image, ...
            layerIndex, ...
            axialRes, ...
            rpeTop, ...
            foveaParams, ...
            invalidIndices, ...
            layers);
            
        % Assign the appropriate adjacency matrix
        matrixIndex = matrixIndices(iLayer);
        weightMatrix = weightingMatrices{matrixIndex};
        
        % Perform graph cut between each of the points, and combine them
        % together to create a continuous segmented line across the image
        cut = cutRegion(imageSize, regionIndices, weightMatrix);
            
        % Take care of missing IS-OS layer
        if layerIndex == 3 && nLayers >= 5 && ~all(isnan(layers(5,:)))
            replaceIndices = ((layers(4,:) - cut) < round(13/axialRes));
            cut(replaceIndices) = layers(4,replaceIndices);
        end
        
        % See if there is a fovea present
        if layerIndex == 3
            ilm = layers(1,:);
            innerLayer = round(smooth(cut,0.1)');
            rpe = layers(6,:);
            foveaParams = locateFovea(imageSize, axialRes, lateralRes, ...
                ilm, innerLayer, rpe, invalidIndices);   
        end
        
        layers(layerIndex,:) = cut;
    end
	   

    %----------------------------------------------------------------------
    %  Make sure the layers do not cross
    %----------------------------------------------------------------------
    
    for iLayer = 1:nLayers
        if iLayer < nLayers
            topLayer = layers(iLayer, :);
            bottomLayer = layers(iLayer + 1, :);
            crossIndices = find((bottomLayer - topLayer) < 0);

            bottomLayer(crossIndices) = topLayer(crossIndices);
            layers(iLayer + 1,:) = bottomLayer;
        end
    end
    
    
    %----------------------------------------------------------------------
    %  Remove the extra columns  and layers
    %----------------------------------------------------------------------
    
    layers = layers(:,2:end-1);
    
    % Remove extra layers that were not segmented or supposed to be
    % segmented
    layersToRemove = setdiff(1:nLayers,uniqueLayerIndices(1:numLayers));
    layers(layersToRemove,:) = [];
end