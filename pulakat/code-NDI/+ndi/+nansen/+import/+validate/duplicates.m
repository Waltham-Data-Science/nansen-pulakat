function [isValid, errorMessages] = duplicates(dataTable,dataName,identifiers,options)
%DUPLICATES Validates if a table contains duplicate records.
%
%   This function checks for duplicate rows in the provided data table
%   relative to the existing Nansen metatable. It uses specific
%   identification columns and can use 'any' or 'all' logic for
%   determining uniqueness.
%
%   Inputs:
%      dataTable (table): The input table to check for duplicates.
%      dataName (char or string): The name of the metatable class
%         ('Dataset', 'Session', 'Subject', or 'File').
%      identifiers (char or cell array): Column names to use for
%         uniqueness checks.
%
%   Name-Value Arguments:
%      Logic (char): Uniqueness logic ('any' or 'all'). Default is 'all'.
%      Project (nansen.config.project.Project): Optional. The Nansen
%         project object. Defaults to the current project.
%
%   Outputs:
%      isValid (logical): Column vector indicating if each row is unique.
%      errorMessages (string): Descriptive messages for duplicate rows.
%
%   See also: NDI.NANSEN.FUN.GETCOMPLETEUNIQUEROWS

% Input argument validation
arguments
    dataTable table
    dataName {mustBeMember(dataName,{'Dataset','Session','Subject','File'})}
    identifiers {mustBeText} = ''
    options.Logic {mustBeMember(options.Logic,{'any','all'})} = 'all'
    options.Project {mustBeA(options.Project,'nansen.config.project.Project')} = nansen.getCurrentProject;
end

% 1. Initialization
numRows = height(dataTable);
isValid = true(numRows, 1);
errorMessages = repmat("", numRows, 1);

if isempty(dataTable)
    return
end

% Get full metatable
metaTable = options.Project.MetaTableCatalog.getMetaTable(dataName);
vars = dataTable.Properties.VariableNames;

% Check for unique rows in the dataTable compared against the full metatable
switch options.Logic
    case 'all'
        [~,indUnique] = ndi.nansen.fun.getCompleteUniqueRows([dataTable;metaTable.entries(:,vars)],identifiers);
    case 'any'
        if ~strcmp(identifiers,'')
            vars = intersect(vars,identifiers);
        end
        [~,~,indUnique] = unique([dataTable(:,vars);metaTable.entries(:,vars)]);
end

% Get the unique values and a mapping of original elements to those values (ic)
[~, ~, ic] = unique(indUnique);

% Count how many times each unique index appears
counts = accumarray(ic, 1);

%Check which counts, and map that logic back to the original size
copies = counts(ic);
copies = copies(1:numRows);
copies = max(copies - 1,1);
isValid = copies == 1;

% Create error messages
errorMessages(~isValid) = arrayfun(@(c) string(sprintf('%i duplicates found.',c)),copies(~isValid)-1);

end
