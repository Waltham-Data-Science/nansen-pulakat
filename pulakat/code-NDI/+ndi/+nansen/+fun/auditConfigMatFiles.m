function results = auditConfigMatFiles(options)
%AUDITCONFIGMATFILES Inspect committed .mat configuration files for portability.
%
%   The project ships a number of .mat files under
%   pulakat/configurations/, pulakat/metadata/, and
%   pulakat/configurations/custom_options/. These are opaque binaries in
%   code review, but may contain absolute paths or machine-specific values
%   copied from a developer's machine, which break on a fresh client.
%
%   This helper loads each .mat file, lists the variables, and reports any
%   string value that looks like an absolute filesystem path (starts with
%   '/' on Unix, or '<drive>:\' / '\\' on Windows). Review the output
%   before shipping to a client and rebuild any file that contains a
%   developer-specific path.
%
%   Name-Value Pairs:
%      ProjectRoot (char): Optional. The path to the pulakat project
%         root. Default: auto-detected from the installed package.
%      Verbose (logical): If true, print per-file summaries. Default: true.
%
%   Outputs:
%      results (struct array): One entry per .mat file with fields
%         File, Variables (struct array with Name, Class, Size),
%         SuspiciousPaths (cell array of hit strings).
%
%   Example:
%      r = ndi.nansen.fun.auditConfigMatFiles();
%      problems = r(arrayfun(@(x) ~isempty(x.SuspiciousPaths), r));

arguments
    options.ProjectRoot (1,:) char = ''
    options.Verbose (1,1) logical = true
end

if isempty(options.ProjectRoot)
    thisFile = which('ndi.nansen.fun.auditConfigMatFiles');
    % Package file lives at .../pulakat/code-NDI/+ndi/+nansen/+fun/ so the
    % pulakat project root is five levels up.
    options.ProjectRoot = fileparts(fileparts(fileparts(fileparts(fileparts(fileparts(thisFile))))));
end

scanDirs = { ...
    fullfile(options.ProjectRoot,'configurations'), ...
    fullfile(options.ProjectRoot,'configurations','custom_options'), ...
    fullfile(options.ProjectRoot,'metadata','tables')};

results = struct('File',{},'Variables',{},'SuspiciousPaths',{});
pathPattern = '(^|[^\w])(/[^\s''"]{2,}|[A-Za-z]:\\[^\s''"]+|\\\\[^\s''"]+)';

for d = 1:numel(scanDirs)
    if ~isfolder(scanDirs{d}); continue; end
    matFiles = dir(fullfile(scanDirs{d},'*.mat'));
    for f = 1:numel(matFiles)
        matPath = fullfile(matFiles(f).folder, matFiles(f).name);
        entry = struct('File', matPath, 'Variables', struct([]), ...
            'SuspiciousPaths', {{}});
        try
            loaded = load(matPath);
        catch ME
            if options.Verbose
                fprintf('[skip] %s: %s\n', matPath, ME.message);
            end
            entry.SuspiciousPaths = {sprintf('load failed: %s', ME.message)};
            results(end+1) = entry; %#ok<AGROW>
            continue
        end
        varNames = fieldnames(loaded);
        varInfo = struct('Name',{},'Class',{},'Size',{});
        for v = 1:numel(varNames)
            val = loaded.(varNames{v});
            varInfo(end+1) = struct('Name',varNames{v}, ...
                'Class',class(val),'Size',size(val)); %#ok<AGROW>
            entry.SuspiciousPaths = [entry.SuspiciousPaths; ...
                local_findPathStrings(val, pathPattern)];
        end
        entry.Variables = varInfo;
        if options.Verbose
            fprintf('%s  (%d var%s)\n', matPath, numel(varInfo), ...
                char(string(numel(varInfo)~=1)*'s'));
            for p = 1:numel(entry.SuspiciousPaths)
                fprintf('    !! %s\n', entry.SuspiciousPaths{p});
            end
        end
        results(end+1) = entry; %#ok<AGROW>
    end
end

if options.Verbose
    nHits = sum(arrayfun(@(x) numel(x.SuspiciousPaths), results));
    fprintf('\nScanned %d .mat file(s); %d suspicious path-like string(s) found.\n', ...
        numel(results), nHits);
end
end


function hits = local_findPathStrings(value, pattern)
%LOCAL_FINDPATHSTRINGS Recurse through value and collect path-looking strings.

hits = {};
if ischar(value) || isstring(value)
    for s = reshape(string(value),1,[])
        m = regexp(s, pattern, 'match');
        hits = [hits; m(:)]; %#ok<AGROW>
    end
elseif iscell(value)
    for i = 1:numel(value)
        hits = [hits; local_findPathStrings(value{i}, pattern)]; %#ok<AGROW>
    end
elseif isstruct(value)
    fn = fieldnames(value);
    for i = 1:numel(value)
        for j = 1:numel(fn)
            hits = [hits; local_findPathStrings(value(i).(fn{j}), pattern)]; %#ok<AGROW>
        end
    end
elseif istable(value)
    for j = 1:width(value)
        hits = [hits; local_findPathStrings(value{:,j}, pattern)]; %#ok<AGROW>
    end
elseif isa(value,'containers.Map')
    keysList = keys(value);
    for i = 1:numel(keysList)
        hits = [hits; local_findPathStrings(value(keysList{i}), pattern)]; %#ok<AGROW>
    end
end
end
