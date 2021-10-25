classdef Positions < handle
    
    properties
        List = []; % of size Nx2 (or 3 if Z matters) 
        Labels = {}; % of size Nx1 names of 
        Group = {}; % if size Nx1, a grouping variables for positions 
        % for example could be used for multi-wells a way to know which
        % positions belong to which group
        Batch = categorical(1); % size Nx1, numerical grouping variable to group together 
                     % batches of wells. e.g. Image a collumn of a plate
                     % before moving to the next collumn. Should be
                     % integers that increase from 1 to M.
        batchStartInd = [1]; % size Mx1, Index of the List where each batch 
                             % starts in the list, where M is the number of
                             % batches
        ExperimentMetadata=struct([]); % of size Nx1 where each element had all the field names for all different Metadata types
        
        PlateType = ''; % in case this position list was made for a specific plate
                        % save 
        
        Skip=[];                 
                        
        
        axis = {'XY'};
        ordr
        current = 0;
        circular = true;
        isOptimized
        
        currentBatch = 0; % tracking index for current batch
        NumPerBatch = []; % vector to hold the number of positions in each batch
        BatchIndNums = {};
    end
    
    properties (Dependent = true)
        N
        Nbatch
        NinBatch
    end
    
    methods
        
        function remove(Pos,name)
            ix=ismember(Pos.Labels,name); 
            Pos.List(ix,:)=[]; 
            Pos.Labels(ix)=[]; 
            Pos.Group(ix)=[]; 
            Pos.ExperimentMetadata(ix)=[]; 
        end
        
        function Skp = getSkipForNextPosition(Pos)
            % get the skip value for the next position without advancing
            % the counter. 
            if isempty(Pos.Skip)
                Skp=1; 
            else
                if Pos.current == size(Pos.List,1)
                    if ~Pos.circular
                        error('Already at the end of a NON circular position list')
                    end
                    ix=0; 
                else
                    ix=Pos.current; 
                end
            ix =ix+1;
            Skp = Pos.Skip(ix);
            end
        end
        
% Constructor
        function Pos = Positions(fullfilename,varargin)
            arg.axis = Pos.axis;
            arg = parseVarargin(varargin,arg);
            Pos.axis = arg.axis;
            
            if nargin>0 && ~isempty(fullfilename) % assume we are building position list from
                cls = class(fullfilename); 
                prts=regexp(cls,'\.','split');
                cls = prts{end}; 

                % decide if fillfilename is a filename of a position list
                % or a object of PositionList class (from MM)

                if strcmp(cls,'PositionList') 
                    PL=fullfilename; 
                else
                    PL = PositionList;
                    PL.load(fullfilename);
                end
                Pos.List=nan(PL.getNumberOfPositions,numel(arg.axis));
                Pos.Labels=cell(PL.getNumberOfPositions,1);
                
                for i=1:PL.getNumberOfPositions
                    ps = PL.getPositionCopy(i-1);
                    for j=1:length(Pos.axis)
                        switch Pos.axis{j}
                            case 'X'
                                Pos.List(i,j)=ps.getX;
                            case 'Y'
                                Pos.List(i,j)=ps.getY;
                            case 'XY'
                                Pos.List(i,j:j+1)=[ps.getX ps.getY];
                            case 'Z'
                                Pos.List(i,j)=ps.getZ;
                        end
                    end
                    Pos.Labels{i}=char(ps.getLabel);
                end
            end
            if nargin && isa(fullfilename,'org.micromanager.navigation.PositionList')
                Pos.Group=Pos.Labels; 
            end
        end
        
        function save(Pos,fullfilepath)
            PL = Pos.getMMPosList;
            PL.save(fullfilepath);
        end
        
        function Pos = add(Pos,xy,labels)
            if any(ismember(labels,Pos.Labels))
                error('Position with this name already exists');
            end
            Pos.List = [Pos.List; xy];
            if ~iscell(labels)
                labels={labels};
            end
            Pos.Labels = [Pos.Labels; labels];
            Pos.Group = [Pos.Group; strtok(labels,'_')];
        end
        
        function tf = hasZ(Pos)
            tf = any(~cellfun(@isempty,regexp(Pos.axis,'Z'))) ;
        end
        
        function N=get.N(Pos)
            N=size(Pos.List,1);
        end
        
        function NinBatch=get.NinBatch(Pos)
            if ~isempty(Pos.NumPerBatch)
                if Pos.currentBatch == 0
                    NinBatch=Pos.NumPerBatch(1);
                else
                    NinBatch=Pos.NumPerBatch(Pos.currentBatch);
                end
            else
                NinBatch=Pos.N;
            end
        end
        
        function Nbatch = get.Nbatch(Pos)
            if isempty(Pos.BatchIndNums)
                Nbatch = 1;
            else
                Nbatch = length(Pos.BatchIndNums);
            end
        end
        
        function PL = getMMPosList(Pos,Scp)
            PL = org.micromanager.navigation.PositionList;
            xyz = Pos.List;
            if size(xyz,2)==2
                xyz=[xyz zeros(size(xyz,1),1)];
            end
            lbls = Pos.Labels;
            p =  org.micromanager.navigation.MultiStagePosition;
            for i=1:Pos.N
                for j=1:numel(Pos.axis)
                    sp = org.micromanager.navigation.StagePosition;
                    sp.stageName = Scp.mmc.getXYStageDevice;
                    switch Pos.axis{1}
                        case 'XY'
                            sp.x=xyz(i,1);
                            sp.y=xyz(i,2);
                        case 'X'
                            sp.x=xyz(i,j);
                        case 'Y'
                            sp.x=xyz(i,j);
                        case 'Z'
                            spz = org.micromanager.navigation.StagePosition;
                            spz.stageName = Scp.mmc.getFocusDevice;
                            spz.z = xyz(i,j);
                    end
                end
                p.add(sp);
                if Pos.hasZ
                    p.add(spz);
                end
            end
            p.setLabel(lbls{i});
            PL.addPosition(p);
        end
        
        function ordr = get.ordr(Pos)
            if isempty(Pos.ordr)
                ordr = 1:size(Pos.List,1);
            else
                ordr = Pos.ordr;
            end
        end
        
        function label = peek(Pos,varargin)
            arg.group = false; 
            arg = parseVarargin(varargin,arg); 
            
            % returns next position without advancing indexing
            if Pos.current==0
                ix=Pos.current+1;
            else
                ix=Pos.current;
            end
            if arg.group
                label = Pos.Group{ix}; 
            else
                label = Pos.Labels{ix};
            end
            
        end
        
        function label = next(Pos)
