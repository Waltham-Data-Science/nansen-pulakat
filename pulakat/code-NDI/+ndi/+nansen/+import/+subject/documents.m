function [subjectTable] = documents(session, options)
%CREATEDOCUMENTS Creates NDI subject documents tethered to Sessions.
%
%   This function implements the Tier 2 -> Tier 3 hierarchical sync.
%   Subjects are established as children of the current Session UID.

% Input argument validation
arguments
    session {mustBeA(session,{'ndi.session.dir'})}
    options.LabName {mustBeText} = nansen.getCurrentProject().Name;
    options.Project {mustBeA(options.Project,'nansen.config.project.Project')} = nansen.getCurrentProject;
end

% Get project info
labName = char(options.LabName);
projectFile = fullfile('+ndi','+setup','+conv',['+',labName],'project_info.json');
projectInfo = jsondecode(fileread(projectFile));

% Framework objects
subjectMaker = ndi.setup.NDIMaker.subjectMaker;
subjectCreator = ndi.nansen.import.subject.informationCreator();
tableDocMaker = ndi.setup.NDIMaker.tableDocMaker(session,labName);

% Get subject metatable
project = options.Project;
subjectMetaTable = project.MetaTableCatalog.getMetaTable('Subject');
subjectTable = subjectMetaTable.entries;

% Identify new subjects
indNew = ~ndi.fun.table.identifyValidRows(subjectTable,'SubjectDocumentIdentifier',{''});
subjectTable{:,'LabName'} = labName;
subjectTable_new = subjectTable(indNew,:);

% Only pass valid subjects

% Create subject documents
[~,subjectTable_new.SubjectLocalIdentifier,subjectTable_new.SubjectDocumentIdentifier] = ...
    subjectMaker.addSubjectsFromTable(session,subjectTable_new,subjectCreator);

% Create ontologyTableRow documents (and add to session)
ind = strcmp({projectInfo.subjectFileColumns.document},'ontologyTableRow');
tableRowVariables = [{projectInfo.subjectFileColumns(ind).name},...
    'SubjectIdentifier','ElectronicFileName'];
docs = tableDocMaker.table2ontologyTableRowDocs(subjectTable_new(:,tableRowVariables), ...
    {'SubjectIdentifier'});
for i = 1:numel(docs)
    docs{i}.set_dependency_value('document_id',subjectTable_new.SubjectDocumentIdentifier{i});
end

% Add subject identifiers to metatable
for i = 1:height(subjectTable_new)
    subjectTable = ndi.nansen.metatable.edit(subjectTable_new(i,{'SubjectIdentifier',...
        'SubjectDocumentIdentifier','SubjectLocalIdentifier'}),'Subject',...
        'LabName',labName);
end

end
