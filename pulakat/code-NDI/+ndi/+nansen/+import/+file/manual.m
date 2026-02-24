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
subjectTable = ndi.nansen.metatable.subject(session);
if isempty(subjectTable)
    error('No subjects found in session. Please add a subject first.');
end
subjectNames = subjectTable.SubjectLocalIdentifier;

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
        newRow.SubjectLocalIdentifier = subjectTable.SubjectLocalIdentifier(indSubj(j));
        newRow.SubjectDocumentIdentifier = subjectTable.SubjectDocumentIdentifier(indSubj(j));
        dataTable_new = [dataTable_new; newRow];
    end
end

if isempty(dataTable_new); return; end

% Get existing data table from session
dataTable_session = ndi.nansen.metatable.file(session);

% Identify new and unique files (prevent duplicates)
fileIdentifiers = {'ElectronicFileName','DataTypeName','SubjectDocumentIdentifier'};
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

[dataFiles_unique,~,indUnique] = unique(dataTable_new(:,{'ElectronicFileName','DataTypeName'}),'stable');

% Create data documents
[generic_file_docs,ontologyLabel_docs] = deal(cell(height(dataFiles_unique),1));
for i = 1:height(dataFiles_unique)

    % Get subject document id(s)
    subject_id = dataTable_new.SubjectDocumentIdentifier(indUnique == i);
    if isscalar(subject_id)
        subject_id = subject_id{1};
    else
        % If more than one subject, make subject group
        subject_group_doc = ndi.document('subject_group') + session.newdocument();
        for j = 1:numel(subject_id)
            subject_group_doc = subject_group_doc.add_dependency_value_n(...
                'subject_id',subject_id{j});
        end
        subject_id = subject_group_doc.id;
        session.database_add(subject_group_doc);
    end

    % Define file format and label
    indFileType = strcmp(fileTypes,dataFiles_unique.DataTypeName{i});
    fileName = dataFiles_unique.ElectronicFileName{i};
    fileFormat = projectInfo.dataFileTypes(indFileType).format;
    fileDelete = projectInfo.dataFileTypes(indFileType).delete;

    if projectInfo.dataFileTypes(indFileType).zip
        filePath = [fileName,'.zip'];
        if ~exist(filePath,'file')
            zip(filePath, fileName);
        end
    else
        filePath = fileName;
    end

    % Get file metadata
    checksum = ndi.fun.file.MD5(filePath);
    dateCreated = convertTo(ndi.fun.file.dateCreated(fileName),'datenum');
    dateUpdated = convertTo(ndi.fun.file.dateUpdated(fileName),'datenum');

    % Create generic_file document
    generic_file = struct('filename',fileName,'formatOntology',fileFormat, ...
        'checksum',checksum,'dateCreated',dateCreated,'dateUpdated',dateUpdated);
    generic_file_doc = ndi.document('generic_file','generic_file',generic_file) + ...
        session.newdocument();
    generic_file_doc = generic_file_doc.add_file('generic_file.ext',filePath,...
        'delete_original',fileDelete);
    generic_file_doc = generic_file_doc.set_dependency_value('document_id', subject_id);
    generic_file_docs{i} = generic_file_doc;

    % Create ontologyLabel document
    ontologyID = ndi.ontology.lookup(['EMPTY:',dataFiles_unique.DataTypeName{i}]);
    ontologyLabel = struct('ontologyNode',ontologyID);
    ontologyLabel_doc = ndi.document('ontologyLabel', ...
        'ontologyLabel',ontologyLabel) + session.newdocument;
    ontologyLabel_doc = ontologyLabel_doc.set_dependency_value( ...
        'document_id',generic_file_doc.id);
    ontologyLabel_docs{i} = ontologyLabel_doc;
end

% Add files to database
session.database_add(generic_file_docs);
session.database_add(ontologyLabel_docs);

% Return updated data table
dataTable = ndi.nansen.metatable.file(session);

end
