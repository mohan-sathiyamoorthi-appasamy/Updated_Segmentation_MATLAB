%**************************************************************************
%  readFile()
%**************************************************************************

function imageFiles = readFile(pathName, fileName)

global isGuiClosed
            
    file = fullfile(pathName, fileName);
    
    [path, name, extension] = fileparts(fileName);

    %
    %  When reading the file, images will be saved to a directory.  Get
    %  this from the user
    %
    imageDirectory = uigetdir( ...
        pathName, ...
        'Select a folder to save the images');

    if imageDirectory == 0
        return;
    end

    try
        switch lower(extension)
            case {'.oct'}
                imageFiles = readOctFile(file, imageDirectory);
            case {'.vol'}
                imageFiles = readHeidelbergFile(file, imageDirectory, 8);
            otherwise
                error('Files of extension %s are not supported', extension);
        end                   

    catch exception                
        msgbox(sprintf('Error loading the %s file. %s', ...
            extension, exception.message), 'Error');
        return;
    end

    %
    %  Check to see if the GUI was closed while loading the OCT 
    %  file.  If so, terminate the program instead of proceeding.
    %  The drawnow method flushes the event queue and updates the
    %  figure window
    %
    if isGuiClosed
       return;
    end
end