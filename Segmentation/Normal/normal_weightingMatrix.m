%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%  normal_weightingMatrix.m
%
%  Generates the weighting matrices to be used for graph cut
%
%--------------------------------------------------------------------------
%
%  function weightingMatrices = normal_weightingMatrix( ...
%      image, ...
%      axialRes, ...
%      lateralRes, ...
%      matrixIndices, ...
%      invalidIndices, ...
%      params)
%
%  INPUT PARAMETERS:
%
%       image - Image to generate adjacency matrix for
%
%       axialRes - Axial (vertical) resolution of the image in um/pixel
%
%       lateralRes - Lateral (horizontal) resoution of the image in
%                    um/pixel
%
%       matrixIndices - (Optional)Indices of the matrices to generate the 
%                       adjacency matrix for if not all need to be created 
%
%       invalidIndices - A vector of image indices that should be ignored
%                        and not considered during graph cut
%
%       params - (Optional) WeightingMatrixParameters object containing 
%                 all of the constants used in this function.  Default 
%                 values are set by normal_getParameters();
%
%  RETURN VARIABLES:
%
%       weightingMatrices - Array of weighting matrices to be used on
%                           particular layers, as defined by the
%                           WeightingMatrixType class
%
%--------------------------------------------------------------------------
%
%  Author:          Stephanie Chiu
%  Institution:     Duke University
%  Date Created:    2009.05.22
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


