%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%  segmentationGui.m
%
%  This is the M-file for segmentationGui.fig.  segmentationGui, by itself,
%  creates a new segmentationGui instance or raises the existing singleton*
%
%--------------------------------------------------------------------------
%
%  INPUT PARAMETERS:
%
%       segmentationGui('CALLBACK',hObject,eventdata,handles,...) 
%       calls the local function named CALLBACK in segmentationGui.M with 
%       the given input arguments.
%
%       segmentationGui('Property','Value',...) 
%       creates a new segmentationGui or raises the existing singleton*.  
%       Starting from the left, property value pairs are applied to the GUI 
%       before segmentationGui_OpeningFcn gets called.  An unrecognized 
%       property name or invalid value makes property application stop
%       All inputs are passed to segmentationGui_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%       instance to run (singleton)".
%
%  OUTPUT VARIABLES:
%
%       h - segmentationGui returns the handle to a new segmentationGui or 
%           the handle to the existing singleton*.
%
%  See also: 
%       GUIDE, GUIDATA, GUIHANDLES
%
%--------------------------------------------------------------------------
%
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% CONSTRUCTOR FUNCTIONS

function varargout = segmentationGui(varargin)

    % Begin initialization code - DO NOT EDIT

    gui_Singleton = 1;
    gui_State = struct('gui_Name',       mfilename, ...
                       'gui_Singleton',  gui_Singleton, ...
                       'gui_OpeningFcn', @segmentationGui_OpeningFcn, ...
                       'gui_OutputFcn',  @segmentationGui_OutputFcn, ...
                       'gui_LayoutFcn',  [] , ...
                       'gui_Callback',   []);

    if nargin && ischar(varargin{1})
        gui_State.gui_Callback = str2func(varargin{1});
    end

    if nargout
        [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
    else
        gui_mainfcn(gui_State, varargin{:});
    end

    % End initialization code - DO NOT EDIT
end

function segmentationGui_OpeningFcn(hObject, eventdata, handles, varargin)
% --- Executes just before segmentationGui is made visible
%
%   hObject - handle to figure
%   eventdata - reserved. to be defined in a future version of MATLAB
%   handles - structure with handles and user data (see GUIDATA)
%   varargin - command line arguments to segmentationGui 
% ---

    % Add GLOBAL VARIABLES to the gui
    handles.ALGORITHM_TYPES = {'Normal','Drusen','Pediatric','DME'};
    handles.ENABLE_CYST = 0;
    handles.STUDY_TYPE = 'Default';
    handles.ENABLE_SLIDER = 1;
    handles.IMAGE_FILES = [];
    handles.BSCAN_FILES = [];
    handles.RULER_PIXEL_WIDTH = [];
    handles.RULER_PIXEL_HEIGHT = [];
    handles.BSCAN = [];
    handles.IMAGE_SIZE = [];
    handles.WAITBAR = [];
    handles.RULER_LENGTH = 11;
    handles.RULER_SPACING = 10;
    handles.FOVEA_SCANS = [];
    handles.FOVEA_LOCATIONS = [];
    handles.LOAD_PATH = '';
    handles.NUM_TOTAL_IMAGES = [];    
    handles.TAB_NAMES = {'Load','Automatic','Manual','Review'};
    handles.ZOOM_LIMIT = [];
    handles.CLOSED_CONTOUR_IMAGE = [];

    % Set the tool tip strings
    LoadInstructions(handles);
    AutomaticInstructions(handles);
    ManualInstructions(handles);
    ReviewInstructions(handles);
    OtherInstructions(handles);
    
    % Update title with version number
    bScan = BScan();
    version = sprintf(' (Version %s)', bScan.SoftwareVersion);
%     title = strcat(get(handles.Title, 'String'), version);
%     set(handles.Title, 'String', title);
    
    % Choose default command line output for segmentationGui
    handles.output = hObject;
    
    % Display Load Tab
    ShowTab('Load',handles,hObject);
    
    % Set algorithm types
    if ~isempty(handles.ALGORITHM_TYPES)
        set(handles.Algorithm_Popup,'String',handles.ALGORITHM_TYPES);
                
        % Replace any spaces in the algorithm with an underscore
        for iAlgorithm = 1:length(handles.ALGORITHM_TYPES)
            algorithm = handles.ALGORITHM_TYPES{iAlgorithm};
            algorithm = strrep(algorithm, ' ', '_');
            handles.ALGORITHM_TYPES{iAlgorithm} = lower(algorithm);
        end
    end

    % Update handles structure
    guidata(hObject, handles);
end

function varargout = segmentationGui_OutputFcn(hObject, eventdata, handles)
% --- Outputs from this function are returned to the command line
%
%   hObject - handle to figure
%   eventdata - reserved. to be defined in a future version of MATLAB
%   handles - structure with handles and user data (see GUIDATA)
%   varargout - cell array for returning output args (see VARARGOUT);
% ---

    % Get default command line output from handles structure
    varargout{1} = handles.output;
end


%% INSTRUCTION FUNCTIONS

function General_Information_Button_Callback(hObject, eventdata, handles)
% --- Executes on button press in General_Information_Button.
% hObject    handle to General_Information_Button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
%
    general = sprintf('%s\r\n%s\r\n%s\r\n\r\n\r\n%s\r\n%s\r\n\r\n%s\r\n%s\r\n\r\n%s\r\n%s\r\n\r\n%s\r\n%s\r\n\r\n', ...
        'For help:', ...
        '-- Click on the ''Instructions'' button for guidelines', ...
        '-- Hover over the object in question for specific help', ...
        'Load/View Tab:', ...
        '-- Load images and view segmentations.', ... 
        'Automatic Tab:', ...
        '-- Select algorithm and run automatic segmentation', ...
        'Manual Tab:', ...
        '-- Manually segment images, correct automatic segmentation, and use vertical or horizontal rulers', ...
        'Review Tab:', ...
        '-- Add comments, select the fovea, select foci, and view vertical bars');
    
    msgbox(general, 'General Instructions','replace');    
end

function LoadInstructions(handles)

    set(handles.Load_Tab,'tooltipstring', ...
        'This tab is dedicated to loading and viewing images');    
    set(handles.Load_File_Button,'tooltipstring', sprintf('%s\r\n\r\n%s\r\n%s\r\n%s', ...
        'Select which image(s) to load.', ...
        '-- Supported file types: TIF, JPG, DCM', ...
        '-- Select the original (unsegmented) image(s)', ...
        '-- To select multiple images, hold down the Ctrl button'));
    set(handles.Load_Stack_Button,'tooltipstring', sprintf('%s\r\n\r\n%s\r\n%s\r\n%s', ...
        'Load a group of similar images.', ...
        '-- Supported file types: TIF, JPG, DCM, OCT, VOL', ...
        '-- For OCT and VOL files, select the file to load', ...
        '-- For TIF, JPG, and DCM files, select any single (unsegmented) image and all images will load'));
    set(handles.Automatic_Radio_Button,'tooltipstring', sprintf('%s\r\n%s', ...
        'Show the automatically segmented boundaries,', ...
        'with or without manual corrections')); 
    set(handles.Manual_Radio_Button,'tooltipstring', ...
        'Show the manually segmented boundaries');
    Set_ShowBoundariesCheckbox(handles, 'tooltipstring', ...
        'Turn the boundaries on/off');
    Set_ShowCorrectionsCheckbox(handles, 'tooltipstring', sprintf('%s\r\n%s', ...
        'Toggles between the fully automatically segmented boundaries', ...
        'and the automatic boundaries corrected by a user'));
end

function Automatic_Instructions_Button_Callback(hObject, eventdata, handles)
% --- Executes on button press in Automatic_Instructions_Button.
% hObject    handle to Automatic_Instructions_Button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

    general = sprintf('%s\r\n\r\n%s\r\n%s\r\n%s\r\n%s\r\n%s\r\n\r\n', ...
        'This tab is dedicated to automatic image segmentation', ...
        'To segment image(s)', ...
        ' 1.  In the ''Load/View'' tab, load image(s)', ...
        ' 2.  In the ''Automatic'' tab, select the ''Algorithm Type''', ...
        ' 3.  (Optional) Customize algorithm parameters', ...
        ' 4.  Click ''Segment Layers'' to segment all loaded images');
    
    cancel = sprintf('%s\r\n\r\n%s\r\n%s\r\n%s\r\n\r\n%s\r\n%s\r\n', ...
        'To cancel segmentation:', ...
        '    If parallel processing is disabled:', ...
        '       1.  Click ''Cancel'' on the waitbar popup', ...
        '       2.  Wait for the current image to finish segmenting', ...
        '    If parallel processing is enabled:', ...
        '       1.  Hold down ''Ctrl''+''C''');
    
    msgbox(sprintf('%s%s',general, cancel), 'Automatic Tab Instructions','replace');
end

function AutomaticInstructions(handles)

    set(handles.Automatic_Tab,'tooltipstring', ...
        'This tab is dedicated to automatic image segmentation');
    set(handles.Algorithm_Popup, 'tooltipstring', ...
        'Select which segmentation algorithm to run');
    set(handles.Num_Layers, 'tooltipstring', sprintf('%s\r\n\r\n%s', ...
        'The number of layers to segment', ...
        'Note:  Which layers to segment cannot be specified'));
    set(handles.Smoothing_Correction, 'tooltipstring', sprintf('%s\r\n\r\n%s\r\n%s\r\n%s', ...
        'The amount to smooth a layer', ...
        '-- Values range from 0 to 1', ...
        '-- Specify a value for each layer:', ...
        '-- Example: "0.1, 0, 0.9" for three layers'));
    Set_LineThickness(handles, 'tooltipstring', sprintf('%s\r\n%s', ...
        'The thickness of the boundaries (in pixels).', ...
        'Note:  This is for visualization purposes only.'));
    Set_LateralSpacing(handles, 'tooltipstring', sprintf('%s\r\n\r\n%s\r\n%s\r\n%s\r\n%s', ...
        'The number of microns each pixel represents horizontally.', ...
        '-- To calculate, divide the image width (in microns) by the', ...
        'image width (in pixels).', ...
        '-- Example: For a 10mm-wide image that is 1000 pixels in width,', ...
        'the lateral pixel spacing is 10000um/1000pixels = 10um/pixel'));
    Set_AxialSpacing(handles, 'tooltipstring', sprintf('%s\r\n%s', ...
        'The number of microns each pixel represents vertically.', ...
        '(This value is intrinsic to the imaging system)'));
    set(handles.Eye_Popup, 'tooltipstring', sprintf('%s\r\n%s', ...
        'Which eye was imaged.', ...
        '(Left = OS, Right = OD)'));
    set(handles.Scan_Orientation_Popup, 'tooltipstring', sprintf('%s\r\n\r\n%s\r\n%s\r\n\r\n%s\r\n%s', ...
        'The orientation in which the images were acquired.', ...
        'Horizontal (0 degree) images:', ...
        '-- Acquired from top to bottom (or vice versa)', ...
        'Vertical (90 degree) images:', ...
        '-- Acquired from left to right (or vice versa)'));
    set(handles.Segment_Cysts_Checkbox, 'tooltipstring', sprintf('%s\r\n%s', ...
        'Segments intra-retinal cysts in addition to ', ...
        'retinal layer boundaries.'));
    set(handles.Invert_Image_Checkbox, 'tooltipstring', sprintf( ...
        'Invert the image so that it is upright during segmentation'));
    set(handles.Parallel_Processing_Checkbox, 'tooltipstring', ...
        sprintf('%s\r\n%s\r\n\r\n%s\r\n%s\r\n%s\r\n%s\r\n%s\r\n\r\n%s\r\n%s\r\n%s\r\n%s', ...
        'Uses multiple threads to segment images simultaneously,', ...
        'resulting in a faster computation time.', ...
        'With Parallel Processing Enabled:', ... 
        '- Faster segmentation time', ...
        '- Viewing options are disabled until segmentation is complete', ...
        '- Can only cancel segmentation using ''Ctrl''+''C''', ...
        '- Will not be able to use other applications during this process', ...
        'With Parallel Processing Disabled:', ... 
        '- Normal segmentation time', ...
        '- Viewing and Cancelling options enabled', ...
        '- Can use other applications during this process'));
    set(handles.Default_Parameters_Button, 'tooltipstring', ...
        'Resets the parameters to the default values');
    set(handles.Segment_Layers_Button,'tooltipstring', ...
        'Click to begin segmentation');
end

function Manual_Instructions_Button_Callback(hObject, eventdata, handles)
% --- Executes on button press in Manual_Instructions_Button.

    general = sprintf('%s\r\n\r\n%s\r\n%s\r\n%s\r\n%s\r\n%s\r\n\r\n%s\r\n%s\r\n%s\r\n\r\n', ...
        'This tab is dedicated to manual image segmentation/correction', ...
        'To segment/correct image(s):', ...
        ' 1.  In the ''Load/View'' tab, load image(s)', ...
        ' 2.  In the ''Manual'' tab, select the ''Mode''', ...
        ' 3.  In the ''Marking'' panel, select the ''Boundary Type''', ...
        ' 4.  Use the ''Marking'' panel to correct/segment the image', ...
        'Note:', ...
        '-- If clicking points, press ''Enter'' when complete', ...
        '-- If drawing freehand, double click when complete');
    
    ruler = sprintf('%s\r\n%s\r\n%s\r\n%s\r\n%s', ...
        'To create a ruler to view the size of structures on the image:', ...
        '1.  Select the ''Horizontal'' or ''Vertical'' ruler option', ...
        '2.  Enter the required input parameters', ...
        '3.  A ruler will appear to the right or bottom of the image', ...
        '4.  Click on the image to display the ruler');
    
    msgbox(sprintf('%s%s',general,ruler), 'Manual Tab Instructions','replace');        
end

function ManualInstructions(handles)

    set(handles.Automatic_Tab,'tooltipstring', ...
        'This tab is dedicated to manual image segmentation/correction');
    set(handles.Automatic_Radio_Button2,'tooltipstring', sprintf('%s\r\n%s', ...
        'Select to correct automatically segmented boundaries,', ...
        'with or without manual corrections')); 
    set(handles.Manual_Radio_Button2,'tooltipstring', ...
        'Select to manually segment boundaries from scratch');
    set(handles.Marker_Size,'tooltipstring', sprintf('%s\r\n%s\r\n', ...
        'The size of the clicked points while', ...
        'manually marking (in pixels)'));
    set(handles.Layer_Type_Button,'tooltipstring', ...
        'Segment/correct layer bounaries'); 
    set(handles.Closed_Type_Button,'tooltipstring', ...
        'Segment/correct closed-contour bounaries');
    if get(handles.Layer_Type_Button,'Value')
        set(handles.Correct_Current_Boundary_Button,'tooltipstring', ...
            sprintf('%s\r\n\r\n%s\r\n%s\r\n%s\r\n%s', ...
            'Make corrections to the current layer:', ...
            '1.  Click ''Correct Current Layer''', ...
            '2.  Mark the image where the layer needs correction', ...
            '3.  If clicking points, press ''Enter'' when complete.', ...
            'Otherwise if drawing freehand, double click when complete.'));
        set(handles.Add_New_Boundary_Button,'tooltipstring', ...
            sprintf('%s\r\n\r\n%s\r\n%s\r\n%s\r\n%s', ...
            'Add a new layer:', ...
            '1.  Click ''Add New Layer''', ...
            '2.  Mark the image at the boundary location', ...
            '3.  If clicking points, press ''Enter'' when complete.', ...
            'Otherwise if drawing freehand, double click when complete.'));        
        if get(handles.Click_Points_Checkbox,'Value')
            set(handles.Manual_Instructions_String,'string', ...
                sprintf('%s\r\n\r\n%s\r\n\r\n\r\n%s\r\n\r\n%s\r\n\r\n%s\r\n\r\n\r\n%s\r\n\r\n%s\r\n\r\n%s\r\n\r\n%s\r\n\r\n', ...
                'NOTE:', ...
                '** All buttons have been disabled during manual marking!', ...
                'TO CANCEL:', ...
                '1. Click only one point anywhere on the GUI', ...
                '2.  Press ''Enter''', ...
                'TO MARK A LAYER:', ...
                '1.  Click a minimum of two points on the image corresponding to the layer to be marked', ...
                '2.  To ensure the marking extends to the edge of the image, click a point just off the image', ...
                '3.  Press ''Enter'' when complete.'));
        else
            set(handles.Manual_Instructions_String,'string', ...
                sprintf('%s\r\n\r\n%s\r\n\r\n\r\n%s\r\n\r\n%s\r\n\r\n\r\n%s\r\n\r\n%s\r\n\r\n%s\r\n\r\n', ...
                'NOTE:', ...
                '** All buttons have been disabled during manual marking!', ...
                'TO CANCEL:', ...
                '1. Double click one point anywhere on the GUI', ...
                'TO MARK A REGION:', ...
                '1.  Hold the mouse down and draw the region to add/remove', ...
                '2.  With the cross-arrows still visible, double click'));
        end
    else
        set(handles.Correct_Current_Boundary_Button,'tooltipstring', ...
            sprintf('%s\r\n%s\r\n%s', ...
            'Trim off already-marked regions by selecting', ...
            'regions that should be removed.', ...
            '(Use the zooming toolbar for finer selections)'));
        set(handles.Add_New_Boundary_Button,'tooltipstring', ...
            sprintf('%s\r\n%s', ...
            'Add new regions by selecting the regions to include', ...
            '(Use the zooming toolbar for finer selections)'));
        set(handles.Manual_Instructions_String,'string', ...
            sprintf('%s\r\n\r\n%s\r\n\r\n\r\n%s\r\n\r\n%s\r\n\r\n\r\n%s\r\n\r\n%s\r\n\r\n', ...
            'NOTE:', ...
            '** All buttons have been disabled during manual marking!', ...
            'TO CANCEL:', ...
            '1. Click one point anywhere on the GUI', ...
            'TO MARK A REGION:', ...
            '1.  Hold the mouse down and draw the region to add/remove'));
    end
    set(handles.Reset_Current_Boundary_Button,'tooltipstring', ...
        sprintf('%s\r\n\r\n%s\r\n%s\r\n%s\r\n%s', ...
        'Reset the current boundary to its original state', ...
        '-- If correcting automatic segmentation, then the current', ...
        'boundary will be reset to the fully automatic segmentation.', ...
        '-- If manually segmenting from a blank image, then the', ...
        'current boundary will be completely removed'));
    set(handles.Reset_All_Boundaries_Button,'tooltipstring', ...
        sprintf('%s\r\n\r\n%s\r\n%s\r\n%s\r\n%s', ...
        'Reset all boundaries to their original state', ...
        '-- If correcting automatic segmentation, all corrections', ...
        'will be reset to the fully automatic segmentation.', ...
        '-- If manually segmenting from a blank image, then', ...
        'all boundaries will be completely removed'));
    set(handles.Current_Boundary,'tooltipstring', sprintf('%s\r\n\r\n%s\r\n%s', ...
        'Specify the current boundary', ...
        '-- For layers, the top layer is Boundary 1', ...
        '-- For closed-contours, the top-left closed-contour is Boundary 1'));
    set(handles.Current_Boundary_Up,'tooltipstring', ...
        'Increment the current boundary by 1');
    set(handles.Current_Boundary_Down,'tooltipstring', ...
        'Decrement the current boundary by 1');
    set(handles.Pin_Boundary_Popup,'tooltipstring', ...
        sprintf('%s\r\n\r\n%s\r\n%s\r\n%s\r\n%s\r\n%s', ... %\r\n\r\n%s\r\n%s\r\n%s', ...
        'Prevent (pin) other boundaries from being altered', ...
        'For layers:', ...
        '-- Neither:  Do not pin the layers above or below the current layer', ...
        '-- Top:  Pin only the layers above the current layer', ...
        '-- Bottom:  Pin only the layers below the current layer', ...
        '-- Both:  Pin all layers above and below the current layer'));
%         'For closed-contours:', ...
%         '-- None:  Do not pin any boundaries aside from the current boundary', ...
%         '-- All:  Pin all boundaries aside from the current boundary'));
    set(handles.Click_Points_Checkbox,'tooltipstring', sprintf('%s\r\n%s', ...
        'Turn on to manually mark the image by clicking points', ...
        'Turn off to manually mark the image by freehand drawing'));
    set(handles.Show_Other_Boundaries_Checkbox,'tooltipstring', sprintf('%s\r\n%s', ...
        'Show the locations of the other boundaries', ...
        'when manually marking'));
    set(handles.Horizontal_Ruler_Button,'tooltipstring', sprintf('%s\r\n\r\n%s\r\n%s\r\n%s\r\n%s', ...
        'View a horizontal ruler for measuring the width of structures by:', ...
        '1.  Enter the lateral pixel spacing', ...
        '2.  Enter the desired width of the ruler (in microns)', ...
        '3.  A ruler will appear to the right or bottom of the image', ...
        '4.  Click on the image to display the ruler'));
    set(handles.Vertical_Ruler_Button,'tooltipstring', sprintf('%s\r\n\r\n%s\r\n%s\r\n%s\r\n%s', ...
        'View a vertical ruler for measuring the width of structures by:', ...
        '1.  Enter the axial pixel spacing', ...
        '2.  Enter the desired height of the ruler (in microns)', ...
        '3.  A ruler wil appear to the right or bottom of the image', ...
        '4.  Click on the image to display the ruler'));
    set(handles.Ruler_Width,'tooltipstring', ...
        'Desired width of the ruler (in microns)');
    set(handles.Ruler_Height,'tooltipstring', ...
        'Desired height of the ruler (in microns)');
    set(handles.Clear_Lines_Button,'tooltipstring', ...
        'Clear all ruler markings on the image');
