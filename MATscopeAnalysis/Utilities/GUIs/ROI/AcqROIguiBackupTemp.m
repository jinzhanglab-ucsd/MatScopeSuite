function varargout = AcqROIgui(varargin)
% ACQROIGUI MATLAB code for AcqROIgui.fig
%      ACQROIGUI, by itself, creates a new ACQROIGUI or raises the existing
%      singleton*.
%
%      H = ACQROIGUI returns the handle to a new ACQROIGUI or the handle to
%      the existing singleton*.
%
%      ACQROIGUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in ACQROIGUI.M with the given input arguments.
%
%      ACQROIGUI('Property','Value',...) creates a new ACQROIGUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before AcqROIgui_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to AcqROIgui_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help AcqROIgui

% Last Modified by GUIDE v2.5 24-Jan-2017 14:01:40

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @AcqROIgui_OpeningFcn, ...
                   'gui_OutputFcn',  @AcqROIgui_OutputFcn, ...
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


% --- Executes just before AcqROIgui is made visible.
function AcqROIgui_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to AcqROIgui (see VARARGIN)

% Choose default command line output for AcqROIgui


% UIWAIT makes AcqROIgui wait for user response (see UIRESUME)
% uiwait(handles.AcqROImainFrame);


%%% Get Variables
% Get Scp variable
Scp = varargin{1};
handles.Scp = Scp;

% Get initial image acquisition cell array
initImgCell = varargin{2};
handles.initImgCell = initImgCell;
% set temporary variable for ROI information
handles.ROIinfo = cell(1,length(initImgCell));

%%% Update appearances
% Remove image axis ticks and labels
set(handles.imgAx,'xtick',[],'ytick',[])

%%% Populate pull down menus
% Set position names
PosNames = cellfun(@(x) x{1},handles.initImgCell,'UniformOutput',false);
set(handles.imgPosPuMenu,'String',PosNames)
% Set channel names 
ChNames = handles.initImgCell{1}{3};
set(handles.chPUmenu,'String',ChNames)

%%% Initialize image
posImgStack = handles.initImgCell{1}{4};
imgIn = posImgStack(:,:,1);
imgHandle = imagesc(imgIn,'Parent',handles.imgAx);
%Assume size does not change between locations
[sx,sy] = size(imgIn);
handles.sx = sx;
handles.sy = sy;
handles.imgHandle=imgHandle;
colormap(handles.imgAx,'gray')
set(handles.imgAx,'xtick',[],'ytick',[])
currLim = get(handles.imgAx,'CLim');
if currLim(1) == 0
    currLim(1) = 1;
end
set(handles.minSlider,'Value',log2(currLim(1)));
set(handles.maxSlider,'Value',log2(currLim(2)));

% Update handles structure
guidata(hObject, handles);




% --- Outputs from this function are returned to the command line.
function varargout = AcqROIgui_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
% varargout{1} = handles.output;
% uiwait(handles.AcqROImainFrame);
% guidata(hObject, handles);

% Return the updated initImgCell variable
% varargout{1} = handles.initImgCell;

% Return the figure handle of the GUI
varargout{1} = handles.AcqROImainFrame;



% --- Executes on button press in selMDbutton.
function selMDbutton_Callback(hObject, eventdata, handles)
% hObject    handle to selMDbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.output = hObject;

imgDir = uigetdir;
cd(imgDir)
MD = Metadata(pwd);
set(handles.imgPosPuMenu,'Visible', 'on');
set(handles.chPUmenu,'Visible', 'on');
if ~strcmp(MD.Types,'RoiSet')
    MD.addToImages(1:length(MD.ImgFiles),'RoiSet',[])
end
handles.MD = MD;
MDvtab = cell2table(MD.Values,'VariableNames',MD.Types);
MDvtab.group = categorical(MDvtab.group);
MDvtab.Channel = categorical(MDvtab.Channel);
MDgrps = categories(MDvtab.group);
set(handles.imgPosPuMenu,'String', MDgrps);
possCh = MDvtab.Channel(MDvtab.group == MDgrps{1});
chGr = categories(possCh);
set(handles.chPUmenu,'String', chGr);

handles.MDvtab = MDvtab;
% Update handles structure
guidata(hObject, handles);