%             % if at the end of the list and circular - init (zero out)
%             if Pos.current == size(Pos.List,1)
            if Pos.currentBatch==0
                Pos.nextBatch;
            end
            % if at the end of the ones in the batch and circular - init (return to starting ind for batch)
            if Pos.current == (Pos.batchStartInd(Pos.currentBatch) + Pos.NinBatch - 1)
                if ~Pos.circular
                    error('Already at the end of a NON circular position list')
                end
                Pos.current = Pos.batchStartInd(Pos.currentBatch)-1;
            end
            Pos.current = Pos.current+1;
            label = Pos.Labels{Pos.current};
        end
        
        function nextBatch(Pos)
            % Advance to the next batch of positions. 
            
                        
            % if at the end of the list and circular - init (zero out)
            if Pos.currentBatch >= Pos.Nbatch
                if ~Pos.circular
                    error('Already at the end of a NON circular position list')
                end
                Pos.currentBatch = 0;
            end
            
            % increment the current batch number
            Pos.currentBatch = Pos.currentBatch + 1;
            Pos.current = Pos.batchStartInd(Pos.currentBatch)-1;
            % Update the number of positions in this batch
%             Pos.NinBatch = Pos.NumPerBatch;            
        end
        
        function init(Pos)
            
            if Pos.currentBatch==0
                Pos.current=Pos.batchStartInd(1)-1;
            else
                Pos.current=Pos.batchStartInd(Pos.currentBatch)-1;
            end
