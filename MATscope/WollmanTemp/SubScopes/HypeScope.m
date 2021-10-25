classdef HypeScope < WollmanScopes
    % Subclass of Scope that makes certain behavior specific to the
    % zeiss scope.
    
    properties
        
    end
    
    
    
    methods
        %% Image properties
        function updateState(Scp,AcqData)
            
            %% set AcqData to the one that is being used
            assert(isa(AcqData, 'AcquisitionData'), 'AcqData is not of AcquisitionData class');
            
            Scp.AcqData = AcqData;
            
            %% change the scope state to be what is required by AcqData
            % change channel (only if needed othwise it will time out)
            if ~strcmp(Scp.Channel,AcqData.Channel)
                Scp.Channel=AcqData.Channel;
            end
            
            %% exposure
            %             Scp.mmc.setProperty('ZeissAxioCam', 'Exposure', 30);
            Scp.Exposure = AcqData.Exposure;
            
            %% dZ option between channels
            if ~isempty(AcqData.dZ) && AcqData.dZ~=0
                fprintf('dZ\n');
                Scp.Z=Scp.Z+AcqData.dZ;
            end
            
        end
        
        function [img] = snapImage(Scp)
            %             Scp.mmc.setCameraDevice('ZeissAxioCam');
            %             Scp.mmc.setProperty('Zyla42', 'TriggerMode', 'External');
            %             Scp.mmc.getProperty('ZeissAxioCam', 'Exposure');
            %             Scp.mmc.getProperty('Zyla42', 'Exposure');
            %             mrm_image = Scp.mmc.getImage;
            %             mrm_value = abs(mean(mrm_image) - 31);
            %             mrm_value
            Scp.mmc.setCameraDevice('Zyla42');
            
            %             Scp.mmc.snapImage;
            imgArray = Scp.LiveWindow.snap(1);
            arrayIterator = imgArray.listIterator;
            MMimg = arrayIterator.next;
            img = MMimg.getRawPixels;
            img = mat2gray(img,[0 2^Scp.BitDepth]);
            img = reshape(img,[Scp.Width Scp.Height]); % don't transpose here
            if Scp.CorrectFlatField
                img = Scp.doFlatFieldCorrection(img);
            end
            %             if ismember(Scp.acqshow,{'single','channel'})
            %                 Scp.mmc.setCameraDevice('Zyla42');
            %                 img2 = uint16(img*2^Scp.BitDepth);
            %                 Scp.gui.displayImage(img2(:));
            % %                 Scp.mmc.setCameraDevice('ZeissAxioCam');
            % %                 disp('hi')
            %             end
            if strcmp(Scp.Channel,Scp.Stk.Channel)
                if isempty(Scp.Channel)
                    warndlg('Please choose a channel!!!')
                    error('Please choose a channel');
                end
                Scp.Stk.data(:,:,Scp.Tpnts.current) = imresize(img,Scp.Stk.resize);
            end
            %             Scp.mmc.setCameraDevice('ZeissAxioCam');
        end
        
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
            arg.channelfirst = true; % used for Z stack
            arg = parseVarargin(varargin,arg);
            
            %% Flush the Zyla42 image buffer
            Scp.mmc.setCameraDevice('Zyla42');
            %             Scp.mmc.getImage();
            %             Scp.mmc.setCameraDevice('ZeissAxioCam');
            %% Init Acq
            if isempty(arg.acqname)
                acqname = Scp.initAcq(AcqData,arg);
            else
                acqname = arg.acqname;
            end
            
            
            %% move scope to camera port
            %             Scp.mmc.setProperty(Scp.LightPath{1},Scp.LightPath{2},Scp.LightPath{3});
            
            %% set up acq function
            if isempty(arg.func)
                if isempty(arg.dz)
                    arg.func = @() acqFrame(Scp,AcqData,acqname);
                else
                    arg.func = @() acqZstack(Scp,AcqData,acqname,arg.dz,'channelfirst',arg.channelfirst);
                end
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
            Scp.MD.saveMetadata(fullfile(Scp.pth,acqname));
            
        end
        
        function acqZstack(Scp,AcqData,acqname,dZ,varargin)
            disp('starting z stack')
            % acqZstack acquires a whole Z stack
            arg.channelfirst = true; % if True will acq multiple channels per Z movement.
            % False will acq a Z stack per color.
            arg = parseVarargin(varargin,arg);
            Scp.autofocus;
            Z0 = Scp.Z;
            AFmethod = Scp.AutoFocusType;
            
            % turn autofocus off
            Scp.AutoFocusType='none';
            
            % acquire a Z stack and do all colors each plane
            if arg.channelfirst
                for i=1:numel(dZ)
                    Scp.Z=Z0+dZ(i);
                    acqFrame(Scp,AcqData,acqname,'z',i);
                end
            else % per color acquire a Z stack
                for j=1:numel(AcqData)
                    tic;
                    Scp.AutoFocusType = AFmethod;
                    Scp.autofocus
                    disp('Autofocus time')
                    toc
                    Scp.AutoFocusType='none';
                    for i=1:numel(dZ)
                        Scp.Z=Z0+dZ(i);
                        acqFrame(Scp,AcqData(j),acqname,'z',i);
                    end
                end
            end
            
            % return to base and set AF back to it's previous state
            Scp.AutoFocusType = AFmethod;
            Scp.Z=Z0;
        end
        
        function acqFrame(Scp,AcqData,acqname,varargin)
            % acqFrame - acquire a single frame in currnet position / timepoint
            % here is also where we add / save the metadata
            
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
            arg = parseVarargin(varargin,arg);
            
            t = arg.t;
            p = arg.p;
            
            Scp.FrameCount(p)=Scp.FrameCount(p)+1;
            
            % autofocus function depends on scope settings
            Scp.TimeStamp = 'before_focus';
            Scp.autofocus
            Scp.TimeStamp = 'after_focus';
            %% Make sure I'm using the right MD
            Scp.MD = acqname; % if the Acq wasn't initizlied properly it should throw an error
            
            % set baseZ to allow dZ between channels
            baseZ=Scp.Z;
            
            % get XY to save in metadata
            XY = Scp.XY;
            Z=Scp.Z;
            
            n = numel(AcqData);
            ix=zeros(n,1);
            T=zeros(n,1);
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
                % if Z was changed, change the current Z for Metadata
                if  ~isempty(AcqData(i).dZ) && AcqData(i).dZ~=0 % only move if dZ was not empty;
                    Z=baseZ + AcqData(i).dZ;
                end
                Scp.TimeStamp='updateState';
                %% figure out image filename to be used by MM
                filename = sprintf('img_%09g_%s_000.tif',t-1,AcqData(i).Channel);
                if Scp.Pos.N>1 % add position folder
                    filename =  fullfile(sprintf('Pos%g',p-1),filename);
                end
                if ~isempty(arg.z)
                    filename = filename(1:end-4);
                    filename = sprintf('%s_%03g.tif',filename,arg.z);
                end
                
                %% Snap image
                % proceed differ whether we are using MM to show the stack
                % or showing images one by one.
                if strcmp(Scp.acqshow,'multi')
                    %%
                    Scp.gui.setChannelName(acqname,i-1,AcqData(i).Channel);
                    Scp.gui.snapAndAddImage(acqname, t-1, i-1, 0,p-1);
                    
                    %% flat field correction "hack"
                    if Scp.CorrectFlatField
                        % try to read image from hard drive
                        try
                            img = imread(fullfile(Scp.pth,acqname,filename));
                            img = mat2gray(img,[0 2^16]);
                            img = Scp.doFlatFieldCorrection(img);
                            imwrite(uint16(img*2^16),fullfile(Scp.pth,acqname,filename));
                        catch  %#ok<CTCH>
                            try
                                wrongfilename = regexprep(filename,AcqData(i).Channel,'Default');
                                img = imread(fullfile(Scp.pth,acqname,wrongfilename));
                                img = mat2gray(img,[0 2^16]);
                                img = Scp.doFlatFieldCorrection(img);
                                imwrite(uint16(img*2^16),fullfile(Scp.pth,acqname,filename));
                            catch e
                                warnning('Will not do flatfield correction for current image! - error code was %s',e.message);
                            end
                        end
                    end
                else
                    %%
                    [img] = Scp.snapImage;
                    Scp.TimeStamp='image';
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
                        imwrite(uint16(img*2^Scp.BitDepth),fullfile(Scp.pth,acqname,filename));
                    catch  %#ok<CTCH>
                        errordlg('Cannot save image to harddeive. Check out space on drive E:');
                    end
                    Scp.TimeStamp='save image';
                    if strcmp(Scp.acqshow,'channel')
                        Scp.showStack;
                    end
                end
                
                % timestamp to update Scope when last image was taken
                T(i)=now; % to save in metadata
                
                % return Z to baseline
                if ~isempty(AcqData(i).dZ) && AcqData(i).dZ~=0 % only move if dZ was not empty;
                    Scp.Z=baseZ;
                    Z=baseZ;
                end
                
                %% deal with metadata of scope parameters
                grp = Scp.Pos.peek('group',false); % the position group name, e.g. the well
                ix(i) = Scp.MD.addNewImage(filename,'Position',Scp.Pos.peek,'group',grp,'acq',acqname,'frame',t,'TimestampImage',T(i),'XY',XY,'PixelSize',Scp.PixelSize,'Z',Z,'Zindex',arg.z);
                fld = fieldnames(AcqData(i));
                for j=1:numel(fld)
                    if ~isempty(AcqData(i).(fld{j}))
                        Scp.MD.addToImages(ix(i),fld{j},AcqData(i).(fld{j}))
                    end
                end
                Scp.MD.saveMetadata(fullfile(Scp.pth,acqname));
                Scp.TimeStamp='metadata'; % to save within scope timestamps
            end
            T(skipped)=[];
            ix(skipped)=[];
            
            % add metadata - average time for frame and position based
            % experimental metadata
            Scp.MD.addToImages(ix,'TimestampFrame',mean(T));
            ExpMetadata = fieldnames(Scp.Pos.ExperimentMetadata);
            for i=1:numel(ExpMetadata)
                Scp.MD.addToImages(ix,ExpMetadata{i},Scp.Pos.ExperimentMetadata(p).(ExpMetadata{i}));
            end
            Scp.MD.saveMetadata(fullfile(Scp.pth,acqname));
            Scp.TimeStamp='endofframe';
        end
        
        %         function set.XY(Scp,XY)
        %             maxDelta = 100; %um max move
        %             currXY = Scp.XY;
        %             moveVectorXY = (currXY-XY);
        %             dist = sqrt(sum(moveVectorXY.^2));
        %             if Scp.XYpercision >0 && dist < Scp.XYpercision
        %                 fprintf('movment too small - skipping XY movement\n');
        %                 return
        %             end
        %             ratioXY = abs(moveVectorXY(1))./abs(moveVectorXY(2);
        %             newY = maxDelta./sqrt(ratioXY.^2+1);
        %             newX =
        %
        %             Scp.mmc.setXYPosition(Scp.mmc.getXYStageDevice,XY(1),XY(2))
        %             Scp.mmc.waitForDevice(Scp.mmc.getProperty('Core','XYStage'));
        %         end
        function getChannel(Scp, chnl)
            error('Not implemented')
        end
        function setChannel(Scp, chnl)
            if ~ischar(chnl),
                                        error('Channel state must be char!');
                                    end
                                    % Find out settings for VF-5, emission wheel, and dichroic
                                    [emission_wheel, vf_code, dichroic_position, settingValues, led] = channelMapping(chnl);
                                    Scp.mmc.setProperty('ZeissReflectorTurret', 'State', dichroic_position-1);
                                    %                 if led == 0
                                    %                     Scp.mmc.setProperty('Arduino-Shutter', 'OnOff', 0);
                                    %                 elseif led==1
                                    %                     Scp.Devices.vf.changeWlen([218 1 wlen2code(690)]);
                                    %                     Scp.mmc.setProperty('Arduino-Switch', 'Label', '660LED')
                                    %                     Scp.mmc.setProperty('Arduino-Shutter', 'OnOff', 1)
                                    %                 elseif led==2
                                    %                     Scp.Devices.vf.changeWlen([218 1 wlen2code(690)]);
                                    %                     Scp.mmc.setProperty('Arduino-Switch', 'Label', '730LED')
                                    %                     Scp.mmc.setProperty('Arduino-Shutter', 'OnOff', 1)
                                    %                 end
                                    
                                    %                 device_buffer_size = Scp.Devices.vf.deviceCOM.BytesAvailable
                                    %                 fread(Scp.Devices.vf.deviceCOM, device_buffer_size);
                                    Scp.Devices.vf.changeWlen(vf_code);
                                    Scp.Devices.vf.send(128+16+emission_wheel);
                                    
                                    Scp.mmc.waitForDevice('ZeissReflectorTurret');
                                    settingValues;
                                    pause(0.1)
                                    now-t0;
        end
        
        function [z,s]=autofocus(Scp,AcqData)
            %             persistent XY;
            z=nan;
            s=nan;
            
            switch lower(Scp.AutoFocusType)
                case 'hardware'
                    [move confidence mi ref] = Scp.Devices.df.checkFocus();
                    disp(['Movement (um):', num2str(-1*move), ' with ', num2str(confidence), ' confidence.']) 
                    if confidence > 3.5
                        if abs(move > 50)
                            error('Movement too large. I am afraid to break the coverslip.')
                        end
                        Scp.Z = Scp.Z + move;
                    else
                        disp('Did not have confidence in finding focus')
                    end
                    %                     Scp.mmc.sleep(1);
                case 'none'
                    disp('No autofocus used')
                    
                    
            end
            
        end
        
        
    end
    
end

