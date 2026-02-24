function [dataTable] = manual(session, labName)
%MANUAL Manually adds a file to an NDI session.
%
%   This function prompts the user to select one or more files and
%   specify their data type, then creates corresponding data documents
%   and adds them to the NDI session's database.
%
%   Inputs:
%       session (ndi.session.dir): The NDI session object.
%       labName (char or string): Optional. The name of the lab. Defaults
%           to the current project name.
%
%   Outputs:
%       dataTable (table): An updated table containing information about
%           all data in the session.

% Input argument validation
arguments
    session {mustBeA(session,{'ndi.session.dir'})}
    labName {mustBeText} = nansen.getCurrentProject().Name;
end

labName = char(labName);

% Get project info
projectFile = fullfile('+ndi','+setup','+conv',['+',labName],'project_info.json');
projectInfo = jsondecode(fileread(projectFile));
fileTypes = {projectInfo.dataFileTypes.DataTypeName};

% Select file(s)
[files, path] = uigetfile('*.*', 'Select File(s) to Import', 'MultiSelect', 'on');
if isequal(files, 0); return; end
if ischar(files); files = {files}; end

% For each file, ask for data type and subject(s)
project = nansen.getCurrentProject;
subjectMetaTable = project.MetaTableCatalog.getMetaTable('Subject');
subjectTable = subjectMetaTable.entries;
if ~isempty(subjectTable)
    % Only include subjects for current session
    indSession = strcmp(subjectTable.SessionIdentifier, session.id);
    subjectTable = subjectTable(indSession, :);
end

if isempty(subjectTable)
    error('No subjects found in session. Please add a subject first.');
end

% Prepare subject names for display (handle pending subjects)
subjectNames = subjectTable.SubjectLocalIdentifier;
subjectIdentifiers = projectInfo.subjectIdentifierFields;
isPending = cellfun(@isempty, subjectNames);
if any(isPending)
    for i = find(isPending)'
        subjectParts = cellfun(@(f) char(subjectTable.(f){i}), ...
            subjectIdentifiers, 'UniformOutput', false);
        subjectNames{i} = [strjoin(subjectParts, '_'), ' (pending)'];
    end
end

dataTable_new = table();

for i = 1:numel(files)
    filePath = fullfile(path, files{i});

    % Select Data Type
    [ind, ok] = listdlg('ListString', fileTypes, 'SelectionMode', 'single', ...
        'Name', ['Data Type for ', files{i}], 'PromptString', 'Select Data Type:');
    if ~ok; continue; end
    dataType = fileTypes{ind};

    % Select Subject(s)
    [indSubj, okSubj] = listdlg('ListString', subjectNames, 'SelectionMode', 'multiple', ...
        'Name', ['Subject(s) for ', files{i}], 'PromptString', 'Select Subject(s):');
    if ~okSubj; continue; end

    % Create entries for this file
    for j = 1:numel(indSubj)
        newRow = table();
        newRow.ElectronicFileName = {filePath};
        newRow.DataTypeName = {dataType};
        % Add subject identifying fields
        for f = 1:numel(subjectIdentifiers)
            fieldName = subjectIdentifiers{f};
            newRow.(fieldName) = subjectTable.(fieldName)(indSubj(j));
        end
        newRow.SubjectDocumentIdentifier = subjectTable.SubjectDocumentIdentifier(indSubj(j));
        dataTable_new = [dataTable_new; newRow];
    end
end

if isempty(dataTable_new); return; end

% Get existing data table from project
fileMetaTable = project.MetaTableCatalog.getMetaTable('File');
dataTable_project = fileMetaTable.entries;
if ~isempty(dataTable_project)
    % Only include files for current session
    indSession = strcmp(dataTable_project.SessionIdentifier, session.id);
    dataTable_session = dataTable_project(indSession, :);
else
    dataTable_session = table();
end

% Identify new and unique files (prevent duplicates)
fileIdentifiers = [{'ElectronicFileName','DataTypeName'}, subjectIdentifiers'];
if ~isempty(dataTable_session)
    [~,indNew] = setdiff(dataTable_new(:,fileIdentifiers), ...
        dataTable_session(:,fileIdentifiers));
    dataTable_new = dataTable_new(indNew,:);
end

if isempty(dataTable_new)
    warning('No new files to add.')
    dataTable = dataTable_session;
    return
end

% Add session and other metadata
dataTable_new.SessionIdentifier = repmat({session.id}, height(dataTable_new), 1);
dataTable_new.SessionName = repmat({session.reference}, height(dataTable_new), 1);
dataTable_new.SessionPath = repmat({session.path}, height(dataTable_new), 1);
dataTable_new.FileDocumentIdentifier = repmat({''}, height(dataTable_new), 1);
dataTable_new.Cloud = false(height(dataTable_new), 1);

% Return new data table
dataTable = dataTable_new;

end
