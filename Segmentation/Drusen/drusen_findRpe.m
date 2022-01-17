%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%  drusen_findRpe.m
%
%  Finds the RPE layer based on the segmented RPE and Bruchs layers
%
%--------------------------------------------------------------------------
%
%  function rpe = drusen_findRpe(image, axialRes, lateralRes, rpe, bruchs)
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
%       rpe - y coordinates of the RPE (1 x imageWidth)
%
%       bruchs - y coordinates of the Bruch's membrane (1 x imageWidth
%
%  RETURN VARIABLES:
%
%       rpe - y coordinates of the RPE (1 x imageWidth), 
%             empty if the RPE was not found
%
%--------------------------------------------------------------------------
%
%  Author:          Stephanie Chiu
%  Institution:     Duke University
%  Date Created:    2010.11.12
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function rpe = drusen_findRpe(image, axialRes, lateralRes, rpe, bruchs)
    
    
    %----------------------------------------------------------------------
    %  Initialize missing input parameters
    %----------------------------------------------------------------------
    
    if isempty(rpe) || isempty(bruchs)
        rpe = [];
        return;
    end
    
    
    %----------------------------------------------------------------------
    %  Process the bottom layer
    %----------------------------------------------------------------------
    
    imageHeight = size(image,1);
    imageWidth = size(image,2);

    topLayer = rpe;
    bottomLayer = bruchs;
    indices = (bottomLayer - topLayer > round(46.9/axialRes));
    bottomLayer(indices) = nanmax(topLayer(indices),bottomLayer(indices)-round(13.4/axialRes));
    indices = (bottomLayer - topLayer > round(100.5/axialRes));
    bottomLayer(indices) = nanmax(topLayer(indices),bottomLayer(indices)-round(26.8/axialRes));
    
    
    %----------------------------------------------------------------------
    %  Filter the image
    %----------------------------------------------------------------------
    
    xFilterSize = round(67 / lateralRes);
    yFilterSize = round(32.5 / axialRes);
    filter = fspecial('gaussian',[yFilterSize,xFilterSize],5);   
    image = blurImage(image,filter);
    filter = fspecial('gaussian',[yFilterSize,1],5); 
    image = blurImage(image,filter);
    
    
    %----------------------------------------------------------------------
    %  Find the RPE for each column based on intensity
    %----------------------------------------------------------------------

    startCol = find(~isnan(topLayer) & ~isnan(bottomLayer),1,'first');
    endCol = find(~isnan(topLayer) & ~isnan(bottomLayer),1,'last');
    
    for col = startCol:endCol
        smoothColumn = image(:, col);
        
        startInd = max(1,topLayer(col));
        endInd = min(imageHeight,bottomLayer(col));        
        smoothColumn([1:startInd,endInd:imageHeight]) = 0;
        
        y = find(smoothColumn == nanmax(smoothColumn), 1);
        if y == 1
            rpe(col) = rpe(col);
        else
            rpe(col) = y;
        end
    end
    
    
    %----------------------------------------------------------------------
    %  Look for jumps up or down and remove them
    %----------------------------------------------------------------------
    
    minJump = round(33 / axialRes);
    difference = diff(rpe);
    jumps = find(difference > minJump | difference < -minJump);
    
    for ind = 2:length(jumps)
        if difference(jumps(ind))*difference(jumps(ind-1)) > 0 || ...
           jumps(ind) - jumps(ind-1) > round(134/lateralRes)
            continue;
        end
        
        for col = jumps(ind-1):jumps(ind)
            smoothColumn = image(:, col);
            if col > 1
                startInd = rpe(col-1) - round(32.5/axialRes);
                endInd = rpe(col-1) + round(32.5/axialRes);
            end
            startInd = nanmax(1, startInd);
            endInd = nanmin(imageHeight,endInd);
            smoothColumn([1:startInd,endInd:imageHeight]) = 0;
            y = find(smoothColumn == nanmax(smoothColumn), 1);
            if y == 1
                rpe(col) = rpe(col);
            else
                rpe(col) = y;
            end
        end
    end
    
    %----------------------------------------------------------------------
    % Make sure it does not go out of bounds
    %----------------------------------------------------------------------
    
    rpe(rpe < 1) = 1;
    rpe(rpe > imageHeight) = imageHeight;    
end