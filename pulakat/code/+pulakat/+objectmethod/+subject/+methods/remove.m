function varargout = remove(subjectObject, varargin)
%REMOVE Deletes local subjects and removes them from the metatable.
%
%   This object method checks if subjects are synchronized to the cloud.
%   If they are not, it deletes them from their respective NDI sessions
%   and removes their entries from the subject metatable.
%
%   Inputs:
%       subjectObject (struct): A structure or array of structures
%           representing subjects.
%       varargin: Optional name-value pairs for parameters.
%
%   Outputs:
%       varargout: If called without inputs, returns the method's attributes.

    % Get struct of parameters from local function
    params = getDefaultParameters();
    
    % Create a cell array with attribute keywords
    ATTRIBUTES = {'batch', 'queueable'};
    
    % Create a struct with "attributes" using a predefined pattern
    import nansen.session.SessionMethod
    fcnAttributes = SessionMethod.setAttributes(params, ATTRIBUTES{:});
    
    if ~nargin && nargout > 0
        varargout = {fcnAttributes};   return
    end
    
    % Parse name-value pairs from function input and update parameters
    params = utility.parsenvpairs(params, [], varargin);
    
    % --- Implementation of the method ---

    % Convert subject object to table
    subjectTable = struct2table(subjectObject,'AsArray',true);
    
    % Check the subject status
    if all(subjectTable.Cloud)
        error('Subjects that are already synced to the cloud cannot be deleted.')
    elseif any(subjectTable.Cloud)
        warning('Only subjects that not already synced to the cloud were deleted.')
        subjectTable(subjectTable.Cloud,:) = []; % remove cloud subjects from table
    end

    % Get unique sessions
    sessionPaths = cellstr(subjectTable.SessionPath);
    [sessionPaths_unique,~,ind] = unique(sessionPaths,'stable');
    for i = 1:numel(sessionPaths_unique)

        % Get session object
        session = ndi.session.dir(sessionPaths_unique{i});

        % Delete subject(s) from session
        subjectIDs = cellstr(subjectTable.SubjectDocumentIdentifier);
        session.database_rm(subjectIDs(ind == i));
    end

    % Remove subject(s) from metatable
    ndi.nansen.metatable.remove(subjectTable,'Subject');

    % Return session object (please do not remove):
    % if nargout; varargout = {subjectsObject}; end
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
