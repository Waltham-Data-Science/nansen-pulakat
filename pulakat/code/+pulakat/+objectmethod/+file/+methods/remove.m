function varargout = remove(filesObject, varargin)
%REMOVE Deletes local files and removes them from the metatable.
%
%   This object method checks if files are synchronized to the cloud.
%   If they are not, it deletes them from their respective NDI sessions
%   and removes their entries from the file metatable.
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
    if all(fileTable.Cloud)
        error('Files that are already synced to the cloud cannot be deleted.')
    elseif any(fileTable.Cloud)
        warning('Only files that not already synced to the cloud were deleted.')
        fileTable(fileTable.Cloud,:) = []; % remove cloud files from table
    end

    % Get unique sessions
    [sessionPaths,~,ind] = unique(fileTable.SessionPath,'stable');
    for i = 1:numel(sessionPaths)

        % Get session object
        session = ndi.session.dir(sessionPaths{i});

        % Delete file document(s) from session
        % Also delete the file on disk if it exists
        fileIDs = fileTable.FileDocumentIdentifier(ind == i);
        for j = 1:numel(fileIDs)
            doc = session.database_search(ndi.query('','isa','generic_file') & ...
                ndi.query('base.id','exact_string',fileIDs{j}));
            if ~isempty(doc)
                % Delete associated ontologyLabel as well
                labelDoc = session.database_search(ndi.query('','isa','ontologyLabel') & ...
                    ndi.query('depends_on.value','exact_string',fileIDs{j}));
                if ~isempty(labelDoc)
                    session.database_rm(labelDoc{1}.id);
                end

                % Delete generic_file doc and file on disk
                session.database_rm(doc{1}.id);
            end
        end
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
