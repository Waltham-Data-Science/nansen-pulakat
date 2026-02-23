function [dataTable] = file(session, dataTable, options)
%FILE Edits file metadata in an NDI session.
%
%   This function allows the user to interactively edit metadata for a
%   file in an NDI session and updates the corresponding NDI documents
%   and Nansen metatables.
%
%   Inputs:
%       session (ndi.session.dir): The NDI session object.
%       dataTable (table): A table containing the file's metadata.
%       options.EditableVariables (cell array): Optional. A list of
%           variables that can be edited.
%       options.Project (nansen.config.project.Project): Optional. The
%           Nansen project object.
%
%   Outputs:
%       dataTable (table): The updated file metadata table.

% Input argument validation
arguments
    session {mustBeA(session,{'ndi.session.dir'})}
    dataTable (1,:) table
    options.EditableVariables {mustBeText} = {'DataTypeName'};
    options.Project {mustBeA(options.Project,'nansen.config.project.Project')} = nansen.getCurrentProject;
end

% Check is file is already in the cloud
if dataTable.Cloud
    warning('Cannot update file %s because it is already in the cloud.', ...
        dataTable.ElectronicFileName{1})
    return
end

% Get editable variables and their Nansen column names
settingsFileName = fullfile(options.Project.FolderPath,'metadata','tables','metatable_column_settings.json');
columnSettings = jsondecode(fileread(settingsFileName));
columnMap = containers.Map({columnSettings.VariableName}, {columnSettings.ColumnLabel});

% Query user for file changes
editableVariables = intersect(cellstr(options.EditableVariables),...
    dataTable.Properties.VariableNames);
editableNames = cellfun(@(x) columnMap(x),editableVariables,'UniformOutput',false);
answer = inputdlg(editableNames,'File Metadata',repmat([1 45],numel(editableNames),1),...
    dataTable{1,editableVariables});

if isempty(answer); return; end
dataTable{1,editableVariables} = answer';

% Update ontologyLabel document in NDI
% 1. Find the ontologyLabel document for this file
query = ndi.query('','isa','ontologyLabel') & ...
    ndi.query('depends_on.value','exact_string',dataTable.FileDocumentIdentifier{1});
docs = session.database_search(query);

if ~isempty(docs)
    % 2. Update the ontologyNode
    ontologyID = ndi.ontology.lookup(['EMPTY:',dataTable.DataTypeName{1}]);
    docs{1}.document_properties.ontologyLabel.ontologyNode = ontologyID;
    session.database_add(docs{1}); % database_add with existing ID updates the document
end

% Update Nansen metatable
ndi.nansen.metatable.add(dataTable,'File');

% Return updated data table
dataTable = ndi.nansen.metatable.file(session);

end
