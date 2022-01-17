%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%  drusen_getParameters.m
%
%  Gets the parameters required to segment the image
%
%--------------------------------------------------------------------------
%
%  function parameters = drusen_getParameters()
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

function parameters = drusen_getParameters()
    
    % SegmentImageParameters
    parameters = SegmentImageParameters;
    parameters.ALGORITHM_TYPE = 'drusen';
    %parameters.DEFAULT_LATERAL_RESOLUTION = 6.7;  % um/pixel
    %parameters.DEFAULT_AXIAL_RESOLUTION = 3.35; % um/pixel
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
    parameters.graphCutParams.NUM_LAYERS = 3;
    parameters.graphCutParams.MAX_NUM_LAYERS = 3;
    parameters.graphCutParams.SMOOTHING_CORRECTION = [0.03,0.015,0.3];
    parameters.graphCutParams.LAYER_INDICES = [1,3,3,2,2,2];
    parameters.graphCutParams.MATRIX_INDICES = [1,2,3,4,1,1];
    
    % WeightingMatrixParameters
    parameters.graphCutParams.weightingMatrixParams.X_FILTER_SIZE = 67;  % um
    parameters.graphCutParams.weightingMatrixParams.Y_FILTER_SIZE = 20.1;  % um
    parameters.graphCutParams.weightingMatrixParams.SIGMA = 2;  % um
    parameters.graphCutParams.weightingMatrixParams.EDGE_FILTER = [0.2 0.6 0.2; -0.2 -0.6 -0.2];
    parameters.graphCutParams.weightingMatrixParams.WEIGHT_RANGES = { ...
        {[0,1]}, ...                % dark-light weights
        {[0,1]}, ...                % dark-light weights for GA
        {[2,4],[0,0.2],[2,4]}, ...  % light-dark, dark-light, short weights
        {[0,1]}, ...                % bright intensity weights
    };
end