function [sessionTable] = session(session, fullMetaTable)
%SESSION Compiles a metadata table for NDI sessions.
%
%   This function retrieves information about one or more NDI sessions
%   within a session directory or dataset and compiles it into a MATLAB
%   table. It can optionally include a summary of subject metadata.
%
%   Inputs:
%       session (ndi.session.dir or ndi.dataset.dir): The NDI session or
%           dataset object.
%       fullMetaTable (logical): Optional. If true, adds subject summary
%           metadata to the table. Defaults to true.
%
%   Outputs:
%       sessionTable (table): A table containing session metadata.

% Input argument validation
arguments
    session {mustBeA(session,{'ndi.session.dir','ndi.dataset.dir'})}
    fullMetaTable (1,1) logical = true
end

% Get sessions (if dataset)
if isa(session,'ndi.dataset.dir')
    dataset = session;
    [~,sessionIDs,sessionDocIDs] = dataset.session_list;
    sessions = cell(size(sessionIDs));
    for i = 1:numel(sessionIDs)
        sessions{i} = dataset.open_session(sessionIDs{i});
    end
    query = ndi.query('base.session_id','exact_string',dataset.id) & ...
        (ndi.query('','isa','dataset_remote') | ndi.query('','isa','dataset'));
    doc = dataset.database_search(query);
    datasetDocID = doc{1}.document_properties.base.id;
else
    sessions = {session};
    query = ndi.query('base.session_id','exact_string',session.id);
    doc = session.database_search(query);
    sessionDocIDs = {doc{1}.document_properties.base.id};
end

% Get basic session metadata
sessionTable = table();
for i = 1:numel(sessions)
    sessionTable.SessionName{i} = sessions{i}.reference;
    sessionTable.SessionIdentifier{i} = sessions{i}.identifier;
    sessionTable.SessionDocumentIdentifier{i} = sessionDocIDs{i};
    sessionTable.SessionPath{i} = sessions{i}.path;
    sessionTable.DateAdded(i) = NaT('TimeZone', 'UTC');

    if exist('dataset','var')
        sessionTable.DatasetIdentifier{i} = dataset.id;
        sessionTable.DatasetDocumentIdentifier{i} = datasetDocID;
        statusTable = ndi.nansen.sync.status(dataset);
        sessionTable = join(sessionTable,statusTable,'LeftKeys',...
            'SessionDocumentIdentifier','RightKeys','DocumentIdentifier');
        % Add DateAdded from NDI
        doc = dataset.database_search(ndi.query('base.id','exact_string',sessionDocIDs{i}));
        if ~isempty(doc)
            datestamp = doc{1}.document_properties.base.datestamp;
            sessionTable.DateAdded(i) = datetime(datestamp,'InputFormat', ...
                'yyyy-MM-dd''T''HH:mm:ss.SSS''Z''','TimeZone','UTC');
        end
    end
end

% If wanting the full meta table, add summary of subject table
if fullMetaTable & ~isempty(sessionTable)
    if exist('dataset','var')
        subjectTable = ndi.nansen.metatable.subject(dataset);
    else
        subjectTable = ndi.nansen.metatable.subject(session);
    end
    if ~isempty(subjectTable)
        sessionTable =  ndi.fun.table.join({sessionTable, ...
            removevars(subjectTable,{'SubjectDocumentIdentifier',...
            'SubjectLocalIdentifier','ElectronicFileName','DateAdded'})}, ...
            'uniqueVariables','SessionDocumentIdentifier');
    end
end

end