%             Pos.current=0;
            
        end
        function initBatch(Pos)
            Pos.currentBatch = 0;
        end
        
        function xyzrtrn = getPositionFromLabel(Pos,label)
            xyz = Pos.List(find(ismember(Pos.Labels,label),1),:);
            if strcmp(Pos.axis,'XY')
                xyzrtrn=xyz(:,1:2);
            else
                xyzrtrn=xyz;
            end
        end
        
        function label = prev(Pos)
            if Pos.current == 1
                if ~Pos.circular
                    error('Already at the start of a NON circular position list')
                end
                Pos.current = Pos.N+1;
            end
            Pos.current = Pos.current-1;
            label = Pos.Labels{Pos.current,:};
        end
        
        function Pos = updateZ(Pos,label,Z)
            ix = find(ismember(Pos.Labels,label),1); % update only to the first one...
            Pos.List(ix,ismember(Pos.axis,'Z'))=Z;
        end
        
        function Pos = interpolateZBasedOnSubsetOfPositions(Pos,labels,varargin)
            % at this version only does a very simple interpolation
            % subset must be convex hull of all inner points
            ix = find(ismember(Pos.Labels,labels));
            xyz = [Pos.List(:,ismember(Pos.axis,'X')) ...
                Pos.List(:,ismember(Pos.axis,'Y')) ...
                Pos.List(:,ismember(Pos.axis,'Z'))];
            zfit = griddata(xyz(ix,1),xyz(ix,2),xyz(ix,3),xyz(:,1),xyz(:,2)); 
            Pos.List(:,ismember(Pos.axis,'Z'))=zfit;
            
        end
        
        function Pos = optimizeOrder(Pos,varargin)
            % set defaults
            arg.method = 'tsp';
            arg = parseVarargin(varargin,arg);
            switch (arg.method)
                case 'tsp'
                    o =  tspsearch(Pos.List);
                    ix = find(o==1);
                    o=[o(ix:end) o(1:(ix-1))]; 
                    Pos.ordr=o; 
                    
                    %                 case 'greedy'
                    %                     Pos.ordr = zeros(Pos.N,1);
                    %                     Pos.ordr(1)=1;
                    %                     for i=2:Pos.N
                    %                         ix=i:Pos.N;
                    %                         Pos.ordr(i)=ix(knnsearch(Pos.List(i-1,1:2),Pos.List(ix,1:2),1));
                    %                     end
            end
            
            Pos.Labels=Pos.Labels(Pos.ordr);
            Pos.List=Pos.List(Pos.ordr,:);
            Pos.Group=Pos.Group(Pos.ordr,:);
            if ~isempty(Pos.ExperimentMetadata)
                Pos.ExperimentMetadata=Pos.ExperimentMetadata(Pos.ordr);
            end
            if ~isempty(Pos.Skip)
                Pos.Skip=Pos.Skip(Pos.ordr); 
            end
            
        end
        
        function plot(Pos,varargin)
            % if Scp is passed use it to plot
            if isa(varargin{1},'Scope')
                Scp=varargin{1};
                varargin=varargin(2:end);
            end
            
            arg.fig = [];
            arg.showlabels = false;
            arg.time = 0;
            arg.current = Pos.current;
            arg.label = ''; % label "wins" over current index
            arg.single = false;
            arg = parseVarargin(varargin,arg);
            
            if isempty(arg.fig)
                arg.fig=figure;
            end
            figure(arg.fig)
            clf
            hold on
            if exist('Scp','var')
                Scp.Chamber.plotHeatMap(ones(Scp.Chamber.sz),'colormap',gray(256))
                if arg.single
                    if arg.label
                        lst = find(ismember(Pos.Labels,arg.label));
                    else
                        lst = arg.current;
                    end
                else
                    lst = 1:Pos.N;
                end
                if ~isempty(lst) && lst(1)>0
                    pix_size = Scp.PixelSize;
%                     if pix_size==0
%                         pix_size=0.160
%                     end
                    for i=lst
                        rct=[Pos.List(i,1:2)-Scp.Width*pix_size/2 Scp.Width*pix_size Scp.Height*pix_size];
                        if i<=arg.current
                            rectangle('position',rct,'edgecolor','c','facecolor','m'),
                        else
                            rectangle('position',rct,'edgecolor','c'),
                        end
                    end
                end
            end
            if ~arg.single
                plot(Pos.List(:,1),Pos.List(:,2),'.-')
            end
            %             set(gca, 'XDir', 'reverse','YDir','reverse')
            if arg.current > 0
                if isnumeric(arg.time)
                    arg.time = datestr(arg.time,13);
                end
                if isempty(arg.label)
                    ttl = sprintf('Current position: %s Time: %s',Pos.Labels{arg.current},arg.time);
                else
                    ttl = sprintf('Current position: %s Time: %s',arg.label,arg.time);
                end
                ttl = regexprep(ttl,'_',' ');
                title(ttl)
            end
            drawnow;
        end
        
        function addSkip(Pos,Labels,Skip)
            assert(numel(Labels)==numel(Skip),'Must provide a skip position for each label');
            %% init Skip if needed
            if isempty(Pos.Skip)
                Pos.Skip=ones(size(Pos.Labels)); 
            end
            %% add by label
            ix = ismember(Pos.Labels,Labels);
            Pos.Skip(ix)=Skip;
        end
        
        function addMetadata(Pos,Labels,Property,Value,varargin)
            arg.bygroup = true;
            arg.experimentdata = struct([]); 
            arg = parseVarargin(varargin,arg);
            
            if isempty(Property) && isempty(Value) && isstruct(arg.experimentdata); 
                fld = fieldnames(arg.experimentdata);
                for i=1:numel(fld)
                    Values = arg.experimentdata.(fld{i});
                    Pos.addMetadata(Labels,fld{i},Values)
                end
                return % stop the normal flow
            end
                        
            % Not sure why I had the line below - for now commented out
            % if there are any issue - revisit. 
