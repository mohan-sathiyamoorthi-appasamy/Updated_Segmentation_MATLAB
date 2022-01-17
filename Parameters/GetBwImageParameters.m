%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%  GetBwImageParameters.m
%
%  GetBwImageParameters class
%
%  Contains contants used in the getBwImage() function
%
%--------------------------------------------------------------------------
%
%  Author:          Stephanie Chiu (stephanie.chiu@duke.edu)
%  Organization:    Duke University
%  Date:            2009.12.19
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

classdef GetBwImageParameters
    
    %----------------------------------------------------------------------
    %  Properties
    %----------------------------------------------------------------------
    
    properties
        X_FILTER_SIZE = 0;  % um
        Y_FILTER_SIZE = 0;  % um
        SIGMA = 0;
        X_STREL_SIZE = 0;   % um
        Y_STREL_SIZE = 0;   % um
        NUM_BORDERS = 0;
        MIN_CLUSTER_SIZE = 0;
        weightingMatrixParams = WeightingMatrixParameters;
    end
end