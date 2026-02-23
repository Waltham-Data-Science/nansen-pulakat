function varargout = files(sessionObject, varargin)
%FILES Summary of this function goes here
%   Detailed explanation goes here

% % % % % % % % % % % % % % % INSTRUCTIONS % % % % % % % % % % % % % % %
% - - - - - - - - - - You can remove this part - - - - - - - - - - -
% Instructions on how to use this template:
%   1) If the session method should have parameters, these should be
%      defined in the local function getDefaultParameters at the bottom of
%      this script.
%   2) Scroll down to the custom code block below and write code to do
%   operations on the sessionObjects and it's data.
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

    % Get dataset and session objects
    dataset = ndi.nansen.fun.datasetID2Object(sessionObject.DatasetIdentifier);
    session = ndi.session.dir(sessionObject.SessionPath);

    % Get generic file document ids in this session
    query = ndi.query('','isa','generic_file');
    documents = session.database_search(query);
    documentIDs = ndi.docs.docfun(@id,documents);

    % Choose folder for download
    if ispc
        userDir = getenv('USERPROFILE'); % Windows
    else
        userDir = getenv('HOME'); % Mac/Linux
    end
    downloadsDir = fullfile(userDir, 'Downloads');
    downloadFolder = uigetdir(downloadsDir,'Select directory for download.');
    dateString = char(datetime('now','Format','yyyyMMdd_HHmmss'));
    exportFolder = fullfile(downloadFolder,['export_',dateString]);
    mkdir(exportFolder);
    
    % Download files
    ndi.cloud.download.downloadGenericFiles(dataset,...
        documentIDs,exportFolder);

    % Download metadata table
    project = nansen.getCurrentProject;
    fileTable = project.MetaTableCatalog.getMetaTable('File');
    subjectTable = project.MetaTableCatalog.getMetaTable('Subject');
    fileTable = fileTable.entries;
    subjectTable = subjectTable.entries;
    indFiles = ndi.fun.table.identifyMatchingRows(fileTable, ...
        'SessionIdentifier',sessionObject.SessionIdentifier);
    indSubjects = ndi.fun.table.identifyMatchingRows(subjectTable, ...
        'SessionIdentifier',sessionObject.SessionIdentifier);
    exportTable = join(fileTable(indFiles,:),subjectTable(indSubjects,:),...
        'Keys',{'SubjectDocumentIdentifier'},...
        'KeepOneCopy',{'ElectronicFileName','SessionDocumentIdentifier',...
        'SessionIdentifier','SessionName','DatasetDocumentIdentifier',...
        'DatasetIdentifier','SessionPath','SubjectLocalIdentifier','Cloud'});
    writetable(exportTable,fullfile(exportFolder,'metadata.csv'));
    
    % Return session object (please do not remove):
    % if nargout; varargout = {sessionObject}; end
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
