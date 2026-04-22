function varargout = file(sessionObject, varargin)
%FILE Manually add data files for a session and update the metatable.
%
%   Session method backing the GUI's 'Import > Data > Files' action. Lets
%   the user pick files from a dialog, imports them into NDI, and
%   refreshes the Subject, File, and Session metatables so the new files
%   appear in the GUI and the per-subject aggregates are up to date.
%
%   Inputs:
%       sessionObject (nansen.session.Session): The Nansen session object.
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

    % Get dataset and session objects
    dataset = ndi.nansen.fun.datasetID2Object(sessionObject.DatasetIdentifier);
    session = ndi.session.dir(sessionObject.SessionPath);

    % Add files to session
    dataTable = ndi.nansen.import.file.auto(session);

    if isempty(dataTable); return; end

    % Update metatables. Order matters: refresh Subject first (so new
    % subjects show up for File to inherit from), then File, then refresh
    % the per-subject aggregates (NumFiles, DataTypeName) without rebuilding
    % the Subject table again, and finally Session. Skipping UpdateTable on
    % the second Subject pass avoids an unnecessary full rebuild.
    ndi.nansen.metatable.update(dataset,'Subject');
    ndi.nansen.metatable.update(dataset,'File');
    ndi.nansen.metatable.update(dataset,'Subject', ...
        'UpdateTable',false, ...
        'UpdateVariableNames',{'NumFiles','DataTypeName'});
    ndi.nansen.metatable.update(dataset,'Session');

    % Return session object (please do not remove):
    % if nargout; varargout = {sessionObject}; end
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
