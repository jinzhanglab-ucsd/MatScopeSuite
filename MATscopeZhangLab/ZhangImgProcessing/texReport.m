function texReport(rptName,exptTable,figName)
%% Generate latex

% templateName = 'C:\Users\Eric\OneDrive\UCSD\AnalysisCode\ReportGen\LaTeXheader.tex';
templateName = 'C:\Users\Eric\Documents\MATLAB\ScopeControl\ZhangImgProcessing\LaTeXheader.tex';

% rptName = 'ReportXXX.tex';
currDir = pwd;
rptDir = [currDir,'\report'];
if ~exist(rptDir)
    mkdir('report')
end
rptDirFile = [currDir,'\report\',rptName];
copyfile(templateName,rptDirFile)
rpt = fopen(rptDirFile,'a+');
nDish = length(exptTable.DishNo);
%% Extract Input Values
% [name,date ,time,exptName] = inputFields{:};
fprintf(rpt,'\\rfoot{%s} \r',exptTable.date{1});
fprintf(rpt,'\\cfoot{%s} \r',exptTable.exptName{1});
% fprintf(rpt,'\\lfoot{\\thepage\\ of %s} \r',num2str(nDish));
fprintf(rpt,'\\lfoot{\\thepage\\ of \\pageref{LastPage}} \r');
fprintf(rpt,'\\begin{document} \r');
%% repeat information


for k = 1:nDish
    %% Experiment info
fprintf(rpt,'{\\Large \\textbf{Imaging Experiment Form (Zhang Lab)}}');
fprintf(rpt,'\\section*{Experiment Setup} \r');
fprintf(rpt,'\\begin{tabu}{ X[l] X[c] X[r] X[c]} \r');
fprintf(rpt,'Name: & %s & Lab: & Jin Zhang \\\\\\cline{2-2}\\cline{4-4} \r',exptTable.name{k});
fprintf(rpt,'Date: & %s & Time: & %s \\\\\\cline{2-2}\\cline{4-4} \r',exptTable.date{k},exptTable.time{k});
fprintf(rpt,'Experiment Name: & \\multicolumn{3}{l}{%s}  \\\\\\cline{2-4} \r',exptTable.exptName{k});
fprintf(rpt,'\\end{tabu} \r');

%% Dish information
fprintf(rpt,'\\section*{Dish Details - Dish No: %s} \r',exptTable.DishNo{k});
fprintf(rpt,'\\begin{tabu}{ X[l] X[c] X[r] X[c]} \r');
fprintf(rpt,'Cell Type: & %s & Constructs Used: & %s \\\\\\cline{2-2}\\cline{4-4} \r',exptTable.CellType{k},exptTable.Construct{k});
fprintf(rpt,'Transfection Date: & %s & Transfection Time: & %s \\\\\\cline{2-2}\\cline{4-4} \r',exptTable.TXNdate{k},exptTable.TXNtime{k});
fprintf(rpt,'$\\Delta$ Medium Date: & %s & $\\Delta$ Medium Time: & %s \\\\\\cline{2-2}\\cline{4-4}\r',exptTable.MediumDate{k},exptTable.MediumTime{k});
fprintf(rpt,'Medium: & %s & Starve Medium: & %s \\\\\\cline{2-2}\\cline{4-4} \r',exptTable.Medium{k},exptTable.MediumStarve{k});
fprintf(rpt,'Starve Date: & %s & Starve Time: & %s \\\\\\cline{2-2}\\cline{4-4} \r',exptTable.StarveDate{k},exptTable.StarveTime{k});
fprintf(rpt,'Transfection Hours: & %s & Expression Hours: & %s \\\\\\cline{2-2}\\cline{4-4} \r',exptTable.TXNhours{k},exptTable.ExprHrs{k});
fprintf(rpt,'Other Pretreatments: & \\multicolumn{3}{l}{%s} \\\\\\cline{2-4} \r',exptTable.OtherPreTreat{k});
fprintf(rpt,'Initial Comments: & \\multicolumn{3}{l}{%s} \\\\\\cline{2-4} \r',exptTable.InitComments{k});
fprintf(rpt,'\\end{tabu} \r');

%% Imaging Parameters
fprintf(rpt,'\\subsection*{Imaging} \r');
fprintf(rpt,'\\begin{tabu}{  X[l] X[c] X[r] X[c]} \r');
fprintf(rpt,'ND used: & %s & Protocol: & %s \\\\\\cline{2-2}\\cline{4-4} \r',exptTable.NDused{k},exptTable.protocol{k});
fprintf(rpt,'Imaging Vol.: & %s & Temp (C): & %s \\\\\\cline{2-2}\\cline{4-4} \r',exptTable.imgVol{k},exptTable.temp{k});
fprintf(rpt,'Interval: & %s & No. Frames: & %s \\\\\\cline{2-2}\\cline{4-4} \r',exptTable.timeInt{k},exptTable.noFrames{k});
fprintf(rpt,'Notes: & \\multicolumn{3}{l}{%s} \\\\\\cline{2-4} \r',exptTable.imgNotes{k});
fprintf(rpt,'\\end{tabu} \r');
fprintf(rpt,'\\vspace{2mm} \r');
fprintf(rpt,'\\begin{tabu} {|X[l]|X[c]|X[c]|X[c]|X[c]|X[c]|}\\hline \r');
fprintf(rpt,' & W1 & W2 & W3 & W4 & W5 \\\\\\hline \r');
fprintf(rpt,'Channel  \\hspace{3cm} Name & %s & %s & %s & %s & %s \\\\\\hline \r',exptTable.w1c{k},exptTable.w2c{k},exptTable.w3c{k},exptTable.w4c{k},exptTable.w5c{k});
fprintf(rpt,'Exposure Time (ms) & %s & %s & %s & %s & %s \\\\\\hline \r',exptTable.w1t{k},exptTable.w2t{k},exptTable.w3t{k},exptTable.w4t{k},exptTable.w5t{k});
fprintf(rpt,'Intensity (C/N) & %s & %s & %s & %s & %s \\\\\\hline \r',exptTable.w1i{k},exptTable.w2i{k},exptTable.w3i{k},exptTable.w4i{k},exptTable.w5i{k});
fprintf(rpt,'\\end{tabu}');
fprintf(rpt,'\\vspace{2mm} \r');
fprintf(rpt,'\\begin{tabu}{  X[l] X[c] X[r] X[c]} \r');
fprintf(rpt,'Starting Ratio (C/N): & %s & Percent Response: & %s \\\\\\cline{2-2}\\cline{4-4} \r',exptTable.StartingRatio{k},exptTable.percResp{k});
fprintf(rpt,' \\multicolumn{4}{l}{Events and Observations:}  \\\\ \r');
fprintf(rpt,' \\multicolumn{4}{l}{\\hspace{1em}\\parbox{\\textwidth}{');
perturbs = exptTable.imgEvents{k};
numPerturb = size(perturbs,1);
for m = 1:numPerturb
    fprintf(rpt,'%s after frame %s \\\\',perturbs{m,1},perturbs{m,2});
end
imgObs = exptTable.imgObs{k};
numObs = length(imgObs);
for m = 1:numObs
    fprintf(rpt,' %s \\\\',imgObs{m});
end
fprintf(rpt,'}} \r');

fprintf(rpt,'\\end{tabu} \r');

if nargin == 3
fprintf(rpt,'\\pagebreak \r');

fprintf(rpt,['\\includegraphics{',figName{k},'.png} \r']);
end

if k~=nDish
    fprintf(rpt,'\\pagebreak \r \r');
end
end

fprintf(rpt,'\\end{document} \r');
closeStatus = fclose(rpt)
