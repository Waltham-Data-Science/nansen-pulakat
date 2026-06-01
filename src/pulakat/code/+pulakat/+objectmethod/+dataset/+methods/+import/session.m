function varargout = session(datasetObject, varargin)
%SESSION Prompt for a session directory and add it to the dataset.
%
%   Object method backing the Dataset table's 'Import > Session' action.
%   Opens a folder picker and a text-prompt for the session name,
%   registers the directory as a new NDI session, and refreshes the
%   Session metatable.
%
%   Inputs:
%       datasetObject (struct): The selected Nansen dataset record.
%       varargin: Optional name-value pairs (currently unused).

    params = getDefaultParameters();
    ATTRIBUTES = {'serial', 'queueable'};

    import nansen.session.SessionMethod
    fcnAttributes = SessionMethod.setAttributes(params, ATTRIBUTES{:});

    if ~nargin && nargout > 0
        varargout = {fcnAttributes};   return
    end

    params = utility.parsenvpairs(params, [], varargin); %#ok<NASGU>

    % Get dataset and project
    dataset = ndi.dataset.dir(datasetObject.DatasetPath);

    % Create new session entry in metatable
    sessionPath = uigetdir(userpath, ...
        'Select directory where session data is located.');
    if isequal(sessionPath, 0); return; end
    sessionName = inputdlg('What is the name of the new session?', ...
        'Session title',[1 50],{'projectName_YYYY'});
    if isempty(sessionName); return; end
    ndi.nansen.import.session(dataset,sessionPath,sessionName);
    ndi.nansen.metatable.update(dataset,'Session');

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
