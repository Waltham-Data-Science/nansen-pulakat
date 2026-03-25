function varargout = file(sessionObject, varargin)
%AUTO Imports subjects for a session into NDI and updates the metatable.
%
%   This session method identifies subjects associated with the session,
%   imports them into the NDI database, checks their cloud synchronization
%   status, and updates the session's subject and session metatables.
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

    % Add subjects to session
    subjectTable = ndi.nansen.import.subject.auto(session);

    if isempty(subjectTable); return; end

    % Update subject and session metatables
    ndi.nansen.metatable.update(dataset,'Subject');
    ndi.nansen.metatable.update(dataset,'Session');
    nansen.App.updateTable
    
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
