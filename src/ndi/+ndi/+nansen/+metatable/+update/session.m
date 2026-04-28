function [sessionTable] = session(session)
%SESSION Compiles a session metadata table for NDI sessions or datasets.
%
%   This function retrieves information about one or more NDI
%   sessions within a session directory or dataset and compiles it
%   into a MATLAB table.
%
%   Inputs:
%      session (ndi.session.dir or ndi.dataset.dir): The NDI session
%         or dataset object.
%
%   Outputs:
%      sessionTable (table): A table containing session metadata.
%
%   Examples:
%      % Get session metadata for a dataset:
%      sessionTable = ndi.nansen.metatable.update.session(dataset)
%
%   See also: NDI.SESSION.DIR, NDI.DATASET.DIR, NANSEN.PROJECTMANAGER

% Input argument validation
arguments
    session {mustBeA(session,{'ndi.session.dir','ndi.dataset.dir'})}
end

% Initialize output
sessionTable = table();

% Get sessions (if dataset)
if isa(session,'ndi.dataset.dir')
    dataset = session;
    [~,sessionIDs,sessionDocIDs] = dataset.session_list;
    sessions = cell(size(sessionIDs));
    for i = 1:numel(sessionIDs)
        sessions{i} = dataset.open_session(sessionIDs{i});
    end
    datasetID = dataset.id;
else
    sessions = {session};
    query = ndi.query('base.session_id','exact_string',session.id);
    doc = session.database_search(query);
    sessionDocIDs = {doc{1}.document_properties.base.id};

    % Asssume only one dataset and get id
    project = nansen.getCurrentProject();
    datasetTable = project.MetaTableCatalog.getMetaTable('Dataset');
    if ~isscalar(datasetTable.members)
        error('NDI:Nansen:Metatable:Update:Session:MultipleDatasets', ...
            ['[NDI:Nansen:Metatable:Update:Session:MultipleDatasets] ' ...
             'More than one dataset is not supported.'])
    else
        datasetID = datasetTable.members{1};
    end
end

% Return if empty
if isempty(sessions)
    return
end

% Get basic session metadata
for i = 1:numel(sessions)
    sessionTable.SessionName{i} = sessions{i}.reference;
    sessionTable.SessionIdentifier{i} = sessions{i}.identifier;
    sessionTable.SessionDocumentIdentifier{i} = sessionDocIDs{i};
    sessionTable.SessionPath{i} = sessions{i}.path;
    sessionTable.DatasetIdentifier{i} = datasetID;
    sessionTable.Document(i) = true;
end

end
