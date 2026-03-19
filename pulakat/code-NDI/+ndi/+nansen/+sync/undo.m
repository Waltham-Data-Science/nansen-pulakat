function [success] = undo(dataset, options)
%UNDO Reverts pending local NDI document creations.
%
%   SUCCESS = UNDO(DATASET) identifies NDI documents that have been created
%   locally but not yet synchronized to the cloud, and removes them from the
%   local NDI database. This also resets the corresponding Nansen metatable
%   entries (DocumentIdentifiers).
%
%   Inputs:
%       dataset (ndi.dataset.dir): The NDI dataset object.
%
%   Outputs:
%       success (logical): True if the undo operation was successful.

% Input argument validation
arguments
    dataset {mustBeA(dataset,{'ndi.dataset.dir'})}
    options.LabName {mustBeText} = nansen.getCurrentProject().Name;
end

success = false;
labName = char(options.LabName);

% 1. Get synchronization status
statusTable = ndi.nansen.sync.status(dataset);

% 2. Identify pending (unsynced) documents
pendingDocIds = statusTable.DocumentIdentifier(~statusTable.Cloud);

if isempty(pendingDocIds)
    disp('No pending documents to undo.');
    success = true;
    return;
end

% 3. Confirm with user
choice = questdlg(sprintf('Are you sure you want to undo %d pending documents? This will remove them from the local NDI database and unlock them for editing in Nansen.', numel(pendingDocIds)), ...
	'Confirm Undo', 'Yes','No','No');

if ~strcmp(choice, 'Yes')
    return;
end

% 4. Remove documents from NDI sessions
[~, sessionIDs] = dataset.session_list();
for i = 1:numel(sessionIDs)
    session = dataset.open_session(sessionIDs{i});
    for j = 1:numel(pendingDocIds)
        % Try to remove the document if it exists in this session
        % (NDI session.database_rm uses doc ID or doc object)
        try
            session.database_rm(pendingDocIds{j});
        catch
            % Skip if not found in this session
        end
    end
end

% 5. Reset Nansen metatables
project = nansen.getCurrentProject();
tableNames = {'Subject', 'File'};

for i = 1:numel(tableNames)
    metaTable = project.MetaTableCatalog.getMetaTable(tableNames{i});
    idVarName = [tableNames{i}, 'DocumentIdentifier'];

    if ismember(idVarName, metaTable.entries.Properties.VariableNames)
        indReset = ismember(metaTable.entries.(idVarName), pendingDocIds);
        if any(indReset)
            rowInds = find(indReset);
            for j = 1:numel(rowInds)
                metaTable.editEntries(rowInds(j), idVarName, 'N/A');
                if strcmp(tableNames{i}, 'File')
                    % Also reset Cloud status if it exists
                    if ismember('Cloud', metaTable.entries.Properties.VariableNames)
                        metaTable.editEntries(rowInds(j), 'Cloud', false);
                    end
                end
            end
        end
    end
    metaTable.save();
end

% 6. Update metatables from dataset to ensure consistency
ndi.nansen.metatable.updateAll(dataset, 'LabName', labName);

disp('Undo operation completed successfully.');
success = true;

end
