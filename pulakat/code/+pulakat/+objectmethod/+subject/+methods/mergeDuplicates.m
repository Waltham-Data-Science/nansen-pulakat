function varargout = mergeDuplicates(subjectObject, varargin)
%MERGEDUPLICATES Merge duplicate subject records in the Subject metatable.
%
%   Object method backing the Subject table's 'Merge Duplicates' action.
%   Looks for subject rows that share identifying metadata and collapses
%   them into a single row, then refreshes the Session metatable and GUI.
%
%   Inputs:
%       subjectObject (struct array): The selected Nansen subject records.
%       varargin: Optional name-value pairs (currently unused).

    params = getDefaultParameters();
    ATTRIBUTES = {'batch', 'queueable'};

    import nansen.session.SessionMethod
    fcnAttributes = SessionMethod.setAttributes(params, ATTRIBUTES{:});

    if ~nargin && nargout > 0
        varargout = {fcnAttributes};   return
    end

    params = utility.parsenvpairs(params, [], varargin); %#ok<NASGU>

    % Convert subject object to table
    subjectTable = struct2table(subjectObject,'AsArray',true);

    % Merge duplicates
    ndi.nansen.fun.mergeMetaTableCells(subjectTable,'Subject');

    % Get dataset object
    dataset = ndi.nansen.fun.datasetID2Object(subjectObject(1).DatasetIdentifier);

    % Update session table
    ndi.nansen.metatable.update(dataset,'Session');

    % Update nansen viewer
    ndi.nansen.fun.refreshAppTable();
    
    % Return session object (please do not remove):
    % if nargout; varargout = {subjectObject}; end
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
