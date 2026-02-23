function [subjectTable] = subject(session, subjectTable, options)
%SUBJECT Edits subject metadata in an NDI session.
%
%   This function allows the user to interactively edit metadata for a
%   subject in an NDI session and updates the corresponding NDI documents
%   and Nansen metatables.
%
%   Inputs:
%       session (ndi.session.dir): The NDI session object.
%       subjectTable (table): A table containing the subject's metadata.
%       options.EditableVariables (cell array): Optional. A list of
%           variables that can be edited.
%       options.Project (nansen.config.project.Project): Optional. The
%           Nansen project object.
%
%   Outputs:
%       subjectTable (table): The updated subject metadata table.

% Input argument validation
arguments
    session {mustBeA(session,{'ndi.session.dir'})}
    subjectTable (1,:) table
    options.EditableVariables {mustBeText} = {'SubjectEnumeratedIdentifier',...
        'SubjectCageIdentifier','SubjectTextIdentifier','Treatment',...
        'StrainName','SpeciesName','BiologicalSexName','DataTypeName'};
    options.Project {mustBeA(options.Project,'nansen.config.project.Project')} = nansen.getCurrentProject;
end

% Check is subject is already in the cloud
if subjectTable.Cloud
    warning('Cannot update subject %s because it is already in the cloud.', ...
        subjectTable.SubjectLocalIdentifier)
    return
end

% Get editable variables and their Nansen column names
settingsFileName = fullfile(options.Project.FolderPath,'metadata','tables','metatable_column_settings.json');
columnSettings = jsondecode(fileread(settingsFileName));
columnMap = containers.Map({columnSettings.VariableName}, {columnSettings.ColumnLabel});

% Query user for subject changes
editableVariables = intersect(cellstr(options.EditableVariables),...
    subjectTable.Properties.VariableNames);
editableNames = cellfun(@(x) columnMap(x),editableVariables,'UniformOutput',false);
answer = inputdlg(editableNames,'Subject Metadata',repmat([1 45],numel(editableNames),1),...
    subjectTable{1,editableVariables});

if isempty(answer); return; end
subjectTable{1,editableVariables} = answer';

% Get project info
labName = options.Project.Name;
projectFile = fullfile('+ndi','+setup','+conv',['+',labName],'project_info.json');
projectInfo = jsondecode(fileread(projectFile));

% Create subjectMaker and tableDocMaker
subjectMaker = ndi.setup.NDIMaker.subjectMaker();
subjectCreator = ndi.nansen.import.subject.informationCreator();
tableDocMaker = ndi.setup.NDIMaker.tableDocMaker(session,labName);

% Create subject documents (and add to session)
[~,subjectTable.SubjectLocalIdentifier,subjectTable.SubjectDocumentIdentifier] = ...
    subjectMaker.addSubjectsFromTable(session,subjectTable,subjectCreator);

% Create ontologyTableRow documents (and add to session)
ind = strcmp({projectInfo.subjectFileColumns.document},'ontologyTableRow');
tableRowVariables = ['SubjectLocalIdentifier','SubjectDocumentIdentifier',...
    {projectInfo.subjectFileColumns(ind).name},'ElectronicFileName'];
tableDocMaker.table2ontologyTableRowDocs(subjectTable(:,tableRowVariables), ...
        {'SubjectDocumentIdentifier'});

% Return updated subject table
subjectTable = ndi.nansen.metatable.subject(session);

end