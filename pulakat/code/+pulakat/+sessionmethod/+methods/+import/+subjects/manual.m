function varargout = manual(sessionObject, varargin)
%MANUAL Manually adds subjects for a session into NDI and updates the metatable.
%
%   This session method allows the user to manually enter subject details,
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

    % Get session object
    session = ndi.session.dir(sessionObject.SessionPath);

    % Add subjects to session
    subjectTable = ndi.nansen.import.subject.manual(session);

    if isempty(subjectTable); return; end

    % Add subjects to metatable
    ndi.nansen.metatable.add(subjectTable,'Subject');

    % Update session metatable with subject summary metadata
    dataset = ndi.nansen.fun.datasetID2Object(sessionObject.DatasetIdentifier);
    sessionTable = ndi.nansen.metatable.session(dataset);
    ndi.nansen.metatable.add(sessionTable,'Session');

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
