classdef Plate < Chamber
   properties
       sz;
       Wells = {};
       x0y0; % position of the upper left well (e.g. A01)
       tform; % an optional transformation that came from plate calibration. 
       wellSpacingXY
       wellDimensions
       wellCurvature
       directionXY=[-1 -1];
       Features=struct('Name',{},'XY',{}); 
              
       %% from the Chamber interface
       type
       numOfsubChambers
       Labels
       Fig = struct('fig',[],'Wells',{});
   end
   
   properties (Dependent)
      Xcenter
      Ycenter
   end
   
   methods
       function P = Plate(type)
           if nargin==0
               type = 'Costar96 (3904)';
           end
           switch type 
               case 'Costar96 (3904)'
                   P.numOfsubChambers=96; 
                   P.type = type;
                   P.sz = [8 12];
                   P.wellDimensions=[6300 6300]; 
                   P.wellCurvature = [1 1];
                   P.x0y0 = [ ]; %Has to be determined by Scope stage in ScopeStartup config file
                   P.wellSpacingXY = [9020 9020];
                   P.Wells = {  'A01'    'A02'    'A03'    'A04'    'A05'    'A06'    'A07'    'A08'    'A09'    'A10'    'A11'    'A12'
                                'B01'    'B02'    'B03'    'B04'    'B05'    'B06'    'B07'    'B08'    'B09'    'B10'    'B11'    'B12'
                                'C01'    'C02'    'C03'    'C04'    'C05'    'C06'    'C07'    'C08'    'C09'    'C10'    'C11'    'C12'
                                'D01'    'D02'    'D03'    'D04'    'D05'    'D06'    'D07'    'D08'    'D09'    'D10'    'D11'    'D12'
                                'E01'    'E02'    'E03'    'E04'    'E05'    'E06'    'E07'    'E08'    'E09'    'E10'    'E11'    'E12'
                                'F01'    'F02'    'F03'    'F04'    'F05'    'F06'    'F07'    'F08'    'F09'    'F10'    'F11'    'F12'
                                'G01'    'G02'    'G03'    'G04'    'G05'    'G06'    'G07'    'G08'    'G09'    'G10'    'G11'    'G12'
                                'H01'    'H02'    'H03'    'H04'    'H05'    'H06'    'H07'    'H08'    'H09'    'H10'    'H11'    'H12'};
               case 'Costar384 (4681)'
                   P.numOfsubChambers=336; 
                   P.type = type;
                   P.sz = [14 24];
                   P.wellDimensions=[2000 2000]; 
                   P.wellCurvature = [1 1];
                   P.x0y0 = [ ]; %Has to be determined by Scope stage in ScopeStartup config file
                   P.wellSpacingXY = [4500 4500];
                   W=cell(14,24); 
                   R='BCDEFGHIJKLMNO';
                   for i=1:14
                       for j=1:24
                           W{i,j}=[R(i) sprintf('%02.0f',j)]; 
                       end
                   end
                   P.Wells=W; 
               case 'Costar24 (3526)'
                   P.numOfsubChambers=24; 
                   P.type = type;
                   P.sz = [4 6];
                   P.wellDimensions=[15620 15620]; 
                   P.wellCurvature = [1 1];
                   P.x0y0 = [ ]; %Has to be determined by Scope stage in ScopeStartup config file
                   P.wellSpacingXY = [19300 19300];
                   P.Wells = {  'A01'    'A02'    'A03'    'A04'    'A05'    'A06'
                                'B01'    'B02'    'B03'    'B04'    'B05'    'B06'
                                'C01'    'C02'    'C03'    'C04'    'C05'    'C06'
                                'D01'    'D02'    'D03'    'D04'    'D05'    'D06'};
               case 'ibidi 6-lane 4 sites per lane'
                   P.numOfsubChambers=24; 
                   P.type = type;
                   P.sz = [4 6];
                   P.wellDimensions=[3800 2500]; 
                   P.wellCurvature = [0.2 1];
                   P.x0y0 = []; %Has to be determined by Scope stage in ScopeStartup config file
                   %changed Ryan 7/1
                   P.directionXY = [-1 -1];
                   P.wellSpacingXY = [8800 3000];
                   P.Wells = {  'L1S1'    'L2S1'    'L3S1'    'L4S1'    'L5S1'    'L6S1' 
                                'L1S2'    'L2S2'    'L3S2'    'L4S2'    'L5S2'    'L6S2'
                                'L1S3'    'L2S3'    'L3S3'    'L4S3'    'L5S3'    'L6S3'
                                'L1S4'    'L2S4'    'L3S4'    'L4S4'    'L5S4'    'L6S4'};   
               case 'ibidi high-mag'
                   P.numOfsubChambers = 6;
                   P.type = type;
                   P.sz = [1 6];
                   P.directionXY = [-1 1];
                   P.wellDimensions = [3800 2500];
                   P.wellCurvature = [0.2 1];
                   P.x0y0 = [];
                   P.wellSpacingXY = [8800 3000];
                   P.Wells = {'L1' 'L2', 'L3', 'L4', 'L5', 'L6'}; % Ibidi -> L1 .. L6
               
               case 'ibidi 6-lane center at top'
                   P.numOfsubChambers=6; 
                   P.type = type;
                   P.sz = [1 6];
                   P.wellDimensions=[2500 17000]; 
                   P.wellCurvature = [0 0];
                   P.x0y0 = [24189       -9405]; % define this at the top position you want to image in (assuming you use alignsites = top
                   %changed Ryan 7/1
                   P.directionXY = [-1 -1];
                   %P.wellSpacingXY = [8800 0];
                   P.wellSpacingXY = [12000 0];
                   P.Wells = {  'L1'    'L2'    'L3'    'L4'    'L5'    'L6'}; 
               case 'ibidi 6-lane'
                   P.numOfsubChambers=24; 
                   P.type = type;
                   P.sz = [1 6];
                   P.wellDimensions=[2500 18000]; 
                   P.wellCurvature = [0 0];
%                    P.x0y0 = [23417  700]; 
                   P.x0y0 = []; % define this at the top position you want to image in (assuming you use alignsites = top
                   %changed Ryan 7/1
                   P.directionXY = [-1 1];
                   P.wellSpacingXY = [9000 0];
                   P.Wells = {  'L1'    'L2'    'L3'    'L4'    'L5'    'L6'};    
                   P.Features(1) = struct('Name','TopL1','XY',[22643      -12395]); 
                   P.Features(2) = struct('Name','BottomL1','XY',[22643     12395]); 
                   P.Features(3) = struct('Name','TopL2','XY',[13843      -12395]); 
                   P.Features(4) = struct('Name','BottomL2','XY',[13843      12395]); 
                   P.Features(5) = struct('Name','TopL3','XY',[5043      -12395]); 
                   P.Features(6) = struct('Name','BottomL3','XY',[5043      12395]);
                   P.Features(7) = struct('Name','TopL4','XY',[-3757      -12395]); 
                   P.Features(8) = struct('Name','BottomL4','XY',[-3757      12395]);
                   P.Features(9) = struct('Name','TopL5','XY',[-12557      -12395]);
                   P.Features(10) = struct('Name','BottomL5','XY',[-12557      -12395]);
                   P.Features(11) = struct('Name','TopL6','XY',[-21357 -12395]);
                   P.Features(12) = struct('Name','BottomL6','XY',[-21357 -12395]);

               case 'PTFE glass slide'
                   P.numOfsubChambers=30; 
                   P.type = type;
                   P.sz = [3 10];
                   P.wellDimensions=[2000 2000]; 
                   P.wellCurvature = [1 1];
                   P.x0y0 = []; %Has to be determined by Scope stage in ScopeStartup config file
                   P.wellSpacingXY = [5073 5853]; %needs to be recalibrated each time
                   P.Wells = {  'A01'    'A02'    'A03'    'A04'    'A05'    'A06'    'A07'    'A08'    'A09'    'A10'
                                'B01'    'B02'    'B03'    'B04'    'B05'    'B06'    'B07'    'B08'    'B09'    'B10'
                                'C01'    'C02'    'C03'    'C04'    'C05'    'C06'    'C07'    'C08'    'C09'    'C10'};
               case 'Labtek 8-wells'
                   P.numOfsubChambers=8; 
                   P.type = type;
                   P.sz=[2 4];
                   P.x0y0 = [ ]; %Has to be determined by Scope stage in ScopeStartup config file
                   P.wellSpacingXY = [nan nan]; %TODO = put right valuse
                   P.Wells 
               case 'Microfluidics Wounding Device Ver 3.0'
                   P.numOfsubChambers = 1; 
                   P.type = type; 
                   P.sz = [1 1]; 
                   P.x0y0 = []; 
                   P.wellSpacingXY = [0 0]; 
                   P.Wells = {'uFluidicsDevice'}; 
                   P.wellDimensions = [4000 4000]; 
                   P.wellCurvature = [0 0]; 
               case 'Coverslip'
                   P.numOfsubChambers = 1; 
                   P.type = type; 
                   P.sz = [1 1]; 
                   P.x0y0 = []; 
                   P.wellSpacingXY = [0 0]; 
                   P.Wells = {'Coverslip'}; 
                   P.wellDimensions = [10000 10000]; 
                   P.wellCurvature = [0 0];     
               case '50mm Matek Chamber'
                   P.numOfsubChambers = 1; 
                   P.type = type; 
                   P.sz = [6 6]; 
                   P.x0y0 = []; 
                   P.wellSpacingXY = [5000 5000]; 
                   P.Wells = { 'Pos0' 'Pos1'    'Pos2'    'Pos3'    'Pos4'    'Pos5'    'Pos6'    'Pos7'    'Pos8'    'Pos9'    'Pos10'    'Pos11'    'Pos12'    'Pos13'    'Pos14'    'Pos15'    'Pos16' ...
                         'Pos17'    'Pos18'    'Pos19'    'Pos20'    'Pos21'    'Pos22'    'Pos23'    'Pos24'    'Pos25'    'Pos26'    'Pos27'    'Pos28'    'Pos29'    'Pos30' 'Pos31' 'Pos32' 'Pos33' 'Pos34' 'Pos35'}; 
                   P.wellDimensions = [5000 5000]; 
                   P.wellCurvature = [0 0];
                   
               otherwise
                   error('Unknown plate type - check for typo, or add antoehr plate definition')
           end
           P.Fig(1).Wells = cell(P.sz);
           P.Fig.fig = 999; 
       end
       
       function calibratePlateThroughPairs(Plt,MeasuredXY,FeatureNames)
           % identify a transformation for XY points based on sets of
           % features and their XY position. 
           assert(numel(FeatureNames)>1,'Must provide at least two features to calibrate')
           assert(size(MeasuredXY,1)==numel(FeatureNames),'Must provide measured XY for each plate Feature used for calibration'); 
           AllFeatureNames = {Plt.Features.Name};
           assert(all(ismember(FeatureNames,AllFeatureNames)),'Selected features not define in plate configuration')
           AllFeatureXY = cat(1,Plt.Features.XY);
           TheoryXY = AllFeatureXY(ismember(AllFeatureNames,FeatureNames),:); 
           Plt.tform = cp2tform(MeasuredXY,TheoryXY,'nonreflective similarity'); %#ok<DCPTF>
       end
       
       function [Xcenter,Ycenter] = getXY(Plt)
           grdx = 0:Plt.wellSpacingXY(1)*Plt.directionXY(1):(Plt.sz(2)-1)*Plt.wellSpacingXY(1)*Plt.directionXY(1);
           grdy = 0:Plt.wellSpacingXY(2)*Plt.directionXY(2):(Plt.sz(1)-1)*Plt.wellSpacingXY(2)*Plt.directionXY(2); 
           if ~isempty(grdx)
               Xcenter = Plt.x0y0(1)+grdx;
           else
               Xcenter = Plt.x0y0(1); 
           end
            if ~isempty(grdy)
               Ycenter = Plt.x0y0(2)+grdy;
           else
               Ycenter = Plt.x0y0(2); 
           end
           Xcenter = repmat(Xcenter(:)',Plt.sz(1),1);
           Ycenter = repmat(Ycenter(:),1,Plt.sz(2));
           if ~isempty(Plt.tform)
               [Xcenter,Ycenter]=tformfwd(Plt.tform,Xcenter,Ycenter);
           end
       end
       
       function Xcenter = get.Xcenter(Plt)
           [Xcenter,~] = getXY(Plt); 
       end
       
       function Ycenter = get.Ycenter(Plt)
           [~,Ycenter] = getXY(Plt);
       end

       function Labels = get.Labels(Plt)
           Labels = Plt.Wells; 
       end
       
       function [dx,dy]=getWellShift(Plt,posalign)
           % TODO verify
           dx=0; 
           dy=0; 
           switch posalign
               case 'center'
                   % do nothing. 
               case 'top'
                   % add 
                   dy = -Plt.wellDimensions(2)/2*Plt.directionXY(2); 
               case 'bottom'
                   dy= Plt.wellDimensions(2)/2*Plt.directionXY(2); 
               case 'left'
                   dx = - Plt.wellDimensions(1)/2*Plt.directionXY(1); 
               case 'right'
                   dx = Plt.wellDimensions(1)/2*Plt.directionXY(1); 
               otherwise
                   error('Position alignment must be {center/top/bottom/left/right}')
           end
       end
              
       function xy = getXYbyLabel(Plt,label)
           [Xcntr,Ycntr] = Plt.getXY; 
           x = Xcntr(ismember(Plt.Labels,label));
           y = Ycntr(ismember(Plt.Labels,label));
           xy=[x(:) y(:)];
       end
       
       function plotHeatMap(Plt,msk,varargin)
           
           if ~isempty(Plt.Fig)
               arg.fig = Plt.Fig(1).fig;
           else
               arg.fig = []; 
           end
           arg.colormap = [0 0 0; jet(256)];
           arg = parseVarargin(varargin,arg); 
           
           if isempty(arg.fig); 
               arg.fig = figure;
               Plt.Fig(1).fig = arg.fig; 
           end
           figure(arg.fig)
           set(arg.fig,'colormap',arg.colormap); 
           Plt.Fig(1).Wells = cell(Plt.sz);
           
           %%
           msk = gray2ind(msk,256)+1;
           clr = arg.colormap; 
           
           for i=1:Plt.sz(1)
               for j=1:Plt.sz(2)
                   rct = [Plt.Xcenter(i,j)-Plt.wellDimensions(1)/2 ...
                          Plt.Ycenter(i,j)-Plt.wellDimensions(2)/2 ...
                          Plt.wellDimensions(1:2)];
                      
                   Plt.Fig.Wells{i,j} = rectangle('Position',rct,...
                                                       'curvature',Plt.wellCurvature,...
                                                       'facecolor',clr(msk(i,j),:),...
                                                       'HitTest','off');
               end
           end
           
           ytcklabel=cell(Plt.sz(1),1);
           for i=1:Plt.sz(1)
               strt=uint8(Plt.Labels{1,1}(1))-1;
               ytcklabel{i} = char(strt+i); % assume that we start from A
           end
           
           [xtck,ordr]=sort(Plt.Xcenter(1,:)); 
           xtcklabel = 1:Plt.sz(2); 
           xtcklabel=xtcklabel(ordr); 
           
           [ytck,ordr]=sort(Plt.Ycenter(:,1));
           ytcklabel=ytcklabel(ordr); 
           
           set(gca,'xtick',xtck,'xticklabel',xtcklabel,'ytick',ytck,'yticklabel',ytcklabel)
           axis xy
           if Plt.directionXY(1)==-1
               set(gca,'XDir','reverse')
           end
           if Plt.directionXY(2)==1
               set(gca,'YDir','reverse')
           end
           axis equal
           
       end
       
   end
end