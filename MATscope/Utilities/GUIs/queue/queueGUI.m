function varargout = queueGUI(varargin)
% QUEUEGUI MATLAB code for queueGUI.fig
%      QUEUEGUI, by itself, creates a new QUEUEGUI or raises the existing
%      singleton*.
%
%      H = QUEUEGUI returns the handle to a new QUEUEGUI or the handle to
%      the existing singleton*.
%
%      QUEUEGUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in QUEUEGUI.M with the given input arguments.
%
%      QUEUEGUI('Property','Value',...) creates a new QUEUEGUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before queueGUI_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to queueGUI_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help queueGUI

% Last Modified by GUIDE v2.5 17-Apr-2017 16:32:48

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @queueGUI_OpeningFcn, ...
                   'gui_OutputFcn',  @queueGUI_OutputFcn, ...
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


% --- Executes just before queueGUI is made visible.
function queueGUI_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to queueGUI (see VARARGIN)

% Choose default command line output for queueGUI
handles.output = hObject;

% Set Scope handle
handles.Scp = varargin{1};

% Get queue if it is set
queue = handles.Scp.Sched.queue;
sortQueue = sortrows(queue,'order');
NameVals = sortQueue.name;

handles.isStarted = 0;

% Add listener for changes in the queue
handlerFN = @(x,y) (updateListOnChange(x,y,handles));
handles.chListener = event.listener(handles.Scp.Sched,'queueChanged',handlerFN);

% Add listener for updates in the time remaing in the step of the queue
handlerFN_clock = @(x,y) (updateClockOnChange(x,y,handles));
handles.clockListener = event.listener(handles.Scp.Sched,'tDiffUpdated',handlerFN_clock);



% Run for initial setup;
handlerFN(handles.Scp.Sched,[])
% set(handles.queueList,'String',NameVals);

% Populate events listbox
eventsListToListbox(handles)

% Populate dropdown
handles.unitList.String = {'uM';'N/A';'nM';'mM';'mL';'uL';'nmole';'umole';...
    'mg';'ug';'ng';'U'};

% Turn off ability to mark on startup
handles.btnMarkAndPause.Enable = 'off';
handles.btnAddMarkPause.Enable = 'off';
handles.btnMarkEvent.Enable = 'off';
handles.btnAddAndMark.Enable = 'off';


% Update handles structure

guidata(hObject, handles);

% UIWAIT makes queueGUI wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = queueGUI_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;

% --- updates the list when the queue gets updated
function updateListOnChange(Sched,src,guiHandles)
% Function to update the whole queue.

% Get updated queue
queue =Sched.queue;

% Gray out start queue if already started
if queue.status(queue.ID ==1)=='Completed'
    guiHandles.startQueueBtn.Enable = 'off';
    guiHandles.btnMarkAndPause.Enable = 'on';
    guiHandles.btnAddMarkPause.Enable = 'on';
    guiHandles.btnMarkEvent.Enable = 'on';
    guiHandles.btnAddAndMark.Enable = 'on';
else
    guiHandles.startQueueBtn.Enable = 'on';
    guiHandles.btnMarkAndPause.Enable = 'off';
    guiHandles.btnAddMarkPause.Enable = 'off';
    guiHandles.btnMarkEvent.Enable = 'off';
    guiHandles.btnAddAndMark.Enable = 'off';
end
sortQueue = sortrows(queue,'order');
NameVals = sortQueue.name;

% Update whole queue list
if guiHandles.isStarted ==0 || height(sortQueue)==1
for k = 1:height(sortQueue)
    if sortQueue.type(k)=='Initilaization'
        baseText = ['*',sortQueue.name{k}, '*'];
    elseif sortQueue.type(k)=='PrimeIter'
        baseText = ['=== ',sortQueue.name{k}, ' ==='];
    elseif sortQueue.type(k)=='TimePoint'
        baseText = ['~ ',sortQueue.name{k}, ' ~'];
    else
        baseText = [num2str(sortQueue.timeOrder(k)), ' - ', sortQueue.name{k}];
%         if sortQueue.timePoint(k) ==0
%             baseText = [num2str(sortQueue.timeOrder(k)-1), ' - ', sortQueue.name{k}];
%         else
%             baseText = [num2str(sortQueue.timeOrder(k)), ' - ', sortQueue.name{k}];
%         end
    end
    
    compStatus = sortQueue.status(k);
    if compStatus == 'Completed'
        textList{k} = ['<HTML><BODY bgcolor="green">',baseText,'</BODY></HTML>'];
    else
        textList{k} = ['<HTML><BODY>',baseText,'</BODY></HTML>'];
    end
end
set(guiHandles.queueList,'String',textList);
end

