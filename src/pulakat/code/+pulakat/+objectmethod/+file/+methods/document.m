function varargout = document(fileObject, varargin)
%DOCUMENT Validate and create NDI documents for selected files.
%
%   Object method backing the File table's 'Document' action. Runs the
%   file validator, creates NDI file documents for every valid row that
%   isn't already documented, refreshes the metatables, and displays a
%   validation report.
%
%   Inputs:
%       fileObject (struct array): The selected Nansen file records.
%       varargin: Optional name-value pairs (currently unused).

    params = getDefaultParameters();
    ATTRIBUTES = {'batch', 'queueable'};

    import nansen.session.SessionMethod
    fcnAttributes = SessionMethod.setAttributes(params, ATTRIBUTES{:});

    if ~nargin && nargout > 0
        varargout = {fcnAttributes};   return
    end

    params = utility.parsenvpairs(params, [], varargin); %#ok<NASGU>

    % Get dataset object
    dataset = ndi.nansen.fun.datasetID2Object(fileObject(1).DatasetIdentifier);

    % Update file metatable
    % ndi.nansen.metatable.update(dataset,'File');

    % Get updated subject object
    project = nansen.getCurrentProject;
    metaTable = project.MetaTableCatalog.getMetaTable('File');

    % Get updated subject table
    fileTable = metaTable.getEntry({fileObject.FileIdentifier});

    % Call validation function
    [isValid,reportTable] = ndi.nansen.import.file.validate(fileTable);

    % Check for already documented rows
    isDocument = isequal(fileTable.FileDocumentIdentifier,{'N/A'});

    % Create documents. Pass the session reference name as well as
    % the path to ndi.session.dir because dataset and session can
    % share a directory; without the reference, ndi.session.dir
    % creates a fresh session with a new identifier instead of
    % opening the existing one.
    fileTable_valid = fileTable(isValid & ~isDocument,:);
    sessionPaths = unique(fileTable_valid.SessionPath);
    for i = 1:numel(sessionPaths)
        indSession = strcmp(fileTable_valid.SessionPath,sessionPaths{i});
        sessionName = fileTable_valid.SessionName{find(indSession,1)};
        session = ndi.session.dir(sessionName, sessionPaths{i});
        ndi.nansen.import.file.documents(session,fileTable_valid(indSession,:));
    end

    % Update metatables. File is restricted to the selected files'
    % rows so a click on N files doesn't recompute every other
    % file's HasUpdateFunction variables.
    fileIDs = {fileObject.FileIdentifier};
    ndi.nansen.metatable.update(dataset,'File', ...
        'UpdateRowIdentifiers', fileIDs);
    ndi.nansen.metatable.update(dataset,'Dataset');
    ndi.nansen.fun.refreshAppTable();

    % Show detailed report table
    ndi.nansen.fun.showValidationReport(isValid, reportTable);
    
    % Return session object (please do not remove):
    % if nargout; varargout = {fileObject}; end
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
