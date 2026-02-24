function varargout = sync(datasetObject, varargin)
%SYNC Synchronizes the local dataset with the NDI cloud.
%
%   This object method attempts to upload new local documents to the cloud
%   and performs a two-way sync if necessary. It also updates the local
%   dataset metatable.
%
%   Inputs:
%       datasetObject (struct): A structure representing the dataset.
%       varargin: Optional name-value pairs for parameters.
%
%   Outputs:
%       varargout: If called without inputs, returns the method's attributes.

    % Get struct of parameters from local function
    params = getDefaultParameters();
    
    % Create a cell array with attribute keywords
    ATTRIBUTES = {'serial', 'queueable'};
    
    % Create a struct with "attributes" using a predefined pattern
    import nansen.session.SessionMethod
    fcnAttributes = SessionMethod.setAttributes(params, ATTRIBUTES{:});
    
    if ~nargin && nargout > 0
        varargout = {fcnAttributes};   return
    end
    
    % Parse name-value pairs from function input and update parameters
    params = utility.parsenvpairs(params, [], varargin);
    
    % --- Implementation of the method ---

    % Get dataset object
    dataset = ndi.dataset.dir(datasetObject.DatasetPath);

    % Get Nansen project
    project = nansen.getCurrentProject;
    labName = project.Name;

    % 1. Create NDI Session documents if missing
    sessionMetaTable = project.MetaTableCatalog.getMetaTable('Session');
    sessionTable = sessionMetaTable.entries;

    for i = 1:height(sessionTable)
        if isempty(sessionTable.SessionDocumentIdentifier{i})
            sessionPath = sessionTable.SessionPath{i};
            sessionName = sessionTable.SessionName{i};
            [dataParentDir,sessionFolderName] = fileparts(sessionPath);

            SessionRef = {sessionName};
            SessionPath = {sessionFolderName};
            sessionMaker = ndi.setup.NDIMaker.sessionMaker(dataParentDir,...
                table(SessionRef,SessionPath));
            session = sessionMaker.sessionIndices{1};

            % Add to dataset
            [~,sessionIDs] = dataset.session_list;
            if ~any(strcmp(sessionIDs,session.id))
                dataset.add_linked_session(session);
            end

            % Get session document id
            query = ndi.query('base.session_id','exact_string',session.id);
            doc = session.database_search(query);
            sessionTable.SessionDocumentIdentifier{i} = doc{1}.document_properties.base.id;
            sessionTable.SessionIdentifier{i} = session.id;
        end
    end
    ndi.nansen.metatable.add(sessionTable, 'Session');

    % 2. Create NDI Subject documents if missing
    subjectMetaTable = project.MetaTableCatalog.getMetaTable('Subject');
    subjectTable = subjectMetaTable.entries;
    indPending = cellfun(@isempty, subjectTable.SubjectDocumentIdentifier);

    if any(indPending)
        pendingSubjects = subjectTable(indPending, :);
        uniqueSessions = unique(pendingSubjects.SessionIdentifier);
        for i = 1:numel(uniqueSessions)
            session = dataset.open_session(uniqueSessions{i});
            indSess = strcmp(pendingSubjects.SessionIdentifier, uniqueSessions{i});
            createdSubjects = ndi.nansen.import.subject.createDocuments(session, pendingSubjects(indSess, :), labName);

            % Update main table
            for j = 1:height(createdSubjects)
                ind = strcmp(subjectTable.SessionIdentifier, uniqueSessions{i}) & ...
                      strcmp(subjectTable.SubjectLocalIdentifier, createdSubjects.SubjectLocalIdentifier{j});
                subjectTable.SubjectDocumentIdentifier(ind) = createdSubjects.SubjectDocumentIdentifier(j);
            end
        end
        ndi.nansen.metatable.add(subjectTable, 'Subject');
    end

    % 3. Create NDI File documents if missing
    fileMetaTable = project.MetaTableCatalog.getMetaTable('File');
    fileTable = fileMetaTable.entries;

    % Update SubjectDocumentIdentifier in fileTable from subjectTable
    [~, indS] = ismember(fileTable(:, {'SessionIdentifier', 'SubjectLocalIdentifier'}), ...
        subjectTable(:, {'SessionIdentifier', 'SubjectLocalIdentifier'}));
    fileTable.SubjectDocumentIdentifier = subjectTable.SubjectDocumentIdentifier(indS);

    indPending = cellfun(@isempty, fileTable.FileDocumentIdentifier);
    if any(indPending)
        pendingFiles = fileTable(indPending, :);
        uniqueSessions = unique(pendingFiles.SessionIdentifier);
        for i = 1:numel(uniqueSessions)
            session = dataset.open_session(uniqueSessions{i});
            indSess = strcmp(pendingFiles.SessionIdentifier, uniqueSessions{i});
            createdFiles = ndi.nansen.import.file.createDocuments(session, pendingFiles(indSess, :), labName);

            % Update main table
            for j = 1:height(createdFiles)
                ind = strcmp(fileTable.SessionIdentifier, uniqueSessions{i}) & ...
                      strcmp(fileTable.SubjectLocalIdentifier, createdFiles.SubjectLocalIdentifier{j}) & ...
                      strcmp(fileTable.ElectronicFileName, createdFiles.ElectronicFileName{j}) & ...
                      strcmp(fileTable.DataTypeName, createdFiles.DataTypeName{j});
                fileTable.FileDocumentIdentifier(ind) = createdFiles.FileDocumentIdentifier(j);
            end
        end
        ndi.nansen.metatable.add(fileTable, 'File');
    end

    % Sync dataset to cloud
    success = ndi.cloud.sync.uploadNew(dataset);
    if ~success
        warning('Error encountered syncing dataset to cloud. Try logging in again.')
        ndi.cloud.uilogin(true);
        [success,errorMessage] = ndi.cloud.sync.twoWaySync(dataset);
        if ~success
            error('Could not sync dataset to cloud: %s',errorMessage);
        end
    end

    % Update metatable
    datasetTable = ndi.nansen.metatable.dataset(dataset);
    ndi.nansen.metatable.remove(datasetTable,'Dataset');
    ndi.nansen.metatable.add(datasetTable,'Dataset');
    
    % Return session object (please do not remove):
    % if nargout; varargout = {datasetObject}; end
end

function params = getDefaultParameters()
%getDefaultParameters Get the default parameters for this session method
%
%   params = getDefaultParameters() should return a struct, params, which
%   contains fields and values for parameters of this session method.

    % Add fields to this struct in order to define parameters for this
    % session method:
    params = struct();

end
