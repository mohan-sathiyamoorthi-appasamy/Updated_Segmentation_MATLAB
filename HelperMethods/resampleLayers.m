%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%  resampleLayers.m
%
%  Resample the layers to the specified width
%
%--------------------------------------------------------------------------
%
%  function layers = resampleLayers(layers, originalSize, newSize)
%
%  INPUT ARGUMENTS:
%
%       layers - A (numLayers x imageWidth) matrix of the segmented 
%                layers
%
%       originalSize - A vector of length 2 specifying the original size of
%                      the image, in the form [imageHeight, imageWidth] 
%
%       newSize - A vector of length 2 specifying the size of the image
%                 to resample to, in the form [newHeight, newWidth] 
%
%  RETURN VARIABLES:
%
%       layers - A (numLayers x newWidth) matrix of the segmented 
%                layers
%
%--------------------------------------------------------------------------
%
%  Author:          Stephanie Chiu
%  Institution:     Duke University
%  Creation Date:   2011.09.02
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function layers = resampleLayers(layers, originalSize, newSize)

    %----------------------------------------------------------------------
    % Calculate the scaling needed to upsample
    %----------------------------------------------------------------------

    scale = newSize ./ originalSize;
    
    if all(scale == 1)
        return;
    end
    
    
    %----------------------------------------------------------------------
    %  Upsample in the y direction
    %----------------------------------------------------------------------

    layers = round(layers * scale(1));
    
    
    %----------------------------------------------------------------------
    % Upsample each layer in the x direction using interpolation
    %----------------------------------------------------------------------
    
    nLayers = size(layers,1);
        
    if scale(2) < 1
        x = round(linspace(1,originalSize(2),newSize(2)));
        y = layers;
        layers = y(:,x);
    else
        newWidth = newSize(2);
        x = 1:newWidth;
        y = layers;

        layers = NaN(nLayers,newWidth);
        ind = round(1:scale(2):newWidth);
        ind(end) = newWidth;
        layers(:,ind) = y;

        % Loop through each layer
        for iLayer = 1:nLayers
            layer = layers(iLayer,:);

            if all(isnan(layer))
                continue;
            end

            % Interpolate
            validInd = ~isnan(layer);
            invalidInd = ~validInd;
            invalidInd(1:find(invalidInd == 0,1,'first')) = 0;
            invalidInd(find(invalidInd == 0,1,'last'):end) = 0;

            layer(invalidInd) = round(interp1( ...
                x(validInd),layer(validInd),x(invalidInd),'spline'));

            % Make sure the layers do not cross
            if iLayer > 1
                invInd = (layer - layers(iLayer-1,:)) < 0;
                layer(invInd) = layers(iLayer-1,invInd);
            end

            layers(iLayer,:) = layer;
        end
    end
end