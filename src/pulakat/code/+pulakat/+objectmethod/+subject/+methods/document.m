function varargout = document(subjectObject, varargin)
%DOCUMENT Validate and create NDI documents for selected subjects.
%
%   Object method backing the Subject table's 'Document' action. Runs the
%   subject validator, creates NDI subject documents for every valid row
%   that isn't already documented, refreshes the metatables, and displays
%   a validation report.
%
%   Inputs:
%       subjectObject (struct array): The selected Nansen subject records.
%       varargin: Optional name-value pairs (currently unused).

    params = getDefaultParameters();
    ATTRIBUTES = {'batch', 'queueable'};

    import nansen.session.SessionMethod
    fcnAttributes = SessionMethod.setAttributes(params, ATTRIBUTES{:});

    if ~nargin && nargout > 0
        varargout = {fcnAttributes};   return
    end

    params = utility.parsenvpairs(params, [], varargin); %#ok<NASGU>

    % Get dataset object. Fall back to the project's Dataset metatable
    % if the selected row's DatasetIdentifier is empty (orphan rows).
    dataset = ndi.nansen.fun.datasetID2Object( ...
        ndi.nansen.fun.resolveDatasetID(subjectObject(1).DatasetIdentifier));

    % Update subject metatable, restricted to the selected subjects'
    % rows so a click on N subjects doesn't recompute every other
    % subject's HasUpdateFunction variables.
    subjectIDs = {subjectObject.SubjectIdentifier};
    ndi.nansen.metatable.update(dataset,'Subject', ...
        'UpdateRowIdentifiers', subjectIDs);

    project = nansen.getCurrentProject;
    metaTable = project.MetaTableCatalog.getMetaTable('Subject');

    % Validate -> review -> (optionally edit) -> revalidate. Re-fetch
    % the subject rows from the metatable on each iteration because
    % the inner Edit call mutates them. The loop exits when:
    %   - everything is clean (no invalid, no already-documented), or
    %   - user picks "Create N document(s)", or
    %   - user picks Cancel / Close / closes the dialog.
    while true
        subjectTable = metaTable.getEntry({subjectObject.SubjectIdentifier});
        [isValid, reportTable] = ndi.nansen.import.subject.validate(subjectTable);

        % Per-row strcmp; isequal(..., {'N/A'}) compares the whole cell
        % column against a length-1 cell and is only true for a
        % single-row table.
        isDocument = ~strcmp(subjectTable.SubjectDocumentIdentifier, 'N/A');
        nToCreate  = sum(isValid & ~isDocument);
        haveInvalid = any(~isValid);

        % Clean: no dialog, proceed straight to creation.
        if ~haveInvalid && ~any(isDocument)
            break
        end

        % Build button set for this iteration. The Edit path is only
        % offered when there's at least one invalid row.
        if nToCreate == 0 && ~haveInvalid
            buttons = {'Close'};
        elseif nToCreate == 0
            buttons = {'Edit invalid', 'Cancel'};
        elseif haveInvalid
            buttons = {'Edit invalid first', ...
                       sprintf('Create %d document(s)', nToCreate), ...
                       'Cancel'};
        else
            buttons = {sprintf('Create %d document(s)', nToCreate), ...
                       'Cancel'};
        end

        choice = ndi.nansen.fun.showValidationReport(isValid, reportTable, ...
            'IsDocumented', isDocument, ...
            'Buttons', buttons, ...
            'Default', buttons{1}, ...
            'Title', 'Subject documents');

        if startsWith(choice, "Edit ")
            % Hand the invalid rows directly to the Edit object method
            % so the user doesn't have to re-select them. Match by
            % SubjectIdentifier rather than positional index because
            % metaTable.getEntry doesn't promise to return rows in the
            % order ids were requested. After edit completes, the loop
            % re-fetches and re-validates so the user can iterate
            % until they're ready to Create or Cancel.
            invalidIDs = subjectTable.SubjectIdentifier(~isValid);
            allIDs = {subjectObject.SubjectIdentifier};
            invalidObjects = subjectObject(ismember(allIDs, invalidIDs));
            if isempty(invalidObjects); return; end
            pulakat.objectmethod.subject.methods.edit(invalidObjects);
            continue
        end

        if startsWith(choice, "Create ")
            break
        end

        % Cancel, Close, or X.
        return
    end

    % Create documents. Group selected rows by SessionIdentifier (not
    % SessionPath) because a dataset and a session can share a
    % directory: collapsing on path would merge rows that belong to
    % different sessions into one ndi.session.dir(name, path) call,
    % which silently picks the dataset's default session. Pass the id
    % as ndi.session.dir's third positional arg to pin resolution.
    subjectTable_valid = subjectTable(isValid & ~isDocument,:);
    sessionIds = unique(subjectTable_valid.SessionIdentifier);
    for i = 1:numel(sessionIds)
        indSession = strcmp(subjectTable_valid.SessionIdentifier,sessionIds{i});
        firstRow = find(indSession,1);
        sessionName = subjectTable_valid.SessionName{firstRow};
        sessionPath = subjectTable_valid.SessionPath{firstRow};
        session = ndi.session.dir(sessionName, sessionPath, sessionIds{i});
        assert(strcmp(session.id, sessionIds{i}), ...
            'Pulakat:Subject:Document:SessionMismatch', ...
            ['[Pulakat:Subject:Document:SessionMismatch] Resolved ' ...
             'session id %s does not match metatable %s.'], ...
            session.id, sessionIds{i});
        ndi.nansen.import.subject.documents(session,subjectTable_valid(indSession,:));
    end

    % Update metatables. Subject is restricted to the selected
    % subjects again; Dataset is a single-row table so a full pass
    % is the same as a targeted pass.
    ndi.nansen.metatable.update(dataset,'Subject', ...
        'UpdateRowIdentifiers', subjectIDs);
    ndi.nansen.metatable.update(dataset,'Dataset');
    ndi.nansen.fun.refreshAppTable();

    % Return session object (please do not remove):
    % if nargout; varargout = {subjectObject}; end
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
