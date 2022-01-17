%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%  pediatric_getParameters.m
%
%  Gets the parameters required to segment the image
%
%--------------------------------------------------------------------------
%
%  function parameters = pediatric_getParameters()
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

function parameters = pediatric_getParameters()
    
    % SegmentImageParameters
    parameters = SegmentImageParameters;
    parameters.ALGORITHM_TYPE = 'pediatric';
    %parameters.DEFAULT_LATERAL_RESOLUTION = 6.7;  % um/pixel
    %parameters.DEFAULT_AXIAL_RESOLUTION = 3.25; % um/pixel
    parameters.X_RESOLUTION = 13.4;  % um/pixel
    parameters.Y_RESOLUTION = 6.5; % um/pixel
    
    % GetBwImageParameters
    parameters.getBwImageParams.X_FILTER_SIZE = 147.4;  % um
    parameters.getBwImageParams.Y_FILTER_SIZE = 71.5;  % um
    parameters.getBwImageParams.SIGMA = 11;  % um
    parameters.getBwImageParams.X_STREL_SIZE = 40.2;  % um;
    parameters.getBwImageParams.Y_STREL_SIZE = 19.5;  % um;
    parameters.getBwImageParams.MIN_CLUSTER_SIZE = 18000;  % um^2
    parameters.getBwImageParams.NUM_BORDERS = 6;
    
    % GetGraphCutParameters
    parameters.graphCutParams.NUM_LAYERS = 9;
    parameters.graphCutParams.MAX_NUM_LAYERS = 9;
    parameters.graphCutParams.SMOOTHING_CORRECTION = [0.05,0.05,0.1,0.1,0.05,0.05,0.05,0.05,0.1];
    parameters.graphCutParams.LAYER_INDICES = [1,6,8,7,6,9,5,3,4,5,2];
    parameters.graphCutParams.MATRIX_INDICES = [1,1,2,3,3,4,9,7,8,5,5];
    
    % WeightingMatrixParameters
    parameters.graphCutParams.weightingMatrixParams.X_FILTER_SIZE = 40.2;  % um
    parameters.graphCutParams.weightingMatrixParams.Y_FILTER_SIZE = 32.5;  % um
    parameters.graphCutParams.weightingMatrixParams.SIGMA = 2;
    parameters.graphCutParams.weightingMatrixParams.EDGE_FILTER = [0.2 0.3 0.3 0.2;-0.2 -0.3 -0.3 -0.2];
    parameters.graphCutParams.weightingMatrixParams.WEIGHT_RANGES = { ...
        {[0,1]}, ...             % Dark-light
        {[0,0.5], [0.5,1]}, ...  % Bruchs weights (light-dark, distance)
        {[0,1]}, ...             % Dark-light
        {[0.3,1], [0,0.1]}, ...  % Choroid weights (dark-light, distance)
        {[0.5,1],[0,0.5],[0,0.1]}, ...  % light-dark short weights (light-dark,distance,bright)
        {[0.5,1],[0,0.5]}, ...          % dark intensity + light-dark weights (dark,light-dark)
        {[0.6,1],[0,0.6],[0,0.3]}, ...  % dark intensity + light-dark short weights (dark,light-dark,distance)
        {[0.5,1],[0,0.5],[0,0.3]}, ...  % dark intensity + dark-light weights (dark,dark-light,distance)
        {[0,0.5],[0,0.5],[0.5,1]}, ...  % bright intensity + light-dark short weights (bright,light-dark,distance)
    };

    % otherParams
    parameters.otherParams.SEGMENT_CYSTS = [];
    parameters.otherParams.FOLDER_DIRECTORY = [];
end