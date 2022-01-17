function varargout = aboutBox(varargin)
% ABOUTBOX M-file for aboutBox.fig
%      ABOUTBOX, by itself, creates a new ABOUTBOX or raises the existing
%      singleton*.
%
%      H = ABOUTBOX returns the handle to a new ABOUTBOX or the handle to
%      the existing singleton*.
%
%      ABOUTBOX('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in ABOUTBOX.M with the given input arguments.
%
%      ABOUTBOX('Property','Value',...) creates a new ABOUTBOX or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before aboutBox_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to aboutBox_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help aboutBox

% Last Modified by GUIDE v2.5 22-Mar-2010 07:50:15

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @aboutBox_OpeningFcn, ...
                   'gui_OutputFcn',  @aboutBox_OutputFcn, ...
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


% --- Executes just before aboutBox is made visible.
function aboutBox_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to aboutBox (see VARARGIN)

% Choose default command line output for aboutBox
handles.output = hObject;

% Update title with version number
bScan = BScan();
version = sprintf(' (Version %s)', bScan.SoftwareVersion);
title = strcat(get(handles.Title, 'String'), version);
set(handles.Title, 'String', title);

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes aboutBox wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = aboutBox_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;
