function [subjectTable] = auto(session,subjectFile,options)
%AUTO Automatically imports subject metadata from a file.
%
%   This function reads subject information from a specified metadata
%   file (e.g., CSV or Excel) and merges it into the Nansen 'Subject'
%   metatable. It ensures that subjects are unique and associated
%   with the correct session.
%
%   Inputs:
%      session (ndi.session.dir): The NDI session object.
%      subjectFile (char or string): Optional. Path to the subject file.
%         If not provided, a selection dialog will open.
%
%   Name-Value Pairs:
%      LabName (char or string): Optional. The name of the lab. Default
%         is the current Nansen project name.
%      Project (nansen.config.project.Project): Optional. The Nansen
%         project object. Default is the current Nansen project.
%
%   Outputs:
%      subjectTable (table): The updated Nansen 'Subject' metatable entries.
%
%   Examples:
%      % Import subjects from a CSV file:
%      ndi.nansen.import.subject.auto(session, 'subjects.csv')
%
%   See also: NDI.NANSEN.IMPORT.SUBJECT, NDI.NANSEN.IMPORT.SUBJECT.TABLEFROMFILE

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