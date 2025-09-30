function [dataTable] = data(session,dataPath,options)
%DATA Summary of this function goes here
%   Detailed explanation goes here

% Input argument validation
arguments
    session {mustBeA(session,{'ndi.session.dir'})}
    dataPath {mustBeText} = '';
    options.DirOrFiles {mustBeMember(options.DirOrFiles,{'files','dir'})} = 'files';
end

% Retrieve cell array of files
dataFiles = pulakat.import.selectFiles(dataPath,'DirOrFiles',options.DirOrFiles);

% Check that there are still files to import


% Identify which data files are new
dataTable_currentPath = pulakat.import.dataFiles(dataFiles);
% dataTable_ingested = ;% get current table from session
dataTable_newOnly = dataTable_currentPath;% compare files found in current path with existing files

% Get subjects in session
subjectTable = ndi.fun.docTable.subject(session);

% Match data files to subjects
[indSubjects,numSubjects] = ndi.setup.conv.pulakat.matchData2Subjects(diaTable,subjectTable);
dataTable_matching = dataTable_newOnly(numSubjects == 1,:);
dataTable_matching.indSubject = [indSubjects{numSubjects == 1}]';

% Create data documents (and add to session)
indDIA = ndi.fun.table.identifyMatchingRows(dataTable_newOnly,'fileType','DIA');
pulakat.import.DIA(session,dataTable_newOnly.fileName(indDIA));



end

