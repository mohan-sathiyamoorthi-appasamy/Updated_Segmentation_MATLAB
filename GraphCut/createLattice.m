%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%  createLattice.m
%
%  Creates pairs of nodes to be connected by edges.  Assumes an 8-neighbor
%  connectivity
%
%--------------------------------------------------------------------------
%
%  function edges = createLattice(imageSize)
%
%  INPUT PARAMETERS:
%
%       imageSize - A (1x2) vector containng the image size, [height width]
%
%  RETURN VARIABLES:
%
%       edges - a two-column matrix containing pairs of connected nodes
%
%--------------------------------------------------------------------------
%
%  Author:          Stephanie Chiu
%  Date Created:    2009.05.22
%  Institution:     Duke University
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function edges = createLattice(imageSize)

    %----------------------------------------------------------------------
    %  Initialize missing input parameters
    %----------------------------------------------------------------------
    
    imageHeight = imageSize(1);
    imageWidth = imageSize(2);

    %----------------------------------------------------------------------
    %  Get edge pairs
    %----------------------------------------------------------------------
    
    % Create a matrix containing the indices of each pixel
    indexMatrix = reshape(1:imageHeight*imageWidth, imageHeight, imageWidth);
    
    % Get (undirectional) vertical edges
    startNodes = indexMatrix(1:end-1,:);
    endNodes = indexMatrix(2:end,:);    
    edges = [startNodes(:), endNodes(:)];
    
    % Get (undirectional) horizontal edges
    startNodes = indexMatrix(:,1:end-1);
    endNodes = indexMatrix(:,2:end);
    edges = [edges; startNodes(:), endNodes(:)];
    
    % Get (undirectional) diagonal edges
    startNodes = indexMatrix(1:end-1,1:end-1);
    endNodes = indexMatrix(2:end,2:end);
    edges = [edges; startNodes(:), endNodes(:)];

    startNodes = indexMatrix(2:end,1:end-1);
    endNodes = indexMatrix(1:end-1,2:end);
    edges = [edges; startNodes(:), endNodes(:)];
end
