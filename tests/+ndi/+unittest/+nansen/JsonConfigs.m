classdef JsonConfigs < matlab.unittest.TestCase
%JSONCONFIGS Validate every JSON config file shipped under src/.
%
%   Walks src/ recursively and turns every *.json file into a
%   parameterised test case asserting it parses with jsondecode and
%   isn't empty. Covers per-module configs (menu_visibility.json,
%   metatable_column_settings.json, ...), per-module integration
%   settings under +ndi/+setup/+conv/+<name>/ (project_info.json,
%   tableDoc_dictionary.json), and any shared integration JSON
%   (e.g. +ndi/+nansen/+import/+subject/strains.json) without
%   needing a per-file allowlist.
%
%   Why bother: a typo or truncation in any of these files only
%   surfaces at runtime as an obscure error from a downstream consumer.
%   This test catches the JSON parse failure with a per-file message
%   before the consumer ever runs.
%
%   Schema-level checks for module.nansen.json and project_info.json
%   live in ModuleManifest, so this class stays cheap and entirely
%   structure-agnostic. Discovery has no module/lab knowledge baked
%   in: a fork that adds new JSON anywhere under src/ gets coverage
%   for free.

    properties (TestParameter)
        ConfigFile = ndi.unittest.nansen.JsonConfigs.discoverJsonFiles()
    end

    methods (Test)
        function configFileParses(testCase, ConfigFile)
            try
                value = jsondecode(fileread(ConfigFile));
            catch ME
                testCase.verifyFail(sprintf( ...
                    '%s does not parse as JSON: %s', ...
                    ConfigFile, ME.message));
                return
            end
            testCase.verifyNotEmpty(value, sprintf( ...
                '%s parsed to an empty value; the file is likely empty.', ...
                ConfigFile));
        end
    end

    methods (Static)
        function configs = discoverJsonFiles()
            %DISCOVERJSONFILES Walk src/ and collect every *.json into
            %a struct mapping a flat field name (derived from the path
            %under src/) to the absolute filesystem path.
            configs = struct();
            srcRoot = fullfile( ...
                ndi.unittest.nansen.ModulePlugins.repoRoot(), 'src');
            if ~isfolder(srcRoot); return; end
            configs = ndi.unittest.nansen.JsonConfigs ...
                .collectJsonRecursive(srcRoot, srcRoot, configs);
        end

        function configs = collectJsonRecursive(currentDir, srcRoot, configs)
            files = dir(fullfile(currentDir, '*.json'));
            for i = 1:numel(files)
                fullPath = fullfile(files(i).folder, files(i).name);
                % Field name = relative path under src/ with separators
                % flattened to underscores. Keeps each test case's name
                % human-readable while remaining a valid MATLAB
                % identifier.
                rel = erase(fullPath, [srcRoot, filesep]);
                rel = erase(rel, '+');
                field = matlab.lang.makeValidName( ...
                    strrep(strrep(rel, filesep, '_'), '.', '_'));
                configs.(field) = fullPath;
            end
            entries = dir(currentDir);
            for i = 1:numel(entries)
                if ~entries(i).isdir; continue; end
                if any(strcmp(entries(i).name, {'.', '..'})); continue; end
                configs = ndi.unittest.nansen.JsonConfigs ...
                    .collectJsonRecursive( ...
                        fullfile(currentDir, entries(i).name), ...
                        srcRoot, configs);
            end
        end
    end
end
