function [subjectTable] = tableFromFile(subjectFiles,labName)
%TABLEFROMFILE Imports subject metadata from CSV or Excel files.
%
%   This function reads subject information from structured files,
%   validates required columns, and renames them to match the NDI
%   schema.
%
%   Inputs:
%      subjectFiles (cell array): Optional. List of file paths.
%         If empty, a selection dialog opens.
%      labName (char or string): Optional. The name of the lab.
%
%   Outputs:
%      subjectTable (table): A table containing the consolidated data.
%
%   Examples:
%      % Import subjects from a CSV:
%      subjects = ndi.nansen.import.subject.tableFromFile('animals.csv')
%
%   See also: NDI.NANSEN.IMPORT.SUBJECT.AUTO, NDI.NANSEN.IMPORT.FILE.VALIDATETABLE

% Input argument validation
arguments
    subjectFiles {mustBeText} = ''
    labName {mustBeText} = nansen.getCurrentProject().Name;
end

% Convert inputs to char arrays for internal processing
labName = char(labName);

% Get project info
projectInfo = ndi.nansen.fun.readProjectInfo(labName);

% If not specified, select file
if isempty(subjectFiles)
    subjectFiles = ndi.nansen.import.file.select('', ...
        'GetType','file', ...
        'FileName',projectInfo.subjectFileName, ...
        'FileExtensions',{'csv','xls','xlsx'});
end

% Check that there are subject files selected
if isempty(subjectFiles)
    subjectTable = table();
    return;
end

subjectTables = cell(size(subjectFiles));
sfc = projectInfo.subjectFileColumns;
allCsvCols = {sfc.value};
allTargets = {sfc.name};

% Some entries in subjectFileColumns describe columns that later
% import steps add by code rather than read from the CSV — the
% project_info schema keeps them here so documents.m can include
% them in ontologyTableRow document creation, but they are
% intentionally absent from the source CSV. Such entries are
% flagged "auto": true in project_info.json. Filter them out for
% the CSV-shape checks; the columns themselves are still present
% in the post-rename table because we add them below or in
% ndi.nansen.import.subject.
csvExpectedMask = ~ndi.nansen.fun.isAutoColumn(sfc);
expectedCsvCols = allCsvCols(csvExpectedMask);

for i = 1:numel(subjectFiles)
    subjectFile = subjectFiles{i};

    % Validate that subject files contain the genuinely-expected
    % CSV columns. validateTable issues a warning for any missing
    % column; we keep the call inside the loop so per-file warnings
    % carry the file path.
    valid = ndi.nansen.import.file.validateTable(subjectFile,expectedCsvCols);
    if ~valid
        warning('NDI:Nansen:Import:Subject:InvalidFile', ...
            ['[NDI:Nansen:Import:Subject:InvalidFile] %s is not a valid ' ...
             'subject file. Skipping.'], subjectFile);
    end

    % Import subject table from file. setvartype and
    % SelectedVariableNames both throw when given a name that
    % isn't in the file's variable list, so restrict to columns
    % the CSV actually carries. The auto-computed columns are
    % added back below (ElectronicFileName here, SubjectIdentifier
    % later by ndi.nansen.import.subject).
    importOptions = detectImportOptions(subjectFile);
    presentCsvCols = intersect(allCsvCols, ...
        importOptions.VariableNames, 'stable');
    importOptions = setvartype(importOptions,presentCsvCols,'char');
    importOptions.SelectedVariableNames = presentCsvCols;
    subjectTables{i} = readtable(subjectFile,importOptions);
    subjectTables{i}{:,'ElectronicFileName'} = {subjectFile};
end

% Stack subject tables
subjectTable = ndi.fun.table.vstack(subjectTables);

% Rename relevant variables. Match present-in-table columns to
% their target names — entries in subjectFileColumns whose `value`
% wasn't in any source CSV pass through; their target column will
% be populated by a later import step or stay empty.
presentInTable = intersect(allCsvCols, ...
    subjectTable.Properties.VariableNames, 'stable');
[~, idx] = ismember(presentInTable, allCsvCols);
subjectTable = renamevars(subjectTable, presentInTable, allTargets(idx));

end