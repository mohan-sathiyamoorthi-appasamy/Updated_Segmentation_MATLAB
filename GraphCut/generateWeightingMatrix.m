%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%  generateWeightingMatrix.m
%
%  Generates a weighting matrix
%
%--------------------------------------------------------------------------
%
%  function matrix = generateWeightingMatrix( ...
%      matrixSize, ...
%      imageEdges, ...
%      weights, ...
%      weightRanges, ...
%      columnEdges, ...
%      columnWeight)
%
%  INPUT PARAMETERS:
%
%       matrixSize - An integer corresponding to the size of the adjacency 
%                    matrix (the largest index value in an image, e.g. 
%                    imageHeight * imageWidth)
%
%       imageEdges - A two-column matrix containing pairs of connected 
%                    nodes for the image, excluding the vertical edges for
%                    the columns added to either side of the image
%
%       weights - An array of weight values coressponding to each image
%                 edge
%
%       weightRanges - A cell array of weight ranges, where each element is 
%                      a vector of length 2 containing the minimum and 
%                      maximum weight for the individual features to be
%                      summed in the weight (e.g. gradient, intensity)
%
%       columnEdges - A two-column matrix containing the vertical edge
%                     pairs for the columns added to either side of the 
%                     image
%
%       columnWeight - The minimum weight to be enforced on the entire
%                      matrix. Also sets the weight value of the vertical
%                      column edges
%
%  RETURN VARIABLES:
%
%       matrix - A sparse matrix with the specified size and weight values 
%                normalized to the specified ranges
%
%  EXAMPLE: Consider a matrix combining distance weights ranging from 0 to
%           1 and intensity weights ranging from 2 to 3
%
%       weights =  {distanceWeights, intensityWeights}
%
%       weightRanges = {[0,1], [2,3]}
%
%       The result is a sparse matrix contains the addition of distance 
%       weights ranging from 0 to 1 and intensity weights ranging from 2 to 
%       3 and a minimum weight for the vertical column edges
%
%--------------------------------------------------------------------------
%
%  Author:          Stephanie Chiu
%  Institution:     Duke University
%  Date Created:    2009.05.22
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function matrix = generateWeightingMatrix( ...
    matrixSize, ...
    imageEdges, ...
    weights, ...
    weightRanges, ...
    columnEdges, ...
    columnWeight)

    %
    %  Set the column weights
    %
    columnWeights = columnWeight .* ones(length(columnEdges),1);    
    
    %
    %  Normalize the image weights and combine all weights together
    %
    imageWeights = columnWeight;
    
    for index = 1:length(weights)
        weights{index} = normalizeValues( ...
            weights{index}, weightRanges{index}(1), weightRanges{index}(2));
        
        imageWeights = imageWeights + weights{index};
    end 
                    
    %
    %  Combine the image and column weights, adding node pair duplicates
    %  such that the paths are bidirectional
    %
    totalEdges = [imageEdges; columnEdges];
    totalWeights = [imageWeights; columnWeights];
    
    %
    %  Create a weighting matrix. Rows represent the indices of the first
    %  node and columns represent the indices of the second node.  The 
    %  values represent the weights for the edge that is formed between
    %  the two nodes   
    %    
    matrix = sparse( ...
        totalEdges(:,2), totalEdges(:,1), ...
        totalWeights, ...
        matrixSize, matrixSize);
end