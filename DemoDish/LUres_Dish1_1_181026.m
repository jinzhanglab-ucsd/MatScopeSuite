% Analysis script automatically generated by Live Updates in Scope.m 
% on 26-Oct-2018

% Make sure that the analysis file is on the MATLAB path when running from results 

%% Key user input - the path where the images are (try to keep as a relative path) 
pth = '/Users/danielleschmitt/Desktop/Demo_Dish';
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
    

    
    % Update the cell values for each channel
    for k = 1:length(Channels)
            % get timepoints for measurements. 
        T = MD.getSpecificMetadata('TimestampFrame','Channel',Channels{k},'Position',R.PosNames{i},'timefunc',@(t) true(size(t)));
        T=cat(1,T{:});
    
    % Relative Time in seconds
    Trel = (T-T(1))*24*3600;
        % Load the stacks
        chanImg = stkread(MD,'Position',R.PosNames{i},'Channel',Channels{k},'timefunc',@(t) true(size(t)));
        chanMeanInt = meanIntensityPerLabel(Lbl,gray2ind(chanImg,2^16),T,'func','mean','type','base');
        R.addTimeSeries(Channels{k},chanMeanInt,Trel,R.PosNames{i});
        if isempty(Lbl.BkgrManualRoi)
            R.addTimeSeries([Channels{k},'_bkgrSub'],nan(size(chanMeanInt)),T,R.PosNames{i});
        else
            [chanBkgrSub,bcksml] = Lbl.bkgrSubtractManualRoi(chanImg);
            bsChanMeanInt = meanIntensityPerLabel(Lbl,gray2ind(chanBkgrSub,2^16),T,'func','mean','type','base');
            R.addTimeSeries([Channels{k},'_bkgrSub'],bsChanMeanInt,T,R.PosNames{i});
        end
    end
    
    % Get channel values by name 
	[ExRai_405,~] = getTimeseriesData(R,'ExRai_405',R.PosNames{i});
	[ExRai_405_bkgrSub,~] = getTimeseriesData(R,'ExRai_405_bkgrSub',R.PosNames{i});
	[GFP,~] = getTimeseriesData(R,'GFP',R.PosNames{i});
	[GFP_bkgrSub,~] = getTimeseriesData(R,'GFP_bkgrSub',R.PosNames{i});
	
	% Re-calculate cell values 
	ExRai_ratio = GFP./(ExRai_405);
	addTimeSeries(R,'ExRai_ratio',ExRai_ratio,Trel,R.PosNames{i});
	ExRai_ratio_bkgrSub = (GFP_bkgrSub)./(ExRai_405_bkgrSub);
	addTimeSeries(R,'ExRai_ratio_bkgrSub',ExRai_ratio_bkgrSub,Trel,R.PosNames{i});
	% add Position properties
    for j=1:numel(Props)
        try
            tmp=unique(MD,Props{j},'Position',R.PosNames{i});
            if isempty(tmp)
                setProperty(R,Props{j},NaN,R.PosNames{i});
            else
                setProperty(R,Props{j},tmp(1),R.PosNames{i});
            end
        catch
            warning('off','backtrace')
            warning('Attempted to set property, %s, but unable to get unique values',Props{j});
            warning('on','backtrace')
        end
    end
        
end
[ExRai_ratio_bkgrSub,tout] = getTimeseriesData(R,'ExRai_ratio_bkgrSub',R.PosNames{1});
tout = tout/3600/24/60;

figure;plot(tout,ExRai_ratio_bkgrSub);

normMat = ones(length(ExRai_ratio_bkgrSub(:,1)),1)*mean(ExRai_ratio_bkgrSub(1:3,:),1);
ExRai_ratio_bkgrSub_norm =ExRai_ratio_bkgrSub./normMat;

figure;plot(tout,ExRai_ratio_bkgrSub_norm);

ExRai_ratio_bkgrSub_avg = mean(ExRai_ratio_bkgrSub_norm,2);
ExRai_ratio_bkgrSub_stder = std(ExRai_ratio_bkgrSub_norm,[],2)./sqrt(length(ExRai_ratio_bkgrSub_norm(1,:)));

hold on
errorbar(tout,ExRai_ratio_bkgrSub_avg,ExRai_ratio_bkgrSub_stder)

%% save results
R.analysisScript=mfilename; 
R.saveResults; 