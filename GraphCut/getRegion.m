%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%  getRegion.m
%
%  Gets a region based on a top and bottom layer and returns the regions
%  indices
%
%--------------------------------------------------------------------------
%
%  function regionIndices = getRegion( ...
%      imageSize, ...
%      topLayer, ...
%      bottomLayer, ...
%      topAddition, ...
%      bottomAddition, ...
%      invalidIndices, ...
%      correctBottomLine, ...
%      spanImageWidth)
%
%  INPUT PARAMETERS:
%
%       imageSize - A (1x2) vector containng the image size, [height width]
%
%       topLayer - A (1 x width) vector containing the y coordinates of the
%                  top layer of the region
%
%       bottomLayer - A (1 x width) vector containing the y coordinates of
%                     the bottom layer of the region
%
%       topAddition - Number of pixels to widen the top of the region by.
%                     A negative value shifts the line up, a positive value
%                     shifts the line down
%
%       bottomAddition - Number of pixels to widen the bottom of the region
%                        A negative value shifts the line up, a positive 
%                        value shifts the line down
%
%       invalidIndices - Vector containing indices of the image that should
%                        not be included as part of the region to perform
%                        segmentation
%
%       correctBottomLine - Change the bottom line according to the top
%                           line in the case of overlap if true. Correct 
%                           the top line based off of the bottom otherwise
%
%       spanImageWidth - If true, expands the region so that it extends 
%                        across the entire width of the image. This is
%                        useful for graph cutting acroos the image
%
%  OUTPUT VARIABLES:
%
%       regionIndices - Indices of the image that are in the region
%
%--------------------------------------------------------------------------
%
%  Author:          Stephanie Chiu
%  Institution:     Duke University
%  Date Created:    2009.05.22
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function regionIndices = getRegion( ...
    imageSize, ...
    topLayer, ...
    bottomLayer, ...
    topAddition, ...
    bottomAddition, ...
    invalidIndices, ...
    correctBottomLine, ...
    spanImageWidth)
    
        
    %----------------------------------------------------------------------
    %  Initialize missing input parameters
    %----------------------------------------------------------------------
    
    if nargin < 4
        topAddition = 0;
    end
    if nargin < 5
        bottomAddition = 0;
    end
    if nargin < 6
        invalidIndices = [];
    end
    if nargin < 7
        correctBottomLine = 1;
    end
    if nargin < 8
        spanImageWidth = 1;
    end
        
    
    %----------------------------------------------------------------------
    %  Validate input parameters
    %----------------------------------------------------------------------

    imageHeight = imageSize(1);
    imageWidth = imageSize(2);
    
    if length(topLayer) ~= length(bottomLayer)
        error('topLayer and bottomLayer must be of the same length');
    end
    
    if length(topLayer) ~= imageWidth
        error('The layers must have a length equal to the image width');
    end
    
    % Replace all layer values outside the image range
    topLayer(topLayer < 1) = 1;
    topLayer(topLayer > imageHeight) = imageHeight;
    bottomLayer(bottomLayer < 1) = 1;
    bottomLayer(bottomLayer > imageHeight) = imageHeight;
  
    
    %----------------------------------------------------------------------
    %  Expand the each layer boundary by the number of pixels to add,
    %  making sure to take care of any pixels that are out of bounds
    %----------------------------------------------------------------------
    
    bottomLayer = bottomLayer + bottomAddition;    
    topLayer = topLayer + topAddition;
    
    
    %----------------------------------------------------------------------
    %  Limit the layers by the invalid region
    %----------------------------------------------------------------------
    
    invalidImage = zeros(imageSize);
    invalidImage(invalidIndices) = 1;
    
    for iCol = 1:imageWidth
        topIndex = find(invalidImage(:,iCol) == 0, 1, 'first');
        bottomIndex = find(invalidImage(:,iCol) == 0, 1, 'last');
        if ~isempty(topIndex)
            topLayer(iCol) = max(topLayer(iCol),topIndex);
            bottomLayer(iCol) = min(bottomLayer(iCol),bottomIndex);
        end
    end
    
    
    %----------------------------------------------------------------------
    %  Correct the appropriate line if it crosses the other line
    %----------------------------------------------------------------------
    
    difference = bottomLayer - topLayer;
    invalidInd = find(difference < 0);
    if ~isempty(invalidInd)
        if correctBottomLine
            bottomLayer(invalidInd) = topLayer(invalidInd);
        else
            topLayer(invalidInd) = bottomLayer(invalidInd);
        end
    end
    
    
    %----------------------------------------------------------------------
    %  Get the indices of all pixels in between the two regions  
    %----------------------------------------------------------------------
    
    regionImage = zeros(imageSize);
    
    for iCol = 1:imageWidth
        
        % Close any vertical gaps that there may be in the region
        if (iCol < imageWidth)
            if topLayer(iCol) > bottomLayer(iCol+1)
                topLayer(iCol) = topLayer(iCol+1);
                bottomLayer(iCol+1) = bottomLayer(iCol);
                
            elseif bottomLayer(iCol) < topLayer(iCol+1)
                bottomLayer(iCol) = bottomLayer(iCol+1);
                topLayer(iCol+1) = topLayer(iCol);
            end
        end
        
        % Get the indices in the region
        yRegion = topLayer(iCol):bottomLayer(iCol);
        indices = round(sub2ind(imageSize, yRegion, iCol*ones(size(yRegion))));
        if ~isnan(indices)
            regionImage(indices) = 1;
            
        % Make sure the region extends across the width of the image
        elseif spanImageWidth
            regionImage(:,iCol) = 1;
        end
    end
    
    
    %----------------------------------------------------------------------
    %  Take out any region indices that were specified as invalid
    %----------------------------------------------------------------------
      
    invalidImage = zeros(imageSize);
    invalidImage(invalidIndices) = 1;
    invalidImage = invalidImage & regionImage;
    
    % Remove invalid indices from the region
    regionImage(invalidIndices) = 0;
    
    % Make sure no columns are all NaN
    nanColumns = sum(regionImage) ==  0;
    regionImage(:,nanColumns) = invalidImage(:,nanColumns);
    nanColumns = sum(regionImage) ==  0;
    validImage = ones(imageSize);
    validImage(invalidIndices) = 0;
    regionImage(:,nanColumns) = validImage(:,nanColumns);
    nanColumns = sum(regionImage) ==  0;
    regionImage(:,nanColumns) = 1;
    
    % Get the indices    
    regionIndices = find(regionImage == 1);
end