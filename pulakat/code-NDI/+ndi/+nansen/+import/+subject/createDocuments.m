function [subjectTable] = createDocuments(session, subjectTable, labName)
%CREATEDOCUMENTS Creates NDI subject documents tethered to Sessions.
%
%   This function implements the Tier 2 -> Tier 3 hierarchical sync.
%   Subjects are established as children of the current Session UID.

% Get project info
projectFile = fullfile('+ndi','+setup','+conv',['+',labName],'project_info.json');
projectInfo = jsondecode(fileread(projectFile));

% Framework objects
subjectMaker = ndi.setup.NDIMaker.subjectMaker;
subjectCreator = ndi.nansen.import.subject.informationCreator();
tableDocMaker = ndi.setup.NDIMaker.tableDocMaker(session,labName);

% 1. HIERARCHICAL TETHERING (Tier 3)
% Ensure subjects are created with a dependency on the Session UID.
% In our 4-tier model, the 'session' object passed here represents Tier 2.
sessionUID = session.id; % Immutable NDI Session ID

% Create subject documents
[~,subjectTable.SubjectLocalIdentifier,subjectTable.SubjectDocumentIdentifier] = ...
    subjectMaker.addSubjectsFromTable(session,subjectTable,subjectCreator);

% 2. ENFORCE TETHER: Add Parent Session Dependency to each Subject Doc
for i = 1:height(subjectTable)
    docID = subjectTable.SubjectDocumentIdentifier{i};
    doc = session.database_search(ndi.query('base.id','exact_string',docID));
    if ~isempty(doc)
        % Add the Session dependency to ensure Tier 2 -> Tier 3 ownership
        doc{1} = doc{1}.set_dependency_value('session_id', sessionUID);
        session.database_add(doc{1}, 'overwrite');
    end
end

% 3. PERSISTENCE: Create ontologyTableRow documents
ind = strcmp({projectInfo.subjectFileColumns.document},'ontologyTableRow');
tableRowVariables = ['SubjectLocalIdentifier','SubjectDocumentIdentifier',...
    {projectInfo.subjectFileColumns(ind).name},'ElectronicFileName'];

% Note: We add the Nansen_UUID to the ontology doc for bi-directional lookup
if ismember('Nansen_UUID', subjectTable.Properties.VariableNames)
    tableRowVariables = [tableRowVariables, 'Nansen_UUID'];
end

tableDocMaker.table2ontologyTableRowDocs(subjectTable(:,tableRowVariables), ...
        {'SubjectDocumentIdentifier'});

end
