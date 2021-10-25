classdef Scope < handle
    % Version 0.3
    % Making Scope compatible with MM 2.0
    %
    
    %% ECG TESTING %% Event handles for using queueing
%     events
%         POScallback
%         AcqFRcallback
%         Zcallback
%         TPcallback
%         LUcallback
%     end
    
    
    
    properties (Transient = true) % don't save to disk - ever...
        
        %% MM objects
        mmc % the MM core
        studio %% MM studio - the main plugin
        LiveWindow; % a MM live windows, can also be used to trigger snap
        frameID=0; % internal running number
        
        %% Acquisition related properties
        openAcq={};
        currentAcq = 0;
        CurrentDatastore;
        
        %% imaging properties
        Binning=1;
        
        Objective
        ObjectiveOffsets
        
        %% User etc
        Username
        Dataset
        Project
        ExperimentDescription %free form description of the experiment to be saved in the Metadata for this experiment.
        
        %% Acquisition information
        SkipCounter = 0; % this is for Position skipping
        Pos
        Tpnts
        AllMDs = [];
        MD = []; % current MD (this is a pointer, a copy of which will be in AllMDs as well!
        
        acqshow = 'single'; %This controls how imgaes are shown:
        %'single' shows the last image acquired. The most used and debugged options...
        % 'multi' uses MM GUI, tends to run out of memory and slows thing down
        % 'channel'
        acqsave = true;
        
        %% Timing
        Tic
        
        %Added by AKC to log time taken per site
        logTimeFile;
        
        %% image size properties
        Width
        Height
        BitDepth
        PixelSize
        
        %% Color convenstions
        Clr
        ClrArray
        
        %% Plate configurations
        %         CurrentChamberIndex = []; % index into the Chamber being imaged (this allows exploratory moving between wells etc)
        %         PossibleChambers = [Plate('Costar96 (3904)') Plate('Microfluidics Wounding Device Ver 3.0')]; % array of Chambers (subclasses of)
        Chamber % determine what is the current chamber (plate, slide, etc) that is being imaged
        
        %% Temp/Humidity sensor
        TempHumiditySensor % until I implement it as a micro-manager device...
        Temperature
        Humidity
        CO2
        TempLog=[];
        HumidityLog=[];
        CO2Log=[];
        
        
        %% Enforcing new Metadata policy
        EnforceEmptyWell = false;
        EnforcePlatingDensity = false;
        
        %% properties needed to save images
        AllAcqDataUsedInThisDataset
        AcqData % last AcqData used in a frame
        FrameCount = 0; % this is for per channel skipping
        basePath = '';
        
        TimeStamp={'init',now};
        
        ErrorLogPth
        DieOnError=true; 
        
        %% pause menu
        Pause=false;
        
        
        %% software image based autofocus related parameters
        AutoFocusType = 'Hardware'; % Software / Hardware / DefiniteFocus / None
        autogrid=10;
        AFgrid
        AFscr
        AFlog=struct('Time',[],'Z',[],'Score',[],'Channel','','Type','');
        TtoplotAFlogFrom=0;
        autofocusTimeout = 10; %seconds
        
        %% Flag to determine if should take shortcuts for speed
        reduceAllOverheadForSpeed = false; % several steps could be ignored for speed
        
        %% an array to determine config sepcific naming
        ScopeName = 'None';
        LightPath = '';
        CameraName
        DeviceNames
        
        %%  additional non-MM devices
        Devices = struct();
        
        %% Flat field correction
        FlatFields
        FlatFieldsFileName='';
        CorrectFlatField = false;
        CurrentFlatFieldConfig
        
        %% to allow showing a stack while imaging
        PastImagesToshow = 10;
        Stk = struct('data',[],'resize',0.25,'Channel','','ijp',[]);
        
        %% Percision XY
        XYpercision = 10; % microns
        dXY = [0 0];
        %% Magnification
        Optovar = 1;
        
        %% Queue properties
        Sched;  %pointer to scheduler
        endLH;  % Handle for end of queue listener
        acqNameHolder;
        
        %% Live Updates
        LiveUpdates = 0;
        
        %% Control what text get pushed to command line
        debugging = 0; % Sends a lot of text to the command window for debugging purposes
        verbose = 1; % Sends some info that might be useful to the user to the command window
        
    end
    
    properties (Access = private, Transient = true)
        InternalGain=nan;
    end
    
    properties (Dependent = true)
        Channel
        Exposure
        Gain
        Z
        X
        Y
        XY % so I can set them togahter in a singla call
        pth
        relpth
        MMversion
    end

    %% Methods
    
    methods (Static = true)
        function cl = java2cell(jv)
            n=jv.size;
            cl = cell(n,1);
            for i=1:n
                cl(i)=jv.get(i-1);
            end
        end
    end
    
    methods
        
        %% Constructor
        
        function Scp = Scope
            
            % general stuff
            warning('off','Images:initSize:adjustingMag')
            warning('off','Images:imshow:magnificationMustBeFitForDockedFigure')
            
            run('ScopeStartup')
            
            % Initialize the Scheduler for the queue            
            Scp.Sched = Scheduler(Scp,'verbose',Scp.verbose,'debugging',Scp.debugging);
        end
        
        function disp(Scp) %#ok<MANU>
            fprintf('Scope\n')
        end
        
        %% Image Acquisition tools
        
        function img = snapImage(Scp)
            % Snap a single image
            
%             if str2double(char(Scp.mmc.getProperty('Core','AutoShutter')))==1
%                 % added try-catch around this to make sure we can still
%                 % image if there is a problem with getImage. We assume that
%                 % if there is a problem in getImage before snap there will
%                 % be no issues with Snap. Hope we are right.... 2/1/2016
%                 try
%                     Scp.mmc.getImage;
%                 catch
%                     warning('no image to get from buffer so assuming snap would just work. Make sure it does!!!!')
%                 end
%             else % for some reason empty camera buffer require AS to be 1 (why?????)
%                 E=Scp.Exposure;
%                 Scp.Exposure=0;
%                 Scp.mmc.setProperty('Core','AutoShutter',1);
%                 Scp.mmc.snapImage;
%                 Scp.mmc.getImage;
%                 Scp.mmc.setProperty('Core','AutoShutter',0);
%                 Scp.Exposure=E;
%             end
            
            % continue as usual
            if ismember(Scp.acqshow,{'single','channel'})
                showImg = true; %#ok<NASGU>
            else
                showImg = false; %#ok<NASGU>
            end
            
            if Scp.MMversion > 1.5
                
                Scp.mmc.snapImage;
                timg=Scp.mmc.getTaggedImage;
                img=timg.pix;
                coords = Scp.studio.data.createCoords('t=0,p=0,c=0,z=0');
                imgtoshow = Scp.studio.data.convertTaggedImage(timg);
                imgtoshow = imgtoshow.copyAtCoords(coords);
                Scp.LiveWindow.displayImage(imgtoshow)
                
                % on 3/28 we (Roy and Alon) replaced the code below with the above lines
                % to prevent image freezing issues (where lot's of images where saved with
                % same image).
                %                 imgArray = Scp.LiveWindow.snap(showImg);
                %                 arrayIterator = imgArray.listIterator;
                %                 MMimg = arrayIterator.next;
                %                 img = MMimg.getRawPixels;
            else
                Scp.mmc.snapImage;
                img = Scp.mmc.getImage;
                
                % The Hamamatsu Flash is putting values out as int16
                % instead of uint16 so have to do conversion.
                img = typecast(img,'uint16');
            end
            img = double(img);%AOY and Rob, fix saturation BS.
            img(img<0)=img(img<0)+2^Scp.BitDepth;
            img = reshape(img,[Scp.Width Scp.Height])';
            img = mat2gray(img,[1 2^Scp.BitDepth]);
            if Scp.CorrectFlatField
                img = Scp.doFlatFieldCorrection(img);
            end
            
            if Scp.MMversion < 1.5
                if ismember(Scp.acqshow,{'single','channel'})
                    img2 = uint16(img'*2^16);
                    Scp.gui.displayImage(img2(:));
                end
            end
            
            
            % if img is identical to previous image - restart
            if ~isempty(Scp.Stk) && isequal(Scp.Stk,img)
                %
                warndlg('Image duplicaiton issue - restarting Micro-Manager')
                Scp.studio.loadSystemConfiguration;
            end
            Scp.Stk=img;
        end
        
        function acqFrame(Scp,AcqData,acqname,varargin)
            % Acquire a single frame in current position / timepoint
            
            % This method also adds / saves the metadata
            
            % set up default position based on Scope's Tpnts and Pos
            if ~isempty(Scp.Tpnts)
                arg.t = Scp.Tpnts.current;
            else
                arg.t=1;
            end
            if ~isempty(Scp.Pos)
                arg.p = Scp.Pos.current;
            else
                arg.p = 1;
            end
            arg.z=[];
            arg.savemetadata=true;
            arg.refposname=''; 
            arg.usemda = 0;
            
            arg = parseVarargin(varargin,arg);
            
            t = arg.t;
            p = arg.p;
            
            Scp.FrameCount(p)=Scp.FrameCount(p)+1;
            
            % autofocus function depends on scope settings
            Scp.TimeStamp = 'before_focus';
            Scp.autofocus;
            Scp.TimeStamp = 'after_focus';
            % Make sure I'm using the right MD
            Scp.MD = acqname; % if the Acq wasn't initizlied properly it should throw an error
            
            % set baseZ to allow dZ between channels
            baseZ=Scp.Z;
            
            % get XY to save in metadata
            
            XY = Scp.XY; %#ok<PROPLC>
            Z=Scp.Z;  %#ok<PROPLC>
            
            % Get objective to save in metadata
            objectiveLabel = Scp.Objective;
            
            n = numel(AcqData);
            ix=zeros(n,1);
            T=zeros(n,1);
            skipped=false(n,1);
            
            % check that acquisition is not paused
            while Scp.Pause
                pause(0.1) %TODO - check that this is working properly with the GUI botton
                fprintf('pause\n')
            end
            
            % Pre-allocate memory to collect all images in the frame for
            % post-frame analysis if doing LiveUpdates
            if Scp.LiveUpdates == 1
                % Pre allocate memory
                allImg= zeros(Scp.Height,Scp.Width,n);
            end
            
            if arg.usemda == 0
                for i=1:n

                    % Never skip on the first frame...
                    if  Scp.FrameCount(p) >1 && mod(Scp.FrameCount(p),AcqData(i).Skip)
                        skipped(i)=true;
                        continue
                    end

                    % See if just illumating without acquiring an image
                    justIllum = AcqData(i).illumOnly;
                    if justIllum == 1

                        %%% update Scope state
                        % Need to trick update state into giving it the
                        % appropriate exposure time for a camera even though
                        % not using.
                        exposureHolder = AcqData(i).Exposure;
                        AcqData(i).Exposure = 100;
                        Scp.updateState(AcqData(i)); % set scopre using all fields of AcqData including channel, dZ, exposure etc.
                        Scp.TimeStamp='updateState';
                        AcqData(i).Exposure = exposureHolder;

                        % Use exposure time to open shutter for a specified
                        % amount of time

                        tStartIlum = now*24*3600*1000;
                        tEndIlum = tStartIlum + exposureHolder;
                        % Open shutter
                        Scp.mmc.setShutterOpen(1)
                        Scp.TimeStamp='illuminate';
                        fprintf('Pause time till end of task: %s\n',datestr(tEndIlum/3600/24/1000-now,13));

                        while now*24*3600*1000<tEndIlum
                            fprintf('\b\b\b\b\b\b\b\b%s',datestr(tEndIlum/3600/24/1000-now,13))
                            pause(0.001)
                        end

                        % Close shutter
                        Scp.mmc.setShutterOpen(0)
                    else

                        %%% update Scope state
                        Scp.updateState(AcqData(i)); % set scopre using all fields of AcqData including channel, dZ, exposure etc.
                        Scp.TimeStamp='updateState';

                        %%% figure out image filename to be used by MM
                        filename = sprintf('img_%09g_%s_000.tif',t-1,AcqData(i).Channel);
                        if Scp.Pos.N>1 % add position folder
                            filename =  fullfile(sprintf('Pos%g',p-1),filename);
                        end
                        if ~isempty(arg.z)
                            filename = filename(1:end-4);
                            filename = sprintf('%s_%03g.tif',filename,arg.z);
                        end
                        if ~isempty(AcqData(i).dZ)
                            filename = filename(1:end-4);
                            filename = sprintf('%s_%03g.tif',filename,i);
                        end

                        %%% Snap image
                        % proceed differ whether we are using MM to show the stack

                        img = Scp.snapImage;
                        Scp.TimeStamp='image';

                        % On-the-fly image processing
                        img = onTheFlyProcessing(Scp,img);                    

                        if Scp.Pos.N>1
                            if ~exist([Scp.pth filesep acqname filesep sprintf('Pos%g',p-1)],'dir')
                                mkdir([Scp.pth filesep acqname filesep sprintf('Pos%g',p-1)]);
                            end
                        else
                            if ~exist([Scp.pth filesep acqname],'dir')
                                mkdir([Scp.pth filesep acqname]);
                            end
                        end
                        try
                            imwrite(uint16(img*2^16),fullfile(Scp.pth,acqname,filename));
                        catch  %#ok<CTCH>
                            errordlg('Cannot save image to harddeive. Check out space on drive E:');
                        end
                        Scp.TimeStamp='save image';
                        if strcmp(Scp.acqshow,'channel')
                            Scp.showStack;
                            if ~exist([Scp.pth filesep acqname],'dir')
                                mkdir([Scp.pth filesep acqname]);
                            end
                        end 

                        % timestamp to update Scope when last image was taken
                        T(i)=now; % to save in metadata

                        % return Z to baseline
                        if ~isempty(AcqData(i).dZ) && AcqData(i).dZ~=0 % only move if dZ was not empty;
                            Scp.Z=baseZ;
                            Z=baseZ;
                        end

                        %%% deal with metadata of scope parameters
                        grp = Scp.Pos.peek('group',true); % the position group name, e.g. the well
                        ix(i) = Scp.MD.addNewImage(filename,'FlatField',Scp.CurrentFlatFieldConfig,'Position',Scp.Pos.peek,'group',grp,'acq',acqname,'frame',t,'TimestampImage',T(i),'XY',XY,'PixelSize',Scp.PixelSize,'PlateType',Scp.Chamber.type,'Z',Z,'Zindex',arg.z,'Objective',objectiveLabel); %#ok<PROPLC>
                        fld = fieldnames(AcqData(i));
                        for j=1:numel(fld)
                            if ~isempty(AcqData(i).(fld{j}))
                                Scp.MD.addToImages(ix(i),fld{j},AcqData(i).(fld{j}))
                            end
                        end

                        % Collect all frame images if doing live updates
                        if Scp.LiveUpdates == 1
                            % Gather all images
                            allImg(:,:,i) = img;
                        end

%                         Scp.MD.saveMetadata(fullfile(Scp.pth,acqname));
%                         Scp.TimeStamp='metadata'; % to save within scope timestamps
                    end
                end
            else
                %%% Setup MDA
                
                Scp.updateMDA(AcqData);
                % close previous MDA
%                 if isstruct(
                if ~strcmp(class(Scp.CurrentDatastore),'double')
                    Scp.CurrentDatastore.close();
                end
                
%                 memory

                %%% Snap MDA
                % proceed differ whether we are using MM to show the stack
                Scp.CurrentDatastore = Scp.studio.acquisitions().runAcquisition();
                Scp.TimeStamp='image';


                % Save images
                for i = 1:n
                     
                    
                    %%% figure out image filename to be used by MM
                    filename = sprintf('img_%09g_%s_000.tif',t-1,AcqData(i).Channel);
                    if Scp.Pos.N>1 % add position folder
                        filename =  fullfile(sprintf('Pos%g',p-1),filename);
                    end
                    if ~isempty(arg.z)
                        filename = filename(1:end-4);
                        filename = sprintf('%s_%03g.tif',filename,arg.z);
                    end
                    if ~isempty(AcqData(i).dZ)
                        filename = filename(1:end-4);
                        filename = sprintf('%s_%03g.tif',filename,i);
                    end

                    if Scp.Pos.N>1
                        if ~exist([Scp.pth filesep acqname filesep sprintf('Pos%g',p-1)],'dir')
                            mkdir([Scp.pth filesep acqname filesep sprintf('Pos%g',p-1)]);
                        end
                    else
                        if ~exist([Scp.pth filesep acqname],'dir')
                            mkdir([Scp.pth filesep acqname]);
                        end
                    end
                    % Get image from datastore
                    builder = Scp.studio.data().getCoordsBuilder();
                    builder = builder.z(0).time(0).channel(i-1).stagePosition(0);
                    coords = builder.build();
                    imgData = Scp.CurrentDatastore.getImage(coords);
                    img = imgData.getRawPixels();
                    
                    % On-the-fly image processing
                    img = onTheFlyProcessing(Scp,img);
                    
                    % The Hamamatsu Flash is putting values out as int16
                    % instead of uint16 so have to do conversion.
                    img = typecast(img,'uint16');
                    img = double(img);%AOY and Rob, fix saturation BS.
                    img(img<0)=img(img<0)+2^Scp.BitDepth;
                    img = reshape(img,[Scp.Width Scp.Height])';
                    img = mat2gray(img,[1 2^Scp.BitDepth]);
                    
                    if Scp.CorrectFlatField
                        img = Scp.doFlatFieldCorrection(img);
                    end
                    
                    try
                        imwrite(uint16(img*2^16),fullfile(Scp.pth,acqname,filename));
                    catch  %#ok<CTCH>
                        errordlg('Cannot save image to harddeive. Check out space on drive E:');
                    end
                    Scp.TimeStamp='save image';

                    % timestamp to update Scope when last image was taken
                    T(i)=now; % to save in metadata

                    % return Z to baseline
                    if ~isempty(AcqData(i).dZ) && AcqData(i).dZ~=0 % only move if dZ was not empty;
                        Scp.Z=baseZ;
                        Z=baseZ;
                    end

                    %%% deal with metadata of scope parameters
                    grp = Scp.Pos.peek('group',true); % the position group name, e.g. the well
                    ix(i) = Scp.MD.addNewImage(filename,'FlatField',Scp.CurrentFlatFieldConfig,'Position',Scp.Pos.peek,'group',grp,'acq',acqname,'frame',t,'TimestampImage',T(i),'XY',XY,'PixelSize',Scp.PixelSize,'PlateType',Scp.Chamber.type,'Z',Z,'Zindex',arg.z,'Objective',objectiveLabel); %#ok<PROPLC>
                    fld = fieldnames(AcqData(i));
                    for j=1:numel(fld)
                        if ~isempty(AcqData(i).(fld{j}))
                            Scp.MD.addToImages(ix(i),fld{j},AcqData(i).(fld{j}))
                        end
                    end

                    % Collect all frame images if doing live updates
                    if Scp.LiveUpdates == 1
                        % Gather all images
                        allImg(:,:,i) = img;
                    end
                end
%                 Scp.MD.saveMetadata(fullfile(Scp.pth,acqname));
%                 Scp.TimeStamp='metadata'; % to save within scope timestamps
                
            end
            T(skipped)=[];
            ix(skipped)=[];
            
            if Scp.LiveUpdates == 1
                % Run analysis required for live updates
                Scp.liveUpdateAnalysis(allImg,n,p,t,T);
            end
            
            % Check if there are any images
            if max(ix)>0
                % add metadata - average time for frame and position based
                % experimental metadata
                Scp.MD.addToImages(ix,'TimestampFrame',mean(T));
                ExpMetadata = fieldnames(Scp.Pos.ExperimentMetadata);
                for i=1:numel(ExpMetadata)
                    Scp.MD.addToImages(ix,ExpMetadata{i},Scp.Pos.ExperimentMetadata(p).(ExpMetadata{i}));
                end
                if arg.savemetadata
                    Scp.MD.saveMetadata(fullfile(Scp.pth,acqname));
                end
            end
            Scp.TimeStamp='endofframe';
        end
        
        function imgOut = onTheFlyProcessing(Scp,imgIn)
            % Overloadable method for immediately processing images
            
            % Currently just returning the image but can be overloaded in sub-scope
            imgOut = imgIn;
        end
        
        function liveUpdateAnalysis(Scp,img,n,p,t,T)
            % Overloadable method for processing images after the frame has
            % been acquired
            
            % Currently empty but can be overloaded in sub-scope
            
        end
        
        function acqZstack(Scp,AcqData,acqname,dZ,varargin)
            % Aqcuire a z stack at the curent posotion.
            
            if Scp.verbose == 1 || Scp.debugging ==1
                disp('starting z stack')
            end
            % acqZstack acquires a whole Z stack
            arg.channelfirst = true; % if True will acq multiple channels per Z movement.
            % False will acq a Z stack per color.
            arg = parseVarargin(varargin,arg);
            arg.usemda = 0; % use the MDA to aqcuire a frame
            Z0 = Scp.Z;
            AFmethod = Scp.AutoFocusType;
            
            % turn autofocus off
            Scp.AutoFocusType='none';
            
            % acquire a Z stack and do all colors each plane
            if arg.channelfirst
                for i=1:numel(dZ)
                    Scp.Z=Z0+dZ(i);
                    acqFrame(Scp,AcqData,acqname,'z',i,'usemda',arg.usemda);
                end
            else % per color acquire a Z stack
                for j=1:numel(AcqData)
                    for i=1:numel(dZ)
                        Scp.Z=Z0+dZ(i);
                        acqFrame(Scp,AcqData(j),acqname,'z',i,'usemda',arg.usemda);
                    end
                end
            end
            
            % return to base and set AF back to it's previous state
            Scp.AutoFocusType = AFmethod;
            Scp.Z=Z0;
            Scp.autofocus;
            
        end
        
        % Set up the MDA specification
        
        function updateMDA(Scp,AcqData,varargin)
            
            
            
%             % Get the channel group
%             chGroup = Scp.mmc.getChannelGroup();
            % Get the Acquisition Engine
            AcqEng = Scp.studio.getAcquisitionEngine();
            % Get the current MDA settings
            settings = Scp.studio.acquisitions().getAcquisitionSettings();

            % Get already set channels
            channels = settings.channels;
            % Clear the channel list
            channels.clear();
            
            % Possible channel names
            chNames = AcqEng.getChannelConfigs();
            chNames = cell(chNames);
%             nChSet = channels.size();
%             % clear the settings (change later because this is
%             % inefficent)
%             if nChSet>0
%             for k = nChSet:-1:1
%                 channels.remove(k-1);
%             end
%             end
            settings.numFrames = 1; % Set number of frames to 1
            settings.save = false; % Turn off saving
            settings.usePositionList = false; % Turn of multiposition
            settings.slices.clear(); % clear all the z slice positions. 
            settings.keepShutterOpenChannels = false;
            
            % Update acq engine
            Scp.studio.acquisitions().setAcquisitionSettings(settings);
            
            % Build MDA settings (later move to update state)
            for k=1:length(AcqData)
                % blank ChannelSpec
                newch = org.micromanager.acquisition.ChannelSpec();
                
                % verify that channel name matches with a channel available
                if sum(strcmp(AcqData(k).Channel,chNames))~= 1
                    error('Channel specified in AcqData must exactly match the string in the channel GUI');
                end
                % specify channel 
                newch.config = AcqData(k).Channel;

                %%% exposure
                newch.exposure=AcqData(k).Exposure;

                AcqEng.addChannel(newch.config,newch.exposure,newch.doZStack,newch.skipFactorFrame,int32(0),newch.color,newch.useChannel);

                %%% dZ option between channels
                if ~isempty(AcqData(k).dZ) && AcqData(k).dZ~=0
                    % Get the updated MDA settings
                    settings = Scp.studio.acquisitions().getAcquisitionSettings();

                    % Get updated channels
                    channels = settings.channels;
                    % update the z offset
                    fprintf('dZ\n');
                    channels.get(k-1).zOffset =  AcqData(k).dZ;
                end


            end
            
            
        end
        
        %% Initialization of image acquisition
        
        function acqname = initAcq(Scp,AcqData,varargin)
            % Initialize the acquisition
            
            arg.baseacqname='acq';
            arg.show=Scp.acqshow;
            arg.save=Scp.acqsave;
            arg.closewhendone=false;
            
            arg = parseVarargin(varargin,arg);
            
            switch arg.show
                case 'multi'
                    arg.show = true;
                case 'single'
                    arg.show = false;
                case 'channel'
                    arg.show = false;
                    sz = size(imresize(zeros(Scp.Height,Scp.Width),Scp.Stk.resize));
                    Scp.Stk.data = zeros([sz Scp.Tpnts.N]);
                otherwise
                    error('Requested image display mechanism is wrong');
            end
            
            %%% fill in empty Position, Timepoints
            if isempty(Scp.Tpnts)
                Scp.Tpnts = Timepoints;
                Scp.Tpnts.initAsNow;
            end
            
            if isempty(Scp.Pos)
                Scp.Pos = Positions;
                Scp.Pos.Labels = {'here'};
                Scp.Pos.List = Scp.XY;
                Scp.Pos.Group = {'here'};
            end
            
            Scp.FrameCount = zeros(Scp.Pos.N,1);
            
            %%% update FrameID and create
            Scp.frameID = Scp.frameID+1;
            acqname = [arg.baseacqname '_' num2str(Scp.frameID)];
            
            %%%  set up the MM acqusition
            if Scp.MMversion < 2
                Scp.gui.openAcquisition(acqname,Scp.pth,Scp.Tpnts.num, length(AcqData), 1,Scp.Pos.N,arg.show,arg.save)
            end
            Scp.openAcq{end+1}=acqname;
            %             DataManager = Scp.studio.data;
            %             acqpth = fullfile(Scp.pth,acqname);
            %             Scp.CurrentDatastore = DataManager.createSinglePlaneTIFFSeriesDatastore(acqpth);
            
            %%% Init Metadata criterias
            Scp.MD = Metadata(fullfile(Scp.pth,acqname),acqname);
            Scp.MD.Description = Scp.ExperimentDescription;
            
            %%% Add user info to metadata
            Scp.MD.Project = Scp.Project;
            Scp.MD.Dataset = Scp.Dataset;
            Scp.MD.Username = Scp.Username;
            Scp.MD.relpth = Scp.relpth;
        end
        
        %% For loop acquisition methods (non-queue based)
        
        function acquire(Scp,AcqData,varargin)
            % Begin acquiring the multi-dimensional image set
            
            %%% parse optional input arguments
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
            arg.usemda = 0; % use the MDA to aqcuire a frame
            
            arg = parseVarargin(varargin,arg);
            
            % Make sure live updates are turned off as they haven't been
            % implemented for acquire
            Scp.LiveUpdates = 0;
            
            %%% Init Acq
            if isempty(arg.acqname)
                acqname = Scp.initAcq(AcqData,arg);
            else
                acqname = arg.acqname;
            end
            
            %%% save all flat-field images
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
                
                %%% save that channel to drive outside of metadata
                imwrite(uint16(mat2gray(flt)*2^16),fullfile(Scp.pth,filename));
            end
                       
            %%% if metadata enforcment is in place, go acquire an empty well
            if Scp.EnforceEmptyWell
                
                % find positions that are empty
                emptywells_indx = find([Scp.Pos.ExperimentMetadata.EmptyWells]);
                
                % in a for loop:
                for i=1:numel(emptywells_indx)
                    % go to position
                    Scp.goto(Scp.Pos.Labels{emptywells_indx(i)});
                    
                    % acquire frame in all AcqData channels
                    acqFrame(Scp,Scp.AllAcqDataUsedInThisDataset,acqname,'p',emptywells_indx(i),'usemda',arg.usemda);
                end
                % remove that position from Scp.Pos
                
                while ~isempty(emptywells_indx)
                    Scp.Pos.remove(Scp.Pos.Labels{emptywells_indx(1)});
                    emptywells_indx = find([Scp.Pos.ExperimentMetadata.EmptyWells]);
                end
            end
            
            %%% set up acq function
            if isempty(arg.func)
                if isempty(arg.dz)
                    arg.func = @() acqFrame(Scp,AcqData,acqname,'usemda',arg.usemda);
                else
                    arg.func = @() acqZstack(Scp,AcqData,acqname,arg.dz,'channelfirst',arg.channelfirst,'usemda',arg.usemda);
                end
            end
            
            %%% start a mutli-time / Multi-position / Multi-Z acquisition
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
        end
        
        function multiSiteAction(Scp,func)
            % Iterator for multi-posotion image acquistion. 
            
            % func is a function that gets one input - an index in the
            % Scp.Pos postion list
            
            % init Pos to make sure that next is well defined at the first
            % potision
            Scp.Pos.init;
            Scp.SkipCounter=Scp.SkipCounter+1;
            
            %%% Multi-position loop
            for k =1:Scp.Pos.Nbatch
                % Advance to the next batch of positions. 
                Scp.Pos.nextBatch;
                
                for j=1:Scp.Pos.NinBatch

                    %%% get Skip value
                    skp = Scp.Pos.getSkipForNextPosition;
                    if Scp.SkipCounter>1 && mod(Scp.SkipCounter,skp) % if we get a value different than 0 it means that this could be skipped
                        fprintf('Skipping position %s, counter at %g\n',Scp.Pos.next,Scp.SkipCounter); % still advance the position list
                        continue %skip the goto and func calls
                    end

                    %%% goto position
                    Scp.goto(Scp.Pos.next,Scp.Pos);

                    %%% perfrom action
                    func();

                end
            end
        end
        
        function multiTimepointAction(Scp,func)
            % Iterator for multi-timepoint image acquistion.
            
            Scp.Tpnts.start(1); % start in 1 sec delay
            Tnxt = Scp.Tpnts.next;
            %             Tindx = Scp.Tpnts.current;
            while ~isempty(Tnxt)
                %%% prompt status
                fprintf('\nTask %g out of %g.\n Time till end: %s\n',Scp.Tpnts.current,Scp.Tpnts.N,datestr(Scp.Tpnts.Tabs(end)/3600/24-now,13))
                fprintf('\n');
                % run whatever function asked for.
                func();
                
                Tpeek = Scp.Tpnts.peek;
                Tnxt = Scp.Tpnts.next;
                if isempty(Tnxt), continue, end
                % if there is some time till end of task - wait for it...
                if now*24*3600 < Tpeek
                    fprintf('Pause time till end of task: %s\n',datestr(Tpeek/3600/24-now,13));
                    while now*24*3600<Tpeek
                        fprintf('\b\b\b\b\b\b\b\b%s',datestr(Tpeek/3600/24-now,13))
                        pause(0.1)
                    end
                end
                
            end
        end
        
        %% Queued image acquisition methods
        
        function acqname = initQueue(Scp,AcqData,varargin)
            % initialize the acquisition and the queue
            
            arg.baseacqname='acq';
            arg.show=Scp.acqshow;
            arg.save=Scp.acqsave;
            arg.closewhendone=false;
            
            arg.type = 'time(site)';
            arg.func = [];
            arg.dz=[];
            arg.channelfirst = true; % used for Z stack
            arg.closelufigs = 1; % default to close the live update figures
            arg.liveupdates = 0;
            arg.timespacing = 'absolute'; %default spacing between time points
            arg.usemda = 0; % use the MDA to aqcuire a frame
            % later add 'relative' which
            % keeps the spacing between time
            % events the same.

            arg = parseVarargin(varargin,arg);
            
            acqname = initAcq(Scp,AcqData,'baseacqname',arg.baseacqname,...
                    'show',arg.show,'save',arg.save,...
                    'closewhendone',arg.closewhendone);
            
            
            %%% Setup Queue

            %%% Clean up
            % Clear previous queue and delete previous end queue listener
            delete(Scp.endLH);
            Scp.Sched.clearQueue();
            
            Scp.acqNameHolder = acqname;
            
            %%% turn on live updates if requested
            if arg.liveupdates==1
                Scp.LiveUpdates = 1;
                % Do what ever is needed to prep the live updates
                Scp.liveUpdatePrep(arg.closelufigs);
            else
                Scp.LiveUpdates = 0;
            end
            
            Scp.Pos.initBatch;
            if ~isempty(Scp.Sched)
                % Initalize the timeInfo variable.
                timeInfo = {0,arg.timespacing};
                % Choose if single Z or multi-Z
                if isempty(arg.func)
                    if isempty(arg.dz)
                        arg.func = @(tInfo) acqFramePrep(Scp,AcqData,acqname,tInfo,'usemda',arg.usemda);
                    else
                        arg.func = @(tInfo) acqZstackPrep(Scp,AcqData,acqname,arg.dz,tInfo,'channelfirst',arg.channelfirst,'usemda',arg.usemda);
                    end
                end
                
                % Choose which order to add to queue
                switch arg.type
                    case 'time(site)'
                        func = @(tInfo) multiSiteActionPrep(Scp,arg.func,tInfo,arg.liveupdates,arg.type);
                        multiTimepointActionPrep(Scp,func,timeInfo,arg.liveupdates,arg.type);
                    case 'site(time)'
                        func = @(tInfo) multiTimepointActionPrep(Scp,arg.func,tInfo,arg.liveupdates,arg.type);
                        multiSiteActionPrep(Scp,func,timeInfo,arg.liveupdates,arg.type);
                end
                
                Scp.Sched.addToQueue('End of Init pop.',{},-1,'InitPopEnd',{},'',Scp,'InitPopEnd','',0);
                
            end
            
        end
        
        function liveUpdatePrep(Scp)
            % Overloadable function needed to initalize the live updates
            
        end
        
        function acquireQueue(Scp,varargin)
            % Start the acquisition using the queue
            
            %%% parse optional input arguments
            arg.delay = 1; % include a 1 second delay.
            arg = parseVarargin(varargin,arg);
            
            %%% Init Acq
            if isempty(Scp.acqNameHolder)
                error('Acquisition not initalized, run initQueue first');
            end
            
            %%% move scope to camera port
            Scp.mmc.setProperty(Scp.DeviceNames.LightPath{1},Scp.DeviceNames.LightPath{2},Scp.DeviceNames.LightPath{3});
            
            %%% Start Queue Running
            % Create listener to run when
            Scp.endLH = addlistener(Scp.Sched,'queueFinished',@Scp.postQueueProc);
            
            % Reset Position list
            Scp.Pos.init;
            % Start Queue
            
            % Start timpoint increments counter
            Scp.Tpnts.current = 0;
            Scp.Sched.startQueue(arg.delay);
            
        end
        
        function returnTimeInfo = multiSiteActionPrep(Scp,func,timeInfo,liveUpdates,iterType)
            % Iterator to populate the queue with multi-position methods 
            
            % func is a function that gets one input - an index in the
            % Scp.Pos postion list
            
            
            % init Pos to make sure that next is well defined at the first
            % potision
            Scp.Pos.init;
            Scp.SkipCounter=Scp.SkipCounter+1;
            
            
            %%% Multi-position loop
            
                
                
                
                for j=1:Scp.Pos.NinBatch
                
                    %%% get Skip value
                    skp = Scp.Pos.getSkipForNextPosition;
                    if Scp.SkipCounter>1 && mod(Scp.SkipCounter,skp) % if we get a value different than 0 it means that this could be skipped
                        fprintf('Skipping position %s, counter at %g\n',Scp.Pos.next,Scp.SkipCounter); % still advance the position list
                        continue %skip the goto and func calls
                    end

                    % Get Pos name
                    posName = Scp.Pos.next;
                    % Initialize the CellLabel
                    Scp.currLbl(j).posname = posName;

                    %%% add goto position to queue
                    switch iterType
                        case 'time(site)'
                            Scp.Sched.addToQueue(['Move To Position i=',num2str(j)],timeInfo,-1,'MovePos',{posName},'POScallback',Scp,'xyEvent','',1);
                        case 'site(time)'
                            % Add a little bit of time so that it gets its own
                            % timepoint
                            if j>1
                                timeInfo{1} = timeInfo{1} + 0.1;
                            end
                            Scp.Sched.addToQueue(['Move To Position i=',num2str(j)],timeInfo,-1,'PrimeIter',{posName},'POScallback',Scp,'xyEvent','',1);
                    end

                    %%% perfrom action
                    timeInfo = func(timeInfo);

                    if strcmp(iterType,'site(time)')
                        if liveUpdates == 1
                            Scp.Sched.addToQueue('Update Live ROI Data',timeInfo,-1,'LiveUpdate',{},'LUcallback',Scp,'liveUpdateEvent','',1);
                        end
                    end
                
                end
            
            
            % pass back return time info.
            returnTimeInfo = timeInfo;
        end
        
        function returnTimeInfo = multiTimepointActionPrep(Scp,func,timeInfo,liveUpdates,iterType)
            % Iterator to populate the queue with multi-timepoint methods 
            
            
            for j =1:Scp.Pos.Nbatch
                % Advance to the next batch of positions. 
                Scp.Pos.nextBatch;
                Scp.Sched.addToQueue(['Start batch k=',num2str(j)],timeInfo,-1,'PrimeIter',{},'POScallback',Scp,'batchEvent','',1);
            % Go through each of the timepoints and add thing to queue
            for k = 1:Scp.Tpnts.N
                Tval = Scp.Tpnts.Tsec(k);
                if k==1
                    timeInfo{1} = Tval+timeInfo{1};
                else
                    tDiff = Tval-Scp.Tpnts.Tsec(k-1);
                    timeInfo{1} = tDiff + timeInfo{1};
                end
                switch iterType
                    case 'time(site)'
                        Scp.Sched.addToQueue(['Time point ',num2str(k),', T=',num2str(Tval)],timeInfo,-1,'PrimeIter',{[k,Tval,0]},'TPcallback',Scp,'absTimeEvent','',1);
                    case 'site(time)'
                        Scp.Sched.addToQueue(['Time point ',num2str(k),', T_rel=',num2str(Tval),', T_abs= ',num2str(timeInfo{1})],timeInfo,-1,'TimePoint',{[k,Tval,0]},'TPcallback',Scp,'absTimeEvent','',1);
                end
                timeInfo = func(timeInfo);
                
                if strcmp(iterType,'time(site)')
                    if liveUpdates == 1
                        Scp.Sched.addToQueue('Update Live ROI Data',timeInfo,-1,'LiveUpdate',{iterType},'LUcallback',Scp,'liveUpdateEvent','',1);
                    end
                end
                
                % pass back return time info.
                returnTimeInfo = timeInfo;
            end
            end
        end
        
        function returnTimeInfo = acqFramePrep(Scp,AcqData,acqname,timeInfo,varargin)
            % Populate the queue with frame acuisition methods
            
            if nargin == 4
                Scp.Sched.addToQueue('Acquire Frame(s)',timeInfo,-1,'acqFrame',{{AcqData,acqname}},'AcqFRcallback',Scp,'acqEvent','',1);
            else
                inputVars = {AcqData,acqname};
                for k = 1:length(varargin)
                    inputVars{k+2} = varargin{k};
                end
                Scp.Sched.addToQueue('Acquire Frame',timeInfo,-1,'acqFrame',{inputVars},'AcqFRcallback',Scp,'acqEvent','',1);
            end
            
            % pass back return time info.
            returnTimeInfo = timeInfo;
        end
        
        function returnTimeInfo = acqZstackPrep(Scp,AcqData,acqname,dZ,timeInfo,varargin)
            % Iterator to populate the queue with z-stack methods
            
            arg.channelfirst = true; % if True will acq multiple channels per Z movement.
            % False will acq a Z stack per color.
            arg = parseVarargin(varargin,arg);
            
            % Add zStack acquisition to queue
            Scp.Sched.addToQueue('Acquire Z Stack',timeInfo,-1,'zStack',{{AcqData,acqname,dZ,arg.channelfirst}},'Zcallback',Scp,'zStackEvent','',1);

            % pass back return time info.
            returnTimeInfo = timeInfo;
            
        end
        
        function postQueueProc(Scp,src,eventData)
            % Method to clean up and save MD after the queue has finished
            
            
            fprintf('In post queue scope process \n');
            delete(Scp.endLH);
            
            if ~isempty(Scp.MD.ImgFiles)
                Scp.MD.saveMetadata(fullfile(Scp.pth,Scp.acqNameHolder));
            end
            
            fprintf('Completed post queue scope process \n');
            
            Scp.Sched.clearQueue();
            Scp.acqNameHolder = [];
            % Reset live updates
            Scp.LiveUpdates = 0;
        end
        
        function batchEvent(Scp,cellIn)
            % Queue method called to move position (goto)
            
            if Scp.verbose == 1 || Scp.debugging ==1
                fprintf('In batch event \n');
            end
            
            % Advance to the next batch of positions. 
            Scp.Pos.nextBatch;
%             notify(Scp,'POScallback');
            %             Scp.Sched.nextInLine;
        end
        
        function xyEvent(Scp,cellIn)
            % Queue method called to move position (goto)
            
            if Scp.verbose == 1 || Scp.debugging ==1
                fprintf('In xy event \n');
            end
            
            nextPos = cellIn{:};
            Scp.Pos.next;
            Scp.goto(nextPos,Scp.Pos)
%             notify(Scp,'POScallback');
            %             Scp.Sched.nextInLine;
        end
        
        function acqEvent(Scp,cellIn)
            % Queue method called to acquire frame (acqFrame)
            
            if Scp.debugging ==1
                fprintf('In acquire frame event \n');
            end
            
            getParamVals = cellIn{:};
            Scp.acqFrame(getParamVals{:});
            %             feval(Scp.acqFrame,getParamVals{:});
%             notify(Scp,'AcqFRcallback');
            %             Scp.Sched.nextInLine;
        end
        
        function absTimeEvent(Scp,cellIn)
            % Queue method called to advance timepoints (Scp.Tpnts.current)
            
            if Scp.debugging ==1
                fprintf('In time event \n');
            end
            
            % Advance timepoint counter
            Scp.Tpnts.current = Scp.Tpnts.current+1;
            
            %             timeVect = inCell{:};
            %             if now*24*3600 < timeVect(3)
            %                 fprintf('Pause time till end of task: %s\n',datestr(timeVect(3)/3600/24-now,13));
            %                 while now*24*3600<timeVect(3)
            %                     fprintf('\b\b\b\b\b\b\b\b%s',datestr(timeVect(3)/3600/24-now,13))
            %                     pause(0.1)
            %                 end
            %             end
            
%             notify(Scp,'TPcallback');
            
        end
        
         function zStackEvent(Scp,cellIn)
            % Queue method called to acquire a zStack (acqZstack)
            
            if Scp.verbose == 1 || Scp.debugging ==1
                fprintf('In z-stack event \n');
            end
            
            extrCell = cellIn{:};
            AcqDataIn = extrCell{1};
            acqname = extrCell{2};
            dZ = extrCell{3};
            channelfirstIn = extrCell{4};
            
            Scp.acqZstack(AcqDataIn,acqname,dZ,'channelfirst',channelfirstIn)
        end
        
        
        function liveUpdateEvent(Scp,cellIn)
            % Update live update calculations and plots at the end of
            % an iteration.
            
            if Scp.verbose == 1 || Scp.debugging ==1
                fprintf('In Live update event \n');
            end
            
            % Currently empty but can be overloaded to include customized
            % updates while imaging.
            
%             notify(Scp,'LUcallback');
        end
        
        %% Devices methods
        
        function updateState(Scp,AcqData)
            % Sets the components of the microscope to the AcqData Specs.
            
            %%% check input arguments
            %             if numel(AcqData)~=1 || ~isa(AcqData,'AcquisitionData')
            %                 error('Can only update Scope with a SINGLE AcquisitionData object!')
            %             end
            
            %%% set AcqData to the one that is being used
            assert(isa(AcqData, 'AcquisitionData'), 'AcqData is not of AcquisitionData class');
            Scp.AcqData = AcqData;
            
            %%% change the scope state to be what is required by AcqData
            % change channel (only if needed othwise it will time out)
            if ~strcmp(Scp.Channel,AcqData.Channel)
                Scp.Channel=AcqData.Channel;
            end
            
            %%% exposure
            Scp.Exposure=AcqData.Exposure;
            
            %%% dZ option between channels
            if ~isempty(AcqData.dZ) && AcqData.dZ~=0
                fprintf('dZ\n');
                Scp.Z=Scp.Z+AcqData.dZ;
            end
            
            %%% camera gain if one exists
            if ~isempty(AcqData.Gain);
                Scp.Gain=AcqData.Gain;
            end
            
            %%% binning - TODO: change the hard-wired camera name!!!
            %             binning=1;
            %             if isfield(AcqData,'Bin') && ~isempty(AcqData.Bin);
            %                 Scp.mmc.setProperty('QuantEM','Binning',num2str(AcqData.Bin))
            %                 binning=AcqData.Bin;
            %                 h=Scp.Height;
            %                 w=Scp.Width;
            %             end
            %             Scp.mmc.waitForSystem;
        end
        
        function goto(Scp,label,Pos,varargin)
            % Move the stage to a given position
            
            Scp.TimeStamp = 'startmove';
            arg.plot = Scp.posPlot;
            arg.single = true;
            arg.feature='';
            arg = parseVarargin(varargin,arg);
            
            if nargin==2 || isempty(Pos) % no position list provided
                Pos  = Scp.createPositions('tmp',true,'prefix','');
                single = arg.single;
            else
                if ~isa(Pos,'Position')
                    Pos = Scp.Pos;
                end
                single = false;
            end
            
            if isempty(arg.feature)
                xyz = Pos.getPositionFromLabel(label);
            else
                AllFeatureNames = {Scp.Chamber.Features.Name};
                assert(ismember(arg.feature,AllFeatureNames),'Selected feature not define in plate configuration')
                AllFeatureXY = cat(1,Scp.Chamber.Features.XY);
                xyz = AllFeatureXY(ismember(AllFeatureNames,arg.feature),:);
                label = arg.feature;
            end
            if isempty(xyz)
                error('Couldn''t find position with label %s',label);
            end
            if Scp.verbose == 1 || Scp.debugging ==1
                fprintf('Moved to position: %s\n',label)
            end
            if strcmp(Pos.axis{1},'XY')
                Scp.XY=xyz;
            else
                for i=1:length(Pos.axis)
                    switch Pos.axis{i}
                        case 'X'
                            Scp.X=xyz(i);
                        case 'Y'
                            Scp.Y=xyz(i);
                        case 'Z'
                            Scp.Z=xyz(i);
                    end
                end
            end
            
            % update display (unless low overhead is enabled)
            if ~Scp.reduceAllOverheadForSpeed && arg.plot;
                plot(Pos,Scp,'fig',Scp.Chamber.Fig.fig,'label',label,'single',single);
            end
            Scp.TimeStamp = 'endmove';
        end
        
        function [z,s]=autofocus(Scp,AcqData)
            % Run the specified autofocus method
            
            %persistent XY;
            z=nan;
            s=nan;
            switch lower(Scp.AutoFocusType)
                case 'none'
                    if Scp.verbose == 1 || Scp.debugging ==1
                        disp('No autofocus used');
                    end
                case 'hardware'                    
                    % Run the hardware autofocus method
                    Scp.hardwareAF(AcqData)
                    
                case 'software'                    
                    % Run the software autofocus method
                    [z,s]=Scp.softwareAF(AcqData);
                otherwise
                    error('Please define type of autofocus (as None if none exist)')
            end            
        end
        
        function hardwareAF(Scp,AcqData)
            % Overloadable method to use the hardware for autofocus
            
            Scp.mmc.enableContinuousFocus(true);
            t0=now;
            while ~Scp.mmc.isContinuousFocusLocked && (now-t0)*24*3600 < Scp.autofocusTimeout
                pause(Scp.autofocusTimeout/1000)
            end
            if (now-t0)*24*3600 > Scp.autofocusTimeout
                msgbox('Out of Focus ! watch out!!!');
            end
        end
        
        function [z,s]=softwareAF(Scp,AcqData)
            % Overloadable method for software autofocus
            
            if length(AcqData)~=1
                error('autofocus can only get a single channel!')
            end
            %                     if isfield(AcqData,'ROI')
            %                         roi=AcqData.ROI;
            %                     end
            % set up imaging parameters
            if ~strcmp(Scp.Channel,AcqData.Channel)
                Scp.Channel=AcqData.Channel;
            end
            Scp.Exposure=AcqData.Exposure;

            % set up binning
            %                     if isfield(AcqData,'binning')
            %                         Scp.mmc.setProperty('CoolSNAP','Binning',num2str(AcqData.binning));
            %                         if isfield(AcqData,'ROI')
            %                             roi=ceil(roi./AcqData.binning);
            %                         end
            %                     end
            % set up ROI [x top left, y top left, width, height]
            %                     if isfield(AcqData,'ROI')
            %                         Scp.mmc.setROI(roi(1),roi(2),roi(3),roi(4));
            %                     end
            w=Scp.Width;
            h=Scp.Height;
            bd=Scp.BitDepth;

            % define image anlysis parameters
            hx = fspecial('sobel');
            hy= fspecial('sobel')';

            % Z to test on
            Z0=Scp.Z;
            Zv=Z0+linspace(-6,6,Scp.autogrid);
            S=zeros(size(Zv));
            Tlog=zeros(size(Zv));

            % open shutter
            Scp.mmc.setAutoShutter(0)
            Scp.mmc.setShutterOpen(1)

            % run a Z scan
            for i=1:length(Zv)
                tic
                Scp.Z=Zv(i);
                Scp.mmc.snapImage;
                imgtmp=Scp.mmc.getImage;
                img=reshape(single(imgtmp)./(2^bd),w,h)';
                gx=imfilter(img,hx);
                gy=imfilter(img,hy);
                S(i)=mean(hypot(gx(:),gy(:)));
                Tlog(i)=now;
            end
            % close shutter
            Scp.mmc.setShutterOpen(0)
            Scp.mmc.setAutoShutter(1)

            f=@(p,x) exp(-(x-p(1)).^2./2/p(2).^2);
            p0=[Z0 1.5];
            opt=optimset('Display','off');
            p=lsqcurvefit(f,p0,Zv,mat2gray(S),[min(Zv) 0.5],[max(Zv) 2.5],opt);
            z=p(1);
            s=interp1(Zv,S,z);

            % clear ROI if it was used
            Scp.mmc.clearROI;

            Scp.AFscr=S;
            Scp.AFgrid=Zv;

            % move to the new Z
            Scp.Z=z;


            % update the log
            Scp.AFlog.Z=[Scp.AFlog.Z(:); Zv(:)];
            Scp.AFlog.Time=[Scp.AFlog.Time(:); Tlog(:)];
            Scp.AFlog.Score=[Scp.AFlog.Score(:); S(:)];
            Scp.AFlog.Type=[Scp.AFlog.Type; repmat({'Scan'},length(Zv),1)];
            Scp.AFlog.Channel=[Scp.AFlog.Channel; repmat({AcqData.Channel},length(Zv),1)];
        end
        
        function moveByStageAFrame(Scp,direction,overlap)
            % Move the stage an image width over to create mosaic
            
            if nargin==2,
                overlap=1;
            end
            frmX = Scp.mmc.getPixelSizeUm*Scp.Width*overlap;
            frmY = Scp.mmc.getPixelSizeUm*Scp.Height*overlap;
            switch direction
                case 'north'
                    dxdy=[0 1];
                case 'south'
                    dxdy=[0 -1];
                case 'west'
                    dxdy=[1 0];
                case 'east'
                    dxdy=[-1 0];
                case 'northeast'
                    dxdy=[-1 1];
                case 'northwest'
                    dxdy=[1 1];
                case 'southeast'
                    dxdy=[-1 -1];
                case 'southwest'
                    dxdy=[1 -1];
                otherwise
                    dxdy=[0 0];
                    warning('Unrecognized direction - not moving'); %#ok<*WNTAG>
            end
            Scp.XY=[Scp.X+dxdy(1)*frmX Scp.Y+dxdy(2)*frmY];
        end
        
        %% Position methods
        
        function Pos = createPositions(Scp,varargin)
            % Automatically create positions for a multi-well plate
            
            Plt = Scp.Chamber;
            Scp.currentAcq=Scp.currentAcq+1;
            arg.msk = true(Plt.sz);
            arg.wells = Plt.Wells;
            arg.sitesperwell = [1 1]; % [x y]
            arg.alignsites = 'center';
            arg.sitesshape = 'grid';
            arg.spacing = 1; % percent of frame size
            arg.xrange = []; % determine sites based on range to image
            arg.yrange = [];
            arg.tmp = false;
            arg.experimentdata = [];
            arg.prefix = 'acq';
            arg.optimize = false;
            arg.skip=[];
            arg.imagewelloverlap=[];
            arg.manualoverride = false;
            arg.enforceemptywell=Scp.EnforceEmptyWell;
            arg.enforceplatingdensity=Scp.EnforcePlatingDensity;
            arg.batchinds = [];
            arg = parseVarargin(varargin,arg);
            
            
            %%% create relative grid per well
            frm = [Scp.PixelSize*Scp.Width ...
                Scp.PixelSize*Scp.Height];
            ttl = [frm(1)*arg.spacing*arg.sitesperwell(1) ...
                frm(2)*arg.spacing*arg.sitesperwell(2)]; %#ok<NASGU>
            dlta = [frm(1)*arg.spacing frm(2)*arg.spacing];
            
            [Xwell,Ywell] = meshgrid(cumsum(repmat(dlta(1), 1, arg.sitesperwell(1))), ...
                cumsum(repmat(dlta(2), 1, arg.sitesperwell(2))));
            Xwell=flipud(Xwell(:)-mean(Xwell(:)));
            Ywell=Ywell(:)-mean(Ywell(:));
            
            
            %%% now create grid for all wells asked for
            ixWellsToVisit = intersect(find(arg.msk),find(ismember(Plt.Wells,arg.wells)));
            Xcntr = Plt.Xcenter;
            Ycntr = Plt.Ycenter;
            
            %%% create the position list
            Pos=Positions;
            Pos.PlateType = Plt.type;
            
            %%% Gather all labels
            AllLabels = {};
            batchVect = [];
            %%% add to the position list well by well
            for i=1:numel(ixWellsToVisit)
                %%% set up labels
                WellLabels = repmat(Plt.Wells(ixWellsToVisit(i)),prod(arg.sitesperwell),1);
                if prod(arg.sitesperwell)>1
                    for j=1:arg.sitesperwell(1)
                        for k=1:arg.sitesperwell(2)
                            cnt=(j-1)*arg.sitesperwell(2)+k;
                            WellLabels{cnt}=[WellLabels{cnt} '_site' num2str(cnt) '_' num2str(j) '_' num2str(k)];
                        end
                    end
                end
                
                %%% add relative offset within wells for sites in this well
                [dX,dY]=Plt.getWellShift(arg.alignsites);
                switch arg.alignsites
                    case 'center'
                    case 'top'
                        dY=dY+Scp.Chamber.directionXY(2)*(Scp.PixelSize*Scp.Height*arg.sitesperwell(2)*arg.spacing)/2;
                    case 'bottom'
                        dY=dY-Scp.Chamber.directionXY(2)*(Scp.PixelSize*Scp.Height*arg.sitesperwell(2)*arg.spacing)/2;
                    case 'left'
                    case 'right'
                end
                
                %%% set up XY
                WellXY = [Xcntr(ixWellsToVisit(i))+Xwell+dX Ycntr(ixWellsToVisit(i))+Ywell+dY];
                
                
                %%% add up to long list
                Pos = add(Pos,WellXY,WellLabels);
                
                AllLabels=[AllLabels;WellLabels{:}];
                if ~isempty(arg.batchinds)
                     batchVect = [batchVect;repmat(arg.batchinds(ixWellsToVisit(i)),prod(arg.sitesperwell),1)];
                end
            end
            
            %%% add experiment metadata
            if ~arg.tmp
                if ~isempty(arg.experimentdata)
                    Labels = Plt.Wells;
                    Pos.addMetadata(Labels,[],[],'experimentdata',arg.experimentdata);
                    
                    fld=fieldnames(Pos.ExperimentMetadata);
                    fld=cellfun(@(m) lower(m),fld,'Uniformoutput',0);
                    if arg.enforceplatingdensity
                        assert(any(ismember(fld,'platingdensity')),'Must provide plating density in Metadata')
                        pltdens=[Pos.ExperimentMetadata.PlatingDensity];
                        assert(numel(pltdens)==Pos.N,'You did not provide Plating Density per position');
                        assert(all(pltdens>=0),'Must provide positive value for plating density')
                        assert(all(~isnan(pltdens)),'Must provide plating density to all wells')
                    end
                    
                    if arg.enforceemptywell
                        assert(any(ismember(fld,'emptywells')),'Must provide at least one empty well')
                        emptywell = [Pos.ExperimentMetadata.EmptyWells];
                        assert(numel(emptywell)==Pos.N ,'You did not provide empty well information per position');
                        assert(any(emptywell),'Must provide at least one empty well in Metadata')
                    end
                    
                    
                    
                else
                    assert(~arg.enforceplatingdensity,'Must provide Metadata with platedensity')
                    assert(~arg.enforceemptywell,'Must provide Metadata with empty well information')
                end
            end
            
            
            
            if ~isempty(arg.skip)
                Pos.addSkip(Plt.Wells(ixWellsToVisit),arg.skip(ixWellsToVisit));
                Scp.SkipCounter=0;
            end
            
            if ~isempty(arg.batchinds)
                Pos.addBatch(AllLabels,batchVect);
            end
            if arg.optimize
                Pos.optimizeOrder;
            end
            
            Pos.List(:,1)=Pos.List(:,1)+Scp.dXY(1);
            Pos.List(:,2)=Pos.List(:,2)+Scp.dXY(2);
            
            
            % allow for Z correction
            if arg.manualoverride
                for i=1:numel(Pos.Labels)
                    Scp.goto(Pos.Labels{i});
                    Scp.whereami
                    % find Z
                    uiwait(msgbox('Find focus'));
                    Pos.List(i,3)=Scp.Z;
                    Pos.List(i,1:2)=Scp.XY;
                end
                Pos.axis={'X','Y','Z'};
            end
            
            %%% unless specified otherwise update Scp
            if ~arg.tmp
                Scp.Pos = Pos;
            end
            
        end
        
        function createPositionFromMM(Scp,varargin)
            % Specify imaging positions using MM position list
            
            arg.labels={};
            arg.groups={};
            arg.axis={'XY'};
            Plt = Scp.Chamber;
            arg.guesswells = 0; % Parameter to specify if group names 
                                % should be guessed based on well. location
            arg.experimentdata=struct([]);
            arg = parseVarargin(varargin,arg);
            Scp.studio.showPositionList;
            uiwait(msgbox('Please click when you finished marking position'))
            Scp.Pos = Positions(Scp.studio.getPositionList,'axis',arg.axis);
            if ~isempty(arg.labels)
                Scp.Pos.Labels = arg.labels;
                if isempty(arg.groups)
                    Scp.Pos.Group=arg.labels;
                end
            end
            if ~isempty(arg.groups)
                Scp.Pos.Group=arg.groups;
            else
                % automatically fill in positions if no group is defined
                if isempty(Scp.Pos.Group)
                    if arg.guesswells == 1
                        % Find closest well
                        PosXY = [];
                        if strcmp(Scp.Pos.axis{1},'XY')
                            PosXY = Scp.Pos.List;
                        else
                            for i=1:length(Scp.Pos.axis)
                                switch Scp.Pos.axis{i}
                                    case 'X'
                                        PosXY(:,1) = Scp.Pos.List(:,i);
                                    case 'Y'
                                        PosXY(:,2) = Scp.Pos.List(:,i);
                                end
                            end
                        end
                        wellCenters = [Plt.Xcenter(:),Plt.Ycenter(:)];
                        distFromCenters = pdist2(wellCenters,PosXY);
                        [~,wellInds] = min(distFromCenters,[],1);
                        
                        Scp.Pos.Group= Plt.Labels(wellInds);
                    else
                        % Just give the same name as the position
                        Scp.Pos.Group=Scp.Pos.Labels;
                    end
                end
            end
            
            if ~isempty(arg.experimentdata)
                Scp.Pos.addMetadata(Scp.Pos.Labels,[],[],'experimentdata',arg.experimentdata);
            end
        end
        
        function lbl = whereami(Scp)
            % Find the closest chamber center to current XY position
            
            % Change to pdist2
            d=pdist2(Scp.XY',[Scp.Chamber.Xcenter(:) Scp.Chamber.Ycenter(:)]');
%             % Switch back to old one if pdist2 doesnt work for some reason
%             d=distance(Scp.XY',[Scp.Chamber.Xcenter(:) Scp.Chamber.Ycenter(:)]');
            [~,mi]=min(d);
            lbl = Scp.Chamber.Wells(mi);
        end
        
        function useCurrentPosition(Scp)
           Scp.Pos = Positions;
           Scp.Pos.Labels = {'here'};
           Scp.Pos.List = Scp.XY;
           Scp.Pos.Group = {'here'};
        end
        
        %% Flat Field Correction Methods
        
        
        function flt = getFlatFieldImage(Scp,varargin)
            % Get the flat field for current configuration
            
            try
                arg.flatfieldconfig = char(Scp.mmc.getCurrentConfig('FlatField'));
                arg.x1p5 = 0;
                arg = parseVarargin(varargin,arg);
                
                fltname = arg.flatfieldconfig;
                assert(isfield(Scp.FlatFields,fltname),'Missing Flat field')
                flt = Scp.FlatFields.(fltname);
                if Scp.Optovar==1.5
                    fltbig = imresize(flt,1.5);
                    flt = imcrop(fltbig,[504 512 fliplr(size(img))]);
                    flt = flt(2:end,2:end);
                end
                flt = imresize(flt,[Scp.Width Scp.Height]);
            catch e
                warning('Flat field failed with channel %s, error message %s, moving on...',Scp.Channel,e.message);
                flt=ones([Scp.Width Scp.Height]);
            end
        end
        
        function  img = doFlatFieldCorrection(Scp,img,varargin)
            % Correct image using flat-field information
            
            flt = getFlatFieldImage(Scp,varargin);
            img = (img-100/2^16)./flt+100/2^16;
            img(flt<0.05) = prctile(img(unidrnd(numel(img),10000,1)),1); % to save time, look at random 10K pixels and not all of them...
            % deal with artifacts
            img(img<0)=0;
            img(img>1)=1;
        end
        
        function doFlatFieldForAcqDataWithUserConfirmation(Scp,AcqData)
            % Create flat-field image with user confirmation
            
            for i=1:numel(AcqData)
                Scp.Channel=AcqData(i).Channel;
                Scp.Exposure=AcqData(i).Exposure;
                %                 flt = createFlatFieldImage(Scp,'filter',true,'iter',5,'assign',true);
                flt = createFlatFieldImage(Scp,'filter',true,'iter',5,'assign',true,'meanormedian','median','xymove',0.1,'open',strel('disk',250),'gauss',fspecial('gauss',150,75));
                Scp.snapImage;
                figure(321)
                imagesc(flt);
                reply = input('Did the flatfield worked? Y/N [Y]: ', 's');
                if isempty(reply)
                    reply = 'Y';
                end
                ok=strcmp('Y',reply);
                if ~ok
                    error('There was an error in flatfield - please do it again');
                end
                
            end
        end
        
        function [flt,stk] = createFlatFieldImage(Scp,varargin)
            % Create images of flat-field for later correction
            
            arg.iter = 10;
            arg.channel = Scp.Channel;
            arg.exposure = Scp.Exposure;
            arg.assign = true;
            arg.filter = false;
            arg.meanormedian = 'mean';
            arg.xymove = 0.1;
            arg.open=strel('disk',50);
            arg.gauss=fspecial('gauss',75,25);
            % will try to avoid saturation defined as pixel =0 (MM trick or
            % by the function handle in arg.saturation.
            arg.saturation = @(x) x>20000/2^16; % to disable use: @(x) false(size(x));
            arg.minexposure = 33; % minimum allowed exposure time (ms). to disable set to 0
            arg = parseVarargin(varargin,arg);
            
            
            Scp.CorrectFlatField = 0;
            
            XY0 = Scp.XY;
            
            Scp.Channel = arg.channel;
            Scp.Exposure = arg.exposure;
            stk = zeros(Scp.Height,Scp.Width,arg.iter);
            for i=1:arg.iter
                if arg.iter>1,
                    Scp.XY=XY0+randn(1,2)*Scp.Width.*Scp.PixelSize*arg.xymove;
                end
                Scp.mmc.waitForSystem;
                img = Scp.snapImage;
                iter=0;
                while nnz(img==0) > 0.01*numel(img) || nnz(arg.saturation(img)) > 0.01*numel(img)
                    Scp.Exposure = Scp.Exposure./2;
                    if Scp.Exposure < arg.minexposure
                        Scp.Exposure = arg.minexposure;
                        break
                    end
                    img = Scp.snapImage;
                    iter=iter+1;
                    if iter>10, error('Couldn''t get exposure lower enough to match saturation conditions, dilute dye'); end
                end
                img = medfilt2(img); %remove spots that are up to 50 pixel dize
                stk(:,:,i) = img;
            end
            
            switch arg.meanormedian
                case 'mean'
                    flt = nanmean(stk,3);
                case 'median'
                    flt = nanmedian(stk,3);
            end
            if arg.filter
                msk = flt>prctile(img(:),5);
                flt = imopen(flt,arg.open);
                flt(~msk)=nan;
                flt = imfilter(flt,arg.gauss,'symmetric');
            end
            flt = flt-100/2^16;
            flt = flt./nanmean(flt(:));
            
            %%% assign to FlatField
            if arg.assign
                Scp.FlatFields.(char(Scp.mmc.getCurrentConfig('FlatField')))=flt;
            end
            
            Scp.CorrectFlatField = 1;
            
        end
        
        function saveFlatFieldStack(Scp,varargin)
            % Save the stack of images for flat-field correciton to drive
            
            response = questdlg('Do you really want to save FlatField to drive (it will override older FlatField data!!!','Warning - about to overwrite data');
            if strcmp(response,'Yes')
                FlatField=Scp.FlatFields;  %#ok<NASGU>
                save(Scp.FlatFieldsFileName,'FlatField');
            end
        end
        
        function loadFlatFields(Scp)
            % Load the flat field images from the drive
            
            s = load(Scp.FlatFieldsFileName);
            Scp.FlatFields = s.FlatField;
        end
        
        %% Get/set properties
        
        %% Micro-manager properties
        function ver = get.MMversion(Scp)
            % Get the current Micro-manager version
            
            try
                verstr = Scp.studio.getVersion;
            catch
                verstr = Scp.gui.getVersion;
            end
            prts = regexp(char(verstr),'\.','split');
            ver = str2double([prts{1} '.' prts{2}]);
        end
        
        %% Path Properties
        
        function pth = get.pth(Scp)
            % Get the path based on the username, project and dataset
            
            if isempty(Scp.Username) || isempty(Scp.Project) || isempty(Scp.Dataset)
                errordlg('Please define Username, Project and Dataset');
                error('Please define Username, Project and Dataset');
            end
            pth = fullfile(Scp.basePath,Scp.Username,Scp.Project,[Scp.Dataset '_' datestr(floor(Scp.TimeStamp{1,2}),'yyyymmmdd')]);
            if ~exist(pth,'dir')
                mkdir(pth)
            end
        end
        
        function relpth = get.relpth(Scp)
            % Get the relative path based on the username, project and dataset
            
            if isempty(Scp.Username) || isempty(Scp.Project) || isempty(Scp.Dataset)
                errordlg('Please define Username, Project and Dataset');
                error('Please define Username, Project and Dataset');
            end
            relpth = fullfile(Scp.Username,Scp.Project,[Scp.Dataset '_' datestr(now,'yyyymmmdd')]);
        end
        
        %% User Properties
        
        function set.Dataset(Scp,Dataset)
            % Set dataset and clear workspace
            
            % set Dataset
            Scp.Dataset=Dataset;
            
            % clear everything but Scp
            evalin('base','keep Scp');
            % init timestamp
            Scp.TimeStamp = 'reset';
        end
        
        
        function set.Username(Scp,Username)
            % update user name preferences when the Username is set
            % Set username
            Scp.Username = Username;
            
            % Update user settings if defined
            Scp.setUserprefs();
        end
        
        function setUserprefs(Scp)
            % Overloadable method to set any user preferences when username
            % is set. 
            
        end
        
        %% Metadata Properties
        
         function set.MD(Scp,MD)
             % Set the Metadata pointer
             
            % set had to potential calls, where MD is a Metadata and where
            % MD is a char name of an existing Metadata. The first case
            % will add the MD to the scope possible MDs (assuming it has a
            % unique name). The second will make the MD with the acqname MD
            % be the currnet MD.
            if isempty(Scp.AllMDs)
                Scp.AllMDs = MD;
                Scp.MD = MD;
                return
            end
            CurrentMDs = {Scp.AllMDs.acqname};
            if isa(MD,'Metadata')
                % check to see if it exist in AllMDs
                ix = ismember(CurrentMDs,MD.acqname);
                if nnz(ix)==1
                    Scp.AllMDs(ix) = MD;
                else
                    Scp.AllMDs(end+1) = MD;
                end
                Scp.MD=MD;
            else
                % check to see if it exist in AllMDs
                ix = ismember(CurrentMDs,MD); % here MD is a char acqname
                if nnz(ix)==1
                    Scp.MD = Scp.AllMDs(ix);
                elseif nnz(ix)==0
                    error('Can''t set Scp'' active Metadata to %s it doesn''t exist!',MD)
                end
            end
         end
        
        %% Acquisition Properties
        
        function set.AcqData(Scp,AcqData)
            % Set the AcqData
            
            Scp.AcqData = AcqData;
        end
        
        function set.Channel(Scp,chnl)
            % Set the Channel state
            
            % call an external method (not get/set) so that it could be overloaded between microscopes
            setChannel(Scp,chnl)
        end
        
        function setChannel(Scp,chnl)
            % Overloadable function to set the channel properties
            
            %%% do some input checking
            % is char
            if ~ischar(chnl),
                error('Channel state must be char!');
            end
            
            %%% check if change is needed, if not return
            if strcmp(chnl,Scp.Channel)
                return
            end
            
            %%% Change channel
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
            
            %%% update GUI if not in timeCrunchMode
            if ~Scp.reduceAllOverheadForSpeed
                if Scp.MMversion > 1.5
                    Scp.studio.refreshGUI;
                else
                    Scp.gui.refreshGUI;
                end
            end
        end
        
        function chnl = get.Channel(Scp)
            % Get the current channel configuration
            
            % Call overloadable method to get channel config
            chnl = getChannel(Scp);
        end
        
        function chnl = getChannel(Scp)
            % Overloadable method to get the channel configuration
            chnl = char(Scp.mmc.getCurrentConfig(Scp.mmc.getChannelGroup));
        end
        
        function set.Gain(Scp,gn)
            % Set the camera gain
            
            % Call the overloadable method to set the camera gain
            Scp.setGain(gn);
        end
        
        function setGain(Scp,gn)
            % Overloadable method to set the camera gain
            
            % Currently only a placeholder.
        end
        
        function g = get.Gain(Scp)
            % Get camera gain settings
            
            g = getGain(Scp);
            
        end
        
        function g = getGain(Scp)
            % Overloadable method to get camera gain settings
            
            if ~Scp.reduceAllOverheadForSpeed && isnan(Scp.InternalGain)
                g = Scp.InternalGain;
            else
                g = Scp.InternalGain;
            end
        end
        
        function set.Exposure(Scp,exptime)
            % Set exposure time
            
            % check input - real and numel==1
            if ~isreal(exptime) || numel(exptime)~=1 ||exptime <0
                error('Exposure must be a double positive scalar!');
            end
            Scp.mmc.setExposure(exptime);
        end
        
        function exptime = get.Exposure(Scp)
            % Get exposure time
            
            exptime = Scp.mmc.getExposure();
            if ~isnumeric(exptime)
                exptime=str2double(exptime);
            end
        end
        
        function Objective = get.Objective(Scp)
            % Get objective label
            
            % Run overloadable method to get the objective label
            Objective = getObjective(Scp);
        end
        
        function Objective = getObjective(Scp)
            % Overloadable method to get the objective label
            
            Objective = Scp.mmc.getProperty(Scp.DeviceNames.Objective,'Label');
            Objective = char(Objective);
        end
        
        function set.Objective(Scp,Objective)
            % Set the current objective
            
            % Run the overloadable method to set the objective
            Scp.setObjective(Objective);
            
        end
        
        function setObjective(Scp,Objective)
            % Overloadable method to set the objective.
            
            % get full name of objective from shortcut
            avaliableObj = Scope.java2cell(Scp.mmc.getAllowedPropertyValues(Scp.DeviceNames.Objective,'Label'));
            
            % find the index of that objective
            objIx = cellfun(@(f) ~isempty(regexp(f,Objective, 'once')),avaliableObj);
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
            
            Scp.mmc.setProperty(Scp.DeviceNames.Objective,'Label',Objective);
            Scp.mmc.waitForSystem;
            % return to the Z with offset
            Scp.Z = oldZ + dZ;
            
        end
        
        function Mag = get.Optovar(Scp)
            % Get current optovar
            
            % Run the overloadable method to get the optovar magnification
            Mag = getOptovar(Scp);
        end
        
        function Mag = getOptovar(Scp)
            % Overloadable method to get the optovar magnification
            
            % Change in your scope subclasses 
            switch Scp.ScopeName
                case 'None'
                    throw(MException('OptovarFetchError', 'ScopeStartup did not handle optovar'));
                case 'Demo'
                    Mag = 1;
            end
        end
        
        %% Image Properties
        
        function w=get.Width(Scp)
            % Get image width
            w=Scp.mmc.getImageWidth;
        end
        
        function h=get.Height(Scp)
            % Get image height
            h=Scp.mmc.getImageWidth;
        end
        
        function bd=get.BitDepth(Scp)
            % Get image bit depth
            bd=Scp.mmc.getImageBitDepth;
        end
        
        function PixelSize = get.PixelSize(Scp)
            % Get image pixel size (in um)
            
            % Run overloadable function to get pixel size.
            PixelSize = Scp.getPixelSize;
        end
        
        function PixelSize = getPixelSize(Scp)
            % Overloadable method to get the pixel size
            
            PixelSize = Scp.mmc.getPixelSizeUm;
        end
        
        %% Position Properties
        
        function set.Pos(Scp,Pos)
            % Set the Scope's Position class pointer
            
            % make sure Pos is of the right type;
            assert(isa(Pos,'Positions'));
            Scp.Pos = Pos;
        end
        
        function Z = get.Z(Scp)
            % Get current Z posotion
            
            Z=Scp.mmc.getPosition(Scp.mmc.getFocusDevice);
        end
        
        function set.Z(Scp,Z)
            % Set the Z position
            
            % Run the overloadable method to set the Z position
            Scp.setZ(Z);
        end
        
        function setZ(Scp,Z)
            % Overloadable method to set the Z position
            
            try
                Scp.mmc.setPosition(Scp.mmc.getFocusDevice,Z)
                Scp.mmc.waitForDevice(Scp.mmc.getProperty('Core','Focus'));
            catch e
                warning('failed to move Z with error: %s',e.message);
            end
            
        end
        
        function X = get.X(Scp)
            % Get the current X position
            
            X=Scp.mmc.getXPosition(Scp.mmc.getXYStageDevice);
        end
        
        function set.X(Scp,X)
            % Set the X position
            
            % Run the overloadable method to set the X position.
            Scp.setX(X);
        end
        
        function setX(Scp,X)
            % Overloadable method to set the X position
            
            Scp.mmc.setXYPosition(Scp.mmc.getXYStageDevice,X,Scp.Y)
            Scp.mmc.waitForDevice(Scp.mmc.getProperty('Core','XYStage'));
        end
        
        function Y = get.Y(Scp)
            % Get the current Y position
            
            Y=Scp.mmc.getYPosition(Scp.mmc.getXYStageDevice);
        end
        
        function set.Y(Scp,Y)
            % Set the Y position
            
            % Run the overloadable method to set the Y position.
            Scp.setY(Y);
        end
        
        function setY(Scp,Y)
            % Overloadable method to set the Y position
            
            Scp.mmc.setXYPosition(Scp.mmc.getXYStageDevice,Scp.X,Y)
            Scp.mmc.waitForDevice(Scp.mmc.getProperty('Core','XYStage'));
        end
        
        function XY = get.XY(Scp)
            % Get both X and Y position as a single vector
            
            % Run the overloadable method to get XY
            XY = Scp.getXY;
        end
        
        function XY = getXY(Scp)
            % Overloadable funtion to get the current XY as a single vect.
            
            XY(1)=Scp.mmc.getXPosition(Scp.mmc.getXYStageDevice);
            XY(2)=Scp.mmc.getYPosition(Scp.mmc.getXYStageDevice);
            XY = round(XY); % round to the closest micron...
        end
        
        function set.XY(Scp,XY)
            % Simultaneously set X and Y
            
            % Run the overloadable method to set XY
            Scp.setXY(XY);
        end
        
        function setXY(Scp,XY)
            % Overloadable method to set XY
            
            currXY = Scp.XY;
            dist = sqrt(sum((currXY-XY).^2));
            if Scp.XYpercision >0 && dist < Scp.XYpercision
                if Scp.verbose==1 
                    fprintf('movment too small - skipping XY movement\n');
                end
                return
            end
            
            Scp.mmc.setXYPosition(Scp.mmc.getXYStageDevice,XY(1),XY(2))
            Scp.mmc.waitForDevice(Scp.mmc.getProperty('Core','XYStage'));
        end
        
        
        %% Chamber Properties
        
        function set.Chamber(Scp,ChamberType)
            % Set the current chamber type
            
            if ~isa(ChamberType,'Plate')
                error('Chamber must be of type Plate!')
            end
            Scp.Chamber = ChamberType;
        end
        
        %% Environmental Properties
        
        function Tout=get.Temperature(Scp)
            % Get the temperature
            
            [Tout,~]=getTempAndHumidity(Scp);
        end
        
        function Hout=get.Humidity(Scp)
            % Get the humidity
            
            [~,Hout]=getTempAndHumidity(Scp);
        end
        
        function [Tout,Hout]=getTempAndHumidity(Scp) %#ok<MANU>
            % Overloadable method to get the temperature and humidity
            
            Tout=[];
            Hout =[];
        end
        
        %% Flat-field Properties
        
        function FlatFieldConfig = get.CurrentFlatFieldConfig(Scp)
            FlatFieldConfig = char(Scp.mmc.getCurrentConfig('FlatField'));
        end
        
        %% Display Properties
        
        function clr = get.Clr(Scp)
            % Get the current color for the channel that is set
            try
                clr = Scp.ClrArray.(Scp.Channel);
            catch %#ok<CTCH>
                warning('Color for %s was not defined in the ScopeStartup configuration file, returning random color',Scp.Channel);
                clr = rand(1,3);
            end
        end

        %% Timestamp Properties
        
        function set.TimeStamp(Scp,what)
            if strcmp(what,'reset')
                Scp.TimeStamp = {'init',now};
                return
            end
            
            % this will replace the last entry
            % ix = find(ismember(Scp.TimeStamp(:,1),what), 1);
            ix=[];
            if isempty(ix)
                Scp.TimeStamp(end+1,:)= {what,now};
            else
                Scp.TimeStamp(ix,:) = {what,now};
            end
        end
        
        function when = getTimeStamp(Scp,what)
            ix = ismember(Scp.TimeStamp(:,1),what);
            if ~any(ix)
                when=nan;
                return
            end
            when = cat(1,Scp.TimeStamp{ix,2});
            when=when-Scp.TimeStamp{1,2};
            when=when*24*60*60;
        end
        
        %% Display cmd line text properties
        
        function set.verbose(Scp,verbIn)
            % Set the verbose property and update other classes verbose
            % property
            
            % Check that the input is either a 0 or 1;
            if verbIn==0 || verbIn == 1
                % Update other classes
                setVerbose(Scp,verbIn)

                % Set parameter for scope
                Scp.verbose = verbIn;
            else
                error('verbose property must either be a 0 or 1');
            end
        end
        
        function setVerbose(Scp,verbIn)
            % Overloadable method to make any necessary changes to other
            % classes if verbose is changed
            
            % Update Scheduler class verbose setting
            Scp.Sched.verbose = verbIn;
        end
        
        function set.debugging(Scp,debugIn)
            % Set the debugging property and update other classes debugging
            % property
            
            % Check that the input is either a 0 or 1;
            if debugIn==0 || debugIn == 1
                % Update other classes
                setDebugging(Scp,debugIn)

                % Set parameter for scope
                Scp.debugging = debugIn;
            else
                error('debugging property must either be a 0 or 1');
            end
            
        end
        
        function setDebugging(Scp,debugIn)
            % Overloadable method to make any necessary changes to other
            % classes if debugging is changed
            
            % Update Scheduler class debugging setting
            Scp.Sched.debugging = debugIn;
        end
        
        %% Accessory Methods
        
        
        function unloadAll(Scp)
            Scp.mmc.unloadAllDevices;
            Scp.mmc=[];
            Scp.studio=[];
        end


        
        %% register by previous image
        function dXY = findRegistrationXYshift(Scp,varargin)
            %% input arguments
            arg.channel = 'Yellow';
            arg.position = '';
            arg.exposure = [];
            arg.fig = 123;
            arg.help = true;
            arg.pth = '';
            arg.auto = false;
            arg.verify = true;
            arg = parseVarargin(varargin,arg);
            
            if isempty(arg.pth)
                error('Please provide the path to the previous dataset!!!')
            end
            if isempty(arg.position)
                error('Please provide the position you want to register')
            end
            if isempty(Scp.Pos)
                error('Please run createPosition before trying to register')
            end
            PrevMD = Metadata(arg.pth);
            LastImage = stkread(PrevMD,'Channel',arg.channel,'Position',arg.position,'specific','last');
            
            Scp.Channel = arg.channel;
            if ~isempty(arg.exposure)
                Scp.Exposure = arg.exposure;
            end
            
            if arg.auto
                % try using cross-correlation.
                img = Scp.snapImage;
                cc=normxcorr2(img,LastImage);
                [~, imax] = max(abs(cc(:)));
                imax=gather(imax);
                [ypeak, xpeak] = ind2sub(size(cc),imax(1));
                sz=size(img1);
                dy_pixel=ypeak-sz(1);
                dx_pixel=xpeak-sz(2);
                
            else % manually click on spots (cells or highlighter, whatever is easier...)
                success = 'No';
                Scp.goto(arg.position)
                while ~strcmp(success,'Yes')
                    
                    img = Scp.snapImage;
                    
                    figure(arg.fig)
                    imshowpair(imadjust(img),imadjust(LastImage));
                    
                    if arg.help
                        disp('Click purple to green')
                        %                     uiwait(msgbox('click purple to green'))
                    end
                    
                    [x,y] = ginput(2);
                    dx_pixel = diff(x);
                    dy_pixel = diff(y);
                    
                    %                 success = questdlg('Success?');
                    success = input('Do you want to move on (m) try again (t) or  abort (a)? (m/t/a)','s');
                    assert(any(ismember('mta',success)),'Look what you are clicking you moron!')
                    
                    if strcmp(success,'a')
                        return;
                    end
                    
                    if strcmp(success,'t')
                        input('Move stage a bit and try again','s');
                    end
                    if strcmp(success,'m')
                        break % get out of the infinite while loop
                    end
                    disp('Still in While-loop')
                    
                end
                disp('Out of while-loop')
            end
            dX_micron = dx_pixel*Scp.PixelSize;
            dY_micron = dy_pixel*Scp.PixelSize;
            
            if arg.verify
                XYold=Scp.XY;
                XYnew =XYold+[dX_micron dY_micron];
                Scp.XY=XYnew;
                img = Scp.snapImage;
                figure(arg.fig)
                imshowpair(imadjust(img),imadjust(LastImage));
                success = input('Do you approve? (y / n)');
                if ~strcmp(success,'y')
                    return
                end
            end
            
            dXY=[dXmicron dY_micron];
            Scp.dXY=dXY;
            
        end
        
        function plotTimeStamps(Scp)
            %%
            figure,
            Tall = Scp.TimeStamp(:,2);
            Tall = cat(1,Tall{:});
            Tall = Tall-Tall(1);
            Tall=Tall*24*3600;
            stem(diff(Tall)), set(gca,'xtick',1:numel(Tall),'xticklabel',Scp.TimeStamp(2:end,1))
        end
        
        
        
        function img = getLastImage(Scp)
            img = Scp.mmc.getLastImage;
            img = mat2gray(img,[0 2^Scp.BitDepth]);
            img = reshape(img,[Scp.Width Scp.Height]);
        end

        
        
        function plotAFcurve(Scp,fig)
            if ~strcmp(Scp.AutoFocusType,'software')
                warning('Can only plot AF curve in software mode')
                return
            end
            if nargin==1
                fig=figure;
            end
            
            Z0=Scp.Z;
            Zv=Scp.AFgrid;
            S=Scp.AFscr;
            f=@(p,x) exp(-(x-p(1)).^2./2/p(2).^2);
            p0=[Z0 1.5];
            opt=optimset('Display','off');
            p=lsqcurvefit(f,p0,Zv,mat2gray(S),[min(Zv) 0.5],[max(Zv) 2.5],opt);
            
            
            figure(fig)
            clf
            Zfine=linspace(min(Zv),max(Zv),100);
            
            plot(Scp.AFgrid,mat2gray(S),'.',Zfine,mat2gray(f(p,Zfine)));
            hold on
            plot([p(1) p(1)],[0 1]);
            plot([Z0 Z0],[0 1],'r--');
            
            
        end
        

        %% Depreciated methods
        
        
        function showStack(Scp) %#ok<MANU>
            error('not supported')
            % an alternative apporach will be to create a stack and add an
            % image to it, than set the slice to 1 and delete it
            % MIJ.run("Concatenate...", "  title=A image1=A image2=frame image3=[-- None --]");
            % MIJ.setSlice(1);
            % MIJ.run('Delete Slice')
            % this will always keep N image in memory.
            if isempty(Scp.Stk.ijp) %#ok<UNRCH>
                Scp.Stk.ijp = stkshow(Scp.Stk.data);
            else
                Scp.Stk.ijp.close;
                Scp.Stk.ijp = stkshow(Scp.Stk.data);
            end
        end
        
                %% add additional information to the different wells / sites in the current chamber.
        function setChamberProperties(Scp,ChamberType,prop,value)
            %% get chamber by type
            found=false;
            for i=1:numel(Scp.PossibleChambers)
                if strcmp(Scp.PossibleChambers(i).type,ChamberType)
                    found=true;
                    break
                end
            end
            if ~found
                error('Didn''t find chamber of type %s',ChamberType);
            end
            Scp.PossibleChambers(i).(prop)=value;
        end
        
        function initTic(Scp)
            Scp.Tic=now;
        end
        
        function waitTillToc(Scp,t)
            while (now-Scp.Tic)*24*60*60<t
                pause(0.01)
            end
        end
        
        %         function writeAcquisitionComments(Scp,UserName,ProjectName,DatasetName,ExpID,varargin)
        %             pth = Scp.getPath(UserName,ProjectName,DatasetName);
        %             fid = fopen(fullfile(pth,'Scope_display_and_comments.txt'),'w');
        %             DispAndComments.Channels=[]; %TODO - try to get setting from MM
        %             DispAndComments.Comments.Summary=sprintf('ExperimentID = %g',ExpID);
        %             str = savejson('',DispAndComments);
        %             fprintf(fid,str);
        %             fclose(fid);
        %         end
        
%         function reportToGoogle(Scp,email,varargin)
%             arg.functorun=[];
%             arg.spreadsheetID='1CRhX6wr9_D-ct8zDXamEUR_Tn8CtqAJD7fXxrg_2jsE';
%             arg.sheetID = '0';
%             arg.status = 'Running';
%             switch Scp.ScopeName
%                 case 'Ninja'
%                     sheetpos=[2 2];
%                 case 'Hype'
%                     sheetpos=[5 2];
%             end
%             arg = parseVarargin(varargin,arg);
%             
%             % run func if one was provided
%             if isa(arg.functorun,'function_handle');
%                 arg.functorun();
%             end
%             
%             runok = mat2sheets(arg.spreadsheetID, arg.sheetID, sheetpos, {arg.status,datestr(now),email});
%             if ~runok
%                 warning('Reporting to google spreadsheet didn''t work')
%             end
%         end
        
%         function zEvent(Scp,cellIn)
%             
%             %% have not implemented
%             fprintf('In z event \n');
%             %             notify(Scp,'Zcallback');
%             %             Scp.Sched.nextInLine;
%         end
        
        %         function Texpose = lightExposure(Scp,ExcitationPosition,Time,varargin)
%             arg.units = 'seconds';
%             arg.dichroic = '425LP';
%             arg.shutter = 'ExcitationShutter';
%             arg.cameraport = false;
%             arg.stagespeed = [];
%             arg.mirrorpos = 'mirror';%added by naomi 1/27/17
%             arg.move=[]; % array of nx2 of position to move between in circular fashion. relative to current position in um
%             arg.movetimes = [];
%             arg = parseVarargin(varargin,arg);
%             % switch time to seconds
%             switch arg.units
%                 case {'msec','millisec','milliseconds'}
%                     Time=Time/1000;
%                 case {'sec','Seconds','Sec','seconds'}
%                     Time=Time*1;
%                 case {'minutes','Minutes','min','Min'}
%                     Time=Time*60;
%                 case {'Hours','hours'}
%                     Time=Time*3600;
%             end
%             % timestamp
%             Scp.TimeStamp='start_lightexposure';
%             
%             
%             % decide based on ExcitationPosition which Shutter and Wheel to
%             % use, two options are ExcitationWheel, LEDarray
%             % get list of labels for ExcitationList
%             lst = Scp.mmc.getStateLabels('ExcitationWheel');
%             str = lst.toArray;
%             PossExcitationWheelPos = cell(numel(str),1);
%             for i=1:numel(str)
%                 PossExcitationWheelPos{i}=char(str(i));
%             end
%             lst = Scp.mmc.getStateLabels('Arduino-Switch');
%             str = lst.toArray;
%             PossArduinoSwitchPos = cell(numel(str),1);
%             for i=1:numel(str)
%                 PossArduinoSwitchPos{i}=char(str(i));
%             end
%             if ismember(ExcitationPosition,PossExcitationWheelPos)
%                 shutter = 'ExcitationShutter';
%                 wheel = 'ExcitationWheel';
%             elseif ismember(ExcitationPosition,PossArduinoSwitchPos)
%                 shutter = '405LED';
%                 wheel = 'Arduino-Switch';
%             else
%                 error('Excitation position: %s does not exist in the system',ExcitationPosition)
%             end
%             Scp.mmc.setProperty('Core','Shutter',shutter)
%             Scp.mmc.setProperty('Dichroics','Label',arg.dichroic)
%             %added by LNH 1/27/17
%             Scp.mmc.setProperty('EmissionWheel','Label',arg.mirrorpos)
%             %
%             Scp.mmc.setProperty(wheel,'Label',ExcitationPosition)
%             if arg.cameraport
%                 Scp.mmc.setProperty(Scp.DeviceNames.LightPath{1},Scp.DeviceNames.LightPath{2},Scp.DeviceNames.LightPath{4})
%             end
%             
%             if ~isempty(arg.move)
%                 curr_xy=Scp.XY;
%                 arg.move=arg.move+repmat(curr_xy,size(arg.move,1),1);
%                 Scp.XY=arg.move(1,:);
%             end
%             
%             Scp.mmc.setShutterOpen(true);
%             Tstart=now;
%             if isempty(arg.move)
%                 pause(Time)
%             else %deal with stage movment
%                 % first adjust speed if requested
%                 
%                 if ~isempty(arg.stagespeed)
%                     currspeed(1) = str2double(Scp.mmc.getProperty(Scp.mmc.getXYStageDevice,'SpeedX'));
%                     currspeed(2) = str2double(Scp.mmc.getProperty(Scp.mmc.getXYStageDevice,'SpeedY'));
%                     Scp.mmc.setProperty(Scp.mmc.getXYStageDevice,'SpeedX',num2str(arg.stagespeed));
%                     Scp.mmc.setProperty(Scp.mmc.getXYStageDevice,'SpeedY',num2str(arg.stagespeed));
%                 end
%                 t0=now;
%                 cnt=0;
%                 % do first round no matter how time it takes.
%                 if ~isempty(arg.movetimes)
%                     for j=1:arg.movetimes
%                         for i=1:size(arg.move,1)
%                             Scp.XY=arg.move(i,:);
%                         end
%                     end
%                 else
%                     while (now-t0)*24*3600<Time % move time to sec
%                         cnt=cnt+1;
%                         continouscnt=continouscnt+1;
%                         if cnt>size(arg.move,1)
%                             cnt=1;
%                         end
%                         Scp.XY=arg.move(cnt,:);
%                         cnt %#ok<NOPRT>
%                     end
%                 end
%             end
%             Scp.mmc.setShutterOpen(false);
%             Texpose=(now-Tstart)*24*3600;
%             if arg.cameraport
%                 Scp.mmc.setProperty(Scp.DeviceNames.LightPath{1},Scp.DeviceNames.LightPath{2},Scp.DeviceNames.LightPath{3})
%             end
%             if ~isempty(arg.move)
%                 Scp.XY=curr_xy;
%                 if ~isempty(arg.stagespeed)
%                     Scp.mmc.setProperty(Scp.mmc.getXYStageDevice,'SpeedX',num2str(currspeed(1)));
%                     Scp.mmc.setProperty(Scp.mmc.getXYStageDevice,'SpeedY',num2str(currspeed(2)));
%                 end
%             end
%             Scp.mmc.setShutterOpen(false);
%             Scp.mmc.setProperty('Core','Shutter','ExcitationShutter')
%             Scp.TimeStamp='end_lightexposure';
%         end
        
%         function AcqData = optimizeChannelOrder(Scp,AcqData)
%             % TODO: optimizeChannelOrder only optimzes filter wheels - need to add dichroics etc.
%             n=length(AcqData);
%             stats=nan(n,3); % excitaion, emission, gain
%             for i=1:n
%                 cnf=Scp.mmc.getConfigData('Channel',AcqData(i).Channel);
%                 vrbs=char(cnf.getVerbose);
%                 if ~isempty(regexp(vrbs,'Excitation', 'once'))
%                     str=vrbs(strfind(vrbs,'Excitation:Label=')+17:end);
%                     str=str(1:strfind(str,'<br>')-1);
%                     stats(i,1)=Scp.mmc.getStateFromLabel('Excitation',str);
%                 end
%                 if ~isempty(regexp(char(vrbs),'Emission', 'once'))
%                     str=vrbs(strfind(vrbs,'Emission:Label=')+15:end);
%                     str=str(1:strfind(str,'<br>')-1);
%                     stats(i,2)=Scp.mmc.getStateFromLabel('Emission',str);
%                 end
%                 stats(i,3)=AcqData(i).Gain;
%             end
%             
%             possorders=perms(1:n);
%             cst=zeros(factorial(n),1);
%             for i=1:size(possorders,1)
%                 chngs=abs(diff(stats(possorders(i,:),:)));
%                 chngs(isnan(chngs))=0;
%                 chngs(chngs(:,3)>0,3)=1;
%                 cst(i)=sum(chngs(:));
%             end
%             [~,mi]=min(cst);
%             AcqData = AcqData(possorders(mi,:));
%         end
        
%         function liveUpdateEvent(Scp,cellIn)
%             % Update live update calculations and plots at the end of
%             % acquiring all positions.
%             
%             fprintf('In Live update event \n');
%             t = Scp.Tpnts.current; % Current time index
%             
%             if t> 0
%                 % Do liveupdate calculations
%                 if Scp.LiveUpdates == 1
%                     
%                     nPos = Scp.Pos.N; % Number of positions
%                     plotCounter = 0;
%                     for m = 1:nPos
%                         % Add cell label
%                         ManualLbl = Scp.currLbl(m).ManualLbl;
%                         if size(ManualLbl,1) == Scp.Width && size(ManualLbl,2) == Scp.Height
%                             % Check that the label is actually of the right
%                             % dimentsions then add
%                             Scp.currLbl(m).addLbl(ManualLbl,'base',Scp.ROItpnts{m}(t,1))
%                         end
%                         
%                         if ~isempty(Scp.ROIprop)
%                             
%                             nProps = length(Scp.ROIprop(:,1));
%                             
%                             
%                             for k = 1:nProps
%                                 calcFn = Scp.ROIprop{k,1};
%                                 plotSep = Scp.ROIprop{k,3};
%                                 calcName = Scp.ROIprop{k,2};
%                                 
%                                 values = feval(calcFn,Scp.ROIvals{m},Scp.ROIbkgrVals{m},t);
%                                 Scp.ROIcalcs{k,m}(t,:)=values;
%                                 if Scp.ROIprop{k,4} == 1
%                                     % Normalize to first position's initial time
%                                     Scp.ROInormT{k,m}(t,1) = (Scp.ROItpnts{m}(t,1) - Scp.ROItpnts{1}(1,1))*24*60*60;
%                                 else
%                                     % Normalize to own position's initial time
%                                     Scp.ROInormT{k,m}(t,1) = (Scp.ROItpnts{m}(t,1) - Scp.ROItpnts{m}(1,1))*24*60*60;
%                                 end
%                                 
%                                 if t == 1
%                                     % On the first timepoint initialize the
%                                     % plots and figures
%                                     
%                                     % Plot the masks
%                                     if k == 1
%                                         Scp.LUfigH(m) = figure;
%                                         %                                         ROImask = Scp.MD.LiveROIdata{m,6};
%                                         plotH = imagesc(ManualLbl);
%                                         ax = gca;
%                                         colorbar(ax,'Ticks',0:max(max(ManualLbl)));
%                                         plotCounter = plotCounter + 1;
%                                         Scp.LUplotH{plotCounter} = plotH;
%                                     end
%                                     % Number of ROI for this calc and pos.
%                                     nValues = length(Scp.ROIcalcs{k,m}(1,:));
%                                     if plotSep == 1
%                                         Scp.LUfigH(k+nPos) = figure;
%                                         title([calcName,' - ',Scp.Pos.Labels{m}]);
%                                         xlabel('Time (s.)')
%                                         % make legend names
%                                         leader = repmat('ROI ',nValues,1);
%                                         nums = num2str([1:nValues]');
%                                         legNames = [leader,nums];
%                                     else
%                                         if m == 1
%                                             Scp.LUfigH(k+nPos) = figure;
%                                             title(calcName);
%                                             xlabel('Time (s.)')
%                                         else
%                                             figure(Scp.LUfigH(k+nPos))
%                                         end
%                                         % make legend names
%                                         leader = repmat([Scp.Pos.Labels{m},' - ROI '],nValues,1);
%                                         nums = num2str([1:nValues]');
%                                         legNames = [leader,nums];
%                                     end
%                                     % Convert legend char array to cell array
%                                     legNames = cellstr(legNames);
%                                     
%                                     plotCounter = plotCounter + 1;
%                                     hold on;
%                                     plotH = plot(Scp.ROInormT{k,m},Scp.ROIcalcs{k,m},...
%                                         'LineStyle',Scp.LUplot_LineStyle,...
%                                         'LineWidth',Scp.LUplot_LineWidth,...
%                                         'Marker', Scp.LUplot_Marker,...
%                                         'MarkerSize',Scp.LUplot_MarkerSize);
%                                     
%                                     % Set display names
%                                     set(plotH,{'DisplayName'},legNames);
%                                     
%                                     % Create legend
%                                     if plotSep == 1
%                                         hold off;
%                                         legend('show','Location','eastoutside');
%                                     else
%                                         % wait till all plotted to add legend
%                                         if m == nPos
%                                             hold off;
%                                             legend('show','Location','eastoutside');
%                                         end
%                                     end
%                                     
%                                     
%                                     % Set datasource to update plot with.
%                                     for n = 1:length(plotH)
%                                         plotH(n).XDataSource = ['Scp.ROInormT{',num2str(k),',',num2str(m),'}'];
%                                         plotH(n).YDataSource = ['Scp.ROIcalcs{',num2str(k),',',num2str(m),'}(:,',num2str(n),')'];
%                                     end
%                                     
%                                     % Store plot handles
%                                     Scp.LUplotH{plotCounter} = plotH;
%                                     numTracePlots = length(Scp.LUtracePlotInds);
%                                     Scp.LUtracePlotInds(numTracePlots +1) = plotCounter;
%                                     %                             else
%                                     %                                 plotCounter = plotCounter + 1;
%                                     %                                 refreshdata(Scp.LUplotH(plotCounter + m));
%                                 end
%                             end
%                         end
%                         
%                         
%                     end
%                     
%                     % Update the plots
%                     for n = 1:length(Scp.LUtracePlotInds)
%                         refreshdata(Scp.LUplotH(Scp.LUtracePlotInds(n)));
%                     end
%                 end
%             end
%             
%             notify(Scp,'LUcallback');
%         end
%         
%         function acqOne(Scp,AcqData,acqname,varargin)
%             % acqOne - get a single image from each channel and position so
%             % that ROI can be specified for a given position to be able to
%             % get live updates of intensities or image ratios.
%             
%             Scp.Pos.init;
%             Scp.SkipCounter=Scp.SkipCounter+1;
%             
%             % Reset Scp ROI parameters
%             Scp.ROIprop = {};
%             Scp.ROIvals = {};
%             Scp.ROIvalsName = {};
%             Scp.ROIbkgrVals = {};
%             Scp.ROIcalcs = {};
%             Scp.ROItpnts = {};
%             Scp.ROInormT = {};
%             
%             
%             %% Multi-position loop
%             for j=1:Scp.Pos.N
%                 
%                 %% get Skip value
%                 skp = Scp.Pos.getSkipForNextPosition;
%                 if Scp.SkipCounter>1 && mod(Scp.SkipCounter,skp) % if we get a value different than 0 it means that this could be skipped
%                     fprintf('Skipping position %s, counter at %g\n',Scp.Pos.next,Scp.SkipCounter); % still advance the position list
%                     continue %skip the goto and func calls
%                 end
%                 
%                 %% add goto position to queue
%                 Scp.goto(Scp.Pos.next,Scp.Pos);
%                 PosName = Scp.Pos.peek;
%                 acqnameIn = acqname;
%                 %% perfrom action
%                 getImgStack = Scp.acqOneFrame(AcqData,acqname,varargin);
%                 % Scale Image stack
%                 getImgStack = uint16(getImgStack*2^16);
%                 channelNames = {AcqData(:).Channel};
%                 
%                 % Set the channel vals name
%                 Scp.ROIvalsName =channelNames;
%                 
%                 allImgStacks{j} = {PosName,acqnameIn,channelNames,getImgStack,[],[]}; % empty slots are for for the ROI data, and then the ROI masks
%                 
%             end
%             
%             % use acqROIgui to specify the ROI for each position
%             AcqROIguiHandle = AcqROIgui(Scp,allImgStacks);
%             uiwait(AcqROIguiHandle);
%             
%         end
%         
%         function imgStack = acqOneFrame(Scp,AcqData,acqname,varargin)
%             % acqOneFrame - acquire a single frame in currnet position
%             % but don't save. This is to be able to create ROI
%             
%             if ~isempty(Scp.Pos)
%                 arg.p = Scp.Pos.current;
%             else
%                 arg.p = 1;
%             end
%             arg.z=[];
%             arg = parseVarargin(varargin,arg);
%             
%             %             t = arg.t;
%             p = arg.p;
%             
%             % autofocus function depends on scope settings
%             Scp.TimeStamp = 'before_focus';
%             Scp.autofocus;
%             Scp.TimeStamp = 'after_focus';
%             
%             %% Make sure I'm using the right MD
%             Scp.MD = acqname; % if the Acq wasn't initizlied properly it should throw an error
%             
%             % set baseZ to allow dZ between channels
%             baseZ=Scp.Z;
%             
%             % get XY to save in metadata
%             XY = Scp.XY;
%             Z=Scp.Z;
%             
%             n = numel(AcqData);
%             %             ix=zeros(n,1);
%             %             T=zeros(n,1);
%             skipped=false(n,1);
%             %% check that acquisition is not paused
%             while Scp.Pause
%                 pause(0.1) %TODO - check that this is working properly with the GUI botton
%                 fprintf('pause\n')
%             end
%             for i=1:n
%                 
%                 % Never skip on the first frame...
%                 if  Scp.FrameCount(p) >1 && mod(Scp.FrameCount(p),AcqData(i).Skip)
%                     skipped(i)=true;
%                     continue
%                 end
%                 
%                 %% update Scope state
%                 Scp.updateState(AcqData(i)); % set scopre using all fields of AcqData including channel, dZ, exposure etc.
%                 Scp.TimeStamp='updateState';
%                 
%                 %% Snap image
%                 % or showing images one by one.
%                 img = Scp.snapImage;
%                 Scp.TimeStamp='image';
%                 imgStack(:,:,i) = img;
%                 
%             end
%             
%         end
%         
%         function addLiveCalc(Scp,calcString,calcName,fieldVarName, varargin)
%             % addLiveCalc  Add a calculation for real-time tracking
%             %   This method takes in a string made with specified regular
%             %   expressions to specify calculations that can be performed.
%             %
%             %   Details on the specified regular expressions
%             %       Ch[0-9]: mean intensity of cells in a given the channel
%             %                   number as defined in AcqData
%             %       Bkgr[0-9]: background of the channel number
%             %
%             %   MAKE SURE YOU USE SCALAR ARITHMATIC IN STRING (./ .*)
%             
%             arg.plotpossep = 0; % Plot positions on seperate graphs
%             arg.plotcalc = 1; % flag to plot the new calculation
%             arg.normtglobal = 1; % normalize the start time to just the first position timepoint
%             %      If false, normalized time w.r.t. that
%             %      positions first acquisition time.
%             arg = parseVarargin(varargin,arg);
%             
%             % Check that the fieldVarName is a valid variable name
%             if ~isvarname(fieldVarName)
%                 error('fieldVarName does not conform to MATLAB variable name requirements. Please choose a different reference name');
%             end
%             
%             % Check that the fieldVarName hasn't already been used
%             % Number of props already defined
%             nProp=size(Scp.ROIprop,1);
%             %
%             if nProp>0
%                 if any(strcmp(fieldVarName,Scp.ROIprop(:,3)))
%                     error('fieldVarName conflicts with names of calculations already set. Please choose a different reference name');
%                 end
%             end
%             
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
%             replace = 'BkgrValsIn(m,1,$1)';
%             
%             newStr = regexprep(newStr,expr,replace);
%             
%             % Convert string into function.
%             fnStr = ['@(ROIvalsIn,BkgrValsIn,m)',newStr];
%             fnHandle = str2func(fnStr);
%             
%             
%             Scp.ROIprop(nProp+1,1:5) = {fnHandle,calcName,arg.plotpossep,arg.normtglobal,fieldVarName};
%             
%         end
        
        %%%%%%%%
        
    end
end
