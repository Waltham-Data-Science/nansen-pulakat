function [subjectTable] = documents(session, subjectTable, options)
%DOCUMENTS Creates NDI subject documents tethered to Sessions.
%
%   This function implements the Tier 2 -> Tier 3 hierarchical sync.
%   Subjects are established as children of the current Session UID
%   within the NDI database.
%
%   Inputs:
%      session (ndi.session.dir): The NDI session object.
%      subjectTable (table): A table containing the subject records.
%
%   Name-Value Pairs:
%      LabName (char or string): Optional. The name of the lab. Default
%         is the current Nansen project name.
%      Project (nansen.config.project.Project): Optional. The Nansen
%         project object. Default is the current Nansen project.
%
%   Outputs:
%      subjectTable (table): The updated Nansen 'Subject' metatable
%         entries with established UIDs.
%
%   Examples:
%      % Create NDI documents for session subjects:
%      ndi.nansen.import.subject.documents(session, mySubjectTable)
%
%   See also: NDI.NANSEN.IMPORT.FILE.CREATEDOCUMENTS

% Input argument validation
arguments
    session {mustBeA(session,{'ndi.session.dir'})}
    subjectTable table
    options.LabName {mustBeText} = nansen.getCurrentProject().Name;
    options.Project {mustBeA(options.Project,'nansen.config.project.Project')} = nansen.getCurrentProject;
end

% Get project info
labName = char(options.LabName);
projectBase = fileparts(fileparts(which('ndi.nansen.startup'))); projectFile = fullfile(projectBase,'+setup','+conv',['+',labName],'project_info.json');
projectInfo = jsondecode(fileread(projectFile));

% Framework objects
subjectMaker = ndi.setup.NDIMaker.subjectMaker;
subjectCreator = ndi.nansen.import.subject.informationCreator();
tableDocMaker = ndi.setup.NDIMaker.tableDocMaker(session,labName);

% Get subject metatable
project = options.Project;
subjectMetaTable = project.MetaTableCatalog.getMetaTable('Subject');
subjectTable_session = subjectMetaTable.entries;

% Identify new subjects
indNew = cellfun(@(x) isempty(x) || strcmp(x, 'N/A'), subjectTable.SubjectDocumentIdentifier);
subjectTable{:,'LabName'} = labName;
subjectTable_new = subjectTable(indNew,:);

% Only pass valid subjects

% Create subject documents
[~,subjectTable_new.SubjectLocalIdentifier,subjectTable_new.SubjectDocumentIdentifier] = ...
    subjectMaker.addSubjectsFromTable(session,subjectTable_new,subjectCreator);

% Create ontologyTableRow documents (and add to session)
ind = strcmp({projectInfo.subjectFileColumns.document},'ontologyTableRow');
tableRowVariables = [{projectInfo.subjectFileColumns(ind).name},...
    'SubjectIdentifier','ElectronicFileName','SubjectDocumentIdentifier'];
docs = tableDocMaker.table2ontologyTableRowDocs(subjectTable_new(:,tableRowVariables), ...
    {'SubjectIdentifier'},'DependencyVariable','SubjectDocumentIdentifier');

% Add subject identifiers to metatable
for i = 1:height(subjectTable_new)
    subjectTable = ndi.nansen.metatable.edit(subjectTable_new(i,{'SubjectIdentifier',...
        'SubjectDocumentIdentifier','SubjectLocalIdentifier'}),'Subject',...
        'LabName',labName);
end

end
