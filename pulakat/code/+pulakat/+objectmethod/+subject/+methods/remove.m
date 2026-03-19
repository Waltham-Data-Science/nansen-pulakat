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
    indDocument = ~strcmp(subjectTable.SubjectDocumentIdentifier,'N/A');
    if all(indDocument)
        error('Subjects that are already documents cannot be deleted.')
    elseif any(indDocument)
        warning('Only subjects that are not already documents were deleted.')
        subjectTable(indDocument,:) = []; % remove document subjects from table
    end

    % Remove subject(s) from metatable
    ndi.nansen.metatable.remove(subjectTable,'Subject');

    % Remove associated file(s) from metatble
    project = nansen.getCurrentProject;
    fileTable = project.MetaTableCatalog.getMetaTable('File');
    indRemove = ismember(fileTable.entries.SubjectIdentifier,subjectTable.SubjectIdentifier);
    ndi.nansen.metatable.remove(fileTable.entries(indRemove,:),'File');

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
