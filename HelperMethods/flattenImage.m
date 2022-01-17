%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%  flattenImage.m
%
%  Flattens a vector into a line or matrix (Bscan) according to the PRNL
%
%  Note:  A positive shift value means the column is shifted up a row.  
%         For images, this means the column is shifted down, visually
%
%--------------------------------------------------------------------------
%
%  function [flattenedImage, pixelShift, invalidIndices, flattenedLine] = ...
%      flattenImage(image, lineToFlatten, referencePoint, fillType)
%
%  INPUT ARGUMENTS:
%
%       image - Vector of size (1 x imageWidth) or matrix of size 
%               (imageHeight x imageWidth) to be flattened
%
%       lineToFlatten - Vector of size (1 x imageWidth) that is used to
%                       flatten the image
%
%       referencePoint - Reference line for where the pixels will be
%                        shifted to. optional variable with default = 0
%
%              [0] - mean of the line to flatten
%              [1] - min of the line to flatten
%              [2] - max of the line to flatten
%              [offset] - mean of the line to flatten plus an offset,
%                         cannot be 1,or 2
%
%       fillType - The type of filler for the invalid pixels. Default = 1
%
%              [0] - invalid pixel values are set to 0 (black)
%              [1] - invalid pixel values set to mirror image of valid
%                    region
%              [2] - invalid pixel values set to the nearest valid pixel
%
%
%  RETURN VARIABLES:
% 
%       flattenedImage - Flattened vector or matrix of equivalent size to
%                        the image
%
%       pixelShift - A (1 x imageWidth) vector of the number of pixels
%                    each column was shifted by
%
%       invalidIndices - A vector of image indices that should be ignored
%                       (eg: pixels shifted from the bottom of the image to
%                        the top, or the top few rows due to shot noise)
%
%       flattenedLine - A (1 x imageWidth) vector of the lineToFlatten post
%                       flattening (should be a straight line at a
%                       particular y-position)
%
%--------------------------------------------------------------------------
%
%  Author:          Stephanie Chiu
%  Institution:     Duke University
%  Creation Date:   2009.11.23
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


function [flattenedImage, pixelShift, invalidIndices, flattenedLine] = ...
    flattenImage(image, lineToFlatten, referencePoint, fillType)

    %----------------------------------------------------------------------
    %  Validate input parameters
    %----------------------------------------------------------------------
    
    if nargin < 3 || isempty(referencePoint)
        referencePoint = 0;
    end
    
    if nargin < 4 || isempty(fillType)
        fillType = 1;
    end
    
    if isempty(image)
        error('Image cannot be empty');
    end
    
    if size(image, 3) > 1
        error('Image must be 1D or 2D');
    end
    
    if size(image, 2) == 1
        image = image';
    end
    
    % Do nothing if the line to flatten was not specified
    if isempty(lineToFlatten) || all(isnan(lineToFlatten))
        flattenedImage = image;
        pixelShift = [];
        invalidIndices = [];
        flattenedLine = [];
        return;
    end

    image = double(image);
    imageSize = size(image);
    imageHeight = imageSize(1);
    imageWidth = imageSize(2);
    
    if length(lineToFlatten) ~= imageWidth
        error('The line to flatten must be the same length as the image width');
    end
    
    % We are doing pixel shifts, so sub-pixel shifting is not allowed
    lineToFlatten = round(lineToFlatten);

    
    %----------------------------------------------------------------------
    %  Flatten a vector (line)
    %----------------------------------------------------------------------
    
    if imageHeight == 1
        
        % Shift the line so that it lies on the reference location        
        switch referencePoint
            case 0
                reference = round(mean(lineToFlatten));
            case 1
                reference = round(min(lineToFlatten));
            case 2
                reference = round(max(lineToFlatten));
            otherwise
                reference = round(mean(lineToFlatten) + referencePoint);
        end
        pixelShift = reference - lineToFlatten;
        flattenedImage = image + pixelShift;
        invalidIndices = [];
        flattenedLine =  reference * ones(imageSize);
        
        
    %----------------------------------------------------------------------
    %  Flatten a matrix (Bscan) based on the PRNL
    %----------------------------------------------------------------------
    
    else
        % Shift the image with respect reference location
        flattenedImage = image;
        switch referencePoint
            case 0
                reference = round(mean(lineToFlatten));
            case 1
                reference = round(min(lineToFlatten));
            case 2
                reference = round(max(lineToFlatten));
            otherwise
                reference = round(mean(lineToFlatten) + referencePoint);
        end
        pixelShift = reference - lineToFlatten;
        invalidImage = zeros(imageSize);

        % Loop through each column, shifting it up or down so that the line
        % to flatten lies on a flat line. 
        for index = 1:length(lineToFlatten)
            
            % Circular shift the column
            flattenedImage(1:end, index) = ...
                circshift(image(1:end, index), pixelShift(index));

            % If shifted down
            if pixelShift(index) > 0
                
                % Get locations where pixels have been shifted out. These
                % are invalid regions that need to be replaced
                invalidIndices = 1:pixelShift(index);
                
                switch(fillType)
                    case 0
                        mirroredColumn = zeros(1,length(invalidIndices));
                    case 1
                        % Get the mirror image of the valid regions of the column,
                        % which will be used to replace the invalid regions
                        mirroredColumn = padarray( ...
                            flattenedImage(invalidIndices(end) + 1:end,index), ...
                            length(invalidIndices), ...
                            'symmetric', 'pre');

                        mirroredColumn = mirroredColumn(1:length(invalidIndices));
                    case 2
                        mirroredColumn = (invalidIndices(end)+1)*ones(1,length(invalidIndices));
                end
                
            % If shifted up
            elseif pixelShift(index) < 0
                
                % Get locations where pixels have been shifted out. These
                % are invalid regions that need to be replaced
                invalidIndices = imageHeight + pixelShift(index) + 1:imageHeight;
                
                switch(fillType)
                    case 0
                        mirroredColumn = zeros(1,length(invalidIndices));
                        
                    case 1
                        % Get the mirror image of the valid regions of the column,
                        % which will be used to replace the invalid regions
                        mirroredColumn = padarray( ...
                            flattenedImage(1:invalidIndices(1)-1,index), ...
                            length(invalidIndices), ...
                            'symmetric', 'post');

                        mirroredColumn = mirroredColumn(end-length(invalidIndices)+1:end);
                        
                    case 2
                        mirroredColumn = (invalidIndices(1)-1)*ones(1,length(invalidIndices));
                end
                
            % If no shifting
            else
                invalidIndices = [];
                mirroredColumn = [];
            end
            
            % Replace the invalid indices with the mirror image of the
            % valid pixels. This is so that there is no artificial gradient
            % created when segmenting the image later on.
            flattenedImage(invalidIndices, index) = mirroredColumn;
            
            % Keep track of which indices on the image are invlaid 
            invalidImage(invalidIndices, index) = 1;
        end

        % Get the indices of the invalid regions
        invalidIndices = find(invalidImage == 1);
        
        % Get the resulting flattened line
        flattenedLine = lineToFlatten + pixelShift;
    end
end