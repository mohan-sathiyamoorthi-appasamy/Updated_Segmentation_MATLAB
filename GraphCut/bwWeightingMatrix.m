%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%  weightingMatrix.m
%
%  Generates the weighting matrix to be used for graph cut
%
%--------------------------------------------------------------------------
%
%  function weightingMatrices = bwWeightingMatrix( ...
%      image, ...
%      matrixIndices, ...
%      params)
%
%  INPUT PARAMETERS:
%
%       image - Image to generate adjacency matrix for
%
%       matrixIndices - An array containing the matrix indices to generate
%                       a weighting matrix for. Default = [], which
%                       includes all matrices available
%
%       params - (Optional) WeightingMatrixParameters object containing 
%                 all of the constants used in this function.  Default 
%                 values are set in the WeightingMatrixParameters class 
%                 constructor
%
%  RETURN VARIABLES:
%
%       weightingMatrices - A cell array of weighting matrices to be used
%                           on particular layers weightingMatrix function
%
%--------------------------------------------------------------------------
%
%  Author:          Stephanie Chiu
%  Institution:     Duke University
%  Date Created:    2009.05.22
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


function weightingMatrices = bwWeightingMatrix(image, matrixIndices, params)
    
    
    %----------------------------------------------------------------------
    %  Initialize missing parameters
    %----------------------------------------------------------------------
    
    if nargin < 2
        matrixIndices = [];
    end
    
    if nargin < 3
        params = [];
    end
    
    %----------------------------------------------------------------------
    %  Validate input parameters
    %----------------------------------------------------------------------
    
    if isempty(params)
        params = WeightingMatrixParameters;
    end    

    imageSize = size(image);
    imageHeight = imageSize(1);
    imageWidth = imageSize(2);
    
   
    %----------------------------------------------------------------------
    %  Generate a weighting matrix for the image
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
    rightColIndices = ((imageHeight-1)*(imageWidth-2) + 1) : maxIndex;
    
    columnIndices = [leftColIndices, rightColIndices];
    imageIndices = setdiff(1:size(edges,1), columnIndices);
    
    columnEdges = edges(columnIndices,:);
    imageEdges = edges(imageIndices,:);
    
    
    %----------------------------------------------------------------------
    %  Calculate the weights based on the image gradient.  Lower weights 
    %  are assigned to areas with a higher gradient
    %----------------------------------------------------------------------
    
    %
    %  Create two edge maps (one for edges that transition from dark->light
    %  in the vertical direction, and one for edges transitioning from 
    %  light->dark).  
    %
    diffImage = diff([zeros(1,imageWidth); image]);
    lightDarkEdgeImage = double((diffImage > 0));
    darkLightEdgeImage = double(abs(diffImage < 0));
    
    ind = (lightDarkEdgeImage == 0) & (image == 1);
    lightDarkEdgeImage(ind) = -1;
    
    ind = (darkLightEdgeImage == 0) & (image == 1);
    darkLightEdgeImage(ind) = -1;
    
    %
    %  Calculate the gradient weights for each of the edge maps
    %    
    lightDarkGradientWeights = 2 - ...
        lightDarkEdgeImage(imageEdges(:,1)) - ...
        lightDarkEdgeImage(imageEdges(:,2));
    
    darkLightGradientWeights = 2 - ...
        darkLightEdgeImage(imageEdges(:,1)) - ...
        darkLightEdgeImage(imageEdges(:,2));
    
    
    %----------------------------------------------------------------------
    %  Create a weighting matrix. Rows represent the indices of the first
    %  node and columns represent the indices of the second node.  The 
    %  values represent the weights for the edge that is formed between
    %  the two nodes
    %----------------------------------------------------------------------
    
    % Define the matrices
    weights = { ...
        {lightDarkGradientWeights}, ...  % Dark-light
        {darkLightGradientWeights},...   % Light-dark
    };
    nMatrices = length(weights);  
    
    % Set default weight ranges if necessary   
    if isempty(params.WEIGHT_RANGES)
        params.WEIGHT_RANGES = {{[0,1]},{[0,1]}};
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