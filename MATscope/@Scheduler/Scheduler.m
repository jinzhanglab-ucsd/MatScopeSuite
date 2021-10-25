classdef Scheduler < handle
    
    events
        queueFinished
        nextTimePoint
        queueStepped
        queueChanged
        tDiffUpdated
    end
    
    properties
        
        tStart
        
        eventStat
        queue
        
        queueVarNames = {'ID','name','order','timePoint','timePointType','timeOrder','type','details','callback','status','sourcePointer','runFn','MDinfo'};
        
        currInd = 0; % Current index of the queue that is being run
        currLH;
        
        isPaused = 0;
        pauseTime;
        accumPauseTime=0;
        queueDispList;
        
        timeToNext = 0;
        
        %% Control Printing to command line
        verbose = 1;
        debugging = 0;
        
        %% pointer to Scope class
        parent;
        
    end
    
    methods
        function Sched = Scheduler(Scp,varargin)
            
            % Save pointer to parent scope
            Sched.parent = Scp;
            
            % Parse optional variables
            arg.verbose=1;
            arg.debugging =0;
            
            arg = parseVarargin(varargin,arg);
            
            % Set cmd line display settings
            Sched.verbose = arg.verbose;
            Sched.debugging = arg.debugging;
            
            
            Sched.queue = cell2table({1,'StartQueue',1,-1,'absolute',0,'Initilaization',{NaN},'none','queued',{Sched},'none',''});
            Sched.queue.Properties.VariableNames = Sched.queueVarNames;
            Sched.queue.type = categorical(Sched.queue.type);
            Sched.queue.status = categorical(Sched.queue.status);
            %Sched.queue.Properties.RowNames = Sched.queue.ID;
            
            % Add listeners
            
            
        end
        
        function addToQueue(Sched,name,timeInfo,timeOrder,type,details,callback,source,runFn,MDinfo,initPop)
            
            % Check if first row of queue and generate ID number
            if height(Sched.queue) == 0;
                IDnum = 1;
            else
                IDnum = max(Sched.queue.ID)+1;
            end
            
            % Number of rows being added (mostly a flag to add timepoint if
            % not already there)
            numRowsInsert = 1;
            
            
            if strcmp(type,'InitPopEnd')==1
                notify(Sched,'queueChanged');
            else
                % pull out time information stuff
                timeIn = timeInfo{1};
                timeType = timeInfo{2};
                
                % Find other events that have that time point value
                sameTimeRows = find(Sched.queue.timePoint == timeIn);
                
                % Check if other events that share that time point
                if isempty(sameTimeRows)
                    % There are no other events for this time point. Find the
                    % time point that preceeds it.
                    
                    % Check if this is a timepoint or the primary iterator
                    if strcmp(type,'PrimeIter') == 1 || strcmp(type,'TimePoint') == 1
                        preceedingRows = find(Sched.queue.timePoint<timeIn);
                        insertOrderNum  = max(Sched.queue.order(preceedingRows))+1;
                        insertShiftNum = insertOrderNum;
                        timePosIn = 0;
                    else
                        preceedingRows = find(Sched.queue.timePoint<timeIn);
                        insertTpOrderNum  = max(Sched.queue.order(preceedingRows))+1;
                        insertOrderNum  = max(Sched.queue.order(preceedingRows))+2;
                        insertShiftNum = insertTpOrderNum;
                        timePosIn = 1;
                        numRowsInsert = 2;
                        
                    end
                    
                else
                    % There are other events on that time point
                    
                    % Get the maximum order number and ind for this time point
                    [maxTimePosVal,maxTimeInd] = max(Sched.queue.timeOrder(sameTimeRows));
                    
                    % check timeOrder to see where to put this event relative
                    % to those others.
                    if timeOrder == -1 || (maxTimePosVal+1)==timeOrder
                        % Put at end
                        
                        timePosIn = maxTimePosVal+1;
                        insertOrderNum = Sched.queue.order(sameTimeRows(maxTimeInd))+1;
                        insertShiftNum = insertOrderNum;
                    elseif timeOrder>0 && mod(timeOrder,1) == 0 && maxTimePosVal>=timeOrder
                        % add into relative position given and
                        
                        bumpUpInd = find(Sched.queue.timeOrder(sameTimeRows)==timeOrder);
                        timePosIn = Sched.queue.timeOrder(sameTimeRows(bumpUpInd));
                        insertOrderNum = Sched.queue.order(sameTimeRows(bumpUpInd));
                        insertShiftNum = insertOrderNum;
                        
                        % Update other timeOrder numbers for other events
                        toBeBumped = find(Sched.queue.timeOrder(sameTimeRows)>=timeOrder);
                        Sched.queue.timeOrder(sameTimeRows(toBeBumped)) = Sched.queue.timeOrder(sameTimeRows(toBeBumped)) + 1;
                        
                    else
                        % return error for incorrect timeOrder variable
                        error('''timeOrder'' must be either -1 or an integer greater than zero but less than the number of events currently in that timepoint');
                        
                    end
                    
                end
                
                % Update the global order values
                orderRows = Sched.queue.order >= insertShiftNum;
                Sched.queue.order(orderRows) = Sched.queue.order(orderRows)+numRowsInsert;
                
                
                % If the source input is a string have it point to self
                if ischar(source)
                    source = Sched;
                end
                
                if numRowsInsert==2
                    % Create new table row
                    newRow = cell2table({IDnum+1,['Time point T=',num2str(timeIn)],insertTpOrderNum,timeIn,timeType,0,'PrimeIter',{},{},'queued',{Sched},'evalPlaceholder',''});
                    newRow.Properties.VariableNames = Sched.queueVarNames;
                    
                    % Append row to table
                    Sched.queue = [Sched.queue;newRow];
                end
                
                % Create new table row
                newRow = cell2table({IDnum,name,insertOrderNum,timeIn,timeType,timePosIn,type,details,callback,'queued',{source},runFn,MDinfo});
                newRow.Properties.VariableNames = Sched.queueVarNames;
                
                % Append row to table
                Sched.queue = [Sched.queue;newRow];
                
                
                
                % Event notification of any change to queue
                if initPop==0
                    notify(Sched,'queueChanged');
                end
                
            end
        end
        
        function deleteFromQueue(Sched,ID)
            
            % Get order number of event to be deleted
            delOrd = Sched.queue.order(Sched.queue.ID == ID);
            
            % Shift all the events below that up one.
            rows = Sched.queue.order > delOrd;
            Sched.queue.order(rows) = Sched.queue.order(rows)-1;
            
            % Delete row
            Sched.queue(Sched.queue.ID==ID,:)=[];
            
            % Event notification of any change to queue
            notify(Sched,'queueChanged');
        end
        
        function clearQueue(Sched)
            Sched.queue = cell2table({1,'StartQueue',1,-1,'absolute',0,'Initilaization',{NaN},'none','queued',{Sched},'none',''});
            Sched.queue.Properties.VariableNames = Sched.queueVarNames;
            Sched.queue.type = categorical(Sched.queue.type);
            Sched.queue.status = categorical(Sched.queue.status);
            
            Sched.currInd = 0;
            Sched.isPaused = 0;
            % Event notification of any change to queue
            notify(Sched,'queueChanged');
        end
        
        %% Start running queue
        function startQueue(Sched,delay)
            %             % temp: to test events
            %              lh2 = addlistener(Sched,'queueFinished',@Sched.testEvent);
            
            % Make adding a start delay optional
            if nargin==1
                delay = 0;
            end
            
            Sched.tStart = now*24*3600+ delay;
            Sched.queue.details(1) = {Sched.tStart+ delay};
            
            % Update the absolute time spacing events
            timeRows = Sched.queue.type=='TimePointAbs';
            goodRows = find(timeRows)';
            for k = goodRows
                timeParamCell = Sched.queue.details{k};
                timeParamCell(3) = timeParamCell(2) + Sched.tStart + delay;
                Sched.queue.details(k) = {timeParamCell};
                %                 Sched.queue.details(timeRows)= cellfun(@(x) x+Sched.tStart + delay*24*3600, Sched.queue.details(timeRows),'UniformOutput',false);
            end
            
            % Reset pause time accumulation
            Sched.accumPauseTime = 0;
            
            % Set the current queue index then start next thing in line
            Sched.currInd = 1;
            
            % Mark start as completed
            Sched.queue.status(Sched.queue.ID ==1)='Completed';
            
            Sched.nextInLine(Sched.currInd);
            
        end
        
        %% Pop the next thing in the queue
        function nextInLine(Sched,compOrd)
            
            if nargin == 1
                compOrd = Sched.currInd;
            end
            % 			% Mark event as completed
            % 			Sched.queue.status(Sched.queue.order==compOrd)='Completed';
            
            % Start next event
            nextOrderNum = compOrd+1;
            Sched.currInd = nextOrderNum;
            notify(Sched,'queueStepped');
            % Event notification of any change to queue
            notify(Sched,'queueChanged');
            
            if (max(Sched.queue.order)+1)>nextOrderNum
                row = Sched.queue.order == nextOrderNum;
                
                % Get run function
                runFn = Sched.queue.runFn{row};
                
                %Change status to running
                Sched.queue.status(row) = 'Running';
                
                % See if progress should continue without waiting
                rowID = Sched.queue.ID(row);
                
                % Initiate callback
                
                sourcePt = Sched.queue.sourcePointer{row};
                inputDetails = Sched.queue.details(row);
                eventName = Sched.queue.name{row};
                
                %                 % Get callback
                %                 callback = Sched.queue.callback{row};
                
                % Check if the time is up to start the next thing
                % time Value
                timeVal =  Sched.queue.timePoint(row);
                timeType = Sched.queue.timePointType{row};
                %                 Sched.checkTime(timeType,timeVal);
                
                MDinfo = Sched.queue.MDinfo{row};
                Sched.runIfTime(timeType,timeVal,eventName,sourcePt,runFn,inputDetails,rowID,1,MDinfo);
                
                %                 if isempty(runFn)
                %                     start(timer('StartDelay',0.01, 'StartFcn',@(~,~) fprintf(['running - ',eventName]),...
                %                                 'StopFcn',@(src,det) Sched.advanceIfGood(src,det),...
                %                                 'Tag',eventName));
                %                 start(timer('StartDelay',0.01, 'StartFcn',@(~,~) fprintf(['running - ',eventName]),...
                %                             'TimerFcn',@(~,~) sourcePt.(runFn)(inputDetails),...
                %                             'StopFcn',@(src,det) Sched.advanceIfGood(src,det,rowID),...
                %                             'Name',eventName));
                
                
            else
                %%%% maybe wait a second to make sure that all the things
                %%%% have been saved
                
                % Send notification that the queue has finished.
                notify(Sched,'queueFinished');
            end
            
        end
        
        
        function runIfTime(Sched,waitType,timeVal,eventName,sourcePt,runFn,inputDetails,rowID,isInit,MDinfo)
            % Cycle through checking for the time to be next
            switch waitType
                case 'absolute'
                    %                         fprintf('Curr Time: %s\n',datestr(now,13));
                    timeToChange = Sched.tStart + timeVal + Sched.accumPauseTime;
                    %                         fprintf('tStart: %s\n',datestr(Sched.tStart/3600/24,13));
                    %                         fprintf('time to change: %s\n',datestr(timeToChange/3600/24,13));
                    
                    % Calculate time difference (as a serial date)
                    Sched.timeToNext = timeToChange/3600/24-now;
                    % If more than 2 seconds left out then start a
                    % timer to check back in 1 second.
                    if Sched.timeToNext*24*3600 > 2
                        % Wait time more than 2 seconds.
                        
                        % Show time to change
                        if isInit
                            fprintf('Pause time till end of task: %s\n',datestr(Sched.timeToNext,13));
                        else
                            fprintf('\b\b\b\b\b\b\b\b\b%s\n',datestr(Sched.timeToNext,13));
                        end
                        
                        % if timer is pressed during this update paused
                        % time
                        if Sched.isPaused == 1
                            Sched.pauseTime = now;
                        end
                        % Send to timer that will check in one second
                        start(timer('StartDelay',1,...
                            'TimerFcn',@(~,~) Sched.runIfTime(waitType,timeVal,eventName,sourcePt,runFn,inputDetails,rowID,0),...
                            'Name','Wait for timepoint'));
                        
                        
                    elseif now*24*3600 > timeToChange
                        % The time has already passed
                        
                        % Pause flag to get into while loop
                        pauseFlag = 1;
                        msgFlag = 0;
                        while pauseFlag ==1
                            if Sched.isPaused==0
                                pauseFlag = 0;
                            else
                                if msgFlag ==0
                                    fprintf('Waiting for resume: pause excess time %s\n',datestr(now-timeToChange/3600/24,13));
                                    msgFlag = 1;
                                else
                                    fprintf('\b\b\b\b\b\b\b\b\b%s',datestr(now-timeToChange/3600/24,13))
                                end
                                pause(0.1)
                            end
                        end
                        
                        if ~isempty(MDinfo)
                            location = Sched.parent.Pos.peek('group',true);
                            Sched.parent.MD.markEvent(MDinfo.desc,MDinfo.conc,MDinfo.units,MDinfo.type,location);
                        end
                        start(timer('StartDelay',0.01, 'StartFcn',@(~,~) Sched.startTimerDispEvent(eventName),...
                            'TimerFcn',@(~,~) sourcePt.(runFn)(inputDetails),...
                            'StopFcn',@(src,det) Sched.advanceIfGood(src,det,rowID),...
                            'Name',eventName));
                        %                         start(timer('StartDelay',0.01, 'StartFcn',@(~,~) fprintf(['running - ',eventName]),...
                        %                             'TimerFcn',@(~,~) sourcePt.(runFn)(inputDetails),...
                        %                             'StopFcn',@(src,det) Sched.advanceIfGood(src,det,rowID),...
                        %                             'Name',eventName));
                        
                    else
                        % Use the thread for precision in the last two
                        % seconds.
                        
                        % Show time to change
                        if isInit
                            fprintf('Pause time till end of task: %s\n',datestr(Sched.timeToNext,13));
                        end
                        
                        while now*24*3600<timeToChange
                            % Update time difference
                            Sched.timeToNext = timeToChange/3600/24-now;
                            
                            fprintf('\b\b\b\b\b\b\b\b\b%s\n',datestr(Sched.timeToNext,13))
                            pause(0.1)
                            if Sched.isPaused == 1
                                Sched.pauseTime = now;
                            end
                        end
                        % Pause flag to get into while loop
                        pauseFlag = 1;
                        msgFlag = 0;
                        while pauseFlag ==1
                            if Sched.isPaused==0
                                pauseFlag = 0;
                                break;
                            else
                                if msgFlag ==0
                                    fprintf('Waiting for resume: pause excess time %s\n',datestr(now-timeToChange/3600/24,13));
                                    msgFlag = 1;
                                else
                                    fprintf('\b\b\b\b\b\b\b\b\b%s\n',datestr(now-timeToChange/3600/24,13))
                                end
                                pause(0.1)
                            end
                        end
                        % Run specified function after time has been
                        % reached.
                        start(timer('StartDelay',0.01, 'StartFcn',@(~,~)  Sched.startTimerDispEvent(eventName),...
                            'TimerFcn',@(~,~) sourcePt.(runFn)(inputDetails),...
                            'StopFcn',@(src,det) Sched.advanceIfGood(src,det,rowID),...
                            'Name',eventName));
                        %                         start(timer('StartDelay',0.01, 'StartFcn',@(~,~) fprintf(['running - ',eventName]),...
                        %                             'TimerFcn',@(~,~) sourcePt.(runFn)(inputDetails),...
                        %                             'StopFcn',@(src,det) Sched.advanceIfGood(src,det,rowID),...
                        %                             'Name',eventName));
                    end
                    
                    
                case 'relative'
                    
                    
            end
        end
        
        
        
        function advanceIfGood(Sched,src,eventData,compRow)
            % Method to initiate the next step in the queue
            
            % Display completion if debugging
            if Sched.debugging == 1
                fprintf(['timer event finished  \n']);
            end
            
            % Mark event as completed
            Sched.queue.status(Sched.queue.ID ==compRow)='Completed';
            if Sched.isPaused==0
                Sched.nextInLine;
            else
                while Sched.isPaused == 1
                    if Sched.debugging == 1 || Sched.verbose == 1
                        fprintf('Paused \n');
                    end
                    pause(0.1)
                    if Sched.debugging == 1 || Sched.verbose == 1
                        fprintf('\b\b\b\b\b\b\b\b');
                    end
                end
                Sched.nextInLine;
            end
            
        end
        
        function pause(Sched)
            Sched.pauseTime = now;
            Sched.isPaused = 1;
            
        end
        
        function resume(Sched)
            if Sched.isPaused == 1
                tDiffPause = now- Sched.pauseTime;
                Sched.accumPauseTime= Sched.accumPauseTime + tDiffPause*24*3600;
                Sched.isPaused = 0;
                %                 Sched.nextInLine;
            end
        end
        
        function set.timeToNext(Sched,tDiff)
            
            % Set the time value
            Sched.timeToNext = tDiff;
            
            % Notify event
            notify(Sched,'tDiffUpdated');
        end
        
        function startTimerDispEvent(Sched,eventName)
            % Desplay what timer is being started for debugging purposes
            
            if Sched.debugging == 1
                fprintf(['running - ',eventName,'\n']);
            end
        end
        
        % Need to check if still used
        function markNonstopComp(Sched,src,eventData,compRow)
            
            % Display completion if debugging
            if Sched.debugging == 1
                fprintf(['timer event finished  \n']);
            end
            
            % Mark event as completed
            Sched.queue.status(Sched.queue.ID ==compRow)='Completed';
            
        end
        
        % Need to check if used
        function advanceIfGoodNonstop(Sched,src,eventData)
            
            % Display completion if debugging
            if Sched.debugging == 1
                fprintf(['timer event finished  \n']);
            end
            
            if Sched.isPaused==0
                Sched.nextInLine;
            end
            
        end
        
        %% Depreciated methods
        
        %         function pickupCallback(Sched,src,eventData)
        %             fprintf(['recieved event callback ',eventData.EventName,' \n']);
        %             delete(Sched.currLH);
        %             if Sched.isPaused==0
        %                 Sched.nextInLine;
        %             end
        %         end
        
%         function evalPlaceholder(Sched,src,eventData)
%             fprintf(['place holder called  \n']);
%         end
        
    end
    
end