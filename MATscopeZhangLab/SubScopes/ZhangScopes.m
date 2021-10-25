classdef ZhangScopes < Scope
    % Subclass of Scope that makes certain behavior specific to the
    % Zhang Lab Scope4.
    
    properties
        % Live update variables
        ROIprop = {}; %
        ROIvals={};
        ROIvalsName = {};
        ROIbkgrVals = {};
        ROItpnts={};
        ROInormT = {}; % Normalized time values
        ROIcalcs={};
        LUfigH; % Live update figure handles
        LUplotH;
        LUtracePlotInds;
        currLbl = CellLabel;
        

        
    end
    
    % add ability to have user specific options
    properties (Transient = true)
        
        %Make sure to update the userSettingsTemplate.m file under
        %Utilities/helperScripts/templates when updating these preferences.
        
        % Live Update properties
        
        LUroi_Color = 'r';
        LUroi_LineStyle = '-';
        LUroi_LineWidth = 1.5;
        LUroi_Marker = '*';
        LUroi_MarkerSize = 6;
        LUroi_BkgrColor = 'g';
        
        LUplot_LineStyle = '-';
        LUplot_LineWidth = 1;
        LUplot_Marker = '*';
        LUplot_MarkerSize = 6;
        
        % show the position plot
        posPlot = true;
        
        
        eventsTable  = cell2table({0,'Example Event',0,'uM','Init'},...
            'VariableNames',{'ID','Desc','Conc','Units','Type'});
        
        
        
    end
    
    
    
    methods
        %% Constructor
        
        %% Image Acquisition tools
        
        function imgOut = onTheFlyProcessing(Scp,imgIn)
            % Overloadable method for immediately processing images
            
            % Currently just returning the image but can be overloaded in sub-scope
            imgOut = imgIn;
        end
        
        function liveUpdateAnalysis(Scp,allImg,n,p,t,T)
            % Overloadable method for processing images after the frame has
            % been acquired
            
            if Scp.verbose == 1||Scp.debugging==1;
                % Display current status 
                fprintf('calculating Live Updates...\n');
            end
            tic
            % Get current lbl
            Lbl = Scp.currLbl(p);
            
            % Save the time point as the average
            avgT =  mean(T);
            Scp.ROItpnts{p}(t,1) =avgT;
            % Add label to currLbl
            Scp.currLbl(p).addLbl(Lbl.ManualLbl,'base',avgT);
            toc
            
            % Get the roi intensities for all of the frames
            tic
            for i=1:n
                imgChange = gray2ind(allImg(:,:,i),2^Scp.BitDepth);
                Scp.ROIvals{p}(t,:,i) = meanIntensityPerLabel(Lbl,imgChange,avgT,'func','mean','type','base');
                
%                 Scp.ROIvals{p}(t,:,i) = meanIntensityPerLabel(Lbl,gray2ind(allImg(:,:,i),2^Scp.BitDepth),avgT,'func','mean','type','base');

               
                if isempty(Lbl.BkgrManualRoi)
                    Scp.ROIbkgrVals{p}(t,:,i) = nan(size(Scp.ROIvals{p}(t,:,i)));
                else
                    [chanBkgrSub,~] = Lbl.bkgrSubtractManualRoi(allImg(:,:,i));
                    Scp.ROIbkgrVals{p}(t,:,i) =  meanIntensityPerLabel(Lbl,gray2ind(chanBkgrSub,2^Scp.BitDepth),avgT,'func','mean','type','base');
                end
                
