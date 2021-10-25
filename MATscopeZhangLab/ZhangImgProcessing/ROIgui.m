function varargout = ROIgui(varargin)
% global mmc
% ROIGUI MATLAB code for ROIgui.fig
%      ROIGUI, by itself, creates a new ROIGUI or raises the existing
%      singleton*.
%
%      H = ROIGUI returns the handle to a new ROIGUI or the handle to
%      the existing singleton*.
%
%      ROIGUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in ROIGUI.M with the given input arguments.
%
%      ROIGUI('Property','Value',...) creates a new ROIGUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before ROIgui_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to ROIgui_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help ROIgui

% Last Modified by GUIDE v2.5 09-Nov-2015 20:46:20

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @ROIgui_OpeningFcn, ...
                   'gui_OutputFcn',  @ROIgui_OutputFcn, ...
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

% --- Executes just before ROIgui is made visible.
function ROIgui_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to ROIgui (see VARARGIN)

% Choose default command line output for ROIgui
handles.output = hObject;
% micromanager core handle 
Scp = varargin{1};
handles.core = Scp.mmc; 
handles.MMgui = Scp.gui;
% Update handles structure
guidata(hObject, handles);

% This sets up the initial plot - only do when we are invisible
% so window can get raised using ROIgui.
if strcmp(get(hObject,'Visible'),'off')
    plot(rand(5));
end



% UIWAIT makes ROIgui wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = ROIgui_OutputFcn(hObject, eventdata, handles)
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;

