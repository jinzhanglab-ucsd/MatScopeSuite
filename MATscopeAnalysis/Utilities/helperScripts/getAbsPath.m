function [absPathParent,fullAbsPath] = getAbsPath(pth)

if ispc
    pth = regexprep(pth,'/',filesep);
else
    pth = regexprep(pth,'\',filesep);
end

parts = strsplit(pth, filesep);
if isempty(parts{1})
    parts(1) = [];
end
if isempty(parts)
    absPathParent = [];
    fullAbsPath =[];
    return
end
partsMain = strsplit(pwd, filesep);

if isempty(partsMain{1})
    partsMain(1) = [];
end

matchingIndex = find(strcmp(parts(1),partsMain));

if isempty(matchingIndex)
    dirInfo = dir(pth);
    
    if isempty(dirInfo)
        absPathParent = [];
        fullAbsPath = pth;
%         error('Could not find directory of path to save in')
    else
        if ispc
            absPathParent = fullfile(partsMain{:});
        else
            absPathParent = fullfile(filesep,partsMain{:});
        end
    end
    
    fullAbsPath = fullfile(absPathParent,pth);
    
else
    
    if matchingIndex ==  1
        if ispc
            if ~isempty(strfind(partsMain{1},':'))
                % colon should be marker of drive in a pc
                absPathParent = '';
            else
                error('Unable to interperet path');
            end
        else
            if strcmp(filesep,pth(1))==1
                absPathParent = '';
            else
                absPathParent = fullfile(filesep);
            end
        end
    else
        if ispc
            absPathParent = fullfile(partsMain{1:matchingIndex-1});
        else
            absPathParent = fullfile(filesep,partsMain{1:matchingIndex-1});
        end
    end
%     fullAbsPath = fullfile(absPathParent,pth);
    fullAbsPath = fullfile(absPathParent,parts{:});
%     if strcmp(pth(1),filesep)==1
%         fullAbsPath = fullfile(absPathParent,pth(2:end));
%     else
%         fullAbsPath = fullfile(absPathParent,pth);
%     end
    
end