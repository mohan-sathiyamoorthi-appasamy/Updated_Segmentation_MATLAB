%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%  pediatric_weightingMatrix.m
%
%  Generates the weighting matrices to be used for graph cut
%
%--------------------------------------------------------------------------
%
%  function weightingMatrices = pediatric_weightingMatrix( ...
%      image, ...
%      axialRes, ...
%      lateralRes, ...
%      matrixIndices, ...
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
%       params - (Optional) WeightingMatrixParameters object containing 
%                 all of the constants used in this function.  Default 
%                 values are set by pediatric_getParameters();
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


function weightingMatrices = pediatric_weightingMatrix( ...
    image, ...
    axialRes, ...
    lateralRes, ...
    matrixIndices, ...
    params)

    %----------------------------------------------------------------------
    %  Initialize missing input parameters
    %----------------------------------------------------------------------
    
    if nargin < 4
        matrixIndices = [];
    end
    
    if nargin < 5
        params = [];
    end

    %----------------------------------------------------------------------
    %  Validate input parameters
    %----------------------------------------------------------------------
    
    if isempty(matrixIndices)
        params = pediatric_getParameters();
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
    lightDarkInd2 = (lightDarkEdgeImage2 > 0);
    
    darkLightEdgeImage(lightDarkInd) = 0;
    lightDarkEdgeImage(darkLightInd) = 0;
    darkLightEdgeImage2(lightDarkInd2) = 0;
                     
    % Normalize the weights
    lightDarkEdgeImage = normalizeValues(lightDarkEdgeImage,0,1);  
    darkLightEdgeImage = normalizeValues(darkLightEdgeImage,0,1);
    darkLightEdgeImage2 = normalizeValues(darkLightEdgeImage2,0,1);
    
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
    
    % Make all gradient weights equal
    lightDarkEdgeImage2 = lightDarkEdgeImage;
    lightDarkEdgeImage2(lightDarkEdgeImage2 > 0.1) = 1;
    lightDarkEdgeImage2(lightDarkEdgeImage2 <= 0.1) = 0;
    
    % Make it even more difficult to cross the opposite gradient
    darkLightEdgeImage(lightDarkInd) = -1;
    lightDarkEdgeImage(darkLightInd) = -1;
     
    %
    %  Calculate the gradient weights for each of the edge maps
    %        
    darkLightGradientWeights = 2 - ...
        darkLightEdgeImage(imageEdges(:,1)) - ...
        darkLightEdgeImage(imageEdges(:,2));
    
    darkLightGradientWeights2 = 2 - ...
        darkLightEdgeImage2(imageEdges(:,1)) - ...
        darkLightEdgeImage2(imageEdges(:,2));
    
    lightDarkGradientWeights = 2 - ...
        lightDarkEdgeImage(imageEdges(:,1)) - ...
        lightDarkEdgeImage(imageEdges(:,2));
    
    lightDarkGradientWeights3 = 2 - ...
        lightDarkEdgeImage2(imageEdges(:,1)) - ...
        lightDarkEdgeImage2(imageEdges(:,2));
    
                     
    %----------------------------------------------------------------------
    %  Calculate the geometric distances between pairs of points.  Lower
    %  weights go to pixel pairs that are closer together
    %----------------------------------------------------------------------
    
    [yFirstPoint, xFirstPoint] = ind2sub(imageSize, imageEdges(:,1));
    [ySecondPoint, xSecondPoint] = ind2sub(imageSize, imageEdges(:,2));
    
    distanceWeights = sqrt( ...
        (xFirstPoint - xSecondPoint).^2 + (yFirstPoint - ySecondPoint).^2);
    
    
    %----------------------------------------------------------------------
    %  Calculate intensity weights
    %----------------------------------------------------------------------
        
    brightIntensityWeights = - smoothImage(imageEdges(:,1)) ...
                             - smoothImage(imageEdges(:,2));
     
    darkIntensityWeights = smoothImage(imageEdges(:,1)) ...
                         + smoothImage(imageEdges(:,2));
                     
    
    %----------------------------------------------------------------------
    %  Create a weighting matrix. Rows represent the indices of the first
    %  node and columns represent the indices of the second node.  The 
    %  values represent the weights for the edge that is formed between
    %  the two nodes
    %----------------------------------------------------------------------

    % Define the matrices    
    weights = { ...
        {darkLightGradientWeights}, ...                   % Dark-light
        {lightDarkGradientWeights, distanceWeights}, ...  % Light-dark short
        {darkLightGradientWeights2}, ...                  % Dark-light
        {darkLightGradientWeights, distanceWeights}, ...  % Dark-light short
        {lightDarkGradientWeights3,distanceWeights,brightIntensityWeights}, ...  % light-dark short weights
        {darkIntensityWeights,lightDarkGradientWeights}, ...                     % dark intensity + light-dark weights
        {darkIntensityWeights,lightDarkGradientWeights3,distanceWeights}, ...     % dark intensity + light-dark short weights
        {darkIntensityWeights,darkLightGradientWeights,distanceWeights}, ...     % dark intensity + dark-light weights
        {brightIntensityWeights,lightDarkGradientWeights,distanceWeights}, ...   % bright intensity + light-dark short weights
    };
    nMatrices = length(weights);   
    
    % Set default weight ranges if necessary 
    if isempty(params.WEIGHT_RANGES)
        params.WEIGHT_RANGES = { ...
            {[0,1]}, ...         % Dark-light
            {[0,1], [0,1]}, ...  % Light-dark short
            {[0,1]}, ...         % Dark-light
            {[0,1], [0,1]}, ...  % Dark-light short
            {[0,1],[0,1],[0,1]}, ...  % light-dark short weights (light-dark,distance,bright)
            {[0,1],[0,1]}, ...        % dark intensity + light-dark weights (dark,light-dark)
            {[0,1],[0,1],[0,1]}, ...  % dark intensity + light-dark short weights (dark,light-dark,distance)
            {[0,1],[0,1],[0,1]}, ...  % dark intensity + dark-light weights (dark,dark-light,distance)
            {[0,1],[0,1],[0,1],[0,1]}, ...  % bright intensity + light-dark short weights (bright,light-dark,distance)
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