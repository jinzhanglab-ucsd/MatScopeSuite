%% Set up: username, metadata, position, and AcqData
%userdata
Scp.Username = 'egreenwald'; % your username!
Scp.Project = 'ScopeTest'; % the project this dataset correspond to
Scp.Dataset = 'testingPlate';  % the name of this specific image dataset - i.e. this experiment.
 
%% metadata
% [ExperimentConfig,Desc] = GUIgetMetadata;
% Scp.ExperimentDescription = 'test ATP analogs for Ca2+ activation';
% Scp.reduceAllOverheadForSpeed=true;
%% Aquisition Data
AcqData = AcquisitionData;
 
AcqData(1).Channel='Rhodamine';
AcqData(1).Exposure=300;
AcqData(1).Fluorophore='mCherry';
AcqData(1).Marker = 'Ca';
 
AcqData(2).Channel='DAPI';
AcqData(2).Exposure=200;
AcqData(2).Fluorophore='Hoescht';
AcqData(2).Marker = 'DNA';

AcqData(3).Channel='Cy5';
AcqData(3).Exposure=200;
AcqData(3).Fluorophore='Smurfp';
AcqData(3).Marker = 'actin';

%% Set chambers
Scp.Chamber = Plate('Costar24 (3526)');
Scp.Chamber.x0y0 = [50055      -29678];
% Scp.Chamber.x0y0 = [50055      -29678];
Scp.Chamber.directionXY = [-1 1];

%% positions
c=3;%do one column at a time
r=[2 3 4];
%% positions
msk = false(8,12);
msk(r,c)=1;
% Scp.createPositions([],'sitesperwell',[2,2],'msk',msk,'experimentdata',ExperimentConfig,'optimize',true);
Scp.createPositions([],'msk',msk,'experimentdata',ExperimentConfig,'optimize',true);

%% Start Scheduler
Sched = Scheduler;
Scp.Sched = Sched;

%% imaging
%initial image
Scp.Tpnts = Timepoints;
Scp.Tpnts = createEqualSpacingTimelapse(Scp.Tpnts,2,5); %N,dT
initOut = Scp.initAcq(AcqData);
queueGUI(Scp,AcqData,initOut)
% Scp.acquireQueue(AcqData,'acqname',initOut);
% Scp.acquire(AcqData);
% pause(5)
% Scp.Tpnts = Timepoints;
% Scp.Tpnts = createEqualSpacingTimelapse(Scp.Tpnts,100,3);
% Scp.initAcq(AcqData);
% Scp.acquire(AcqData);