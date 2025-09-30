function [dataTable] = data(session,dataPath)
%DATA Summary of this function goes here
%   Detailed explanation goes here

% Input argument validation
arguments
    session {mustBeA(session,{'ndi.session.dir'})}
    dataPath {mustBeText} = '';
end

% Retrieve data files
dataFiles = pulakat.import.file.select(dataPath);

% Get current data table from files
dataTable_files = pulakat.import.data.tableFromFiles(session,dataFiles);

% Get existing data table from session
dataTable_session = pulakat.import.data.tableFromSession(session);

% Identify new and unique files
fileIdentifiers = {'ElectronicFileName'};
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
    fileName = dataFiles_new.ElectronicFileName{i};
    filePath = fileName;
    switch dataFiles_new.DataType{i}
        case 'experiment metadata file'
            fileFormat = 'format:3620';
            fileDelete = 0;
        case 'data-independent acquisition (DIA)'
            fileFormat = 'format:3620';
            fileDelete = 0;
        case 'slide scanner image acquisition'
            fileFormat = 'NCIT:C172214';
            fileDelete = 0;
        case 'echocardiogram acquisition'
            fileFormat = 'format:3987';
            fileDelete = 1;
            filePath = [fileName,'.zip'];
            
            % Zip files in the echo session
            if ~exist(filePath,'file')
                zip(filePath, fileName);
            end
    end

    % Create generic_file document
    generic_file = struct('filename',fileName,'formatOntology',fileFormat);
    generic_file_doc = ndi.document('generic_file','generic_file',generic_file) + ...
        session.newdocument();
    generic_file_doc = generic_file_doc.add_file('generic_file.ext',filePath,...
        'delete_original',fileDelete);
    generic_file_doc = generic_file_doc.set_dependency_value('document_id', subject_id);
    generic_file_docs{i} = generic_file_doc;

    % Create ontologyLabel document
    ontologyID = ndi.ontology.lookup(['EMPTY:',dataFiles_new.DataType{i}]);
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
dataTable = pulakat.import.data.tableFromSession(session);

% Upload files to cloud
%ndi.cloud.sync.uploadNew(dataset)

end

