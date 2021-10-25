%% Get experiment metadata and apply to image set


%% Select file for MD information

[exptCSV,exptPath,FilterIndex] = uigetfile('*.csv','Select CSV experiment file');
cd(exptPath);

exptParams = readtable(exptCSV,'Format',...
    '%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s');
numDish = height(exptParams);

basepth = exptPath;
dirFiles = dir;
files = struct2cell(dirFiles);
fileNames = files(1,:);

for m = 1:numDish
    fileType = exptParams.AcqSoftware{m};
%     foldInd = find(strcmp(fileNames,exptParams.folderName(m)));
    cd([basepth,'\',exptParams.folderName{m}])
    MD = Metadata;
    MD.pth = pwd;
    MD.basepth = basepth;
    MD.Username = exptParams.name{m};
    MD.Project = exptParams.exptName{m};
    subFiles = struct2cell(dir);
    switch fileType
        case 'ipl'
            % May add in later
            %              CFPind = find(strncmp('CFP',files(1,:),3));
        case 'Metafluor'
            
            fileNamesTest = subFiles(1,:);
            findInf = cellfun(@(x) strsplit(x(1,:),{'.'}),fileNamesTest,'UniformOutput',0);
            infInd = find(cellfun(@(x) strcmp(x(2),'INF'),findInf));
            infName = subFiles{1,infInd};
            infID =  fopen(infName);
            frame2time = textscan(infID,'%f o %f %*[^\n]','CommentStyle','*');
            frameMapping = [frame2time{1},frame2time{2}];
            fclose(infID);
            validFiles = find(cell2mat(subFiles(4,:))~=1);
            
            nFiles = length(validFiles);
            
            for k = 1:nFiles
                C= strsplit(subFiles{1,validFiles(k)},{'.'});
                endVal = str2num(C{2});
                if ~isempty(endVal)
                    timeValInd = find(frameMapping(:,1)==endVal);
                    timePt = frameMapping(timeValInd,2)/100;
                    fn = C{1};
                    chNum = str2num(fn(end));
                    eval(['chName = exptParams.w',fn(end),'c{m};'])
                    eval(['chExp = exptParams.w',fn(end),'t{m};'])
                    groupName = exptParams.folderName{m};
%                     if ismember(MD.ImgFiles,[exptParams.folderName{m},'\',subFiles{1,validFiles(k)}])
%                         indx = find(ismember(MD.ImgFiles,[exptParams.folderName{m},'\',subFiles{1,validFiles(k)}]));
%                         indx = find(ismember(MD.ImgFiles,subFiles{1,validFiles(k)}));
%                         
%                         MD.addToImages(indx,'Channel',chName,'Exposure',chExp,'group',groupName,'frame',endVal,'TimestampFrame',timePt);
%                     else
                        MD.addNewImage(subFiles{1,validFiles(k)},'Channel',chName,'Exposure',chExp,'group',groupName,'frame',endVal,'TimestampFrame',timePt,'Skip',0);
%                     end
                end
            end
    end
    MD.saveMetadata(pwd)
    cd(basepth)    
end

%% Collect all Metadata from subfolders

allMD = Metadata(pwd);
allMD.pth = pwd;
allMD.basepth = basepth;
allMD.Username = exptParams.name{1};
allMD.Project = exptParams.exptName{1};
allMD.saveMetadata(pwd)
