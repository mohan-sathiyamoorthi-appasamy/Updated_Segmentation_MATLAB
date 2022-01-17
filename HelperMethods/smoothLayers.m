%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%  smoothLayers.m
%
%  Smooths the layers according to the smoothness value input
%
%--------------------------------------------------------------------------
%
%  function layers = smoothLayers( ...
%      layers, ...
%      imageHeight, ...
%      smoothness, ...
%      roundLayers)
%
%  INPUT PARAMETERS:
%
%       layers - A (nLayers x scanWidth x nScans) matrix containing
%                segmented layer maps to smooth
%
%       imageHeight - The height of the image (number of rows)
%
%       smoothness - A (1 x nLayers) vector containing a value from 0-1
%                    indicating the smoothness, where 0 means no smoothing
%
%       roundLayers - True to round the values to an integer value,
%                     false otherwise [Default = 1]
%
%  Output Parameters:
%
%       layers - A (nLayers x scanWidth x nScans) matrix containing the
%                smoothed layer maps
%
%--------------------------------------------------------------------------
%
%  Author:          Stephanie Chiu
%  Institution:     Duke University
%  Date Created:    2009.12.15
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


function layers = smoothLayers( ...
    layers, ...
    imageHeight, ...
    smoothness, ...
    roundLayers)

    %----------------------------------------------------------------------
    %  Initialize missing input parameters
    %----------------------------------------------------------------------
    
    if nargin < 4
        roundLayers = 1;
    end

    
    %----------------------------------------------------------------------
    %  Verify input parameters
    %----------------------------------------------------------------------

    if isempty(smoothness)
        error('''smoothness'' cannot be empty');
    end
    
    nLayers = size(layers, 1);
    
    % If only one smoothness value was given, use that value for all layers
    if length(smoothness) == 1
        smoothness = smoothness * ones(1,nLayers);
        
    % If not enough smoothness values were given, do not smooth the layers
    % not given a value
    elseif length(smoothness) < nLayers
        temp = smoothness;
        smoothness = zeros(1,nLayers);
        smoothness(1:length(temp)) = temp;
    end
    
    
    %----------------------------------------------------------------------
    %  Smooth each layer individually
    %----------------------------------------------------------------------

    for iLayer = 1:nLayers

        layer = layers(iLayer,:);
        
        if smoothness(iLayer) > 0
            layer = smooth(layer, smoothness(iLayer), 'moving')';
            
            if roundLayers
                layer = round(layer);
            end
        end
        
        % Take care of out of bounds scenaries
        layer(layer < 1) = 1;
        layer(layer > imageHeight) = imageHeight;
        
        % Make sure the lower layers do not cross the layers above it
        if (iLayer > 1)
            crossIndices = (layer - layers(iLayer-1,:)) < 0;
            layer(crossIndices) = layers(iLayer-1, crossIndices);
        end
        
        layers(iLayer,:) = layer;
    end
end