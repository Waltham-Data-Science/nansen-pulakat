function varargout = remove(sessionObject, varargin)
%REMOVE Deletes a local session and removes it from the metatable.
%
%   This session method checks if a session is synchronized to the cloud.
%   If it is not, it unlinks the session from the NDI dataset and
%   optionally deletes the session directory from the local disk.
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

    % Check that session status
    if sessionObject.Cloud
        error('Pulakat:SessionMethod:Remove:AlreadySynced', ...
            ['[Pulakat:SessionMethod:Remove:AlreadySynced] Sessions that ' ...
             'are already synced to the cloud cannot be deleted.'])
    end

    % Confirm destructive action with the user before touching disk. The
    % downstream dataset.unlink_session call is passed 'areYouSure',true to
    % suppress its own prompt, so nothing else gates this on a human.
    prompt = sprintf(['Delete session "%s" and its local data from disk?\n' ...
        '\nSession path: %s\n\nThis cannot be undone.'], ...
        sessionObject.SessionName, sessionObject.SessionPath);
    choice = questdlg(prompt, 'Confirm session removal', ...
        'Delete', 'Cancel', 'Cancel');
    if ~strcmp(choice, 'Delete')
        fprintf('[Pulakat] Session removal cancelled for "%s".\n', ...
            sessionObject.SessionName);
        return
    end

    % Get dataset object. Fall back to the project's Dataset metatable
    % if the selected session row's DatasetIdentifier is empty.
    dataset = ndi.nansen.fun.datasetID2Object( ...
        ndi.nansen.fun.resolveDatasetID(sessionObject.DatasetIdentifier));

    % Delete session from local disk
    [~,sessionIDs] = dataset.session_list;
    if any(strcmp(sessionIDs,sessionObject.SessionIdentifier))
        dataset.unlink_session(sessionObject.SessionIdentifier,...
            'areYouSure',true,'AlsoDeleteSessionAfterUnlinking',true);
    end

    % Remove session from metatable
    [~,sessionIDs] = dataset.session_list;
    if ~any(strcmp(sessionIDs,sessionObject.SessionIdentifier))
        ndi.nansen.metatable.remove(struct2table(sessionObject),'Session');
    else
        error('Pulakat:SessionMethod:Remove:DeleteFailed', ...
            ['[Pulakat:SessionMethod:Remove:DeleteFailed] Session failed ' ...
             'to be deleted from the database.'])
    end

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
