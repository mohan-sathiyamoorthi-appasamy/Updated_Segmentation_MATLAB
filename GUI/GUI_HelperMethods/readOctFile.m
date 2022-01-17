function imageFiles = readOctFile(file, saveDir)


%% File Information 
% Oct_Reader_Current.m
% Created by:   Bradley A. Bower
%               Bioptigen, Inc.
%               bbower@bioptigen.com

%% Revision History
% 2006.12.14    Created file. 
% 2006.12.15    Completed and tested file to support Bioptigen v1.4.  
% 2007.03.23    Modified to read the timestamp on each frame
% 2007.06.12    Updated with 2 new file tags for v1.7
% 2008.02.26    Updated to read data created with InVivoVue Clinic
% 2008.10.09    Modified from Oct_Reader_IVVC.m to extract a directory of
% .oct files. 
% 2008.10.29    Updated to remove timestamp--there's an error with how the
% timestamped images are loaded into ImageJ and this is a temporary
% work-around. Updated frame timestamp to pad millisecond with 0's as
% appropriate. 
% 2009.1.9	   Renamed to Oct_Reader_Current.m from Oct_ExtractDirectory_NoTimestamp. No code changes.  
% 2009.01.10    Modified by Stephanie Chiu (stephanie.chiU@duke.edu) to 
%               be able to run on a gui
%               - Turned the m-file into a function
%               - The 'gray' colormap variable does not exist when running 
%                 in a GUI, so it had to be self defined below

%% Notes
% 2006.12.15
% This software should work with Bioptigen software versions 1.4 and
% later. It has not been tested for earlier versions. As the header
% content has changed with later versions, this software may not work with
% data acquired with any version earlier than v1.4. If the header content is 
% greatly changed for later file versions, the software will require 
% updates to reflect those changes. 

% 2007.03.23 
% Information on the SYSTEMTIME structure can be found at: 
% http://www.cs.rpi.edu/courses/fall01/os/systemtime.html
% Information on writing C functions in Matlab: 
% http://cnx.org/content/m12348/latest/

%% Initialize constants

gray=[ ...
    0         0         0;
    0.0159    0.0159    0.0159;
    0.0317    0.0317    0.0317;
    0.0476    0.0476    0.0476;
    0.0635    0.0635    0.0635;
    0.0794    0.0794    0.0794;
    0.0952    0.0952    0.0952;
    0.1111    0.1111    0.1111;
    0.1270    0.1270    0.1270;
    0.1429    0.1429    0.1429;
    0.1587    0.1587    0.1587;
    0.1746    0.1746    0.1746;
    0.1905    0.1905    0.1905;
    0.2063    0.2063    0.2063;
    0.2222    0.2222    0.2222;
    0.2381    0.2381    0.2381;
    0.2540    0.2540    0.2540;
    0.2698    0.2698    0.2698;
    0.2857    0.2857    0.2857;
    0.3016    0.3016    0.3016;
    0.3175    0.3175    0.3175;
    0.3333    0.3333    0.3333;
    0.3492    0.3492    0.3492;
    0.3651    0.3651    0.3651;
    0.3810    0.3810    0.3810;
    0.3968    0.3968    0.3968;
    0.4127    0.4127    0.4127;
    0.4286    0.4286    0.4286;
    0.4444    0.4444    0.4444;
    0.4603    0.4603    0.4603;
    0.4762    0.4762    0.4762;
    0.4921    0.4921    0.4921;
    0.5079    0.5079    0.5079;
    0.5238    0.5238    0.5238;
    0.5397    0.5397    0.5397;
    0.5556    0.5556    0.5556;
    0.5714    0.5714    0.5714;
    0.5873    0.5873    0.5873;
    0.6032    0.6032    0.6032;
    0.6190    0.6190    0.6190;
    0.6349    0.6349    0.6349;
    0.6508    0.6508    0.6508;
    0.6667    0.6667    0.6667;
    0.6825    0.6825    0.6825;
    0.6984    0.6984    0.6984;
    0.7143    0.7143    0.7143;
    0.7302    0.7302    0.7302;
    0.7460    0.7460    0.7460;
    0.7619    0.7619    0.7619;
    0.7778    0.7778    0.7778;
    0.7937    0.7937    0.7937;
    0.8095    0.8095    0.8095;
    0.8254    0.8254    0.8254;
    0.8413    0.8413    0.8413;
    0.8571    0.8571    0.8571;
    0.8730    0.8730    0.8730;
    0.8889    0.8889    0.8889;
    0.9048    0.9048    0.9048;
    0.9206    0.9206    0.9206;
    0.9365    0.9365    0.9365;
    0.9524    0.9524    0.9524;
    0.9683    0.9683    0.9683;
    0.9841    0.9841    0.9841;
    1.0000    1.0000    1.0000];

    
