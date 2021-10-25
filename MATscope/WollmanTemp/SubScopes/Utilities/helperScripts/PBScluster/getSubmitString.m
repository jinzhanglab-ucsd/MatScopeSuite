function submitString = getSubmitString(jobName, quotedLogFile, quotedCommand, ...
    varsToForward, additionalSubmitArgs)
%GETSUBMITSTRING Gets the correct qsub command for a PBS cluster

% Copyright 2010-2012 The MathWorks, Inc.

nameEqualsValCell = cellfun(@(name) sprintf('%s=%s', name, getenv(name)), ...
                            varsToForward, 'UniformOutput', false);
nameEqualsValCommaSep = sprintf('%s,', nameEqualsValCell{:});

%envString = strtrim(sprintf('-v ''%s'' ', nameEqualsValCommaSep(1:end-1)));
envString = '';

% Submit to PBS using qsub. Note the following:
% "-N Job#" - specifies the job name
% "-j oe" joins together output and error streams
% "-o ..." specifies where standard output goes to
% envString has the "-v 'NAME=value,NAME2=value2'" piece.
submitString = sprintf('/opt/torque/bin/qsub -N %s -j oe -o %s %s %s %s', ...
    jobName, quotedLogFile, envString, additionalSubmitArgs, quotedCommand);


