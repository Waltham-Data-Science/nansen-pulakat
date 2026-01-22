function [subjectTable] = subject(session,subjectTable,options)
%SUBJECTS Imports subjects into an NDI session from a specified data path.
%   This function identifies new subjects from 'animal_mapping' files,
%   creates corresponding subject documents, and adds them to the
%   NDI session's database.
%
%   Inputs:
%       session (ndi.session.dir): The NDI session object where the 
%           subjects will be imported.
%       dataPath (char or string): Optional. The path to the directory 
%           containing the subject files. If not provided, the function 
%           will look for files in the current directory.
%
%   Outputs:
%       subjectTable (table): An updated table containing information about
%           all subjects in the session, including the newly imported subjects.

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

% Create subjectMaker and tableDocMaker
subjectMaker = ndi.setup.NDIMaker.subjectMaker();
subjectCreator = run(ndi.setup.conv.(options.Project.Name).informationCreator);
tableDocMaker = ndi.setup.NDIMaker.tableDocMaker(session,options.Project.Name);

% Create subject documents (and add to session)
[~,subjectTable.SubjectLocalIdentifier,subjectTable.SubjectDocumentIdentifier] = ...
    subjectMaker.addSubjectsFromTable(session,subjectTable,subjectCreator);

% Create ontologyTableRow documents (and add to session)
tableRowVariables = ['SubjectLocalIdentifier','SubjectDocumentIdentifier',...
    subjectIdentifiers,'Treatment','ElectronicFileName'];
tableDocMaker.table2ontologyTableRowDocs(subjectTable_new(:,tableRowVariables), ...
        {'SubjectDocumentIdentifier'});

% Return updated subject table
subjectTable = ndi.nansen.metatable.subject(session);

end