function [] = updateAll(dataset,options)
%UPDATEALL Updates all Nansen metatables for a given NDI dataset.
%
%   This function synchronizes the local dataset with the NDI cloud,
%   and updates the Dataset, File, Subject, and Session metatables for
%   the current Nansen project.
%
%   Inputs:
%      dataset (ndi.session.dir or ndi.dataset.dir): The NDI dataset
%         or session object.
%
%   Name-Value Pairs:
%      LabName (char or string): Optional. The name of the lab. Default
%         is current Nansen project name.
%      Project (nansen.config.project.Project): Optional. The Nansen
%         project object. Default is current Nansen project.
%
%   Examples:
%      % Update all metatables for the current dataset:
%      ndi.nansen.metatable.updateAll(dataset)
%
%   See also: NDI.NANSEN.METATABLE.UPDATE, NDI.CLOUD.SYNC.DOWNLOADNEW

% Input argument validation
arguments
    dataset {mustBeA(dataset,{'ndi.session.dir','ndi.dataset.dir'})}
    options.LabName {mustBeText} = nansen.getCurrentProject().Name;
    options.Project {mustBeA(options.Project,'nansen.config.project.Project')} = nansen.getCurrentProject;
end

% Cloud sync is the responsibility of the caller. Both callers
% (ndi.nansen.startup and pulakat.objectmethod.dataset.sync) run
% ndi.cloud.sync.downloadNew themselves with proper error handling
% before invoking updateAll, so doing it here too just produces a
% redundant network round-trip. Repeated calls are harmless but
% wasteful — downloadNew always fetches "documents added since the
% last sync index", which is empty on the second consecutive call.

% First pass: fetch fresh data from the dataset and merge into each
% metatable, capturing whether anything actually moved. We skip the
% per-variable update() calls here for Session and Subject because
% those depend on File data that hasn't been merged yet — they're
% deferred to the second pass below.
ndi.nansen.metatable.update(dataset,'Dataset','Project',options.Project,...
    'LabName',options.LabName);

[sessionChanged] = ndi.nansen.metatable.update(dataset,'Session', ...
    'Project',options.Project,'LabName',options.LabName, ...
    'UpdateVariableNames',{''});

[subjectChanged] = ndi.nansen.metatable.update(dataset,'Subject', ...
    'Project',options.Project,'LabName',options.LabName, ...
    'UpdateVariableNames',{''});

[fileChanged] = ndi.nansen.metatable.update(dataset,'File', ...
    'Project',options.Project,'LabName',options.LabName);

% Second pass: refresh the HasUpdateFunction variables on Subject
% and Session, but only when first-pass merges actually moved data
% the second pass would consume. Subject's variables read from the
% File metatable, and Session's variables read from both Subject
% and File (and from Session itself, e.g. Treatment via
% SessionIdentifier match). When nothing changed during the first
% pass, recomputing every row of these tables produces identical
% values to what's already on disk — pure waste at Pulakat scale,
% where Subject.NumFiles alone iterates Subjects × Files row-pairs.
if subjectChanged || fileChanged
    ndi.nansen.metatable.update(dataset,'Subject','Project',options.Project,...
        'LabName',options.LabName,'UpdateTable',false);
end

if sessionChanged || subjectChanged || fileChanged
    ndi.nansen.metatable.update(dataset,'Session','Project',options.Project,...
        'LabName',options.LabName,'UpdateTable',false);
end

end