% --- Executes on button press in newROI.
function newROI_Callback(hObject, eventdata, handles)
% hObject    handle to newROI (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% axes(handles.axes1);
% cla;
% 
% popup_sel_index = get(handles.popupmenu1, 'Value');
% switch popup_sel_index
%     case 1
%         plot(rand(5));
%     case 2
%         plot(sin(1:0.01:25.99));
%     case 3
%         bar(1:.5:10);
%     case 4
%         plot(membrane);
%     case 5
%         surf(peaks);
% end

button  = 1;

xv =[];
yv=[];
hold on;
getPolyToggle = get(handles.polyToggle,'Value');
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
                hp = plot(xv(end),yv(end),'r-*','LineWidth',2);
            end
            
        end
    case 'Rect'
        [xin,yin,button]=ginput(1);
        xv = round(xin);
        yv = round(yin);
        hp = plot(xv,yv,'r-*','LineWidth',2);
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
% plot(xv([1,end]),yv([1,end]),'r-*','LineWidth',2)
% testrand = round(rand()*100);
contents = get(handles.listbox1,'String');

if strcmp(contents,'<no ROI>')
    nextHandle='ROI 1';
    set(handles.listbox1,'String',nextHandle)
else
    if iscell(contents)
        nStr = length(contents);
        nextHandle=['ROI ',num2str(nStr+1)];
        contents{nStr+1} = nextHandle;
    else
        nextHandle='ROI 2';
        contents = {contents,nextHandle};
    end
    set(handles.listbox1,'String',contents)
end
roiMat = [xv',yv'];
if isstruct(handles.newROI.UserData)
    roiStruct = handles.newROI.UserData;
    nEntries = length(roiStruct);
    roiStruct(nEntries+1).names =  nextHandle;
    roiStruct(nEntries+1).roiMatrix =  roiMat;
    roiStruct(nEntries+1).plotH =  hp;
else
    roiStruct = struct('names',nextHandle,'roiMatrix',roiMat,'plotH',hp);
end
handles.newROI.UserData=roiStruct;
% set(handles.listbox1,'String',num2str(testrand))


% --------------------------------------------------------------------
function FileMenu_Callback(hObject, eventdata, handles)
% hObject    handle to FileMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function OpenMenuItem_Callback(hObject, eventdata, handles)
% hObject    handle to OpenMenuItem (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
file = uigetfile('*.fig');
if ~isequal(file, 0)
    open(file);
end

% --------------------------------------------------------------------
function PrintMenuItem_Callback(hObject, eventdata, handles)
% hObject    handle to PrintMenuItem (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
printdlg(handles.figure1)

% --------------------------------------------------------------------
function CloseMenuItem_Callback(hObject, eventdata, handles)
% hObject    handle to CloseMenuItem (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
selection = questdlg(['Close ' get(handles.figure1,'Name') '?'],...
                     ['Close ' get(handles.figure1,'Name') '...'],...
                     'Yes','No','Yes');
if strcmp(selection,'No')
    return;
end

delete(handles.figure1)


% --- Executes on selection change in popupmenu1.
function popupmenu1_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenu1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = get(hObject,'String') returns popupmenu1 contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupmenu1


% --- Executes during object creation, after setting all properties.
function popupmenu1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenu1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
     set(hObject,'BackgroundColor','white');
end

set(hObject, 'String', {'plot(rand(5))', 'plot(sin(1:0.01:25))', 'bar(1:.5:10)', 'plot(membrane)', 'surf(peaks)'});


% --- Executes on selection change in listbox1.
function listbox1_Callback(hObject, eventdata, handles)
% hObject    handle to listbox1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns listbox1 contents as cell array
%        contents{get(hObject,'Value')} returns selected item from listbox1

index_selected = get(handles.listbox1,'Value');
allStr= get(handles.listbox1,'String');
ROIstruct = handles.newROI.UserData;
ROIstr =  {ROIstruct.names};
Ind = strcmp(allStr(index_selected),ROIstr);

htoCh = ROIstruct(Ind).plotH;
set(htoCh,'Color',[0 0 1])
hnoCh = {ROIstruct(~strcmp(allStr(index_selected),ROIstr)).plotH};
for k = 1:length(hnoCh)
    set(hnoCh{k},'Color',[1 0 0]);
end
hbkgr = ROIstruct(strcmp('Background',ROIstr)).plotH;
if hbkgr ~= htoCh
    set(hbkgr,'Color',[0 1 0]);
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


% --- Executes on button press in snapButton.
function snapButton_Callback(hObject, eventdata, handles)
% hObject    handle to snapButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% global mmc
mmc = handles.core;
axes(handles.axes1);
cla;

mmc.snapImage();                    %Take the image
img=mmc.getImage();                 %Retrieve Image
width=mmc.getImageWidth();          %Get width and height for reshaping
height=mmc.getImageHeight();
if mmc.getBytesPerPixel==2
    pixelType='uint16';
else
    pixelType='uint8';
end
img=typecast(img,pixelType);        %Cast
img=reshape(img, [width, height]);
img=transpose(img);
imshow(img);                     %Draw to axes with autoscale


% --- Executes on button press in delROI.
function delROI_Callback(hObject, eventdata, handles)
% hObject    handle to delROI (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

index_selected = get(handles.listbox1,'Value');
allStr= get(handles.listbox1,'String');
ROIstruct = handles.newROI.UserData;
ROIstr =  {ROIstruct.names};
Ind = strcmp(allStr(index_selected),ROIstr);

htoDel = ROIstruct(Ind).plotH;
delete(htoDel);
ROIstruct(Ind) = [];
handles.newROI.UserData =ROIstruct;
set(handles.listbox1,'Value',1);
set(handles.listbox1,'String', allStr(~Ind));


% --- Executes on button press in bkgrROI.
function bkgrROI_Callback(hObject, eventdata, handles)
% hObject    handle to bkgrROI (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

button  = 1;

xv =[];
yv=[];
hold on;
getPolyToggle = get(handles.polyToggle,'Value');
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
                hp = plot(xv(end),yv(end),'g-*','LineWidth',2);
            end
            
        end
        xv = [xv,xv(1)];
        yv = [yv,yv(1)];
    case 'Rect'
        [xin,yin,button]=ginput(1);
        xv = round(xin);
        yv = round(yin);
        hp = plot(xv,yv,'g-*','LineWidth',2);
        [xin,yin,button]=ginput(1);
        xin = round(xin);
        yin = round(yin);
        xv = [xv, xv, xin, xin, xv];
        yv = [yv, yin, yin, yv, yv];
        set(hp,'XData',xv,'YData',yv)
end
set(hp,'XData',xv,'YData',yv)
% plot(xv([1,end]),yv([1,end]),'r-*','LineWidth',2)
% testrand = round(rand()*100);

roiMat = [xv',yv'];

if isstruct(handles.newROI.UserData)
    contents = get(handles.listbox1,'String');
    roiStruct = handles.newROI.UserData;
    ROIstr =  {roiStruct.names};
    Ind = find(strcmp('Background',ROIstr)==1);
    if ~isempty(Ind)
        oldH = roiStruct(Ind).plotH;
        delete(oldH);
%         roiStruct(Ind).names =  'Background';
        roiStruct(Ind).roiMatrix =  roiMat;
        roiStruct(Ind).plotH =  hp;
    else
        nEntries = length(roiStruct);
        roiStruct(nEntries+1).names =  'Background';
        roiStruct(nEntries+1).roiMatrix =  roiMat;
        roiStruct(nEntries+1).plotH =  hp;
        if iscell(contents)
            contents{nEntries+1} = 'Background';
        else
            contents = {contents,'Background'};
        end
        set(handles.listbox1,'String',contents)
    end
else
    roiStruct = struct('names','Background','roiMatrix',roiMat,'plotH',hp);
    set(handles.listbox1,'String','Background')
end

handles.newROI.UserData=roiStruct;


% --- Executes on button press in rectToggle.
function rectToggle_Callback(hObject, eventdata, handles)
% hObject    handle to rectToggle (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of rectToggle
set(handles.polyToggle,'Value',0)


% --- Executes on button press in polyToggle.
function polyToggle_Callback(hObject, eventdata, handles)
% hObject    handle to polyToggle (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of polyToggle
set(handles.rectToggle,'Value',0)


% --- Executes on button press in endButton.
function endButton_Callback(hObject, eventdata, handles)
% hObject    handle to endButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

assignin('base','ROIstuct',handles.newROI.UserData)
close(gcf);


% --- Executes on button press in liveButton.
function liveButton_Callback(hObject, eventdata, handles)
% hObject    handle to liveButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

handles.MMgui.enableLiveMode(1);
