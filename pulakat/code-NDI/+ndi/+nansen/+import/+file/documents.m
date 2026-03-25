function [dataTable] = documents(session, dataTable, options)
%CREATEDOCUMENTS Creates NDI file documents tethered to Subject UIDs.
%
%   This function implements the Tier 3 -> Tier 4 hierarchical sync.
%   Files are established as children of their parent Subject UID
%   within the NDI database.
%
%   Inputs:
%      session (ndi.session.dir): The NDI session object.
%      dataTable (table): A table containing the file records.
%      labName (char or string): The name of the lab.
%
%   Outputs:
%      dataTable (table): The updated Nansen 'File' metatable entries
%         with established UIDs.
%
%   Examples:
%      % Create NDI documents for session files:
%      ndi.nansen.import.file.createDocuments(session, myFileTable, 'pulakat')
%
%   See also: NDI.NANSEN.IMPORT.SUBJECT.DOCUMENTS

% Input argument validation
arguments
    session {mustBeA(session,{'ndi.session.dir'})}
    dataTable table
    options.LabName {mustBeText} = nansen.getCurrentProject().Name;
end

% Get project info
labName = char(options.LabName);
projectFile = fullfile('+ndi','+setup','+conv',['+',labName],'project_info.json');
projectInfo = jsondecode(fileread(projectFile));
fileTypes = {projectInfo.dataFileTypes.DataTypeName};

% Framework object
tableDocMaker = ndi.setup.NDIMaker.tableDocMaker(session,labName);

% Get unique files
[dataFiles_unique,~,indUnique] = unique(dataTable(:,{'ElectronicFileName','DataTypeName'}),'stable');
numFiles = height(dataFiles_unique);

% Create data documents
[generic_file_docs,ontologyLabel_docs] = deal(cell(numFiles,1));

for i = 1:numFiles

    % Get subject document id
    subject_id = dataTable.SubjectDocumentIdentifier(indUnique == i);
    if isscalar(subject_id)
        parent_uid = subject_id{1};
    else
        % If more than one subject, make subject group
        subject_group_doc = ndi.document('subject_group') + session.newdocument();
        for j = 1:numel(subject_id)
            subject_group_doc = subject_group_doc.add_dependency_value_n(...
                'subject_id',subject_id{j});
        end
        parent_uid = subject_group_doc.id;
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

    % 2. Create generic_data document
    generic_file = struct('filename',fileName,'formatOntology',fileFormat, ...
        'checksum',checksum,'dateCreated',dateCreated,'dateUpdated',dateUpdated);

    generic_file_doc = ndi.document('generic_file','generic_file',generic_file) + ...
        session.newdocument();

    generic_file_doc = generic_file_doc.add_file('generic_file.ext',filePath,...
        'delete_original',fileDelete);

    generic_file_doc = generic_file_doc.set_dependency_value('document_id', parent_uid);
    generic_file_docs{i} = generic_file_doc;

    % 3. Create ontologyLabel document
    ontologyID = ndi.ontology.lookup(['EMPTY:',dataFiles_unique.DataTypeName{i}]);
    ontologyLabel = struct('ontologyNode',ontologyID);
    ontologyLabel_doc = ndi.document('ontologyLabel', ...
        'ontologyLabel',ontologyLabel) + session.newdocument;
    ontologyLabel_doc = ontologyLabel_doc.set_dependency_value( ...
        'document_id',generic_file_doc.id);
    ontologyLabel_docs{i} = ontologyLabel_doc;

    % Update dataTable_pending with new FileDocumentIdentifier
    indRows = (indUnique == i);
    dataTable.FileDocumentIdentifier(indRows) = {generic_file_doc.id};
end

% Add files to database
session.database_add(generic_file_docs);
session.database_add(ontologyLabel_docs);

% 4. Create ontologyTableRow document
indOTR = strcmp({projectInfo.dataFileColumns.document},'ontologyTableRow');
tableRowVariables = [{projectInfo.dataFileColumns(indOTR).name},...
    'FileDocumentIdentifier','SubjectDocumentIdentifier'];
tableDocMaker.table2ontologyTableRowDocs(dataTable(:,tableRowVariables), ...
    {'FileIdentifier'},'DependencyVariable',{'FileDocumentIdentifier','SubjectDocumentIdentifier'});

end