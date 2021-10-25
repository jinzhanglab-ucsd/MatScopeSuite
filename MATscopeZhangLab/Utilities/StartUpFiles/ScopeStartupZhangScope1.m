%% Init MM

cd C:\Micro-Manager-2.0beta
import mmcorej.*;
import org.micromanager.*

%% For MM version 2.0

Scp.studio = StartMMStudio;
% Scp.gui = Scp.studio.getMMStudioMainFrameInstance;
Scp.mmc = Scp.studio.getCore; 
Scp.LiveWindow = Scp.studio.live; 

%% import MM position list
import org.micromanager.navigation.*

%% Scope base path for image storage
Scp.basePath = 'D:\';

%% some propeties require knowing the name of the device

Scp.DeviceNames.Objective = 'ZeissObjectives';
Scp.DeviceNames.LightPath = {'ZeissSidePortTurret','Label','2 - Left 100%', '3 -  Left 50%-Binocular 50%',  '1 - Binocular 100%'};
Scp.ScopeName = 'ZhangZeiss';
Scp.CameraName = 'OrcaFlashV3_LT';

% Scp.DeviceNames.Objective = 'ObjectiveTurret';
% % Scp.DeviceNames.AFoffset = 'TIPFSOffset';
% Scp.DeviceNames.LightPath = {'ZeissSidePort','Label','3-100%L', '2-50%BS_50%L',  '1-100%BP'};
% Scp.ScopeName = 'ZeissAxioObserverZ1';


Scp.mmc.setProperty(Scp.DeviceNames.LightPath{1},Scp.DeviceNames.LightPath{2},Scp.DeviceNames.LightPath{3});


% Demo scope setup
Scp.mmc.setChannelGroup('Channel');
% Scp.CameraName = 'OrcaFlashV3';
Scp.mmc.setXYStageDevice('DXYStage');

%% set the system to save using Multi-image format
% To force MM to use the multi-image-per-file format:
%             T = org.micromanager.acquisition.TaggedImageStorageMultipageTiff(java.lang.String('delme'),java.lang.Boolean(true),org.json.JSONObject());
%             Scp.gui.setImageSavingFormat(T.getClass());

%% To force MM to use the single-image-per-fle format:
% try % to
%     T = org.micromanager.acquisition.TaggedImageStorageDiskDefault('delme');
%     Scp.gui.setImageSavingFormat(T.getClass());
% catch %#ok<CTCH>
%     warning('Couldn''t set single file as default')
% end






%% define default color for channels
Scp.ClrArray.Blue = [0 0 1];
Scp.ClrArray.Cyan =  [0 1 1];
Scp.ClrArray.DeepBlue = [0 0 0.5];
Scp.ClrArray.FarRed = [0.5 0 0];
Scp.ClrArray.FuraCaBound = [0.8902    0.3569    0.8471];
Scp.ClrArray.FuraCaFree = [0.8902    0.3569    0.8471];
Scp.ClrArray.Green = [0 1 0];
Scp.ClrArray.Orange =  [1.0000    0.4980    0.1412];
Scp.ClrArray.Red = [1 0 0];
Scp.ClrArray.Yellow = [0 1 1];

%% set default chamber for this microscope - 96 Costar + add properties needed for this scope
Scp.Chamber = Plate('Microfluidics Wounding Device Ver 3.0');
Scp.Chamber.x0y0 = Scp.XY;
Scp.Chamber.directionXY = [-1 1];

%% Offsets for different objectives

% Order is acccorting to the Objective Labels
% Scp.ObjectiveOffsets.Z = [   0    -19    -8 0 0 0
%     19     0  11 0 0 0
%     8     -11   0 0 0 0
%     zeros(3,6)];
% Scp.ObjectiveOffsets.AF = [  0.0  -161.8  -209.9
%     161.8    0.0   -48.1
%     209.9   48.1    0.0];

% 20x = 5033.125
% 10x = 5022.7
% 4x = 5041.325

%% Autofocus method
% Scp.AutoFocusType = 'Hardware';
Scp.AutoFocusType = 'none';
% Scp.Devices = Diaphragm;
% Scp.Devices.initialize;

%% Flatfield
% Scp.FlatFieldsFileName='D:\Scope4flatfield\FlatField.mat';
% Scp.loadFlatFields;
Scp.CorrectFlatField = false;

%% Set overhead skip to true
Scp.reduceAllOverheadForSpeed = true; % Because the Axiovert 200m is slow

%% Start ImageJ
Miji;

%% change directory to base path

cd(Scp.basePath)