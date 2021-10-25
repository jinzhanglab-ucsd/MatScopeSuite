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

%% save results
R.analysisScript=mfilename; 
R.saveResults; 