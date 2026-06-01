classdef MetatablePersistence < ndi.unittest.nansen.ProjectTestCase
%METATABLEPERSISTENCE Regression tests that mutations are saved to disk.
%
%   nansen.metadata.MetaTable.open routes through MetaTableCache and may
%   call reloadFromDisk when the cached instance reports IsClean. Some
%   mutation paths leave IsClean=true even after real changes (see
%   ndi.nansen.metatable.update.m:135-139), so a mutation that is only
%   applied to the in-memory table can disappear on the next
%   getMetaTable call. These tests bypass the cache entirely by reading
%   the .mat file directly and asserting the saved entries reflect each
%   mutation.

    methods (Test)
        function removePersists(testCase)
            seed = testCase.buildSubjectTable(3);
            ndi.nansen.metatable.merge(seed, 'Subject');

            ndi.nansen.metatable.remove(seed(1,:), 'Subject');

            entries = testCase.loadFromDisk('Subject');
            testCase.verifyEqual(height(entries), 2, ...
                'remove() did not persist deletion to disk.');
            testCase.verifyFalse( ...
                any(strcmp(entries.SubjectIdentifier, seed.SubjectIdentifier{1})), ...
                'Removed row resurfaced after disk reload.');
        end

        function editPersists(testCase)
            seed = testCase.buildSubjectTable(2);
            ndi.nansen.metatable.merge(seed, 'Subject');

            edited = seed(1,:);
            edited.BiologicalSex = {'Female'};
            ndi.nansen.metatable.edit(edited, 'Subject');

            entries = testCase.loadFromDisk('Subject');
            rowIdx = strcmp(entries.SubjectIdentifier, seed.SubjectIdentifier{1});
            testCase.verifyEqual(entries.BiologicalSex(rowIdx), {'Female'}, ...
                'edit() did not persist column change to disk.');
        end

        function mergeAddPersists(testCase)
            % First merge creates the metatable.
            seed = testCase.buildSubjectTable(2);
            ndi.nansen.metatable.merge(seed, 'Subject');

            % Second merge adds two more rows — the addTable branch.
            more = testCase.buildSubjectTable(2, 100);
            ndi.nansen.metatable.merge(more, 'Subject');

            entries = testCase.loadFromDisk('Subject');
            testCase.verifyEqual(height(entries), 4, ...
                'merge() did not persist addTable rows to disk.');
        end
    end

    methods (Access = private)
        function tbl = buildSubjectTable(testCase, nRows, offset) %#ok<INUSL>
            if nargin < 3; offset = 0; end
            ids = ndi.nansen.fun.getIdentifier( ...
                table(((1:nRows) + offset)', 'VariableNames', {'N'}), 'Subject');
            tbl = table(ids, repmat({'Male'}, nRows, 1), ...
                'VariableNames', {'SubjectIdentifier','BiologicalSex'});
        end

        function entries = loadFromDisk(testCase, dataName)
        %loadFromDisk Read MetaTable .mat file directly, bypassing cache.
            project = nansen.getCurrentProject;
            filePath = project.MetaTableCatalog.getMetaTableFilePath(dataName);
            testCase.fatalAssertTrue(isfile(filePath), ...
                sprintf('MetaTable file not on disk: %s', filePath));
            % MetaTables are saved as a struct with MetaTableEntries
            % (table) and MetaTableMembers (cell). See MetaTable.save:217.
            S = load(filePath);
            entries = S.MetaTableEntries;
        end
    end
end
