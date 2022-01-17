%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%  locateFovea.m
%
%  Locates the fovea based on the ILM and a second layer
%
%--------------------------------------------------------------------------
%
%  function foveaParams = locateFovea( ...
%      imageSize, ...
%      axialRes, ...
%      lateralRes, ...
%      ilm, ...
%      innerLayer, ...
%      rpe, ...
%      invalidIndices)
%
%  INPUT PARAMETERS:
%
%       imageSize - A (1x2) vector containng the image size, [height width]
%
%       axialRes - Axial (vertical) resolution of the image in um/pixel
%
%       lateralRes - Lateral (horizontal) resoution of the image in
%                    um/pixel
%
%       rpe - A vector of size (1 x imageWidth) containing the
%             y-coordinates of the inner limiting membrane
%
%       innerLayer - A vector of size (1 x imageWidth) containing the
%                    y-coordinates of an inner layer boundary
%
%       rpe - A vector of size (1 x imageWidth) containing the
%             y-coordinates of the inner aspect of the RPE
%
%       invalidIndices - A vector of image indices that should be ignored
%                        and not considered during graph cut
%
%  Output Parameters:
%
%       foveaParams - A structure containing information about the fovea
%                     described by the following parameters
%
%           Index:  The image column containing the foveal center;
%
%           Range: A 1x2 vector containing the left and right columns that
%                  contain the fovea region;
%
%           Percentage = The percentage of the fovea depression (a larger
%                        percentage indicating a deeper depression)
%
%--------------------------------------------------------------------------
%
%  Author:          Stephanie Chiu
%  Institution:     Duke University
%  Date Created:    2009.12.15
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


function foveaParams = locateFovea( ...
    imageSize, ...
    axialRes, ...
    lateralRes, ...
    ilm, ...
    innerLayer, ...
    rpe, ...
    invalidIndices)

    % Only look for the fovea in the middle of the image
    imageWidth = imageSize(2);
    margin = round(imageWidth/8);
    middleInd = zeros(1,imageWidth);
    middleInd(margin:imageWidth-margin) = 1;
    
    % Do not look at the fovea where the image is invalid
    x = 1:imageWidth;
    invalidInd = intersect(sub2ind(imageSize,[ilm,rpe],[x,x]), invalidIndices);
    [yInvalid,xInvalid] = ind2sub(imageSize,invalidInd);
    xInvalid = unique(xInvalid);
    middleInd(xInvalid) = 0;
            
    % Get the layer thickness
    thicknessOrig = innerLayer - ilm;
    thickness = smooth(thicknessOrig,0.1);
    
    % Locate where the locale max and min layer thicknesses are
    maxima = find( middleInd(2:end)' & diff( sign( diff([thickness(1); thickness]) ) ) < 0 );
    maxima(diff(maxima) == 1) = [];
    minima = find( middleInd(2:end)' & diff( sign( diff([thickness(1); thickness;]) ) ) > 0 );
    minima(diff(minima) == 1) = [];
    combined = [maxima, zeros(length(maxima),1); minima, ones(length(minima),1)];
    combined = sortrows(combined);
    
    % Look for the largest change in thickness (corresponding to the fovea
    % location)
    difference = abs(diff(thickness(combined(:,1))));
    locations = find(difference > round(33.5/axialRes));
    
    foveaParams.Index = [];
    foveaParams.Range = [];
    foveaParams.Percentage = [];
           
    for index = 1:length(locations)-1
        if (combined(locations(index),2) == 0 && combined(locations(index)+1,2) == 1) && ...
           (combined(locations(index+1),2) == 1 && combined(locations(index+1)+1,2) == 0)
    
            foveaRange = [combined(locations(index),1), combined(locations(index+1)+1,1)];
            foveaThick = thicknessOrig(foveaRange(1):foveaRange(2));
            foveaIndex = find(foveaThick == min(foveaThick));
            foveaIndex = foveaIndex(round(length(foveaIndex)/2)) + foveaRange(1) - 1;                   
            foveaPercentage = (innerLayer(foveaIndex) - ilm(foveaIndex)) / ...
                              (rpe(foveaIndex) - ilm(foveaIndex));
                          
            % Make the fovea range a constant width
            thickness = round(670/lateralRes);
            foveaRange(1) = max(1,foveaIndex-thickness);
            foveaRange(2) = min(imageWidth,foveaIndex+thickness);

            foveaParams.Index = foveaIndex;
            foveaParams.Range = foveaRange;
            foveaParams.Percentage = foveaPercentage;
            break;
        end
    end
end