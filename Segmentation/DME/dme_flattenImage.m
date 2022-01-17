%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%  dme_flattenImage.m
%
%  Flattens the image based on the line provided
%
%--------------------------------------------------------------------------
%
%  function [image,pixelShift,invalidIndices] = dme_flattenImage( ...
%      image, line)
%
%  INPUT PARAMETERS:
%
%       image - The image to flatten of size (imageHeight x imageWidth)
%
%       line - The line to flatten the image by of size (1 x imageWidth)
%
%  RETURN VARIABLES:
% 
%       image - Flattened image based on the line
%
%       pixelShift - A (1 x imageWidth) vector of the number of pixels
%                    each column was shifted by
%
%       invalidIndices - A vector of image indices that should be ignored
%                       (eg: pixels shifted from the bottom of the image to
%                        the top, or the top few rows due to shot noise)
%
%--------------------------------------------------------------------------
%
%  Author:          Stephanie Chiu
%  Institution:     Duke University
%  Date Created:    2011.09.01
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [image,pixelShift,invalidIndices] = dme_flattenImage( ...
    image, line)

    %----------------------------------------------------------------------
    %   Validate input parameters
    %----------------------------------------------------------------------
    
    if isempty(line) || all(isnan(line))
        pixelShift = [];
        invalidIndices = [];
        return;
    end
    
    [imageHeight,imageWidth] = size(image);
    
    
    %----------------------------------------------------------------------
    %   Get the line to flatten
    %----------------------------------------------------------------------
    
    % Extrapolate missing values from the line
    x = 1:imageWidth;
    validInd = ~isnan(line);
    line = smooth(line,0.2)';
    line = round(interp1(x(validInd),line(validInd),x,'nearest','extrap'));
    [p1,s1] = polyfit(x(validInd),line(validInd),2);
    [p2,s2] = polyfit(x(validInd),line(validInd),3);
    if s1.normr < s2.normr    
        line = polyval(p1,x);
    else
        line = polyval(p2,x);
    end
    
    % Make sure line is not out of the image bounds
    line(line < 1) = 1;
    line(line > imageHeight) = imageHeight;
    
    
    %----------------------------------------------------------------------
    %   Flatten the image
    %----------------------------------------------------------------------
    
    % Flatten the image based on the line
    [image, pixelShift, invalidIndices] = flattenImage(image,line);
end