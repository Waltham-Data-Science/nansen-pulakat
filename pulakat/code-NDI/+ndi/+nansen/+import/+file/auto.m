function [dataTable] = auto(session, dataFiles, options)
%AUTO Imports data into an NDI session from a specified data path.
%
%   This function identifies new data files in the given path, creates
%   corresponding data and ontologyLabel documents, and adds them to the
%   NDI session's database. It handles different data types and associates
%   the data with the correct subject.
%
%   Inputs:
%       session (ndi.session.dir): The NDI session object where the data 
%           will be imported.
%       dataPath (char or string): Optional. The path to the directory 
%           containing the data files. Defaults to the current directory.
%       labName (char or string): Optional. The name of the lab. Defaults
%           to the current project name.
%
%   Outputs:
%       dataTable (table): An updated table containing information about 
%           all data in the session, including the newly imported data.

% Input argument validation
arguments
    session {mustBeA(session,{'ndi.session.dir'})}
    dataFiles {mustBeText} = ndi.nansen.import.file.select();
    options.LabName {mustBeText} = nansen.getCurrentProject().Name;
    options.Project {mustBeA(options.Project,'nansen.config.project.Project')} = nansen.getCurrentProject
end

% Convert inputs to char arrays for internal processing
dataFiles = cellstr(dataFiles);
labName = char(options.LabName);

% Get current data table from files
dataTable_files = ndi.setup.conv.(labName).subjectInfoFromFile(dataFiles);

% Add new files to metatable
dataTable = ndi.nansen.import.file(session,dataTable_files,...
    'LabName',labName,'Project',options.Project);

end