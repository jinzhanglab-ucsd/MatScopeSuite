%% get information for report

[exptCSV,exptPath,FilterIndex] = uigetfile('*.csv','Select CSV experiment file');
cd(exptPath);
currDir = pwd;
rptDir = [currDir,'\report'];
if ~exist(rptDir)
    mkdir('report')
end
exptParams = readtable(exptCSV,'Format',...
    '%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s');
numDish = height(exptParams);

%% format the more complicated rows

% Pertubations
for m = 1:numDish
C= strsplit(exptParams.imgEvents{m},{'\'})';
if length(C)>1
for k = 1:length(C)
    strVals = strsplit(C{k},'-');
c2(k,1:length(strVals)) = strVals;
end
end
exptParams.imgEvents{m} = c2;
end

% Image observations
for m = 1:numDish
C= strsplit(exptParams.imgObs{m},{'\'})';
if length(C)>1
    obsVect = C;
else
    obsVect = {exptParams.imgObs{m}};
end
exptParams.imgObs{m} = obsVect;
end

% Post Processing
for m = 1:numDish
C= strsplit(exptParams.PostProcessing{m},{'\'})';
ratioCounter = 0;
cellVals=[];
goodInds = cellfun(@(x) ~isempty(x),C);
C = C(goodInds);
for k = 1:length(C)    
    strVals = strsplit(C{k},':');
    if strcmp(strVals(1),'ratio')
        ratioCounter = ratioCounter + 1;
        ratioStr = strsplit(strVals{2},'/');
        expr ='BS(\d)_Ch(\d)';
        [numTokens,~] = regexp(ratioStr{1},expr,'tokens','match');
        [denTokens,~] = regexp(ratioStr{2},expr,'tokens','match');
        eval(['numChName = exptParams.w',num2str(numTokens{1}{2}),'c{m};'])
        eval(['denChName = exptParams.w',num2str(denTokens{1}{2}),'c{m};'])
        eval(['varName = ''R',num2str(ratioCounter),''';'])
        ppVals{k} = {'Ratio',varName,numChName,numTokens{1}{1},denChName,denTokens{1}{1}};
    elseif strcmp(strVals(1),'norm')
    
    else
        ppVals=[];
        
    end
% c2(k,1:length(strVals)) = strVals;
end
exptParams.PostProcessing{m} = ppVals;
end
%% Generate plots

% Get info from metadata
MD = Metadata(pwd);
MDvtab = cell2table(MD.Values,'VariableNames',MD.Types);

MDvtab.group = categorical(MDvtab.group);
MDvtab.Channel = categorical(MDvtab.Channel);
allGr = categories(MDvtab.group);
for k = 1:numDish
    grCh = categories(MDvtab.Channel(MDvtab.group == exptParams.folderName{k}));
    dishPP = exptParams.PostProcessing{k};
    numCol = max(length(grCh),length(dishPP));
%     numPlots = length(grCh)+length(dishPP);
    figH = figure;
    figHall(k) = figH;
    figName{k} = exptParams.folderName{k};
    chValues= [];
    tvals=[];
    for m=1:length(grCh)
        subplot(2,numCol,m)
        imgInds = find(MDvtab.group == exptParams.folderName{k} & MDvtab.Channel==grCh(m)& MDvtab.Skip~=1);
        for p = 1:length(imgInds)
            frIndex = MDvtab.frame(imgInds(p));
            tvals(frIndex) = MDvtab.TimestampFrame(imgInds(p));
            bkgr_sub_out = MDvtab.RoiMeanBkgrSub{imgInds(p)};
            chValues(frIndex,:,m) = bkgr_sub_out;
        end
        tvals(tvals == 0) = NaN;
        plot(tvals,chValues(:,:,m))
        title(grCh{m})
    end
    MD.NonImageBasedData(k,1:3) = {k,dishPP,tvals};
    for m=1:length(dishPP)
        ratioEval=[];
        numerValsAll=[];
        denomValsAll=[];
        subplot(2,numCol,m+numCol)
        PPop = dishPP{m};
        if strcmp(PPop{1},'Ratio')
            numerCh = PPop{3};
            numerInds = find(MDvtab.group == exptParams.folderName{k} & MDvtab.Channel==numerCh & MDvtab.Skip~=1);
            for j = 1:length(numerInds)
                frIndex = MDvtab.frame(numerInds(j));
                tvals(frIndex) = MDvtab.TimestampFrame(numerInds(j));
                if str2num(PPop{4})==1
                    
                    numerVals = MDvtab.RoiMeanBkgrSub{numerInds(j)};
                else
                    numerVals = MDvtab.RoiMeans{numerInds(j)};
                    numerVals = numerVals(2:end);
                end
                numerValsAll(frIndex,:) = numerVals;
            end
            numerValsAll(numerValsAll==0) = NaN;
            denomCh = PPop{5};
            denomInds = find(MDvtab.group == exptParams.folderName{k} & MDvtab.Channel==denomCh & MDvtab.Skip~=1);
            for j = 1:length(denomInds)
                frIndex = MDvtab.frame(denomInds(j));
                if str2num(PPop{6})==1
                    
                    denomVals = MDvtab.RoiMeanBkgrSub{denomInds(j)};
                else
                    denomVals = MDvtab.RoiMeans{denomInds(j)};
                    denomVals = denomVals(2:end);
                end
                denomValsAll(frIndex,:) = denomVals;
            end
            denomValsAll(denomValsAll==0) = NaN;
            ratioName = PPop{2};
            ratioEval = numerValsAll./denomValsAll;
            eval([ratioName,'=ratioEval;'])
            tvals(tvals == 0) = NaN;
            plot(tvals,ratioEval)
            titleStr = [numerCh,'/',denomCh];
            title(titleStr);
            
            MD.NonImageBasedData(k,3+m) = {ratioEval};
            
        end
    end
    set(figH, 'Units', 'Inches', 'Position', [0, 0, 7, 8.5], 'PaperUnits', 'Inches', 'PaperPosition', [0,0,7,8.5])
end

MD.saveMetadata;

for k =1:length(figHall)
%     saveName = [rptDir,'\',figName{k},'.png'];
%     saveas(figHall(k),saveName)
    saveName = [rptDir,'\',figName{k}];
    print(figHall(k),saveName,'-dpng')
end

rptName = 'Results160128rc.tex';

texReport(rptName,exptParams,figName)