end

function Review_Instructions_Button_Callback(hObject, eventdata, handles)
% --- Executes on button press in Review_Instructions_Button.
% hObject    handle to Review_Instructions_Button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

    general = sprintf('%s\r\n\r\n%s\r\n%s\r\n%s\r\n\r\n%s\r\n%s\r\n%s\r\n%s\r\n%s\r\n%s\r\n\r\n', ...
        'This tab is dedicated to reviewing images.', ... 
        'To review images:', ...
        ' 1.  In the ''Load/View'' tab, load image(s)', ...
        ' 2.  Navigate back to the ''Review'' tab', ...
        'Features:', ...
        '-- Input comments about the current image', ...
        '-- Mark the fovea location on the current image', ...
        '-- Mark two different foci groups, or compare foci marked by two users', ...
        '-- Display vertical bars that crop the sides of the image', ...
        '-- Display vertical bars of a given distance from the fovea');
    
    msgbox(general, 'Manual Tab Instructions','replace');        
end

function ReviewInstructions(handles)

    set(handles.Comment_Box, 'tooltipstring', ...
        'User input comments about the current image');
    set(handles.Edit_Comment_Button, 'tooltipstring', ...
        'Edit the comment box');
    set(handles.Apply_Comment_Button, 'tooltipstring', ...
        'Save the new comments');
    set(handles.Select_Fovea_Button, 'tooltipstring', ...
        'Mark the fovea location on the current image');
    set(handles.Show_Fovea_Checkbox, 'tooltipstring', ...
        'Show the fovea location with an asterisk');
    set(handles.Clear_Fovea_Button, 'tooltipstring', ...
        'Remove the fovea location on the current image');
    set(handles.Select_Foci_1_Button, 'tooltipstring', ...
        'Mark a first group of foci locations');
    set(handles.Show_Foci_1_Checkbox, 'tooltipstring', sprintf('%s\r\n%s', ...
        'Show the first group of foci', ...
        'locations with green asterisks'));
    set(handles.Clear_Foci_1_Button, 'tooltipstring', ...
        'Remove the first group of foci locations');
    set(handles.Select_Foci_2_Button, 'tooltipstring', ...
        'Mark a second group of foci locations');
    set(handles.Show_Foci_2_Checkbox, 'tooltipstring', sprintf('%s\r\n%s', ...
        'Show the first group of foci', ...
        'locations with red asterisks'));
    set(handles.Clear_Foci_2_Button, 'tooltipstring', ...
        'Remove the second group of foci locations');
    set(handles.Crop_Sides_Text, 'tooltipstring', sprintf('%s\r\n%s', ...
        'Display red vertical bars that crop the sides', ...
        'of the image by the specified percentage'));
    set(handles.Crop_Sides, 'tooltipstring', sprintf('%s\r\n%s', ...
        'Percentage to crop on each side of the image', ...
        '(Enter a value in the range 0 to 50)'));
    set(handles.Show_Crop_Lines_Checkbox, 'tooltipstring', ...
        'Show the vertical bars that crop the image');
    set(handles.Fovea_Centered_Rings_Text, 'tooltipstring', sprintf('%s\r\n%s', ...
        'Display vertical bars of a given', ...
        'distance from the fovea'));
    set(handles.Scan_Length, 'tooltipstring', sprintf('%s\r\n\r\n%s\r\n%s', ...
        'The scan length of the volume (in mm).', ...
        '-- This corresponds to the total distance from the', ...
        'first B-scan (image) to the last B-scan aquired'));
    set(handles.Num_Stack_Images, 'tooltipstring', sprintf('%s\r\n%s', ...
        'The total number of B-scans (images)', ...
        'acquired in one scan (volume) of the eye'));
    set(handles.Foveal_Distances, 'tooltipstring', sprintf('%s\r\n\r\n%s\r\n%s', ...
        'The radial distance(s) from the fovea (in mm)', ...
        '-- Example:  Enter "1.5,  2,  3" for three circles', ...
        'that are 1.5,  2,  and 3 mm away from the fovea'));
end

function OtherInstructions(handles)
    
    set(handles.Image_Slider, 'tooltipstring', ...
        'Scroll through the loaded images');
    set(handles.Image_Number, 'tooltipstring', ...
        'Enter the image to view');
    set(handles.Save_Image_Button, 'tooltipstring', ...
        'Save a screenshot of the current image');
end


%% TAB FUNCTIONS

function Load_Tab_Callback(hObject, eventdata, handles)
% --- Executes on button press in Load_Tab.

    ShowTab('Load',handles,hObject);
end

function Automatic_Tab_Callback(hObject, eventdata, handles)
% --- Executes on button press in Automatic_Tab.
    
    ShowTab('Automatic',handles,hObject);
end

function Manual_Tab_Callback(hObject, eventdata, handles)
% --- Executes on button press in Manual_Tab.
    
    ShowTab('Manual',handles,hObject);
end

