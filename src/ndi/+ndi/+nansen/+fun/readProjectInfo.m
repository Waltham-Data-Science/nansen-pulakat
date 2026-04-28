function projectInfo = readProjectInfo(labName)
%READPROJECTINFO Reads the project_info.json for a lab.
%
%   projectInfo = ndi.nansen.fun.readProjectInfo(labName) loads the
%   package-shipped project_info.json for the given lab and returns it
%   as a struct.
%
%   The helper resolves the package file via WHICH so it works
%   regardless of the current working directory, centralising what
%   would otherwise be 15 identical jsondecode(fileread(...)) call
%   sites across the codebase.
%
%   Inputs:
%      labName (char or string): Name of the lab (e.g. 'pulakat'). The
%         function looks up '+ndi/+setup/+conv/+<labName>/project_info.json'.
%
%   Outputs:
%      projectInfo (struct): Parsed project info.
%
%   See also: NDI.NANSEN.STARTUP

arguments
    labName {mustBeTextScalar}
end
labName = char(labName);

baseFile = which(fullfile('+ndi','+setup','+conv',['+',labName],'project_info.json'));
if isempty(baseFile)
    error('NDI:Nansen:Fun:ReadProjectInfo:NotFound', ...
        ['[NDI:Nansen:Fun:ReadProjectInfo:NotFound] Could not locate ' ...
         'project_info.json for lab ''%s''. Ensure ' ...
         '''+ndi/+setup/+conv/+%s/project_info.json'' is on the MATLAB ' ...
         'path.'], labName, labName);
end
projectInfo = jsondecode(fileread(baseFile));

end
