function varargout = sync(datasetObject, varargin)
%SYNC Synchronizes the local dataset with the NDI cloud.
%
%   This object method attempts to upload new local documents to the cloud.
%   It also updates the local dataset metatable.
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

    % Get project info
    projectFile = fullfile('+ndi','+setup','+conv',['+',labName],'project_info.json');
    projectInfo = jsondecode(fileread(projectFile));
    subjectIdentifiers = projectInfo.subjectIdentifierFields;

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
            if ~isempty(doc)
                sessionTable.SessionDocumentIdentifier{i} = doc{1}.document_properties.base.id;
                sessionTable.SessionIdentifier{i} = session.id;
            else
                warning('Could not find NDI document for session: %s', sessionName);
            end
        end
    end
    ndi.nansen.metatable.add(sessionTable, 'Session');

    % 2. Create NDI Subject documents if missing
    subjectMetaTable = project.MetaTableCatalog.getMetaTable('Subject');
    subjectTable = subjectMetaTable.entries;
    if ~isempty(subjectTable)
        indPending = cellfun(@isempty, subjectTable.SubjectDocumentIdentifier);
    else
        indPending = false(0,1);
    end

    if any(indPending)
        pendingSubjects = subjectTable(indPending, :);
        uniqueSessions = unique(pendingSubjects.SessionIdentifier);
        for i = 1:numel(uniqueSessions)
            if isempty(uniqueSessions{i}); continue; end
            session = dataset.open_session(uniqueSessions{i});
            indSess = strcmp(pendingSubjects.SessionIdentifier, uniqueSessions{i});
            createdSubjects = ndi.nansen.import.subject.createDocuments(session, pendingSubjects(indSess, :), labName);

            % Update main table
            for j = 1:height(createdSubjects)
                indSubjMatch = true(height(subjectTable),1);
                for f = 1:numel(subjectIdentifiers)
                    indSubjMatch = indSubjMatch & strcmp(subjectTable.(subjectIdentifiers{f}), createdSubjects.(subjectIdentifiers{f}){j});
                end
                ind = strcmp(subjectTable.SessionIdentifier, uniqueSessions{i}) & indSubjMatch;
                subjectTable.SubjectDocumentIdentifier(ind) = createdSubjects.SubjectDocumentIdentifier(j);
                subjectTable.SubjectLocalIdentifier(ind) = createdSubjects.SubjectLocalIdentifier(j);
            end
        end
        ndi.nansen.metatable.add(subjectTable, 'Subject');
    end

    % 3. Create NDI File documents if missing
    fileMetaTable = project.MetaTableCatalog.getMetaTable('File');
    fileTable = fileMetaTable.entries;

    if ~isempty(fileTable)
        % Update SubjectDocumentIdentifier and SubjectLocalIdentifier in fileTable from subjectTable
        [Lia, indS] = ismember(fileTable(:, [{'SessionIdentifier'}, subjectIdentifiers']), ...
            subjectTable(:, [{'SessionIdentifier'}, subjectIdentifiers']));

        fileTable.SubjectDocumentIdentifier(Lia) = subjectTable.SubjectDocumentIdentifier(indS(Lia));
        fileTable.SubjectLocalIdentifier(Lia) = subjectTable.SubjectLocalIdentifier(indS(Lia));

        indPending = cellfun(@isempty, fileTable.FileDocumentIdentifier);
    else
        indPending = false(0,1);
    end
    if any(indPending)
        pendingFiles = fileTable(indPending, :);
        uniqueSessions = unique(pendingFiles.SessionIdentifier);
        for i = 1:numel(uniqueSessions)
            session = dataset.open_session(uniqueSessions{i});
            indSess = strcmp(pendingFiles.SessionIdentifier, uniqueSessions{i});
            createdFiles = ndi.nansen.import.file.createDocuments(session, pendingFiles(indSess, :), labName);

            % Update main table
            for j = 1:height(createdFiles)
                % Match using identifying fields since SubjectLocalIdentifier might have just been created
                indSubjMatch = true(height(fileTable),1);
                for f = 1:numel(subjectIdentifiers)
                    indSubjMatch = indSubjMatch & strcmp(fileTable.(subjectIdentifiers{f}), createdFiles.(subjectIdentifiers{f}){j});
                end

                ind = strcmp(fileTable.SessionIdentifier, uniqueSessions{i}) & ...
                      indSubjMatch & ...
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
        success = ndi.cloud.sync.uploadNew(dataset);
        if ~success
            error('Could not sync dataset to cloud.');
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
