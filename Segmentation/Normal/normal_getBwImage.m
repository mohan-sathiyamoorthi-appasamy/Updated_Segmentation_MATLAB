%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%  normal_getBwImage.m
%
%  Gets a binary image isolating the hyper-reflective layers of the image
%
%--------------------------------------------------------------------------
%
%  function [bwImage, borders] = normal_getBwImage( ...
%       image, axialRes, lateralRes, invalidIndices, params)
%
%  INPUT PARAMETERS:
%
%       image - Bscan of the retina (imageHeight x imageWidth)
%
%       axialRes - Axial (vertical) resolution of the image in um/pixel
%
%       lateralRes - Lateral (horizontal) resoution of the image in
%                    um/pixel
%
%       invalidIndices - Vector containing indices of the image that should
%                        not be included as part of the valid image region
%
%       params - (Optional) FindRpeParameters object containing all of the
%                 constants used in this function.  Default values are set
%                 in the FindRpeParameters class constructor
%
%  RETURN VARIABLES:
%
%       bwImage - A [imageHeight x imageWidth] binary image containing two
%                 white bands roughly corresponding to the two brightest
%                 bands of the retina
%
%       borders - A [4 x imageWidth] matrix with each row containing the
%                 y-values of the edges of the hyper-reflective bands in 
%                 the bwImage 
%
%--------------------------------------------------------------------------
%
%  Author:          Stephanie Chiu
%  Institution:     Duke University
%  Date Created:    2010.02.07
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [bwImage, borders] = normal_getBwImage( ...
    image, axialRes, lateralRes, invalidIndices, params)

    %----------------------------------------------------------------------
    %  Initialize missing input parameters
    %----------------------------------------------------------------------
    
    if nargin < 4
        invalidIndices = [];
    end
    
    if nargin < 5
        params = [];
    end
    
    
    %----------------------------------------------------------------------
    %  Validate input parameters
    %----------------------------------------------------------------------
    
    if isempty(image)
        error('Image cannot be empty');
    end
    
    if size(image, 3) > 1
        error('Image must be 2D');
    end
    
    if isempty(params)
        params = normal_getParameters();
        params = params.getBwImageParams;
    end


    %----------------------------------------------------------------------
    %  Process the image
    %----------------------------------------------------------------------
    
    image = double(image);
    imageSize = size(image);
    imageHeight = imageSize(1);
    imageWidth = imageSize(2);
    
    %
    %  Smooth the image to reduce noise
    %
    xFilterSize = round(params.X_FILTER_SIZE / lateralRes);
    yFilterSize = round(params.Y_FILTER_SIZE / axialRes);
    filter = fspecial('gaussian',[yFilterSize,xFilterSize],params.SIGMA);
    
    smoothImage = blurImage(image,filter);
    
    
    %----------------------------------------------------------------------
    %  Generate a binary image of the hyper-reflective bands
    %----------------------------------------------------------------------
    
    %
    %  Find the edges of the image
    %         
    bwImage = [zeros(1,imageWidth);diff(smoothImage)];
    bwImage(bwImage <= 0.5) = 0;
    bwImage(bwImage > 0.5) = 1;   
    bwImage(invalidIndices) = 0;

    %
    %  Open any gaps in the clusters
    %
    xStrelSize = round(params.X_STREL_SIZE / lateralRes);
    yStrelSize = round(params.Y_STREL_SIZE / axialRes);
    structuringElement = strel('rectangle',[yStrelSize, xStrelSize]);
    bwImage = imopen(bwImage, structuringElement);

    %
    %  Remove all clusters smaller than a certain size
    %
    clusters = bwconncomp(bwImage);
    minClusterSize = params.MIN_CLUSTER_SIZE / (axialRes*lateralRes);
    
    for iCluster = 1:clusters.NumObjects
        clusterInd = clusters.PixelIdxList{iCluster};
        clusterSize = length(clusterInd);
        if clusterSize < minClusterSize
           bwImage(clusterInd) = 0;
        end
    end

    %
    %  Close any gaps in the clusters
    %
    bwImage = imclose(bwImage, structuringElement);
    
    
    %----------------------------------------------------------------------
    %  Get the borders of the two hyper-reflective bands
    %----------------------------------------------------------------------
    
    % Add an additional column to each side of the image
    bwImage = addColumns(bwImage, 1);
    newImageSize = size(bwImage);
    newImageWidth = newImageSize(2);
    
    % Get the weighting matrices
    weightingMatrices = bwWeightingMatrix(bwImage,[],params.weightingMatrixParams);

    % Cut each border
    lines = NaN(params.NUM_BORDERS,newImageWidth);
    invalidIndices = [];
    numBorders = params.NUM_BORDERS;
    
    for iBorder = 1:numBorders

        % Exclude the previous borders from the region to cut
        if iBorder > 1
            x = 2:(newImageWidth-1);
            y = lines(iBorder-1,x);
            removeInd = (y == 1 | y == imageHeight);
            x(removeInd) = [];
            y(removeInd) = [];
            invalidIndices = [invalidIndices, sub2ind(newImageSize, y, x)];
        end
        
        if iBorder < params.NUM_BORDERS
            yBottom = imageHeight*ones(1,newImageWidth);
        else
            yBottom = nanmax(lines);
        end

        % Get the valid region to cut
        regionIndices = getRegion( ...
            newImageSize, ...
            ones(1,newImageWidth), ...
            yBottom, ...
            0, ...
            0, ...
            invalidIndices);

        % Cut the region to get the border
        lines(iBorder,:) = cutRegion( ...
            newImageSize, ...
            regionIndices, ...
            weightingMatrices{mod(iBorder,2)+1});
    end
    
    % Remove the added columns
    bwImage = bwImage(:,2:end-1);
    lines = lines(:,2:end-1);
    
    % Sort the lines in ascending order
    oddIndices = 1:2:params.NUM_BORDERS;
    evenIndices = 2:2:params.NUM_BORDERS;
    oddSortOrder = sortrows([nanmean(lines(oddIndices,:),2), (1:length(oddIndices))']);
    evenSortOrder = sortrows([nanmean(lines(evenIndices,:),2), (1:length(evenIndices))']);
    bottomBorders = lines(oddIndices(oddSortOrder(:,2)),:);
    topBorders = lines(evenIndices(evenSortOrder(:,2)),:);
    
    borders(oddIndices,:) = topBorders;
    borders(evenIndices,:) = bottomBorders;
    
    % Replace extrapolated points (those that do not lie along a
    % hyper-reflective band) with NaN
    for iBorder = 1:params.NUM_BORDERS
        border = borders(iBorder,:);
        if ~mod(iBorder,2)
            border = border - 1;
            border(border < 1) = 1;
        end
        ind = sub2ind(imageSize, border, 1:imageWidth);
        [yStart,xStart] = ind2sub(imageSize, ind(find(bwImage(ind), 1, 'first')));
        [yEnd,xEnd] = ind2sub(imageSize, ind(find(bwImage(ind), 1, 'last')));
        borders(iBorder,:) = NaN(1,imageWidth);
        borders(iBorder,xStart:xEnd) = border(xStart:xEnd);
    end
end