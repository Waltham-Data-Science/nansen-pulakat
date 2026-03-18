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
project = options.Project;
if ismember('File',project.MetaTableCatalog.Table.MetaTableName)
    fileMetaTable = project.MetaTableCatalog.getMetaTable('File');
    dataTable_project = fileMetaTable.entries;
else
    dataTable_project = table();
end

% Only include files for current session
if ~isempty(dataTable_project)
    indSession = strcmp(dataTable_project.SessionIdentifier, session.id);
    dataTable_session = dataTable_project(indSession, :);
else
    dataTable_session = table();
end

% Add new subjects
subjectIdentifiers = intersect(dataTable.Properties.VariableNames,...
    projectInfo.subjectIdentifierFields);
subjectTable = ndi.nansen.import.subject(session,dataTable(:,subjectIdentifiers),...
    'LabName',options.LabName,'Project',options.Project);

% Add the subject information to the dataTable
[indMatch,numMatch] = ndi.nansen.fun.matchTables(dataTable(:,subjectIdentifiers),...
    subjectTable(:,subjectIdentifiers));
for i = 1:height(dataTable)
    ind = indMatch{i};
    if numMatch(i) > 1
        warning('More than one match found. Skipping second match. Consult NDI to discuss resolutions.')
        ind = ind(1);
    elseif numMatch(i) == 0
        continue
    end
    dataTable.SubjectIdentifier(i) = subjectTable.SubjectIdentifier(ind);
end
dataTable = removevars(dataTable,subjectIdentifiers);

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
    disp('No new data files found.')
    dataTable = dataTable_project;
    return
end

% Add metadata
numFiles = height(dataTable_new);
dataTable_new.FileIdentifier = cellstr(num2hex(rand(numFiles,1) + randi(32727*[-1 1],numFiles,1)));

% Add data table to nansen
ndi.nansen.metatable.merge(dataTable_new,'File','Project',options.Project);

% Return data table
fileMetaTable = project.MetaTableCatalog.getMetaTable('File');
dataTable = fileMetaTable.entries;

end