function Review_Tab_Callback(hObject, eventdata, handles)
% --- Executes on button press in Review_Tab.
% hObject    handle to Review_Tab (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    
    ShowTab('Review',handles,hObject);
end

function ShowTab(tabName,handles,hObject)    
    
    tabShown = 0;
    for iTab = 1:length(handles.TAB_NAMES)
        currentTab = handles.TAB_NAMES{iTab};
        
        % Determine whether to show the tab
        if tabShown || ~strcmp(tabName, currentTab)
            enable = 'on';
            style = 'pushbutton';
            visible = 'off';
        else
            enable = 'inactive';
            style = 'edit';
            visible = 'on';
            tabShown = 1;
        end
        
        % Show or unshow the tab
        eval(sprintf('set(handles.%s_Tab, ''Enable'', enable);', currentTab));
        eval(sprintf('set(handles.%s_Tab, ''Style'', style);', currentTab));
        eval(sprintf('set(handles.%s_Panel, ''Visible'', visible);', currentTab));
    end
    
    guidata(hObject, handles);
    DisplayImage(hObject,handles);  
end


%% MENU FUNCTIONS

function Help_Menu_Callback(hObject, eventdata, handles)
end

function About_Menu_Callback(hObject, eventdata, handles)
    aboutBox;
end


%% SET MULTIPLE PROPERTIES

function Set_ShowBoundariesCheckbox(handles,property,value)
    set(handles.Show_Boundaries_Checkbox,property,value);
    set(handles.Show_Boundaries_Checkbox2,property,value);
end

function Set_AutomaticRadioButton(handles,property,value)
    set(handles.Automatic_Radio_Button,property,value);
    set(handles.Automatic_Radio_Button2,property,value);
end

function Set_ManualRadioButton(handles,property,value)
    set(handles.Manual_Radio_Button,property,value);
    set(handles.Manual_Radio_Button2,property,value);
end

function Set_LateralSpacing(handles,property,value)
    set(handles.Lateral_Resolution,property,value);
    set(handles.Lateral_Resolution2,property,value);
    set(handles.Lateral_Resolution3,property,value);
end

function Set_AxialSpacing(handles,property,value)
    set(handles.Axial_Resolution,property,value);
    set(handles.Axial_Resolution2,property,value);
end

function Set_LineThickness(handles,property,value)
    set(handles.Line_Thickness,property,value);
    set(handles.Line_Thickness2,property,value);
end

function Set_ShowCorrectionsCheckbox(handles,property,value)
    set(handles.Show_Corrections_Checkbox,property,value);
    set(handles.Show_Corrections_Checkbox2,property,value);
end


%%  LOAD IMAGE FUNCTIONS

function imageFiles = ReadFile(pathName, fileName)

    %  When reading the file, images will be saved to a directory.
    %  Get this directory from the user.
    directory = uigetdir(pathName,'Select a folder to save the images');

    % If no directory was selected, then do nothing
    if directory == 0
        return;
    end

    % Load the file
    file = fullfile(pathName,fileName);    
    [path,name,extension] = fileparts(fileName);
    
    try
        switch lower(extension)
            case {'.oct'}
                imageFiles = readOctFile(file,directory);
            case {'.vol'}
                imageFiles = readHeidelbergFile(file,directory,8);
            otherwise
                error('The ''%s'' file extension is not supported',extension);
        end

    % Report any errors
    catch exception                
        msgbox(sprintf('Error loading the %s file.\r\n\r\n%s', ...
            extension,exception.message),'Error','Replace');
        return;
    end
end

function Load_File_Button_Callback(hObject, eventdata, handles)
% --- Executes on button press in Load_File_Button

    % Ask the user for the file(s) to load
    [fileName, pathName] = uigetfile( ...
        {'*.tiff;*.tif;*.jpg;*.dcm;',  'All Files'; ...
         '*.tiff', 'TIF Files (*.tiff)'; ...
         '*.tif', 'TIF Files (*.tif)'; ...
         '*.jpg', 'JPEG Files (*.jpg)'; ...
         '*.dcm', 'DICOM Files (*.dcm)'}, ...
         'Select (unsegmented) Image(s) / File(s)', ...
         'MultiSelect', 'on', ...
         handles.LOAD_PATH);
    
    % Do nothing if no file was selected
    if isequal(fileName,0)
        return;       
    end

    % Make the fileName a cell object if only one file was selected
    if ~iscell(fileName)
        fileName = {fileName};
    end
    
    % Set the total number of images in the directory
    [path,name,extension] = fileparts(fileName{1});
    searchString = strcat('*',extension);
    files = dir(fullfile(pathName,searchString));
    imageFiles = {files.('name')};
    imageFiles = strcat(pathName,imageFiles);
    handles.NUM_TOTAL_IMAGES = length(imageFiles);
    
    % Save the path for loading next time
    handles.LOAD_PATH = pathName;
    guidata(hObject, handles);    
    
    % Load the image(s)
    file = strcat(pathName,fileName);
    LoadImage(pathName,file,hObject,handles);
end

function Load_Stack_Button_Callback(hObject, eventdata, handles)
%  --- Executes on button press in Load_Stack_Button
    
    % Ask the user for a file in the stack to load
    [fileName,pathName] = uigetfile( ...
        {'*.tif;*.jpg;*.dcm;*.oct;*.vol',  'All Files'; ...
         '*.tif', 'TIF Files (*.tif)'; ...
         '*.jpg', 'JPEG Files (*.jpg)'; ...
         '*.dcm', 'DICOM Files (*.dcm)'; ...
         '*.oct', 'OCT Files (*.oct)'; ...
         '*.vol', 'HEIDELBERG Files (*.vol)'}, ...
         'Select an (unsegmented) Image in the Stack', ...
         handles.LOAD_PATH);
    
    % Do nothing if no file was selected
    if isequal(fileName, 0)
        return;       
    end
    
    % Save the path for loading next time
    handles.LOAD_PATH = pathName;
    guidata(hObject, handles); 

    % The reading method depends on the file extension type
    [path,name,extension] = fileparts(fileName);
    
    if strcmpi('.oct',extension) || ...
       strcmpi('.vol',extension)
    	
        try
            imageFiles = ReadFile(pathName,fileName);       
        catch
            return;
        end
    else
        searchString = strcat('*',extension);
        files = dir(fullfile(pathName,searchString));
        imageFiles = {files.('name')};
        imageFiles = strcat(pathName,imageFiles);
    end
    
    % Set the total number of images in the directory
    handles.NUM_TOTAL_IMAGES = length(imageFiles);
    guidata(hObject, handles);
    
    % Load the images
    LoadImage(pathName,imageFiles,hObject,handles);
end

function LoadImage(directory, imageFiles, hObject, handles)  
% --- Initializes the figure and values and loads the image
%
%	imageFiles - cell array of image filenames
%   handles - structure with handles and user data (see GUIDATA)
% ---

    % Reset zoom properties
    handles.ZOOM_LIMIT = [];
    Zoom_Out_Toolbar_ClickedCallback(hObject, [], handles);
    
    nImages = length(imageFiles);

    % Turn off the slider if there is only one image
    if nImages == 1        
        set(handles.Image_Slider, 'Enable', 'off');
        set(handles.Image_Slider, 'Value', 1);
        set(handles.Image_Number, 'Enable', 'off')
    
    % If multiple images exist, then set the slider 
    % range to match the number of images
    else
        arrowStepSize = 1;
        troughStepSize = ceil(double(nImages)/10);
        
        sliderStep(1) = arrowStepSize/(nImages-1);
        sliderStep(2) = troughStepSize/(nImages-1);
    
        set(handles.Image_Slider, ...
            'Sliderstep', sliderStep, ...
            'Min', 1, ...
            'Max', nImages, ...
            'Value', 1);
    
        set(handles.Image_Slider,'Enable','on');
        set(handles.Image_Number,'Enable','on');
    end
    
    % Allow users to runSegmentation
    if ~isempty(handles.ALGORITHM_TYPES)
        set(handles.Segment_Layers_Button,'Enable','on');
    end
    
    % Check to see if there are already segmented files available
    matFileDir = fullfile(directory,'Segmentation');
    matFiles = dir(fullfile(matFileDir,'*.mat'));
    matFiles = {matFiles.name};
    bScanFiles = cell(1,length(imageFiles));

    % Parameters for the fovea
    foveaScan = NaN(1,nImages);
    foveaLocation = cell(1,nImages);
        
    % If there are segmented files, keep track of the mat files
    if ~isempty(matFiles)
        
        % Create a waitbar
        hFileLoad = waitbar(0,'Loading Images...'); 
        
        for iFile = 1:nImages
            
            % Only updaste the waitbar every 10 frams
            if mod(iFile,10) == 0
                waitbar(iFile/length(imageFiles),hFileLoad); 
            end 
            
            file = imageFiles{iFile};
            [path,name] = fileparts(file);
            matFile = strcat(name,'.mat');        
            matFileIndex = find(ismember(matFiles,matFile));

            if ~isempty(matFileIndex)
                bScanFiles{iFile} = fullfile(matFileDir,matFiles{matFileIndex});
                
                % Search for the fovea
                load(bScanFiles{iFile});
                if ~isempty(bScan.Fovea)
                    foveaScan(iFile) = iFile;
                    foveaLocation(iFile) = {bScan.Fovea};
                end
            end
        end
        invalidFovea = isnan(foveaScan);
        foveaScan(invalidFovea) = [];
        foveaLocation(invalidFovea) = [];
        close(hFileLoad);
    end

    % Make the parameters below are accesible to all callback methods
    handles.IMAGE_FILES = imageFiles;
    handles.BSCAN_FILES = bScanFiles;
    handles.RULER_PIXEL_WIDTH = 0;   
    handles.RULER_PIXEL_HEIGHT = 0;
    handles.FOVEA_SCANS = foveaScan;
    handles.FOVEA_LOCATIONS = foveaLocation;
    
    guidata(hObject, handles);
    
    % Enable showing layers if a Bscan exists
    if isempty(bScanFiles{1}) 
        bScan = [];
        enableCheckbox = 'off';
    else
        load(bScanFiles{1});
        enableCheckbox = 'on';
    end
    Set_ShowBoundariesCheckbox(handles,'Value',1)
    Set_ShowBoundariesCheckbox(handles,'Enable',enableCheckbox)
    
    % Enable automatic radiobutton if segmentation exists
    if ~isempty(bScan) && (~isempty(bScan.Layers) || ~isempty(bScan.ClosedContourImage))
        Set_AutomaticRadioButton(handles,'Value',1);
        Set_AutomaticRadioButton(handles,'Enable','on');
    else
        Set_ManualRadioButton(handles,'Value',1);
        Set_AutomaticRadioButton(handles,'Enable','off');
    end        
    
    % Enable properties to be viewed
    Set_ManualRadioButton(handles,'Enable','on');
    set(handles.Layer_Type_Button,'Enable','on');
    set(handles.Closed_Type_Button,'Enable','on');
    set(handles.Lateral_Resolution2,'Enable','on');
    set(handles.Axial_Resolution2,'Enable','on');
    set(handles.Line_Thickness2,'Enable','on');
    set(handles.Edit_Comment_Button,'Enable','on');
    set(handles.Apply_Comment_Button,'Enable','on');
    set(handles.Select_Fovea_Button,'Enable','on');
    set(handles.Crop_Sides,'Enable','on');
    set(handles.Show_Fovea_Checkbox,'Enable','on');
    set(handles.Select_Foci_1_Button,'Enable','on');
    set(handles.Select_Foci_2_Button,'Enable','on');
    set(handles.Show_Foci_1_Checkbox,'Enable','on');
    set(handles.Show_Foci_2_Checkbox,'Enable','on');
    set(handles.Horizontal_Ruler_Button,'Enable','on');
    set(handles.Vertical_Ruler_Button,'Enable','on');
    set(handles.Ruler_Width,'Enable','on');
    set(handles.Ruler_Height,'Enable','on');
    set(handles.Marker_Size,'Enable','on');
    set(handles.Current_Boundary,'Enable','on');
    set(handles.Current_Boundary_Up,'Enable','on');
    set(handles.Current_Boundary_Down,'Enable','on');
    set(handles.Pin_Boundary_Popup,'Enable','on');
    set(handles.Show_Other_Boundaries_Checkbox,'Enable','on');
    set(handles.Save_Image_Button,'Enable','on');
    set(handles.Image_Number,'String',1);
    set(handles.Click_Points_Checkbox, 'Enable','on')
    set(handles.Lateral_Resolution3,'Enable','on');
    set(handles.Scan_Length,'Enable','on');
    
    % Set parameters related to the image filename
    SetImageParameters(handles);
    
    studySites = get(handles.Study_Site_Popup,'String');
    if size(studySites,1) > 1
        set(handles.Study_Site_Popup,'Enable','on'); 
    end
    
    % Enable segmentation parameters
    if ~isempty(handles.ALGORITHM_TYPES)
        
        % Enable parameters not dependent on the algorithm type
        set(handles.Algorithm_Popup,'Enable','on');
        set(handles.Num_Layers,'Enable','on');
        set(handles.Smoothing_Correction,'Enable','on');
        set(handles.Line_Thickness,'Enable','on');
        set(handles.Lateral_Resolution,'Enable','on');
        set(handles.Axial_Resolution,'Enable','on');
        set(handles.Invert_Image_Checkbox,'Enable','on');
        set(handles.Parallel_Processing_Checkbox,'Enable','on');
        set(handles.Default_Parameters_Button,'Enable','on');
        
        % Set algorithm parameters and enable relevant parameters
        Algorithm_Popup_Callback(hObject,[],handles);
    end
    
    % Set fovea parameters
    if ~isempty(bScan) && ~isempty(bScan.Fovea)
        set(handles.Clear_Fovea_Button,'Enable','on');
    else
        set(handles.Clear_Fovea_Button,'Enable','off');
    end
    count = max(length(foveaScan),length(foveaLocation));
    if count ~= 1
        set(handles.Foveal_Distances,'String','');
    end
    
    % Show the total number of images
    nImagesString = sprintf('/ %d',nImages);
    set(handles.Num_Images, 'String', nImagesString);
    
    % Display the first image
    DisplayImage(hObject,handles,1);
end


%% DISPLAY FUNCTIONS

function handles = DisplayImage(hObject, handles, imageNumber)
% --- Displays the image on the figure
%
%	imageNumber - index of the file to load
%   Handles - structure with handles and user data (see GUIDATA)
% ---
    
    if nargin < 3
        imageNumber = [];
    end    

    % Save the current zoom setting
    if ~isempty(handles.ZOOM_LIMIT)
        currentZoom = get(handles.Image_Axes, {'xlim','ylim'});
        zoom reset;
    end
    
    % Clear the current image axes
    ResetFigureAxes(handles.Image_Axes);
    
    if isempty(imageNumber)
        imageNumber = str2double(get(handles.Image_Number,'String'));
    elseif imageNumber < 1
        imageNumber = 1;
    elseif imageNumber > length(handles.BSCAN_FILES)
        imageNumber = length(handles.BSCAN_FILES);
    end
    
    if isnan(imageNumber)
        return;
    end
    
    enableSlider = get(handles.Image_Slider,'Enable');
    handles.ENABLE_SLIDER = 0;
    guidata(hObject,handles);
    
    if imageNumber < 1
        imageNumber = 1;
    end
    
    % Get the Bscan object if it exists
    if ~isempty(handles.BSCAN_FILES) && ...
       ~isempty(handles.BSCAN_FILES{imageNumber})  
        load(handles.BSCAN_FILES{imageNumber});
    else
        bScan = [];
    end
    handles.BSCAN = bScan;
    
    % Enable the correction options if the bScan exists
    if ~isempty(bScan) && (~isempty(bScan.Layers) || ~isempty(bScan.ClosedContourImage))
        Set_AutomaticRadioButton(handles,'Enable','on');
    else
        Set_AutomaticRadioButton(handles,'Enable','off');
    end
    
    lineThickness = round(str2double(get(handles.Line_Thickness,'String')));
    
    enableReset = 'off';
    enableCorrection = 'off';
    enableAddition = 'off';
        
    % Get the boundaries
    if ~isempty(bScan)
        filename = handles.BSCAN_FILES{imageNumber};
        layerType = -1;
        closedType = -1;
        
        if get(handles.Show_Boundaries_Checkbox,'Value')
        
            % Get the manually segmented closed contour image
            if get(handles.Manual_Radio_Button,'Value') && ...
                ~isempty(bScan.ManualClosedContourImage)
                closedType = 2;
                if get(handles.Closed_Type_Button,'Value')
                    enableReset = 'on';
                    enableCorrection = 'on';
                    enableAddition = 'on';
                end

            % Get the automatic corrected closed contour image
            elseif get(handles.Automatic_Radio_Button,'Value') && ...
                   get(handles.Show_Corrections_Checkbox,'Value') && ...
                   ~isempty(bScan.CorrectedClosedContourImage)       
                closedType = 1;
                if get(handles.Closed_Type_Button,'Value')
                    enableReset = 'on';
                    enableCorrection = 'on';
                    enableAddition = 'on';
                end

            % Get the automatically segmented closed contour image
            elseif get(handles.Automatic_Radio_Button,'Value') && ...
                   ~isempty(bScan.ClosedContourImage)
                closedType = 0;
                if get(handles.Closed_Type_Button,'Value') && ...
                   isempty(bScan.CorrectedClosedContourImage)
                    enableCorrection = 'on';
                    enableAddition = 'on';
                end
            end
            
        
            % Get the manually segmented layers
            if get(handles.Manual_Radio_Button,'Value') && ...
                ~isempty(bScan.ManualLayers)
                layerType = 2;
                if get(handles.Layer_Type_Button,'Value')
                    enableReset = 'on';
                    enableCorrection = 'on';
                    enableAddition = 'on';
                end

            % Get the automatic corrected layers
            elseif get(handles.Automatic_Radio_Button,'Value') && ...
                   get(handles.Show_Corrections_Checkbox,'Value') && ...
                   ~isempty(bScan.CorrectedLayers)       
                layerType = 1;
                if get(handles.Layer_Type_Button,'Value')
                    enableReset = 'on';
                    enableCorrection = 'on';
                    enableAddition = 'on';
                end

            % Get the automatically segmented layers
            elseif get(handles.Automatic_Radio_Button,'Value') && ...
                   ~isempty(bScan.Layers)
                layerType = 0;
                if get(handles.Layer_Type_Button,'Value') && ...
                   isempty(bScan.CorrectedLayers)
                    enableCorrection = 'on';
                    enableAddition = 'on';
                end
            end
        end
        
        image = bScan.getSegmentedImage(-1, closedType, 2, 1, lineThickness);
        handles.CLOSED_CONTOUR_IMAGE = bScan.getClosedContourImage(closedType, 0);
        layers = bScan.getLayers(layerType);
        
    % Boundaries do not exist. Get the raw image
    else
        filename = handles.IMAGE_FILES{imageNumber};
        if isempty(bScan)
            bScan = BScan(filename,imageNumber);
        end
        layerType = -1;
        closedType = -1;
    end
    
    if layerType == -1 && closedType == -1
        layers = [];
        image = bScan.Image;
        handles.CLOSED_CONTOUR_IMAGE = [];
    end
    
    if get(handles.Manual_Radio_Button,'Value') && ...
       ((get(handles.Layer_Type_Button,'Value') && isempty(bScan.ManualLayers)) || ...
        (get(handles.Closed_Type_Button,'Value') && isempty(bScan.ManualClosedContourImage)))
        enableAddition = 'on';
    end
    
    % Enable adding/correcting boundaries
    set(handles.Add_New_Boundary_Button, 'Enable', enableAddition);
    set(handles.Correct_Current_Boundary_Button, 'Enable', enableCorrection);
    set(handles.Reset_Current_Boundary_Button,'Enable',enableReset);
    set(handles.Reset_All_Boundaries_Button,'Enable',enableReset); 
    
    % Set corrected segmentation properties
    if layerType == 1 || closedType == 1
        showSegmentationTime = 0;
        correctedString = 'Automatic - Corrected';
        correctedColor = [1,0,0];
        showCorrectionsCheckbox = 'on';
        
    % Set automatic segmentation properties
    elseif layerType == 0 || closedType == 0
        showSegmentationTime = 1;
        correctedString = 'Automatic - Not Corrected';
        correctedColor = [0,1,0];
        
        if ~isempty(bScan.CorrectedLayers) || ...
           ~isempty(bScan.CorrectedClosedContourImage)
            showCorrectionsCheckbox = 'on';
        else
            showCorrectionsCheckbox = 'off';
        end
        
    % Set manual segmentation properties
    elseif layerType == 2 || closedType == 2
        showSegmentationTime = 0;
        correctedString = 'Manual';
        correctedColor = [1,1,0];
        showCorrectionsCheckbox = 'off';

    % Set raw image properties
    else
        set(handles.Segmentation_Time, 'String', '');        
        showSegmentationTime = 0;
        correctedString = '';
        correctedColor = [0.941,0.941,0.941];
        showCorrectionsCheckbox = 'off';
    end 
    
    image = uint8(image);
    imageHeight = size(image,1);
    imageWidth = size(image,2);
    
    % Set the image size for all callbacks to access
    handles.IMAGE_SIZE = [imageHeight,imageWidth];    
    guidata(hObject,handles);    
    
    % Display the vertical ruler
    totalRulerLength = handles.RULER_LENGTH + handles.RULER_SPACING;
    ruler = 0.941*ones(imageHeight,totalRulerLength)*255;
    rulerHeight = handles.RULER_PIXEL_HEIGHT;
    rulerMiddle = mean(1:handles.RULER_LENGTH);
    rulerRange = (rulerMiddle-1:rulerMiddle+1)+handles.RULER_SPACING;
    
    if rulerHeight > 0
        startRuler = round(imageHeight/2 - rulerHeight/2 + 1);
        endRuler = startRuler + rulerHeight - 1;     
        ruler(endRuler,handles.RULER_SPACING+1:end) = 0;
        ruler(startRuler,handles.RULER_SPACING+1:end) = 0;
        ruler(startRuler:endRuler,rulerRange) = 0;
    end

    if size(image,3) == 3
        ruler = cat(3,ruler, ruler, ruler);
    end
    image = [image,ruler];
    rulerString = sprintf('%d pixels',rulerHeight);
    set(handles.Vertical_Ruler_Pixel_Text,'String',rulerString); 
    
    % Display the horizontal ruler
    ruler = 0.941*ones(totalRulerLength,imageWidth)*255;
    rulerWidth = handles.RULER_PIXEL_WIDTH;
    
    if rulerWidth > 0
        startRuler = round(imageWidth/2 - rulerWidth/2 + 1);
        endRuler = startRuler + rulerWidth - 1;     
        ruler(handles.RULER_SPACING+1:end,endRuler) = 0;
        ruler(handles.RULER_SPACING+1:end,startRuler) = 0;
        ruler(rulerRange,startRuler:endRuler) = 0;
    end
    
    corner = 0.941*ones(size(ruler,1),size(image,2)-size(ruler,2))*255;
    ruler = [ruler,corner];
    if size(image,3) == 3
        ruler = cat(3,ruler, ruler, ruler);
    end
    image = [image;ruler];
    rulerString = sprintf('%d pixels',rulerWidth);
    set(handles.Horizontal_Ruler_Pixel_Text,'String',rulerString);
    
    if rulerHeight > 0 || rulerWidth > 0
        set(handles.Clear_Lines_Button,'Enable','on');
    else
        set(handles.Clear_Lines_Button,'Enable','off');
    end
    
    % Display image
    imshow(image,'Parent',handles.Image_Axes);
    
    % Plot the layers
    for iLayer = 1:size(layers,1)
        axes(handles.Image_Axes);
        hold on;
        color = GetLayerColor(iLayer);
        plot(layers(iLayer,:),color,'LineWidth',lineThickness);
    end
    
    % Format image information
    imageSizeString = sprintf('Image size:  %d x %d pixels',imageHeight,imageWidth);
    
    % Display information about the image
    set(handles.Image_Number,'String',imageNumber);
    set(handles.Image_Filename,'String',filename);
    set(handles.Is_Corrected,'String',correctedString);
    set(handles.Is_Corrected,'BackgroundColor',correctedColor);
    set(handles.Image_Size,'String',imageSizeString); 
    set(handles.Comment_Box,'String',bScan.Comments);
    
    % Display the vertical lines cropping the image
    if get(handles.Show_Crop_Lines_Checkbox,'Value')
        CropSides(handles);
    end
    
    % Display the vertical lines represending distances from the fovea
    if get(handles.Show_Ring_Lines_Checkbox,'Value')
        DrawCircularRings(handles);
    end
    
    % Display information about the fovea
    if isempty(bScan)
        ShowFovea(handles,[]);
    else
        ShowFovea(handles,bScan.Fovea);
    end
    
    % Display foci
    if ~isempty(bScan)
        ShowFoci(handles);
    end
    
    % Set further properties
    set(handles.Is_Corrected_Text,'String',correctedString);
    set(handles.Is_Corrected_Text,'BackgroundColor',correctedColor);
    Set_ShowCorrectionsCheckbox(handles,'Enable',showCorrectionsCheckbox);
    
    % Display the segmentation time
    if showSegmentationTime
        segmentationTimeText = sprintf( ...
            'Segmentation time:  %.2f seconds', bScan.SegmentationTime);  
        segmentationTimeText2 = sprintf( ...
            '%.2f seconds', bScan.SegmentationTime);  
    else
        segmentationTimeText = ''; 
        segmentationTimeText2 = '';
    end
    set(handles.Segmentation_Time,'String',segmentationTimeText);
    set(handles.Auto_Tab_Segmentation_Time,'String',segmentationTimeText2);

    % Set the slider to the correct position if necessary
    sliderPosition = round(get(handles.Image_Slider,'Value'));
    
    if strcmp('on',enableSlider) && sliderPosition ~= imageNumber
        set(handles.Image_Slider,'Value',imageNumber);
    end
    
    %  Enable the show layers checkbox if the image has been segmented    
    if get(handles.Automatic_Radio_Button,'Value') && ...
       (~isempty(bScan.Layers) || ~isempty(bScan.ClosedContourImage))
            Set_ShowBoundariesCheckbox(handles,'Enable','on');
    elseif get(handles.Manual_Radio_Button,'Value') && ...
           (~isempty(bScan.ManualLayers) || ~isempty(bScan.ManualClosedContourImage))
        Set_ShowBoundariesCheckbox(handles,'Enable','on');
    else
        Set_ShowBoundariesCheckbox(handles,'Enable','off');
    end
    
    % Set the zoom setting to it's previous state
    if ~isempty(handles.ZOOM_LIMIT)
        set(handles.Image_Axes, {'xlim','ylim'}, currentZoom);
    else
        zoom reset;
    end    
    
    handles.ENABLE_SLIDER = 1;
    guidata(hObject,handles);
end

function Show_Boundaries_Checkbox_Callback(hObject, eventdata, handles)
% --- Executes on button press in Show_Boundaries_Checkbox
    
    UpdateShowLayers(hObject, handles);
end

function Show_Boundaries_Checkbox2_Callback(hObject, eventdata, handles)
% --- Executes on button press in Show_Boundaries_Checkbox2.

    UpdateShowLayers(hObject, handles)
end

function UpdateShowLayers(hObject, handles)

    % Set the corresponding checkbox
    value = get(hObject,'Value');
    Set_ShowBoundariesCheckbox(handles,'Value',value);
    
    % Redisplay the image
    DisplayImage(hObject,handles); 
end

function Show_Corrections_Checkbox2_Callback(hObject, eventdata, handles)

      UpdateShowCorrections(hObject, handles);
end

function Show_Corrections_Checkbox_Callback(hObject, eventdata, handles)
% --- Executes on button press in Show_Corrections_Checkbox.  

      UpdateShowCorrections(hObject, handles);
end

function UpdateShowCorrections(hObject, handles)

    % Set the corresponding checkbox
    value = get(hObject,'Value');
    Set_ShowCorrectionsCheckbox(handles,'Value',value);
    
    % Redisplay the image
    DisplayImage(hObject,handles); 
end
    
function Viewing_Mode_Panel_SelectionChangeFcn(hObject, eventdata, handles)
% --- Executes when selected object is changed in Viewing_Mode_Panel

    value = get(handles.Automatic_Radio_Button,'Value');
    Set_AutomaticRadioButton(handles,'Value',value);
    
    value = get(handles.Manual_Radio_Button,'Value');
    Set_ManualRadioButton(handles,'Value',value);
    
    Current_Boundary_Callback(hObject, eventdata, handles)
    
    DisplayImage(hObject,handles);
end

function Viewing_Mode_Panel2_SelectionChangeFcn(hObject, eventdata, handles)
% --- Executes when selected object is changed in Viewing_Mode_Panel2

    value = get(handles.Automatic_Radio_Button2,'Value');
    Set_AutomaticRadioButton(handles,'Value',value);
    
    value = get(handles.Manual_Radio_Button2,'Value');
    Set_ManualRadioButton(handles,'Value',value);
    
    Current_Boundary_Callback(hObject, eventdata, handles)
    
    DisplayImage(hObject,handles);
end

function Figure_CloseRequestFcn(hObject, eventdata, handles)
% --- Executes when user attempts to close Figure.

    delete(hObject);
end

function color = GetLayerColor(layerNumber)

    layerNumber = mod(layerNumber,5);
    
    switch (layerNumber)
        case {1}    % blue
            color = 'b';
        case {2}    % magenta
            color = 'm';
        case {3}    % cyan
            color = 'c';
        case {4}    % yellow
            color = 'y';
        case {0}    % green
            color = 'g';
        otherwise
            color = [];
    end
end


%% IMAGE SLIDER/NUMBER FUNCTIONS

function Image_Slider_Callback(hObject, eventdata, handles)
% --- Executes on slider movement

    % Do nothing if the slider is not enabled (if the image count is 1)
    % or if no files exist
    if strcmp('off', get(handles.Image_Slider,'Enable')) || ...
       isempty(handles.IMAGE_FILES) || ~handles.ENABLE_SLIDER
        return;
    end
    
    % Load the image corresponding to the slider position
    sliderNumber = round(get(handles.Image_Slider,'Value'));    
    DisplayImage(hObject,handles,sliderNumber);
end

function Image_Slider_KeyPressFcn(hObject, eventdata, handles)
% --- Executes on key press with focus on Image_Slider and none of its controls.
% hObject    handle to Image_Slider (see GCBO)
% eventdata  structure with the following fields (see UICONTROL)
%	Key: name of the key that was pressed, in lower case
%	Character: character interpretation of the key(s) that was pressed
%	Modifier: name(s) of the modifier key(s) (i.e., control, shift) pressed
% handles    structure with handles and user data (see GUIDATA)

    % Do nothing if the slider is not enabled (if the image count is 1)
    % or if no files exist
    if strcmp('off', get(handles.Image_Slider,'Enable')) || ...
       isempty(handles.IMAGE_FILES) || ~handles.ENABLE_SLIDER
        return;
    end
    
    % Load the image corresponding to the slider position
    sliderNumber = round(get(handles.Image_Slider,'Value'));
    
    switch (eventdata.Key)
        case 'rightarrow'
            sliderNumber = sliderNumber + 1;
        case 'leftarrow'  
            sliderNumber = sliderNumber - 1;
    end
    DisplayImage(hObject,handles,sliderNumber);   
end

function Image_Slider_CreateFcn(hObject, eventdata, handles)
% --- Executes on slider movement

    if isequal(get(hObject,'BackgroundColor'), ...
               get(0,'defaultUicontrolBackgroundColor'))
        
        set(hObject,'BackgroundColor',[.9 .9 .9]);
    end
end

function Image_Number_Callback(hObject, eventdata, handles)
    
    % Clear the text if no images exist
    if isempty(handles.IMAGE_FILES)
        set(handles,'Image_Number','');
        return;
    end
    
    % Get the user input image number
    imageNumber = round(str2double(get(hObject,'String')));
    nImages = length(handles.IMAGE_FILES);

    % Do nothing if the image number is invalid
    if isnan(imageNumber) || imageNumber < 1 || imageNumber > nImages
        return;      
    end
    
    % If valid, set the image slider position to the desired image
    set(handles.Image_Slider,'Value',imageNumber);
    
    % Load the image based on the image slider position
    Image_Slider_Callback(hObject,eventdata,handles);
end

function Image_Number_CreateFcn(hObject, eventdata, handles)

    if ispc && ...
       isequal(get(hObject,'BackgroundColor'), ...
               get(0,'defaultUicontrolBackgroundColor'))
           
        set(hObject,'BackgroundColor','white');
    end
end 


%% SEGMENTATION FUNCTIONS

function Segment_Layers_Button_Callback(hObject, eventdata, handles)
% --- Executes on button press in Segment_Layers_Button

    % Do nothing if no images exist
    if isempty(handles.IMAGE_FILES)
        return;
    end
    
    % Get the folder where the segmented images and data will be saved
    directory = fileparts(handles.IMAGE_FILES{1});    
    if directory == 0
        return;
    end
    saveDir = fullfile(directory,'Segmentation');
    
    % Set properties to show the layers after segmenting
    Set_ShowBoundariesCheckbox(handles,'Value',1);       

    % Get the segmentation parameters
    segmentParams = Get_Parameters(handles);
    
    % Segment the images
    if ~isempty(segmentParams)
        Segment_Images(hObject,handles,saveDir,segmentParams);
    end
end

function isSuccess = Segment_Images(hObject, handles, saveDir, segmentParams)

    isSuccess = 1;
    nImages = length(handles.IMAGE_FILES);
    imageFiles = handles.IMAGE_FILES;
    if isempty(handles.BSCAN_FILES)
        bScanFiles = cell(1,nImages);
    else
        bScanFiles = handles.BSCAN_FILES;
    end
    
    % Determine whether to use parallel processing
    parallel = get(handles.Parallel_Processing_Checkbox,'Value');
    
    % PARALLEL PROCESSING
    if parallel
          
        % Initialize Progress bar 
        handles.WAITBAR = waitbar(0, 'Opening parallel processes...'); 
        guidata(hObject,handles);
                
        % Open matlab pools       
        if matlabpool('size') == 0           
            matlabpool open;
        end
        
        if ~isempty(handles.WAITBAR) && ishandle(handles.WAITBAR)
            waitbar(1/3, handles.WAITBAR, 'Segmenting images...');
        else
            handles.WAITBAR = waitbar(1/3, 'Segmenting images...');
            guidata(hObject,handles);
        end            

        % Loop through each image and segment it
        hTime = tic;
        parfor fileIndex = 1:nImages

            % Determine filenames to save image and data as
            file = imageFiles{fileIndex};
            [path,name] = fileparts(file);
            if isempty(bScanFiles{fileIndex})
                bScanFilename = fullfile(saveDir,strcat(name,'.mat'));
                bScan = BScan(file,fileIndex);
            else
                bScan = load(bScanFiles{fileIndex});
                bScan = bScan.bScan;
                bScanFilename = bScanFiles{fileIndex};
            end

            imageFilename = fullfile(saveDir,strcat(name,'.tif'));

            % Try to segment the image
            bScan.segmentImage(segmentParams);

            % Create the save directory
            if ~exist(saveDir,'dir')
                mkdir(saveDir);
            end

            % Save the results
            bScan.saveBscan(bScanFilename);
            bScan.saveSegmentedImage(imageFilename,0,0,2);
            bScanFiles{fileIndex} = bScanFilename;
        end
        time = toc(hTime);
        
        Set_AutomaticRadioButton(handles,'Value',1);
        handles.BSCAN_FILES = bScanFiles;
        guidata(hObject,handles);
        poolSize = matlabpool('size');
        
        % Close the parallel processes
        if ~isempty(handles.WAITBAR) && ishandle(handles.WAITBAR)
            waitbar(2/3, handles.WAITBAR, 'Closing parallel processes...');
        else
            handles.WAITBAR = waitbar(2/3, 'Closing parallel processes...');
            guidata(hObject,handles);
        end       
        matlabpool close;
        
        % Delete the waitbar
        if ~isempty(handles.WAITBAR) && ishandle(handles.WAITBAR)
            delete(handles.WAITBAR);
        end
        
        % Get the total segmentation time
        timeString1 = 'Total segmentation time using parallel processing';
        timeString2 = ' with %d cores took %.2f seconds for %d image(s).';
        timeString = sprintf(strcat(timeString1,timeString2),poolSize,time,nImages);

        DisplayImage(hObject,handles,nImages);

    % NO PARALLEL PROCESSING
    else
        % Initialize Progress bar
        WAITBAR_MESSAGE = 'Segmenting Image %d / %d...';    
        CANCEL_WAITBAR = 'CancelWaitbar';

        handles.WAITBAR = waitbar( ...
            0, ...
            sprintf(WAITBAR_MESSAGE,1,nImages), ...
            'CreateCancelBtn', ...
            sprintf('setappdata(gcbf,''%s'',1)',CANCEL_WAITBAR)); 

        setappdata(handles.WAITBAR,CANCEL_WAITBAR, 0);
        guidata(hObject,handles);


        % Loop through each image and segment it
        hTime = tic;
        for fileIndex = 1:nImages

            % Update progress bar
            if fileIndex <= nImages
                
                if ~isempty(handles.WAITBAR) && ishandle(handles.WAITBAR)
                    waitbar( ...
                        (fileIndex-1)/nImages, ...
                        handles.WAITBAR, ...
                        sprintf(WAITBAR_MESSAGE, fileIndex, nImages));
                else
                    handles.WAITBAR = waitbar( ...
                        (fileIndex-1)/nImages, ...
                        sprintf(WAITBAR_MESSAGE, fileIndex, nImages));
                    guidata(hObject,handles);
                end       
            end

            %  Check to see if the GUI was closed while segmenting.  If so,
            %  terminate the program instead of proceeding.  Drawnow flushes
            %  the event queue and updates the figure window
            if ~ishandle(handles.Figure)
                return;       
            end

            % Check for Cancel button press. If so, do not 
            % segment subsequent images
            if getappdata(handles.WAITBAR,CANCEL_WAITBAR)
                break;
            end

            % Determine filenames to save image and data as
            file = imageFiles{fileIndex};
            [path,name] = fileparts(file);
            if isempty(bScanFiles{fileIndex})
                bScanFilename = fullfile(saveDir,strcat(name,'.mat'));
                bScan = BScan(file,fileIndex);
            else
                bScan = load(bScanFiles{fileIndex});
                bScan = bScan.bScan;
                bScanFilename = bScanFiles{fileIndex};
            end

            imageFilename = fullfile(saveDir,strcat(name,'.tif'));

            %Segment the image
            error = bScan.segmentImage(segmentParams);
            
            % Report any errors during segmentation
            if error == 0
                success = 1;
            else
                % Display the error message
                msgbox(sprintf( ...
                    ['Unexpected Error Segmenting Image %d.\r\n\r\n' ...
                     'The function %s() at line %d ' ...
                     'threw the following exception: "%s"'], ...
                     fileIndex, ...
                     error.stack(1,1).name, ...
                     error.stack(1,1).line, ...
                     error.message),'Error','replace');

                success = 0;
            end

            % Create the save directory
            if ~exist(saveDir,'dir')
                mkdir(saveDir);
            end

            % Save the results
            bScan.saveBscan(bScanFilename);
            bScan.saveSegmentedImage(imageFilename,0,0,2);
            bScanFiles{fileIndex} = bScanFilename;
            clear('bScan');
            
            if ~success
                continue;
            end

            % Store the segmented filenames for access from other
            % callback methods
            handles.BSCAN_FILES = bScanFiles;
            guidata(hObject,handles);

            % Set correction properties
            Set_AutomaticRadioButton(handles,'Value',1);

            % Display the segmented image on the GUI
            DisplayImage(hObject,handles,fileIndex);
        end
        time = toc(hTime);
        delete(handles.WAITBAR);
        
        % Get the total segmentation time
        timeString1 = 'Total segmentation time without parallel processing';
        timeString2 = ' took %.2f seconds for %d image(s).';
        timeString = sprintf(strcat(timeString1,timeString2,'\r\n'),time,fileIndex);
    end
        
    % Display completion message
    msgbox(['Segmentation is complete! ',timeString],'Replace');
    
    % Save the segmentation time
    fileId = fopen(fullfile(saveDir,'SegmentationTime.txt'), 'a');
    fprintf(fileId, timeString);
    fclose(fileId);
end


%% PARAMETER FUNCTIONS

function SetImageParameters(handles, siteIndex)

    if nargin < 2
        siteIndex = [];
    end
    
    imageNumber = str2double(get(handles.Image_Number,'String'));
    filename = handles.IMAGE_FILES{imageNumber};
    [path,name,ext] = fileparts(filename);
    
    % Get the parameters
    eval(sprintf('params = getParameters_%s(path,ext,siteIndex);',lower(handles.STUDY_TYPE)));
    
    % Set the study sites
    if ~isempty(params.STUDY_SITES)
        set(handles.Study_Site_Popup,'String',params.STUDY_SITES);
        set(handles.Study_Site_Popup,'Value',params.SITE_INDEX + 1);  
    end
    
    % Set other parameters
    Set_AxialSpacing(handles,'String',num2str(params.AXIAL_RESOLUTION));
    Set_LateralSpacing(handles,'String',num2str(params.LATERAL_RESOLUTION));
    set(handles.Invert_Image_Checkbox,'Value',params.INVERT_IMAGE);
    set(handles.Scan_Length,'String',num2str(params.SCAN_LENGTH));
    set(handles.Num_Stack_Images,'String',num2str(handles.NUM_TOTAL_IMAGES));
    set(handles.Eye_Popup,'Value',params.EYE + 1);
    set(handles.Scan_Orientation_Popup,'Value',params.SCAN_ORIENTATION + 1);
    
    if ~isempty(params.SCAN_LENGTH)
        string = sprintf('(across the %.2f mm)',params.SCAN_LENGTH);
        set(handles.Num_Stack_Images_String,'String',string);
    else
        set(handles.Num_Stack_Images_String,'String','');
    end
    
    DrawCircularRings(handles);
end

function EnableAlgorithmParameters(handles, algorithmType)
    
    % Get the parameters
    eval(sprintf('params = %s_getParameters();',lower(algorithmType)));
    
    % Set default parameter visualization
    eye = 'off';
    orientation = 'off';
    segmentCysts = 'off';
    
    % Turn on parameters that exist
    if isfield(params.otherParams,'EYE')
        eye = 'on';
    end
    if isfield(params.otherParams,'SCAN_ORIENTATION')
        orientation = 'on';
    end
    if isfield(params.otherParams,'SEGMENT_CYSTS') && handles.ENABLE_CYST
        segmentCysts = 'on';
    end

    set(handles.Eye_Popup,'Enable',eye);
    set(handles.Scan_Orientation_Popup,'Enable',orientation);
    set(handles.Segment_Cysts_Checkbox,'Enable',segmentCysts);
end

function SetAlgorithmParameters(handles) 
    
    % Enable parameters dependent on the algorithm type
    algorithmIndex = get(handles.Algorithm_Popup,'Value');
    algorithmType = handles.ALGORITHM_TYPES{algorithmIndex};
    
    % Get the parameters based on the algorithm type
    eval(sprintf('params = %s_getParameters();',lower(algorithmType)));
    maxLayersString = sprintf('/ %d',params.graphCutParams.MAX_NUM_LAYERS);
    smoothingCorrection = regexprep(num2str(params.graphCutParams.SMOOTHING_CORRECTION),' *',', ');
    smoothingCorrection = sprintf('%s',smoothingCorrection);

    set(handles.Num_Layers,'String',params.graphCutParams.NUM_LAYERS);
    set(handles.Total_Layers_Text,'String',maxLayersString);
    set(handles.Smoothing_Correction,'String',smoothingCorrection);
end

function SetOtherParameters(handles)

    set(handles.Parallel_Processing_Checkbox,'Value',0);
    set(handles.Segment_Cysts_Checkbox,'Value',0);

    algorithmIndex = get(handles.Algorithm_Popup,'Value');
    if isempty(handles.ALGORITHM_TYPES)
        params.LINE_THICKNESS = 2;
    else
        algorithmType = handles.ALGORITHM_TYPES{algorithmIndex};
        eval(sprintf('params = %s_getParameters;',lower(algorithmType))); 
    end   
    Set_LineThickness(handles,'String',params.LINE_THICKNESS);
end

function Default_Parameters_Button_Callback(hObject, eventdata, handles)
% --- Executes on button press in Default_Parameters_Button.
    
    % Set default parameters related to the loaded image
    SetImageParameters(handles);
    
    % Set all other remaining parameters
    SetOtherParameters(handles);
    
    % Set default parameters for the specified algorithm
    SetAlgorithmParameters(handles);
    
    % Update the image 
    imageNumber = str2double(get(handles.Image_Number,'String'));   
    DisplayImage(hObject,handles,imageNumber);
end

function params = Get_Parameters(handles)

    % Get the default parameters for the specified algorithm
    algorithmIndex = get(handles.Algorithm_Popup,'Value');
    algorithmType = handles.ALGORITHM_TYPES{algorithmIndex};
    eval(sprintf('params = %s_getParameters;',lower(algorithmType)));
    
    % Get the parameters specified in the GUI
    params.graphCutParams.NUM_LAYERS = round(str2double(get(handles.Num_Layers,'String')));
    params.graphCutParams.SMOOTHING_CORRECTION = eval(sprintf('[%s]',get(handles.Smoothing_Correction,'String')));
    params.LINE_THICKNESS = round(str2double(get(handles.Line_Thickness,'String')));
    params.INVERT_IMAGE = get(handles.Invert_Image_Checkbox,'Value');
     
    if isfield(params.otherParams,'SEGMENT_CYSTS')
        segmentCyst = get(handles.Segment_Cysts_Checkbox,'Value');
        params.otherParams.SEGMENT_CYSTS = segmentCyst;
    end
    
    % Display a warning if required parameters have not been input
    lateralRes = str2double(get(handles.Lateral_Resolution,'String'));
    if ~isnan(lateralRes)
        params.LATERAL_RESOLUTION = lateralRes;
    else
        msgbox('Please enter the lateral resolution','Replace');
        params = [];
        return;
    end
    
    axialRes = str2double(get(handles.Axial_Resolution,'String'));
    if ~isnan(axialRes)
        params.AXIAL_RESOLUTION = axialRes;
    else
        msgbox('Please enter the axial resolution','Replace');
        params = [];
        return;
    end
    
    if isfield(params.otherParams,'EYE')  
        eye = get(handles.Eye_Popup,'Value') - 1;
        if eye > 0
            params.otherParams.EYE = eye;
        else
            msgbox('Please select the eye parameter','Replace');
            params = [];
            return;
        end
    end
    
    if isfield(params.otherParams,'SCAN_ORIENTATION')  
        orientation = get(handles.Scan_Orientation_Popup,'Value') - 1;
        if orientation > 0
            params.otherParams.SCAN_ORIENTATION = orientation;
        else
            msgbox('Please select the scan orientation parameter','Replace');
            params = [];
            return;
        end
    end
end

function Algorithm_Popup_Callback(hObject, eventdata, handles)
% --- Executes on selection change in Algorithm_Popup
      
    % Enable parameters dependent on the algorithm type
    algorithmIndex = get(handles.Algorithm_Popup,'Value');
    algorithmType = handles.ALGORITHM_TYPES{algorithmIndex};

    % Semgnetation has been disabled, so do not set paramters
    if strcmpi(get(handles.Algorithm_Popup,'Enable'),'off')
        return;
    end
    
    EnableAlgorithmParameters(handles, algorithmType);
    SetAlgorithmParameters(handles);
end

function Algorithm_Popup_CreateFcn(hObject, eventdata, handles)
% --- Executes during object creation, after setting all properties

    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end
end

function Num_Layers_Callback(hObject, eventdata, handles)

    %  Get the user input number of layers
    nLayers = round(str2double(get(hObject,'String')));  
    
    %  Get the default number of layers for the specified algorithm
    algorithmIndex = get(handles.Algorithm_Popup,'Value');
    algorithmType = handles.ALGORITHM_TYPES{algorithmIndex};
    eval(sprintf('params = %s_getParameters;',lower(algorithmType)));
    
    %  Check the validity of the number  
    maxLayers = params.graphCutParams.MAX_NUM_LAYERS;
    
    if isnan(nLayers) || nLayers > maxLayers
        nLayers = maxLayers;
    elseif nLayers < 1
        nLayers = 1;
    end
    
    set(handles.Num_Layers, 'String', nLayers); 
end

function Num_Layers_CreateFcn(hObject, eventdata, handles)
% --- Executes during object creation, after setting all properties

    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end
end

function Smoothing_Correction_Callback(hObject, eventdata, handles)
% hObject    handle to Smoothing_Correction (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
   
    string = GetArrayFromString(get(handles.Smoothing_Correction,'String'),1,0,0,0.99);
    set(handles.Smoothing_Correction,'String',string);
end

function Smoothing_Correction_CreateFcn(hObject, eventdata, handles)
% --- Executes during object creation, after setting all properties.

    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end
end

function Lateral_Resolution_Callback(hObject, eventdata, handles)
% hObject    handle to Lateral_Resolution (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

    % Study site is no longer set to a preset
    set(handles.Study_Site_Popup,'Value',1);
    
    % Set the lateral resolution
    lateralRes = get(handles.Lateral_Resolution,'String');
    Set_LateralSpacing(handles,'String',lateralRes);
    
    % Reset the ruler
    handles = Set_Ruler_Width(hObject,handles,0);
    DisplayImage(hObject,handles);
end

function Lateral_Resolution_CreateFcn(hObject, eventdata, handles)
% --- Executes during object creation, after setting all properties.
% hObject    handle to Lateral_Resolution (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end
end

function Axial_Resolution_Callback(hObject, eventdata, handles)
% hObject    handle to Axial_Resolution (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    
    % Study site is no longer set to a preset
    set(handles.Study_Site_Popup,'Value',1);
    
    % Set the lateral resolution
    axialRes = get(handles.Axial_Resolution,'String');
    Set_AxialSpacing(handles,'String',axialRes);
    
    % Reset the ruler
    handles = Set_Ruler_Height(hObject,handles,0);
    DisplayImage(hObject,handles);
end

function Axial_Resolution_CreateFcn(hObject, eventdata, handles)
% --- Executes during object creation, after setting all properties.
% hObject    handle to Axial_Resolution (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end
end

function Scan_Orientation_Popup_Callback(hObject, eventdata, handles)
% --- Executes on selection change in Scan_Orientation_Popup.
% hObject    handle to Scan_Orientation_Popup (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns Scan_Orientation_Popup contents as cell array
%        contents{get(hObject,'Value')} returns selected item from Scan_Orientation_Popup
end

function Scan_Orientation_Popup_CreateFcn(hObject, eventdata, handles)
% --- Executes during object creation, after setting all properties.
% hObject    handle to Scan_Orientation_Popup (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end
end

function Eye_Popup_Callback(hObject, eventdata, handles)
% --- Executes on selection change in Eye_Popup
end

function Eye_Popup_CreateFcn(hObject, eventdata, handles)
% --- Executes during object creation, after setting all properties

    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end
end

function Line_Thickness_Callback(hObject, eventdata, handles)

    UpdateLineThickness(hObject, handles);
end

function Line_Thickness2_Callback(hObject, eventdata, handles)
% hObject    handle to Line_Thickness2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

    UpdateLineThickness(hObject, handles);
end

function UpdateLineThickness(hObject, handles)
    
    % Get the user input number of layers
    lineThickness = round(str2double(get(hObject,'String')));
    
    % Check the validity of the number
    if isnan(lineThickness) || lineThickness < 1
        lineThickness = 1;
    end
    
    % Update the line thickness
    Set_LineThickness(handles,'String',lineThickness);
    DisplayImage(hObject, handles);
end

function Line_Thickness_CreateFcn(hObject, eventdata, handles)
% --- Executes during object creation, after setting all properties.

    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end
end

function Line_Thickness2_CreateFcn(hObject, eventdata, handles)
% --- Executes during object creation, after setting all properties.
% hObject    handle to Line_Thickness2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end
end

function Segment_Cysts_Checkbox_Callback(hObject, eventdata, handles)
% --- Executes on button press in Segment_Cysts_Checkbox.
% hObject    handle to Segment_Cysts_Checkbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of Segment_Cysts_Checkbox
end

function Invert_Image_Checkbox_Callback(hObject, eventdata, handles)
% --- Executes on button press in Invert_Image_Checkbox.
% hObject    handle to Invert_Image_Checkbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of Invert_Image_Checkbox
end

function Parallel_Processing_Checkbox_Callback(hObject, eventdata, handles)
% --- Executes on button press in Parallel_Processing_Checkbox.
% hObject    handle to Parallel_Processing_Checkbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
end

%% MANUAL MARKING FUNCTIONS
    
function Boundary_Type_Panel_SelectionChangeFcn(hObject, eventdata, handles)
% --- Executes when selected object is changed in Boundary_Type_Panel
    
    set(handles.Pin_Boundary_Popup,'Value',1');
    ManualInstructions(handles);
    
    % Layer Type
    if get(handles.Layer_Type_Button,'Value')
        %set(handles.Pin_Boundary_Popup,'String',{'Neither','Top','Bottom','Both'});
        set(handles.Correct_Current_Boundary_Button,'String','Correct Current Layer');
        set(handles.Add_New_Boundary_Button,'String','Add New Layer');
        set(handles.Reset_Current_Boundary_Button,'String','Reset Current Layer');
        set(handles.Reset_All_Boundaries_Button,'String','Reset All Layers');
        set(handles.Pin_Boundary_Popup,'Enable','on');
        set(handles.Click_Points_Checkbox,'Enable','on');
        
    % Closed-contour Type
    elseif get(handles.Closed_Type_Button,'Value')
        %set(handles.Pin_Boundary_Popup,'String',{'None','All'});
        set(handles.Correct_Current_Boundary_Button,'String','Trim Region');
        set(handles.Add_New_Boundary_Button,'String','Add Region');
        set(handles.Reset_Current_Boundary_Button,'String','Reset Current Region');
        set(handles.Reset_All_Boundaries_Button,'String','Reset All Regions');
        set(handles.Pin_Boundary_Popup,'Enable','off');
        set(handles.Click_Points_Checkbox,'Enable','off');
    end
    
    % Update the current boundary
    Current_Boundary_Callback(hObject, eventdata, handles);
    
    % Re-display the image
    imageNumber = str2double(get(handles.Image_Number, 'String'));
    DisplayImage(hObject,handles,imageNumber);
end

function Current_Boundary_Callback(hObject, eventdata, handles)

    % Set the boundary to 1 if there is no segmentation
    if isempty(handles.BSCAN)
        set(handles.Current_Boundary,'String',1); 
        return;
    end
    
	boundary = round(str2double(get(handles.Current_Boundary,'String')));
    
    % Get max number of boundaries
    boundaries = GetBoundaries(handles);
    if get(handles.Layer_Type_Button,'Value')
        maxBoundaries = size(boundaries,1);
    elseif get(handles.Closed_Type_Button,'Value')
        maxBoundaries = max(boundaries(:));
    end
    maxBoundaries = max(1,maxBoundaries);
        
    % Do not let the layer number exceed the max
    if boundary > maxBoundaries
        boundary = maxBoundaries;
    elseif isnan(boundary) || boundary < 1 || isempty(maxBoundaries)
        boundary = 1;
    end
    
    set(handles.Current_Boundary, 'String', boundary); 
end

function boundaries = GetBoundaries(handles)   

    % Get the bScan
    bScan = handles.BSCAN;

    % Determine the maximum number of layers
    if get(handles.Layer_Type_Button,'Value')
        
        % In correction mode
        if get(handles.Automatic_Radio_Button2, 'Value')
            if ~isempty(bScan.CorrectedLayers) && ...
                get(handles.Show_Corrections_Checkbox2,'Value')
                boundaries = bScan.CorrectedLayers;
            else
                boundaries = bScan.Layers;
            end

        % In manual mode
        elseif get(handles.Manual_Radio_Button2,'Value')
            boundaries = bScan.ManualLayers;
        end
        
    % Determine the maximum number of closed-contours
    elseif get(handles.Closed_Type_Button,'Value')
        % In correction mode
        if get(handles.Automatic_Radio_Button2, 'Value')
            if ~isempty(bScan.CorrectedClosedContourImage) && ...
                get(handles.Show_Corrections_Checkbox2,'Value')
                boundaries = bScan.CorrectedClosedContourImage;
            else
                boundaries = bScan.ClosedContourImage;
            end

        % In manual mode
        elseif get(handles.Manual_Radio_Button2,'Value')
            boundaries = bScan.ManualClosedContourImage;
        end
    end
end

function Current_Boundary_CreateFcn(hObject, eventdata, handles)
	if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
		set(hObject,'BackgroundColor','white');
	end
end

function Current_Boundary_Up_Callback(hObject, eventdata, handles)
% --- Executes on button press in Current_Boundary_Up.
% hObject    handle to Current_Boundary_Up (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
   
    currentLayer = str2double(get(handles.Current_Boundary,'String'));
    set(handles.Current_Boundary,'String',currentLayer+1);
    Current_Boundary_Callback(hObject, eventdata, handles);
end

function Current_Boundary_Down_Callback(hObject, eventdata, handles)
% --- Executes on button press in Current_Boundary_Down.
% hObject    handle to Current_Boundary_Down (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

    currentLayer = str2double(get(handles.Current_Boundary,'String'));
    set(handles.Current_Boundary,'String',currentLayer-1);
    Current_Boundary_Callback(hObject, eventdata, handles);
end

function Correct_Current_Boundary_Button_Callback(hObject, eventdata, handles)
	
    ManualInstructions(handles);
    
    % Turn off and on to make sure the button is not highlighted in blue
    set(handles.Correct_Current_Boundary_Button,'Visible','off');
    set(handles.Correct_Current_Boundary_Button,'Visible','on');
    
    % Get image information
    boundaryNumber = str2double(get(handles.Current_Boundary,'String')); 
	imageNumber = str2double(get(handles.Image_Number, 'String'));
    bScan = handles.BSCAN;
    
    if isempty(bScan)
        return;
    end

    % Get boundaries
    boundaries = GetBoundaries(handles);
    
    if isempty(boundaries)
        return;
    end
    
    % Make sure the boundary number is valid
    if get(handles.Layer_Type_Button,'Value')
        maxBoundaries = size(boundaries,1);
    elseif get(handles.Closed_Type_Button,'Value')
        maxBoundaries = max(boundaries(:));
    end
    if (boundaryNumber > maxBoundaries)        
        msgbox('Current Layer Number is out of range','Replace');
        return;
    end
    
    % Display the boundaries, making the active boundary red
    DisplayBoundaries(handles, boundaries, boundaryNumber)
    
    % Display the vertical lines cropping the image
    CropSides(handles);

    % Let user click points on the image
    [xCoord,yCoord] = GetUserClickedPoints(handles,hObject,imageNumber);    
    
    if isempty(xCoord)
        return;
    end
    
    % Save corrected boundary
    try
        handles = SaveUpdatedBoundaries(handles, boundaries, ...
            boundaryNumber, xCoord, yCoord, imageNumber);

        Set_ShowBoundariesCheckbox(handles,'Value',1);
        Set_ShowBoundariesCheckbox(handles,'Enable','on');
        Set_ShowCorrectionsCheckbox(handles,'Value',1);  

        % Show the updated image
        DisplayImage(hObject,handles,imageNumber);
        
    % Report any errors with updating the boundaries
    catch exception
        DisplayImage(hObject,handles,imageNumber);
        msgbox(exception.message, 'Warning!','Replace');
    end
end

function DisplayBoundaries(handles, boundaries, boundaryNumber)


    if ~get(handles.Show_Boundaries_Checkbox2,'Value')
        return;
    end
    
    bScan = handles.BSCAN;
    
    % Save the current zoom setting
    if ~isempty(handles.ZOOM_LIMIT)
        currentZoom = get(handles.Image_Axes, {'xlim','ylim'});
        zoom reset;
    end
    
    % Display layers
    if get(handles.Layer_Type_Button,'Value')
        
        imshow(uint8(bScan.Image), 'Parent', handles.Image_Axes);
        axes(handles.Image_Axes);
        hold on;
        if get(handles.Show_Other_Boundaries_Checkbox,'Value')
            for iLayer = 1:size(boundaries,1)
                if isempty(boundaryNumber) || iLayer ~= boundaryNumber
                    plot(boundaries(iLayer,:),'b');
                end
            end
        end
        if ~isempty(boundaryNumber)
            plot(boundaries(boundaryNumber,:),'r');
        end
        
    % Display closed contours
    elseif get(handles.Closed_Type_Button,'Value')
        
        if isempty(boundaries);
            return;
        end
        
        if ~isempty(bScan.SegmentationParams) && ...
            strcmpi(bScan.SegmentationParams.ALGORITHM_TYPE,'rpe_cells')
            boundaries = ~logical(boundaries);
        else
            boundaries = edge(boundaries,'sobel',0.1);
        end
        
        redgreenImage = bScan.Image;
        redgreenImage(boundaries) = 0;
        
        blueImage = bScan.Image;
        blueImage(boundaries) = 255;
        
        image = cat(3,redgreenImage,redgreenImage,blueImage);        
        imshow(uint8(image), 'Parent', handles.Image_Axes);
    end
        
    % Set the zoom setting to it's previous state
    if ~isempty(handles.ZOOM_LIMIT)
        set(handles.Image_Axes, {'xlim','ylim'}, currentZoom);
    else
        zoom reset;
    end   
end

function handles = SaveUpdatedBoundaries(handles, boundaries, ...
    boundaryNumber, xCoord, yCoord, imageNumber)

    bScan = handles.BSCAN;
    imageSize = [bScan.Height, bScan.Width];
    
    % Update the layers
    if get(handles.Layer_Type_Button,'Value')
        
        % Add new layer
        if isempty(boundaryNumber)
           
            % Determine the layer number based on the location of the first 
            % clicked point
            x = round(xCoord(:));
            y = round(yCoord(:));
            invalidIndices = ( x < 1 | x > bScan.Width | ...
                               y < 1 | y > bScan.Height);
            x(invalidIndices) = [];
            y(invalidIndices) = [];

            if isempty(boundaries) || all( y(1) > boundaries(:,x(1)))
                boundaryNumber = size(boundaries,1) + 1;
            else
                boundaryNumber = find( (y(1) - boundaries(:,x(1))) < 1,1,'first');
            end
            
            % Do nothing if the layer number is invalid
            if isempty(boundaryNumber)
                error('Layer to add is invalid.');
            end
            
            % Keep track of the layers above and below the newly added layer
            if boundaryNumber > 1
                layerIndicesPrior = 1:(boundaryNumber - 1);
            else
                layerIndicesPrior = [];
            end    
            if boundaryNumber <= size(boundaries,1)
                layerIndicesAfter = boundaryNumber:size(boundaries,1);
            else
                layerIndicesAfter = [];
            end
            
            % Insert a new layer
            boundaries = [ boundaries(layerIndicesPrior,:); ...
                           NaN(1, imageSize(2)); ...
                           boundaries(layerIndicesAfter,:)      ];
                       
            set(handles.Current_Boundary,'String',boundaryNumber); 
    
            % Fit the user clicked points to a line and add it to the existing
            % layers
            boundaries = GetInterpolatedLayers( ...
                handles, boundaryNumber, [bScan.Height, bScan.Width], boundaries, xCoord, yCoord);
   
        % Correct current layer
        else
            % Interpolate the line
            [interpolatedLayers, xCoord] = GetInterpolatedLayers( ...
                handles, boundaryNumber, imageSize, boundaries, xCoord, yCoord);

            % Only modify points within the outermost clicked points
            startCoord = max(1, min(xCoord(:)));
            endCoord = min(bScan.Width, max(xCoord(:)));    
            boundaries(:, startCoord:endCoord) = interpolatedLayers(:,startCoord:endCoord);
        end
        
        % Store the updated layers
        if get(handles.Automatic_Radio_Button2, 'Value')
            bScan.setCorrectedLayers(boundaries, boundaryNumber);
        else
            bScan.ManualLayers = boundaries;
        end
        
    % Update the closed-contour boundaries
    elseif get(handles.Closed_Type_Button,'Value')
        
        xCoord = round(xCoord);
        yCoord = round(yCoord);
        markedIndices = sub2ind(imageSize, yCoord, xCoord);
        markedBoundary = false(imageSize);
        markedBoundary(markedIndices) = 1;
            
        if isempty(boundaries)
            boundaries = markedBoundary;
        elseif isempty(boundaryNumber)
            boundaries(markedBoundary) = 1;
        else
            boundaries(markedBoundary) = 0;
        end
        
        % Renumber and reorder the boundaries
        boundaries = bwlabel(boundaries);

        % Update the boundary number
        boundaryNumber = unique(boundaries(markedBoundary));
        if boundaryNumber < 1
            boundaryNumber = 1;
        end
        set(handles.Current_Boundary,'String',num2str(boundaryNumber));
        
        if all(~boundaries(:))
            boundaries = [];
        end
        
        % Save the updated boundary
        if get(handles.Automatic_Radio_Button2, 'Value')
            bScan.CorrectedClosedContourImage = boundaries;
        else
            bScan.ManualClosedContourImage = boundaries;
        end
    end
    
    if isempty(handles.BSCAN_FILES{imageNumber})
        [path,name] = fileparts(handles.IMAGE_FILES{imageNumber});
        segmentationFolder = fullfile(path,'Segmentation');
        if ~isdir(segmentationFolder)
            mkdir(segmentationFolder);
        end
        handles.BSCAN_FILES{imageNumber} = fullfile( ...
            segmentationFolder,strcat(name,'.mat'));
    end
    
	save(handles.BSCAN_FILES{imageNumber}, 'bScan');
end

function Add_New_Boundary_Button_Callback(hObject, eventdata, handles)
% --- Executes on button press in Add_New_Boundary_Button.
	
    ManualInstructions(handles);
    
    % Turn off and on to make sure the button is not highlighted in blue
    set(handles.Add_New_Boundary_Button,'Visible','off');
    set(handles.Add_New_Boundary_Button,'Visible','on');
    
    % Get image information 
	imageNumber = str2double(get(handles.Image_Number, 'String'));
    bScan = handles.BSCAN;
    
    % No bScan present. Cannot correct but can segment from scratch
    if isempty(bScan)    
        if get(handles.Automatic_Radio_Button2, 'Value')
            return;
        elseif get(handles.Manual_Radio_Button2, 'Value')
            bScan = BScan(handles.IMAGE_FILES{imageNumber},imageNumber);
            handles.BSCAN = bScan;
            guidata(hObject,handles);
        end
    end

    % Get boundaries
    boundaryNumber = [];
    boundaries = GetBoundaries(handles);
    
    % Display the boundaries, making the active boundary red
    DisplayBoundaries(handles, boundaries, boundaryNumber)
    
    % Display the vertical lines cropping the image
    CropSides(handles);

    % Let user click points on the image
    [xCoord,yCoord] = GetUserClickedPoints(handles,hObject,imageNumber);    
    
    if isempty(xCoord)
        return;
    end
    
    % Save added boundary
    try
        handles = SaveUpdatedBoundaries(handles, boundaries, ....
            boundaryNumber, xCoord, yCoord, imageNumber);

        Set_ShowBoundariesCheckbox(handles,'Value',1);
        Set_ShowBoundariesCheckbox(handles,'Enable','on');

        % Show the updated image
        DisplayImage(hObject,handles,imageNumber);
        
    % Report any errors with updating the boundaries
    catch exception
        DisplayImage(hObject,handles,imageNumber);
        msgbox(exception.message, 'Warning!','Replace');
    end
end

function [xCoord,yCoord] = GetUserClickedPoints(handles,hObject,imageNumber)
 
    state = uisuspend(handles.Figure);   
    try
        EnableDisablePanel(handles,handles.Manual_Panel,handles.Manual_Instructions_String,'off');
        if ~get(handles.Click_Points_Checkbox, 'Value') || ...
           get(handles.Closed_Type_Button,'Value')
       
            closed = get(handles.Closed_Type_Button,'Value');
            
            h = imfreehand(handles.Image_Axes,'Closed',closed);
            if closed
                imageHandles = imhandles(handles.Image_Axes);
                mask = h.createMask(imageHandles(1));
                [yCoord,xCoord] = find(mask);
            else
                coord = wait(h);
                xCoord = coord(:,1);
                yCoord = coord(:,2);
            end
        else
            markerSize = str2double(get(handles.Marker_Size,'String'));
            [xCoord,yCoord] = ginput_modified(-1,1,markerSize);
        end
        
    % Report any errors with ginput
    catch exception
        DisplayImage(hObject,handles,imageNumber);
        xCoord = [];
        yCoord = [];
    end
    uirestore(state);
    
    % Display an error if fewer than 2 points were clicked
    if length(xCoord) < 2
        DisplayImage(hObject,handles,imageNumber);
        msgbox('You must click at least two points','Replace'); 
        xCoord = [];
        yCoord = [];
    end
        
    % Redisplay the original image upon error
    EnableDisablePanel(handles,handles.Manual_Panel,handles.Manual_Instructions_String,'on');  
end

function Reset_Current_Boundary_Button_Callback(hObject, eventdata, handles)
	
    % Turn off and on to make sure the button is not highlighted in blue
    set(handles.Reset_Current_Boundary_Button,'Visible','off');
    set(handles.Reset_Current_Boundary_Button,'Visible','on');
	
    % Get image information 
    imageNumber = str2double(get(handles.Image_Number, 'String'));
    boundaryNumber = str2double(get(handles.Current_Boundary,'String'));
    bScan = handles.BSCAN; 
    
    if isempty(bScan)
        return;
    end
    
    % Reset layers
    if get(handles.Layer_Type_Button,'Value')
        
        % Get the automatic corrected layers
        if get(handles.Automatic_Radio_Button2,'Value')
            if isempty(bScan.CorrectedLayers)
                return;
            end
            layers = bScan.CorrectedLayers;
            
        % Get the manual layers
        elseif get(handles.Manual_Radio_Button2,'Value')
            if isempty(bScan.ManualLayers)
                return;
            end
            layers = bScan.ManualLayers;
        end
        nLayers = size(layers,1);
        
        % Show an error if the layer number is invalid
        if boundaryNumber < 1 || boundaryNumber > nLayers
            msgbox('Current Layer Number is out of range','Replace');
            return;
        end
        
        % Reset current boundary to the automatically segmented boundary if
        % in correction mode
        if get(handles.Automatic_Radio_Button2,'Value')
            
            % If the layer to reset was an added layer, completely remove it
            if find(boundaryNumber == bScan.AddedLayers)
                layers(boundaryNumber,:) = [];
                bScan.AddedLayers(bScan.AddedLayers == boundaryNumber) = [];

                decrementIndices = bScan.AddedLayers > boundaryNumber;
                bScan.AddedLayers(decrementIndices) = bScan.AddedLayers(decrementIndices) - 1;
                set(handles.Current_Boundary,'String',max(1,boundaryNumber - 1)); 

            % If the layer to reset had been automatically segmented, replace
            % it with the segmented layer
            else
                nAddedLayersPrior = sum(boundaryNumber - bScan.AddedLayers > 0);
                layers(boundaryNumber,:) = bScan.Layers(boundaryNumber - nAddedLayersPrior,:);        
            end

            if any(size(layers) ~= size(bScan.Layers)) || any(layers(:) - bScan.Layers(:))
                bScan.CorrectedLayers = layers;
            else
                bScan.CorrectedLayers = [];
            end
            
        % Remove the line all together if in manual marking mode
        elseif get(handles.Manual_Radio_Button2,'Value')
            
            layers(boundaryNumber,:) = [];
            if any(~size(layers))
                layers = [];
            end

            % Decrement the current layer if it was at the max
            if boundaryNumber == nLayers
                set(handles.Current_Boundary,'String',max(1,boundaryNumber - 1)); 
            end
            bScan.ManualLayers = layers;
        end

    % Reset closed contour boundaries
    elseif get(handles.Closed_Type_Button,'Value')     
        
        % Get the automatic corrected layers
        if get(handles.Automatic_Radio_Button2,'Value')
            boundaries = bScan.CorrectedClosedContourImage;
        % Get the manual layers
        elseif get(handles.Manual_Radio_Button2,'Value')
            boundaries = bScan.ManualClosedContourImage;
        end
        nBoundaries = max(boundaries(:));
        
        % Show an error if the layer number is invalid
        if boundaryNumber < 1 || boundaryNumber > nBoundaries
            msgbox('Current Boundary Number is out of range','Replace');
            return;
        end
        
        % See if there is only one boundary there
        boundaryIndices = unique(boundaries(boundaries > 0));
        if length(boundaryIndices) == 1
            if boundaryIndices == boundaryNumber
                boundaries = [];
            else
                msgbox('Current Boundary Number is out of range','Replace');
                return;
            end
        else
            boundaries(boundaries == boundaryNumber) = 0; 
            boundaries = bwlabel(boundaries);
        end
        
        % Reset current boundary to the automatically segmented boundary if
        % in correction mode
        if get(handles.Automatic_Radio_Button2,'Value')
            boundaries(bScan.ClosedContourImage == boundaryNumber) = boundaryNumber;
            bScan.CorrectedClosedContourImage = boundaries;
            
        % Remove the boundary all together if in manual marking mode
        elseif get(handles.Manual_Radio_Button2,'Value')
             bScan.ManualClosedContourImage = boundaries;
        end
        
        % Reset the current boundary
        currentBoundary = str2double(get(handles.Current_Boundary, 'String'));
        maxBoundary = max(boundaries(:));
        if currentBoundary > maxBoundary
            set(handles.Current_Boundary,'String',maxBoundary);
        end
    end
    
    % Save the updated image
	save(handles.BSCAN_FILES{imageNumber}, 'bScan');
    
    Set_ShowBoundariesCheckbox(handles,'Value',1);
    Set_ShowBoundariesCheckbox(handles,'Enable','on');
    
	DisplayImage(hObject,handles,imageNumber);
end

function Reset_All_Boundaries_Button_Callback(hObject, eventdata, handles)
	
    % Turn off and on to make sure the button is not highlighted in blue
    set(handles.Reset_All_Boundaries_Button, 'Visible', 'off');
    set(handles.Reset_All_Boundaries_Button, 'Visible', 'on');
	
    bScan = handles.BSCAN; 
  
    % Reset layers
    if get(handles.Layer_Type_Button,'Value')
        % Reset all layers to the automatically segmented layers if in
        % correction mode
        if get(handles.Automatic_Radio_Button2,'Value')
            bScan.CorrectedLayers = [];	
            bScan.AddedLayers = [];
            if str2double(get(handles.Current_Boundary,'String')) > size(bScan.Layers,1)
                set(handles.Current_Boundary,'String',size(bScan.Layers,1));
            end

        % Reset to blank image if in manual marking mode
        elseif get(handles.Manual_Radio_Button2,'Value')
            bScan.ManualLayers = [];
            set(handles.Current_Boundary,'String',1);
        end
        
    % Reset closed contours
    elseif get(handles.Closed_Type_Button,'Value')
        % Reset all boundaries to the automatically segmented boundaries if
        % in correction mode
        if get(handles.Automatic_Radio_Button2,'Value')
            bScan.CorrectedClosedContourImage = [];

        % Reset to blank image if in manual marking mode
        elseif get(handles.Manual_Radio_Button2,'Value')
            bScan.ManualClosedContourImage = [];
            set(handles.Current_Boundary,'String',1);
        end
    end
    
    % Display the updated image
    imageNumber = str2double(get(handles.Image_Number,'String'));
    save(handles.BSCAN_FILES{imageNumber},'bScan');   
        
    Set_ShowBoundariesCheckbox(handles,'Value',1);
    Set_ShowBoundariesCheckbox(handles,'Enable','on');
    
    DisplayImage(hObject,handles,imageNumber);    
end

function [layers, xcoord, ycoord] = GetInterpolatedLayers(handles, layerNumber, imageSize, layers, xcoord, ycoord)

    % Make sure the coordinates lie on a pixel
    xcoord = round(xcoord(:));
    ycoord = round(ycoord(:));
    
    % Remove duplicate coordinates, since interpolation cannot deal with 
    % two markings on exact same x position
    [b,unique_x,n]=unique(xcoord,'last');
    xcoord = xcoord(unique_x);
    ycoord = ycoord(unique_x);
    
    % Fit the coordinates to a line
    fittingOptions = fitoptions('method','NonlinearLeastSquares','Lower',[-Inf,-Inf,0,-Inf,-Inf,0],'Robust','off');
    fittingType = fittype('cubicinterp');
    
    warning('off', 'curvefit:fit:mismatchedOptions');
    fittedLine = fit(xcoord, ycoord, fittingType, fittingOptions);    
    warning('on', 'curvefit:fit:mismatchedOptions');
    
    line = round(fittedLine(1: imageSize(2)))';    
    line(line < 1) = 1;
    line(line > imageSize(1)) = imageSize(1);
    
    % Make sure the layers do not cross
    switch get(handles.Pin_Boundary_Popup,'Value')
        case 1  % Neither
            pinTop = 0;
            pinBottom = 0;
        case 2  % Top
            pinTop = 1;
            pinBottom = 0;
        case 3  % Bottom
            pinTop = 0;
            pinBottom = 1;
        case 4  % Both
            pinTop = 1;
            pinBottom = 1;
    end
    numLayers = size(layers,1);
    if layerNumber > 1
        if pinTop
            previousLayer = layers(layerNumber - 1,:);
            invalidIndices = (line < previousLayer);
            line(invalidIndices) = previousLayer(invalidIndices);
        else
            for iLayer = 1:layerNumber-1
                topLayer = layers(iLayer,:);
                invalidIndices = (line < topLayer);
                layers(iLayer,invalidIndices) = line(invalidIndices);
            end
        end
    end    
    if layerNumber < numLayers
        if pinBottom
            postLayer = layers(layerNumber + 1,:);
            invalidIndices = (line > postLayer);
            line(invalidIndices) = postLayer(invalidIndices);
        else
            for iLayer = layerNumber+1:numLayers
                bottomLayer = layers(iLayer,:);
                invalidIndices = (line > bottomLayer);
                layers(iLayer,invalidIndices) = line(invalidIndices);
            end
        end
    end
    
    if isempty(layers)
        layers = line;
    else
        layers(layerNumber,:) = line;
    end
end

function EnableDisablePanel(handles,panelHandle,instructionHandle,visibility)

    set(handles.Load_Tab,'Visible',visibility);
    set(handles.Automatic_Tab,'Visible',visibility);
    set(handles.Manual_Tab,'Visible',visibility);
    set(handles.Review_Tab,'Visible',visibility);  
    
    set(panelHandle,'Visible',visibility);  
    
    set(handles.Image_Slider,'Visible',visibility);  
    set(handles.Image_Number,'Visible',visibility);
    set(handles.Num_Images,'Visible',visibility);
    set(handles.Save_Image_Button,'Visible',visibility);

    
    if strcmpi(visibility,'off')
        set(instructionHandle,'Visible','on');
    elseif strcmpi(visibility,'on');
        set(instructionHandle,'Visible','off');
    end
end

function Pin_Boundary_Popup_Callback(hObject, eventdata, handles)
% --- Executes on selection change in Pin_Boundary_Popup.
% hObject    handle to Pin_Boundary_Popup (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns Pin_Boundary_Popup contents as cell array
%        contents{get(hObject,'Value')} returns selected item from Pin_Boundary_Popup
end

function Pin_Boundary_Popup_CreateFcn(hObject, eventdata, handles)
% --- Executes during object creation, after setting all properties.
% hObject    handle to Pin_Boundary_Popup (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end
end

function Click_Points_Checkbox_Callback(hObject, eventdata, handles)
% --- Executes on button press in Click_Points_Checkbox.
% hObject    handle to Click_Points_Checkbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of Click_Points_Checkbox
end

function Show_Other_Boundaries_Checkbox_Callback(hObject, eventdata, handles)
% --- Executes on button press in Show_Other_Boundaries_Checkbox.
% hObject    handle to Show_Other_Boundaries_Checkbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of Show_Other_Boundaries_Checkbox
end

function Marker_Size_Callback(hObject, eventdata, handles)
% hObject    handle to Marker_Size (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of Marker_Size as text
%        str2double(get(hObject,'String')) returns contents of Marker_Size as a double

    markerSize = get(handles.Marker_Size,'String');
    
    if isempty(markerSize)
        return;
    end
    
    markerSize = round(str2double(markerSize));
    
    if isnan(markerSize) || markerSize < 1
        markerSize = 1;
    end
    
    set(handles.Marker_Size,'String',markerSize);
end

function Marker_Size_CreateFcn(hObject, eventdata, handles)
% --- Executes during object creation, after setting all properties.
% hObject    handle to Marker_Size (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end
end

function Figure_WindowButtonMotionFcn(hObject, eventdata, handles)
% --- Executes on mouse motion over figure - except title and menu.
% hObject    handle to Figure (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    
    % Get the coordinates of the mouse cursor
    cursorPosition = get(handles.Image_Axes,'CurrentPoint'); 
    xCursor = round(cursorPosition(1,1));
    yCursor = round(cursorPosition(1,2));
            
    % Do nothing if
    % -- Not in the Manual tab in Closed contour mode
    % -- The cursor is out of the bounds of the image
    % -- Closed contours do not exist
    % -- The cursor is not overlying a closed contour
    if isempty(handles.IMAGE_SIZE) || ...
       isempty(handles.CLOSED_CONTOUR_IMAGE) || ...
       strcmpi('on',get(handles.Manual_Tab,'Enable')) || ...
       ~get(handles.Closed_Type_Button,'Value') || ...
       (xCursor < 1) || (xCursor > size(handles.CLOSED_CONTOUR_IMAGE,2)) || ...
       (yCursor < 1) || (yCursor > size(handles.CLOSED_CONTOUR_IMAGE,1)) || ...
       handles.CLOSED_CONTOUR_IMAGE(yCursor,xCursor) == 0
        return;
    end
    
    % Display the boundary number located at the mouse cursor
%     message = sprintf('Boundary %d', handles.CLOSED_CONTOUR_IMAGE(yCursor,xCursor));
%     text(xCursor, yCursor, message);
%     helpdlg(message);

end

%% RULER FUNCTIONS

function Ruler_Width_Callback(hObject, eventdata, handles)

    handles = Set_Ruler_Width(hObject,handles,1);
    DisplayImage(hObject,handles);
end

function Ruler_Width_CreateFcn(hObject, eventdata, handles)
% --- Executes during object creation, after setting all properties

    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end
end

function Lateral_Resolution2_Callback(hObject, eventdata, handles)

    % Study site is no longer set to a preset
    set(handles.Study_Site_Popup,'Value',1);
    
    % Set the lateral resolution
    lateralRes = get(handles.Lateral_Resolution2,'String');
    Set_LateralSpacing(handles,'String',lateralRes);
    
    % Reset the ruler
    handles = Set_Ruler_Width(hObject,handles,0);
    DisplayImage(hObject,handles);
end

function Lateral_Resolution2_CreateFcn(hObject, eventdata, handles)
% --- Executes during object creation, after setting all properties

    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end
end

function handles = Set_Ruler_Width(hObject, handles, resetRuler)

	rulerLength = str2double(get(handles.Ruler_Width,'String'));
    lateralRes = str2double(get(handles.Lateral_Resolution,'String'));
   
    if isnan(rulerLength) || rulerLength <= 0
        rulerLength = NaN;
        set(handles.Ruler_Width,'String','');
    end
    if isnan(lateralRes) || lateralRes <= 0
        lateralRes = NaN;
        Set_LateralSpacing(handles,'String','');       
    end

    % Do not show the ruler if the scale cannot be calculated
    if isempty(handles.IMAGE_FILES) || isnan(lateralRes) || isnan(rulerLength)
        handles.RULER_PIXEL_WIDTH = 0;
        guidata(hObject,handles);
        return;
    end
    
    % Calculate the ruler scale
    imagePixelWidth = handles.IMAGE_SIZE(2);
    rulerPixelWidth = round(rulerLength / lateralRes);

    % Do not show the ruler if the ruler length and image with are
    % incompatible
    if rulerPixelWidth <= 0 || rulerPixelWidth > imagePixelWidth
        if resetRuler
            set(handles.Ruler_Width,'String',''); 
        else
            Set_LateralSpacing(handles,'String','');
        end
        handles.RULER_PIXEL_WIDTH = 0;
        guidata(hObject,handles);
        return;
    end
    
    % Make the scale accessible to other callback functions
    handles.RULER_PIXEL_WIDTH = rulerPixelWidth;
    guidata(hObject,handles);
end

function ResetFigureAxes(figureHandle)
    cla(figureHandle,'reset');
    set(figureHandle, 'XTick', []);
    set(figureHandle, 'YTick', []);
    set(figureHandle, 'XColor', [0.941, 0.941, 0.941]);
    set(figureHandle, 'YColor', [0.941, 0.941, 0.941]);
    set(figureHandle, 'Color', [0.941, 0.941, 0.941]);
end
    
function Clear_Lines_Button_Callback(hObject, eventdata, handles)
% --- Executes on button press in Clear_Lines_Button

    DisplayImage(hObject,handles);
end

function Figure_WindowButtonDownFcn(hObject, eventdata, handles)
% --- Executes on mouse press over figure background, over a disabled or
% --- inactive control, or over an axes background.

    if (isempty(handles.RULER_PIXEL_WIDTH) || handles.RULER_PIXEL_WIDTH == 0) && ...
       (isempty(handles.RULER_PIXEL_HEIGHT) || handles.RULER_PIXEL_HEIGHT == 0)
        return;
    end
    
    % Get the coordinates of the mouseclick
    clickPosition = get(handles.Image_Axes,'CurrentPoint'); 
    xClick = clickPosition(1,1);
    yClick = clickPosition(1,2);
    
    % Determine whether to plot the horizontal or vertical ruler
    isHorizontal = get(handles.Horizontal_Ruler_Button,'Value');
            
    % Plot the ruler on the image
    if (xClick > 0) && (xClick < handles.IMAGE_SIZE(2)) && ...
       (yClick > 0) && (yClick < handles.IMAGE_SIZE(1))
          
        axes(handles.Image_Axes);
        hold on;
        
        if isHorizontal && ~isempty(handles.RULER_PIXEL_WIDTH) && handles.RULER_PIXEL_WIDTH > 0
            halfLength = handles.RULER_PIXEL_WIDTH/2;
            xStart = xClick-halfLength;
            xEnd = xClick+halfLength;
            plot(xStart:xEnd,yClick,'y');
            plot(xStart:xEnd,yClick+1,'y');
            plot(xStart,yClick-2:yClick+3,'y');
            plot(xEnd,yClick-2:yClick+3,'y');
        elseif ~isHorizontal && ~isempty(handles.RULER_PIXEL_HEIGHT) && handles.RULER_PIXEL_HEIGHT > 0
            halfLength = handles.RULER_PIXEL_HEIGHT/2;
            yStart = yClick-halfLength;
            yEnd = yClick+halfLength;
            plot(xClick,yStart:yEnd,'y');
            plot(xClick+1,yStart:yEnd,'y');
            plot(xClick-2:xClick+3,yStart,'y');
            plot(xClick-2:xClick+3,yEnd,'y');
        end
    end
end

function Axial_Resolution2_Callback(hObject, eventdata, handles)
% hObject    handle to Axial_Resolution (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    
    % Study site is no longer set to a preset
    set(handles.Study_Site_Popup,'Value',1);
    
    % Set the lateral resolution
    axialRes = get(handles.Axial_Resolution2,'String');
    Set_AxialSpacing(handles,'String',axialRes);
    
    % Reset the ruler
    handles = Set_Ruler_Height(hObject,handles,0);
    DisplayImage(hObject,handles);
end

function Axial_Resolution2_CreateFcn(hObject, eventdata, handles)
% --- Executes during object creation, after setting all properties.
% hObject    handle to Axial_Resolution (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end
end

function Ruler_Height_Callback(hObject, eventdata, handles)
% hObject    handle to Ruler_Height (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

    handles = Set_Ruler_Height(hObject,handles,1);
    DisplayImage(hObject,handles);
end

function Ruler_Height_CreateFcn(hObject, eventdata, handles)
% --- Executes during object creation, after setting all properties.
% hObject    handle to Ruler_Height (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end
end

function handles = Set_Ruler_Height(hObject, handles, resetRuler)

	rulerLength = str2double(get(handles.Ruler_Height,'String'));
    axialRes = str2double(get(handles.Axial_Resolution,'String'));
   
    if isnan(rulerLength) || rulerLength <= 0
        rulerLength = NaN;
        set(handles.Ruler_Height,'String','');
    end
    if isnan(axialRes) || axialRes <= 0
        axialRes = NaN;
        Set_AxialSpacing(handles,'String','');
    end

    % Do not show the ruler if the scale cannot be calculated
    if isempty(handles.IMAGE_FILES) || isnan(axialRes) || isnan(rulerLength)
        handles.RULER_PIXEL_HEIGHT = 0;
        guidata(hObject,handles);
        return;
    end
    
    % Calculate the ruler scale
    imagePixelHeight = handles.IMAGE_SIZE(1);
    rulerPixelHeight = round(rulerLength / axialRes);

    % Do not show the ruler if the ruler length and image with are
    % incompatible
    if rulerPixelHeight <= 0 || rulerPixelHeight > imagePixelHeight
        if resetRuler
            set(handles.Ruler_Height,'String',''); 
        else
            Set_AxialSpacing(handles,'String','');
        end
        handles.RULER_PIXEL_HEIGHT = 0;
        guidata(hObject,handles);
        return;
    end
    
    % Make the scale accessible to other callback functions
    handles.RULER_PIXEL_HEIGHT = rulerPixelHeight;
    guidata(hObject,handles);
end


%% REVIEW FUNCTIONS

function Edit_Comment_Button_Callback(hObject, eventdata, handles)
% --- Executes on button press in Edit_Comment_Button.
% hObject    handle to Edit_Comment_Button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

    set(handles.Comment_Box, 'Enable', 'on');
end

function Apply_Comment_Button_Callback(hObject, eventdata, handles)
% --- Executes on button press in Apply_Comment_Button.
% hObject    handle to Apply_Comment_Button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

    % disable the comment box
    set(handles.Comment_Box, 'Enable', 'off');
    
    % instantiate bscan if it does not already exist 
    imageNumber = str2double(get(handles.Image_Number,'String'));  
    bScan = handles.BSCAN;
    if isempty(bScan)
        bScan = BScan(handles.IMAGE_FILES{imageNumber},imageNumber);
    end
    
    % set the comment string
    commentString = get(handles.Comment_Box, 'String');
    bScan.Comments = commentString;
        
    % save the updated bscan
    if isempty(handles.BSCAN_FILES{imageNumber})
        [path,name] = fileparts(handles.IMAGE_FILES{imageNumber});
        segmentationFolder = fullfile(path,'Segmentation');
        if ~isdir(segmentationFolder)
            mkdir(segmentationFolder);
        end
        handles.BSCAN_FILES{imageNumber} = fullfile( ...
            segmentationFolder,strcat(name,'.mat'));
    end
    save(handles.BSCAN_FILES{imageNumber},'bScan');   
    handles.BSCAN = bScan;
    guidata(hObject,handles);
end

function Comment_Box_Callback(hObject, eventdata, handles)
% hObject    handle to Comment_Box (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of Comment_Box as text
%        str2double(get(hObject,'String')) returns contents of Comment_Box as a double
end

function Comment_Box_CreateFcn(hObject, eventdata, handles)
% --- Executes during object creation, after setting all properties.
% hObject    handle to Comment_Box (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end
end

function Clear_Fovea_Button_Callback(hObject, eventdata, handles)
% --- Executes on button press in Clear_Fovea_Button.
% hObject    handle to Clear_Fovea_Button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

    Set_Fovea(hObject,eventdata,handles,[]);
end

function Select_Fovea_Button_Callback(hObject, eventdata, handles)
% --- Executes on button press in Select_Fovea_Button.
% hObject    handle to Select_Fovea_Button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
   [foveaCol,foveaRow] = ginput_modified(1,0);
   Set_Fovea(hObject,eventdata,handles,[round(foveaRow),round(foveaCol)]);
end

function Set_Fovea(hObject,eventdata,handles,fovea)
    
    bScan = handles.BSCAN;
    imageNumber = str2double(get(handles.Image_Number,'String'));
    
    if isempty(bScan)
        bScan = BScan(handles.IMAGE_FILES{imageNumber},imageNumber);
    end
    bScan.Fovea = fovea;    
    
    ind = (handles.FOVEA_SCANS == imageNumber);
    
    if isempty(fovea)
        handles.FOVEA_SCANS(ind) = [];
        handles.FOVEA_LOCATIONS(ind) = [];
    elseif sum(ind) == 0
        handles.FOVEA_SCANS = [handles.FOVEA_SCANS, imageNumber];
        handles.FOVEA_LOCATIONS = [handles.FOVEA_LOCATIONS, {fovea}];
    else
        handles.FOVEA_LOCATIONS{ind} = fovea;
    end

    % save the updated bscan
    if isempty(handles.BSCAN_FILES{imageNumber})
        [path,name] = fileparts(handles.IMAGE_FILES{imageNumber});
        segmentationFolder = fullfile(path,'Segmentation');
        if ~isdir(segmentationFolder)
            mkdir(segmentationFolder);
        end
        handles.BSCAN_FILES{imageNumber} = fullfile( ...
            segmentationFolder,strcat(name,'.mat'));
    end
                    
    save(handles.BSCAN_FILES{imageNumber},'bScan'); 
    set(handles.Clear_Fovea_Button,'Enable','on');
    handles.BSCAN = bScan;
    guidata(hObject,handles);
    
    Foveal_Distances_Callback(hObject,eventdata,handles);
end

function ShowFovea(handles,fovea)
    
    notFoveaString = 'Fovea is not present';
    foveaString = 'Row, Col :  (%d,%d)';
    bScan = handles.BSCAN;  
    
    if isempty(fovea) && isempty(bScan)
        set(handles.Show_Fovea_Checkbox,'Enable','off');
        set(handles.Fovea_String,'String',notFoveaString);
        return;
    end
        
    % instantiate bscan if it does not already exist 
    if isempty(bScan)            
        imageNumber = str2double(get(handles.Image_Number,'String'));
        bScan = BScan(handles.IMAGE_FILES{imageNumber},imageNumber);
    end
        
    % Fovea is not present
    if isempty(fovea)    
        set(handles.Show_Fovea_Checkbox,'Enable','off');
        set(handles.Fovea_String,'String',notFoveaString);
        set(handles.Clear_Fovea_Button,'Enable','on');
        
    % Fovea coordinates are invalid
    elseif fovea(1) < 1 || fovea(1) > bScan.Height || ...
           fovea(2) < 1 || fovea(2) > bScan.Width
        msgbox('Fovea coordinates are out of bounds','Error','Replace'); 
        return;
        
    % Set fovea coordinates
    else
        set(handles.Show_Fovea_Checkbox,'Enable','on');
        set(handles.Fovea_String,'String',sprintf(foveaString,fovea(1),fovea(2)));
    end
    
    % Display fovea
    if ~isempty(fovea) && get(handles.Show_Fovea_Checkbox,'Value')
        axes(handles.Image_Axes);
        hold on;
        plot(fovea(2),fovea(1),'*y');  
        set(handles.Clear_Fovea_Button,'Enable','on');
    else
        set(handles.Clear_Fovea_Button,'Enable','off'); 
    end
end

function Show_Fovea_Checkbox_Callback(hObject, eventdata, handles)
% --- Executes on button press in Show_Fovea_Checkbox.
% hObject    handle to Show_Fovea_Checkbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of Show_Fovea_Checkbox
    DisplayImage(hObject,handles);
end

function Select_Foci_1_Button_Callback(hObject, eventdata, handles)
% --- Executes on button press in Select_Foci_1_Button.
% hObject    handle to Select_Foci_1_Button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
   Click_Foci(hObject,handles,1,'g');
   ShowFoci(handles);
end

function Select_Foci_2_Button_Callback(hObject, eventdata, handles)
% --- Executes on button press in Select_Foci_2_Button.
% hObject    handle to Select_Foci_2_Button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
   Click_Foci(hObject,handles,2,'r');
   ShowFoci(handles);
end

function Show_Foci_1_Checkbox_Callback(hObject, eventdata, handles)
% --- Executes on button press in Show_Foci_1_Checkbox.
% hObject    handle to Show_Foci_1_Checkbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    DisplayImage(hObject,handles);
end

function Show_Foci_2_Checkbox_Callback(hObject, eventdata, handles)
% --- Executes on button press in Show_Foci_2_Checkbox.
% hObject    handle to Show_Foci_2_Checkbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    DisplayImage(hObject,handles);
end

function Clear_Foci_1_Button_Callback(hObject, eventdata, handles)
% --- Executes on button press in Clear_Foci_1_Button.
% hObject    handle to Clear_Foci_1_Button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    Set_Foci(hObject,handles,[],1,1);
    DisplayImage(hObject,handles);
end

function Clear_Foci_2_Button_Callback(hObject, eventdata, handles)
% --- Executes on button press in Clear_Foci_2_Button.
% hObject    handle to Clear_Foci_2_Button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    Set_Foci(hObject,handles,[],2,1);
    DisplayImage(hObject,handles);
end

function Click_Foci(hObject,handles,fociSet,color)
    
    if nargin < 4
        color = [];
    end

	imageNumber = str2double(get(handles.Image_Number, 'String'));
    
    % Let user click points on the image
    try
        EnableDisablePanel(handles,handles.Review_Panel,handles.Review_Instructions_String,'off');
        markerSize = str2double(get(handles.Marker_Size,'String'));
        [xFoci,yFoci] = ginput_modified(-1,1,markerSize,color);        
        EnableDisablePanel(handles,handles.Review_Panel,handles.Review_Instructions_String,'on');
        foci = round([yFoci,xFoci]);
        
    % Report any errors with ginput
    catch exception
        msgbox(sprintf('%s\r\n\r\n%s:\r\n%s', ...
            'Error! Please restart the program. ', ...
            'Ginput failed with the following exception', ...
            exception.message), 'Error! Restart the Program!','Replace');
        
        % Redisplay the original image upon error    
        EnableDisablePanel(handles,handles.Review_Panel,handles.Review_Instructions_String,'on');   
        DisplayImage(hObject,handles,imageNumber);
        return;
    end
    
    Set_Foci(hObject,handles,foci,fociSet,0);
end

function Set_Foci(hObject,handles,foci,fociSet,replaceFoci)
        
    bScan = handles.BSCAN;
	imageNumber = str2double(get(handles.Image_Number, 'String'));
    if isempty(bScan)
        bScan = BScan(handles.IMAGE_FILES{imageNumber}, imageNumber);
    end
    
    % Remove invalid foci
    if ~isempty(foci)
        invalidFoci = foci(:,1) > bScan.Height | foci(:,2) > bScan.Width;
        foci(invalidFoci) = [];
    end

    % save the updated bscan
    if isempty(handles.BSCAN_FILES{imageNumber})
        [path,name] = fileparts(handles.IMAGE_FILES{imageNumber});
        segmentationFolder = fullfile(path,'Segmentation');
        if ~isdir(segmentationFolder)
            mkdir(segmentationFolder);
        end
        handles.BSCAN_FILES{imageNumber} = fullfile( ...
            segmentationFolder,strcat(name,'.mat'));
    end
    
    % Add the foci
    if fociSet == 1
        if ~replaceFoci
            foci = [bScan.Foci1;foci];
        end
        bScan.Foci1 = foci;
    elseif fociSet == 2
        if ~replaceFoci
            foci = [bScan.Foci2;foci];
        end
        bScan.Foci2 = foci;
    end
    handles.BSCAN = bScan; 
    guidata(hObject, handles);
                    
    save(handles.BSCAN_FILES{imageNumber},'bScan'); 
end

function ShowFoci(handles)

    bScan = handles.BSCAN;
    
    % Determine whether to show the foci
    enableFoci1 = 'off';
    enableFoci2 = 'off';
    
    if ~isempty(bScan)
        if ~isempty(bScan.Foci1)
            enableFoci1 = 'on';
        end
        if ~isempty(bScan.Foci2)
            enableFoci2 = 'on';
        end
    end
    
    set(handles.Show_Foci_1_Checkbox,'Enable',enableFoci1);
    set(handles.Clear_Foci_1_Button,'Enable',enableFoci1);
    set(handles.Show_Foci_2_Checkbox,'Enable',enableFoci2);
    set(handles.Clear_Foci_2_Button,'Enable',enableFoci2);
        
    % Instantiate bscan if it does not already exist 
    if isempty(bScan)            
        imageNumber = str2double(get(handles.Image_Number,'String'));
        bScan = BScan(handles.IMAGE_FILES{imageNumber}, imageNumber);
    end
    
    % Display first set of foci
    if ~isempty(bScan.Foci1) && get(handles.Show_Foci_1_Checkbox,'Value')
        axes(handles.Image_Axes);
        hold on;
        for iPoint = 1:size(bScan.Foci1,1)
            plot(bScan.Foci1(:,2),bScan.Foci1(:,1),'*g');  
        end
        set(handles.Clear_Foci_1_Button,'Enable','on');
    else
        set(handles.Clear_Foci_1_Button,'Enable','off');
    end
    
    % Display second set of foci
    if ~isempty(bScan.Foci2) && get(handles.Show_Foci_2_Checkbox,'Value')
        axes(handles.Image_Axes);
        hold on;
        for iPoint = 1:size(bScan.Foci2,1)
            plot(bScan.Foci2(:,2),bScan.Foci2(:,1),'*r');  
        end
        set(handles.Clear_Foci_2_Button,'Enable','on');
    else
        set(handles.Clear_Foci_2_Button,'Enable','off');
    end
end

function Crop_Sides_Callback(hObject, eventdata, handles)
% hObject    handle to CropSides (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
 
    set(handles.Show_Crop_Lines_Checkbox,'Value',1);              
    DisplayImage(hObject, handles);
end

function CropSides(handles)

    % Get the percent to crop
    percent = str2double(get(handles.Crop_Sides,'String'));

    % Do nothing if the image number is invalid
    if isnan(percent) || percent <= 0 || percent > 50
        set(handles.Crop_Sides,'String','');
        set(handles.Show_Crop_Lines_Checkbox,'Enable','off');        
        if ~isnan(percent) && percent ~= 0
            msgbox('Percent must be between 0 and 50%','Error','Replace');
        end
        return;
    else
        set(handles.Show_Crop_Lines_Checkbox,'Enable','on'); 
    end
    
    % instantiate bscan if it does not already exist 
    bScan = handles.BSCAN;
    if isempty(bScan)            
        imageNumber = str2double(get(handles.Image_Number,'String'));
        bScan = BScan(handles.IMAGE_FILES{imageNumber},imageNumber);
    end
    
    % Calculate the locations to plot the vertical lines
    nPixels = bScan.Width * percent / 100;
    leftLine = nPixels*ones(1,bScan.Height);
    rightLine = (bScan.Width-nPixels+1)*ones(1,bScan.Height);
    y = 1:bScan.Height;
    
    % Plot the lines
    if nPixels > 0
        axes(handles.Image_Axes);
        hold on;
        plot(leftLine,y,'r',rightLine,y,'r');
    end
end

function Crop_Sides_CreateFcn(hObject, eventdata, handles)
% --- Executes during object creation, after setting all properties.
% hObject    handle to CropSides (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end
end

function Show_Crop_Lines_Checkbox_Callback(hObject, eventdata, handles)
% --- Executes on button press in Show_Crop_Lines_Checkbox.
% hObject    handle to Show_Crop_Lines_Checkbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

    DisplayImage(hObject, handles);
end

function Study_Site_Popup_Callback(hObject, eventdata, handles)
% --- Executes on selection change in Study_Site_Popup.
% hObject    handle to Study_Site_Popup (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    
    siteIndex = get(handles.Study_Site_Popup,'Value') - 1;
    SetImageParameters(handles,siteIndex);
end

function Study_Site_Popup_CreateFcn(hObject, eventdata, handles)
% --- Executes during object creation, after setting all properties.
% hObject    handle to Study_Site_Popup (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end
end

function Lateral_Resolution3_Callback(hObject, eventdata, handles)
% hObject    handle to Lateral_Resolution3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of Lateral_Resolution3 as text
%        str2double(get(hObject,'String')) returns contents of Lateral_Resolution3 as a double

    % Study site is no longer set to a preset
    set(handles.Study_Site_Popup,'Value',1);
    
    % Set the lateral resolution
    lateralRes = get(handles.Lateral_Resolution3,'String');
    Set_LateralSpacing(handles,'String',lateralRes);
    
    % Reset the ruler
    handles = Set_Ruler_Width(hObject,handles,0);
    DisplayImage(hObject,handles);
end

function Lateral_Resolution3_CreateFcn(hObject, eventdata, handles)
% --- Executes during object creation, after setting all properties.
% hObject    handle to Lateral_Resolution3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end
end

function Scan_Length_Callback(hObject, eventdata, handles)
% hObject    handle to Scan_Length (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of Scan_Length as text
%        str2double(get(hObject,'String')) returns contents of Scan_Length as a double

    set(handles.Study_Site_Popup,'Value',1);
    scanLength = str2double(get(handles.Scan_Length,'String'));    
    if isnan(scanLength) || scanLength <= 0
        set(handles.Scan_Length,'String','');
        set(handles.Num_Stack_Images_String,'String','');
    else
        scanLength = get(handles.Scan_Length,'String');  
        set(handles.Num_Stack_Images_String,'String',sprintf('(across the %s mm)',scanLength));
    end
    DisplayImage(hObject,handles);
end

function Scan_Length_CreateFcn(hObject, eventdata, handles)
% --- Executes during object creation, after setting all properties.
% hObject    handle to Scan_Length (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end
end

function Foveal_Distances_CreateFcn(hObject, eventdata, handles)
% --- Executes during object creation, after setting all properties.
% hObject    handle to Foveal_Distances (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end
end

function Foveal_Distances_Callback(hObject, eventdata, handles)
% hObject    handle to Foveal_Distances (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

    foveaScan = handles.FOVEA_SCANS;
    foveaLocation = handles.FOVEA_LOCATIONS;
    count = max(length(foveaScan),length(foveaLocation));
    
    % Show an error if more than one fovea was found, or if none were found
    if count ~= 1 && ...
       ~isempty(get(handles.Lateral_Resolution3,'String')) && ...
       ~isempty(get(handles.Scan_Length,'String')) && ...
       ~isempty(get(handles.Num_Stack_Images,'String'))
   
        if count == 0
            errorString = sprintf('%s%s', ...
                'A fovea has not been selected in the loaded image(s). ', ...
                'Cannot draw circular rings. See ''Select Fovea''');
        else
            errorString = sprintf('%d of the loaded image(s) contain a fovea. %s', ...
                'Only one can exist to draw circular rings. See ''Clear Fovea''',count);
        end
        set(handles.Foveal_Distances,'String','');
    else
        errorString = [];
    end
    scanLength = str2double(get(handles.Scan_Length,'String'));
    lateralRes = str2double(get(handles.Lateral_Resolution3,'String'));
    scanWidth = handles.IMAGE_SIZE(2) * lateralRes / 1000;
    distances = GetArrayFromString(get(handles.Foveal_Distances,'String'),1,1,0,max(scanLength,scanWidth));
    set(handles.Foveal_Distances,'String',distances);
    DisplayImage(hObject,handles);
    if ~isempty(errorString)
        msgbox(errorString,'Error','Replace');
    end
end

function string = GetArrayFromString(string,showMessage,getUniqueValues,minValue,maxValue)
    
    if nargin < 4
        minValue = [];
    end
    if nargin < 5
        maxValue = [];
    end
    
    % Remove anything that is not a number, replacing it with a comma
    originalString = string;
    string = regexprep(string,'[^0-9.]+',',');
    string = regexprep(string,'[.,]+,',',');
    
    % Remove leading or trailing commas
    if ~isempty(string) && string(1) == ','
        string(1) = '';
    end
    if ~isempty(string) && (string(end) == ',' || string(end) == '.')
        string(end) = '';
    end
    
    % Sort and get only unique instances of each number
    if showMessage
        try
            number = eval(sprintf('[%s]',string));
        catch
            msgbox(sprintf('''%s'' is invalid. See instructions for help.', ...
                originalString), 'Error');
            string = '';
            return;
        end
    else
        number = eval(sprintf('[%s]',string));
    end
        
    if getUniqueValues
        number = unique(number);
    end
    
    % Make sure the numbers lie within the specified range
    if ~isempty(minValue) && sum(number < minValue)
        number(number < minValue) = [];
        msgbox(sprintf('Values must range from %g to %g',minValue,maxValue),'replace');
    end
    if ~isempty(maxValue) && sum(number > maxValue)
        number(number > maxValue) = [];
        msgbox(sprintf('Values must range from %g to %g',minValue,maxValue),'replace');
    end
    
    string = num2str(number);
    string = regexprep(string,' +',',');
    string = regexprep(string,',',', ');
end

function Num_Stack_Images_Callback(hObject, eventdata, handles)
% hObject    handle to Num_Images (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

    numStackImages = str2double(get(handles.Num_Stack_Images,'String'));
    if isnan(numStackImages) || numStackImages <= 0
        set(handles.Num_Stack_Images,'String','');
    end
    DisplayImage(hObject,handles);
end

function Num_Stack_Images_CreateFcn(hObject, eventdata, handles)
% --- Executes during object creation, after setting all properties.
% hObject    handle to Num_Images (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end
end

function DrawCircularRings(handles)

    lateralRes = str2double(get(handles.Lateral_Resolution3,'String'));
    scanLength = str2double(get(handles.Scan_Length,'String'));
    numImages = str2double(get(handles.Num_Stack_Images,'String'));
    distances = eval(sprintf('[%s]',get(handles.Foveal_Distances,'String')));
    
    isLateralResEmpty = isempty(lateralRes) || isnan(lateralRes);
    isLengthEmpty = isempty(scanLength) || isnan(scanLength);
    isNumImagesEmpty = isempty(numImages) || isnan(numImages);
    isDistanceEmpty = isempty(distances) || sum(isnan(distances));
    
    if isLateralResEmpty || isLengthEmpty || isDistanceEmpty
        set(handles.Show_Ring_Lines_Checkbox,'Enable','off');
    else
        set(handles.Show_Ring_Lines_Checkbox,'Enable','on');
    end
    
    if isLateralResEmpty || isLengthEmpty
        set(handles.Num_Stack_Images,'Enable','off');
        set(handles.Foveal_Distances,'Enable','off');
    elseif isNumImagesEmpty
        set(handles.Num_Stack_Images,'Enable','on');
        set(handles.Foveal_Distances,'Enable','off');
    else
        set(handles.Num_Stack_Images,'Enable','on');
        set(handles.Foveal_Distances,'Enable','on');        
    end

    foveaScan = handles.FOVEA_SCANS;
    foveaLocation = handles.FOVEA_LOCATIONS;
    
    bScan = handles.BSCAN;
    imageNumber = str2double(get(handles.Image_Number,'String'));
    
    % Instantiate bscan if it does not already exist 
    if isempty(bScan)            
        bScan = BScan(handles.IMAGE_FILES{imageNumber},imageNumber);
    end
    
    % Loop through each of the distances from the fovea
    for iDist = 1:length(distances)
        
        distance = distances(iDist);
        color = GetLayerColor(iDist);
        
        % Calculate the locations to plot the vertical lines
        y = abs(imageNumber - foveaScan);
        y = y / numImages * scanLength;
        
        if y > distance
            continue;
        end
        
        x = sqrt(distance^2 - y^2);
        x = x / lateralRes * 1000;
        xLeft = foveaLocation{1}(2) - x;
        xRight = foveaLocation{1}(2) + x;
               
        yLine = 1:bScan.Height;
        
        if xLeft < 1
            xLeft = 1;
        else
            xLine = xLeft*ones(1,bScan.Height);
            axes(handles.Image_Axes);
            hold on;
            plot(xLine,yLine,color);
            
        end
        
        if xRight > bScan.Width
            xRight = bScan.Width;
        else
            xLine = xRight*ones(1,bScan.Height);
            axes(handles.Image_Axes);
            hold on;
            plot(xLine,yLine,color);
        end
        
        xTop = xLeft:xRight;
        yTop = ones(1,length(xTop));
        axes(handles.Image_Axes);
        hold on;
        plot(xTop,yTop,color);
    end
end

function Show_Ring_Lines_Checkbox_Callback(hObject, eventdata, handles)
% --- Executes on button press in Show_Ring_Lines_Checkbox.
% hObject    handle to Show_Ring_Lines_Checkbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

    DisplayImage(hObject, handles);
end


%% TOOLBAR FUNCTIONS

function Pan_Toolbar_ClickedCallback(hObject, eventdata, handles)
% hObject    handle to Pan_Toolbar (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    pan;
end

function Zoom_In_Toolbar_ClickedCallback(hObject, eventdata, handles)
% hObject    handle to Zoom_In_Toolbar (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

    % Save the original axes limitss
    if isempty(handles.ZOOM_LIMIT)
        handles.ZOOM_LIMIT = get(handles.Image_Axes, {'xlim','ylim'});
        guidata(hObject,handles);
    end
    
    % Zoom in
    zoom;
end

function Zoom_Out_Toolbar_ClickedCallback(hObject, eventdata, handles)
% hObject    handle to Zoom_Out_Toolbar (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
   
    if ~isempty(handles.ZOOM_LIMIT)
        set(handles.Image_Axes, {'xlim','ylim'}, handles.ZOOM_LIMIT); 
        zoom reset;
        handles.ZOOM_LIMIT = [];
        guidata(hObject,handles);
    end
    pan off;
    zoom off;
    set(handles.Pan_Toolbar,'State','off');
    set(handles.Zoom_In_Toolbar,'State','off');
    set(handles.Zoom_Out_Toolbar,'State','off');
    
    if ~isempty(handles.ZOOM_LIMIT)
        DisplayImage(hObject, handles);
    end
end


%% SAVE FUNCTIONS

function Save_Image_Button_Callback(hObject, eventdata, handles)
% --- Executes on button press in Save_Image_Button.
% hObject    handle to Save_Image_Button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

    % Validate the image number
    imageNumber = round(get(handles.Image_Slider, 'Value'));
    if imageNumber < 1 && ~isempty(handles.IMAGE_FILES)
        imageNumber = 1;
    end
    
    % Determine the filename to save as
    [path,name] = fileparts(handles.IMAGE_FILES{imageNumber});
    saveName = fullfile(path,'Segmentation',strcat(name,'.tif'));
    
    % Get the file directory to save in from the user
    [name, path] = uiputfile(saveName, 'Save As...');
    
    % Do nothing if no file was selected
    if isequal(name,0)
        return;       
    end
    
    % Remove the ruler
    image = getframe(handles.Image_Axes);
    image = image.cdata;
    %image = image(1:handles.IMAGE_SIZE(1),1:handles.IMAGE_SIZE(2),:);
    
    % Save the image
    imwrite(image, fullfile(path,name));
end
