function [metaTable] = edit(dataTable, dataName, options)
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
    options.LabName {mustBeTextScalar} = nansen.getCurrentProject().Name;
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
        editableVars = {'TotalDocuments','CloudDocuments','DatasetUpdated'};
    case 'Session'
        editableVars = {'NumSubjects';'NumFiles';'DataTypeName';'Cloud'};
    case'Subject'
        editableVars = {'NumFiles';'DataTypeName';'Cloud'};
    case 'File'
        editableVars = {'Cloud'};
end

% Check if row already has an NDI document
documentID = metaTable.entries.([dataName,'DocumentIdentifier']){rowInd};
if isempty(documentID)
    switch dataName
        case'Subject'
            editableVars = [editableVars;{projectInfo.subjectFileColumns.name}';...
                {'SubjectDocumentIdentifier';'SubjectLocalIdentifier';'ElectronicFileName'}];
        case 'File'
            editableVars = [editableVars;{projectInfo.subjectFileColumns.name}';...
                'SubjectDocumentIdentifier';'FileDocumentIdentifier'];
    end
end

% Remove any variables that don't exist in the data table
editableVars = intersect(cellstr(editableVars),...
    dataTable.Properties.VariableNames);

% Update Nansen metatable values
for i = 1:numel(editableVars)
    newValue = dataTable{1, editableVars{i}};
    oldValue = metaTable.entries{rowInd,editableVars{i}};
    if ~isequaln(newValue,oldValue) && ... % old and new are not equal
            ~isempty(newValue) && ~isequal(newValue,{''}) % new is not empty
        metaTable.editEntries(rowInd,editableVars{i},newValue);
    end
end
metaTable.save();

end
