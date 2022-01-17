%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%  cutRegion.m
%
%  Cut a predetermined section using Dykestra's method
%
%--------------------------------------------------------------------------
%
%  function cut = cutRegion( ...
%      imageSize, ...
%      regionIndices, ...
%      weightingMatrix, ...
%      coordinateIndices)
%
%  INPUT PARAMETERS:
%
%       imageSize - A (1x2) vector containng the image size, [height width]
%
%       regionIndices - Indices of the image to perform graph cut within
%
%       weightingMatrix - Weighting matrix containing weights of each node
%                         on the image
%
%       coordinateIndices - (Optional) A vector of the indicies of the 
%                           points to include in the cut.  These are used 
%                           as the initialization points for graphing the 
%                           shortest path
%
%  OUTPUT VARIABLES:
%
%       cut - A (1 x width) vector containing the y coordinates of the cut
%
%       distance - The total weight distance accumulated along the path
%
%--------------------------------------------------------------------------
%
%  Author:          Stephanie Chiu
%  Institution:     Duke University
%  Date Created:    2009.12.19
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [cut,distance] = cutRegion( ...
    imageSize, ...
    regionIndices, ...
    weightingMatrix, ...
    coordinateIndices)

    %----------------------------------------------------------------------
    %  Initialize missing parameters
    %----------------------------------------------------------------------
    
    if nargin < 4
        coordinateIndices = [];
    end
    
    
    %----------------------------------------------------------------------
    %  Verify input parameters
    %----------------------------------------------------------------------

    imageHeight = imageSize(1);
    imageWidth = imageSize(2);
    regionIndices = sort(regionIndices);
    
    %
    %  Verify that all input coordinates are within the region 
    %  specified
    %
    if ~isempty(coordinateIndices)
        for iCoord = 1:length(coordinateIndices)
            if (0 == sum(regionIndices == coordinateIndices(iCoord)))
                error('Coordinates must be within the input region');
            end
        end
    end       

    %
    %  Make sure the region spans the entire width of the image
    %
    [y,x] = ind2sub(imageSize,regionIndices);   
    startIndex = regionIndices(1);
    endIndex = find(x == imageWidth,1,'first');
  
    if startIndex > imageHeight || isempty(endIndex)
        error('Region does not span the entire width of the image');
    end
    
    %
    %  Make sure the coordinate indices span the entire width of the image
    %
    if isempty(coordinateIndices) || coordinateIndices(1) > imageHeight
        coordinateIndices = [startIndex, coordinateIndices];
    end
    
    [y,x] = ind2sub(imageSize,coordinateIndices(end));
    if isempty(coordinateIndices) || x < imageWidth
        endIndex = regionIndices(endIndex);
        coordinateIndices = [coordinateIndices, endIndex];
    end
    
    nCoordinates = length(coordinateIndices);
    
    
    %----------------------------------------------------------------------
    %  Restrict the graph cut region to the regionIndices input
    %----------------------------------------------------------------------
        
    %
    %  Restrict the adjacency matrix based on the region indices
    %
    weightingMatrix = weightingMatrix(regionIndices, regionIndices);
        
    %    
    %  Generate lookup matrix, creating indices for the new region.
    %
    region = zeros(imageSize);
    region(regionIndices) = 1:length(regionIndices);
    
    
    %----------------------------------------------------------------------
    %  Calculate the best path that will connect the input coordinates
    %----------------------------------------------------------------------
    
    path = [];
    
    for iCoord = 1:nCoordinates - 1
        
        firstIndex = coordinateIndices(iCoord);
        secondIndex = coordinateIndices(iCoord + 1);
        
        %
        %  Find the shortest path two coordinates at a time
        %
    	[distance, pathSegment] = graphshortestpath( ...
            weightingMatrix, ...
            region(firstIndex), ...
            region(secondIndex), ...
            'Method', 'Dijkstra', ...
            'Directed', 0);
        
        %
        %  Add the paths together. Remove the repeated coordinate
        %
        if isempty(pathSegment)
            path = [];
            break;
        elseif iCoord ~= 1
            pathSegment(1) = [];
        end
        
        path = [path, pathSegment];
    end
    
    [y,x] = ind2sub(imageSize,regionIndices(path));
    
    %
    %  Since the path contains multiple points per column, take the first
    %  point in every column as the path
    %
    cut = NaN(1, imageWidth);
    
    if ~isempty(x) && ~isempty(y)
        for column = 1:imageWidth

            if column == 1
                index = find(x == column, 1, 'last'); 
            else
                index = find(x == column, 1, 'first'); 
            end

            cut(column) = y(index);
        end
    end
end

