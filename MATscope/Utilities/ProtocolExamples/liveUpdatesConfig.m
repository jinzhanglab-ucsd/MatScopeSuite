%% Set up: username, metadata, position, and AcqData
%userdata
Scp.Username = 'egreenwald'; % your username!
Scp.Project = 'ScopeTest'; % the project this dataset correspond to
Scp.Dataset = 'TestPosition43';  % the name of this specific image dataset - i.e. this experiment.
 
%% metadata
% [ExperimentConfig,Desc] = GUIgetMetadata;
% Scp.ExperimentDescription = 'test ATP analogs for Ca2+ activation';
% Scp.reduceAllOverheadForSpeed=true;
%% Aquisition Data
AcqData = AcquisitionData;
 
AcqData(1).Channel='GFP';
AcqData(1).Exposure=10;
AcqData(1).Fluorophore='GreenFP';
AcqData(1).Marker = 'Ca';

AcqData(2).Channel='CY5';
AcqData(2).Exposure=20;

Scp.Chamber = Plate('Microfluidics Wounding Device Ver 3.0');
Scp.Chamber.x0y0 = Scp.XY;
Scp.Chamber.directionXY = [-1 1];
Scp.createPositionFromMM('guessWells',1);


%% imaging
%initial image
Scp.Tpnts = Timepoints;
Scp.Tpnts = createEqualSpacingTimelapse(Scp.Tpnts,3,15); %N,dT
initOut = Scp.initAcq(AcqData,'liveupdates',1);
Scp.acqOne(AcqData,initOut);

Scp.addLiveCalc('(Ch1-Bkgr1)./(Ch2-Bkgr2)','FRET Ratio','plotpossep',1);
Scp.addLiveCalc('Ch1-Bkgr1','Bkgr subtracted GFP','normtglobal',0);
queueGUI(Scp)
% Scp.acquireQueue(AcqData,'acqname',initOut);
% Scp.acquire(AcqData);
% pause(5)
% Scp.Tpnts = Timepoints;
% Scp.Tpnts = createEqualSpacingTimelapse(Scp.Tpnts,100,3);
% Scp.initAcq(AcqData);
% Scp.acquire(AcqData);