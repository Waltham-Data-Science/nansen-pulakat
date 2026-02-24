function varargout = auto(sessionObject, varargin)
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

    % Get session object
    session = ndi.session.dir(sessionObject.SessionPath);

    % Add files to session
    ndi.nansen.import.file.auto(session);
    dataTable = ndi.nansen.metatable.file(session);

    % Add cloud status to subject table
    dataset = ndi.nansen.fun.datasetID2Object(sessionObject.DatasetIdentifier);
    statusTable = ndi.nansen.sync.status(dataset);
    dataTable = join(dataTable,statusTable,'LeftKeys',...
        'FileDocumentIdentifier','RightKeys','DocumentIdentifier');

    % Add subjects to metatable
    ndi.nansen.metatable.add(dataTable,'File');

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
