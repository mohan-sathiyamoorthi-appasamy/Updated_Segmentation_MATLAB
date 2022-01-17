%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%  dme_getParameters.m
%
%  Gets the parameters required to segment the image
%
%--------------------------------------------------------------------------
%
%  function parameters = dme_getParameters()
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

function parameters = dme_getParameters()
    
    % SegmentImageParameters
    parameters = SegmentImageParameters;
    parameters.ALGORITHM_TYPE = 'dme';
    %parameters.DEFAULT_LATERAL_RESOLUTION = 5.7;  % um/pixel
    %parameters.DEFAULT_AXIAL_RESOLUTION = 3.5; % um/pixel
    parameters.X_RESOLUTION = 13.4;  % um/pixel
    parameters.Y_RESOLUTION = 6.7; % um/pixel
    
    % GetBwImageParameters
    parameters.getBwImageParams.X_FILTER_SIZE = 67;  % um
    parameters.getBwImageParams.Y_FILTER_SIZE = 33.5;  % um
    parameters.getBwImageParams.SIGMA = 11;  % um
    parameters.getBwImageParams.X_STREL_SIZE = 40.2;  % um;
    parameters.getBwImageParams.Y_STREL_SIZE = 33.5;  % um;
    parameters.getBwImageParams.MIN_CLUSTER_SIZE = 18000;  % um^2
    parameters.getBwImageParams.NUM_BORDERS = 4;
    
    % GetGraphCutParameters
    parameters.graphCutParams.NUM_LAYERS = 3;
    parameters.graphCutParams.MAX_NUM_LAYERS = 3;
    parameters.graphCutParams.SMOOTHING_CORRECTION = [0.03,0.03,0.1];
    parameters.graphCutParams.LAYER_INDICES = [1,3,2,2];
    parameters.graphCutParams.MATRIX_INDICES = [1,2,1,1];
    
    % WeightingMatrixParameters
    parameters.graphCutParams.weightingMatrixParams.X_FILTER_SIZE = 67;  % um
    parameters.graphCutParams.weightingMatrixParams.Y_FILTER_SIZE = 19.5;  % um
    parameters.graphCutParams.weightingMatrixParams.SIGMA = 2;  % um
    parameters.graphCutParams.weightingMatrixParams.EDGE_FILTER = [0.2 0.6 0.2; -0.2 -0.6 -0.2];
    parameters.graphCutParams.weightingMatrixParams.WEIGHT_RANGES = { ...
        {[0,1]}, ...        % dark-light weights
        {[0.4,1],[0,0.4],[0,0.4]}, ...        % light-dark
        {[0,1]}, ...        % dark-light weights
    };

    parameters.AXIAL_RESOLUTION = [];
    parameters.LATERAL_RESOLUTION = [];
    parameters.otherParams.SEGMENT_CYSTS = [];
end