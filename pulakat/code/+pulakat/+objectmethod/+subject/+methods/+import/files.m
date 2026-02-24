function varargout = files(subjectsObject, varargin)
%FILES Imports data files for the selected subjects.
%
%   This object method identifies the sessions associated with the
%   selected subjects and imports any new data files found in those
%   session directories into NDI.
%
%   Inputs:
%       subjectsObject (struct): A structure or array of structures
%           representing subjects.
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

    % Convert subjects object to table
    subjectTable = struct2table(subjectsObject);
    
    % Get unique sessions
    [sessionPaths, ~, ~] = unique(subjectTable.SessionPath, 'stable');
    
    for i = 1:numel(sessionPaths)
        % Get session object
        session = ndi.session.dir(sessionPaths{i});

        % Add files to session
        ndi.nansen.import.data(session);
        dataTable = ndi.nansen.metatable.file(session);

        % Add cloud status to data table
        dataset = ndi.nansen.fun.datasetID2Object(subjectTable.DatasetIdentifier{1});
        statusTable = ndi.nansen.sync.status(dataset);
        dataTable = join(dataTable, statusTable, 'LeftKeys', ...
            'FileDocumentIdentifier', 'RightKeys', 'DocumentIdentifier');

        % Add files to metatable
        ndi.nansen.metatable.add(dataTable, 'File');
    end

    % Return subjects object (please do not remove):
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