function weightingMatrices = normal_weightingMatrix( ...
    image, ...
    axialRes, ...
    lateralRes, ...
    matrixIndices, ...
    invalidIndices, ...
    params)

    %----------------------------------------------------------------------
    %  Initialize missing input parameters
    %----------------------------------------------------------------------
    
    if nargin < 4
        matrixIndices = [];
    end
    
    if nargin < 5
        invalidIndices = [];
    end
    
    if nargin < 6
        params = [];
    end

    %----------------------------------------------------------------------
    %  Validate input parameters
    %----------------------------------------------------------------------
    
    if isempty(matrixIndices)
        params = normal_getParameters();
        params = params.graphCutParams.weightingMatrixParams;
    end
    
    nMatrices = length(params.WEIGHT_RANGES);
    
    if ~isempty(matrixIndices)
        matrixIndices(matrixIndices < 1) = [];
        matrixIndices(matrixIndices > nMatrices) = [];
    end
    if isempty(matrixIndices)
        matrixIndices = 1:nMatrices;
    end   

    imageSize = size(image);
    imageHeight = imageSize(1);
    imageWidth = imageSize(2);
    
   
    %----------------------------------------------------------------------
    %  Separate the vertical weights on the leftmost and rightmost columns
    %  from the rest of the weights in the image
    %----------------------------------------------------------------------
    
    %
    %  Generate edges and points on the image
    %
    edges = createLattice(imageSize);
    
    %
    %  Separate the edges corresponding to the left-most and right-most
    %  columns that were artificially added to the image
    %
    maxIndex = imageHeight*imageWidth;
    leftColIndices = 1:(imageHeight-1);
    rightColIndices = ((imageHeight-1)*(imageWidth-1) + 1) : maxIndex;
    
    columnIndices = [leftColIndices, rightColIndices];
    imageIndices = setdiff(1:size(edges,1), columnIndices);
    
    columnEdges = edges(columnIndices,:);
    imageEdges = edges(imageIndices,:);
    
    
    %----------------------------------------------------------------------
    %  Calculate the weights based on the image gradient.  Lower weights 
    %  are assigned to areas with a higher gradient
    %----------------------------------------------------------------------
    
    %
    %  Filter the image
    %
    xFilterSize = round(params.X_FILTER_SIZE / lateralRes);
    yFilterSize = round(params.Y_FILTER_SIZE / axialRes); 
    filter = fspecial('gaussian',[yFilterSize,xFilterSize],params.SIGMA);   
    smoothImage = blurImage(image,filter);
    filter = fspecial('gaussian',[1,xFilterSize],params.SIGMA);   
    smoothImage2 = blurImage(image,filter);
    
    %
    %  Create two edge maps (one for edges that transition from dark->light
    %  in the vertical direction, and one for edges transitioning from 
    %  light->dark).  
    %
    lightDarkEdgeImage = (blurImage(smoothImage, -params.EDGE_FILTER) > 0) .* ...
                         blurImage(smoothImage, -params.EDGE_FILTER);
                     
    darkLightEdgeImage = (blurImage(smoothImage, params.EDGE_FILTER) > 0) .* ...
                         blurImage(smoothImage, params.EDGE_FILTER);       
    
    lightDarkEdgeImage2 = (blurImage(smoothImage2, -params.EDGE_FILTER) > 0) .* ...
                         blurImage(smoothImage2, -params.EDGE_FILTER);
                     
    darkLightEdgeImage2 = (blurImage(smoothImage2, params.EDGE_FILTER) > 0) .* ...
                         blurImage(smoothImage2, params.EDGE_FILTER);              
    
    % Make it difficult to cross the opposite gradient
    darkLightInd = (darkLightEdgeImage > 0);
    lightDarkInd = (lightDarkEdgeImage > 0);
    darkLightInd2 = (darkLightEdgeImage2 > 0);
    
    darkLightEdgeImage(lightDarkInd) = 0;
    lightDarkEdgeImage(darkLightInd) = 0;
    lightDarkEdgeImage2(darkLightInd2) = 0;
                     
    % Normalize the weights
    lightDarkEdgeImage = normalizeValues(lightDarkEdgeImage,0,1);  
    darkLightEdgeImage = normalizeValues(darkLightEdgeImage,0,1); 
    lightDarkEdgeImage2 = normalizeValues(lightDarkEdgeImage2,0,1);  

    lightDarkEdgeImage3 = lightDarkEdgeImage;
    
    % Only keep the strongest gradient, removing consecutive gradient
    % values
    for iCol = 1:imageWidth
        column = darkLightEdgeImage(:,iCol);
        maxima = find(diff(sign(diff([0;column;0]))) < 0);
        darkLightEdgeImage(:,iCol) = 0;
        darkLightEdgeImage(maxima,iCol) = column(maxima);
        
        column = lightDarkEdgeImage(:,iCol);
        maxima = find(diff(sign(diff([0;column;0]))) < 0);
        lightDarkEdgeImage(:,iCol) = 0;
        lightDarkEdgeImage(maxima,iCol) = column(maxima);
    end
    
    % Make it even more difficult to cross the opposite gradient
    darkLightEdgeImage(lightDarkInd) = -1;
    lightDarkEdgeImage(darkLightInd) = -1;
    
    % Set values in the invalid region to zero
    darkLightEdgeImage(invalidIndices) = 0;
    lightDarkEdgeImage(invalidIndices) = 0;
    lightDarkEdgeImage2(invalidIndices) = 0;
    lightDarkEdgeImage3(invalidIndices) = 0;
    
    %
    %  Calculate the gradient weights for each of the edge maps
    %        
    darkLightGradientWeights = 2 - ...
        darkLightEdgeImage(imageEdges(:,1)) - ...
        darkLightEdgeImage(imageEdges(:,2));
    
    lightDarkGradientWeights = 2 - ...
        lightDarkEdgeImage(imageEdges(:,1)) - ...
        lightDarkEdgeImage(imageEdges(:,2));
    
    lightDarkGradientWeights2 = 2 - ...
        lightDarkEdgeImage2(imageEdges(:,1)) - ...
        lightDarkEdgeImage2(imageEdges(:,2));
    
    lightDarkGradientWeights3 = 2 - ...
        lightDarkEdgeImage3(imageEdges(:,1)) - ...
        lightDarkEdgeImage3(imageEdges(:,2));
    
    
    %----------------------------------------------------------------------
    %  Calculate intensity weights
    %----------------------------------------------------------------------
    
    smoothImage(invalidIndices) = 0;
    
    brightIntensityWeights = - smoothImage(imageEdges(:,1)) ...
                             - smoothImage(imageEdges(:,2));
      
    darkIntensityWeights = smoothImage(imageEdges(:,1)) ...
                         + smoothImage(imageEdges(:,2));
    
                     
    %----------------------------------------------------------------------
    %  Calculate the geometric distances between pairs of points.  Lower
    %  weights go to pixel pairs that are closer together
    %----------------------------------------------------------------------
    
    [yFirstPoint, xFirstPoint] = ind2sub(imageSize, imageEdges(:,1));
    [ySecondPoint, xSecondPoint] = ind2sub(imageSize, imageEdges(:,2));
    
    distanceWeights = sqrt( ...
        (xFirstPoint - xSecondPoint).^2 + (yFirstPoint - ySecondPoint).^2);
     
    
    %----------------------------------------------------------------------
    %  Create a weighting matrix. Rows represent the indices of the first
    %  node and columns represent the indices of the second node.  The 
    %  values represent the weights for the edge that is formed between
    %  the two nodes
    %----------------------------------------------------------------------

    % Define the matrices    
    weights = { ...
        {darkLightGradientWeights}, ...                                          % 01: dark-light
        {brightIntensityWeights,distanceWeights}, ...                            % 02: bright, distance
        {lightDarkGradientWeights2,distanceWeights}, ...                         % 03: light-dark, distance
        {lightDarkGradientWeights3,distanceWeights}, ...                         % 04: light-dark, distance
        {darkLightGradientWeights,distanceWeights}, ...                          % 05: light-dark, dark, short weights
        {lightDarkGradientWeights,darkIntensityWeights,distanceWeights}, ...     % 06: light-dark, dark, distance
    };
    nMatrices = length(weights);   
    
    % Set default weight ranges if necessary 
    if isempty(params.WEIGHT_RANGES)
        params.WEIGHT_RANGES = { ...
            {[0,1]}, ...              % 01: dark-light
            {[0,1],[0,1]}, ...        % 02: bright, distance
            {[0,1],[0,1],[0,1]}, ...  % 03: light-dark, distance
            {[0,1],[0,1]}, ...        % 04: light-dark, distance
            {[0,1],[0,1]}, ...        % 05: light-dark, dark, short weights
            {[0,1],[0,1],[0,1]}, ...  % 06: light-dark, dark, distance
        };
    end
    
    % Remove invalid matrix indices
    matrixIndices(matrixIndices < 1) = [];
    matrixIndices(matrixIndices > nMatrices) = [];
    if isempty(matrixIndices)
        matrixIndices = 1:nMatrices;
    end
    
    % Populate the matrices specified
    weightingMatrices = cell(nMatrices,1);
    matrixSize = maxIndex;
    
    for iMatrix = 1:length(matrixIndices)
        
        matrixIndex = matrixIndices(iMatrix);
        
        weightingMatrices{matrixIndex} = generateWeightingMatrix( ...
            matrixSize, ...
            imageEdges, ...
            weights{matrixIndex}, ...
            params.WEIGHT_RANGES{matrixIndex}, ...
            columnEdges, ...
            params.MIN_WEIGHT);
    end
end