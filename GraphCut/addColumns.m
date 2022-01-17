%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%  addColumns.m
%
%  Adds columns to each side of the vector or matrix
%
%--------------------------------------------------------------------------
%
%  function object = addColumns(object, numColumns)
%
%  INPUT PARAMETERS:
%
%       object - A [m x n] matrix or vector to add columns to
%
%       numColumns - Number of columns to add to each side
%
%       fillValue - (Optional) Value to fill the new columns with. Specify
%                   -1 to repeat the left and right-most columns. 
%                   [Default = -1]
%
%  OUTPUT VARIABLES:
%
%       object - A [m x (n + 2)] matrix with columns added to either side
%                of the object
%
%--------------------------------------------------------------------------
%
%  Author:          Stephanie Chiu
%  Institution:     Duke University
%  Date Created:    2010.01.21
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function object = addColumns(object, numColumns, fillValue)
    
    %----------------------------------------------------------------------
    %  Initialize missing input parameters
    %----------------------------------------------------------------------
    
    if nargin < 3
        fillValue = -1;
    end
    
    %----------------------------------------------------------------------
    %  Validate input parameters
    %----------------------------------------------------------------------

    if isempty(object)
        error('Layers cannot be empty');
    end

    %----------------------------------------------------------------------
    %  Add columns to each side, duplicating the rightmost and leftmost
    %  values
    %----------------------------------------------------------------------

    if fillValue == -1
        leftColumns = repmat(object(:,1), 1, numColumns);
        rightColumns = repmat(object(:,end), 1, numColumns);
    else
        leftColumns = fillValue*ones(size(object,1),numColumns);
        rightColumns = leftColumns;
    end
    object = [leftColumns, object, rightColumns];
end