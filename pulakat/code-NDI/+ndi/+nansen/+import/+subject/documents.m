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
end

% Get project info
labName = char(options.LabName);
projectFile = fullfile('+ndi','+setup','+conv',['+',labName],'project_info.json');
projectInfo = jsondecode(fileread(projectFile));

% Framework objects
subjectMaker = ndi.setup.NDIMaker.subjectMaker;
subjectCreator = ndi.nansen.import.subject.informationCreator();
tableDocMaker = ndi.setup.NDIMaker.tableDocMaker(session,labName);

% Create subject documents
subjectTable{:,'LabName'} = {'pulakat'};
[~,subjectTable.SubjectLocalIdentifier,subjectTable.SubjectDocumentIdentifier] = ...
    subjectMaker.addSubjectsFromTable(session,subjectTable,subjectCreator);

% Create ontologyTableRow documents (and add to session)
indOTR = strcmp({projectInfo.subjectFileColumns.document},'ontologyTableRow');
tableRowVariables = [{projectInfo.subjectFileColumns(indOTR).name},...
    'SubjectDocumentIdentifier'];
tableDocMaker.table2ontologyTableRowDocs(subjectTable(:,tableRowVariables), ...
    {'SubjectIdentifier'},'DependencyVariable','SubjectDocumentIdentifier');

end
