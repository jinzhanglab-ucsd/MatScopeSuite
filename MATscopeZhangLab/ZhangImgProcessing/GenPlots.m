% Plot data

MDvtab = cell2table(MD.Values,'VariableNames',MD.Types);

MDvtab.group = categorical(MDvtab.group);
MDvtab.Channel = categorical(MDvtab.Channel);
allGr = categories(MDvtab.group);

for k = 1:length(allGr)
    grCh = categories(MDvtab.Channel(MDvtab.group == allGr(k)));
    figure
    extractValues= [];
    FR = [];
    for m=1:length(grCh)
        subplot(1,length(grCh)+1,m)
        imgInds = find(MDvtab.group == allGr(k) & MDvtab.Channel==grCh(m));
        for p = 1:length(imgInds)
            frIndex = MDvtab.frame(imgInds(p));
            bkgr_sub_out = MDvtab.RoiMeanBkgrSub{imgInds(p)};
            extractValues(frIndex,:,m) = bkgr_sub_out;
        end
        plot(extractValues(:,:,m))
    end
    
    %% hard coded fret ratio
    
    FR = extractValues(:,:,3)./extractValues(:,:,1);
    
    subplot(1,length(grCh)+1,m+1)
    plot(FR)
    title(allGr{k})
    
    allVals(k,:) = {extractValues,FR};
    
    
end

normInd = [8,8,16,8,16,8,8,8];
for k = 1:length(allGr)
    FRvals =[];
    normFR =[];
    FRvals = allVals{k,2};
   
%     normFR = FRvals./(ones(length(FRvals(:,1)),1)*FRvals(normInd(k),:));
    if normInd(k)~=8
        FRvals= FRvals(9:end,:);        
    end
    normFR = FRvals./(ones(length(FRvals(:,1)),1)*FRvals(8,:));
    figure
    plot(normFR)
    title(allGr{k})
    ylim([.9 1.5])
    dishAvg(1:length(normFR(:,1)),k) = mean(normFR,2);
    dishStd(1:length(normFR(:,1)),k) = std(normFR,0,2);
    
end

figure
shadedErrorBar([1:length(dishAvg(:,1))]'/4*ones(1,length(dishAvg(1,:))),dishAvg,dishStd)
ylim([.9 1.5])

legend('200 uM','100 uM','50 uM','None','200 uM','25 uM','12.5 uM','2 uM')
title('AKAR4 response to 5s UV with caged cAMP')
ylabel('Normalized FRET ratio (Y/C)')
xlabel('Time (min)')