%                 Scp.ROIvals{p}(t,:,i) = Lbl.getLUmeanIntensityPerCell(allImg(:,:,i),'roi_type','Cells');
%                 Scp.ROIbkgrVals{p}(t,1,i) = Lbl.getLUmeanIntensityPerCell(allImg(:,:,i),'roi_type','Bkgr');
            end
            toc

            

        end
        
        %% Initialization of image acquisition
        
        %% For loop acquisition methods (non-queue based)
        
        %% Queued image acquisition methods
        
        function liveUpdatePrep(Scp,closeFigs)
            % Overloadable function needed to initalize the live updates
            
            % clear currLbl
            Scp.currLbl = CellLabel;
            
            if closeFigs == 1
                % Find open figures for live updates
                openFigHandles = find(ishandle(Scp.LUfigH(:)));
                % Close open figure handles
                close(Scp.LUfigH(openFigHandles));
                % Clear the figure handle list
                Scp.LUfigH = [];
            end
        end
        
        function postQueueProc(Scp,src,eventData)
            % Method to clean up and save MD after the queue has finished
            
            fprintf('In post queue scope process \n');
            delete(Scp.endLH);
            
            if ~isempty(Scp.MD.ImgFiles)
                %                 try
                Scp.MD.saveMetadata(fullfile(Scp.pth,Scp.acqNameHolder));
                
                
                if Scp.LiveUpdates == 1
                    cd(fullfile(Scp.pth,Scp.acqNameHolder));
                    
                    % Generate Results file
                    R = MultiPositionSingleCellResults(fullfile(Scp.pth,Scp.acqNameHolder));
                    R.PosNames = unique(Scp.MD,'Position');
                    Channels = unique(Scp.MD,'Channel');
                    
                    % Grab non default props
                    Props =  Scp.MD.NewTypes;
                    
                    for m = 1:Scp.Pos.N
                        if ~isempty(Scp.currLbl(m).Lbl)
                            
                            % get timepoints for measurements.
                            T = Scp.MD.getSpecificMetadata('TimestampFrame','Channel',Channels{1},'Position',R.PosNames{m},'timefunc',@(t) true(size(t)));
                            T=cat(1,T{:});
                            
                            % Relative Time in seconds
                            Trel = (T-T(1))*24*3600;
    
                            % Add lbl to results
                            Lbl = setLbl(R,Scp.currLbl(m),R.PosNames{m});
                            
                            %                             % Add the time searies for each of the channels
                            %                             for k = 1:length(Scp.ROIvalsName)
                            %                                 addTimeSeries(R,Scp.ROIvalsName{k},Scp.ROIvals{m}(:,:,k),Scp.ROItpnts{m},R.PosNames{m});
                            %                             end
                            %
                            % Add the calculations done
                            nProps = length(Scp.ROIprop(:,1));
                            for k = 1:length(Channels)
                                R.addTimeSeries(Channels{k},Scp.ROIvals{m},Trel,R.PosNames{m});
                                R.addTimeSeries([Channels{k},'_bkgrSub'],Scp.ROIbkgrVals{m},Trel,R.PosNames{m});
                                if m == 1
                                    if k==1
                                       chStrAdd =['[',Channels{k},',~] = getTimeseriesData(R,''',Channels{k},''',R.PosNames{i});\n\t'];
                                       chStrAdd = [chStrAdd,'[',Channels{k},'_bkgrSub,~] = getTimeseriesData(R,''',Channels{k},'_bkgrSub'',R.PosNames{i});\n\t'];
                                    else
                                       chStrAdd =[chStrAdd,'[',Channels{k},',~] = getTimeseriesData(R,''',Channels{k},''',R.PosNames{i});\n\t'];
                                       chStrAdd = [chStrAdd,'[',Channels{k},'_bkgrSub,~] = getTimeseriesData(R,''',Channels{k},'_bkgrSub'',R.PosNames{i});\n\t'];
                                    
                                    end
                                        
                                end
                            end
                            
                            propsStrAdd = '';
                            for k = 1:nProps
                                addTimeSeries(R,Scp.ROIprop{k,5},Scp.ROIcalcs{k,m},Trel,R.PosNames{m});
                                if m == 1
                                    if k==1
                                        propsStrAdd =[Scp.ROIprop{k,5},' = ',Scp.ROIprop{k,2},';\n\t'];
                                        propsStrAdd =[propsStrAdd,'addTimeSeries(R,''',Scp.ROIprop{k,5},''',',Scp.ROIprop{k,5},',Trel,R.PosNames{i});\n\t'];
                                    else
                                        propsStrAdd =[propsStrAdd,Scp.ROIprop{k,5},' = ',Scp.ROIprop{k,2},';\n\t'];
                                        propsStrAdd =[propsStrAdd,'addTimeSeries(R,''',Scp.ROIprop{k,5},''',',Scp.ROIprop{k,5},',Trel,R.PosNames{i});\n\t'];
                                    end
                                        
                                end
                            end
                            
                            % add Position properties
                            for j=1:numel(Props)
                                try
                                    tmp=unique(Scp.MD,Props{j},'Position',R.PosNames{m});
                                    if isempty(tmp)
                                        setProperty(R,Props{j},NaN,R.PosNames{m});
                                    else
                                        setProperty(R,Props{j},tmp(1),R.PosNames{m});
                                    end
                                catch
                                    warning('off','backtrace')
                                    warning('Attempted to set property, %s, but unable to get unique values',Props{j});
                                    warning('on','backtrace')
                                end
                            end
                            
                            %                             Scp.currLbl(m).dumpToDrive(fullfile(Scp.pth,Scp.acqNameHolder),Scp.Pos.Labels{m});
                        end
                    end
                    % Save the results
                    R.saveResults;
                    
                    % Generate LUresults mfile
                    
                    % Get base template for user prefs
                    firstPart = fileread('resultsPart1.m');
                    
                    % Add comment at the beginning of how this was made and the date
                    LUanalysisStr = sprintf(['%% Analysis script automatically generated by Live Updates in Scope.m \n',...
                        '%% on ',date,'\n\n',...
                        '%% Make sure that the analysis file is on the MATLAB path when running from results \n\n',...
                        '%%%% Key user input - the path where the images are (try to keep as a relative path) \n',...
                        'pth = ''']);
                    LUanalysisStr = [LUanalysisStr,filesep,fullfile(Scp.relpth,Scp.MD.acqname),sprintf(''';\n')];
%                     analysisFile = [filesep,fullfile(Scp.relpth,Scp.MD.acqname,['LUresultsScript',datestr(now,'yymmdd'),'.m'])];
                    % Change to just havingLocalName
                    analysisFile = ['LUres_',Scp.acqNameHolder,'_',datestr(now,'yymmdd'),'.m'];
                    
                    % Add on the next part
                    LUanalysisStr = [LUanalysisStr,firstPart];
                    
                    % Add the caluclations to the script.
                    LUanalysisStr = [LUanalysisStr,...
                        sprintf('%% Get channel values by name \n\t'),sprintf(chStrAdd),...
                        sprintf('\n\t%% Re-calculate cell values \n\t'),sprintf(propsStrAdd)];
                    
                    endPart = fileread('resultsPartEnd.m');
                    LUanalysisStr = [LUanalysisStr,endPart];
                    
                    
                    % Write the settings file
                    fid = fopen(analysisFile,'w');
                    fwrite(fid,LUanalysisStr);
                    fid = fclose(fid);
                    
                    R.analysisScript = analysisFile;
                    
                    % Save the results
                    R.saveResults;
                    
                    % Re-run the analysis script
                    R.runAnalysis;
                end
            end
            fprintf('Completed post queue scope process \n');
            Scp.Sched.clearQueue();
            Scp.acqNameHolder = [];
            
        end
        
        function liveUpdateEvent(Scp,cellIn)
            % Update live update calculations and plots at the end of
            % acquiring all positions.
            
            if Scp.verbose == 1 || Scp.debugging == 1
                fprintf('In Live update event \n');
            end
            t = Scp.Tpnts.current; % Current time index
            
            if t> 0
                % Do liveupdate calculations
                if Scp.LiveUpdates == 1
                    
                    nPos = Scp.Pos.N; % Number of positions
                    plotCounter = 0;
                    for m = 1:nPos
%                         % Add cell label
                        ManualLbl = Scp.currLbl(m).ManualLbl;
%                         if size(ManualLbl,1) == Scp.Width && size(ManualLbl,2) == Scp.Height
%                             % Check that the label is actually of the right
%                             % dimentsions then add
%                             Scp.currLbl(m).addLbl(ManualLbl,'base',Scp.ROItpnts{m}(t,1))
%                         end
                        
                        if ~isempty(Scp.ROIprop)
                            
                            nProps = length(Scp.ROIprop(:,1));
                            
                            
                            for k = 1:nProps
                                calcFn = Scp.ROIprop{k,1};
                                plotSep = Scp.ROIprop{k,3};
                                calcName = Scp.ROIprop{k,6};
                                
                                values = feval(calcFn,Scp.ROIvals{m},Scp.ROIbkgrVals{m},t);
                                Scp.ROIcalcs{k,m}(t,:)=values;
                                if Scp.ROIprop{k,4} == 1
                                    % Normalize to first position's initial time
                                    Scp.ROInormT{k,m}(t,1) = (Scp.ROItpnts{m}(t,1) - Scp.ROItpnts{1}(1,1))*24*60*60;
                                else
                                    % Normalize to own position's initial time
                                    Scp.ROInormT{k,m}(t,1) = (Scp.ROItpnts{m}(t,1) - Scp.ROItpnts{m}(1,1))*24*60*60;
                                end
                                
                                if t == 1
                                    % On the first timepoint initialize the
                                    % plots and figures
                                    
                                    % Plot the masks
                                    if k == 1
                                        Scp.LUfigH(m) = figure;
                                        %                                         ROImask = Scp.MD.LiveROIdata{m,6};
                                        plotH = imagesc(ManualLbl);
                                        ax = gca;
                                        colorbar(ax,'Ticks',0:max(max(ManualLbl)));
                                        plotCounter = plotCounter + 1;
                                        Scp.LUplotH{plotCounter} = plotH;
                                    end
                                    % Number of ROI for this calc and pos.
                                    nValues = length(Scp.ROIcalcs{k,m}(1,:));
                                    if plotSep == 1
                                        Scp.LUfigH(k+nPos) = figure;
                                        title([calcName,' - ',Scp.Pos.Labels{m}]);
                                        xlabel('Time (s.)')
                                        % make legend names
                                        leader = repmat('ROI ',nValues,1);
                                        nums = num2str([1:nValues]');
                                        legNames = [leader,nums];
                                    else
                                        if m == 1
                                            Scp.LUfigH(k+nPos) = figure;
                                            title(calcName);
                                            xlabel('Time (s.)')
                                        else
                                            figure(Scp.LUfigH(k+nPos))
                                        end
                                        % make legend names
                                        leader = repmat([Scp.Pos.Labels{m},' - ROI '],nValues,1);
                                        nums = num2str([1:nValues]');
                                        legNames = [leader,nums];
                                    end
                                    % Convert legend char array to cell array
                                    legNames = cellstr(legNames);
                                    
                                    plotCounter = plotCounter + 1;
                                    hold on;
                                    plotH = plot(Scp.ROInormT{k,m},Scp.ROIcalcs{k,m},...
                                        'LineStyle',Scp.LUplot_LineStyle,...
                                        'LineWidth',Scp.LUplot_LineWidth,...
                                        'Marker', Scp.LUplot_Marker,...
                                        'MarkerSize',Scp.LUplot_MarkerSize);
                                    
                                    % Set display names
                                    set(plotH,{'DisplayName'},legNames);
                                    
                                    % Create legend
                                    if plotSep == 1
                                        hold off;
                                        legend('show','Location','eastoutside');
                                    else
                                        % wait till all plotted to add legend
                                        if m == nPos
                                            hold off;
                                            legend('show','Location','eastoutside');
                                        end
                                    end
                                    
                                    
                                    % Set datasource to update plot with.
                                    for n = 1:length(plotH)
                                        plotH(n).XDataSource = ['Scp.ROInormT{',num2str(k),',',num2str(m),'}'];
                                        plotH(n).YDataSource = ['Scp.ROIcalcs{',num2str(k),',',num2str(m),'}(:,',num2str(n),')'];
                                    end
                                    
                                    % Store plot handles
                                    Scp.LUplotH{plotCounter} = plotH;
                                    numTracePlots = length(Scp.LUtracePlotInds);
                                    Scp.LUtracePlotInds(numTracePlots +1) = plotCounter;
                                    %                             else
                                    %                                 plotCounter = plotCounter + 1;
                                    %                                 refreshdata(Scp.LUplotH(plotCounter + m));
                                end
                            end
                        end
                        
                        
                    end
                    
                    % Update the plots
                    for n = 1:length(Scp.LUtracePlotInds)
                        refreshdata(Scp.LUplotH(Scp.LUtracePlotInds(n)));
                    end
                end
            end
            
%             notify(Scp,'LUcallback');
        end
        
        %% Devices methods
        
        %% Position methods
        
        %% Flat Field Correction Methods
        
        %% Get/set properties
        %% Micro-manager properties
        %% Path Properties
        %% User Properties
        
        function setUserprefs(Scp)
            
            % Find protocol path to see if user preferences is in there.
            protoPth = fullfile(Scp.basePath,Scp.Username,'Protocols');
            settingsFile = fullfile(Scp.basePath,Scp.Username,'Protocols',['ScopeSettings_',Scp.Username,'.m']);
            eventsFile = fullfile(Scp.basePath,Scp.Username,'Protocols',['eventsTable_',Scp.Username,'.mat']);
            
            if ~exist(protoPth,'dir')
                % make a Protocols folder
                mkdir(protoPth)
            end
            
            % Add protocols to path
            addpath(protoPth)
            
            % Make user settings file if it doesnt exist
            if ~exist(settingsFile,'file')
                
                % Get base template for user prefs
                settingsTempl = fileread('userSettingsTemplate.m');
                
                % Add user name to function at beggining of file
                settingsTempl = ['function ScopeSettings_',Scp.Username,'(Scp)',char(10),settingsTempl];
                
                % Write the settings file
                fid = fopen(settingsFile,'w');
                fwrite(fid,settingsTempl);
                fid = fclose(fid);
            end
            
            % Pause to allow the file to finish writing
            while ~exist(settingsFile,'file')
                pause(0.1);
            end
            
            % User settings function
            settingsFnc = str2func(['ScopeSettings_',Scp.Username]);
            
            % Update user settings
            try
                settingsFnc(Scp);
            catch
                error('error in running your settings function from your Protocols folder, please check that the settings script is properly set up');
            end
            
            % Check if events table exists, if so Load it into the
            % variables otherwise create new eventsTable file
            if ~exist(eventsFile,'file')
                
                % Get the base event file
                eventsTable = Scp.eventsTable;
                
                % Save events file
                save(eventsFile,'eventsTable');
                
            else
                
                % load the stored events table
                load(eventsFile,'eventsTable');
                
                % Update the scope variable
                Scp.eventsTable = eventsTable;
                
            end
        end
        
        %% Metadata Properties
        %% Acquisition Properties
        
        function Mag = getOptovar(Scp)
            % Overloadable method to get the optovar magnification
            
            switch Scp.ScopeName
                case 'None'
                    throw(MException('OptovarFetchError', 'ScopeStartup did not handle optovar'));
                case 'Demo'
                    Mag = 1;
                case 'ZeissAxioObserverZ1'
                    Mag = 1;
                case 'Zeiss_Axio_0'
                    Mag = 1;
            end
        end
        
        %% Image Properties
        %% Position Properties
        %% Chamber Properties
        %% Environmental Properties
        %% Flat-field Properties
        %% Display Properties
        %% Timestamp Properties
        
        %% Accessory Methods
        
        
        %% Acquisition Properties
        
        
        %% Subscope unique methods
        
        
        
        function acqOne(Scp,AcqData,acqname,varargin)
            % acqOne - get a single image from each channel and position so
            % that ROI can be specified for a given position to be able to
            % get live updates of intensities or image ratios.
            
            Scp.Pos.init;
            Scp.SkipCounter=Scp.SkipCounter+1;
            
            % Reset Scp ROI parameters
            Scp.ROIprop = {};
            Scp.ROIvals = {};
            Scp.ROIvalsName = {};
            Scp.ROIbkgrVals = {};
            Scp.ROIcalcs = {};
            Scp.ROItpnts = {};
            Scp.ROInormT = {};
            
            
            %% Multi-position loop
            for j=1:Scp.Pos.N
                
                %% get Skip value
                skp = Scp.Pos.getSkipForNextPosition;
                if Scp.SkipCounter>1 && mod(Scp.SkipCounter,skp) % if we get a value different than 0 it means that this could be skipped
                    fprintf('Skipping position %s, counter at %g\n',Scp.Pos.next,Scp.SkipCounter); % still advance the position list
                    continue %skip the goto and func calls
                end
                
                %% add goto position to queue
                Scp.goto(Scp.Pos.next,Scp.Pos);
                PosName = Scp.Pos.peek;
                acqnameIn = acqname;
                %% perfrom action
                getImgStack = Scp.acqOneFrame(AcqData,acqname,varargin);
                % Scale Image stack
                getImgStack = uint16(getImgStack*2^16);
                channelNames = {AcqData(:).Channel};
                
                % Set the channel vals name
                Scp.ROIvalsName =channelNames;
                
                allImgStacks{j} = {PosName,acqnameIn,channelNames,getImgStack,[],[]}; % empty slots are for for the ROI data, and then the ROI masks
                
            end
            
            % use acqROIgui to specify the ROI for each position
            AcqROIguiHandle = AcqROIgui(Scp,allImgStacks);
            uiwait(AcqROIguiHandle);
            
        end
        
        function imgStack = acqOneFrame(Scp,AcqData,acqname,varargin)
            % acqOneFrame - acquire a single frame in currnet position
            % but don't save. This is to be able to create ROI
            
            if ~isempty(Scp.Pos)
                arg.p = Scp.Pos.current;
            else
                arg.p = 1;
            end
            arg.z=[];
            arg = parseVarargin(varargin,arg);
            
            %             t = arg.t;
            p = arg.p;
            
            % autofocus function depends on scope settings
            Scp.TimeStamp = 'before_focus';
            Scp.autofocus;
            Scp.TimeStamp = 'after_focus';
            
            %% Make sure I'm using the right MD
            Scp.MD = acqname; % if the Acq wasn't initizlied properly it should throw an error
            
            % set baseZ to allow dZ between channels
            baseZ=Scp.Z;
            
            % get XY to save in metadata
            XY = Scp.XY;
            Z=Scp.Z;
            
            n = numel(AcqData);
            %             ix=zeros(n,1);
            %             T=zeros(n,1);
            skipped=false(n,1);
            %% check that acquisition is not paused
            while Scp.Pause
                pause(0.1) %TODO - check that this is working properly with the GUI botton
                fprintf('pause\n')
            end
            for i=1:n
                
                % Never skip on the first frame...
                if  Scp.FrameCount(p) >1 && mod(Scp.FrameCount(p),AcqData(i).Skip)
                    skipped(i)=true;
                    continue
                end
                
                %% update Scope state
                Scp.updateState(AcqData(i)); % set scopre using all fields of AcqData including channel, dZ, exposure etc.
                Scp.TimeStamp='updateState';
                
                %% Snap image
                % or showing images one by one.
                img = Scp.snapImage;
                Scp.TimeStamp='image';
                imgStack(:,:,i) = img;
                
            end
            
        end
        
        function addLiveCalc(Scp,AcqData,calcString,fieldVarName,calcDesc,varargin)
            % addLiveCalc  Add a calculation for real-time tracking
            %   This method takes in a string made with the channel names
            %   or the channel name + '_bkgrSub' for the background
            %   subtracted version of that channel, e.g. 'GFP' for the raw
            %   channel values and 'GFP_bkgrSub' for the background
            %   subtracted values (using a manually defined background 
            %   region subtraction).
            %
            %
            %   MAKE SURE YOU USE SCALAR ARITHMATIC IN STRING (./ .*)
            
            arg.plotpossep = 0; % Plot positions on seperate graphs
            arg.plotcalc = 1; % flag to plot the new calculation
            arg.normtglobal = 1; % normalize the start time to just the first position timepoint
            %      If false, normalized time w.r.t. that
            %      positions first acquisition time.
            arg = parseVarargin(varargin,arg);
            
            % Check that the fieldVarName is a valid variable name
            if ~isvarname(fieldVarName)
                error('fieldVarName does not conform to MATLAB variable name requirements. Please choose a different reference name');
            end
            
            % Check that the fieldVarName hasn't already been used
            % Number of props already defined
            nProp=size(Scp.ROIprop,1);
            if nProp>0
                if any(strcmp(fieldVarName,Scp.ROIprop(:,3)))
                    error('fieldVarName conflicts with names of calculations already set. Please choose a different reference name');
                end
            end
            
            % Get all of the channel names
            chNames = {AcqData.Channel}';
            % Add '_bkgrSub' to all the channel names
            bkgrNames = strcat(chNames,'_bkgrSub');
            
            nCh = length(chNames); % Number of channels
            
            % Check that the fieldVarName doesn't conflict with the channel
            % name or background subtracted channel
            if any(strcmp(fieldVarName,chNames)) || any(strcmp(fieldVarName,bkgrNames))
                error('fieldVarName must be different than the channel names or the channel name appended with ''_bkgrSub'' ');
            end
            
            % Sort by length of string to do the longest first to prevent
            % picking up parts of a string in a long one that may be in a
            % smaller one, e.g. 'YFP' inside of 'FRET_YFP'
            strLen = cellfun(@(x)length(x),chNames);
            [~,sortInd] = sort(strLen,1,'descend');
            
            % Iterate through each of the channels and replace the channel
            % names with the reference matrix 
            
            newStr = calcString;
            
            for k =1:length(strLen)
                strIn = chNames{sortInd(k)};
                bkgrStrIn = bkgrNames{sortInd(k)};
                
                % First look for background subtracted
                replace = sprintf('BkgrSubValsIn(tInd,:,%i)',sortInd(k));
                
                % Replace background subtracted name with matrix reference
                newStr = regexprep(newStr,bkgrStrIn,replace);
                
                % Now that the background subtracted ones have been
                % replaced we can find the regular ones
                replace = sprintf('ROIvalsIn(tInd,:,%i)',sortInd(k));
                
                % Replace channel name with matrix reference
                newStr = regexprep(newStr,strIn,replace);
                
            end
            
                       
            
            
%             % Replace 'Ch[0-9]' with ROIvalues for the cells
%             expr = 'Ch([0-9]*)';
%             replace = 'ROIvalsIn(m,:,$1)';
%             
%             newStr = regexprep(calcString,expr,replace);
%             
%             % Replace the 'Bkgr[0-9]' with the background values for the
%             % channel.
%             
%             expr = 'Bkgr([0-9]*)';
%             replace = 'BkgrSubValsIn(m,1,$1)';
%             
%             newStr = regexprep(newStr,expr,replace);
            
            % Convert string into function.
            fnStr = ['@(ROIvalsIn,BkgrSubValsIn,tInd)',newStr];
            fnHandle = str2func(fnStr);
            
            % run a simple test to check if their string is set up
            % correctly            
            try
                
                % Generate test values
                for k = 1:nCh
                    testROIvals(:,:,k) = rand(10,5);
                    testBkgrVals(:,:,k) = testROIvals(:,:,k) + 10*pi*rand(10,5) + sqrt(2)*pi;                    
                end
                % Test calculation function
                testOut = feval(fnHandle,testROIvals,testBkgrVals,10);
            catch
                % Try again just to make sure not some fluke with the
                % random matricies
                
                try
                    % Generate test values
                    for k = 1:nCh
                        testROIvals(:,:,k) = rand(10,5);
                        testBkgrVals(:,:,k) = testROIvals(:,:,k) + 10*pi*rand(10,5) + sqrt(2)*pi;                    
                    end
                    % Test calculation function
                    testOut = feval(fnHandle,testROIvals,testBkgrVals,10);
                catch ME
                    error(['Something is not correct about the calcString format',...
                        'Check that the channel names are spelled the same ',...
                        'and that scalar arithmatic (./ .*) if intended\n',...
                        'Here is the error text: \n',ME.message]);
                end
            end
            
            
            Scp.ROIprop(nProp+1,1:6) = {fnHandle,calcString,arg.plotpossep,arg.normtglobal,fieldVarName,calcDesc};
            
        end
        
        function saveEvents(Scp)
            % Save the events file in the user's protocol folder
            
            if isempty(Scp.Username)
                warning('Username not set, unable to save events')
            else
                eventsFile = fullfile(Scp.basePath,Scp.Username,'Protocols',['eventsTable_',Scp.Username,'.mat']);
                
                eventsTable = Scp.eventsTable;
                
                save(eventsFile,'eventsTable');
            end
            
        end
        

        
    end
    
end