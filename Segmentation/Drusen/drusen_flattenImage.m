%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%  drusen_flattenImage.m
%
%  Flattens the image based on the ILM and the RPE
%
%--------------------------------------------------------------------------
%
%  function [image,pixelShift,invalidIndices] = drusen_flattenImage( ...
%      image, lateralRes, ilm, rpe)
%
%  INPUT PARAMETERS:
%
%       image - The image to flatten of size (imageHeight x imageWidth)
%
%       lateralRes - Lateral (horizontal) resoution of the image in
%                    um/pixel
%
%       ilm - The y locations of the ILM (1 x imageWidth)
%
%       rpe - The y locations of the RPE (1 x imageWidth)
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
%  Date Created:    2011.09.08
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [image,pixelShift,invalidIndices] = drusen_flattenImage( ...
    image, lateralRes, ilm, rpe)

    %----------------------------------------------------------------------
    %   Validate input parameters
    %----------------------------------------------------------------------
    
    % Do nothing if both the ILM and the RPE re invalid
    if (isempty(ilm) || all(isnan(ilm))) && (isempty(rpe) || all(isnan(rpe)))
        pixelShift = [];
        invalidIndices = [];
        return;
    end
    
    [imageHeight,imageWidth] = size(image);
    
    xILM = 1:imageWidth;
    xRPE = 1:imageWidth;
    
    yILM = ilm; 
    yRPE = rpe; 
    
    % Ignore columns that are NAN   
    nanILMind = isnan(yILM);
    xILM(nanILMind) = [];
    yILM(nanILMind) = [];

    nanRPEind = isnan(yRPE);
    xRPE(nanRPEind) = [];
    yRPE(nanRPEind) = [];


    %----------------------------------------------------------------------
    %   Get the convex hull
    %----------------------------------------------------------------------
    
    % Get the convex hull indices for the ILM
    if ~isempty(yILM)
        ILMhullInd = convhull(xILM,yILM);
        botILMInd = fliplr([ILMhullInd(diff(ILMhullInd) < 0); ILMhullInd(end)]);
        topILMInd = [ILMhullInd(diff(ILMhullInd) > 0); botILMInd(1)]; 
    else
        ILMhullInd = [];
    end

    % Get the convex hull indices for the RPE
    if ~isempty(yRPE)
        RPEhullInd = convhull(xRPE,yRPE);
        botRPEInd = fliplr([RPEhullInd(diff(RPEhullInd) < 0); RPEhullInd(end)]);
        topRPEInd = [RPEhullInd(diff(RPEhullInd) > 0); botRPEInd(1)];  
    else
        RPEhullInd = [];
    end


    %----------------------------------------------------------------------
    %   Determine whether to use the ILM or the RPE to flatten the image,
    %   and also determine whether the top or the bottom of the convex hull
    %   should be used
    %----------------------------------------------------------------------
    
    % Do not consider hull indices that are too close to each other
    minSpacing = 67 / lateralRes;
    
    % The ILM was invalid, so flatten based on the RPE    
    if isempty(ILMhullInd)
        botRPELength = sum(diff(botRPEInd) <= -minSpacing) + 1;
        if botRPELength < 3
            bruchs = round(interp1(xRPE(topRPEInd), yRPE(topRPEInd), 1:imageWidth, 'linear', 'extrap'));
        else
            bruchs = round(interp1(xRPE(botRPEInd), yRPE(botRPEInd), 1:imageWidth, 'linear', 'extrap'));
        end
        
    % Otherwise the RPE was invalid, so flatten based on the ILM
    elseif isempty(RPEhullInd)
        botILMLength = sum(diff(botILMInd) <= -minSpacing) + 1;
        if botILMLength < 4
            bruchs = round(interp1(xILM(topILMInd), yILM(topILMInd), 1:imageWidth, 'linear', 'extrap'));
        else
            bruchs = round(interp1(xILM(topILMInd), yILM(topILMInd), 1:imageWidth, 'linear', 'extrap'));
        end

    % Otherwise both were valid, so determine whether to flatten based on 
    % the ILM or the RPE
    else
        
        % Get the number of valid hull indices
        botILMLength = sum(diff(botILMInd) <= -minSpacing) + 1;
        botRPELength = sum(diff(botRPEInd) <= -minSpacing) + 1;

        % Determine whether to use the bottom or top convex hull indices
        if (botILMLength < 4 && botRPELength < 3)
            bruchsILM = round(interp1(xILM(topILMInd), yILM(topILMInd), 1:imageWidth, 'linear', 'extrap'));
            bruchsRPE = round(interp1(xRPE(topRPEInd), yRPE(topRPEInd), 1:imageWidth, 'linear', 'extrap'));
        else
            bruchsILM = round(interp1(xILM(botILMInd), yILM(botILMInd), 1:imageWidth, 'linear', 'extrap'));
            bruchsRPE = round(interp1(xRPE(botRPEInd), yRPE(botRPEInd), 1:imageWidth, 'linear', 'extrap'));
        end

        % Replace locations where the ILM is invalid with the RPE
        startInd = find(nanILMind & ~nanRPEind,1,'first');
        endInd = find(~nanILMind & ~nanRPEind,1,'first');
        if ~isempty(endInd) && ~isempty(startInd)
            difference = bruchsRPE(endInd) - bruchsILM(endInd);
            bruchsILM(startInd:endInd) = bruchsRPE(startInd:endInd) - difference;
        end

        % Replace locations where the RPE is invalid with the ILM
        startInd = find(~nanILMind & ~nanRPEind,1,'last');
        endInd = find(nanILMind & ~nanRPEind,1,'last');
        if ~isempty(endInd) && ~isempty(startInd)
            difference = bruchsRPE(startInd) - bruchsILM(startInd);
            bruchsILM(startInd:endInd) = bruchsRPE(startInd:endInd) - difference;
        end

        % Determine whether to use the ILM or RPE convex hull indices
        validInd = find(~(nanILMind & nanRPEind));
        medianDiff = median(bruchsRPE(validInd) - bruchsILM(validInd));
        bruchsILM = bruchsILM + medianDiff;

        skip = 0;
        if bruchsILM(validInd(1)) - bruchsRPE(validInd(1)) > 0
            leftInd = validInd(1) : find(bruchsILM(validInd) - bruchsRPE(validInd) <= 0,1,'first') - 1;
            xLeft = 1:length(leftInd);
            yLeft = fliplr(bruchsILM(leftInd) - bruchsRPE(leftInd));
            if length(yLeft) > 2 && sum(yLeft > 2*minSpacing) > 0
                fit = polyfit(xLeft,yLeft,1);
                if fit(1) >= 0.05
                    bruchs = bruchsILM;
                    skip = 1;
                end
            end
        end
        if ~skip && bruchsILM(validInd(end)) - bruchsRPE(validInd(end)) > 0
            rightInd = find(bruchsILM(validInd) - bruchsRPE(validInd) <= 0,1,'last') + 1 : validInd(end);
            xRight = 1:length(rightInd);
            yRight = bruchsILM(rightInd) - bruchsRPE(rightInd);
            if length(yRight) > 1 && sum(yRight > 2*minSpacing)
                fit = polyfit(xRight,yRight,1);
                if fit(1) >= 0.05
                    bruchs = bruchsILM;
                    skip = 1;
                end
            end
        end
        if ~skip
            bruchs = bruchsRPE;
        end   
        if length(validInd) < length(bruchs)
            bruchs = round(interp1(x(validInd), bruchs(validInd), 1:imageWidth, 'linear', 'extrap'));        
        end
    end
    
    % Make sure line is not out of the image bounds
    bruchs(bruchs < 1) = 1;
    bruchs(bruchs > imageHeight) = imageHeight;
    
    % Flatten the image based on the line
    [image, pixelShift, invalidIndices] = flattenImage(image,bruchs);
end