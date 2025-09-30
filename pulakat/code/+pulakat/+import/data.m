function [dataTable] = data(session,dataPath)
%DATA Summary of this function goes here
%   Detailed explanation goes here

% Input argument validation
arguments
    session {mustBeA(session,{'ndi.session.dir'})}
    dataPath {mustBeText} = '';
end

% Retrieve data files
dataFiles = pulakat.import.file.select(dataPath);

% Get current data table from files
dataTable_files = pulakat.import.data.tableFromFiles(session,dataFiles);

% Get existing data table from session
dataTable_session = table();
% dataTable_session = pulakat.import.data.tableFromSession(session);

% Identify new and unique files
fileIdentifiers = {'ElectronicFileName'};
if isempty(dataTable_session)
    dataTable_new = dataTable_files;
else
    [~,indNew] = setdiff(dataTable_files(:,fileIdentifiers), ...
        dataTable_session(:,fileIdentifiers));
    dataTable_new = dataTable_files(indNew,:);
end
[~,~,indUnique] = unique(dataTable_new(:,fileIdentifiers),'stable');
dataTable_new = dataTable_new(indUnique,:);

% Check whether there are new files to add
if isempty(dataTable_new)
    warning('No new files found in: %s.',strjoin(dataFiles,';'))
    dataTable = dataTable_files;
    return
end

% Create data documents (and add to session)
for i = 1:height(dataTable_new)
indDIA = ndi.fun.table.identifyMatchingRows(dataTable_newOnly,'fileType','DIA');
pulakat.import.DIA(session,dataTable_newOnly.fileName(indDIA));

% Return updated data table
dataTable = pulakat.import.data.tableFromSession(session);

% Upload files to cloud
%ndi.cloud.sync.uploadNew(dataset)

end

