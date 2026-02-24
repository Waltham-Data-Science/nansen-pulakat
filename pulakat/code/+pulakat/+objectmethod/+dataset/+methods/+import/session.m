function varargout = session(datasetObject, varargin)
%SESSION Summary of this function goes here
%   Detailed explanation goes here

% % % % % % % % % % % % % % % INSTRUCTIONS % % % % % % % % % % % % % % %
% - - - - - - - - - - You can remove this part - - - - - - - - - - -
% Instructions on how to use this template:
%   1) If the session method should have parameters, these should be
%      defined in the local function getDefaultParameters at the bottom of
%      this script.
%   2) Scroll down to the custom code block below and write code to do
%   operations on the datasetObjects and it's data.
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
    ATTRIBUTES = {'serial', 'queueable'};
    
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
    
    % Get dataset and project
    dataset = ndi.dataset.dir(datasetObject.DatasetPath);

    % Create new session entry in metatable
    sessionTable = ndi.nansen.import.session(dataset);
    ndi.nansen.metatable.add(sessionTable,'Session');

    autoImport = questdlg('Would you like to automatically import subjects and files from the session directory?', ...
        'Import Subjects and Files','Yes', 'No', 'Yes');
    if strcmp(autoImport, 'Yes')
        % Create a temporary NDI session object to allow auto import logic to work (it needs paths etc)
        [dataParentDir, sessionFolderName] = fileparts(sessionTable.SessionPath{1});
        SessionRef = sessionTable.SessionName;
        SessionPath = {sessionFolderName};
        sessionMaker = ndi.setup.NDIMaker.sessionMaker(dataParentDir,...
                table(SessionRef,SessionPath));
        sessionObj = sessionMaker.sessionIndices{1};

        % Add subjects to session
        subjectTable = ndi.nansen.import.subject.auto(sessionObj, sessionObj.path);
        ndi.nansen.metatable.add(subjectTable,'Subject');

        % Add data to session
        dataTable = ndi.nansen.import.file.auto(sessionObj, sessionObj.path);
        ndi.nansen.metatable.add(dataTable,'File');
    end

    % Return session object (please do not remove):
    % if nargout; varargout = {datasetObject}; end
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
