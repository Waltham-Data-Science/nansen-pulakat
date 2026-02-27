function [dataTable] = edit(dataTable, dataName, options)
%EDIT Edits metadata in an NDI session.
%
%   This function allows the user to interactively edit metadata for a
%   subject or file in an NDI session and updates the corresponding NDI
%   documents and Nansen metatables.
%
%   Inputs:
%       session (ndi.session.dir): The NDI session object.
%       dataTable (table): A table containing the metadata (1 row).
%       type (char): The type of metadata to edit ('subject' or 'file').
%       options.EditableVariables (cell array): Optional. A list of
%           variables that can be edited.
%       options.Project (nansen.config.project.Project): Optional. The
%           Nansen project object.
%
%   Outputs:
%       dataTable (table): The updated metadata table.

% Input argument validation
arguments
    dataTable (1,:) table
    dataName {mustBeMember(dataName,{'Dataset','Session','Subject','File'})}
    options.LabName {mustBeText} = nansen.getCurrentProject().Name;
    options.Project {mustBeA(options.Project,'nansen.config.project.Project')} = nansen.getCurrentProject;
end

% Convert inputs to char arrays for internal processing
labName = char(options.LabName);

% Get project info
projectFile = fullfile('+ndi','+setup','+conv',['+',labName],'project_info.json');
projectInfo = jsondecode(fileread(projectFile));

% Get metatable
metaTable = options.Project.MetaTableCatalog.getMetaTable(dataName);
rowInd = metaTable.getIndexById(dataTable.(metaTable.MetaTableIdVarname){1});

% Set default editable variables if not provided
switch dataName
    case 'Dataset'
        editableVariables = {'TotalDocuments','CloudDocuments','DatasetUpdated'};
    case 'Session'
        editableVariables = {'NumSubjects';'NumFiles';'DataTypeName';'Cloud'};
    case'Subject'
        editableVariables = {'NumFiles';'DataTypeName';'Cloud'};
    case 'File'
        editableVariables = {'Cloud'};
end

% Check if row already has an NDI document
documentID = metaTable.entries.([dataName,'DocumentIdentifier']){rowInd};
if isempty(documentID)
    switch dataName
        case'Subject'
            editableVariables = [editableVariables;{projectInfo.subjectFileColumns.name}';...
                {'SubjectDocumentIdentifier';'SubjectLocalIdentifier';'ElectronicFileName'}];
        case 'File'
            editableVariables = [editableVariables;{projectInfo.subjectFileColumns.name}';...
                'SubjectDocumentIdentifier';'FileDocumentIdentifier'];
    end
end

% Remove any variables that don't exist in the data table
editableVariables = intersect(cellstr(editableVariables),...
    dataTable.Properties.VariableNames);

% Update Nansen metatable
for i = 1:numel(editableVariables)
    metaTable.editEntries(rowInd, editableVariables{i}, ...
        dataTable{1, editableVariables{i}});
end
metaTable.save();

dataTable = metaTable.entries;

end
