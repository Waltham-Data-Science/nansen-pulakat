function projectInfo = readProjectInfo(labName)
%READPROJECTINFO Reads the project_info.json for a lab with local overrides.
%
%   projectInfo = ndi.nansen.fun.readProjectInfo(labName) loads the
%   package-shipped project_info.json for the given lab and merges in any
%   client-specific overrides from userpath/ndi/<labName>_overrides.json.
%
%   The helper resolves the package file via WHICH so it works regardless
%   of the current working directory. Overrides let a client change
%   deployment-specific fields (e.g. cloudDatasetID, subjectSuffix)
%   without editing source that is tracked in git.
%
%   Inputs:
%      labName (char or string): Name of the lab (e.g. 'pulakat'). The
%         function looks up '+ndi/+setup/+conv/+<labName>/project_info.json'.
%
%   Outputs:
%      projectInfo (struct): Parsed project info with overrides applied.
%
%   Override file format:
%      userpath/ndi/<labName>_overrides.json contains a flat JSON object
%      whose top-level fields replace the corresponding fields in the
%      shipped project_info.json. Example:
%         {
%           "cloudDatasetID": "66abc123deadbeefcafef00d",
%           "subjectSuffix": "@my-lab.example.edu"
%         }
%
%   See also: NDI.NANSEN.STARTUP

arguments
    labName {mustBeTextScalar}
end
labName = char(labName);

baseFile = which(fullfile('+ndi','+setup','+conv',['+',labName],'project_info.json'));
if isempty(baseFile)
    error('NDI:Nansen:Fun:ReadProjectInfo:NotFound', ...
        ['Could not locate project_info.json for lab ''%s''. Ensure ' ...
         '''+ndi/+setup/+conv/+%s/project_info.json'' is on the MATLAB path.'], ...
        labName, labName);
end
projectInfo = jsondecode(fileread(baseFile));

overrideFile = fullfile(userpath, 'ndi', [labName, '_overrides.json']);
if isfile(overrideFile)
    overrides = jsondecode(fileread(overrideFile));
    overrideFields = fieldnames(overrides);
    for i = 1:numel(overrideFields)
        projectInfo.(overrideFields{i}) = overrides.(overrideFields{i});
    end
end

end
