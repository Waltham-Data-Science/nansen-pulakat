classdef MetatableEdit < ndi.unittest.nansen.ProjectTestCase
%METATABLEEDIT Unit tests for ndi.nansen.metatable.edit.
%
%   Verifies the M1a batch-by-column rewrite — specifically that
%   updates land correctly across cell, numeric, and logical column
%   types, and that rows whose values did not change aren't touched.

    methods (Test)
        function editsCellColumn(testCase)
            seed = testCase.buildSubjectTable(3, 'Male');
            ndi.nansen.metatable.merge(seed, 'Subject');

            change = seed;
            change.BiologicalSex(:) = {'Female'};
            ndi.nansen.metatable.edit(change, 'Subject');

            entries = getEntries(testCase);
            testCase.verifyEqual(entries.BiologicalSex, repmat({'Female'},3,1));
        end

        function editsOnlyDifferingRows(testCase)
            seed = testCase.buildSubjectTable(3, 'Male');
            ndi.nansen.metatable.merge(seed, 'Subject');

            change = seed;
            change.BiologicalSex{2} = 'Female';   % only row 2 changes
            ndi.nansen.metatable.edit(change, 'Subject');

            entries = getEntries(testCase);
            testCase.verifyEqual(entries.BiologicalSex, ...
                {'Male';'Female';'Male'});
        end

        function ignoresEmptyAndNAValues(testCase)
            % Edit.m explicitly skips '' and 'N/A' — if a caller passes
            % those they should NOT clobber an existing value.
            seed = testCase.buildSubjectTable(2, 'Male');
            ndi.nansen.metatable.merge(seed, 'Subject');

            change = seed;
            change.BiologicalSex = {''; 'N/A'};
            ndi.nansen.metatable.edit(change, 'Subject');

            entries = getEntries(testCase);
            testCase.verifyEqual(entries.BiologicalSex, {'Male';'Male'});
        end

        function preservesUnchangedColumns(testCase)
            % Sending only SubjectIdentifier + one column should not
            % disturb the other columns.
            seed = testCase.buildSubjectTable(2, 'Male');
            seed.SessionName = {'First';'Second'};
            ndi.nansen.metatable.merge(seed, 'Subject');

            change = seed(:, {'SubjectIdentifier','BiologicalSex'});
            change.BiologicalSex(:) = {'Female'};
            ndi.nansen.metatable.edit(change, 'Subject');

            entries = getEntries(testCase);
            testCase.verifyEqual(entries.BiologicalSex, {'Female';'Female'});
            testCase.verifyEqual(entries.SessionName, {'First';'Second'});
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


function entries = getEntries(testCase)
project = nansen.getCurrentProject();
subj = project.MetaTableCatalog.getMetaTable('Subject');
entries = subj.entries;
testCase.verifyNotEmpty(entries, 'Subject metatable unexpectedly empty.');
end
