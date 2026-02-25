function [dataTable] = auto(session, dataPath, labName)
%AUTO Imports data into an NDI session from a specified data path.
%
%   This function identifies new data files in the given path, creates
%   corresponding data and ontologyLabel documents, and adds them to the
%   NDI session's database. It handles different data types and associates
%   the data with the correct subject.
%
%   Inputs:
%       session (ndi.session.dir): The NDI session object where the data 
%           will be imported.
%       dataPath (char or string): Optional. The path to the directory 
%           containing the data files. Defaults to the current directory.
%       labName (char or string): Optional. The name of the lab. Defaults
%           to the current project name.
%
%   Outputs:
%       dataTable (table): An updated table containing information about 
%           all data in the session, including the newly imported data.

% Input argument validation
arguments
    session {mustBeA(session,{'ndi.session.dir'})}
    dataPath {mustBeText} = '';
    labName {mustBeText} = nansen.getCurrentProject().Name;
end

% Convert inputs to char arrays for internal processing
dataPath = char(dataPath);
labName = char(labName);

% Get project info
projectFile = fullfile('+ndi','+setup','+conv',['+',labName],'project_info.json');
projectInfo = jsondecode(fileread(projectFile));
fileTypes = {projectInfo.dataFileTypes.DataTypeName};

% Retrieve data files
dataFiles = ndi.nansen.import.file.select(dataPath);

% Get current data table from files
dataTable_files = ndi.nansen.import.data.tableFromFile(session,dataFiles);

% Get existing data table from project
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

% Get subject identifying fields
subjectIdentifiers = projectInfo.subjectIdentifierFields;

% Identify new and unique files
fileIdentifiers = [{'ElectronicFileName','DataTypeName'}, subjectIdentifiers'];
if isempty(dataTable_session)
    dataTable_new = dataTable_files;
else
    [~,indNew] = setdiff(dataTable_files(:,fileIdentifiers), ...
        dataTable_session(:,fileIdentifiers));
    dataTable_new = dataTable_files(indNew,:);
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