% Move cursor
if Sched.currInd ~= 0
    currRowNum = find(sortQueue.order == Sched.currInd,1,'first');
    if ~isempty(currRowNum)
        set(guiHandles.queueList,'Value',currRowNum);
    end
else 
    set(guiHandles.queueList,'Value',1);
end

% Update List
drawnow;

% rowNum = find(Sched.queue.order == Sched.currInd,1,'first');
% baseText = Sched.queue.name{rowNum-1};
% getList = get(guiHandles.queueList,'String');
% getList{rowNum-1} = ['<HTML><BODY bgcolor="green">',baseText,'</BODY></HTML>'];
% set(guiHandles.queueList,'String',getList);
% set(guiHandles.queueList,'Value',rowNum);
% drawnow;
% bob=1;

% --- Executes on selection change in queueList.
function queueList_Callback(hObject, eventdata, handles)
% hObject    handle to queueList (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns queueList contents as cell array
%        contents{get(hObject,'Value')} returns selected item from queueList


% --- Executes during object creation, after setting all properties.
function queueList_CreateFcn(hObject, eventdata, handles)
% hObject    handle to queueList (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in startQueueBtn.
function startQueueBtn_Callback(hObject, eventdata, handles)
% hObject    handle to startQueueBtn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% clear the previous event listener
delete(handles.chListener);

% Set that the queue is running to 1. 
handles.isStarted = 1;

% Add listener for changes in the queue
handlerFN = @(x,y) (updateListOnChange(x,y,handles));
handles.chListener = event.listener(handles.Scp.Sched,'queueChanged',handlerFN);


handles.Scp.acquireQueue();
guidata(hObject, handles);

% --- Executes on button press in pauseBtn.
function pauseBtn_Callback(hObject, eventdata, handles)
% hObject    handle to pauseBtn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

getValue = handles.pauseBtn.Value;

if getValue ==1
    handles.Scp.Sched.pause;
    handles.pauseBtn.String = 'Resume Queue';
    handles.pauseBtn.BackgroundColor = 'r';
    handles.btnMarkAndPause.Enable = 'off';
    handles.btnAddMarkPause.Enable = 'off';
elseif getValue == 0
    handles.Scp.Sched.resume;
    handles.pauseBtn.String = 'Pause Queue';
    handles.pauseBtn.BackgroundColor = [0.94 0.94 0.94];
    handles.btnMarkAndPause.Enable = 'on';
    handles.btnAddMarkPause.Enable = 'on';
end

% --- Executes on button press in deleteBtn.
function deleteBtn_Callback(hObject, eventdata, handles)
% hObject    handle to deleteBtn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on button press in addBtn.
function addBtn_Callback(hObject, eventdata, handles)
% hObject    handle to addBtn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on button press in clearBtn.
function clearBtn_Callback(hObject, eventdata, handles)
% hObject    handle to clearBtn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

handles.Scp.Sched.pause;
handles.Scp.Sched.clearQueue;

% clear the previous event listener
delete(handles.chListener);

% Set that the queue is running to 1. 
handles.isStarted = 0;

% Add listener for changes in the queue
handlerFN = @(x,y) (updateListOnChange(x,y,handles));
handles.chListener = event.listener(handles.Scp.Sched,'queueChanged',handlerFN);

% Reset pause button
handles.pauseBtn.String = 'Pause Queue';
handles.pauseBtn.BackgroundColor = [0.94 0.94 0.94];
    
guidata(hObject, handles);

% --- Executes on button press in resumeBtn.
function resumeBtn_Callback(hObject, eventdata, handles)
% hObject    handle to resumeBtn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

handles.Scp.Sched.resume;


% --- Executes during object deletion, before destroying properties.
function queueList_DeleteFcn(hObject, eventdata, handles)
% hObject    handle to queueList (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

delete(handles.chListener);

function updateClockOnChange(Sched,src,guiHandles)
    
    % Get time diff;
    tDiff = Sched.timeToNext;
    
    % Check if negative
    if tDiff<=0
        tDiffStr = '00:00.0';
    else
    % Convert to string
        tDiffStr = datestr(round(tDiff*24*3600,1)/24/3600,'MM:SS.FFF');
        tDiffStr = tDiffStr(1:end-1);
    end
    
    guiHandles.timerText.String = tDiffStr;
    


% --- Executes on selection change in eventList.
function eventList_Callback(hObject, eventdata, handles)
% hObject    handle to eventList (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns eventList contents as cell array
%        contents{get(hObject,'Value')} returns selected item from eventList

% Get table ind of the selection
selInd = get(handles.eventList,'Value');

eventListAll = handles.Scp.eventsTable;
% Populate the text boxes with the text from this line
handles.pertText.String = eventListAll.Desc{selInd};
handles.concText.String = num2str(eventListAll.Conc(selInd));

unitStr = eventListAll.Units{selInd};

unitContents = get(handles.unitList,'String'); 
unitInd = find(strcmp(unitStr,unitContents));
handles.unitList.Value = unitInd;

% Update handles structure
guidata(hObject, handles);


% --- Executes during object creation, after setting all properties.
function eventList_CreateFcn(hObject, eventdata, handles)
% hObject    handle to eventList (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in btnMarkAndPause.
function btnMarkAndPause_Callback(hObject, eventdata, handles)
% hObject    handle to btnMarkAndPause (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Mark the event
btnMarkEvent_Callback(hObject, eventdata, handles)
% Pause the queue
handles.Scp.Sched.pause;
handles.pauseBtn.Value = 1;
handles.pauseBtn.String = 'Resume Queue';
handles.pauseBtn.BackgroundColor = 'r';



% --- Executes on button press in btnMarkEvent.
function btnMarkEvent_Callback(hObject, eventdata, handles)
% hObject    handle to btnMarkEvent (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get table ind of the selection
selInd = get(handles.eventList,'Value');

eventListAll = handles.Scp.eventsTable;
% Populate the text boxes with the text from this line
descStr = eventListAll.Desc{selInd};
concNum = eventListAll.Conc(selInd);
unitStr = eventListAll.Units{selInd};


% Add event to metadata
handles.Scp.MD.markEvent(descStr,concNum,unitStr,'Manual Input',handles.Scp.Pos.peek)


% --- Executes on button press in btnAddEventToList.
function btnAddEventToList_Callback(hObject, eventdata, handles)
% hObject    handle to btnAddEventToList (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

unitContents = get(handles.unitList,'String'); 
uintStr = unitContents{get(handles.unitList,'Value')};
  
addEventToList(handles,handles.pertText.String,handles.concText.String,uintStr)


% --- Executes on button press in btnAddAndMark.
function btnAddAndMark_Callback(hObject, eventdata, handles)
% hObject    handle to btnAddAndMark (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on button press in btnAddMarkPause.
function btnAddMarkPause_Callback(hObject, eventdata, handles)
% hObject    handle to btnAddMarkPause (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)



function pertText_Callback(hObject, eventdata, handles)
% hObject    handle to pertText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of pertText as text
%        str2double(get(hObject,'String')) returns contents of pertText as a double


% --- Executes during object creation, after setting all properties.
function pertText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to pertText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function concText_Callback(hObject, eventdata, handles)
% hObject    handle to concText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of concText as text
%        str2double(get(hObject,'String')) returns contents of concText as a double


% --- Executes during object creation, after setting all properties.
function concText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to concText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in unitList.
function unitList_Callback(hObject, eventdata, handles)
% hObject    handle to unitList (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns unitList contents as cell array
%        contents{get(hObject,'Value')} returns selected item from unitList


% --- Executes during object creation, after setting all properties.
function unitList_CreateFcn(hObject, eventdata, handles)
% hObject    handle to unitList (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in btnDelEvent.
function btnDelEvent_Callback(hObject, eventdata, handles)
% hObject    handle to btnDelEvent (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get table ind of the selection
selInd = get(handles.eventList,'Value');

if selInd ==1
    % don't delete the example event
    warndlg('Can''t delete the example event');
else
    handles.Scp.eventsTable(selInd,:) = [];
    eventsListToListbox(handles);
end

% Save the events list for this user
handles.Scp.saveEvents;
    

function eventsListToListbox(handles)
% generate the string required for the list box from the current events
% list

eventsList = handles.Scp.eventsTable;

nEvents = height(eventsList);

% Generate cell array of strings
for k = 1:nEvents
    eventsTextList{k} = [eventsList.Desc{k},' - ',num2str(eventsList.Conc(k)),' ',eventsList.Units{k}];
    
end

% Update listbox strings
handles.eventList.String = eventsTextList;

function addEventToList(handles,desc,conc,units)
% Adding a row to the events table

% Increment the ID number
nextId = max(handles.Scp.eventsTable.ID)+1;

% Convert conc to a number.
if ~isempty(conc)
    
    conc = str2double(conc);
    
    % Check that they didn't try to pass in some kind of text. 
    if isempty(conc)
        warndlg('Concentration must be a number or empty');
        return;
    end
end

% Generate new line of table
tempTable  = cell2table({nextId,desc,conc,units,'Manual Input'},...
            'VariableNames',{'ID','Desc','Conc','Units','Type'});
        
% Append table
handles.Scp.eventsTable = [handles.Scp.eventsTable;tempTable];

eventsListToListbox(handles);

% Save the events list for this user
handles.Scp.saveEvents;
