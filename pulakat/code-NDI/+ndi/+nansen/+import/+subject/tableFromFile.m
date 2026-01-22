function [subjectTable] = tableFromFile(subjectFiles,labName)
%TABLEFROMFILES Imports and validates subject metadata from CSV or Excel files.
%   This function is designed to read subject information from structured
%   files (e.g., .csv, .xls, .xlsx). It validates that the files contain
%   required columns, reads the data, consolidates it into a single
%   MATLAB table, and renames columns to match the NDI schema.
%
%   Inputs:
%       subjectFiles (Optional): A string array, character vector, or cell
%           array of character vectors where each element is a full path to 
%           a subject data file. If empty or not provided, a file selection
%           dialog opens.
%
%   Outputs:
%       subjectTable (table): A MATLAB table containing the vertically 
%           stacked data from all imported files. The table includes 
%           columns such as: 'SubjectEnumeratedIdentifier', 
%           'SubjectCageIdentifier', 'SubjectTextIdentifier', 'Species', 
%           'Strain', 'BiologicalSex', 'Treatment', and 'ElectronicFileName'.

% Input argument validation
arguments
    subjectFiles {mustBeText} = ''
    labName {mustBeText} = nansen.getCurrentProject().Name;
end

% Convert inputs to char arrays for internal processing
labName = char(labName);

% Get project info
projectFile = fullfile('+ndi','+setup','+conv',['+',labName],'project_info.json');
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
    error('import.subject.tableFromFiles: No file(s) selected.');
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
    subjectTables{i}{:,'ElectronicFileName'} = subjectFile;
end

% Stack subject tables
subjectTable = ndi.fun.table.vstack(subjectTables);

% Rename relevant variables
subjectTable = renamevars(subjectTable,requiredVariableNames, ...
    {projectInfo.subjectFileColumns.name});

end