function [dataTable] = file(session,dataTable,options)
%SUBJECT Summary of this function goes here
%   Detailed explanation goes here

% Input argument validation
arguments
    session {mustBeA(session,{'ndi.session.dir'})}
    dataTable table
    options.LabName {mustBeText} = nansen.getCurrentProject().Name;
    options.Project {mustBeA(options.Project,'nansen.config.project.Project')} = nansen.getCurrentProject;
end

% Convert inputs to char arrays for internal processing
labName = char(options.LabName);

% Get project info
projectFile = fullfile('+ndi','+setup','+conv',['+',labName],'project_info.json');
projectInfo = jsondecode(fileread(projectFile));

% Get current data table from project
project = nansen.getCurrentProject;
fileMetaTable = project.MetaTableCatalog.getMetaTable('File');
dataTable_project = fileMetaTable.entries;
if ~isempty(dataTable_project)
    % Only include files for current session
    indSession = strcmp(dataTable_project.SessionIdentifier, session.id);
    dataTable_session = dataTable_project(indSession, :);
else
    dataTable_session = table();
end

% Add new subjects (if necessary)
subjectIdentifiers = intersect(dataTable.Properties.VariableNames,...
    projectInfo.subjectIdentifierFields);
subjectTable = ndi.nansen.import.subject(session,dataTable(:,subjectIdentifiers),...
    'LabName',options.LabName,'Project',options.Project);

% Join the subject table with the dataTable with subjectIdentifiers as keys
% Check the existing dataTable_session against the new dataTable
% Remove duplicates
% Add new rows

% Get subject identifying fields
subjectIdentifiers = projectInfo.subjectIdentifierFields;

% Identify new and unique files
fileIdentifiers = {'ElectronicFileName','DataTypeName','SubjectIdentifier'};
if isempty(dataTable_session)
    dataTable_new = dataTable;
else
    [~,indNew] = setdiff(dataTable(:,fileIdentifiers), ...
        dataTable_session(:,fileIdentifiers));
    dataTable_new = dataTable(indNew,:);
end
[dataFiles_new,~,indUnique] = unique(dataTable_new(:,fileIdentifiers),'stable');

% Check whether there are new files to add
if isempty(dataFiles_new)
    warning('No new files found in: %s.',strjoin(dataFiles,';'))
    dataTable = dataTable_files;
    return
end

% Add session and other metadata
dataTable_new.SessionIdentifier = repmat({session.id}, height(dataTable_new), 1);
dataTable_new.SessionName = repmat({session.reference}, height(dataTable_new), 1);
dataTable_new.SessionPath = repmat({session.path}, height(dataTable_new), 1);
dataTable_new.FileDocumentIdentifier = repmat({''}, height(dataTable_new), 1);
dataTable_new.FileIdentifier = ndi.nansen.fun.getIdentifier(dataTable_new, 'File', labName);
dataTable_new.DateAdded = repmat(datetime('now'), height(dataTable_new), 1);
dataTable_new.Cloud = false(height(dataTable_new), 1);

% Return new data table
dataTable = dataTable_new;

end

