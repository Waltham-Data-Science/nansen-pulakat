function varargout = edit(subjectObject, varargin)
%EDIT Summary of this function goes here
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

    % Convert subject object to table
    subjectTable = struct2table(subjectObject,'AsArray',true);
    
    % Check the subject status
    indDocument = ~strcmp(subjectTable.SubjectDocumentIdentifier,'N/A');
    if all(indDocument)
        error('Subjects that are already documents cannot be edited.')
    elseif any(indDocument)
        warning('Only subjects that are not already documents can be edited.')
        subjectTable(indDocument,:) = []; % remove document subjects from table
    end

    % Get project info
    labName = char(nansen.getCurrentProject().Name);
    projectFile = fullfile('+ndi','+setup','+conv',['+',labName],'project_info.json');
    projectInfo = jsondecode(fileread(projectFile));

    % Query user for subject edits
    subjectIdentifiers = {projectInfo.subjectFileColumns.name}';
    idShortNames = {projectInfo.subjectFileColumns.value}';
    subjectTable_edit = renamevars(subjectTable,subjectIdentifiers,idShortNames);
    subjectTable_edit = ndi.nansen.fun.editImportTableGUI(subjectTable_edit(:,idShortNames),'Subject',...
        'Prompt',['Carefully confirm the subject info and ensure that each ' ...
        'subject has a fully unique set of identifiers.'],'AddRow',false,'Delete',false);
    subjectTable(:,subjectIdentifiers) = subjectTable_edit(:,idShortNames);

    % Remove associated file(s) from metatable
    ndi.nansen.metatable.edit(subjectTable,'Subject');
    
    % Get dataset object
    dataset = ndi.nansen.fun.datasetID2Object(subjectObject(1).DatasetIdentifier);

    % Update metatables
    ndi.nansen.metatable.update(dataset,'Subject');
    ndi.nansen.metatable.update(dataset,'File');
    ndi.nansen.metatable.update(dataset,'Session');
    nansen.App.updateTable

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
