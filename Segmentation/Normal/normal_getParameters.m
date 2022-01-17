%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%  normal_getParameters.m
%
%  Gets the parameters required to segment the image
%
%--------------------------------------------------------------------------
%
%  function parameters = normal_getParameters()
%
%  OUTPUT VARIABLES:
%
%       parameters - The parameters used to segment the image
%
%--------------------------------------------------------------------------
%
%  Author:          Stephanie Chiu
%  Institution:     Duke University
%  Date Created:    2009.05.13
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function parameters = normal_getParameters()
    
    % SegmentImageParameters
    parameters = SegmentImageParameters;
    parameters.ALGORITHM_TYPE = 'normal';
    %parameters.DEFAULT_LATERAL_RESOLUTION = 11;  % um/pixel
    %parameters.DEFAULT_AXIAL_RESOLUTION = 3.87; % um/pixel
    parameters.X_RESOLUTION = 13.4;  % um/pixel
    parameters.Y_RESOLUTION = 6.7; % um/pixel
    
    % GetBwImageParameters
    parameters.getBwImageParams.X_FILTER_SIZE = 147.4;  % um
    parameters.getBwImageParams.Y_FILTER_SIZE = 73.7;  % um
    parameters.getBwImageParams.SIGMA = 11;  % um
    parameters.getBwImageParams.X_STREL_SIZE = 40.2;  % um;
    parameters.getBwImageParams.Y_STREL_SIZE = 20.1;  % um;
    parameters.getBwImageParams.MIN_CLUSTER_SIZE = 18000;  % um^2
    parameters.getBwImageParams.NUM_BORDERS = 4;
    
    % GetGraphCutParameters
    parameters.graphCutParams.NUM_LAYERS = 8;
    parameters.graphCutParams.MAX_NUM_LAYERS = 8;
    parameters.graphCutParams.SMOOTHING_CORRECTION = [0.05,0.05,0.1,0.1,0.05,0.05,0.05,0.05];
    parameters.graphCutParams.LAYER_INDICES = [1,8,8,7,6,4,3,5,4,2];
    parameters.graphCutParams.MATRIX_INDICES = [1,2,3,5,5,5,4,4,5,6];
    
    % WeightingMatrixParameters
    parameters.graphCutParams.weightingMatrixParams.X_FILTER_SIZE = 40.2;  % um
    parameters.graphCutParams.weightingMatrixParams.Y_FILTER_SIZE = 20.1;  % um
    parameters.graphCutParams.weightingMatrixParams.SIGMA = 6;
    parameters.graphCutParams.weightingMatrixParams.EDGE_FILTER = [0.2 0.6 0.2; -0.2 -0.6 -0.2];
    parameters.graphCutParams.weightingMatrixParams.WEIGHT_RANGES = { ...
        {[0,1]}, ...                        % 01: dark-light
        {[0,0.5],[0.5,1]}, ...              % 02: bright, distance
        {[0,0.4],[0.4,1]}, ...              % 03: light-dark, distance
        {[0,0.6],[0.6,1]}, ...              % 04: light-dark, distance
        {[0,0.5],[0.5,1]}, ...              % 05: dark-light distance
        {[0,0.5],[0.5,0.7],[0.7,1.1]}, ...  % 06: light-dark, dark, distance
    };

    % otherParams
    parameters.otherParams.EYE = [];
    parameters.otherParams.SCAN_ORIENTATION = [];
end