%             
            for i=1:numel(Labels)
                if arg.bygroup
                    ix = find(ismember(Pos.Group,Labels{i})); 
                else
                    ix = find(ismember(Pos.Labels,Labels{i})); 
                end
                if ~isempty(ix)
                    if numel(ix)>1
                        for j=1:numel(ix)
                            Pos.ExperimentMetadata(ix(j)).(Property) = Value(i);
                        end
                    else
                        Pos.ExperimentMetadata(ix).(Property)=Value(i);
                    end
                end
            end
        end
      
        function writePositionKeyToFile(Pos,index,pth,baseacqname)
            % find the current acqusitoin folder - should be the last of
            % the Scp.getPath _x
            possPaths = dir(pth);
            % remove all the paths that do not have the baseacqname in them
            possPaths(cellfun(@isempty,regexp({possPaths.name},baseacqname)))=[];
            [~,ix]=max([possPaths.datenum]);
            fullpth = fullfile(pth,possPaths(ix).name,'Po');
            fid = fopen(fullpth,'a');
            fprintf(fid,'Pos%g,%s\n',index-1,Pos.Labels(index));
            fclose(fid);
        end
        
        function addBatch(Pos,Labels,BatchInd)
            % Add batch information to positions
            
            % Make sure there is a batch in for each label
            assert(numel(Labels)==numel(BatchInd),'Must provide a batch ind for each label');
            
            
            % Check that the batch ind array is numeric and greater than
            % zero            
            assert(all(BatchInd>0)==1 && isnumeric(BatchInd),'Batch labels must be a numeric vector greater than zero');
            
            % Convert BatchInd to categorical
            BatchInd = categorical(BatchInd);
            
            % Batch groups ordered ascending
            Pos.BatchIndNums = categories(BatchInd);
%             Pos.Nbatch = length(Pos.BatchIndNums);
            
            % Check that we have as many labels as are already defined. 
            assert(numel(Labels)==numel(Pos.Labels),'Must add batch information for all positions at one time.');
            
            % Get mapping and check that there is the same number of
            % elements
            [OrigLabels,interSortIn,interSortOrig]=intersect(Labels,Pos.Labels);
            assert(numel(OrigLabels)==numel(Pos.Labels),'Must add batch information for all positions at one time.');
            
            % Resort the BatchInd to match the current label order
            interBatchInd = BatchInd(interSortIn); %BatchInd intermediate sort based on intersect
            ordr = 1:size(Pos.List,1);
            ordrInvt = ordr(interSortOrig);
            BatchInd = interBatchInd(ordrInvt); %Now sorted based on the current order of the Labels
            
            % Update the list, labels and group ordering 
            reordr = [];
            for k =1:Pos.Nbatch
                indx = find(BatchInd == Pos.BatchIndNums{k});
                numIndx = length(indx);
                Pos.NumPerBatch(k) = numIndx;
                reordr = [reordr;indx];
                if k~=Pos.Nbatch
                    Pos.batchStartInd(k+1) = Pos.batchStartInd(k) + numIndx;
                end
            end
            Pos.ordr = reordr;
            
            Pos.Labels=Pos.Labels(Pos.ordr);
            Pos.List=Pos.List(Pos.ordr,:);
            Pos.Group=Pos.Group(Pos.ordr,:);
        end
        
    end
    
end