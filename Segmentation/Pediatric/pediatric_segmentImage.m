%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%  pediatric_segmentImage.m
%
%  Segments retinal layers on an OCT image
%
%--------------------------------------------------------------------------
%
%  function layers = pediatric_segmentImage(image, params)
%
%  INPUT PARAMETERS:
%
%       image - OCT image to segment
%
%       params - (Optional) SegmentImageParameters object containing all of
%                 the constants used in this function.  Default values are
%                 set by the pediatric_getParameters function
%
%  OUTPUT VARIABLES:
%
%       layers - A (numLayers x imageWidth) matrix of the segmented layers
%
%--------------------------------------------------------------------------
%
%  Author:          Stephanie Chiu
%  Institution:     Duke University
%  Date Created:    2011.04.22
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function layers = pediatric_segmentImage(image, params)
    
    
    %----------------------------------------------------------------------
    %  Initialize missing input parameters
    %----------------------------------------------------------------------
    
    if nargin < 2
        params = [];
    end
    
    
    %----------------------------------------------------------------------
    %  Validate input parameters
    %----------------------------------------------------------------------
    
    %
    % Validate the image is a 2D, grayscale image
    %
    if isempty(image)
        error('Image cannot be empty');
    end
    
    nDimensions = size(image,3);
    
    if nDimensions > 3
        image(:,:,4:nDimensions) = [];
    end
    
    if nDimensions == 3
        image = rgb2gray(image);
    end
    
    %
    % Validate the parameters
    %
    if isempty(params)
        params = pediatric_getParameters();
    end
    
    image = double(image);
    originalSize = size(image);
    
    
    %----------------------------------------------------------------------
    %  Make the registered black boundaries invalid
    %----------------------------------------------------------------------
    
    [image, invalidImage] = removeImageBorders(image, [0,255]);
    originalImage = image;
    originalInvalidImage = invalidImage;
    
    
    %----------------------------------------------------------------------
    %  Resize the image to reduce computational complexity
    %----------------------------------------------------------------------
                   
    % Rescale the lateral and axial resolutions
    xResizeScale = params.LATERAL_RESOLUTION / params.X_RESOLUTION;
    yResizeScale = params.AXIAL_RESOLUTION / params.Y_RESOLUTION;
    
    lateralRes = params.X_RESOLUTION;
    axialRes = params.Y_RESOLUTION;
    
    % Resize the image
    image = imresize(image,'scale', [yResizeScale, xResizeScale]);
    image = normalizeValues(image,0,255);
    resizedSize = size(image);
    
    % Resize the invalid image
    invalidImage = imresize(invalidImage,'scale', [yResizeScale, xResizeScale]);
    invalidImage(invalidImage <= 0.5) = 0;
    invalidImage(invalidImage > 0.5) = 1;
    invalidIndices = find(invalidImage);
  

    %----------------------------------------------------------------------
    %  Get the black and white image of the hyper-reflective reitnal layers
    %----------------------------------------------------------------------

    % Get a black and white image of the hyper-reflective bands
    [bwImage, borders] = pediatric_getBwImage( ...
        image, axialRes, lateralRes, invalidIndices, params.getBwImageParams);

    rpeTop = borders(3,:);
    rpeBottom = borders(4,:);
    ilm = borders(1,:);
    
    
    %----------------------------------------------------------------------
    % Flatten the image based on bruchs
    %----------------------------------------------------------------------
    
    invalidImage = zeros(size(image));
    invalidImage(invalidIndices) = 1;
    
    [image,pixelShift,invalidIndices,offset] = pediatric_flattenImage(image, rpeBottom);
    rpeTop = flattenImage(rpeTop + offset, -pixelShift);
    ilm = flattenImage(ilm + offset, -pixelShift);
    
    invalidImage(invalidIndices) = 1;
    invalidIndices = find(invalidImage);

    
    %----------------------------------------------------------------------
    %  Segment layers
    %----------------------------------------------------------------------

    layers = pediatric_graphCut( ...
        image, ...
        axialRes, ...
        lateralRes, ...
        rpeTop, ...
        ilm, ...
        invalidIndices, ...
        1, ...
        params.graphCutParams);
    
    layers = layers - offset;

    
    %----------------------------------------------------------------------
    %  Unflatten the layers if they were flattened
    %----------------------------------------------------------------------
    
    for iLayer = 1:size(layers,1);  
        layers(iLayer,:) = flattenImage(layers(iLayer,:), pixelShift);
    end
    

    %----------------------------------------------------------------------
    %  Upsample the layers to match the original image size
    %----------------------------------------------------------------------
    
    layers = resampleLayers(layers,resizedSize,originalSize);
    
    
    %----------------------------------------------------------------------
    %   Perform layer smoothing
    %----------------------------------------------------------------------
      
    layers = smoothLayers( ...
        layers, ...
        originalSize(1), ...
        params.graphCutParams.SMOOTHING_CORRECTION);
    
    
    %----------------------------------------------------------------------
    %   Ignore the colums of the cut where the image in valid
    %----------------------------------------------------------------------

    invalidIndices = find(originalInvalidImage);
    for iLayer = 1:size(layers,1)
        x = 1:originalSize(2);
        invalidInd = intersect(sub2ind(originalSize,layers(iLayer,:),x), invalidIndices);
        [yInvalid,xInvalid] = ind2sub(originalSize,invalidInd);
        xInvalid = unique(xInvalid);
        layers(iLayer,xInvalid) = NaN;
    end


    %----------------------------------------------------------------------
    %   Segment cysts
    %----------------------------------------------------------------------

    if params.otherParams.SEGMENT_CYSTS  
        cystParams = pediatric_cysts_getParameters();
        cystParams.LATERAL_RESOLUTION = params.LATERAL_RESOLUTION;
        cystParams.AXIAL_RESOLUTION = params.AXIAL_RESOLUTION;
        cystParams.otherParams.INVALID_IMAGE = originalInvalidImage;
        cystParams.otherParams.LAYERS = layers;
        
        cystImage = pediatric_cysts_segmentImage(originalImage,cystParams);
        layers = {layers,cystImage};
    end

    return;
end