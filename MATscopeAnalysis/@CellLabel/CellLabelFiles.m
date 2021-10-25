classdef CellLabel < handle
    
    properties
        Lbl 
        Msk
        T % Time, this should be either empty, or set BEFORE the labels are being added.
        Reg % Registration object 
        filename
        saveToFile = false;
        positionName
    end
    
    properties (Dependent = true)
        Regions
        sz
        Nt
        Nc % max unique number of cells 
    end
    
    methods
        
        function tf = isempty(Lbl)
            tf = isempty(Lbl.Lbl); 
        end
        
        function sz = get.sz(Lbl)
            sz = [size(Lbl.Lbl,1) size(Lbl.Lbl,2)]; 
        end
        
        function Nt = get.Nt(Lbl)
            Nt = numel(Lbl.T); 
        end
        
        function Nc = get.Nc(Lbl) 
            Nc=max(Lbl.Lbl(:)); 
        end
        
        function Regions = get.Regions(Lbl)
            if isstruct(Lbl.Msk)
                Regions = fieldnames(Lbl.Msk);
            else
                Regions = {''}; 
            end
        end
        
        function Bnd = getCellBoundaries(Lbl,cellid,T)
            Bnd = cell(numel(T),1);
            for i=1:numel(T)
                lbl = Lbl.getLbls('base',T(i)); 
                bnd = bwboundaries(lbl==cellid); 
                Bnd{i} = bnd{1}(:,[2 1]);  
            end
                       
        end
        
        
        function R = getRegionMatrix(Lbl,T)
            
            % get index based on timepoint T (1 if empty)
            if nargin==1 || isempty(T)
                ix = 1; 
            else
                [~,ix] = min(abs(Lbl.T-T)); 
            end
            
            % create the empty matrix
            R = zeros(Lbl.sz); 
            for i=1:numel(Lbl.Regions)
                R(Lbl.Msk(:,:,ix).(Lbl.Regions{i}))=i; 
            end
            
        end
        
      
        function xy= getXY(Lbl,T,varargin)
            arg.type = 'base'; 
            arg = parseVarargin(varargin,arg); 
            
            if nargin==1 
                T=[]; 
            end
            lbl = getLbls(Lbl,arg.type,T);
            cntr = regionprops(lbl,'Centroid'); 
            xy = cat(1,cntr.Centroid); 
        end
        
        function addLbl(Lbl,newlbl,type,T,varargin)
            
            % defults
            arg.relabel = 'none'; 
            arg.maxcelldistance = 25; % distance for tracking
            arg = parseVarargin(varargin,arg); 
            
            % default value for type is base
            if ~exist('type','var') || nargin==2 || isempty(type)
                type='base'; 
            end
                        
            % if T is not specified change the first (and only!) layer 
            % if T is specified, either get the index for that timepoint or
            % add another timepoint in the end and get its index. 
            if nargin==3 || isempty(T)
                assert(isempty(Lbl.T),'Can only add a base label without a timepoint when Label doesn''t have a Time vector!'); 
                ix = 1; 
                T=[]; 
            else % find the existing exact timepoint, or add a new one in the end
                ix = find(ismember(Lbl.T,T));
                assignin('base', 'addLblT', ix);
                if isempty(ix)
                    Lbl.T(end+1)=T; 
                    ix = numel(Lbl.T); 
                end
            end
               
            
            if strcmp(type,'base') 
                if  ~isempty(Lbl.Lbl)
                    switch arg.relabel
                        case 'none'
                        case 'nearest'
                            oldlbl = newlbl; % call the newlbl oldlbl so I can then rename it into newlbl and then keep the same variable name
                            prps = regionprops(oldlbl,{'Centroid','PixelIdxList'});
                            xy = cat(1,prps.Centroid);
                            PxlIdx = {prps.PixelIdxList};
                            
                            % relabel the base according to distances to the closest
                            possT = Lbl.T(setdiff(1:numel(Lbl.T),ix));
                            [~,ix2] = min(abs(possT-T));
                            XY = getXY(Lbl,Lbl.T(ix2));
                            
                            M=annquerysingle(xy',XY', arg.maxcelldistance); 
                            
                            newlbl=zeros(Lbl.sz);
                            for i=1:size(M,1)
                                newlbl(PxlIdx{M(i,2)})=M(i,1);
                            end
                            
                        case 'lapjv' % pretty slow, but optimal assignment.
                            oldlbl = newlbl; % call the newlbl oldlbl so I can then rename it into newlbl and then keep the same variable name
                            prps = regionprops(oldlbl,{'Centroid','PixelIdxList'});
                            xy = cat(1,prps.Centroid);
                            PxlIdx = {prps.PixelIdxList};
                            
                            % relabel the base according to distances to the closest
                            possT = Lbl.T(setdiff(1:Lbl.Nt,ix));
                            [~,ix2] = min(abs(possT-T));
                            XY = getXY(Lbl,Lbl.T(ix2));
                            
                            D=distance(XY',xy');
                            
                            n1=size(D,1); % label already in Lbl
                            n2=size(D,2); % new label
                            ass = lapjv(D,0.1);
                            if n1>n2
                                id = ass;
                            else
                                id = zeros(n2,1);
                                id(ass)=1:n1;
                                id(id==0)=(n1+1):n2;
                            end
                            newlbl=zeros(Lbl.sz);
                            for i=1:n2
                                newlbl(PxlIdx{i})=id(i);
                            end
                    end
                end
                if ~saveToFile
                    Lbl.Lbl(:,:,ix)=newlbl;
                elseif saveToFile
                    assert((position & pth), 'Must set positionName if using saveToFile=true')
                    save(cat(1, pth, position), newlbl);
                    Lbl.
                end
            end
            % set up the type in the Msk datastructure. 
            if ~saveToFile
                Lbl.Msk.(type)(:,:,ix)=newlbl>0;
                elseif saveToFile
                    assert((position & pth), 'Must set positionName if using saveToFile=true')
                    Lbl.
                    save(cat(1, pth, position), Lbl.Lbl);  
                end
            Lbl.Msk.(type)(:,:,ix)=newlbl>0;
        end
        
        
        
        function imshow(Lbl,type,T)
            if nargin<2
                type=[]; 
                T=[]; 
            elseif nargin<3
                T=[]; 
            end
            lbl = Lbl.getLbls(type,T); 
            imshow(label2rgb(lbl,'jet','k','shuffle'));
        end
        
        function time = getT(Lbl)
            time = Lbl.T;
        end
        
        function lbl = getLbls(Lbl,type,T)
            
            if nargin==1 || isempty(type)
                type='base'; 
                T=[]; 
            end
                
            % decide which slice to get. 
            if nargin==2 || isempty(T)
                ix = 1; 
            else
            %find the least to greatest order of the time point as indexes
            %ix
                [~,ix] = min(abs(Lbl.T-T));
            end
            lbl = Lbl.Lbl(:,:,ix); 
            
            % zero out everything that is not in the required region type 
            lbl(~Lbl.Msk.(type)(:,:,ix))=0; 
            
        end
            
        function M = meanIntensityPerLabel(Lbl,Stk,T,varargin)
            % method will calculate a function (mean by defualt) per id per
            % time. It will use the label matrix that is closest in time to
            % the image measured in. 
            arg.type = 'base'; 
            arg.func = 'mean'; 
            arg.interp = []; 
            arg = parseVarargin(varargin,arg); 
                        
            if isempty(Lbl.T) || nargin==2 || isempty(T)
                lbl = getLbls(Lbl,arg.type);
                M = meanIntensityOverTime(Stk,lbl,arg.func);
            else
                assert(numel(T) == size(Stk,3),'Must provide a timepoint for each slice in Stack');
                if numel(T)>2
                    assert(min(diff(T))>0,'Timeseries must be monotonically increasing');  
                end
                M=nan(numel(T),Lbl.Nc); 
                dt = abs(repmat(Lbl.T(:),1,numel(T))-repmat(T(:)',numel(Lbl.T(:)),1));
                [~,ix]=min(dt,[],1);
                unq = unique(ix);

                % Made changes to meanIntensityOverTime to result in missing labels
                % becoming a column of NaN.
                for i=1:numel(unq)
                    lbl = getLbls(Lbl,arg.type,Lbl.T(unq(i)));
                    s = Stk(:,:,ix==unq(i));
                    % there could be a case where max(lbl(:))<Lbl.Nc in
                    % those cases we need to match M till max of lbl
                    % in most cases size(m,2)==Lbl.Nc. In any case the col
                    % number for a cell should match its label number and
                    % the XY position it has etc. 
                    m = meanIntensityOverTime(s,lbl,arg.func); 
                    M(ix==unq(i),1:size(m,2)) = m; 
                end
            end
            if ~isempty(arg.interp)
                M=interp1(T,M,arg.Tinterp); 
            end
            
        end
    end
    
end
        