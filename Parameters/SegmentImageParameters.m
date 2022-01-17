%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%  SegmentImageParameters.m
%
%  SegmentImageParameters class
%
%  Contains contants used in the segmentImage() function
%
%--------------------------------------------------------------------------
%
%  Author:          Stephanie Chiu (stephanie.chiu@duke.edu)
%  Organization:    Duke University
%  Date:            2009.01.07
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

classdef SegmentImageParameters
    
    %----------------------------------------------------------------------
    %  Properties
    %----------------------------------------------------------------------
    
    properties
        ALGORITHM_TYPE = [];
        LINE_THICKNESS = 2;
        AXIAL_RESOLUTION = [];
        LATERAL_RESOLUTION = [];
        X_RESOLUTION = [];
        Y_RESOLUTION = [];
        INVERT_IMAGE = 0;
        otherParams = [];
        getBwImageParams = GetBwImageParameters;
        graphCutParams = GraphCutParameters;
    end
end