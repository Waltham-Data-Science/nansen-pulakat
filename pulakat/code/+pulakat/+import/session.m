function [session] = session(dataset,sessionPath,sessionName)
%SESSION Summary of this function goes here
%   Detailed explanation goes here

% Input argument validation
arguments
    dataset {mustBeA(dataset,'ndi.dataset.dir')}
    sessionPath {mustBeFolder} = uigetdir(userpath, ...
        'Select directory where session data is located.');
    sessionName {mustBeText} = inputdlg('What is the name of the new session?', ...
        'Session title',[1 50],{'projectName_YYYY'});
end

% Create session
SessionRef = cellstr(sessionName);
[dataParentDir,sessionPath] = fileparts(sessionPath);
SessionPath = cellstr(sessionPath);
sessionMaker = ndi.setup.NDIMaker.sessionMaker(dataParentDir,...
    table(SessionRef,SessionPath));
session = sessionMaker.sessionIndices;
session = session{1};

% Add session to dataset
dataset.add_linked_session(session);

% Sync with cloud

end

