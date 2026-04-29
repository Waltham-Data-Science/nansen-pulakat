classdef ModuleManifest < matlab.unittest.TestCase
%MODULEMANIFEST Validate every NANSEN module's manifest and project_info.
%
%   Discovery is the same as ModulePlugins: every +<name>/module.nansen.json
%   under src/*/code/+*/. For each module:
%
%       * module.nansen.json parses and declares Properties.Name +
%         Properties.Description, with Name matching the +<name>
%         folder it's shipped in.
%
%       * ndi.nansen.fun.readProjectInfo(<moduleName>) succeeds,
%         confirming the integration-layer pairing
%         (src/ndi/+ndi/+setup/+conv/+<moduleName>/project_info.json)
%         exists, parses, and is reachable on the MATLAB path.
%
%       * project_info.json declares every field the integration layer
%         consumes — the list is derived from a `grep projectInfo\.` of
%         src/ — so a missing field doesn't surface as an obscure
%         downstream error inside ndi.nansen.startup.
%
%       * project_info.name matches the discovered module name and
%         projectRelativePath, when present, resolves to an existing
%         folder under the repo. Both are guarantees the runtime
%         silently relies on.
%
%   ReadProjectInfo (the existing test) only exercises a synthetic
%   testlab fixture; this class is what catches a regression in the
%   real shipped config.

    properties (Constant)
        % Fields that ndi.nansen.startup, ndi.nansen.fun.*, and the
        % importers read off the project_info struct. Keep in sync with
        % a `grep -ohE "projectInfo\.[a-zA-Z_]+" src/` over the codebase.
        RequiredProjectInfoFields = { ...
            'URL', ...
            'cloudDatasetID', ...
            'dataFileColumns', ...
            'dataFileTypes', ...
            'name', ...
            'projectRelativePath', ...
            'subjectFileColumns', ...
            'subjectFileName', ...
            'subjectIdentifierFields', ...
            'subjectSuffix'}
    end

    properties (TestParameter)
        Module = ndi.unittest.nansen.ModuleManifest.discoverModulesAsParam()
    end

    methods (Test)
        function moduleManifestParses(testCase, Module)
            manifestPath = fullfile(Module.path, 'module.nansen.json');
            testCase.assertTrue(isfile(manifestPath), sprintf( ...
                'module.nansen.json missing for module %s.', Module.name));
            try
                manifest = jsondecode(fileread(manifestPath));
            catch ME
                testCase.verifyFail(sprintf( ...
                    '%s does not parse as JSON: %s', manifestPath, ME.message));
                return
            end
            testCase.verifyTrue(isfield(manifest, 'Properties'), sprintf( ...
                '%s missing top-level Properties block.', manifestPath));
            testCase.verifyTrue(isfield(manifest.Properties, 'Name'), sprintf( ...
                '%s Properties block missing Name.', manifestPath));
            testCase.verifyTrue(isfield(manifest.Properties, 'Description'), ...
                sprintf('%s Properties block missing Description.', manifestPath));
            testCase.verifyEqual(manifest.Properties.Name, Module.name, ...
                sprintf(['%s Properties.Name (%s) does not match the ' ...
                    '+%s package folder it ships in.'], ...
                    manifestPath, manifest.Properties.Name, Module.name));
        end

        function projectInfoLoadsViaReader(testCase, Module)
            % Every shipped module needs a +ndi/+setup/+conv/+<name>/
            % project_info.json so ndi.nansen.startup can resolve it.
            try
                info = ndi.nansen.fun.readProjectInfo(Module.name);
            catch ME
                testCase.verifyFail(sprintf( ...
                    ['ndi.nansen.fun.readProjectInfo(''%s'') threw: %s. ' ...
                     'Ensure +ndi/+setup/+conv/+%s/project_info.json ' ...
                     'is on the MATLAB path.'], ...
                    Module.name, ME.message, Module.name));
                return
            end
            testCase.verifyClass(info, 'struct');
        end

        function projectInfoHasRequiredFields(testCase, Module)
            info = ndi.nansen.fun.readProjectInfo(Module.name);
            required = ndi.unittest.nansen.ModuleManifest.RequiredProjectInfoFields;
            missing = required(~isfield(info, required));
            testCase.verifyEmpty(missing, sprintf( ...
                'Module %s project_info is missing required field(s): %s', ...
                Module.name, strjoin(missing, ', ')));
        end

        function projectInfoNameMatchesModule(testCase, Module)
            info = ndi.nansen.fun.readProjectInfo(Module.name);
            if ~isfield(info, 'name'); return; end % covered above
            testCase.verifyEqual(info.name, Module.name, sprintf( ...
                ['Module %s project_info.name (%s) does not match its ' ...
                 'package folder. ndi.nansen.startup uses both as the ' ...
                 'same identifier.'], Module.name, info.name));
        end

        function projectRelativePathResolvesToFolder(testCase, Module)
            % projectRelativePath is consumed by ndi.nansen.startup to
            % locate the +<name> package directory; if it points
            % nowhere the GUI launches against an empty project.
            info = ndi.nansen.fun.readProjectInfo(Module.name);
            if ~isfield(info, 'projectRelativePath') || ...
                    isempty(info.projectRelativePath)
                return
            end
            repoRoot = ndi.unittest.nansen.ModulePlugins.repoRoot();
            absPath = fullfile(repoRoot, info.projectRelativePath);
            testCase.verifyTrue(isfolder(absPath), sprintf( ...
                ['Module %s projectRelativePath ''%s'' does not resolve ' ...
                 'to an existing folder under %s.'], ...
                Module.name, info.projectRelativePath, repoRoot));
        end
    end

    methods (Static)
        function param = discoverModulesAsParam()
            %DISCOVERMODULESASPARAM Re-shape ModulePlugins.discoverModules
            %into a TestParameter-friendly struct mapping each module's
            %name to its descriptor (so test case names embed the module
            %name).
            param = struct();
            modules = ndi.unittest.nansen.ModulePlugins.discoverModules();
            for i = 1:numel(modules)
                field = matlab.lang.makeValidName(modules(i).name);
                param.(field) = modules(i);
            end
        end
    end
end
