classdef WollmanScopes < Scope
    % Subclass of Scope that makes certain behavior specific to the
    % wollman lab. This is just holding them as I move them out of the main
    % scope and check for functionality
    
    properties
         %% LED array
        LEDarray =[];
        LEDpower = 100; % a number between 0-255 for intensity of light
        
    end
    
    
    
    methods
        
        %% Constructor
        
        %% Image Acquisition tools
        
        %% Initialization of image acquisition
        
        %% For loop acquisition methods (non-queue based)
        
        function acquire(Scp,AcqData,varargin)
            
            %% parse optional input arguments
            arg.baseacqname='acq';
            arg.show=Scp.acqshow;
            arg.save=Scp.acqsave;
            arg.closewhendone=false;
            arg.type = 'time(site)';
            arg.func = [];
            arg.acqname = '';
            arg.dz=[];
            arg.metadata=true;
            arg.reporterrorstoemailaddress = '';
            arg.channelfirst = true; % used for Z stack
            arg = parseVarargin(varargin,arg);
            
            %% Init Acq
            if isempty(arg.acqname)
                acqname = Scp.initAcq(AcqData,arg);
            else
                acqname = arg.acqname;
            end
            
            %% save all flat-field images
            for i=1:numel(AcqData)
                Scp.updateState(AcqData(i));
                Scp.Channel=AcqData(i).Channel;  % do we need this line?
                try
                    flt = getFlatFieldImage(Scp);
                    filename = sprintf('flt_%s.tif',Scp.CurrentFlatFieldConfig);
                catch
                    flt=ones([Scp.Height Scp.Width]);
                    filename=sprintf('flt_%s.tif',Scp.Channel);
                end
                
                %% save that channel to drive outside of metadata
                imwrite(uint16(mat2gray(flt)*2^16),fullfile(Scp.pth,filename));
            end
            
            %% move scope to camera port
            
            %temp solution
            %             Scp.mmc.setProperty(Scp.DeviceNames.LightPath{1},Scp.DeviceNames.LightPath{2},Scp.DeviceNames.LightPath{3});
            
            %% if metadata enforcment is in place, go acquire an empty well
            if Scp.EnforceEmptyWell
                
                % find positions that are empty
                emptywells_indx = find([Scp.Pos.ExperimentMetadata.EmptyWells]);
                
                % in a for loop:
                for i=1:numel(emptywells_indx)
                    % go to position
                    Scp.goto(Scp.Pos.Labels{emptywells_indx(i)});
                    
                    % acquire frame in all AcqData channels
                    acqFrame(Scp,Scp.AllAcqDataUsedInThisDataset,acqname,'p',emptywells_indx(i));
                end
                % remove that position from Scp.Pos
                
                while ~isempty(emptywells_indx)
                    Scp.Pos.remove(Scp.Pos.Labels{emptywells_indx(1)});
                    emptywells_indx = find([Scp.Pos.ExperimentMetadata.EmptyWells]);
                end
            end
            
            %% set up acq function
            if isempty(arg.func)
                if isempty(arg.dz)
                    arg.func = @() acqFrame(Scp,AcqData,acqname);
                else
                    arg.func = @() acqZstack(Scp,AcqData,acqname,arg.dz,'channelfirst',arg.channelfirst);
                end
            end
            
            if ~isempty(arg.reporterrorstoemailaddress)
                arg.func = @() Scp.reportToGoogle(arg.reporterrorstoemailaddress,'functorun',arg.func);
            end
            
            
            %% start a mutli-time / Multi-position / Multi-Z acquisition
            switch arg.type
                case 'time(site)'
                    func = @() multiSiteAction(Scp,arg.func);
                    multiTimepointAction(Scp,func);
                case 'site(time)'
                    func = @() multiTimepointAction(Scp,arg.func);
                    multiSiteAction(Scp,func);
            end
            if arg.metadata
                Scp.MD.saveMetadata(fullfile(Scp.pth,acqname));
            end
            if ~isempty(arg.reporterrorstoemailaddress)
                Scp.reportToGoogle(arg.reporterrorstoemailaddress,'status','Stoped run as it should');
            end
        end
          
        function reportToGoogle(Scp,email,varargin)
            arg.functorun=[];
            arg.spreadsheetID='1CRhX6wr9_D-ct8zDXamEUR_Tn8CtqAJD7fXxrg_2jsE';
            arg.sheetID = '0';
            arg.status = 'Running';
            switch Scp.ScopeName
                case 'Ninja'
                    sheetpos=[2 2];
                case 'Hype'
                    sheetpos=[5 2];
            end
            arg = parseVarargin(varargin,arg);
            
            % run func if one was provided
            if isa(arg.functorun,'function_handle');
                arg.functorun();
            end
            
            runok = mat2sheets(arg.spreadsheetID, arg.sheetID, sheetpos, {arg.status,datestr(now),email});
            if ~runok
                warning('Reporting to google spreadsheet didn''t work')
            end
        end
        
        %% Queued image acquisition methods
        
        %% Devices methods
        
        function plotTempHumodity(Scp,fig)
            if nargin==1
                fig=figure;
            end
            T=Scp.TempLog;
            H=Scp.HumidityLog;
            Tmin=min([T(:,1); H(:,1)]);
            figure(fig)
            plot(T(:,1)-Tmin,T(:,2),H(:,1)-Tmin,H(:,2))
        end
        
        %% Position methods
        
        %% Flat Field Correction Methods
        
        %% Get/set properties
        %% Micro-manager properties
        %% Path Properties
        %% User Properties
        %% Metadata Properties
        %% Acquisition Properties
        function setChannel(Scp,chnl)
            if ismember(chnl(1:3),{'LED','CUS','ARR'})
                assert(isa(Scp.LEDarray,'LEDArduino'),'Called LED config without defniing the LED Array!')
                Scp.LEDarray.parseChannel(chnl);
                chnl='Brightfield';
            else
                if isa(Scp.LEDarray,'LEDArduino')
                    Scp.LEDarray.reset();
                end
            end
            
            %% do some input checking
            % is char
            if ~ischar(chnl),
                error('Channel state must be char!');
            end
            
            %% check if change is needed, if not return
            if strcmp(chnl,Scp.Channel)
                return
            end
            
            %% Change channel
            % the try-catch is a legacy from a hardware failure where
            % the scope wasn't changing on time and we had to wait
            % longer for it to do so. We decided to keep it in there
            % since it doesn't do any harm to try changing channel
            % twice with a warning done message
            try
                Scp.mmc.setConfig(Scp.mmc.getChannelGroup,chnl);
                Scp.mmc.waitForSystem();
                assert(~isempty(Scp.Channel),'error - change channel failed');
            catch e
                fprintf('failed for the first time with error message %s, trying again\n',e.message)
                Scp.mmc.setConfig(Scp.mmc.getChannelGroup,chnl);
                Scp.mmc.waitForSystem();
                disp('done')
            end
            
            %% update GUI if not in timeCrunchMode
            if ~Scp.reduceAllOverheadForSpeed
                if Scp.MMversion > 1.5
                    Scp.studio.refreshGUI;
                else
                    Scp.gui.refreshGUI;
                end
            end
        end
        
        function setGain(Scp,gn)
            % Overloadable method to set the camera gain
            
            if ~Scp.reduceAllOverheadForSpeed || gn~=Scp.InternalGain
                Scp.mmc.setProperty('QuantEM','MultiplierGain',num2str(gn));
                Scp.InternalGain=gn;
            end
        end
        
        function setObjective(Scp,Objective)
            % Overloadable function to set the objective.
            
            % get full name of objective from shortcut
            avaliableObj = Scope.java2cell(Scp.mmc.getAllowedPropertyValues(Scp.DeviceNames.Objective,'Label'));
            label_10xnew = avaliableObj{6};
            avaliableObj{6}='10Xnew';
            % only consider Dry objectives for Scp.set.Objective
            objIx = cellfun(@(f) ~isempty(regexp(f,Objective, 'once')),avaliableObj) & cellfun(@(m) ~isempty(m),strfind(avaliableObj,'Dry'));
            if nnz(objIx)~=1
                error('Objective %s not found or not unique',Objective);
            end
            Objective = avaliableObj(objIx);
            % if requesting current objective just return
            if strcmp(Objective, Scp.Objective)
                return
            end
            % find the offsets - first Z
            obj_old = Scp.Objective;
            ix1 = ismember(avaliableObj,obj_old); %#ok<*MCSUP>
            ix2 = ismember(avaliableObj,Objective);
            dZ = Scp.ObjectiveOffsets.Z(ix1,ix2);
            
            AFstatus = Scp.mmc.isContinuousFocusEnabled;
            if AFstatus
                oldAF = Scp.mmc.getProperty(Scp.DeviceNames.AFoffset,'Position');
                oldAF = str2double(char(oldAF)); %#ok<NASGU>
            end
            Scp.mmc.enableContinuousFocus(false); % turns off AF
            
            % escape and change objectives
            oldZ = Scp.Z;
            Scp.Z = 500;
            if strcmp(Objective,'10Xnew')
                Objective = label_10xnew;
            end
            Scp.mmc.setProperty(Scp.DeviceNames.Objective,'Label',Objective);
            Scp.mmc.waitForSystem;
            % return to the Z with offset
            Scp.Z = oldZ + dZ;
            
            %             if AFstatus
            %                 Scp.mmc.enableContinuousFocus(true);
            %                 dAF = Scp.ObjectiveOffsets.AF(ix1,ix2);
            %                 Scp.mmc.setProperty(Scp.DeviceNames.AFoffset,'Position',oldAF + dAF);
            %             end
            
        end
        
        function Mag = getOptovar(Scp)
            % Overloadable method to get the optovar magnification
            
            % Change in your scope subclasses 
            
            % try to get Optovar stage from arduino - prompt user if
            % failed.
            switch Scp.ScopeName
                case 'None'
                    throw(MException('OptovarFetchError', 'ScopeStartup did not handle optovar'));
                case 'Demo'
                    Mag = 1;
                case 'Zeiss_Axio_0'
                    Mag = 1;
                case 'IncuScope_0'
                    Mag = 1;
                case 'Ninja'
                    try
                        readout = Scp.mmc.getProperty('Optovar','DigitalInput');
                        readout = str2double(char(readout));
                    catch % if error assign readout to be negative
                        readout=-1;
                    end
                    if readout == 1
                        Mag = 1.5;
                    elseif readout == 0
                        Mag = 1;
                    else % could not read optovar from arduino, trying to read from previous images, if not bail out.
                        if ~isempty(Scp.MD) && ~isempty(Scp.MD.Values)
                            warning('cannot read optovar - using Metadata pixelsize')
                            pxlmd = unique(Scp.MD,'PixelSize');
                            if pxlmd == Scp.mmc.getPixelSizeUm
                                Mag=1.5;
                            else
                                Mag=1;
                            end
                        else
                            warning('Cannot read optovar, PixelSize information not accurate')
                            Mag=1;
                        end
                    end
            end
            
        end
        
        %% Image Properties
        
        function PixelSize = getPixelSize(Scp)
            % Overloadable method to get the pixel size
            
            PixelSize = Scp.mmc.getPixelSizeUm;
            if Scp.Optovar==1
                PixelSize = PixelSize/0.7;
            end
        end
        %% Position Properties
        %% Chamber Properties
        %% Environmental Properties
        %% Flat-field Properties
        %% Display Properties
        %% Timestamp Properties
        
        %% Accessory Methods
        
        
        %% Acquisition Properties
        
        
        %% Subscope unique methods
        
        function Texpose = lightExposure(Scp,ExcitationPosition,Time,varargin)
            arg.units = 'seconds';
            arg.dichroic = '425LP';
            arg.shutter = 'ExcitationShutter';
            arg.cameraport = false;
            arg.stagespeed = [];
            arg.mirrorpos = 'mirror';%added by naomi 1/27/17
            arg.move=[]; % array of nx2 of position to move between in circular fashion. relative to current position in um
            arg.movetimes = [];
            arg = parseVarargin(varargin,arg);
            % switch time to seconds
            switch arg.units
                case {'msec','millisec','milliseconds'}
                    Time=Time/1000;
                case {'sec','Seconds','Sec','seconds'}
                    Time=Time*1;
                case {'minutes','Minutes','min','Min'}
                    Time=Time*60;
                case {'Hours','hours'}
                    Time=Time*3600;
            end
            % timestamp
            Scp.TimeStamp='start_lightexposure';
            
            
            % decide based on ExcitationPosition which Shutter and Wheel to
            % use, two options are ExcitationWheel, LEDarray
            % get list of labels for ExcitationList
            lst = Scp.mmc.getStateLabels('ExcitationWheel');
            str = lst.toArray;
            PossExcitationWheelPos = cell(numel(str),1);
            for i=1:numel(str)
                PossExcitationWheelPos{i}=char(str(i));
            end
            lst = Scp.mmc.getStateLabels('Arduino-Switch');
            str = lst.toArray;
            PossArduinoSwitchPos = cell(numel(str),1);
            for i=1:numel(str)
                PossArduinoSwitchPos{i}=char(str(i));
            end
            if ismember(ExcitationPosition,PossExcitationWheelPos)
                shutter = 'ExcitationShutter';
                wheel = 'ExcitationWheel';
            elseif ismember(ExcitationPosition,PossArduinoSwitchPos)
                shutter = '405LED';
                wheel = 'Arduino-Switch';
            else
                error('Excitation position: %s does not exist in the system',ExcitationPosition)
            end
            Scp.mmc.setProperty('Core','Shutter',shutter)
            Scp.mmc.setProperty('Dichroics','Label',arg.dichroic)
            %added by LNH 1/27/17
            Scp.mmc.setProperty('EmissionWheel','Label',arg.mirrorpos)
            %
            Scp.mmc.setProperty(wheel,'Label',ExcitationPosition)
            if arg.cameraport
                Scp.mmc.setProperty(Scp.DeviceNames.LightPath{1},Scp.DeviceNames.LightPath{2},Scp.DeviceNames.LightPath{4})
            end
            
            if ~isempty(arg.move)
                curr_xy=Scp.XY;
                arg.move=arg.move+repmat(curr_xy,size(arg.move,1),1);
                Scp.XY=arg.move(1,:);
            end
            
            Scp.mmc.setShutterOpen(true);
            Tstart=now;
            if isempty(arg.move)
                pause(Time)
            else %deal with stage movment
                % first adjust speed if requested
                
                if ~isempty(arg.stagespeed)
                    currspeed(1) = str2double(Scp.mmc.getProperty(Scp.mmc.getXYStageDevice,'SpeedX'));
                    currspeed(2) = str2double(Scp.mmc.getProperty(Scp.mmc.getXYStageDevice,'SpeedY'));
                    Scp.mmc.setProperty(Scp.mmc.getXYStageDevice,'SpeedX',num2str(arg.stagespeed));
                    Scp.mmc.setProperty(Scp.mmc.getXYStageDevice,'SpeedY',num2str(arg.stagespeed));
                end
                t0=now;
                cnt=0;
                % do first round no matter how time it takes.
                if ~isempty(arg.movetimes)
                    for j=1:arg.movetimes
                        for i=1:size(arg.move,1)
                            Scp.XY=arg.move(i,:);
                        end
                    end
                else
                    while (now-t0)*24*3600<Time % move time to sec
                        cnt=cnt+1;
                        continouscnt=continouscnt+1;
                        if cnt>size(arg.move,1)
                            cnt=1;
                        end
                        Scp.XY=arg.move(cnt,:);
                        cnt %#ok<NOPRT>
                    end
                end
            end
            Scp.mmc.setShutterOpen(false);
            Texpose=(now-Tstart)*24*3600;
            if arg.cameraport
                Scp.mmc.setProperty(Scp.DeviceNames.LightPath{1},Scp.DeviceNames.LightPath{2},Scp.DeviceNames.LightPath{3})
            end
            if ~isempty(arg.move)
                Scp.XY=curr_xy;
                if ~isempty(arg.stagespeed)
                    Scp.mmc.setProperty(Scp.mmc.getXYStageDevice,'SpeedX',num2str(currspeed(1)));
                    Scp.mmc.setProperty(Scp.mmc.getXYStageDevice,'SpeedY',num2str(currspeed(2)));
                end
            end
            Scp.mmc.setShutterOpen(false);
            Scp.mmc.setProperty('Core','Shutter','ExcitationShutter')
            Scp.TimeStamp='end_lightexposure';
        end
        
        function AcqData = optimizeChannelOrder(Scp,AcqData)
            % TODO: optimizeChannelOrder only optimzes filter wheels - need to add dichroics etc.
            n=length(AcqData);
            stats=nan(n,3); % excitaion, emission, gain
            for i=1:n
                cnf=Scp.mmc.getConfigData('Channel',AcqData(i).Channel);
                vrbs=char(cnf.getVerbose);
                if ~isempty(regexp(vrbs,'Excitation', 'once'))
                    str=vrbs(strfind(vrbs,'Excitation:Label=')+17:end);
                    str=str(1:strfind(str,'<br>')-1);
                    stats(i,1)=Scp.mmc.getStateFromLabel('Excitation',str);
                end
                if ~isempty(regexp(char(vrbs),'Emission', 'once'))
                    str=vrbs(strfind(vrbs,'Emission:Label=')+15:end);
                    str=str(1:strfind(str,'<br>')-1);
                    stats(i,2)=Scp.mmc.getStateFromLabel('Emission',str);
                end
                stats(i,3)=AcqData(i).Gain;
            end
            
            possorders=perms(1:n);
            cst=zeros(factorial(n),1);
            for i=1:size(possorders,1)
                chngs=abs(diff(stats(possorders(i,:),:)));
                chngs(isnan(chngs))=0;
                chngs(chngs(:,3)>0,3)=1;
                cst(i)=sum(chngs(:));
            end
            [~,mi]=min(cst);
            AcqData = AcqData(possorders(mi,:));
        end
    end
end