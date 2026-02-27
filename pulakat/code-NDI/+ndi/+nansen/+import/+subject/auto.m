function [subjectTable_files] = auto(session,subjectFile,options)
%AUTO Imports subjects into an NDI session from a specified data path.
%
%   This function identifies new subjects from metadata files, creates
%   corresponding subject documents, and adds them to the NDI session's
%   database.
%
%   Inputs:
%       session (ndi.session.dir): The NDI session object where the 
%           subjects will be imported.
%       dataPath (char or string): Optional. The path to the directory 
%           containing the subject files. Defaults to the current directory.
%       labName (char or string): Optional. The name of the lab. Defaults
%           to the current project name.
%
%   Outputs:
%       subjectTable (table): An updated table containing information about
%           all subjects in the session, including the newly imported subjects.

% Input argument validation
arguments
    session {mustBeA(session,{'ndi.session.dir'})}
    subjectFile {mustBeText} = ndi.nansen.import.file.select('','FileExtensions',{'csv','xls','xlsx'});
    options.LabName {mustBeText} = nansen.getCurrentProject().Name;
    options.Project {mustBeA(options.Project,'nansen.config.project.Project')} = nansen.getCurrentProject
end

% Convert inputs to char arrays for internal processing
subjectFile = cellstr(subjectFile);
labName = char(options.LabName);

% Get current subject table from files
subjectTable_files = ndi.nansen.import.subject.tableFromFile(subjectFile,labName);

% Add new subjects to metatable
subjectTable = ndi.nansen.import.subject(session,subjectTable_files,...
    'LabName',labName,'Project',options.Project);

end