% --- Executes on selection change in imgPosPuMenu.
function imgPosPuMenu_Callback(hObject, eventdata, handles)
    % hObject    handle to imgPosPuMenu (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)

    % Hints: contents = cellstr(get(hObject,'String')) returns imgPosPuMenu contents as cell array
    %        contents{get(hObject,'Value')} returns selected item from imgPosPuMenu

    posIndex = get(hObject,'Value');
    channelIndex = get(handles.chPUmenu,'Value');

    posImgStack = handles.initImgCell{posIndex}{4};
    imgHandle = imagesc(posImgStack(:,:,channelIndex),'Parent',handles.imgAx);
    handles.imgHandle=imgHandle;
    colormap(handles.imgAx,'gray')
    set(handles.imgAx,'xtick',[],'ytick',[])
    currLim = get(handles.imgAx,'CLim');
    if currLim(1) == 0
        currLim(1) = 1;
    end
    set(handles.minSlider,'Value',log2(currLim(1)));
    set(handles.maxSlider,'Value',log2(currLim(2)));

    %%% Populate ROI table if available



    if isfield(handles,'ROIvals')
        oldROIvals = handles.ROIvals;
        for k = 1:length(oldROIvals(:,1))
            if ~isempty(oldROIvals{k,4})
                hand = oldROIvals{k,4};
                delete(hand);
            end
        end
        handles = rmfield(handles,'ROIvals');
%         delete(handles.ROIvals);
%         handles.ROIvals = {[],[],[],[]};
        set(handles.listbox1,'Value',1)
        set(handles.listbox1,'String','<no ROI>')
        set(handles.indexSlider,'Value',1);
        
    end

    % check if there are already ROI in the ROIinfo variable
    thisPosROIinfo = handles.ROIinfo{posIndex};

    if ~isempty(thisPosROIinfo)
        hold on;
        ROIvals = thisPosROIinfo;

        if ~isempty(ROIvals{1,1})
            roiXY = ROIvals{1,3};
            hp = plot(roiXY(:,1),roiXY(:,2),'*-g','LineWidth',1.5);
            ROIvals{1,4} = hp;
        end
        for k = 2:length(ROIvals(:,1))
            roiXY = ROIvals{k,3};
            hp = plot(roiXY(:,1),roiXY(:,2),'*-r','LineWidth',1.5);
            ROIvals{k,4} = hp;
        end
        handles.ROIvals = ROIvals;



        contents = handles.ROIvals(:,2);
        if isempty(contents{1})
            contents = contents(2:end);
        end
        set(handles.listbox1,'String',contents)
        set(handles.listbox1,'Value',length(contents))
    end

    % Update handles structure
    guidata(hObject, handles);
        






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

posIndex = get(handles.imgPosPuMenu,'Value');
channelIndex = get(handles.chPUmenu,'Value');

posImgStack = handles.initImgCell{posIndex}{4};
imgHandle = imagesc(posImgStack(:,:,channelIndex),'Parent',handles.imgAx);
handles.imgHandle=imgHandle;
colormap(handles.imgAx,'gray')
set(handles.imgAx,'xtick',[],'ytick',[])
currLim = get(handles.imgAx,'CLim');
if currLim(1) == 0
    currLim(1) = 1;
end
set(handles.minSlider,'Value',log2(currLim(1)));
set(handles.maxSlider,'Value',log2(currLim(2)));

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
end
contentsGr = cellstr(get(handles.imgPosPuMenu,'String'));
grName = contentsGr{get(handles.imgPosPuMenu,'Value')};

contentsCh = cellstr(get(handles.chPUmenu,'String'));
chName = contentsCh{get(handles.chPUmenu,'Value')};
handles.grName = grName;
handles.chName = chName;

MD = handles.MD;
MDvtab = handles.MDvtab;

