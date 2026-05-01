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

    % Get updated subject object
    project = nansen.getCurrentProject;
    metaTable = project.MetaTableCatalog.getMetaTable('Subject');

    % Get updated subject table
    subjectTable = metaTable.getEntry({subjectObject.SubjectIdentifier});

    % Call validation function
    [isValid,reportTable] = ndi.nansen.import.subject.validate(subjectTable);

    % Check for already documented rows. Per-row strcmp; the previous
    % isequal(..., {'N/A'}) compared the entire cell column against a
    % length-1 cell, which is only true for a single-row table -- for
    % multi-row selections it returned scalar false, every row passed
    % through, and already-documented rows reached documents() where
    % the upstream framework's isnan-on-ndi.document path crashes.
    isDocument = ~strcmp(subjectTable.SubjectDocumentIdentifier, 'N/A');

    % Warn up front if any rows have validation issues or are already
    % documented, so the user can fix things before any documents are
    % created. When everything is clean, skip the prompt.
    nToCreate = sum(isValid & ~isDocument);
    nInvalid  = sum(~isValid);
    nExisting = sum(isDocument);
    if nInvalid > 0 || nExisting > 0
        if nToCreate == 0
            msg = sprintf([ ...
                'Nothing to do.\n\n' ...
                '%d selected row(s) already have documents.\n' ...
                '%d selected row(s) have validation issues.\n\n' ...
                'See the validation report for details.'], ...
                nExisting, nInvalid);
            questdlg(msg, 'Subject documents', 'OK', 'OK');
            ndi.nansen.fun.showValidationReport(isValid, reportTable);
            return
        end
        msg = sprintf([ ...
            'Documents will be created for %d subject(s).\n\n' ...
            '%d row(s) will be skipped: already documented.\n' ...
            '%d row(s) will be skipped: missing required ' ...
            'information (detailed report after run).\n\n' ...
            'Continue?'], nToCreate, nExisting, nInvalid);
        choice = questdlg(msg, 'Subject documents', ...
            'Continue', 'Cancel', 'Cancel');
        if ~strcmp(choice, 'Continue')
            ndi.nansen.fun.showValidationReport(isValid, reportTable);
            return
        end
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

    % Show detailed report table
    ndi.nansen.fun.showValidationReport(isValid, reportTable);
    
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
