function varargout = StackROIgui(varargin)
% STACKROIGUI MATLAB code for StackROIgui.fig
%      STACKROIGUI, by itself, creates a new STACKROIGUI or raises the existing
%      singleton*.
%
%      H = STACKROIGUI returns the handle to a new STACKROIGUI or the handle to
%      the existing singleton*.
%
%      STACKROIGUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in STACKROIGUI.M with the given input arguments.
%
%      STACKROIGUI('Property','Value',...) creates a new STACKROIGUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before StackROIgui_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to StackROIgui_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help StackROIgui

% Last Modified by GUIDE v2.5 21-Mar-2017 15:38:15

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @StackROIgui_OpeningFcn, ...
                   'gui_OutputFcn',  @StackROIgui_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT


% --- Executes just before StackROIgui is made visible.
function StackROIgui_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to StackROIgui (see VARARGIN)

% Choose default command line output for StackROIgui


% UIWAIT makes StackROIgui wait for user response (see UIRESUME)
% uiwait(handles.StackROIguiMainFrame);

handles.roi_Color = 'r';
handles.roi_LineStyle = '-';
handles.roi_LineWidth = 1.5;
handles.roi_Marker = '.';
handles.roi_MarkerSize = 6;
handles.roi_BkgrColor = 'g';
handles.roi_SelColor = 'b';

set(handles.imgAx,'xtick',[],'ytick',[])

    handles.chPUmenu.Visible = 'Off';
    handles.imgPosPuMenu.Visible = 'Off';
    
    handles.rectToggle.Visible = 'Off';
    handles.polyToggle.Visible = 'Off';
    handles.newROIbutton.Visible = 'Off';
    handles.bkgrROIbutton.Visible = 'Off';
    handles.delROIbutton.Visible = 'Off';
    handles.listbox1.Visible = 'Off';
    handles.exitButton.Visible = 'Off';


    handles.getStackButton.Visible = 'Off';
    handles.roiUPbutton.Visible = 'Off';
    handles.roiRIGHTbutton.Visible = 'Off';
    handles.roiDOWNbutton.Visible = 'Off';
    handles.roiLEFTbutton.Visible = 'Off';
    handles.shiftROIcheck.Visible = 'Off';
    handles.roiShiftMenu.Visible = 'Off';
    handles.skipImgBox.Visible = 'Off';
    handles.indexSlider.Visible = 'Off';
    
    handles.uibuttongroup1.Visible = 'Off';
    handles.uipanel1.Visible = 'Off';
    handles.imgAx.Visible = 'Off';
    handles.maxSlider.Visible = 'Off';
    handles.minSlider.Visible = 'Off';
    

    % Change zoom settings
handles.zoomH = zoom(handles.imgAx);
handles.zoomH.ActionPostCallback = @zoomForceEqual;

guidata(hObject, handles);

% --- Outputs from this function are returned to the command line.
function varargout = StackROIgui_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
% varargout{1} = handles.output;




% --- Executes on button press in selMDbutton.
function selMDbutton_Callback(hObject, eventdata, handles)
% hObject    handle to selMDbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.output = hObject;

% imgDir = uigetdir;
[FileName,imgDir] = uigetfile('Metadata.mat','Select the Metadata file');
% tic
cd(imgDir)
h = waitbar(0,'Loading Metadata...');
if exist(fullfile(imgDir,'Metadata.mat'),'file')
    % Load metadata from file
    MD = Metadata(pwd);
    handles.MD = MD;
    waitbar(1/4,h,'Loading Previous Results (if available)...');
    % Load results or create new results if it isnt already saved 
    R = MultiPositionSingleCellResults(imgDir);
    
    
    set(handles.imgPosPuMenu,'Visible', 'on');
    set(handles.chPUmenu,'Visible', 'on');
%     if ~strcmp(MD.Types,'RoiSet')
%         MD.addToImages(1:length(MD.ImgFiles),'RoiSet',[])
%     end
    
    % Convert metadata values to table format

    MDvtab = cell2table(MD.Values,'VariableNames',MD.Types);
    MDvtab.group = categorical(MDvtab.group);
    MDvtab.Channel = categorical(MDvtab.Channel);
    MDvtab.Position = categorical(MDvtab.Position);
    MDpos = categories(MDvtab.Position);
    nPos = length(MDpos);
    if nPos == 1
        set(handles.imgPosPuMenu,'Enable', 'off');
    else
        set(handles.imgPosPuMenu,'Enable', 'on');
    end

    % Check if the results varaible has the proper number of positions
    if R.Np == 0
        waitbar(2/4,h,'Generating blank results file...');
        % No positions have been previously set
        
        R = generateBlankResults(R,MD);
    elseif R.Np ~= nPos
        waitbar(2/4,h,'Generating blank results file...');
        % Number of positions doesnt match so reset the results and
        % re-define
        R = MultiPositionSingleCellResults(imgDir,true);
        R = generateBlankResults(R,MD);
    end
    waitbar(2/4,h,'Loading Previous Results (if available)...');
    % MDgrps = categories(MDvtab.group);
    set(handles.imgPosPuMenu,'String', MDpos);
    possCh = MDvtab.Channel(MDvtab.Position == MDpos{1});
    chGr = categories(possCh);
    set(handles.chPUmenu,'String', chGr);
    waitbar(3/4,h,'Updating Gui...');
    handles.R =  R;
    handles.MDvtab = MDvtab;
%     toc
    % Update handles structure
    
    handles.getStackButton.Visible = 'On';
    handles.chPUmenu.Visible = 'On';
    handles.imgPosPuMenu.Visible = 'On';
    
    

    guidata(hObject, handles);
    delete(h);
else
    errordlg('Please select an image directory with the ''Metadata.mat'' file in it');
    
end


% --- Executes on selection change in imgPosPuMenu.
function imgPosPuMenu_Callback(hObject, eventdata, handles)
% hObject    handle to imgPosPuMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns imgPosPuMenu contents as cell array
%        contents{get(hObject,'Value')} returns selected item from imgPosPuMenu

contents = cellstr(get(hObject,'String'));
grName = contents{get(hObject,'Value')};
MDvtab = handles.MDvtab;

possCh = MDvtab.Channel(MDvtab.group == grName);
chGr = categories(possCh);

set(handles.chPUmenu,'String', chGr);




% --- Executes during object creation, after setting all properties.
function imgPosPuMenu_CreateFcn(hObject, eventdata, handles)
% hObject    handle to imgPosPuMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in chPUmenu.
function chPUmenu_Callback(hObject, eventdata, handles)
% hObject    handle to chPUmenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns chPUmenu contents as cell array
%        contents{get(hObject,'Value')} returns selected item from chPUmenu


% --- Executes during object creation, after setting all properties.
function chPUmenu_CreateFcn(hObject, eventdata, handles)
% hObject    handle to chPUmenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in getStackButton.
function getStackButton_Callback(hObject, eventdata, handles)
% hObject    handle to getStackButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


handles.rectToggle.Visible = 'On';
handles.polyToggle.Visible = 'On';
handles.newROIbutton.Visible = 'On';
handles.bkgrROIbutton.Visible = 'On';
handles.delROIbutton.Visible = 'On';
handles.listbox1.Visible = 'On';
handles.exitButton.Visible = 'On';
handles.getStackButton.Visible = 'On';
handles.selMDbutton.Visible = 'On';
handles.roiUPbutton.Visible = 'On';
handles.roiRIGHTbutton.Visible = 'On';
handles.roiDOWNbutton.Visible = 'On';
handles.roiLEFTbutton.Visible = 'On';
handles.shiftROIcheck.Visible = 'On';
handles.roiShiftMenu.Visible = 'On';
handles.skipImgBox.Visible = 'On';
handles.indexSlider.Visible = 'On';

