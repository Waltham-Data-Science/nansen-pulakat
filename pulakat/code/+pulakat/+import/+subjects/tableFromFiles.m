function [subjectTable] = tableFromFiles(subjectFiles)
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
    subjectFiles {mustBeText} = pulakat.import.file.select('', ...
        'GetType','file', ...
        'FileName','animal_mapping', ...
        'FileExtensions',{'csv','xls','xlsx'});
end

% Check that there are subject files selected
if isempty(subjectFiles)
    warning('import.subject.tableFromFiles: No file(s) selected.');
end

% Validate files
requiredVariableNames = {'Animal','Cage','Label','Species','Strain','BiologicalSex','Treatment'};
for i = 1:numel(subjectFiles)
    subjectFile = subjectFiles{i};
    valid = pulakat.import.file.validateTable(subjectFile,requiredVariableNames);
    if ~valid
        warning('importSubjectFiles: %s is not a valid subject file.',subjectFile); % Change to error
    end
end

% Import data from files
subjectTables = cell(size(subjectFiles));
for i = 1:numel(subjectFiles)
    subjectFile = subjectFiles{i};

    % Import current subject table
    importOptions = detectImportOptions(subjectFile);
    importOptions = setvartype(importOptions,requiredVariableNames,'char');
    importOptions.SelectedVariableNames = requiredVariableNames;
    subjectTables{i} = readtable(subjectFile,importOptions);
    subjectTables{i}{:,'FileName'} = subjectFile;
end

% Stack subject tables
subjectTable = ndi.fun.table.vstack(subjectTables);

% Remove spaces from cage names (if applicable)
subjectTable.Cage = cellfun(@(c) replace(c,' ',''),subjectTable.Cage,...
    'UniformOutput',false);

% Rename relevant variables
subjectTable = renamevars(subjectTable,{'Animal','Cage','Label','FileName'}, ...
    {'SubjectEnumeratedIdentifier','SubjectCageIdentifier', ...
    'SubjectTextIdentifier','ElectronicFileName'});

end