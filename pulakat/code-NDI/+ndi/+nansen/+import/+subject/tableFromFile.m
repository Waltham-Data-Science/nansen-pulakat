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
projectBase = fileparts(fileparts(which('ndi.nansen.startup'))); projectFile = fullfile(projectBase,'+setup','+conv',['+',labName],'project_info.json');
projectInfo = jsondecode(fileread(projectFile));

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
requiredVariableNames = {projectInfo.subjectFileColumns.value};
for i = 1:numel(subjectFiles)
    subjectFile = subjectFiles{i};

    % Validate that subject files contain necessary variables
    valid = ndi.nansen.import.file.validateTable(subjectFile,requiredVariableNames);
    if ~valid
        warning('importSubjectFiles: %s is not a valid subject file. Skipping.',subjectFile);
    end

    % Import subject table from file
    importOptions = detectImportOptions(subjectFile);
    importOptions = setvartype(importOptions,requiredVariableNames,'char');
    importOptions.SelectedVariableNames = requiredVariableNames;
    subjectTables{i} = readtable(subjectFile,importOptions);
    subjectTables{i}{:,'ElectronicFileName'} = {subjectFile};
end

% Stack subject tables
subjectTable = ndi.fun.table.vstack(subjectTables);

% Rename relevant variables
subjectTable = renamevars(subjectTable,requiredVariableNames, ...
    {projectInfo.subjectFileColumns.name});

end