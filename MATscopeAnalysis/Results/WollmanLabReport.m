function WollmanLabReport(varargin)
% create a list of all datasets, use this list to generate an XML file
% and update a few plots for the report

arg.rerun = false; 
arg.basereportfolder = '/home/rwollman/Reports'; 
arg.startdate = datenum('March-12-2013'); 
arg = parseVarargin(varargin,arg); 

%% get datasets and create xml
% DatasetList = findAllDatasets('/data/Images/'); 

DatasetList = findAllDatasets({'/data/Images/','/data2/Images/'}); 

%% Remove Datasets before startdate and sort remaining by time
tm = [DatasetList.AcqDatenum]; 
DatasetList(tm<arg.startdate)=[]; 
tm1 = [DatasetList.AcqDatenum]; 
tm2 = [DatasetList.Datenum]; 
[~,ordr] = sortrows([tm1(:) tm2(:)]); 
DatasetList = DatasetList(ordr); 

%% rerun all reports if needed
% if arg.rerun
%     for i=1:numel(DatasetList)
%         R = Results(DatasetList(i).pth); 
%         try
%             R.publish;
%             DatasetList.Report = fullfile(R.pth,'Report.html');
%         catch e
%             warning('Error in dataset %s\n error message was',DatasetList(ReportMissing(i)).pth,e.message);
%         end
%     end
% end

% %% find out all the datasets without a report
% ReportMissing = find(cellfun(@isempty,{DatasetList.Report})); 
% for i=1:numel(ReportMissung)
%     R = Results(DatasetList(ReportMissing(i)).Fullpath); 
%     try
%         R.publish;
%         DatasetList.Report = fullfile(R.pth,'Report.html'); 
%     catch e
%         warning('Error in dataset %s\n error message was',DatasetList(ReportMissing(i)).pth,e.message); 
%     end
% end

%% copy all html reports into the WWW folders
ReportsExist = find([DatasetList.ReportExist]); 

for i=1:length(ReportsExist)
    source_pth=DatasetList(ReportsExist(i)).Fullpath; 
    destination_pth = regexprep(source_pth,filesep,'_'); 
    movie_pth = fullfile(source_pth,'Movies'); 
    source_pth = fullfile(source_pth,'Report'); 
    copyfile(source_pth,fullfile(arg.basereportfolder,destination_pth));
    DatasetList(ReportsExist(i)).www=fullfile(destination_pth,'Report.html'); 
    if exist(movie_pth,'dir')
        mkdir(fullfile(arg.basereportfolder,destination_pth,'Movies')); 
        copyfile(movie_pth,fullfile(arg.basereportfolder,destination_pth,'Movies'));
    end
end

%% create requried plots 

   %% number of datasets over time - with / repot (stacked bar)
   
   %% number of datasets over time per user

%% create Table.html file

percentResults = (1-mean([DatasetList.ResultExist]))*100; 


HTMLstart = sprintf([...
    '<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">' ...
    '<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en" lang="en">' ...
    '<head>' ...
'	<title>Wollman Lab Reports</title>' ...
	'<meta http-equiv="Content-type" content="text/html; charset=UTF-8" />' ...
	'<script type="text/javascript" src="webtoolkit.sortabletable.js">' ...
'    </script>' ...
 	'<style>' ...
'		table {' ...
'			text-align: left;' ...
'			font-size: 12px;' ...
'			font-family: verdana;' ...
'			background: #c0c0c0;' ...
'		}' ...
 '		table thead  {' ...
'			cursor: pointer;' ...
'		}' ...
 '		table thead tr,' ...
'		table tfoot tr {' ...
'			background: #c0c0c0;' ...
'		}' ...
 '		table tbody tr {' ...
'			background: #f0f0f0;' ...
'		}' ...
 '		td, th {' ...
'			border: 1px solid white;' ...
'		}' ...
'	</style>' ...
'</head>' ...
'<body>' ...
' %2.1f%% Results files are missing' ...
'<table cellspacing="1" cellpadding="2" class="" id="myTable" width="80%%">\n' ...
'	<thead>' ...
'		<tr>' ...
'           <th class="c1">#</th>' ...
'			<th class="c2">User</th>' ...
'			<th class="c3">Project</th>' ...
'			<th class="c4">Dataset</th>' ...
'           <th class="c5">Date</th>' ...
'           <th class="c6">Acq Comments</th>' ...
'           <th class="c7">Result Exist?</th>' ...
'           <th class="c8">Analysis Report</th>' ...
'           <th class="c9">Current Conclusion</th>' ...
		'</tr>' ...
	'</thead>' ...
	'<tbody>'],percentResults); 

HTMLcenter=[]; 
for i=1:numel(DatasetList)
    if ~isempty(DatasetList(i).www) 
        link = sprintf('<a href="%s">Report</a>',DatasetList(i).www); 
    else
        link=''; 
    end
    if DatasetList(i).ResultExist 
        try
            if exist(fullfile(DatasetList(i).Fullpath,'Conclusions.mat'),'file')
                s = load(fullfile(DatasetList(i).Fullpath,'Conclusions.mat'));
                Conclusions = s.Conclusions;
            else
                s = load(fullfile(DatasetList(i).Fullpath,'Results.mat'),'Conclusions');
                if ~isfield(s,'Conclusions')
                    s = load(fullfile(DatasetList(i).Fullpath,'Results.mat'));
                    Conclusions = s.R.Conclusions;
                else
                    Conclusions = s.Conclusions;
                end
            end
        catch e
            Conclusions = sprintf('Error reading Results file with message: %s',e.message'); 
        end
            
        if size(Conclusions,1)>1
            Conclusions_multiline = Conclusions; 
            Conclusions=[]; 
            for j=1:size(Conclusions_multiline,1)
                Conclusions = [Conclusions Conclusions_multiline(j,:) '<br>'];  %#ok<AGROW>
            end
        end
    else
        Conclusions = 'No Conclusions Yet'; 
    end
    tablerow = sprintf(['<tr class="r1">\n' ...
			'<td class="c1">%g</td> ' ...
			'<td class="c2">%s</td> ' ...
			'<td class="c3">%s</td> ' ...
            '<td class="c4">%s</td> ' ...
            '<td class="c5">%s</td> ' ...
            '<td class="c6">%s</td> ' ...
            '<td class="c7">%g</td> ' ...
            '<td class="c8">%s</td> ' ...
            '<td class="c9">%s</td> ' ...
            '</tr>'],i,DatasetList(i).User,...
                       DatasetList(i).Project,...
                       DatasetList(i).Dataset,...
                       DatasetList(i).Date,...
                       DatasetList(i).AcqComments,...
                       DatasetList(i).ResultExist,...
                       link,...
                       Conclusions);
    HTMLcenter = [tablerow HTMLcenter];  %#ok<AGROW>
end
HTMLend = sprintf(['</tbody> '...
'</table>' ...
'<script type="text/javascript">' ...
'var t = new SortableTable(document.getElementById(''myTable''), 100);' ...
'</script>' ...
'<p>Last updated: %s',...
'</body>' ...
'</html>'],datestr(now)); 

HTML = [HTMLstart HTMLcenter HTMLend]; 

indexfile = fullfile(arg.basereportfolder,'index.html'); 
fid = fopen(indexfile,'w'); 
fprintf(fid,'%s',HTML); 
fclose(fid); 


