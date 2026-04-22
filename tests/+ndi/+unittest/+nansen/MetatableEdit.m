classdef MetatableEdit < ndi.unittest.nansen.ProjectTestCase
%METATABLEEDIT Unit tests for ndi.nansen.metatable.edit.
%
%   Verifies the M1a batch-by-column rewrite — specifically that
%   updates land correctly across cell column types, and that rows
%   whose values did not change aren't touched.
%
%   Like MetatableMerge, these tests verify against the metaTable
%   object edit() returns (in-memory state) rather than re-fetching
%   from the catalog: MetaTableCatalog.getMetaTable always re-loads
%   from disk, and edit() doesn't persist.

    methods (Test)
        function editsCellColumn(testCase)
            seed = testCase.buildSubjectTable(3, 'Male');
            ndi.nansen.metatable.merge(seed, 'Subject');

            change = seed;
            change.BiologicalSex(:) = {'Female'};
            mt = ndi.nansen.metatable.edit(change, 'Subject');

            testCase.verifyEqual(mt.entries.BiologicalSex, repmat({'Female'},3,1));
        end

        function editsOnlyDifferingRows(testCase)
            seed = testCase.buildSubjectTable(3, 'Male');
            ndi.nansen.metatable.merge(seed, 'Subject');

            change = seed;
            change.BiologicalSex{2} = 'Female';
            mt = ndi.nansen.metatable.edit(change, 'Subject');

            testCase.verifyEqual(mt.entries.BiologicalSex, ...
                {'Male';'Female';'Male'});
        end

        function ignoresEmptyAndNAValues(testCase)
            seed = testCase.buildSubjectTable(2, 'Male');
            ndi.nansen.metatable.merge(seed, 'Subject');

            change = seed;
            change.BiologicalSex = {''; 'N/A'};
            mt = ndi.nansen.metatable.edit(change, 'Subject');

            testCase.verifyEqual(mt.entries.BiologicalSex, {'Male';'Male'});
        end

        function preservesUnchangedColumns(testCase)
            seed = testCase.buildSubjectTable(2, 'Male');
            seed.SessionName = {'First';'Second'};
            ndi.nansen.metatable.merge(seed, 'Subject');

            change = seed(:, {'SubjectIdentifier','BiologicalSex'});
            change.BiologicalSex(:) = {'Female'};
            mt = ndi.nansen.metatable.edit(change, 'Subject');

            testCase.verifyEqual(mt.entries.BiologicalSex, {'Female';'Female'});
            testCase.verifyEqual(mt.entries.SessionName, {'First';'Second'});
        end
    end

    methods (Access = private)
        function tbl = buildSubjectTable(testCase, nRows, sex) %#ok<INUSD>
            ids = ndi.nansen.fun.getIdentifier( ...
                table((1:nRows)', 'VariableNames', {'N'}), 'Subject');
            tbl = table(ids, repmat({sex},nRows,1), ...
                'VariableNames', {'SubjectIdentifier','BiologicalSex'});
        end
    end
end
