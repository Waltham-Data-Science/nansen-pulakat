function [sessionTable] = session(session)
%SESSION Compiles a session metadata table for NDI sessions or datasets.
%
%   This function retrieves information about one or more NDI
%   sessions within a session directory or dataset and compiles it
%   into a MATLAB table.
%
%   Examples:
%       % Get session metadata for a dataset:
%       sessionTable = ndi.nansen.metatable.update.session(dataset)

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
        error('More than one dataset not supported.')
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
    sessionTable.SessionName{i,1} = sessions{i}.reference;
    sessionTable.SessionIdentifier{i,1} = sessions{i}.identifier;
    sessionTable.SessionDocumentIdentifier{i,1} = sessionDocIDs{i};
    sessionTable.SessionPath{i,1} = sessions{i}.path;
    sessionTable.DatasetIdentifier{i,1} = datasetID;
end

% Add summary and cloud status (if project and dataset are available)
try
    project = nansen.getCurrentProject();

    for i = 1:numel(sessions)
        sessionTable.DateAdded(i,1) = NaT('TimeZone', 'UTC');

        % Count subjects and files from metatables
        subjectMetaTable = project.MetaTableCatalog.getMetaTable('Subject');
        if ~isempty(subjectMetaTable) && ~isempty(subjectMetaTable.entries)
            ind = strcmp(subjectMetaTable.entries.SessionName, sessions{i}.reference);
            sessionTable.NumSubjects(i,1) = sum(ind);
        else
            sessionTable.NumSubjects(i,1) = 0;
        end

        fileMetaTable = project.MetaTableCatalog.getMetaTable('File');
        if ~isempty(fileMetaTable) && ~isempty(fileMetaTable.entries)
            ind = strcmp(fileMetaTable.entries.SessionName, sessions{i}.reference);
            sessionTable.NumFiles(i,1) = sum(ind);
        else
            sessionTable.NumFiles(i,1) = 0;
        end

        % Get DateAdded from NDI
        if exist('dataset','var')
            doc = dataset.database_search(ndi.query('base.id','exact_string',sessionDocIDs{i}));
            if ~isempty(doc)
                datestamp = doc{1}.document_properties.base.datestamp;
                sessionTable.DateAdded(i,1) = datetime(datestamp,'InputFormat', ...
                    'yyyy-MM-dd''T''HH:mm:ss.SSS''Z''','TimeZone','UTC');
            end
        end
    end

    % Add cloud sync status
    if exist('dataset','var') && ~isempty(sessionTable)
        statusTable = ndi.nansen.sync.status(dataset);
        [Lia, Locb] = ismember(sessionTable.SessionDocumentIdentifier, statusTable.DocumentIdentifier);
        sessionTable.Cloud = false(height(sessionTable), 1);
        sessionTable.Cloud(Lia) = statusTable.Cloud(Locb(Lia));
    end
catch
    % Fallback to NDI if project/metatables are not available
    for i = 1:numel(sessions)
        subjectDocs = sessions{i}.database_search(ndi.query('','isa','subject'));
        sessionTable.NumSubjects(i,1) = numel(subjectDocs);

        fileDocs = sessions{i}.database_search(ndi.query('','isa','generic_file'));
        sessionTable.NumFiles(i,1) = numel(fileDocs);
    end
end

end
