%% Init MD / R and create the Props per position
MD=Metadata(pth);
R = MultiPositionSingleCellResults(pth); 
R.PosNames = unique(MD,'Position');  
Channels = unique(MD,'Channel');  

% Props are the property that 
Props =  MD.NewTypes; 

%% Main loop
t0=now; 
for i=1:numel(R.PosNames)
    % output timing
    fprintf('%s %s\n',R.PosNames{i},datestr(now-t0,13)); 
    
    % Assume the cell labels have already been saved before.
    Lbl = setLbl(R,@(x) false(1),R.PosNames{i}); 
    
    %% Get image stacks
    
    % get timepoints for measurements. 
    T = MD.getSpecificMetadata('TimestampFrame','Channel',Channels{1},'Position',R.PosNames{i},'timefunc',@(t) true(size(t)));
    T=cat(1,T{:});
    
    % Relative Time in seconds
    Trel = (T-T(1))*24*3600;
    
    % Update the cell values for each channel
    for k = 1:length(Channels)
        % Load the stacks
        chanImg = stkread(MD,'Position',R.PosNames{i},'Channel',Channels{k},'timefunc',@(t) true(size(t)));
        chanMeanInt = meanIntensityPerLabel(Lbl,gray2ind(chanImg,2^16),T,'func','mean','type','base');
        R.addTimeSeries(Channels{k},chanMeanInt,Trel,R.PosNames{i});
        if isempty(Lbl.BkgrManualRoi)
            R.addTimeSeries([Channels{k},'_bkgrSub'],nan(size(chanMeanInt)),Trel,R.PosNames{i});
        else
            [chanBkgrSub,bcksml] = Lbl.bkgrSubtractManualRoi(chanImg);
            bsChanMeanInt = meanIntensityPerLabel(Lbl,gray2ind(chanBkgrSub,2^16),T,'func','mean','type','base');
            R.addTimeSeries([Channels{k},'_bkgrSub'],bsChanMeanInt,Trel,R.PosNames{i});
        end
    end
    
    