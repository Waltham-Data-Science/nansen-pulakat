function [dataTable] = experimentMetadataFile(dataFile)
%EXPERIMENTMETADATAFILE Extract cage identifiers from an experiment schedule.
%
%   Reads the first sheet of the experiment-schedule spreadsheet and
%   returns the union of the x18Rats / x32Rats / x25Rats columns as
%   SubjectCageIdentifier values. Spaces are stripped from cage names.
%
%   Inputs:
%      dataFile (char or string): Absolute path to the schedule spreadsheet.
%
%   Outputs:
%      dataTable (table): Unique SubjectCageIdentifier values.

% Input argument validation
arguments
    dataFile {mustBeFile}
end

experimentSchedule = readtable(dataFile,'Sheet',1);

% Process study groups from first sheet of experimentSchedule
group1 = unique(experimentSchedule.x18Rats); group1(strcmp(group1,'')) = [];
group2 = unique(experimentSchedule.x32Rats); group2(strcmp(group2,'')) = [];
group3 = unique(experimentSchedule.x25Rats); group3(strcmp(group3,'')) = [];
dataTable = table([group1;group2;group3],'VariableNames', ...
    {'SubjectCageIdentifier'});

% Remove spaces from cage names (if applicable)
dataTable.SubjectCageIdentifier = cellfun(@(c) replace(c,' ',''), ...
    dataTable.SubjectCageIdentifier,'UniformOutput',false);

dataTable = unique(dataTable,'stable');

end