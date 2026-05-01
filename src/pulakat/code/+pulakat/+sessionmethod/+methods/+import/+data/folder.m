function varargout = folder(sessionObject, varargin)
%AUTO Imports data files for a session into NDI and updates the metatable.
%
%   This session method identifies data files associated with the session,
%   imports them into the NDI database, checks their cloud synchronization
%   status, and updates the session's file metatable.
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

    % Get dataset and session objects. Pass the SessionIdentifier as
    % the third arg so a dataset and session that share a directory
    % don't collapse onto the dataset's default session.
    dataset = ndi.nansen.fun.datasetID2Object(sessionObject.DatasetIdentifier);
    session = ndi.session.dir(sessionObject.SessionName, ...
        sessionObject.SessionPath, sessionObject.SessionIdentifier);
    assert(strcmp(session.id, sessionObject.SessionIdentifier), ...
        'Pulakat:Import:Data:SessionMismatch', ...
        ['[Pulakat:Import:Data:SessionMismatch] Resolved session ' ...
         'id %s does not match GUI-selected %s.'], ...
        session.id, sessionObject.SessionIdentifier);

    % Add files to session
    dataFiles = ndi.nansen.import.file.select('','GetType','dir');
    dataTable = ndi.nansen.import.file.auto(session,dataFiles);

    if isempty(dataTable); return; end

    % Update metatables
    ndi.nansen.metatable.update(dataset,'Subject'); % file needs to inheret info from new subjects
    ndi.nansen.metatable.update(dataset,'File');
    ndi.nansen.metatable.update(dataset,'Subject','UpdateVariableNames',{'NumFiles','DataTypeName'}); % subject needs # files & datatypes
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
