function [session] = session(dataset,sessionPath,sessionName)
%SESSION Creates a new NDI session and adds it to a dataset.
%   This function prompts the user to select a directory for the session data,
%   asks for a session name, creates the NDI session, and then links it to the
%   specified NDI dataset.
%
%   Inputs:
%   dataset (ndi.dataset.dir): The NDI dataset object to which the new session will be added.
%   sessionPath (char or string): Optional. The path to the directory where the session data is located.
%       If not provided, a dialog box will open for the user to select the directory.
%   sessionName (char or string): Optional. The name of the new session.
%       If not provided, a dialog box will prompt the user to enter a name.
%
%   Outputs:
%   session (ndi.session.dir): The newly created NDI session object.

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

