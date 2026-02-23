function [dataTable] = data(session, dataPath, labName)
%DATA Imports data into an NDI session from a specified data path.
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

% Get existing data table from session
dataTable_session = ndi.nansen.metatable.file(session);

% Identify new and unique files
fileIdentifiers = {'ElectronicFileName','DataTypeName'};
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

% Create data documents
[generic_file_docs,ontologyLabel_docs] = deal(cell(height(dataFiles_new),1));
for i = 1:height(dataFiles_new)

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
    indFileType = strcmp(fileTypes,dataFiles_new.DataTypeName{i});
    fileName = dataFiles_new.ElectronicFileName{i};
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
    ontologyID = ndi.ontology.lookup(['EMPTY:',dataFiles_new.DataTypeName{i}]);
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