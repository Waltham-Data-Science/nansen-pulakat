function varargout = document(subjectObject, varargin)
%CONFIRM Summary of this function goes here
%   Detailed explanation goes here

% % % % % % % % % % % % % % % INSTRUCTIONS % % % % % % % % % % % % % % %
% - - - - - - - - - - You can remove this part - - - - - - - - - - -
% Instructions on how to use this template:
%   1) If the session method should have parameters, these should be
%      defined in the local function getDefaultParameters at the bottom of
%      this script.
%   2) Scroll down to the custom code block below and write code to do
%   operations on the subjectObjects and it's data.
%   3) Add documentation (summary and explanation) for the session method
%      above. PS: Don't change the function definition (inputs/outputs)
%
%   For examples: Press e on the keyboard while browsing the session
%   methods. (e) should appear after the name in the menu, and when you
%   select a session method, the m-file will open.

% % % % % % % % % % % % CONFIGURATION CODE BLOCK % % % % % % % % % % % %
% Create a struct of default parameters (if applicable) and specify one or
% more attributes (see nansen.session.SessionMethod.setAttributes) for
% details.
    
    % Get struct of parameters from local function
    params = getDefaultParameters();
    
    % Create a cell array with attribute keywords
    ATTRIBUTES = {'batch', 'queueable'};
    
% % % % % % % % % % % % % DEFAULT CODE BLOCK % % % % % % % % % % % % % %
% - - - - - - - - - - Please do not edit this part - - - - - - - - - - -
    
    % Create a struct with "attributes" using a predefined pattern
    import nansen.session.SessionMethod
    fcnAttributes = SessionMethod.setAttributes(params, ATTRIBUTES{:});
    
    if ~nargin && nargout > 0
        varargout = {fcnAttributes};   return
    end
    
    % Parse name-value pairs from function input and update parameters
    params = utility.parsenvpairs(params, [], varargin);
    
% % % % % % % % % % % % % % CUSTOM CODE BLOCK % % % % % % % % % % % % % %
% Implementation of the method : Add your code here:

    % Get dataset object
    dataset = ndi.nansen.fun.datasetID2Object(subjectObject(1).DatasetIdentifier);

    % Update subject metatable
    ndi.nansen.metatable.update(dataset,'Subject');

    % Get updated subject object
    project = nansen.getCurrentProject;
    metaTable = project.MetaTableCatalog.getMetaTable('Subject');

    % Get updated subject table
    subjectTable = metaTable.getEntry({subjectObject.SubjectIdentifier});

    % Call validation function
    [isValid,reportTable] = ndi.nansen.import.subject.validate(subjectTable);

    % Check for already documented rows
    isDocument = isequal(subjectTable.SubjectDocumentIdentifier,{'N/A'});

    % Create documents
    subjectTable_valid = subjectTable(isValid & ~isDocument,:);
    sessionPaths = unique(subjectTable_valid.SessionPath);
    for i = 1:numel(sessionPaths)
        indSession = strcmp(subjectTable_valid.SessionPath,sessionPaths{i});
        session = ndi.session.dir(sessionPaths{i});
        ndi.nansen.import.subject.documents(session,subjectTable_valid(indSession,:));
    end

    % Update metatables
    ndi.nansen.metatable.update(dataset,'Subject');
    ndi.nansen.metatable.update(dataset,'Dataset');
    nansen.App.updateTable

    % Show detailed report table
    ndi.nansen.fun.showValidationReport(isValid, reportTable);
    
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
