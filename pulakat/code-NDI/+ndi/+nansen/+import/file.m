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

% Add the subject information to the dataTable
[indMatch,numMatch] = ndi.nansen.fun.matchTables(dataTable(:,subjectIdentifiers),...
    subjectTable(:,subjectIdentifiers));
subjectTable_data = table();
subjectVars = [projectInfo.subjectIdentifierFields;{'SubjectIdentifier';...
    'SubjectDocumentIdentifier';'SessionIdentifier';'SessionName';...
    'SessionPath';'SubjectLocalIdentifier'}];
for i = 1:numel(indMatch)
    ind = indMatch{i};
    if numMatch(i) > 1
        warning('More than one match found. Skipping second match. Consult NDI to discuss resolutions.')
        ind = ind(1);
    elseif numMatch(i) == 0
        continue
    end
    subjectTable_data(end+1,:) = subjectTable(ind,subjectVars);
end
dataTable = [removevars(dataTable,subjectIdentifiers),subjectTable_data];

% Identify new and unique files
fileIdentifiers = {'ElectronicFileName','SubjectIdentifier'};
if isempty(dataTable_session)
    dataTable_new = dataTable;
else
    [~,indNew] = setdiff(dataTable(:,fileIdentifiers), ...
        dataTable_session(:,fileIdentifiers));
    dataTable_new = dataTable(indNew,:);
end

% Check whether there are new files to add
if isempty(dataTable_new)
    warning('No new data files found.')
    dataTable = dataTable_project;
    return
end

% Add metadata
numFiles = height(dataTable_new);
dataTable_new.FileDocumentIdentifier = repmat({''},numFiles,1);
dataTable_new.FileIdentifier = cellstr(num2hex(rand(numFiles,1) + randi(32727*[-1 1],numFiles,1)));
dataTable_new.DateAdded = repmat(datetime('now','TimeZone','UTC'),numFiles,1);
dataTable_new.Cloud = false(numFiles, 1);

% Add data table to nansen
ndi.nansen.metatable.add(dataTable_new,'File');

% Return new data table
fileMetaTable = project.MetaTableCatalog.getMetaTable('File');
dataTable = fileMetaTable.entries;

end

