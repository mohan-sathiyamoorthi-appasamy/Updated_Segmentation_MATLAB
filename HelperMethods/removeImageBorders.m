%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%  removeImageBorders.m
%
%  Remove borders of a particular pixel value. This is useful for images
%  that have been registered.
%
%--------------------------------------------------------------------------
%
%  function [image, borderImage, borderLines] = removeImageBorders( ...
%      image, borderValues, replaceType)
%
%  INPUT PARAMETERS:
%
%       image - Image of size (imageHeight x imageWidth)
%
%       borderValues - An array of pixel values considered to be a border
%                      value
%
%       replaceType - The type of replacement to make
%
%               [1] = Mirror image of the non-boundary region
%               [2] = Replication of the outermost non-boundary pixels
%
%       borderType - [0] = all (top, bottom, left, right) - default
%                    [1] = top and bottom only
%                    [2] = left and right only
%
%  RETURN VARIABLES:
%
%       image - Image of size (imageHeight x imageWidth) with the borders
%               replaced
%
%       borderImage - A binary image of size (imageHeight x imageWidth)
%                     with borders = 1 and non-borders = 0
%
%       borderLines - A matrix of size (2 x imageWidth). The first row
%                     contains the y values of the top border of the image
%                     and the second row contains the y values of the
%                     bottom border of the image
%
%--------------------------------------------------------------------------
%
%  Author:          Stephanie Chiu
%  Institution:     Duke University
%  Date Created:    2010.03.22
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [image, borderImage, borderLines] = removeImageBorders( ...
    image, borderValues, replaceType, borderType)

    %----------------------------------------------------------------------
    %  Initialize missing input parameters
    %----------------------------------------------------------------------

    if nargin < 3 || isempty(replaceType)
        replaceType = 1;
    end
    if nargin < 4 || isempty(borderType)
        borderType = 0;
    end
        
    %----------------------------------------------------------------------
    %  Validate input parameters
    %----------------------------------------------------------------------
    
    if isempty(image)
        error('Image cannot be empty');
    end

    image = double(image);
    imageSize = size(image);
    imageWidth = imageSize(2);
    
    
    %----------------------------------------------------------------------
    %  Look for boundaries
    %----------------------------------------------------------------------
    
    borderLines = NaN(2,imageWidth);
    borderImage = false(imageSize);
    
    %
    %  First iteration searches through each column of the image, 
    %  second iteration searches through each row of the image,
    %  looking for the valid region (the region inside the borders)
    %
    for i = 1:2
        
        if borderType == 2
            continue;
        end
        
        %
        %  Search through each column of the image, looking for non-border
        %  regions
        %
        imageHeight = size(image,1);
        imageWidth = size(image,2);
    
        for iColumn = 1:imageWidth

            column = image(:,iColumn);
            borderColumn = zeros(size(column));

            % Locate where the border ends on the top of the image, and
            % where it starts on the bottom of the image
            for value = borderValues
                borderColumn(column == value) = 1;
            end

            startIndex = find(borderColumn ~= 1, 1, 'first');
            endIndex = find(borderColumn ~= 1, 1, 'last');

            % The full column is a border, so move on
            if isempty(startIndex) && isempty(endIndex)
                if i == 1
                    borderLines(1,iColumn) = imageHeight;
                    borderLines(2,iColumn) = 1;
                end
                continue;
            end                

            %--------------------------------------------------------------
            %  Address the top border
            %--------------------------------------------------------------
            
            % If no border was found at the top of the image, then move on
            if isempty(startIndex) || startIndex == 1
                if i == 1
                    borderLines(1,iColumn) = NaN;
                end
                
            % Otherwise a border was found
            else
                borderIndices = 1:startIndex-1;
                
                % Replace the border with the first non-border pixel
                if replaceType == 2
                    image(borderIndices,iColumn) = image(startIndex,iColumn);  
                    
                % Otherwise replace the border with the mirror image of the
                % non-border pixels
                else
                    startCol = startIndex;
                    endCol = startCol + length(borderIndices) - 1;
                    
                    if endCol <= imageHeight
                        image(borderIndices,iColumn) = flipud(image(startCol:endCol,iColumn));
                        
                    % During the first iteration, if there arent enough
                    % non-border pixels for mirror imaging, then save it
                    % for the next iteration
                    elseif i == 1
                        image(borderIndices,iColumn) = borderValues(1);
                    
                    % If there are not enough valid non-border pixels for
                    % the mirror image, then just duplicate the last pixel
                    else                        
                        replaceCol = image(startCol:imageHeight,iColumn);
                        missingLength = length(borderIndices) - length(replaceCol);
                        replaceCol = [replaceCol; replaceCol(end)*ones(missingLength,1)];
                        image(borderIndices,iColumn) = flipud(replaceCol);
                    end
                end
            
                % Assign the top border location for the given column
                if i == 1
                    borderLines(1,iColumn) = startIndex-1;
                end
                borderImage(1:startIndex-1,iColumn) = 1;
            end

            %--------------------------------------------------------------
            %  Address the bottom border
            %--------------------------------------------------------------
            
            % If no border was found at the bottom of the image, then move 
            % on
            if isempty(endIndex) || endIndex == imageHeight
                if i == 1
                    borderLines(2,iColumn) = NaN;
                end
                
            % Otherwise a border was found
            else
                borderIndices = endIndex+1:imageHeight;
                
                % Replace the border with the first non-border pixel
                if replaceType == 2
                    image(borderIndices,iColumn) = image(endIndex,iColumn);  
                    
                % Otherwise replace the border with the mirror image of the
                % non-border pixels
                else
                    endCol = endIndex;
                    startCol = endCol - length(borderIndices) + 1;

                    if startCol >= 1
                        image(borderIndices,iColumn) = flipud(image(startCol:endCol,iColumn));
                        
                    % During the first iteration, if there arent enough
                    % non-border pixels for mirror imaging, then save it
                    % for the next iteration
                    elseif i == 1
                        image(borderIndices,iColumn) = borderValues(1);
                    
                    % If there are not enough valid non-border pixels for
                    % the mirror image, then just duplicate the last pixel
                    else                        
                        replaceCol = image(1:endCol,iColumn);
                        missingLength = length(borderIndices) - length(replaceCol);
                        replaceCol = [replaceCol(1)*ones(missingLength,1);replaceCol];
                        image(borderIndices,iColumn) = flipud(replaceCol);
                    end
                end
            
                % Assign the bottom border location for the given column
                if i == 1
                    borderLines(2,iColumn) = endIndex+1;
                end
                borderImage(endIndex+1:end,iColumn) = 1;
            end
        end
                
        if borderType == 1
            break;
        end
        
        image = image';
        borderImage = borderImage';
    end
end