%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%  readHeidelbergFile.m
%
%  Reads a Heidelberg raw data file (.VOL) and saves each Bscan as a Tiff 
%  image
%  
%--------------------------------------------------------------------------
%
%  function[] = readVolFile(filename, outputDir, nBits);
%
%  INPUT PARAMETERS:
%
%       filename - file name of raw data file to read
%
%       outputDir - (optional) path to save images
%                    default = [pwd '\' filename(1:end-4) '_TIFFs'] 
%
%       nBits - (optional) bitdepth of output images (8 or 16) 
%                default = 16 
%
%  RETURN VARIABLES:
%
%       imageFiles - A cell array of the image files that were saved
%
%
%  NOTES:
%
%       adapted from function: ReadBscanDataFromHeidelbergRawData
%       greatly simplified, since we do not care about Bscan header info 
%       here.
% 
%       need to determine appropriate scaling before converting to int.
%       Currently I am half following the advice in the Heidelberg export
%       doc.  They recommend 256*(img)^1/4 to create 8-bit image
%       I am doing [2^15-1]*(img)^1/2 to create 16-bit image
%
%  (C) Peter Nicholas 8/15/2008
%
%--------------------------------------------------------------------------
%
%  Author:          Peter Nicholas
%  Date Created:    8/15/2008
%  Institution:     Duke University
%
%  Modifications:
%
%  - 2010.02.12  Stephanie Chiu (stephanie.chiu@duke.edu)
%       * Changed filename from HeidelbergRaw2Tiff to ReadVolFile
%       * Changed parameter names and organized code and comments
%       * Added waitbar and return value
%       * Change the filename format of the saved images
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function imageFiles = readHeidelbergFile(filename, outputDir, nBits)

    %----------------------------------------------------------------------
    % Validate input parameters
    %----------------------------------------------------------------------
    
    if nargin < 2 || isempty(outputDir)
        outputDir = [];
    end
        
    if nargin < 3
        nBits = 16;
    elseif nBits ~= 8 && nBits ~= 16
    	error('nBits = %d is not an allowed value. Allowed values are 8, 16.', nBits);
    end

    %----------------------------------------------------------------------
    % Parse the raw data file header
    %----------------------------------------------------------------------
    
    header = parseHeidelbergRawDataHeader(filename);

    %
    %  Now we are ready to make the default directory names
    %    
    [path, name] = fileparts(filename);
    
    xWidth  = header.BScanPixelsX * header.BScanPixelXmm;
    yWidth  = header.NumBScans*header.BScanDistance;

    if isempty(outputDir)
        file = sprintf('%s_%s_%1.1fx%1.1fmm_%d_scans', ...
            name, header.Eye(1:2), xWidth, yWidth, header.NumBScans);
        
        outputDir = fullfile(pwd, file, 'TIFFs', sprintf('%dbitTIFFs\', nBits));
        
    elseif ~strcmp(outputDir(end),'\')
        outputDir(end+1) = '\'; 
    end
    
    outputDir = sprintf('%s%s\\', outputDir, name);
        
    if ~exist(outputDir,'dir')
        mkdir(outputDir);
    end

    %
    %  Define constants for calculating file offset position
    %
    headerByteSize = 2048;
    sloByteSize = header.SizeXSlo * header.SizeYSlo;
    bScanByteSize =  header.BScanPixelsX * header.BScanPixelsZ * 4;
    bScanBlockSize = bScanByteSize + header.BScanHdrSize;


    fid = fopen(filename,'rb');
    
    if fid < 0
        error(['error opening file: ' filename'])
    end
    
    %----------------------------------------------------------------------
    %  Loop over all bScans in the raw data file
    %----------------------------------------------------------------------
    
    imageFiles = cell(header.NumBScans,1);
    
    formatString = strcat( ...
        '%s%.', num2str(length(num2str(header.NumBScans))), 'i.tif');
    
    hWaitbar = waitbar(0,'Loading .VOL File'); 
    
    for iScan = 1:header.NumBScans
        
        %
        %  Only update every 10 frames
        %
        if mod(iScan,10) == 0
            waitbar(iScan/header.NumBScans, hWaitbar); 
        end
        
        %
        %  We do not care about BScan headers.  Computer the offset (in
        %  bytes) of the iScan-th BScan header
        %
        offset = headerByteSize + sloByteSize + bScanBlockSize*(iScan-1);
        
        %
        %  Compute the offset (in bytes) of the iScan-th bScan image and
        %  set the pointer to this location
        %
        offset = offset + header.BScanHdrSize;
        
        if fseek(fid, offset, 'bof')
            error('Error setting the file pointer to %d in file: ', offset, filename); 
        end
        
        %
        %  Read BScan Image Data
        %
        image = readBScan(fid, header.BScanPixelsX, header.BScanPixelsZ);
        imageName = sprintf(formatString, outputDir, iScan);
        
        switch nBits 
            case 16
                image = uint16((2^15-1)*sqrt(image));
            case 8
                image = uint8((2^8-1)*(image).^(1/4));
        end
        
        imageFiles{iScan} = imageName;
        imwrite(image, imageName);
    end
    
    close(hWaitbar);
    fclose(fid);
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%  readBScan()
%
%  Helper function to read a single bScan.  Assumes the fid is at the start
%  of a bScan of size (scanHeight x scanWidth)
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function bScan = readBScan(fid, scanHeight, scanWidth)
    bScan = zeros(scanHeight, scanWidth);
    temp = fread(fid, length(bScan(:)), 'float');
    bScan(:) = single(temp);
    bScan = transpose(bScan);
end