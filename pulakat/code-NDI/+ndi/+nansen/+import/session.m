function [session] = session(dataset, sessionPath, sessionName)
%SESSION Creates a new NDI session and adds it to a dataset.
%
%   This function creates an NDI session from a local path and links
%   it to the specified NDI dataset. If path or name are not provided,
%   the function will prompt the user via dialog boxes.
%
%   Inputs:
%      dataset (ndi.dataset.dir): The NDI dataset object to which the
%         session will be added.
%      sessionPath (char or string): Optional. Local path for session data.
%         If not provided, a directory picker will open.
%      sessionName (char or string): Optional. Name of the new session.
%         If not provided, a dialog box will prompt the user.
%
%   Outputs:
%      session (ndi.session.dir): The newly created NDI session object.
%
%   Examples:
%      % Create a session interactively:
%      session = ndi.nansen.import.session(dataset)
%
%   See also: NDI.NANSEN.IMPORT.DATASET, NDI.SESSION.DIR

% Input argument validation
arguments
    dataset {mustBeA(dataset,'ndi.dataset.dir')}
    sessionPath {mustBeFolder} = uigetdir(userpath, ...
        'Select directory where session data is located.');
    sessionName {mustBeText} = inputdlg('What is the name of the new session?', ...
        'Session title',[1 50],{'projectName_YYYY'});
end

% Convert session name to char
sessionName = cellstr(sessionName); sessionName = sessionName{1};

% Create session
session = ndi.session.dir(sessionName, sessionPath);

% Add session to dataset
dataset.add_linked_session(session);

end

