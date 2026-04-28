function varargout = remove(filesObject, varargin)
%REMOVE Deletes local files and removes them from the metatable.
%
%   This object method checks if files are synchronized to the cloud.
%   If they are not, it deletes their entries from the file metatable.
%   Files that are already documented in NDI cannot be deleted via
%   this method.
%
%   Inputs:
%       filesObject (struct): A structure or array of structures
%           representing files.
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

    % Convert files object to table
    fileTable = struct2table(filesObject);

    % Check the file status
    indDocument = ~strcmp(fileTable.FileDocumentIdentifier,'N/A');
    if all(indDocument)
        error('Pulakat:ObjectMethod:File:Remove:AllDocumented', ...
            ['[Pulakat:ObjectMethod:File:Remove:AllDocumented] Files that ' ...
             'are already documents cannot be deleted.'])
    elseif any(indDocument)
        warning('Pulakat:ObjectMethod:File:Remove:SomeDocumented', ...
            ['[Pulakat:ObjectMethod:File:Remove:SomeDocumented] Only ' ...
             'files that are not already documents were deleted.'])
        fileTable(indDocument,:) = []; % remove documented files from table
    end

    % Remove file(s) from metatable
    ndi.nansen.metatable.remove(fileTable,'File');

    % Return session object (please do not remove):
    % if nargout; varargout = {filesObject}; end
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
