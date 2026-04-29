classdef PulakatPlugins < matlab.unittest.TestCase
%PULAKATPLUGINS Smoke tests over every +pulakat plugin file on disk.
%
%   The +pulakat tablevariables, objectmethods, and sessionmethods are
%   discovered by NANSEN purely by folder/name convention — there is no
%   central registry and no compile-time check that a class loads or that
%   a method exposes its attributes. A typo, a missing parent class, or a
%   broken refactor silently disappears from the GUI.
%
%   This class walks src/pulakat/code/+pulakat/ and turns every
%   discovered file into a parameterised test case so:
%
%       * every tablevariable class loads (catches syntax errors and
%         missing parent class),
%       * every tablevariable instantiates with no arguments
%         (catches abstract-property gaps because MATLAB refuses to
%         construct an Abstract subclass that hasn't redeclared every
%         abstract property),
%       * every objectmethod and sessionmethod returns a SessionMethod
%         attributes struct when called as fcn() with one output
%         (the no-arg pathway every NANSEN method file implements),
%
%   so a broken plugin fails CI with a useful per-file message instead
%   of disappearing silently from the GUI.
%
%   The discovery walks the on-disk +pulakat tree under src/, not the
%   class on the path: a file that lives in the package folder but
%   doesn't load is exactly the failure mode we want to surface.

    properties (TestParameter)
        TableVariableClass = ndi.unittest.nansen.PulakatPlugins.discoverTableVariables()
        MethodFunction     = ndi.unittest.nansen.PulakatPlugins.discoverMethodFunctions()
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
            parents = ndi.unittest.nansen.PulakatPlugins.collectSuperclassNames(mc);
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
        function classes = discoverTableVariables()
            %DISCOVERTABLEVARIABLES Walk src/pulakat/code/+pulakat/+tablevariable
            %and return a struct mapping <table>_<ClassName> to the dotted
            %class name. Used as a TestParameter.
            classes = struct();
            tvRoot = fullfile( ...
                ndi.unittest.nansen.PulakatPlugins.pulakatRoot(), ...
                '+tablevariable');
            if ~isfolder(tvRoot); return; end
            tableDirs = dir(fullfile(tvRoot, '+*'));
            for i = 1:numel(tableDirs)
                if ~tableDirs(i).isdir; continue; end
                tableName = tableDirs(i).name(2:end);
                files = dir(fullfile(tvRoot, tableDirs(i).name, '*.m'));
                for j = 1:numel(files)
                    [~, name] = fileparts(files(j).name);
                    fullName = sprintf('pulakat.tablevariable.%s.%s', ...
                        tableName, name);
                    field = matlab.lang.makeValidName( ...
                        sprintf('%s_%s', tableName, name));
                    classes.(field) = fullName;
                end
            end
        end

        function functions = discoverMethodFunctions()
            %DISCOVERMETHODFUNCTIONS Collect every +objectmethod and
            %+sessionmethod function file under src/pulakat/code/+pulakat
            %as a struct mapping a flat field name to the dotted function
            %name. Recursive so nested method packages
            %(+sessionmethod/+methods/+import/+data/...) are included.
            functions = struct();
            root = ndi.unittest.nansen.PulakatPlugins.pulakatRoot();

            % Object methods are scoped per metatable type; each
            % +<table>/+methods/ subtree is collected separately so
            % its prefix is correct.
            omRoot = fullfile(root, '+objectmethod');
            if isfolder(omRoot)
                tableDirs = dir(fullfile(omRoot, '+*'));
                for i = 1:numel(tableDirs)
                    if ~tableDirs(i).isdir; continue; end
                    tableName = tableDirs(i).name(2:end);
                    methodsDir = fullfile(omRoot, tableDirs(i).name, '+methods');
                    if ~isfolder(methodsDir); continue; end
                    prefix = sprintf( ...
                        'pulakat.objectmethod.%s.methods', tableName);
                    fieldPrefix = sprintf('objectmethod_%s_', tableName);
                    functions = ndi.unittest.nansen.PulakatPlugins ...
                        .collectFunctionsRecursive( ...
                            methodsDir, prefix, functions, fieldPrefix);
                end
            end

            % Session methods live under a single +methods/ tree.
            smRoot = fullfile(root, '+sessionmethod', '+methods');
            if isfolder(smRoot)
                functions = ndi.unittest.nansen.PulakatPlugins ...
                    .collectFunctionsRecursive( ...
                        smRoot, ...
                        'pulakat.sessionmethod.methods', ...
                        functions, ...
                        'sessionmethod_');
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
                functions = ndi.unittest.nansen.PulakatPlugins ...
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

        function p = pulakatRoot()
            %PULAKATROOT Filesystem path to src/pulakat/code/+pulakat,
            %resolved from this test file's location so the tests work
            %regardless of cwd.
            here = fileparts(mfilename('fullpath'));
            % .../tests/+ndi/+unittest/+nansen -> .../ (4 parents up).
            repoRoot = fileparts(fileparts(fileparts(fileparts(here))));
            p = fullfile(repoRoot, 'src', 'pulakat', 'code', '+pulakat');
        end
    end
end
