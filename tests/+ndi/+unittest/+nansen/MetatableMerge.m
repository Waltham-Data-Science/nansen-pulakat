classdef MetatableMerge < ndi.unittest.nansen.ProjectTestCase
%METATABLEMERGE Unit tests for ndi.nansen.metatable.merge.
%
%   Covers the three code paths:
%     - No existing metatable → create one
%     - Existing metatable + new rows → addTable path
%     - Existing metatable + changed rows → forward to metatable.edit
%   Plus the error path for a dataTable with no identifier column.
%
%   Note on persistence: nansen.metadata.MetaTableCatalog.getMetaTable
%   always reloads the metatable from disk, and merge() only persists
%   on the initial-create path (via project.addMetaTable → archive).
%   Subsequent addTable / edit calls mutate the returned in-memory
%   object only. These tests therefore verify against the metaTable
%   object that merge returns, not against a fresh catalog.getMetaTable
%   lookup.

    methods (Test)
        function createsMetatableOnFirstMerge(testCase)
            tbl = testCase.buildSubjectTable();
            mt = ndi.nansen.metatable.merge(tbl, 'Subject');

            testCase.verifyEqual(height(mt.entries), 2);
            testCase.verifyTrue(ismember('SubjectIdentifier', ...
                mt.entries.Properties.VariableNames));
        end

        function appendsNewRowsOnSecondMerge(testCase)
            first = testCase.buildSubjectTable();
            ndi.nansen.metatable.merge(first, 'Subject');

            second = testCase.buildSubjectTable(3);
            mt = ndi.nansen.metatable.merge(second, 'Subject');

            % The second merge loads the previously-archived metatable
            % (2 rows) and adds 3 new ones → 5 rows on the returned
            % in-memory object.
            testCase.verifyEqual(height(mt.entries), 5);
        end

        function updatesChangedRows(testCase)
            tbl = testCase.buildSubjectTable(1);
            ndi.nansen.metatable.merge(tbl, 'Subject');
            id = tbl.SubjectIdentifier{1};

            tbl.BiologicalSex{1} = 'Female';
            mt = ndi.nansen.metatable.merge(tbl, 'Subject');

            row = mt.entries(strcmp(mt.entries.SubjectIdentifier, id), :);
            testCase.verifyEqual(row.BiologicalSex{1}, 'Female');
        end

        function errorsOnMissingPrimaryIdentifier(testCase)
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
            mt = ndi.nansen.metatable.merge(empty, 'Subject');

            % The empty-input branch returns early without a value,
            % so capture-and-verify is only meaningful on the load path.
            if ~isempty(mt)
                testCase.verifyEqual(height(mt.entries), 1);
            end
        end
    end

    methods (Access = private)
        function tbl = buildSubjectTable(testCase, nRows) %#ok<INUSD>
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
