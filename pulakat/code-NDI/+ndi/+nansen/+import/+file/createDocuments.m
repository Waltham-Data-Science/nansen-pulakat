function [dataTable] = createDocuments(session, dataTable, labName)
%CREATEDOCUMENTS Creates NDI file documents from a table.

% Get project info
projectFile = fullfile('+ndi','+setup','+conv',['+',labName],'project_info.json');
projectInfo = jsondecode(fileread(projectFile));
fileTypes = {projectInfo.dataFileTypes.DataTypeName};

[dataFiles_unique,~,indUnique] = unique(dataTable(:,{'ElectronicFileName','DataTypeName'}),'stable');

% Create data documents
[generic_file_docs,ontologyLabel_docs] = deal(cell(height(dataFiles_unique),1));
for i = 1:height(dataFiles_unique)

    % Get subject document id(s)
    subject_id = dataTable.SubjectDocumentIdentifier(indUnique == i);
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

    % Update dataTable with new FileDocumentIdentifier
    indRows = (indUnique == i);
    dataTable.FileDocumentIdentifier(indRows) = {generic_file_doc.id};
end

% Add files to database
session.database_add(generic_file_docs);
session.database_add(ontologyLabel_docs);

end
