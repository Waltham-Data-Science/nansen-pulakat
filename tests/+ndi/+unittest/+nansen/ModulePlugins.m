classdef ModulePlugins < matlab.unittest.TestCase
%MODULEPLUGINS Smoke tests over every NANSEN-module plugin file on disk.
%
%   A NANSEN module is a +<name> package with a module.nansen.json manifest;
%   nansen-pulakat ships one (+pulakat) but a fork could ship others. This
%   class discovers every module under src/*/code/+*/module.nansen.json
%   and walks each one's +tablevariable / +objectmethod / +sessionmethod
%   subtrees, turning every plugin file into a parameterised test case.
%
%   The plugins in those subtrees are picked up by NANSEN's plugin loader
%   purely by folder/name convention — no central registry, no compile-time
%   check that a class loads or that a method exposes its attributes. A
%   typo, a missing parent class, or a broken refactor turns into a column
%   or method that silently disappears from the GUI.
%
%   The three contracts checked per file:
%
%       * every tablevariable class loads (catches syntax errors and a
%         renamed/missing parent class),
%       * every tablevariable instantiates with no arguments — MATLAB
%         refuses to construct a subclass of an Abstract class that
%         hasn't redeclared every abstract property, so this catches
%         IS_EDITABLE / DEFAULT_VALUE contract gaps,
%       * every objectmethod and sessionmethod returns a struct from its
%         no-arg attributes call (the pathway NANSEN's session-method
%         loader uses to discover the menu entry).
%
%   Each test case's name embeds the module name (e.g.
%   `tableVariableLoads(pulakat_dataset_Cloud)`) so a failure points
%   straight at the offending file.

    properties (TestParameter)
        TableVariableClass = ndi.unittest.nansen.ModulePlugins.discoverTableVariables()
        MethodFunction     = ndi.unittest.nansen.ModulePlugins.discoverMethodFunctions()
    end

    methods (Test)
        function tableVariableLoads(testCase, TableVariableClass)
            mc = meta.class.fromName(TableVariableClass);
            testCase.verifyNotEmpty(mc, sprintf( ...
                ['Class %s could not be resolved by MATLAB. Likely ' ...
                 'cause: syntax error in the .m file or a renamed ' ...
                 'parent class.'], TableVariableClass));
        end

        function tableVariableInstantiates(testCase, TableVariableClass)
            % MATLAB refuses to construct a subclass of an Abstract
            % class that hasn't redeclared every abstract property,
            % so a no-arg construction here is the cheapest way to
            % verify the IS_EDITABLE / DEFAULT_VALUE contract is met.
            % Use a try/catch rather than verifyWarningFree so a benign
            % upstream warning during construction doesn't fail this
            % smoke test.
            ctor = str2func(TableVariableClass);
            try
                obj = ctor();
            catch ME
                testCase.verifyFail(sprintf( ...
                    'Constructor for %s threw: %s', ...
                    TableVariableClass, ME.message));
                return
            end
            testCase.verifyClass(obj, TableVariableClass);
        end

        function tableVariableInheritsFromAbstract(testCase, TableVariableClass)
            mc = meta.class.fromName(TableVariableClass);
            testCase.assertNotEmpty(mc); % covered by tableVariableLoads
            parents = ndi.unittest.nansen.ModulePlugins.collectSuperclassNames(mc);
            testCase.verifyTrue( ...
                any(strcmp(parents, 'nansen.metadata.abstract.TableVariable')), ...
                sprintf(['%s does not inherit from ' ...
                    'nansen.metadata.abstract.TableVariable. NANSEN''s ' ...
                    'plugin loader will skip it.'], TableVariableClass));
        end

        function methodReturnsAttributes(testCase, MethodFunction)
            % Every +objectmethod/+sessionmethod file follows the
            % NANSEN convention of returning an attributes struct when
            % called with nargin==0 and nargout>0. If the file is
            % missing, has a syntax error, or has lost the no-arg
            % branch, this fails for that specific function.
            fcn = str2func(MethodFunction);
            try
                attrs = fcn();
            catch ME
                testCase.verifyFail(sprintf( ...
                    'Calling %s() for attributes threw: %s', ...
                    MethodFunction, ME.message));
                return
            end
            testCase.verifyClass(attrs, 'struct', sprintf( ...
                ['%s did not return a struct from its no-arg ' ...
                 'attributes call. NANSEN''s session-method loader ' ...
                 'expects fcnAttributes from SessionMethod.setAttributes.'], ...
                MethodFunction));
        end
    end

    methods (Static)
        function modules = discoverModules()
            %DISCOVERMODULES Find every NANSEN module declared under src/.
            %
            %   A module is a +<name> package directory containing a
            %   module.nansen.json manifest. Returns a struct array with
            %   fields .name (e.g. 'pulakat') and .path (the absolute
            %   path of the +<name> directory). One entry per module.
            modules = struct('name', {}, 'path', {});
            srcRoot = fullfile( ...
                ndi.unittest.nansen.ModulePlugins.repoRoot(), 'src');
            if ~isfolder(srcRoot); return; end
            % Walk src/*/code/+*/ explicitly: dir() supports wildcards
            % only at one level of the path, so doing it by hand keeps
            % the search scoped to genuine module roots and avoids
            % pulling in unrelated module.nansen.json files buried
            % deeper in the tree.
            labRoots = dir(srcRoot);
            for i = 1:numel(labRoots)
                if ~labRoots(i).isdir || startsWith(labRoots(i).name, '.')
                    continue
                end
                codeDir = fullfile(srcRoot, labRoots(i).name, 'code');
                if ~isfolder(codeDir); continue; end
                pkgs = dir(fullfile(codeDir, '+*'));
                for j = 1:numel(pkgs)
                    if ~pkgs(j).isdir; continue; end
                    pkgPath = fullfile(codeDir, pkgs(j).name);
                    manifest = fullfile(pkgPath, 'module.nansen.json');
                    if ~isfile(manifest); continue; end
                    modules(end+1) = struct( ...
                        'name', pkgs(j).name(2:end), ...
                        'path', pkgPath); %#ok<AGROW>
                end
            end
        end

        function classes = discoverTableVariables()
            %DISCOVERTABLEVARIABLES Walk every discovered module's
            %+tablevariable subtree and return a struct mapping
            %<module>_<table>_<ClassName> to the dotted class name.
            classes = struct();
            modules = ndi.unittest.nansen.ModulePlugins.discoverModules();
            for k = 1:numel(modules)
                tvRoot = fullfile(modules(k).path, '+tablevariable');
                if ~isfolder(tvRoot); continue; end
                tableDirs = dir(fullfile(tvRoot, '+*'));
                for i = 1:numel(tableDirs)
                    if ~tableDirs(i).isdir; continue; end
                    tableName = tableDirs(i).name(2:end);
                    files = dir(fullfile(tvRoot, tableDirs(i).name, '*.m'));
                    for j = 1:numel(files)
                        [~, name] = fileparts(files(j).name);
                        fullName = sprintf('%s.tablevariable.%s.%s', ...
                            modules(k).name, tableName, name);
                        field = matlab.lang.makeValidName(sprintf( ...
                            '%s_%s_%s', modules(k).name, tableName, name));
                        classes.(field) = fullName;
                    end
                end
            end
        end

        function functions = discoverMethodFunctions()
            %DISCOVERMETHODFUNCTIONS Collect every +objectmethod and
            %+sessionmethod function file under each discovered module
            %as a struct mapping a flat field name to the dotted function
            %name. Recursive so nested method packages
            %(+sessionmethod/+methods/+import/+data/...) are included.
            functions = struct();
            modules = ndi.unittest.nansen.ModulePlugins.discoverModules();
            for k = 1:numel(modules)
                modName = modules(k).name;
                modPath = modules(k).path;

                % Object methods are scoped per metatable type; each
                % +<table>/+methods/ subtree is collected separately so
                % its prefix is correct.
                omRoot = fullfile(modPath, '+objectmethod');
                if isfolder(omRoot)
                    tableDirs = dir(fullfile(omRoot, '+*'));
                    for i = 1:numel(tableDirs)
                        if ~tableDirs(i).isdir; continue; end
                        tableName = tableDirs(i).name(2:end);
                        methodsDir = fullfile(omRoot, tableDirs(i).name, '+methods');
                        if ~isfolder(methodsDir); continue; end
                        prefix = sprintf( ...
                            '%s.objectmethod.%s.methods', modName, tableName);
                        fieldPrefix = sprintf( ...
                            '%s_objectmethod_%s_', modName, tableName);
                        functions = ndi.unittest.nansen.ModulePlugins ...
                            .collectFunctionsRecursive( ...
                                methodsDir, prefix, functions, fieldPrefix);
                    end
                end

                % Session methods live under a single +methods/ tree.
                smRoot = fullfile(modPath, '+sessionmethod', '+methods');
                if isfolder(smRoot)
                    functions = ndi.unittest.nansen.ModulePlugins ...
                        .collectFunctionsRecursive( ...
                            smRoot, ...
                            sprintf('%s.sessionmethod.methods', modName), ...
                            functions, ...
                            sprintf('%s_sessionmethod_', modName));
                end
            end
        end

        function functions = collectFunctionsRecursive(currentDir, prefix, functions, fieldPrefix)
            files = dir(fullfile(currentDir, '*.m'));
            for i = 1:numel(files)
                [~, name] = fileparts(files(i).name);
                fullName = sprintf('%s.%s', prefix, name);
                field = matlab.lang.makeValidName([fieldPrefix, name]);
                functions.(field) = fullName;
            end
            subpkgs = dir(fullfile(currentDir, '+*'));
            for i = 1:numel(subpkgs)
                if ~subpkgs(i).isdir; continue; end
                subName = subpkgs(i).name(2:end);
                functions = ndi.unittest.nansen.ModulePlugins ...
                    .collectFunctionsRecursive( ...
                        fullfile(currentDir, subpkgs(i).name), ...
                        sprintf('%s.%s', prefix, subName), ...
                        functions, ...
                        [fieldPrefix, subName, '_']);
            end
        end

        function names = collectSuperclassNames(mc)
            %COLLECTSUPERCLASSNAMES Flatten the meta.class superclass
            %graph into a cell array of dotted class names so a test
            %can ask "is X anywhere in this class's lineage".
            names = {};
            stack = {mc};
            while ~isempty(stack)
                current = stack{end};
                stack(end) = [];
                if isempty(current); continue; end
                supers = current.SuperclassList;
                for i = 1:numel(supers)
                    names{end+1} = supers(i).Name; %#ok<AGROW>
                    stack{end+1} = supers(i); %#ok<AGROW>
                end
            end
        end

        function p = repoRoot()
            %REPOROOT Filesystem path to the repository root, resolved
            %from this test file's location so the tests work regardless
            %of cwd.
            here = fileparts(mfilename('fullpath'));
            % .../tests/+ndi/+unittest/+nansen -> .../ (4 parents up).
            p = fileparts(fileparts(fileparts(fileparts(here))));
        end
    end
end
