function [subjectTable] = createDocuments(session, subjectTable, labName)
%CREATEDOCUMENTS Creates NDI subject documents from a table.

% Get project info
projectFile = fullfile('+ndi','+setup','+conv',['+',labName],'project_info.json');
projectInfo = jsondecode(fileread(projectFile));

% Create subjectMaker and tableDocMaker
subjectMaker = ndi.setup.NDIMaker.subjectMaker;
subjectCreator = ndi.nansen.import.subject.informationCreator();
tableDocMaker = ndi.setup.NDIMaker.tableDocMaker(session,labName);

% Create subject documents (and add to session)
[~,subjectTable.SubjectLocalIdentifier,subjectTable.SubjectDocumentIdentifier] = ...
    subjectMaker.addSubjectsFromTable(session,subjectTable,subjectCreator);

% Create ontologyTableRow documents (and add to session)
ind = strcmp({projectInfo.subjectFileColumns.document},'ontologyTableRow');
tableRowVariables = ['SubjectLocalIdentifier','SubjectDocumentIdentifier',...
    {projectInfo.subjectFileColumns(ind).name},'ElectronicFileName'];
tableDocMaker.table2ontologyTableRowDocs(subjectTable(:,tableRowVariables), ...
        {'SubjectDocumentIdentifier'});

end