%% Extract OCT data for current file

if ~exist(file, 'file')
    error('The file %s does not exist', file);
end

[filePath, fileName] = fileparts(file);
fid = fopen(file);

% Output image file information
imagePath = fullfile(filePath, fileName);
imageExtension  = '.tif'; 
        
%
%  Get the folder where the images will be saved, determined
%  based on filename with removed extension
%
if isempty(saveDir)
    saveDir = imagePath;
else
    saveDir = fullfile(saveDir, fileName);
end

%% Read file header
magicNumber         = fread(fid,2,'uint16=>uint16'); 
magicNumber         = dec2hex(magicNumber);  
versionNumber       = fread(fid,1,'uint16=>uint16'); 
versionNumber       = dec2hex(versionNumber); 

keyLength           = fread(fid,1,'uint32');
key                 = char(fread(fid,keyLength,'uint8'));
dataLength          = fread(fid,1,'uint32');
if (~strcmp(key','FRAMEHEADER'))
    error('File Load Error. Error loading frame header');
end

headerFlag          = 0;    % set to 1 when all header keys read
while (~headerFlag)         
    keyLength       = fread(fid,1,'uint32'); 
    key             = char(fread(fid,keyLength,'uint8')); 
    dataLength      = fread(fid,1,'uint32');

    % Read header key information
    if (strcmp(key','FRAMECOUNT'))
        frameCount      = fread(fid,1,'uint32');
    elseif (strcmp(key','LINECOUNT'))
        lineCount       = fread(fid,1,'uint32');  
    elseif (strcmp(key','LINELENGTH'))
        lineLength      = fread(fid,1,'uint32');
    elseif (strcmp(key','SAMPLEFORMAT'))
        sampleFormat    = fread(fid,1,'uint32');        
    elseif (strcmp(key','DESCRIPTION'))
        description     = char(fread(fid,dataLength,'uint8')); 
    elseif (strcmp(key','XMIN'))
        xMin            = fread(fid,1,'double'); 
    elseif (strcmp(key','XMAX'))
        xMax            = fread(fid,1,'double'); 
    elseif (strcmp(key','XCAPTION'))
        xCaption        = char(fread(fid,dataLength,'uint8'));
    elseif (strcmp(key','YMIN'))
        yMin            = fread(fid,1,'double');
    elseif (strcmp(key','YMAX'))
        yMax            = fread(fid,1,'double');        
    elseif (strcmp(key','YCAPTION'))
        yCaption        = char(fread(fid,dataLength,'uint8'));
    elseif (strcmp(key','SCANTYPE'))
        scanType        = fread(fid,1,'uint32');
    elseif (strcmp(key','SCANDEPTH'))
        scanDepth       = fread(fid,1,'double');    
    elseif (strcmp(key','SCANLENGTH'))
        scanLength      = fread(fid,1,'double');        
    elseif (strcmp(key','AZSCANLENGTH'))
        azScanLength    = fread(fid,1,'double');
    elseif (strcmp(key','ELSCANLENGTH'))
        elScanLength    = fread(fid,1,'double');
    elseif (strcmp(key','OBJECTDISTANCE'))
        objectDistance  = fread(fid,1,'double');
    elseif (strcmp(key','SCANANGLE'))
        scanAngle       = fread(fid,1,'double');
    elseif (strcmp(key','SCANS'))
        scans           = fread(fid,1,'uint32');
    elseif (strcmp(key','FRAMES'))
        frames          = fread(fid,1,'uint32');
    elseif (strcmp(key','DOPPLERFLAG'))
        dopplerFlag     = fread(fid,1,'uint32');
    elseif (strcmp(key','CONFIG'))
        config          = fread(fid,dataLength,'uint8'); 
    else
        headerFlag      = 1; 
    end         % if/elseif conditional        
end             % while loop 

%% Read frame data
% Initialize frames in memory, need to modify for mod(lineLength,2)~=0
imageData           = zeros(lineLength,lineCount,'uint16'); 
imageFrame          = zeros(lineLength/2,lineCount,'uint16');
if dopplerFlag == 1 
    dopplerData     = zeros(lineLength,lineCount,'uint16'); 
    dopplerFrame    = zeros(lineLength/2,lineCount,'uint16'); 
end
    
fseek(fid,-4,'cof');            % correct for 4-byte keyLength read in frame header loop
currentFrame        = 1;
frameLines          = zeros(1,frameCount);  % for tracking lines/frame in annular scan mode
imageFiles = cell(frameCount,1);

% Generate waitbar
hCurrentFileLoad    = waitbar(0,'Loading .OCT File'); 
while (currentFrame <= frameCount); 
    if mod(currentFrame,10) == 0
        waitbar(currentFrame/frameCount,hCurrentFileLoad); 
    end     % Only update every other 10 frames
    frameFlag       = 0;        % set to 1 when current frame read

    keyLength       = fread(fid,1,'uint32'); 
    key             = char(fread(fid,keyLength,'uint8')); 
    dataLength      = fread(fid,1,'uint32');
   
    if (strcmp(key','FRAMEDATA'))
        while (~frameFlag)
            keyLength       = fread(fid,1,'uint32'); 
            key             = char(fread(fid,keyLength,'uint8')); 
            dataLength      = fread(fid,1,'uint32'); % convert other dataLength lines to 'uint32'
            
            % The following can be modified to have frame values persist
            % Need to modify to convert frameDataTime and frameTimeStamp from byte arrays to real values 
            if (strcmp(key','FRAMEDATETIME'))
                frameDateTime   = fread(fid,dataLength/2,'uint16'); % dataLength/2 because uint16 = 2 bytes
                frameYear       = frameDateTime(1); 
                frameMonth      = frameDateTime(2); 
                frameDayOfWeek  = frameDateTime(3); 
                frameDay        = frameDateTime(4); 
                frameHour       = frameDateTime(5); 
                frameMinute     = frameDateTime(6); 
                frameSecond     = frameDateTime(7); 
                frameMillisecond= frameDateTime(8); 
            elseif (strcmp(key','FRAMETIMESTAMP'))
                frameTimeStamp  = fread(fid,1,'double'); % dataLength is 8 for doubles
            elseif (strcmp(key','FRAMELINES'))
                frameLines(currentFrame)    = fread(fid,1,'uint32');
            elseif (strcmp(key','FRAMESAMPLES'))
                imageData       = fread(fid,[lineLength,frameLines(currentFrame)],'uint16=>uint16'); 
            elseif (strcmp(key','DOPPLERSAMPLES'))
                dopplerData     = fread(fid,[lineLength,frameLines(currentFrame)],'uint16=>uint16'); 
            else
                fseek(fid,-4,'cof');                    % correct for keyLength read 
                frameFlag       = 1; 
            end % if/elseif for frame information
        end % while (~frameFlag)
            
        % Frame subsets
        imageFrame  = imageData;
        if (dopplerFlag == 1)
            dopplerFrame = dopplerData; 
        end % if to check Doppler flag

        if (frameCount < 10)
            index = strcat('00',num2str(currentFrame),imageExtension); 
        elseif (frameCount < 100)
            if (currentFrame < 10)
                index = strcat('00',num2str(currentFrame),imageExtension);
            else
                index = strcat(num2str(currentFrame),imageExtension); 
            end % if for index for frameCount < 100
        elseif (frameCount < 1000)
            if (currentFrame < 10)
                index = strcat('00',num2str(currentFrame),imageExtension);
            elseif (currentFrame < 100)
                index = strcat('0',num2str(currentFrame),imageExtension);
            else
                index = strcat(num2str(currentFrame),imageExtension); 
            end % if for index for frameCount < 100
        end % if/elseif for index creation 

        if (frameHour < 10)
            frameHourStamp = strcat('0',num2str(frameHour));
        else 
            frameHourStamp = num2str(frameHour); 
        end % if/else for frameHour < 10
        
        if (frameMinute < 10)
            frameMinuteStamp = strcat('0',num2str(frameMinute));
        else 
            frameMinuteStamp = num2str(frameMinute); 
        end % if/else for frameMinute < 10
        
        if (frameSecond < 10)
            frameSecondStamp = strcat('0',num2str(frameSecond));
        else 
            frameSecondStamp = num2str(frameSecond); 
        end % if/else for frameSecond < 10
        
        if (frameMillisecond < 10)
            frameMillisecondStamp = strcat('00',num2str(frameMillisecond)); 
        elseif (frameMillisecond < 100)
            frameMillisecondStamp = strcat('0',num2str(frameMillisecond)); 
        else
            frameMillisecondStamp   = num2str(frameMillisecond); 
        end 
        
        if (dopplerFlag == 1)
            imageStamp          = strcat('intensity_',frameHourStamp,'.',frameMinuteStamp,'.',frameSecondStamp,'.',frameMillisecondStamp);
            dopplerImageStamp   = strcat('doppler_',frameHourStamp,'.',frameMinuteStamp,'.',frameSecondStamp,'.',frameMillisecondStamp);
%             imageName           = strcat(imageStamp,index);
%             dopplerImageName    = strcat(dopplerImageStamp,index); 
            imageName           = strcat('intensity_',index); 
            dopplerImageName    = strcat('doppler_',index); 
        else
            imageStamp          = sprintf('%d.%d.%d.%d_',frameHour,frameMinute,frameSecond,frameMillisecond);
%             imageName           = strcat(imageStamp,index);
            imageName           = index; 
        end % if for image names

        % MODIFIED--1:LINELENGTH/2--TEMPORARY FOR LOADING LARGE FILE SETS
        % INTO IMAGEJ
%         imwrite(uint16(imageFrame(1:lineLength/2,:)),gray,strcat(imagePath,imageName),imageExtension(2:end),'Compression','none');
%         if (dopplerFlag == 1)
%            imwrite(uint16(dopplerFrame(1:lineLength/2,:)),gray,strcat(imagePath,dopplerImageName),imageExtension(2:end),'Compression','none');
%         end % Doppler image write if statement

        %
        %  Cut off the bottom portion of the image and rescale to 8-bit
        %
        if size(imageFrame,1) == 1024
            %imageFrame = imageFrame(1:512,:);
        end
        imageFrame = double(imageFrame);
        imageFrame = uint8((imageFrame * 255 ./ max(imageFrame(:))));
        
        if ~exist(saveDir, 'dir')
            mkdir(saveDir);
        end
        
        %
        %  Save the image
        %
        imageFileName = fullfile(saveDir,imageName);
        imwrite(imageFrame, imageFileName);
        imageFiles{currentFrame} = imageFileName;
        
        if (dopplerFlag == 1)
           imwrite(imageFrame, fullfile(imagePath,dopplerImageName));
        end % Doppler image write if statement
 
    
        currentFrame    = currentFrame + 1;     % will increase to frameCount + 1
    end % frames while loop
end % volume while loop

%% Shutdown
close(hCurrentFileLoad);    % close current file progress bar 
fclose(fid);