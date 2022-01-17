%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%  GraphCutParameters.m
%
%  GraphCutParameters class
%
%  Contains contants used in the graphCut() function
%
%--------------------------------------------------------------------------
%
%  Author:          Stephanie Chiu (stephanie.chiu@duke.edu)
%  Organization:    Duke University
%  Date:            2009.01.07
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

classdef GraphCutParameters
    
    %----------------------------------------------------------------------
    %  Properties
    %----------------------------------------------------------------------
    
    properties
        NUM_LAYERS = 0;
        MAX_NUM_LAYERS = 0;
        LAYER_INDICES = [];
        MATRIX_INDICES = [];
        SMOOTHING_CORRECTION = 0;
        weightingMatrixParams = WeightingMatrixParameters;
    end
end