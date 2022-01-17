%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%  getParameters_Default.m
%
%--------------------------------------------------------------------------
%
%
%--------------------------------------------------------------------------
%
%  Author:          Stephanie Chiu
%  Institution:     Duke University
%  Date Created:    2012.03.28
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function params = getParameters_default(filePath, fileExtension, siteIndex, params)

    if nargin < 2
        params = [];
    end
    
    filePath = lower(filePath);
        
    params.STUDY_SITES = {};
    params.SITE_INDEX = 0;
    params.AXIAL_RESOLUTION = [];
    params.LATERAL_RESOLUTION = [];
    params.SCAN_LENGTH = [];
    params.SEGMENT_CYSTS = 0;
    params.INVERT_IMAGE = 0;
    
    %----------------------------------------------------------
    % Set the eye
    %----------------------------------------------------------
    
    isLeft = ~isempty(strfind(filePath,'_os_'));
    isRight = ~isempty(strfind(filePath,'_od_'));
    
    if isLeft && ~isRight
        eye = 1;
    elseif isRight && ~isLeft
        eye = 2;
    else
        eye = 0;
    end
    params.EYE = eye;
    
    %----------------------------------------------------------
    % Set the scan orientation
    %----------------------------------------------------------
    
    isHorizontal = ~isempty(strfind(filePath,'_0_')) || ~isempty(strfind(filePath,'@0'));
    isVertical = ~isempty(strfind(filePath,'_90_')) || ~isempty(strfind(filePath,'@90'));
    
    if isHorizontal && ~isVertical
        scanOrientation = 1;
    elseif isVertical && ~isHorizontal
        scanOrientation = 2;
    else
        scanOrientation = 0;
    end
    params.SCAN_ORIENTATION = scanOrientation;
end