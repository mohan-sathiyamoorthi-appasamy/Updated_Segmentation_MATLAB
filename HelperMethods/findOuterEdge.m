function edgeImage = findOuterEdge(bwImage)

    imageSize = size(bwImage);
    imageHeight = imageSize(1);
    imageWidth = imageSize(2);
    maxIndex = imageHeight*imageWidth;
    
    edgeImage = bwImage;
    clusterIndices = find(bwImage)';
    
    topIndices = 1:imageHeight:maxIndex;
    bottomIndices = imageHeight:imageHeight:maxIndex;
    
    for iCluster = clusterIndices
        if iCluster > imageHeight
            edgeImage(iCluster - imageHeight) = 1;
        end
        if iCluster <= maxIndex - imageHeight
            edgeImage(iCluster + imageHeight) = 1;
        end
        if sum(iCluster == topIndices) == 0
            edgeImage(iCluster - 1) = 1;
        end
        if sum(iCluster == bottomIndices) == 0
            edgeImage(iCluster + 1) = 1;
        end
    end    
    
    edgeImage = edgeImage & ~bwImage;
end