handles.uibuttongroup1.Visible = 'On';
handles.uipanel1.Visible = 'On';
handles.imgAx.Visible = 'On';
handles.maxSlider.Visible = 'On';
handles.minSlider.Visible = 'On';
    
if isfield(handles,'ROIvals')
    oldROIvals = handles.ROIvals;
    for k = 1:length(oldROIvals(:,1))
        if ~isempty(oldROIvals{k,4})
            hand = oldROIvals{k,4};
            delete(hand);
        end
    end
    handles.ROIvals = {[],[],[],[]};
    set(handles.listbox1,'Value',1)
    set(handles.listbox1,'String','<no ROI>')
    set(handles.indexSlider,'Value',1);
else
    handles.ROIvals = {[],[],[],[]};
    handles.BkgrROIval = {[],'Background',[],[]};
end
contentsPos = cellstr(get(handles.imgPosPuMenu,'String'));
posName = contentsPos{get(handles.imgPosPuMenu,'Value')};

contentsCh = cellstr(get(handles.chPUmenu,'String'));
chName = contentsCh{get(handles.chPUmenu,'Value')};
handles.posName = posName;
handles.chName = chName;

MD = handles.MD;
MDvtab = handles.MDvtab;
ImgStack = MD.stkread('Position',posName,'Channel',chName,'timefunc',@(t) true(size(t)))*2^16;
handles.Height = size(ImgStack,1);
handles.Width = size(ImgStack,2);
handles.ImgStack = ImgStack;
ImgInds = MDvtab.Position == posName & MDvtab.Channel == chName;
handles.ImgInds = ImgInds;
imgNames = MD.ImgFiles(ImgInds);
nImages = size(ImgStack,3);
handles.imgNames = imgNames;
handles.globalIndex = find(strcmp(MD.ImgFiles,imgNames{1})); 
% imgIn = imread([MD.basepth,'\',imgNames{1}]);
imgHandle = imagesc(ImgStack(:,:,1),'Parent',handles.imgAx);
handles.imgHandle=imgHandle;
colormap(handles.imgAx,'gray')
set(handles.imgAx,'xtick',[],'ytick',[])
currLim = get(handles.imgAx,'CLim');
set(handles.minSlider,'Value',log2(currLim(1)));
set(handles.maxSlider,'Value',log2(currLim(2)));

set(handles.indexSlider,'Value',1);
set(handles.indexSlider,'Max',nImages);
set(handles.indexSlider,'Min',1);
set(handles.indexSlider, 'SliderStep', [1/(nImages-1) , 10/(nImages-1) ]);

posRindex = find(ismember(handles.R.PosNames,posName));
hold on;
if ~isempty(handles.R.Lbl(posRindex).ManualRoi)
    
    handles.CellRoi = handles.R.Lbl(posRindex).ManualRoi;
    RoiVertsCell = handles.CellRoi{1,2};

    try
        RoiLeg = handles.CellRoi{1,3};
    catch
        handles.R.Lbl(posRindex).setManualRoiGroup(RoiVertsCell,'roi_action','Shift');
        handles.CellRoi = handles.R.Lbl(posRindex).ManualRoi;
        RoiVertsCell = handles.CellRoi{1,2};
        RoiLeg = handles.CellRoi{1,3};
    end
    RoiLeader = 'ROI-';
    for k = 1:length(RoiVertsCell)

        RoiStr = [RoiLeader,num2str(RoiLeg(k))];

        roiXY = RoiVertsCell{k};
        hp = plot(roiXY(:,1),roiXY(:,2),'LineStyle',handles.roi_LineStyle,...
                                        'Color',handles.roi_Color,...
                                        'LineWidth',handles.roi_LineWidth,...
                                        'Marker',handles.roi_Marker,...
                                        'MarkerSize',handles.roi_MarkerSize);
        handles.ROIvals(k,:) = {RoiLeg(k),RoiStr,roiXY,hp};
    end
%     [sortCellRoiFr,sortCRFrInd] = sort(cell2mat(handles.CellRoi(:,1)));
%     
%     currRoiInd = sortCRFrInd(find(sortCellRoiFr<=1,1,'last'));
    
    
end

if ~isempty(handles.R.Lbl(posRindex).BkgrManualRoi)
    
    handles.BkgrRoi = handles.R.Lbl(posRindex).BkgrManualRoi;
    RoiVertsCell = handles.BkgrRoi{1,2};
    roiXY = RoiVertsCell{1};
    hpb = plot(roiXY(:,1),roiXY(:,2),'LineStyle',handles.roi_LineStyle,...
                                    'Color',handles.roi_BkgrColor,...
                                    'LineWidth',handles.roi_LineWidth,...
                                    'Marker',handles.roi_Marker,...
                                    'MarkerSize',handles.roi_MarkerSize);
    handles.BkgrROIval = {1,'Background',roiXY,hpb};
%     [sortBkgrRoiFr,sortBRFrInd] = sort(cell2mat(handles.BkgrRoi(:,1)));
%     
%     currBkgrRoiInd = sortBRFrInd(find(sortBkgrRoiFr<=1,1,'last'));
end

% Update the listbox

if isempty(handles.BkgrROIval{3}) && isempty(handles.ROIvals{1,2})
    set(handles.listbox1,'String','<no ROI>')
elseif isempty(handles.BkgrROIval{3}) && ~isempty(handles.ROIvals{1,2})
    contents = handles.ROIvals(:,2);
    set(handles.listbox1,'String',contents)
elseif ~isempty(handles.BkgrROIval{3}) && isempty(handles.ROIvals{1,2})
    contents = handles.BkgrROIval(2);
    set(handles.listbox1,'String',contents)
else
    contents = [handles.BkgrROIval(2); handles.ROIvals(:,2)];
    set(handles.listbox1,'String',contents)
end

set(handles.listbox1,'Value',1)
% set(handles.imgAx,'CLim',[0 2^16])
% firstInd = find(ImgInds,1);
% if ~isempty(MDvtab.RoiSet{firstInd})
%     hold on;
%     ROIvals = MDvtab.RoiSet{firstInd};
%     
%     if ~isempty(ROIvals{1,1})
%         roiXY = ROIvals{1,3};
%         hp = plot(roiXY(:,1),roiXY(:,2),'*-g','LineWidth',1.5);
%         ROIvals{1,4} = hp;
%     end
%     for k = 2:length(ROIvals(:,1))
%         roiXY = ROIvals{k,3};
%         hp = plot(roiXY(:,1),roiXY(:,2),'*-r','LineWidth',1.5);
%         ROIvals{k,4} = hp;
%     end
%     handles.ROIvals = ROIvals;
%         
% 
% 
% contents = handles.ROIvals(:,2);
% if isempty(contents{1})
%     contents = contents(2:end);
% end
% set(handles.listbox1,'String',contents)
% set(handles.listbox1,'Value',length(contents))
% 
% end

guidata(hObject, handles);


% --- Executes on slider movement.
function maxSlider_Callback(hObject, eventdata, handles)
% hObject    handle to maxSlider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider
newMax = get(hObject,'Value');
oldMin = get(handles.minSlider,'Value');
if newMax < oldMin
    set(handles.minSlider,'Value',newMax);
    set(handles.maxSlider,'Value',oldMin);
    tempMin = oldMin;
    oldMin = newMax;
    newMax = tempMin;
end
set(handles.imgAx,'CLim',[2^oldMin 2^newMax]);


% --- Executes during object creation, after setting all properties.
function maxSlider_CreateFcn(hObject, eventdata, handles)
% hObject    handle to maxSlider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end


% --- Executes on slider movement.
function minSlider_Callback(hObject, eventdata, handles)
% hObject    handle to minSlider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider
newMin = get(hObject,'Value');
oldMax = get(handles.maxSlider,'Value');
if newMin > oldMax
    set(handles.minSlider,'Value',oldMax);
    set(handles.maxSlider,'Value',newMin);
    tempMin = newMin;
    newMin = oldMax;
    oldMax = tempMin;
end
set(handles.imgAx,'CLim',[2^newMin 2^oldMax]);

% --- Executes during object creation, after setting all properties.
function minSlider_CreateFcn(hObject, eventdata, handles)
% hObject    handle to minSlider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end


% --- Executes on slider movement.
function indexSlider_Callback(hObject, eventdata, handles)
% hObject    handle to indexSlider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider

val=round(hObject.Value);
hObject.Value=val;

imgIndex = get(handles.indexSlider,'Value');
handles.ImgIndex = imgIndex;
imgNameNew = handles.imgNames{imgIndex};
MD = handles.MD;
% imgIn = imread([MD.basepth,'\',imgNameNew]);
% newHand = imagesc(handles.ImgStack(:,:,imgIndex),'Parent',handles.imgAx);
handles.imgHandle.CData = handles.ImgStack(:,:,imgIndex);
% delete(handles.imgHandle)
% handles.imgHandle = newHand;
currMin = get(handles.minSlider,'Value');
currMax = get(handles.maxSlider,'Value');

set(handles.imgAx,'CLim',[2^currMin 2^currMax]);
set(handles.imgAx,'xtick',[],'ytick',[])

set(handles.indText,'String',num2str(imgIndex))

% posRindex = find(ismember(handles.R.PosNames,handles.posName));
hold on;
if isfield(handles,'CellRoi')
    
    [sortCellRoiFr,sortCRFrInd] = sort(cell2mat(handles.CellRoi(:,1)));
    
    currRoiInd = sortCRFrInd(find(sortCellRoiFr<=imgIndex,1,'last'));
    
    RoiVertsCell = handles.CellRoi{currRoiInd,2};
    RoiLeg = handles.CellRoi{currRoiInd,3};
 
%     RoiLeader = 'ROI-';
    for k = 1:length(RoiVertsCell)

%         RoiStr = [RoiLeader,num2str(RoiLeg(k))];

        roiXY = RoiVertsCell{k};
        pHand = handles.ROIvals{k,4};
        set(pHand,'XData',roiXY(:,1),'YData',roiXY(:,2))
        handles.ROIvals{k,3} = roiXY;
        uistack(pHand,'top')
    end
end

if isfield(handles,'BkgrRoi')

    [sortBkgrRoiFr,sortBRFrInd] = sort(cell2mat(handles.BkgrRoi(:,1)));
    
    currBkgrRoiInd = sortBRFrInd(find(sortBkgrRoiFr<=imgIndex,1,'last'));
    
    RoiVertsCell = handles.BkgrRoi{currBkgrRoiInd,2};
    roiXY = RoiVertsCell{1};
    
    pHandB = handles.BkgrROIval{1,4};
    set(pHandB,'XData',roiXY(:,1),'YData',roiXY(:,2))
    handles.BkgrROIval{3} = roiXY;
    
    uistack(pHandB,'top')

end

% Update the listbox

% if isempty(handles.BkgrROIval{3}) && isempty(handles.ROIvals{1,2})
%     set(handles.listbox1,'String','<no ROI>')
% elseif isempty(handles.BkgrROIval{3}) && ~isempty(handles.ROIvals{1,2})
%     contents = handles.ROIvals(:,2);
%     set(handles.listbox1,'String',contents)
% elseif ~isempty(handles.BkgrROIval{3}) && isempty(handles.ROIvals{1,2})
%     contents = handles.BkgrROIval(2);
%     set(handles.listbox1,'String',contents)
% else
%     contents = [handles.BkgrROIval(2); handles.ROIvals(:,2)];
%     set(handles.listbox1,'String',contents)
% end
% 
% set(handles.listbox1,'Value',1)



MDvtab = handles.MDvtab;
globalIndex = find(strcmp(MD.ImgFiles,imgNameNew));
handles.globalIndex = globalIndex; 
% IndROI = MDvtab.RoiSet{globalIndex};
% if isfield(handles,'ROIvals')
%     allROI = handles.ROIvals;
%     for k = 1:length(allROI(:,1))
%         if ~isempty(allROI{k,4})
%             hand = allROI{k,4};
%             if max(max(IndROI{k,3}~=allROI{k,3}))
%                 roiXY = IndROI{k,3};
%                 set(hand,'XData',roiXY(:,1),'YData',roiXY(:,2))
%                 allROI{k,3} =  IndROI{k,3};
%                 
%             end
%             uistack(hand,'top')
%         end
%     end
%     handles.ROIvals = allROI;
% end
% 
if max(strcmp(MD.Types,'BadFrame'))
    skipVal = handles.MD.getSpecificMetadataByIndex('BadFrame',globalIndex);
    if isempty(skipVal{1})
        set(handles.skipImgBox,'Value',0);
    else
        set(handles.skipImgBox,'Value',skipVal{1});
    end
else
    set(handles.skipImgBox,'Value',0);
end

guidata(hObject, handles);



% --- Executes during object creation, after setting all properties.
function indexSlider_CreateFcn(hObject, eventdata, handles)
% hObject    handle to indexSlider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end


% --- Executes on button press in newROIbutton.
function newROIbutton_Callback(hObject, eventdata, handles)
% hObject    handle to newROIbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


button  = 1;

% exit zoom and pan
zoom off;
pan off;

% Disable other buttons
grayOutButtons(handles,'off')

xv =[];
yv=[];
hold on;
getPolyToggle = get(handles.polyToggle,'Value');
% getPolyToggle = 1;
if getPolyToggle==1
    typeOpt = 'Poly';
else
    typeOpt = 'Rect';
end
switch typeOpt
    case 'Poly'
        while button == 1
            [xin,yin,button]=ginputc(1,'Color','r');
            xv = [xv,round(xin)];
            yv = [yv,round(yin)];
            if length(xv)>1
                set(hp,'XData',xv,'YData',yv)
                %         plot(xv(end-1:end),yv(end-1:end),'r-*','LineWidth',2)
            elseif length(xv)==1
                hp = plot(xv(end),yv(end),'LineStyle',handles.roi_LineStyle,...
                                        'Color',handles.roi_Color,...
                                        'LineWidth',handles.roi_LineWidth,...
                                        'Marker',handles.roi_Marker,...
                                        'MarkerSize',handles.roi_MarkerSize);
            end
            
        end
    case 'Rect'
        [xin,yin,button]=ginputc(1,'Color','r');
        xv = round(xin);
        yv = round(yin);
%         hp = plot(xv,yv,'r-*','LineWidth',1.5);
        hp = plot(xv,yv,'LineStyle',handles.roi_LineStyle,...
                                        'Color',handles.roi_Color,...
                                        'LineWidth',handles.roi_LineWidth,...
                                        'Marker',handles.roi_Marker,...
                                        'MarkerSize',handles.roi_MarkerSize);
        [xin,yin,button]=ginput(1);
        xin = round(xin);
        yin = round(yin);
        xv = [xv, xv, xin, xin];
        yv = [yv, yin, yin, yv];
        set(hp,'XData',xv,'YData',yv)
end
xv = [xv,xv(1)];
yv = [yv,yv(1)];
set(hp,'XData',xv,'YData',yv)
roiMat = [xv',yv'];

% Add to cell lbl
posRindex = find(ismember(handles.R.PosNames,handles.posName));
handles.R.Lbl(posRindex).setManualRoiGroup({roiMat},'roi_action','Add');
handles.CellRoi = handles.R.Lbl(posRindex).ManualRoi;

RoiLeg = handles.CellRoi{1,3};
RoiLeader = 'ROI-';
RoiStr = [RoiLeader,num2str(RoiLeg(end))];

if ~isfield(handles,'ROIvals')
    handles.ROIvals(1,:) = {RoiLeg(end),RoiStr,roiMat,hp};
else
    if isempty(handles.ROIvals)
        handles.ROIvals(1,:) = {RoiLeg(end),RoiStr,roiMat,hp};
    elseif isempty(handles.ROIvals{1,3})
        handles.ROIvals(1,:) = {RoiLeg(end),RoiStr,roiMat,hp};
    else
        handles.ROIvals(length(handles.ROIvals(:,1))+1,:) = {RoiLeg(end),RoiStr,roiMat,hp};
    end
end
    
% contents = handles.ROIvals(:,2);
% if isempty(contents{1})
%     contents = contents(2:end);
% end
% Update the listbox

if isempty(handles.BkgrROIval{3}) && isempty(handles.ROIvals{1,2})
    contents{1} = '<no ROI>';
    set(handles.listbox1,'String',contents)
elseif isempty(handles.BkgrROIval{3}) && ~isempty(handles.ROIvals{1,2})
    contents = handles.ROIvals(:,2);
    set(handles.listbox1,'String',contents)
elseif ~isempty(handles.BkgrROIval{3}) && isempty(handles.ROIvals{1,2})
    contents = handles.BkgrROIval(2);
    set(handles.listbox1,'String',contents)
else
    contents = [handles.BkgrROIval(2); handles.ROIvals(:,2)];
    set(handles.listbox1,'String',contents)
end

% set(handles.listbox1,'String',contents)
set(handles.listbox1,'Value',length(contents))


% MD = handles.MD;
% MDvtab = handles.MDvtab;
% grName=handles.grName;
% 
% 
% ImgInds = find(MDvtab.group == grName);
% ROIvals = handles.ROIvals;
% MD.addToImages(ImgInds,'RoiSet',ROIvals(:,1:3))
% MDvtab.RoiSet(ImgInds) = {ROIvals(:,1:3)};
% handles.MDvtab = MDvtab;
% saveMetadata(MD,MD.basepth)
% handles.MD = MD;

% Re-enable other buttons
grayOutButtons(handles,'on')

guidata(hObject, handles);


% --- Executes on selection change in listbox1.
function listbox1_Callback(hObject, eventdata, handles)
% hObject    handle to listbox1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns listbox1 contents as cell array
%        contents{get(hObject,'Value')} returns selected item from listbox1

index_selected = get(handles.listbox1,'Value');
allStr= get(handles.listbox1,'String');
selStr = allStr(index_selected);
if ~strcmp(selStr,'<no ROI>')
    if strcmp(selStr,'Background')
        htoCh =handles.BkgrROIval{4};
        set(htoCh,'Color',handles.roi_SelColor)
        if ~isempty(handles.ROIvals(:,2))
            for k = 1:length(handles.ROIvals(:,4))
                set(handles.ROIvals{k,4},'Color',handles.roi_Color);
            end
        end
    else

        ROIcell = handles.ROIvals;
        ROIstr= ROIcell(:,2);

        Ind = strcmp(allStr(index_selected),ROIstr);

        htoCh =ROIcell{Ind,4};
        set(htoCh,'Color',[0 0 1])
        hnoCh = ROIcell(~strcmp(allStr(index_selected),ROIstr),4);
        for k = 1:length(hnoCh)
            set(hnoCh{k},'Color',handles.roi_Color);
        end
        if ~isempty(handles.BkgrROIval{4})
            set(handles.BkgrROIval{4},'Color',handles.roi_BkgrColor);
        end
    end
end

% --- Executes during object creation, after setting all properties.
function listbox1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to listbox1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in bkgrROIbutton.
function bkgrROIbutton_Callback(hObject, eventdata, handles)
% hObject    handle to bkgrROIbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

button  = 1;

xv =[];
yv=[];

% exit zoom and pan
zoom off;
pan off;

% Disable other buttons
grayOutButtons(handles,'off')

hold on;
getPolyToggle = get(handles.polyToggle,'Value');
if ~isempty(handles.BkgrROIval{4})
    delete(handles.BkgrROIval{4});
end
% if isfield(handles,'ROIvals')
%     if ~isempty(handles.ROIvals{1,1})
%         htoDel = handles.ROIvals{1,4};
%         delete(htoDel)
%     end
% end
% getPolyToggle = 1;
if getPolyToggle==1
    typeOpt = 'Poly';
else
    typeOpt = 'Rect';
end
switch typeOpt
    case 'Poly'
        while button == 1
            [xin,yin,button]=ginputc(1,'Color','r');
            xv = [xv,round(xin)];
            yv = [yv,round(yin)];
            if length(xv)>1
                set(hp,'XData',xv,'YData',yv)
                %         plot(xv(end-1:end),yv(end-1:end),'r-*','LineWidth',2)
            elseif length(xv)==1
%                 hp = plot(xv(end),yv(end),'g-*','LineWidth',1.5);
                hp = plot(xv(end),yv(end),'LineStyle',handles.roi_LineStyle,...
                                    'Color',handles.roi_BkgrColor,...
                                    'LineWidth',handles.roi_LineWidth,...
                                    'Marker',handles.roi_Marker,...
                                    'MarkerSize',handles.roi_MarkerSize);
                
            end
            
        end
    case 'Rect'
        [xin,yin,button]=ginputc(1,'Color','r');
        xv = round(xin);
        yv = round(yin);
%         hp = plot(xv,yv,'g-*','LineWidth',1.5);
        hp = plot(xv,yv,'LineStyle',handles.roi_LineStyle,...
                                    'Color',handles.roi_BkgrColor,...
                                    'LineWidth',handles.roi_LineWidth,...
                                    'Marker',handles.roi_Marker,...
                                    'MarkerSize',handles.roi_MarkerSize);
        [xin,yin,button]=ginput(1);
        xin = round(xin);
        yin = round(yin);
        xv = [xv, xv, xin, xin];
        yv = [yv, yin, yin, yv];
        set(hp,'XData',xv,'YData',yv)
end
xv = [xv,xv(1)];
yv = [yv,yv(1)];
set(hp,'XData',xv,'YData',yv)
roiMat = [xv',yv'];



% Add to cell lbl
posRindex = find(ismember(handles.R.PosNames,handles.posName));
handles.R.Lbl(posRindex).setManualRoiGroup({roiMat},'roi_action','Add','roi_type','Bkgr');
handles.BkgrRoi = handles.R.Lbl(posRindex).BkgrManualRoi;

handles.BkgrROIval = {1,'Background',roiMat,hp};
% RoiLeg = handles.CellRoi{1,3};
% RoiLeader = 'ROI-';
% RoiStr = [RoiLeader,num2str(RoiLeg(end))];
% 
% if ~isfield(handles,'ROIvals')
%     handles.ROIvals(1,:) = {RoiLeg(end),RoiStr,roiMat,hp};
% else
%     handles.ROIvals(length(handles.ROIvals(:,1))+1,:) = {RoiLeg(end),RoiStr,roiMat,hp};
% end
    
% contents = handles.ROIvals(:,2);
% if isempty(contents{1})
%     contents = contents(2:end);
% end
% Update the listbox

if isempty(handles.BkgrROIval{3}) && isempty(handles.ROIvals)
    contents{1} = '<no ROI>';
    set(handles.listbox1,'String',contents)
elseif isempty(handles.BkgrROIval{3}) && ~isempty(handles.ROIvals{1,2})
    contents = handles.ROIvals(:,2);
    set(handles.listbox1,'String',contents)
elseif ~isempty(handles.BkgrROIval{3}) && isempty(handles.ROIvals)
    contents = handles.BkgrROIval(2);
    set(handles.listbox1,'String',contents)
else
    contents = [handles.BkgrROIval(2); handles.ROIvals(:,2)];
    set(handles.listbox1,'String',contents)
end

% set(handles.listbox1,'String',contents)
set(handles.listbox1,'Value',length(contents))

% if ~isfield(handles,'ROIvals')
%     handles.ROIvals = {0,'Background', roiMat, hp};
% else
%     ROIvals = handles.ROIvals;
%     ROIvals(1,:)={0,'Background',roiMat,hp};
%     handles.ROIvals = ROIvals;
% end
%     
% contents = handles.ROIvals(:,2);
% set(handles.listbox1,'String',contents)
% 
% MD = handles.MD;
% MDvtab = handles.MDvtab;
% grName=handles.grName;
% 
% 
% ImgInds = find(MDvtab.group == grName);
% ROIvals = handles.ROIvals;
% MD.addToImages(ImgInds,'RoiSet',ROIvals(:,1:3))
% MDvtab.RoiSet(ImgInds) = {ROIvals(:,1:3)};
% handles.MDvtab = MDvtab;
% saveMetadata(MD,MD.basepth)
% handles.MD = MD;

% Re-enable other buttons
grayOutButtons(handles,'on')

guidata(hObject, handles);


% --- Executes on button press in delROIbutton.
function delROIbutton_Callback(hObject, eventdata, handles)
% hObject    handle to delROIbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

index_selected = get(handles.listbox1,'Value');
allStr= get(handles.listbox1,'String');

selStr = allStr(index_selected);
if ~strcmp(selStr,'<no ROI>')
    if strcmp(selStr,'Background')
        htoCh =handles.BkgrROIval{4};
        delete(htoCh);
        posRindex = find(ismember(handles.R.PosNames,handles.posName));
        handles.R.Lbl(posRindex).setManualRoiGroup(0,'roi_action','Del','roi_type','Bkgr');
        
        handles.BkgrROIval = {[],'Background',[],[]};
        handles.BkgrRoi = handles.R.Lbl(posRindex).BkgrManualRoi;
%         set(handles.listbox1,'Value',1);
%         set(handles.listbox1,'String', allStr(2:end));
    else

        ROIcell = handles.ROIvals;
        ROIstr= ROIcell(:,2);

        Ind = strcmp(allStr(index_selected),ROIstr);
        lblNum = ROIcell{Ind,1};

        htoCh =ROIcell{Ind,4};
        delete(htoCh);
        posRindex = find(ismember(handles.R.PosNames,handles.posName));
        handles.R.Lbl(posRindex).setManualRoiGroup(lblNum,'roi_action','Del');
        handles.ROIvals(Ind,:) = [];
        handles.CellRoi = handles.R.Lbl(posRindex).ManualRoi;
%         set(handles.listbox1,'Value',1);
%         set(handles.listbox1,'String', allStr(~Ind));
        
    end
end

if isempty(handles.BkgrROIval{3}) && isempty(handles.ROIvals)
    contents{1} = '<no ROI>';
    set(handles.listbox1,'String',contents)
    set(handles.listbox1,'Value',1)
elseif isempty(handles.BkgrROIval{3}) && ~isempty(handles.ROIvals{1,2})
    contents = handles.ROIvals(:,2);
    set(handles.listbox1,'String',contents)
    if index_selected~=1
        set(handles.listbox1,'Value',index_selected-1)
    else
        set(handles.listbox1,'Value',1)
    end
elseif ~isempty(handles.BkgrROIval{3}) && isempty(handles.ROIvals)
    contents = handles.BkgrROIval(2);
    set(handles.listbox1,'String',contents)
    set(handles.listbox1,'Value',1)
else
    contents = [handles.BkgrROIval(2); handles.ROIvals(:,2)];
    set(handles.listbox1,'String',contents)
    if index_selected~=1
        set(handles.listbox1,'Value',index_selected-1)
    else
        set(handles.listbox1,'Value',1)
    end
end

% set(handles.listbox1,'String',contents)

% set(handles.listbox1,'Value',1)


% ROIcell = handles.ROIvals;
% ROIstr =  ROIcell(:,2);
% Ind = strcmp(allStr(index_selected),ROIstr);
% 
% htoDel = ROIcell{Ind,4};
% delete(htoDel);
% indNum = find(Ind);
% if indNum == 1
%     ROIcell(1,:)={[],[],[],[]};
% else
%     ROIcell(Ind,:) = [];
% end
% handles.ROIvals = ROIcell;
% 
% set(handles.listbox1,'Value',1);
% set(handles.listbox1,'String', allStr(~Ind));
% 
% MD = handles.MD;
% MDvtab = handles.MDvtab;
% grName=handles.grName;
% 
% 
% ImgInds = find(MDvtab.group == grName);
% ROIvals = handles.ROIvals;
% MD.addToImages(ImgInds,'RoiSet',ROIvals(:,1:3))
% MDvtab.RoiSet(ImgInds) = {ROIvals(:,1:3)};
% handles.MDvtab = MDvtab;
% saveMetadata(MD,MD.basepth)
% handles.MD = MD;
guidata(hObject, handles);


% --- Executes on button press in shiftROIcheck.
function shiftROIcheck_Callback(hObject, eventdata, handles)
% hObject    handle to shiftROIcheck (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of shiftROIcheck


% --- Executes on button press in roiUPbutton.
function roiUPbutton_Callback(hObject, eventdata, handles)
% hObject    handle to roiUPbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

shiftValStrAll = cellstr(get(handles.roiShiftMenu,'String'));
shiftValStr = shiftValStrAll{get(handles.roiShiftMenu,'Value')};
shiftDist = str2num(shiftValStr);

posRindex = find(ismember(handles.R.PosNames,handles.posName));

if get(handles.shiftROIcheck,'Value')

    ROIvals = handles.ROIvals;
    for k = 1:length(ROIvals(:,1))
        if ~isempty(ROIvals{k,3})
            oldRoiXY = ROIvals{k,3};
            newRoiXY = [oldRoiXY(:,1),(oldRoiXY(:,2)-shiftDist)];
            ROIvals{k,3} = newRoiXY;
            hp = ROIvals{k,4};
            set(hp,'XData',newRoiXY(:,1),'YData',newRoiXY(:,2)) 
        end
    end
    handles.ROIvals = ROIvals;
    handles.R.Lbl(posRindex).setManualRoiGroup(ROIvals(:,3),'roi_action','Shift','frame_ind',handles.ImgIndex);
    
    if ~isempty(handles.BkgrROIval{3})
        oldRoiXY = handles.BkgrROIval{3};
        newRoiXY = [oldRoiXY(:,1),(oldRoiXY(:,2)-shiftDist)];
        handles.BkgrROIval{3} = newRoiXY;
        hp = handles.BkgrROIval{4};
        set(hp,'XData',newRoiXY(:,1),'YData',newRoiXY(:,2)) 
    end
    handles.R.Lbl(posRindex).setManualRoiGroup(handles.BkgrROIval(3),'roi_action','Shift','frame_ind',handles.ImgIndex,'roi_type','Bkgr');
    
else
    index_selected = get(handles.listbox1,'Value');
    allStr= get(handles.listbox1,'String');

    selStr = allStr(index_selected);
    
    if ~strcmp(selStr,'<no ROI>')
    if strcmp(selStr,'Background')
       if ~isempty(handles.BkgrROIval{3})
            oldRoiXY = handles.BkgrROIval{3};
            newRoiXY = [oldRoiXY(:,1),(oldRoiXY(:,2)-shiftDist)];
            handles.BkgrROIval{3} = newRoiXY;
            hp = handles.BkgrROIval{4};
            set(hp,'XData',newRoiXY(:,1),'YData',newRoiXY(:,2)) 
        end
        handles.R.Lbl(posRindex).setManualRoiGroup(handles.BkgrROIval(3),'roi_action','Shift','frame_ind',handles.ImgIndex,'roi_type','Bkgr');
    
    else

        ROIvals = handles.ROIvals;
        ROIstr= ROIvals(:,2);
        
        Ind = strcmp(allStr(index_selected),ROIstr);
        lblNum = ROIvals{Ind,1};
        
        oldRoiXY = ROIvals{Ind,3};
        newRoiXY = [oldRoiXY(:,1),(oldRoiXY(:,2)-shiftDist)];
        ROIvals{Ind,3} = newRoiXY;
        hp = ROIvals{Ind,4};
        set(hp,'XData',newRoiXY(:,1),'YData',newRoiXY(:,2))
        handles.ROIvals = ROIvals;
        
        handles.R.Lbl(posRindex).setManualRoiGroup(ROIvals(:,3),'roi_action','Shift','frame_ind',handles.ImgIndex);

        
    end
    end
    
end

handles.CellRoi = handles.R.Lbl(posRindex).ManualRoi;
handles.BkgrRoi = handles.R.Lbl(posRindex).BkgrManualRoi;

guidata(hObject, handles);

% --- Executes on button press in roiLEFTbutton.
function roiLEFTbutton_Callback(hObject, eventdata, handles)
% hObject    handle to roiLEFTbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

shiftValStrAll = cellstr(get(handles.roiShiftMenu,'String'));
shiftValStr = shiftValStrAll{get(handles.roiShiftMenu,'Value')};
shiftDist = str2num(shiftValStr);

posRindex = find(ismember(handles.R.PosNames,handles.posName));

if get(handles.shiftROIcheck,'Value')

    ROIvals = handles.ROIvals;
    for k = 1:length(ROIvals(:,1))
        if ~isempty(ROIvals{k,3})
            oldRoiXY = ROIvals{k,3};
            newRoiXY = [(oldRoiXY(:,1)-shiftDist),(oldRoiXY(:,2))];
            ROIvals{k,3} = newRoiXY;
            hp = ROIvals{k,4};
            set(hp,'XData',newRoiXY(:,1),'YData',newRoiXY(:,2)) 
        end
    end
    handles.ROIvals = ROIvals;
    handles.R.Lbl(posRindex).setManualRoiGroup(ROIvals(:,3),'roi_action','Shift','frame_ind',handles.ImgIndex);
    
    if ~isempty(handles.BkgrROIval{3})
        oldRoiXY = handles.BkgrROIval{3};
        newRoiXY = [(oldRoiXY(:,1)-shiftDist),(oldRoiXY(:,2))];
        handles.BkgrROIval{3} = newRoiXY;
        hp = handles.BkgrROIval{4};
        set(hp,'XData',newRoiXY(:,1),'YData',newRoiXY(:,2)) 
    end
    handles.R.Lbl(posRindex).setManualRoiGroup(handles.BkgrROIval(3),'roi_action','Shift','frame_ind',handles.ImgIndex,'roi_type','Bkgr');
    
else
    index_selected = get(handles.listbox1,'Value');
    allStr= get(handles.listbox1,'String');

    selStr = allStr(index_selected);
    
    if ~strcmp(selStr,'<no ROI>')
    if strcmp(selStr,'Background')
       if ~isempty(handles.BkgrROIval{3})
            oldRoiXY = handles.BkgrROIval{3};
            newRoiXY = [(oldRoiXY(:,1)-shiftDist),(oldRoiXY(:,2))];
            handles.BkgrROIval{3} = newRoiXY;
            hp = handles.BkgrROIval{4};
            set(hp,'XData',newRoiXY(:,1),'YData',newRoiXY(:,2)) 
        end
        handles.R.Lbl(posRindex).setManualRoiGroup(handles.BkgrROIval(3),'roi_action','Shift','frame_ind',handles.ImgIndex,'roi_type','Bkgr');
    
    else

        ROIvals = handles.ROIvals;
        ROIstr= ROIvals(:,2);
        
        Ind = strcmp(allStr(index_selected),ROIstr);
        lblNum = ROIvals{Ind,1};
        
        oldRoiXY = ROIvals{Ind,3};
        newRoiXY = [(oldRoiXY(:,1)-shiftDist),(oldRoiXY(:,2))];
        ROIvals{Ind,3} = newRoiXY;
        hp = ROIvals{Ind,4};
        set(hp,'XData',newRoiXY(:,1),'YData',newRoiXY(:,2))
        handles.ROIvals = ROIvals;
        
        handles.R.Lbl(posRindex).setManualRoiGroup(ROIvals(:,3),'roi_action','Shift','frame_ind',handles.ImgIndex);

        
    end
    end
    
end

handles.CellRoi = handles.R.Lbl(posRindex).ManualRoi;
handles.BkgrRoi = handles.R.Lbl(posRindex).BkgrManualRoi;

guidata(hObject, handles);

% --- Executes on button press in roiRIGHTbutton.
function roiRIGHTbutton_Callback(hObject, eventdata, handles)
% hObject    handle to roiRIGHTbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

shiftValStrAll = cellstr(get(handles.roiShiftMenu,'String'));
shiftValStr = shiftValStrAll{get(handles.roiShiftMenu,'Value')};
shiftDist = str2num(shiftValStr);

posRindex = find(ismember(handles.R.PosNames,handles.posName));

if get(handles.shiftROIcheck,'Value')

    ROIvals = handles.ROIvals;
    for k = 1:length(ROIvals(:,1))
        if ~isempty(ROIvals{k,3})
            oldRoiXY = ROIvals{k,3};
            newRoiXY = [(oldRoiXY(:,1)+shiftDist),(oldRoiXY(:,2))];
            ROIvals{k,3} = newRoiXY;
            hp = ROIvals{k,4};
            set(hp,'XData',newRoiXY(:,1),'YData',newRoiXY(:,2)) 
        end
    end
    handles.ROIvals = ROIvals;
    handles.R.Lbl(posRindex).setManualRoiGroup(ROIvals(:,3),'roi_action','Shift','frame_ind',handles.ImgIndex);
    
    if ~isempty(handles.BkgrROIval{3})
        oldRoiXY = handles.BkgrROIval{3};
        newRoiXY = [(oldRoiXY(:,1)+shiftDist),(oldRoiXY(:,2))];
        handles.BkgrROIval{3} = newRoiXY;
        hp = handles.BkgrROIval{4};
        set(hp,'XData',newRoiXY(:,1),'YData',newRoiXY(:,2)) 
    end
    handles.R.Lbl(posRindex).setManualRoiGroup(handles.BkgrROIval(3),'roi_action','Shift','frame_ind',handles.ImgIndex,'roi_type','Bkgr');
    
else
    index_selected = get(handles.listbox1,'Value');
    allStr= get(handles.listbox1,'String');

    selStr = allStr(index_selected);
    
    if ~strcmp(selStr,'<no ROI>')
    if strcmp(selStr,'Background')
       if ~isempty(handles.BkgrROIval{3})
            oldRoiXY = handles.BkgrROIval{3};
            newRoiXY = [(oldRoiXY(:,1)+shiftDist),(oldRoiXY(:,2))];
            handles.BkgrROIval{3} = newRoiXY;
            hp = handles.BkgrROIval{4};
            set(hp,'XData',newRoiXY(:,1),'YData',newRoiXY(:,2)) 
        end
        handles.R.Lbl(posRindex).setManualRoiGroup(handles.BkgrROIval(3),'roi_action','Shift','frame_ind',handles.ImgIndex,'roi_type','Bkgr');
    
    else

        ROIvals = handles.ROIvals;
        ROIstr= ROIvals(:,2);
        
        Ind = strcmp(allStr(index_selected),ROIstr);
        lblNum = ROIvals{Ind,1};
        
        oldRoiXY = ROIvals{Ind,3};
        newRoiXY = [(oldRoiXY(:,1)+shiftDist),(oldRoiXY(:,2))];
        ROIvals{Ind,3} = newRoiXY;
        hp = ROIvals{Ind,4};
        set(hp,'XData',newRoiXY(:,1),'YData',newRoiXY(:,2))
        handles.ROIvals = ROIvals;
        
        handles.R.Lbl(posRindex).setManualRoiGroup(ROIvals(:,3),'roi_action','Shift','frame_ind',handles.ImgIndex);

        
    end
    end
    
end

handles.CellRoi = handles.R.Lbl(posRindex).ManualRoi;
handles.BkgrRoi = handles.R.Lbl(posRindex).BkgrManualRoi;


guidata(hObject, handles);

% --- Executes on button press in roiDOWNbutton.
function roiDOWNbutton_Callback(hObject, eventdata, handles)
% hObject    handle to roiDOWNbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

shiftValStrAll = cellstr(get(handles.roiShiftMenu,'String'));
shiftValStr = shiftValStrAll{get(handles.roiShiftMenu,'Value')};
shiftDist = str2num(shiftValStr);

posRindex = find(ismember(handles.R.PosNames,handles.posName));

if get(handles.shiftROIcheck,'Value')

    ROIvals = handles.ROIvals;
    for k = 1:length(ROIvals(:,1))
        if ~isempty(ROIvals{k,3})
            oldRoiXY = ROIvals{k,3};
            newRoiXY = [oldRoiXY(:,1),(oldRoiXY(:,2)+shiftDist)];
            ROIvals{k,3} = newRoiXY;
            hp = ROIvals{k,4};
            set(hp,'XData',newRoiXY(:,1),'YData',newRoiXY(:,2)) 
        end
    end
    handles.ROIvals = ROIvals;
    handles.R.Lbl(posRindex).setManualRoiGroup(ROIvals(:,3),'roi_action','Shift','frame_ind',handles.ImgIndex);
    
    if ~isempty(handles.BkgrROIval{3})
        oldRoiXY = handles.BkgrROIval{3};
        newRoiXY = [oldRoiXY(:,1),(oldRoiXY(:,2)+shiftDist)];
        handles.BkgrROIval{3} = newRoiXY;
        hp = handles.BkgrROIval{4};
        set(hp,'XData',newRoiXY(:,1),'YData',newRoiXY(:,2)) 
    end
    handles.R.Lbl(posRindex).setManualRoiGroup(handles.BkgrROIval(3),'roi_action','Shift','frame_ind',handles.ImgIndex,'roi_type','Bkgr');
    
else
    index_selected = get(handles.listbox1,'Value');
    allStr= get(handles.listbox1,'String');

    selStr = allStr(index_selected);
    
    if ~strcmp(selStr,'<no ROI>')
    if strcmp(selStr,'Background')
       if ~isempty(handles.BkgrROIval{3})
            oldRoiXY = handles.BkgrROIval{3};
            newRoiXY = [oldRoiXY(:,1),(oldRoiXY(:,2)+shiftDist)];
            handles.BkgrROIval{3} = newRoiXY;
            hp = handles.BkgrROIval{4};
            set(hp,'XData',newRoiXY(:,1),'YData',newRoiXY(:,2)) 
        end
        handles.R.Lbl(posRindex).setManualRoiGroup(handles.BkgrROIval(3),'roi_action','Shift','frame_ind',handles.ImgIndex,'roi_type','Bkgr');
    
    else

        ROIvals = handles.ROIvals;
        ROIstr= ROIvals(:,2);
        
        Ind = strcmp(allStr(index_selected),ROIstr);
        lblNum = ROIvals{Ind,1};
        
        oldRoiXY = ROIvals{Ind,3};
        newRoiXY = [oldRoiXY(:,1),(oldRoiXY(:,2)+shiftDist)];
        ROIvals{Ind,3} = newRoiXY;
        hp = ROIvals{Ind,4};
        set(hp,'XData',newRoiXY(:,1),'YData',newRoiXY(:,2))
        handles.ROIvals = ROIvals;
        
        handles.R.Lbl(posRindex).setManualRoiGroup(ROIvals(:,3),'roi_action','Shift','frame_ind',handles.ImgIndex);

        
    end
    end
    
end

handles.CellRoi = handles.R.Lbl(posRindex).ManualRoi;
handles.BkgrRoi = handles.R.Lbl(posRindex).BkgrManualRoi;

guidata(hObject, handles);

% --- Executes on selection change in roiShiftMenu.
function roiShiftMenu_Callback(hObject, eventdata, handles)
% hObject    handle to roiShiftMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns roiShiftMenu contents as cell array
%        contents{get(hObject,'Value')} returns selected item from roiShiftMenu


% --- Executes during object creation, after setting all properties.
function roiShiftMenu_CreateFcn(hObject, eventdata, handles)
% hObject    handle to roiShiftMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in exitButton.
function exitButton_Callback(hObject, eventdata, handles)
% hObject    handle to exitButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

close(handles.StackROIguiMainFrame)

h = waitbar(0,'Saving Metadata...');
MD = handles.MD;
saveMetadata(MD,MD.pth)

%try
    waitbar(1/4,h,'Updating Cell Labels...');
    R = handles.R;
    nPos = length(R.PosNames);

    % Update the Lbl Masks
    for k = 1:nPos
        R.Lbl(k).updateLblFromManual(handles.Height,handles.Width);
        R.Lbl(k).saveToFile=0;
    end

    waitbar(2/4,h,'Saving Results...');
    % Save the results
    R.saveResults;

    waitbar(3/4,h,'Re-running or generating analysis script...');
    % Run the script to update values if a script is set.
    if ~isempty(R.analysisScript)
        R.runAnalysis;
    %     run(R.analysisScript)
    else
        % Generate basic report that will at least extract all of the channel
        % values

        % Get base template for user prefs
        firstPart = fileread('resultsPart1.m');

        % Add comment at the beginning of how this was made and the date
        LUanalysisStr = sprintf(['%% Analysis script automatically generated by StackROIgui.m \n',...
                        '%% on ',date,'\n\n',...
                        '%%%% Key user input - the path where the images are (try to keep as a relative path) \n',...
                        'pth = ']);
        if ~isempty(MD.Username) 
            usernameStart = strfind(MD.pth,MD.Username);
            if ~isempty(usernameStart)
                relPath = [filesep,MD.pth(usernameStart(1):end)];
            else
                relPath = MD.pth;
            end
%             if strcmp(relPath(1),filesep)==1
%                 relPath = relPath(2:end);
%             end
            relPathStr = relPath;
            % Convert to windows type
            relPathStr = regexprep(relPathStr,'/','\');
            
            LUanalysisStr = [LUanalysisStr,'''',relPathStr,sprintf(''';\n')];

            analysisFile = fullfile(relPath,['ManROIresults_',MD.Username,'_',datestr(now,'yymmdd'),'.m']);
        else
            
            % Theoretically there should always be 4 folders above MD file
            pathParts = strsplit(MD.pth,filesep);
            
            relPath = fullfile(pathParts{end-3:end});
            relPathStr = [filesep,relPath];
            % Convert to windows type
            relPathStr = regexprep(relPathStr,'/','\');
            
            LUanalysisStr = [LUanalysisStr,'''',relPathStr,'',sprintf(''';\n')];
            
            analysisFile = fullfile(relPath,['ManROIresults_',datestr(now,'yymmdd'),'.m']);
        end

        % Add on the next part
        LUanalysisStr = [LUanalysisStr,firstPart];

        endPart = fileread('resultsPartEnd.m');
        LUanalysisStr = [LUanalysisStr,endPart];

        fullPathAnalysisFile = getAbsPath(analysisFile);
        % Write the settings file
        fid = fopen(fullfile(fullPathAnalysisFile,analysisFile),'w');
        fwrite(fid,LUanalysisStr);
        fid = fclose(fid);    

        % record the analysis script and then run it.
        
        % Convert file name to windows style
        analysisFileWin = regexprep(analysisFile,'/','\');
        R.analysisScript = analysisFileWin;
        R.runAnalysis;
    %     run(analysisFile);

    end

    waitbar(1,h,'Done!');

    delete(h) %close waitbar

%catch
%   warndlg('A post processing error has occured, please check command line for error details');
%   delete(h);
%end

% Close the gui

% nImg = length(MD.ImgFiles);
% h = waitbar(0,'Extracting values...');
% for k = 1:nImg
%     ROImdInd = find(strcmp(MD.Types,'RoiSet'));
%     ROIgrp = MD.Values{k,ROImdInd};
%     cellMean = [];
%     if ~isempty(ROIgrp)
%         imgIn = imread([MD.basepth,'\',MD.ImgFiles{k}]);
%         [sx,sy] = size(imgIn);
%         
%         
%         for m = 2:length(ROIgrp(:,1))
%             roiXY = ROIgrp{m,3};
%             mask = poly2mask(roiXY(:,1),roiXY(:,2),sx,sy);
%             cellMean(1,m-1) = mean(mean(imgIn(mask)));            
%         end
%         MD.addToImages(k,'RoiMeans',cellMean);
%         
%         if ~isempty(ROIgrp{1,3})
%             roiXY = ROIgrp{1,3};
%             mask = poly2mask(roiXY(:,1),roiXY(:,2),sx,sy);
%             bkgr = mean(mean(imgIn(mask)));
%             MD.addToImages(k,'Bkgr',bkgr);
%             MD.addToImages(k,'RoiMeanBkgrSub',cellMean-bkgr);
%         end
%     end
%     waitbar(k/nImg)
% end
% 
% 
% 
% saveMetadata(MD,MD.basepth)

% delete(h) %close waitbar


% --- Executes on button press in skipImgBox.
function skipImgBox_Callback(hObject, eventdata, handles)
% hObject    handle to skipImgBox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of skipImgBox

skipValue = get(hObject,'Value');

MD = handles.MD;

if max(strcmp(MD.Types,'BadFrame')) == 0
    for k = 1:length(MD.ImgFiles)
        MD.addToImages(k,'BadFrame',0);
    end
end
MDvtab = handles.MDvtab;

frameIndex = handles.globalIndex;


frNumber = MDvtab.frame(frameIndex);
grpName = MDvtab.group(frameIndex);
allChValsInd = find(MDvtab.group==grpName & MDvtab.frame == frNumber);
for m = 1:length(allChValsInd)
%     MDvtab.Skip(allChValsInd(m)) = skipValue;
    MD.addToImages(allChValsInd(m),'BadFrame',skipValue);
end
handles.MDvtab = MDvtab;
handles.MD = MD;
saveMetadata(MD,MD.basepth)
guidata(hObject, handles);

function R = generateBlankResults(R,MD)
% Generate a results structure that is blank but has the things that are
% appropriate to modify later.


R.PosNames = unique(MD,'Position'); 
nPos = length(R.PosNames);

% Grab non default props
Props =  MD.NewTypes;

for k = 1:nPos
% Get image info
    fprintf('Setting up postion %i\n',k)
    posCh = unique(MD.getSpecificMetadata('Channel','Position',R.PosNames{k},'timefunc',@(t) true(size(t))));
    frames = unique(cell2mat(MD.getSpecificMetadata('frame','Position',R.PosNames{k},'timefunc',@(t) true(size(t)))));
    try 
        firstOfPos = MD.getIndex({'Position','frame'},{R.PosNames{k},1});
        filename = MD.getImageFilename({'index'},{firstOfPos(1)});
        info = imfinfo(filename);
    catch %#ok<CTCH>
        if MD.dieOnReadError
            error('Files not found to read stack')
        else
            warning('Files not found to read stack')
            info.Height = 2048; 
            info.Width = 2048;
        end
    end
    
    % make a blank cell label 
    Lbl = CellLabel;
    emptyLbl = zeros(info.Height,info.Width,'uint16');
    
    % Get the mean time of each acqFrame
    for m = 1:length(posCh)
        T = MD.getSpecificMetadata('TimestampFrame','Channel',posCh(m),'Position',R.PosNames{k},'timefunc',@(t) true(size(t)));
        T=cat(1,T{:});
        Tall(:,m) = T;
    end
    Tmed = mean(Tall,2);
    
    for n = 1:length(frames)
        Lbl.addLbl(emptyLbl,'base',Tmed(n))
    end
    
    Lbl = setLbl(R,Lbl,R.PosNames{k}); 
    
    % add Position properties
    for j=1:numel(Props)
        try
            tmp=unique(MD,Props{j},'Position',R.PosNames{k});
            setProperty(R,Props{j},tmp(1),R.PosNames{k});
        catch
            warning('Attempted to set property but unable to get unique values');
        end
    end

end

function grayOutButtons(handles,state)


handles.rectToggle.Enable = state;
handles.polyToggle.Enable = state;
handles.newROIbutton.Enable = state;
handles.bkgrROIbutton.Enable = state;
handles.delROIbutton.Enable = state;
handles.listbox1.Enable= state;
handles.exitButton.Enable = state;
handles.chPUmenu.Enable = state;
handles.imgPosPuMenu.Enable= state;
handles.getStackButton.Enable = state;
handles.selMDbutton.Enable= state;
handles.roiUPbutton.Enable = state;
handles.roiRIGHTbutton.Enable = state;
handles.roiDOWNbutton.Enable = state;
handles.roiLEFTbutton.Enable = state;
handles.shiftROIcheck.Enable = state;
handles.roiShiftMenu.Enable = state;
handles.skipImgBox.Enable = state;
handles.indexSlider.Enable = state;

if strcmp(state,'off')
    handles.ROIwarningText.Visible = 'on';
else
    handles.ROIwarningText.Visible = 'off';
end

function zoomForceEqual(obj,evd)
evd.Axes.DataAspectRatio = [1 1 1];
evd.Axes.DataAspectRatioMode = 'manual';