ImgInds = MDvtab.group == grName & MDvtab.Channel == chName;
handles.ImgInds = ImgInds;
imgNames = MD.ImgFiles(ImgInds);
nImages = length(imgNames);
handles.imgNames = imgNames;
handles.globalIndex = find(strcmp(MD.ImgFiles,imgNames{1})); 
imgIn = imread([MD.basepth,'\',imgNames{1}]);
imgHandle = imagesc(imgIn,'Parent',handles.imgAx);
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
% set(handles.imgAx,'CLim',[0 2^16])
firstInd = find(ImgInds,1);
if ~isempty(MDvtab.RoiSet{firstInd})
    hold on;
    ROIvals = MDvtab.RoiSet{firstInd};
    
    if ~isempty(ROIvals{1,1})
        roiXY = ROIvals{1,3};
        hp = plot(roiXY(:,1),roiXY(:,2),'*-g','LineWidth',1.5);
        ROIvals{1,4} = hp;
    end
    for k = 2:length(ROIvals(:,1))
        roiXY = ROIvals{k,3};
        hp = plot(roiXY(:,1),roiXY(:,2),'*-r','LineWidth',1.5);
        ROIvals{k,4} = hp;
    end
    handles.ROIvals = ROIvals;
        


contents = handles.ROIvals(:,2);
if isempty(contents{1})
    contents = contents(2:end);
end
set(handles.listbox1,'String',contents)
set(handles.listbox1,'Value',length(contents))

end

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

imgIndex = get(handles.indexSlider,'Value');

imgNameNew = handles.imgNames{round(imgIndex)};
MD = handles.MD;
imgIn = imread([MD.basepth,'\',imgNameNew]);
newHand = imagesc(imgIn,'Parent',handles.imgAx);
delete(handles.imgHandle)
handles.imgHandle = newHand;
currMin = get(handles.minSlider,'Value');
currMax = get(handles.maxSlider,'Value');

set(handles.imgAx,'CLim',[2^currMin 2^currMax]);
set(handles.imgAx,'xtick',[],'ytick',[])

set(handles.indText,'String',num2str(round(imgIndex)))

MDvtab = handles.MDvtab;
globalIndex = find(strcmp(MD.ImgFiles,imgNameNew));
handles.globalIndex = globalIndex; 
IndROI = MDvtab.RoiSet{globalIndex};
if isfield(handles,'ROIvals')
    allROI = handles.ROIvals;
    for k = 1:length(allROI(:,1))
        if ~isempty(allROI{k,4})
            hand = allROI{k,4};
            if max(max(IndROI{k,3}~=allROI{k,3}))
                roiXY = IndROI{k,3};
                set(hand,'XData',roiXY(:,1),'YData',roiXY(:,2))
                allROI{k,3} =  IndROI{k,3};
                
            end
            uistack(hand,'top')
        end
    end
    handles.ROIvals = allROI;
end

if max(strcmp(MDvtab.Properties.VariableNames,'Skip'))
    skipVal = MDvtab.Skip(globalIndex);
    set(handles.skipImgBox,'Value',skipVal);
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
            [xin,yin,button]=ginput(1);
            xv = [xv,round(xin)];
            yv = [yv,round(yin)];
            if length(xv)>1
                set(hp,'XData',xv,'YData',yv)
                %         plot(xv(end-1:end),yv(end-1:end),'r-*','LineWidth',2)
            elseif length(xv)==1
                hp = plot(xv(end),yv(end),'r-*','LineWidth',1.5);
            end
            
        end
    case 'Rect'
        [xin,yin,button]=ginput(1);
        xv = round(xin);
        yv = round(yin);
        hp = plot(xv,yv,'r-*','LineWidth',1.5);
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

if ~isfield(handles,'ROIvals')
    nextName = 'ROI 1';
    handles.ROIvals(2,:) = {1,nextName, roiMat, hp};
else
    ROIvals = handles.ROIvals;
    maxNumROI = max(cell2mat(ROIvals(:,1)));
    nextName=['ROI ',num2str(maxNumROI+1)];
    ROIvals(length(ROIvals(:,1))+1,:)={maxNumROI+1,nextName,roiMat,hp};
    handles.ROIvals = ROIvals;
end
    
contents = handles.ROIvals(:,2);
if isempty(contents{1})
    contents = contents(2:end);
end
set(handles.listbox1,'String',contents)
set(handles.listbox1,'Value',length(contents))


posIndex = get(handles.imgPosPuMenu,'Value');
handles.ROIinfo{posIndex} = handles.ROIvals(:,1:3);
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
    ROIcell = handles.ROIvals;
    ROIstr= ROIcell(:,2);
    
    Ind = strcmp(allStr(index_selected),ROIstr);
    
    htoCh =ROIcell{Ind,4};
    set(htoCh,'Color',[0 0 1])
    hnoCh = ROIcell(~strcmp(allStr(index_selected),ROIstr),4);
    for k = 1:length(hnoCh)
        set(hnoCh{k},'Color',[1 0 0]);
    end
    hbkgr = ROIcell{1,4};
    if ~isempty(hbkgr)
        if hbkgr ~= htoCh
            set(hbkgr,'Color',[0 1 0]);
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
hold on;
getPolyToggle = get(handles.polyToggle,'Value');
if isfield(handles,'ROIvals')
    if ~isempty(handles.ROIvals{1,1})
        htoDel = handles.ROIvals{1,4};
        delete(htoDel)
    end
end
% getPolyToggle = 1;
if getPolyToggle==1
    typeOpt = 'Poly';
else
    typeOpt = 'Rect';
end
switch typeOpt
    case 'Poly'
        while button == 1
            [xin,yin,button]=ginput(1);
            xv = [xv,round(xin)];
            yv = [yv,round(yin)];
            if length(xv)>1
                set(hp,'XData',xv,'YData',yv)
                %         plot(xv(end-1:end),yv(end-1:end),'r-*','LineWidth',2)
            elseif length(xv)==1
                hp = plot(xv(end),yv(end),'g-*','LineWidth',1.5);
            end
            
        end
    case 'Rect'
        [xin,yin,button]=ginput(1);
        xv = round(xin);
        yv = round(yin);
        hp = plot(xv,yv,'g-*','LineWidth',1.5);
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

if ~isfield(handles,'ROIvals')
    handles.ROIvals = {0,'Background', roiMat, hp};
else
    ROIvals = handles.ROIvals;
    ROIvals(1,:)={0,'Background',roiMat,hp};
    handles.ROIvals = ROIvals;
end
    
contents = handles.ROIvals(:,2);
set(handles.listbox1,'String',contents)

posIndex = get(handles.imgPosPuMenu,'Value');
handles.ROIinfo{posIndex} = handles.ROIvals(:,1:3);

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


% --- Executes on button press in delROIbutton.
function delROIbutton_Callback(hObject, eventdata, handles)
% hObject    handle to delROIbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

index_selected = get(handles.listbox1,'Value');
allStr= get(handles.listbox1,'String');
ROIcell = handles.ROIvals;
ROIstr =  ROIcell(:,2);
Ind = strcmp(allStr(index_selected),ROIstr);

htoDel = ROIcell{Ind,4};
delete(htoDel);
indNum = find(Ind);
if indNum == 1
    ROIcell(1,:)={[],[],[],[]};
else
    ROIcell(Ind,:) = [];
end
handles.ROIvals = ROIcell;

set(handles.listbox1,'Value',1);
set(handles.listbox1,'String', allStr(~Ind));

posIndex = get(handles.imgPosPuMenu,'Value');
handles.ROIinfo{posIndex} = handles.ROIvals(:,1:3);

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

if get(handles.shiftROIcheck,'Value')
    shiftValStrAll = cellstr(get(handles.roiShiftMenu,'String'));
    shiftValStr = shiftValStrAll{get(handles.roiShiftMenu,'Value')};
    shiftDist = str2num(shiftValStr);
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
    MD = handles.MD;
    MDvtab = handles.MDvtab;
    globalIndex = handles.globalIndex;
    currGrp = MDvtab.group(globalIndex);
    currFrame = MDvtab.frame(globalIndex);
    IndsToChange = find(MDvtab.group==currGrp & MDvtab.frame>=currFrame);
    
    MD.addToImages(IndsToChange,'RoiSet',ROIvals(:,1:3))
    MDvtab.RoiSet(IndsToChange) = {ROIvals(:,1:3)};
    handles.MDvtab = MDvtab;
    saveMetadata(MD,MD.basepth)
    handles.MD = MD;
    
end

guidata(hObject, handles);

% --- Executes on button press in roiLEFTbutton.
function roiLEFTbutton_Callback(hObject, eventdata, handles)
% hObject    handle to roiLEFTbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

if get(handles.shiftROIcheck,'Value')
    shiftValStrAll = cellstr(get(handles.roiShiftMenu,'String'));
    shiftValStr = shiftValStrAll{get(handles.roiShiftMenu,'Value')};
    shiftDist = str2num(shiftValStr);
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
    MD = handles.MD;
    MDvtab = handles.MDvtab;
    globalIndex = handles.globalIndex;
    currGrp = MDvtab.group(globalIndex);
    currFrame = MDvtab.frame(globalIndex);
    IndsToChange = find(MDvtab.group==currGrp & MDvtab.frame>=currFrame);
    
    MD.addToImages(IndsToChange,'RoiSet',ROIvals(:,1:3))
    MDvtab.RoiSet(IndsToChange) = {ROIvals(:,1:3)};
    handles.MDvtab = MDvtab;
    saveMetadata(MD,MD.basepth)
    handles.MD = MD;
    
end

guidata(hObject, handles);

% --- Executes on button press in roiRIGHTbutton.
function roiRIGHTbutton_Callback(hObject, eventdata, handles)
% hObject    handle to roiRIGHTbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

if get(handles.shiftROIcheck,'Value')
    shiftValStrAll = cellstr(get(handles.roiShiftMenu,'String'));
    shiftValStr = shiftValStrAll{get(handles.roiShiftMenu,'Value')};
    shiftDist = str2num(shiftValStr);
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
    MD = handles.MD;
    MDvtab = handles.MDvtab;
    globalIndex = handles.globalIndex;
    currGrp = MDvtab.group(globalIndex);
    currFrame = MDvtab.frame(globalIndex);
    IndsToChange = find(MDvtab.group==currGrp & MDvtab.frame>=currFrame);
    
    MD.addToImages(IndsToChange,'RoiSet',ROIvals(:,1:3))
    MDvtab.RoiSet(IndsToChange) = {ROIvals(:,1:3)};
    handles.MDvtab = MDvtab;
    saveMetadata(MD,MD.basepth)
    handles.MD = MD;
    
end

guidata(hObject, handles);

% --- Executes on button press in roiDOWNbutton.
function roiDOWNbutton_Callback(hObject, eventdata, handles)
% hObject    handle to roiDOWNbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

if get(handles.shiftROIcheck,'Value')
    shiftValStrAll = cellstr(get(handles.roiShiftMenu,'String'));
    shiftValStr = shiftValStrAll{get(handles.roiShiftMenu,'Value')};
    shiftDist = str2num(shiftValStr);
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
    MD = handles.MD;
    MDvtab = handles.MDvtab;
    globalIndex = handles.globalIndex;
    currGrp = MDvtab.group(globalIndex);
    currFrame = MDvtab.frame(globalIndex);
    IndsToChange = find(MDvtab.group==currGrp & MDvtab.frame>=currFrame);
    
    MD.addToImages(IndsToChange,'RoiSet',ROIvals(:,1:3))
    MDvtab.RoiSet(IndsToChange) = {ROIvals(:,1:3)};
    handles.MDvtab = MDvtab;
    saveMetadata(MD,MD.basepth)
    handles.MD = MD;
    
end

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


nPos = length(handles.ROIinfo);
sx = handles.sx;
sy = handles.sy;
for k = 1:nPos
    ROIgrp = handles.ROIinfo{k};
    allMasks = {};
    if ~isempty(ROIgrp)
            
        
        for m = 2:length(ROIgrp(:,1))
            roiXY = ROIgrp{m,3};
            mask = poly2mask(roiXY(:,1),roiXY(:,2),sx,sy);
%             allMasks(:,:,m) = mask; 
            allMasks{m} = find(mask); 
        end
        
        
        if ~isempty(ROIgrp{1,3})
            roiXY = ROIgrp{1,3};
            mask = poly2mask(roiXY(:,1),roiXY(:,2),sx,sy);
%             allMasks(:,:,1) = mask; 
            allMasks{1} = find(mask);
        end
        handles.initImgCell{k}{6} = allMasks;
    end
    
    handles.initImgCell{k}{5} = ROIgrp;

end

% handles.Scp.MD.LiveROIdata =[handles.Scp.MD.NonImageBasedData;{'ROIdata', handles.initImgCell}];
for k = 1:length(handles.initImgCell)

    handles.Scp.MD.LiveROIdata(k,1:5) = handles.initImgCell{k}([1:3,5,6]);
%     handles.Scp.MD.LiveROIdata(k,1:6) = handles.initImgCell{k};
end
guidata(hObject, handles);





close(handles.AcqROImainFrame);



% --- Executes on button press in skipImgBox.
function skipImgBox_Callback(hObject, eventdata, handles)
% hObject    handle to skipImgBox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of skipImgBox

skipValue = get(hObject,'Value');

MD = handles.MD;
MDvtab = handles.MDvtab;

frameIndex = handles.globalIndex;


frNumber = MDvtab.frame(frameIndex);
grpName = MDvtab.group(frameIndex);
allChValsInd = find(MDvtab.group==grpName & MDvtab.frame == frNumber);
for m = 1:length(allChValsInd)
    MDvtab.Skip(allChValsInd(m)) = skipValue;
    MD.addToImages(allChValsInd(m),'Skip',skipValue);
end
handles.MDvtab = MDvtab;
handles.MD = MD;
saveMetadata(MD,MD.basepth)
guidata(hObject, handles);


% --- Executes when user attempts to close AcqROImainFrame.
function AcqROImainFrame_CloseRequestFcn(hObject, eventdata, handles)
% hObject    handle to AcqROImainFrame (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


uiresume(handles.AcqROImainFrame)
% Hint: delete(hObject) closes the figure
delete(hObject);
