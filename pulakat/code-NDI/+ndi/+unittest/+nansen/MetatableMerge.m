classdef MetatableMerge < ndi.unittest.nansen.ProjectTestCase
%METATABLEMERGE Unit tests for ndi.nansen.metatable.merge.
%
%   Covers the three code paths:
%     - No existing metatable → create one
%     - Existing metatable + new rows → addTable path
%     - Existing metatable + changed rows → forward to metatable.edit
%   Plus the error path for a dataTable with no identifier column.

    methods (Test)
        function createsMetatableOnFirstMerge(testCase)
            tbl = testCase.buildSubjectTable();
            ndi.nansen.metatable.merge(tbl, 'Subject');

            project = nansen.getCurrentProject();
            subj = project.MetaTableCatalog.getMetaTable('Subject');
            testCase.verifyEqual(height(subj.entries), 2);
            testCase.verifyTrue(ismember('SubjectIdentifier', ...
                subj.entries.Properties.VariableNames));
        end

        function appendsNewRowsOnSecondMerge(testCase)
            first = testCase.buildSubjectTable();
            ndi.nansen.metatable.merge(first, 'Subject');

            second = testCase.buildSubjectTable(3);  % 3 subjects
            ndi.nansen.metatable.merge(second, 'Subject');

            project = nansen.getCurrentProject();
            subj = project.MetaTableCatalog.getMetaTable('Subject');
            % All 5 identifiers are unique UUIDs, so the second merge adds
            % 3 new rows to the 2 from the first merge.
            testCase.verifyEqual(height(subj.entries), 5);
        end

        function updatesChangedRows(testCase)
            % Seed a row, then merge the same row with a modified field.
            tbl = testCase.buildSubjectTable(1);
            ndi.nansen.metatable.merge(tbl, 'Subject');
            id = tbl.SubjectIdentifier{1};

            tbl.BiologicalSex{1} = 'Female';
            ndi.nansen.metatable.merge(tbl, 'Subject');

            project = nansen.getCurrentProject();
            subj = project.MetaTableCatalog.getMetaTable('Subject');
            row = subj.entries(strcmp(subj.entries.SubjectIdentifier, id), :);
            testCase.verifyEqual(row.BiologicalSex{1}, 'Female');
        end

        function errorsOnMissingPrimaryIdentifier(testCase)
            % Seed so the metatable exists, then try to merge a table
            % without the primary key column.
            seed = testCase.buildSubjectTable(1);
            ndi.nansen.metatable.merge(seed, 'Subject');

            bad = table({'something'}, 'VariableNames', {'OtherCol'});
            testCase.verifyError( ...
                @() ndi.nansen.metatable.merge(bad, 'Subject'), ...
                'NDI:Nansen:Metatable:Merge:MissingIdentifier');
        end

        function emptyDataTableIsNoop(testCase)
            seed = testCase.buildSubjectTable(1);
            ndi.nansen.metatable.merge(seed, 'Subject');

            empty = seed([],:);
            ndi.nansen.metatable.merge(empty, 'Subject');

            project = nansen.getCurrentProject();
            subj = project.MetaTableCatalog.getMetaTable('Subject');
            testCase.verifyEqual(height(subj.entries), 1);
        end
    end

    methods (Access = private)
        function tbl = buildSubjectTable(testCase, nRows) %#ok<INUSD>
            %BUILDSUBJECTTABLE Synthetic subject table with unique IDs.
            if nargin < 2
                nRows = 2;
            end
            ids  = ndi.nansen.fun.getIdentifier( ...
                table((1:nRows)', 'VariableNames', {'N'}), 'Subject');
            sex  = repmat({'Male'},  nRows, 1);
            name = arrayfun(@(i) sprintf('Subject %d', i), ...
                (1:nRows)', 'UniformOutput', false);
            tbl = table(ids, sex, name, ...
                'VariableNames', {'SubjectIdentifier','BiologicalSex','SessionName'});
        end
    end
end
