%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%  blurImage.m
%
%  Blur the image with a filter, taking care of border effects during the
%  blurring process.
%
%--------------------------------------------------------------------------
%
%  function image = blurImage(image, filter)
%
%  INPUT PARAMETERS:
%
%       image - Image to blur
%
%       filter - Filter to blur the image with using convolution
%
%  OUTPUT VARIABLES:
%
%       image - Resulting blurred image
%
%--------------------------------------------------------------------------
%
%  Author:          Sina Farsiu (sina.farsiu@duke.edu)
%  Date Created:    2003.05.29
%  Institution:     Duke University
%
%  Modifications:
%
%  - 2009.12.10  Stephanie Chiu (stephanie.chiu@duke.edu)
%       * Changed filename from sinablur to blur
%       * Removed third input parameter 'same' since it was not used
%       * Changed parameter names
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function image = blurImage(image, filter)

    image = double(image);
    [imageHeight, imageWidth] = size(image);

    filter = double(filter);
    filterSize = size(filter);

    %
    %  Calculate the half widths of the filter
    %
    yHW = round(filterSize(1)/2);
    xHW = round(filterSize(2)/2);

    %
    %  Pad the borders to minimize convolution edge effects
    %
    image(1+yHW:imageHeight+yHW,1+xHW:imageWidth+xHW) = image;

    image(imageHeight+yHW+1:imageHeight+2*yHW,:) = image(imageHeight+yHW-1:-1:imageHeight,:);
    image(yHW:-1:1,:) = image(1+yHW+1:2*yHW+1,:);

    image(:,imageWidth+xHW+1:imageWidth+2*xHW) = image(:,imageWidth+xHW-1:-1:imageWidth);
    image(:,xHW:-1:1) = image(:,1+xHW+1:2*xHW+1);

    %
    %  Blur the image
    %
    image = conv2(image,filter,'same');

    %
    %  Restore the original size of the image
    %
    image = image(1+yHW:imageHeight+yHW,1+xHW:imageWidth+xHW);
end