function [sessionTable] = session(session)
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
    sessionTable.SessionName{i} = sessions{i}.reference;
    sessionTable.SessionIdentifier{i} = sessions{i}.identifier;
    sessionTable.SessionDocumentIdentifier{i} = sessionDocIDs{i};
    sessionTable.SessionPath{i} = sessions{i}.path;
    sessionTable.DatasetIdentifier{i} = datasetID;
end

% % Get basic session metadata
% for i = 1:numel(sessions)
%     sessionTable.SessionName{i} = sessions{i}.reference;
%     sessionTable.SessionIdentifier{i} = sessions{i}.identifier;
%     sessionTable.SessionDocumentIdentifier{i} = sessionDocIDs{i};
%     sessionTable.SessionPath{i} = sessions{i}.path;
%     sessionTable.DateAdded(i) = NaT('TimeZone', 'UTC');
% 
%     % Count subjects and files from metatables
%     try
%         project = nansen.getCurrentProject();
%         subjectMetaTable = project.MetaTableCatalog.getMetaTable('Subject');
%         if ~isempty(subjectMetaTable) && ~isempty(subjectMetaTable.entries)
%             ind = strcmp(subjectMetaTable.entries.SessionName, sessions{i}.reference);
%             sessionTable.NumSubjects(i) = sum(ind);
%         else
%             sessionTable.NumSubjects(i) = 0;
%         end
% 
%         fileMetaTable = project.MetaTableCatalog.getMetaTable('File');
%         if ~isempty(fileMetaTable) && ~isempty(fileMetaTable.entries)
%             ind = strcmp(fileMetaTable.entries.SessionName, sessions{i}.reference);
%             sessionTable.NumFiles(i) = sum(ind);
%         else
%             sessionTable.NumFiles(i) = 0;
%         end
%     catch
%         % Fallback to NDI if project/metatables are not available
%         subjectDocs = sessions{i}.database_search(ndi.query('','isa','subject'));
%         sessionTable.NumSubjects(i) = numel(subjectDocs);
% 
%         fileDocs = sessions{i}.database_search(ndi.query('','isa','generic_file'));
%         sessionTable.NumFiles(i) = numel(fileDocs);
%     end
% 
%     if exist('dataset','var')
%         sessionTable.DatasetIdentifier{i} = dataset.id;
%         sessionTable.DatasetDocumentIdentifier{i} = datasetDocID;
% 
%         % Add DateAdded from NDI
%         doc = dataset.database_search(ndi.query('base.id','exact_string',sessionDocIDs{i}));
%         if ~isempty(doc)
%             datestamp = doc{1}.document_properties.base.datestamp;
%             sessionTable.DateAdded(i) = datetime(datestamp,'InputFormat', ...
%                 'yyyy-MM-dd''T''HH:mm:ss.SSS''Z''','TimeZone','UTC');
%         end
%     end
% end
% 
% % Add cloud sync status
% if exist('dataset','var') && ~isempty(sessionTable)
%     statusTable = ndi.nansen.sync.status(dataset);
%     [Lia, Locb] = ismember(sessionTable.SessionDocumentIdentifier, statusTable.DocumentIdentifier);
%     sessionTable.Cloud = false(height(sessionTable), 1);
%     sessionTable.Cloud(Lia) = statusTable.Cloud(Locb(Lia));
% end
% 
% % If wanting the full meta table, add summary of subject table
% % if fullMetaTable & ~isempty(sessionTable)
% %     if exist('dataset','var')
% %         subjectTable = ndi.nansen.metatable.subject(dataset);
% %     else
% %         subjectTable = ndi.nansen.metatable.subject(session);
% %     end
% %     if ~isempty(subjectTable)
% %         sessionTable = ndi.fun.table.join({sessionTable, ...
% %             subjectTable(:,{'BiologicalSexName','GeneticStrainTypeName',...
% %             'SpeciesName','StrainName','Treatment','SessionIdentifier',...
% %             'DataTypes'})}, ...
% %             'uniqueVariables','SessionIdentifier');
% % 
% %         % Ensure DataTypes is not NaN and is a cell array of strings
% %         if ismember('DataTypes', sessionTable.Properties.VariableNames)
% %             if isnumeric(sessionTable.DataTypes)
% %                 sessionTable.DataTypes = repmat({''}, height(sessionTable), 1);
% %             elseif iscell(sessionTable.DataTypes)
% %                 isNan = cellfun(@(x) any(isnumeric(x) && isnan(x)), sessionTable.DataTypes);
% %                 sessionTable.DataTypes(isNan) = {''};
% %             end
% %         end
% %     end
% % end

end

