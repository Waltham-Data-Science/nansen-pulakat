function varargout = sync(datasetObject, varargin)
%SYNC Summary of this function goes here
%   Detailed explanation goes here

% % % % % % % % % % % % % % % INSTRUCTIONS % % % % % % % % % % % % % % %
% - - - - - - - - - - You can remove this part - - - - - - - - - - -
% Instructions on how to use this template:
%   1) If the session method should have parameters, these should be
%      defined in the local function getDefaultParameters at the bottom of
%      this script.
%   2) Scroll down to the custom code block below and write code to do
%   operations on the datasetsObjects and it's data.
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

    % Get dataset object
    dataset = ndi.dataset.dir(datasetObject.DatasetPath);

    % Sync dataset to cloud
    success = ndi.cloud.sync.uploadNew(dataset);
    if ~success
        warning('Error encountered syncing dataset to cloud. Try logging in again.')
        ndi.cloud.uilogin(true);
        [success,errorMessage] = ndi.cloud.sync.twoWaySync(dataset);
        if ~success
            error('Could not sync dataset to cloud: %s',errorMessage);
        end
    end

    % Update metatable
    datasetTable = ndi.nansen.metatable.dataset(dataset);
    ndi.nansen.metatable.remove(datasetTable,'Dataset');
    ndi.nansen.metatable.add(datasetTable,'Dataset');
    
    % Return session object (please do not remove):
    % if nargout; varargout = {datasetsObject}; end
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
