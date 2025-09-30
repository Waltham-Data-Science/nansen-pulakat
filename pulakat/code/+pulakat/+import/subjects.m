function [subjectTable] = subjects(session,dataPath)
%IMPORTSUBJECTS Summary of this function goes here
%   Detailed explanation goes here

% Input argument validation
arguments
    session {mustBeA(session,{'ndi.session.dir'})}
    dataPath {mustBeText} = '';
end

% Retrieve subject files
subjectFiles = pulakat.import.selectFiles(dataPath, ...
    'FileName','animal_mapping', ...
    'FileExtensions',{'csv','xls','xlsx'});

% Get current subject table from files
subjectTable_files = pulakat.import.subjects.tableFromFiles(subjectFiles);

% Get existing subject table from session
subjectTable_session = pulakat.import.subjects.tableFromSession(session);

% Identify new and unique subjects
subjectIdentifiers = {'SubjectEnumeratedIdentifier','SubjectCageIdentifier','SubjectTextIdentifier'};
if isempty(subjectTable_session)
    subjectTable_new = subjectTable_files;
else
    [~,indNew] = setdiff(subjectTable_files(:,subjectIdentifiers), ...
        subjectTable_session(:,subjectIdentifiers));
    subjectTable_new = subjectTable_files(indNew,:);
end
[~,indUnique] = unique(subjectTable_new(:,[subjectIdentifiers,'Treatment']),'stable');
subjectTable_new = subjectTable_new(indUnique,:);

% Check whether there are new subjects to add
if isempty(subjectTable_new)
    warning('No new subjects found in: %s.',strjoin(subjectFiles,';'))
    subjectTable = subjectTable_files;
    return
end

% Add session id to subject table
subjectTable_new{:,'SessionID'} = session.id;

% Create subjectMaker and tableDocMaker
subjectMaker = ndi.setup.NDIMaker.subjectMaker();
subjectCreator = pulakat.import.subjects.informationCreator();
tableDocMaker = ndi.setup.NDIMaker.tableDocMaker(session,'pulakat');

% Create subject documents (and add to session)
[~,subjectTable_new.SubjectLocalIdentifier,subjectTable_new.SubjectDocumentIdentifier] = ...
    subjectMaker.addSubjectsFromTable(session,subjectTable_new,subjectCreator);

% Create ontologyTableRow documents (and add to session)
tableRowVariables = ['SubjectLocalIdentifier','SubjectDocumentIdentifier',...
    subjectIdentifiers,'Treatment','ElectronicFilename'];
tableDocMaker.table2ontologyTableRowDocs(subjectTable_new(:,tableRowVariables), ...
        {'SubjectDocumentIdentifier'});

% Return updated subject table
subjectTable = pulakat.import.subjects.tableFromSession(session);

% Upload subjects to cloud
%ndi.cloud.sync.uploadNew(dataset)

end