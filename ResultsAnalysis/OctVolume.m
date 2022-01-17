%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%  OctVolume.m
%
%  OctVolume class
%
%  Represents an OCT volume of Bscans
%
%--------------------------------------------------------------------------
%
%  Author:          Stephanie Chiu (stephanie.chiu@duke.edu)
%  Organization:    Duke University
%  Date:            12/09/2009
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

classdef OctVolume < handle
    
    %----------------------------------------------------------------------
    %  Properties
    %----------------------------------------------------------------------
    
    properties
        DirectoryPath = '';
        DirectoryName = '';
        FileExtension = '';
        BScans = BScan;
        ScanWidth = 0;
        ScanHeight = 0;
        ScanIndices = [];
        NScans = 0;
        AverageSegmentationTime = 0;
        TotalSegmentationTime = 0;
        AllManuallyCorrected = 0;
        FoveaScans = [];
        FoveaLocations = [];
    end
    
    %----------------------------------------------------------------------
    %  Methods
    %----------------------------------------------------------------------
    
    methods
        
        %------------------------------------------------------------------
        %  OctVolume() Constructor
        %------------------------------------------------------------------
        
        function volume = OctVolume(directoryPath, scanIndices)
            
            if nargin == 0
                return;
            end
                        
            if isempty(directoryPath) || strcmp('.', directoryPath)
                directoryPath = pwd;
            elseif ~exist(directoryPath, 'dir')
                error('Directory path %s does not exist', directoryPath);
            end
            
            volume.DirectoryPath = directoryPath;
            [path, volume.DirectoryName] = fileparts(directoryPath);
            
            %
            %  Get all files in the directory with a .mat extension
            %
            files = dir(fullfile(directoryPath, '*.mat'));
            nFiles = length(files);
            
            %
            %  Get the scanIndices
            %
            if nargin < 2 || isempty(scanIndices)
                scanIndices = 1:nFiles;
            else
                scanIndices(scanIndices < 1) = [];
                scanIndices(scanIndices > nFiles) = [];
            end
            
            volume.NScans = length(scanIndices);
            volume.ScanIndices = scanIndices;
            
            if (volume.NScans == 0)
                volume.BScans = [];
                return;
            end
            
            allManuallyCorrected = 1;
            
            % Load each Bscan and set properties        
            volume.BScans(1, volume.NScans) = BScan;
            segmentationTime = 0;
            foveaScans = false(1,volume.NScans);
            foveaLocations = cell(1,volume.NScans);
            
            for iScan = 1:volume.NScans
                fileIndex = scanIndices(iScan);
                filename = fullfile(directoryPath, files(fileIndex).name);
                load(filename);
                volume.BScans(iScan) = bScan;
                segmentationTime = segmentationTime + bScan.SegmentationTime;
                
                % Set the scan height and width based on the first Bscan
                % Also set the number of manually corrected layers
                if (iScan == 1)
                    volume.ScanWidth = volume.BScans(iScan).Width;
                    volume.ScanHeight = volume.BScans(iScan).Height;
                    
                % All other Bscans must hvae the same height and width
                else
                    width = volume.BScans(iScan).Width;
                    height = volume.BScans(iScan).Height;
                    
                    if (volume.ScanWidth ~= width || volume.ScanHeight ~= height)
                        error('Bscan %d must have dimensions %d x %d', ...
                            iScan, volume.ScanHeight, volume.ScanWidth);
                    end
                end
                
                % Determine if all Bscans were manually corrected
                if allManuallyCorrected && ...
                   isempty(volume.BScans(iScan).CorrectedLayers)
                    allManuallyCorrected = 0;
                end
                
                %  Look for fovea locations
                if ~isempty(bScan.Fovea)
                    foveaScans(iScan) = iScan;
                    foveaLocations(iScan) = {bScan.Fovea};
                end
            end
            
            volume.TotalSegmentationTime = segmentationTime;
            volume.AverageSegmentationTime = segmentationTime / volume.NScans;
            volume.AllManuallyCorrected = allManuallyCorrected;
            volume.FoveaScans = foveaScans;
            volume.FoveaLocations = foveaLocations;
        end
        
        
        %------------------------------------------------------------------
        %  getLayers()
        %
        %  Gets a 3D matrix of the layer maps with dimension 
        %  (nLayers x scanWidth x nScans)
        %
        %  layerType - [0] Automatically segmented layers
        %              [1] Corrected automatic layers
        %              [2] Manually segmented layers
        %
        %  filter - Filter to use for gaussian smoothing (default = [])
        %
        %------------------------------------------------------------------
        
        function layers = getLayers(volume, layerType, filter)
            
            layers = [];
            
            if isempty(volume.BScans)
                return;
            end
            
            if nargin < 2
                layerType = 0;
            end
            if nargin < 3
                filter = [];
            end

            % Get manually segmented layers
            if (layerType == 2)       
                layers = [volume.BScans.('ManualLayers')];
                layers = reshape(layers, size(layers,1), volume.ScanWidth, volume.NScans);
                layers = permute(layers,[3,2,1]);
                return;
                
            % Get corrected layers if all have been corrected
            elseif (layerType == 1 && volume.AllManuallyCorrected)
                layers = [volume.BScans.('CorrectedLayers')];    
                layers = reshape(layers, size(layers,1), volume.ScanWidth, volume.NScans);
                layers = permute(layers,[3,2,1]);
                return;
            end
                          
            layers = [volume.BScans.('Layers')];            
            nLayers = size(layers,1);            
            layers = reshape(layers, nLayers, volume.ScanWidth, volume.NScans); 
            layers = permute(layers,[3,2,1]);
            
            % Get automatically segmented layers  
            if (layerType == 0)
                return;
            end
                
            % Get corrected segmented layers  
            for iScan = 1:volume.NScans
                
                correctedLayers = volume.BScans(iScan).CorrectedLayers;

                if isempty(correctedLayers)
                    continue;
                elseif size(correctedLayers,1) ~= nLayers
                    error('Not all scans have an equal number of layers');
                else
                    layers(iScan,:,:) = correctedLayers';
                end
            end
            
            % Filter the layers
            if ~isempty(filter)
                for iLayer = 1:nLayers
                    layers(:,:,iLayer) = blurImage(layers(:,:,iLayer), filter);
                end
            end
        end
        
        
        %------------------------------------------------------------------
        %  getThicknesses()
        %
        %  Gets a 3D matrix of the thickness maps with dimension 
        %  (nLayers x scanWidth x nScans)
        %
        %   layers - a 3D matrix of the layer maps with dimension 
        %            (nLayers x scanWidth x nScans)
        %
        %       or if  [0] gets automatically segmented layers (default)
        %              [1] gets corrected automatic layers
        %              [2] gets manually segmented layers
        %
        %   mapType - [0] gets rectangular map (default)
        %             [1] gets fovea centered circular map
        %
        %   thicknessType - [0] pixel thicknesses
        %                   [1] micron thicknesses
        %
        %   topIndices - Vector of top layer boundary indices. Gets the 
        %                thicknesses of all adjacent layers if empty 
        %                (Default = [])
        %
        %   bottomIndices - Vector of bottom layer boundary indices. Gets 
        %                   the thicknesses of all adjacent layers if empty 
        %                   (Default = [])
        %
        %   axialSpacing - Micron per pixel conversion in the vertical 
        %                  direction of a bScan. Ignored if thicknessType
        %                  = 0
        %
        %   mmScanWidth - The total distance in millimeters from the first
        %                 A-scan to the last A-scan. Ignored if mapType = 0
        %
        %   mmScanLength - The total distance in millimeters from the first
        %                  B-Scan to the last B-scan. Ignored if mapType =
        %                  0
        %
        %   mmRadius - The maximum radial distance in millimeters from the 
        %              fovea to include in the thickness map. Ignored if 
        %              mapType = 0
        %
        %   filter - Filter to use for gaussian smoothing (default = [])
        %
        %------------------------------------------------------------------
        
        function thicknesses = getThicknesses(volume, layers, mapType, ...
                thicknessType, topIndices, bottomIndices, axialSpacing, ...
                mmScanWidth, mmScanLength, mmRadius, filter)
            
            %--------------------------------------------------------------
            % Check input parameters
            %--------------------------------------------------------------
            
            if nargin < 2 || isempty(layers)
                layers = 0;
            end
            if nargin < 3 || isempty(mapType)
                mapType = 0;
            end
            if nargin < 4 || isempty(thicknessType)
                thicknessType = 0;
            end
            if nargin < 5
                topIndices = [];
            end
            if nargin < 6
                bottomIndices = [];
            end
            if nargin < 11
                filter = [];
            end
            
            % If no BScans were segmented, return nothing
            thicknesses = [];
            
            if isempty(volume.BScans)
                return;
            end
            
            %--------------------------------------------------------------
            % Get the layers
            %--------------------------------------------------------------
            
            if isempty(layers) || length(layers(:)) == 1
                layers = volume.getLayers(layers,filter);
            end            
            nLayers = size(layers,3);
            
            % Return if only one layer boundary was segmented
            if nLayers < 2
                return;
            end
            
            % Validate top and bottom layer boundary indices
            if length(bottomIndices) ~= length(bottomIndices)
                error('bottom and top indices must be of the same length');
            elseif xor(isempty(topIndices), isempty(bottomIndices))
                error('Cannot only specify top or bottom index. Must specify both or neither');
            elseif ~isempty(topIndices) && ~isempty(bottomIndices)
                if sum(topIndices < 1 | topIndices > nLayers) > 0
                    error('topIndices are out of range');
                elseif sum(bottomIndices < 1 | bottomIndices > nLayers) > 0
                    error('bottomIndices are out of range');
                elseif sum((bottomIndices - topIndices) < 0) > 0
                    error('bottomIndices must be greater than topIndices');
                end
            end
            
            %--------------------------------------------------------------
            % Get the thicknesses
            %--------------------------------------------------------------
            
            % Get all adjacent layer thicknesses if no indices were specified
            if isempty(topIndices)
                topIndices = [1:nLayers-1,1];
                bottomIndices = [2:nLayers,nLayers];
            end
            
            % Get the thicknesses of the specified layers
            thicknesses = squeeze(layers(:,:,bottomIndices) - layers(:,:,topIndices));
            
            % Return millimeter thicknesses
            if thicknessType == 1
                thicknesses = thicknesses * axialSpacing;
            end
            
            % Get the fovea centered thickness
            if mapType == 1
                % Check to see a single fovea exists
                if sum(volume.FoveaScans) ~= 1
                    error('There must be exactly one fovea selected in the volume');
                end

                % Set thicknesses outside the radius specified to NaN
                foveaScan = find(volume.FoveaScans);
                fovea = volume.FoveaLocations{foveaScan};
                [x,y] = meshgrid(1:size(thicknesses,2), 1:size(thicknesses,1));
                x = (x - fovea(2)) * mmScanWidth / size(thicknesses,2);
                y = (y - foveaScan) * mmScanLength / size(thicknesses,1);
                radii = sqrt(x.^2 + y.^2);
                radii = repmat(radii,[1,1,size(thicknesses,3)]);
                thicknesses(radii > mmRadius) = NaN;
            end
        end
        
        
        %------------------------------------------------------------------
        %  getEtdrsMap()
        %
        %   Gets the mean retinal thicknesses for the 9 regions in an ETDRS
        %   map with 1,3, and 6 mm circular rings centered at the fovea. 
        %
        %                      ...oooOO0OOOOooo...
        %                 .ooo'''               '''ooo.
        %              .ooO'           A6            'Ooo.
        %            .oO'                               'Oo.
        %          .oO' \        ..ooOOOOOOoo..        / 'Oo.
        %         .O'      \  .oO''          ''Oo.  /       'O.
        %        .O'        .\'        A2        '/.         'O.
        %       .O'        o'   \              /   'o         'O.
        %       o'        o'       \.oOOOOo./       'o         'o
        %      .O         O        oO      Oo        O          O.
        %      oO   A7    O   A3   O   A1   O   A5   O    A9    Oo       
        %      'O         O        oO      Oo        O          O'
        %       o.        o.       /'oOOOOo'\       .o         .o
        %       'O.        o.   /              \   .o         .O'
        %        'O.        '/.        A4        .\'         .O'
        %         'O.      /  'oO..          ..Oo'  \       .O'
        %          'oO. /        ''ooOOOOOOoo''        \ .Oo'
        %            'oO.                               .Oo'
        %              'ooO.           A8            .Ooo'
        %                 'ooo...               ...ooo'
        %                      '''oooOOOOOOOooo'''
        %   
        %
        %   layers - a 3D matrix of the layer maps with dimension 
        %            (nLayers x scanWidth x nScans)
        %
        %       or if  [0] gets automatically segmented layers (default)
        %              [1] gets corrected automatic layers
        %              [2] gets manually segmented layers
        %
        %   thicknessType - [0] pixel thicknesses
        %                   [1] micron thicknesses
        %
        %   topIndices - Vector of top layer boundary indices. Gets the 
        %                thicknesses of all adjacent layers if empty 
        %                (Default = [])
        %
        %   bottomIndices - Vector of bottom layer boundary indices. Gets 
        %                   the thicknesses of all adjacent layers if empty 
        %                   (Default = [])
        %
        %   axialSpacing - Micron per pixel conversion in the vertical 
        %                  direction of a bScan. Ignored if thicknessType
        %                  = 0
        %
        %   mmScanWidth - The total distance in millimeters from the first
        %                 A-scan to the last A-scan.
        %
        %   mmScanLength - The total distance in millimeters from the first
        %                  B-Scan to the last B-scan.
        %
        %   filter - Filter to use for gaussian smoothing (default = [])
        %
        %------------------------------------------------------------------
        
        function [meanThicknesses, stdThicknesses, sectorMap] = ...
                getEtdrsMap(volume, layers, thicknessType, topIndices, ...
                bottomIndices, axialSpacing, mmScanWidth, mmScanLength, ...
                filter)
            
            %--------------------------------------------------------------
            % Check input parameters
            %--------------------------------------------------------------
            
            if nargin < 2 || isempty(layers)
                layers = 0;
            end
            if nargin < 3 || isempty(thicknessType)
                thicknessType = 0;
            end
            if nargin < 4
                topIndices = [];
            end
            if nargin < 5
                bottomIndices = [];
            end
            if nargin < 9
                filter = [];
            end
            
            
            %--------------------------------------------------------------
            % Get the thickness maps
            %--------------------------------------------------------------
            
            thicknesses = volume.getThicknesses( ...
                layers, 0, thicknessType, topIndices, bottomIndices, ...
                axialSpacing,[],[],filter);
            
            
            %--------------------------------------------------------------
            % Get the sector map
            %--------------------------------------------------------------
             
            mapSize = size(thicknesses);
            mapSize = mapSize(1:2);
            [x,y] = meshgrid(1:mapSize(2), 1:mapSize(1));
            
            foveaScan = find(volume.FoveaScans);
            fovea = volume.FoveaLocations{foveaScan};  
            x = (x - fovea(2)) * mmScanWidth / mapSize(2);
            y = (y - foveaScan) * mmScanLength / mapSize(1);
                
            % Get the four quadrants
            quadrantMap = zeros(mapSize);
            quadrantMap(x >= 0 & abs(y) <= x) = 4;
            quadrantMap(y > 0 & abs(x) < y) = 3;
            quadrantMap(x < 0 & abs(y) <= abs(x)) = 2;
            quadrantMap(y < 0 & abs(x) < abs(y)) = 1;
            quadrantMap(y > 0 & -x == y) = 3;
            quadrantMap(y < 0 & -y == x) = 1;
            
            % Get the fovea centered circles            
            radii = sqrt(x.^2 + y.^2);
            circle_1mm = radii <= 0.5;
            circle_3mm = radii <= 1.5 & ~circle_1mm;
            circle_6mm = radii <= 3 & ~circle_1mm & ~circle_3mm;
                
            % Get the nine sectors
            sectorMap = zeros(mapSize);
            sectorMap(circle_1mm) = 1;
            sectorMap(circle_3mm & quadrantMap == 1) = 2;
            sectorMap(circle_3mm & quadrantMap == 2) = 3;
            sectorMap(circle_3mm & quadrantMap == 3) = 4;
            sectorMap(circle_3mm & quadrantMap == 4) = 5;
            sectorMap(circle_6mm & quadrantMap == 1) = 6;
            sectorMap(circle_6mm & quadrantMap == 2) = 7;
            sectorMap(circle_6mm & quadrantMap == 3) = 8;
            sectorMap(circle_6mm & quadrantMap == 4) = 9;
            
            
            %--------------------------------------------------------------
            % Get the mean thicknesses for each sector
            %--------------------------------------------------------------
            
            nThicknesses = size(thicknesses,3);
            nSectors = max(sectorMap(:));
            meanThicknesses = zeros(nThicknesses,nSectors+1);
            stdThicknesses = zeros(nThicknesses,nSectors+1);
            
            for iThickness = 1:nThicknesses
                thickness = thicknesses(:,:,iThickness);
                    
                for iSector = 1:nSectors
                    meanThicknesses(iThickness,iSector) = ...
                        nanmean(thickness(sectorMap == iSector));
                    
                    stdThicknesses(iThickness,iSector) = ...
                        nanstd(thickness(sectorMap == iSector));
                end
            end
            
            meanThicknesses(:,end) = thicknesses(foveaScan,fovea(2),:);
        end
        
        
        %------------------------------------------------------------------
        %  getSvp()
        %
        %  Gets the summed voxel projection of the images with dimension
        %  (nScans x scanWidth)
        %------------------------------------------------------------------
        
        function svp = getSvp(volume, enhanceSvp)
            
            if nargin < 2
                enhanceSvp = 0;
            end
                        
            images = [volume.BScans.('Image')];
            images = reshape(images, volume.ScanHeight, volume.ScanWidth, volume.NScans);
            
            classicSvp = squeeze(sum(images));
            classicSvp = shiftdim(classicSvp,1);
            
            if enhanceSvp                
                meanSvp = mean(classicSvp, 2);
                totalMeanSvp = mean(meanSvp + 0.1);
                inverseMeanSvp = totalMeanSvp ./ (meanSvp + 0.1);                
                
                svp = zeros(size(classicSvp));
                
                for iScan = 1:volume.NScans
                    svp(iScan,:) = classicSvp(iScan,:) * inverseMeanSvp(iScan);
                end
            else
                svp = classicSvp;
            end
            
            svp = (svp - min(svp(:))) / max(svp(:)) * 255;
            return;
        end
        
        
        %------------------------------------------------------------------
        %  getImages()
        %
        %  
        %------------------------------------------------------------------
        
        function images = getImages(volume)
            images = [volume.BScans.('Image')];
            images = reshape(images, volume.ScanHeight, volume.ScanWidth, volume.NScans);
        end
        
        
        %------------------------------------------------------------------
        %  getLayerImages()
        %
        %  
        %------------------------------------------------------------------
        
        function layerImages = getLayerImages(volume, topLayerIndex, bottomLayerIndex)
            
            if topLayerIndex < 1 || bottomLayerIndex < 1
                error('Layer index must be greater than zero');
            end
            
            if topLayerIndex > volume.NScans || bottomLayerIndex > volume.NScans
                error('Layer index must be less than %d', volume.NScans);
            end
            
            layers = getLayers(volume);
            images = getImages(volume);
            
            layerImages = zeros(size(images));
            
            for iImage = 1:volume.NScans
                              
                topLayer = layers(topLayerIndex,:,iImage);                
                bottomLayer = layers(bottomLayerIndex,:,iImage);
                
                for iColumn = 1:volume.ScanWidth
                    layerIndices = topLayer(iColumn):bottomLayer(iColumn);
                    
                    if length(layerIndices) > 1
                        layerImages(layerIndices, iColumn, iImage) = length(layerIndices);
                    end
                end
            end
            
            layerImages = layerImages / max(layerImages(:)) * 255;
        end
    end
end