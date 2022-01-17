%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%  WeightingMatrixParameters.m
%
%  WeightingMatrixParameters class
%
%  Contains contants used in the weightingMatrix() function
%
%--------------------------------------------------------------------------
%
%  Author:          Stephanie Chiu (stephanie.chiu@duke.edu)
%  Organization:    Duke University
%  Date:            12/19/2009
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

classdef WeightingMatrixParameters
    
    %----------------------------------------------------------------------
    %  Properties
    %----------------------------------------------------------------------
    
    properties
        MIN_WEIGHT = 0.00001;
        WEIGHT_RANGES = [];
        X_FILTER_SIZE = 0;
        Y_FILTER_SIZE = 0;
        SIGMA = 0;
        EDGE_FILTER = [1, -1];
    end
end