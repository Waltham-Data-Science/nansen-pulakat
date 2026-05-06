classdef FunHelpers < ndi.unittest.nansen.ProjectTestCase
%FUNHELPERS Unit tests for the project-dependent +fun/ helpers.
%
%   Covers the helpers that look up values in a Nansen project's
%   metatable — seeded via metatable.merge. Each test stands up a
%   Dataset or Subject metatable with one or two synthetic rows and
%   then exercises the helper.

    methods (Test)
        function getMetaTableValueReturnsEntryField(testCase)
            % Seed Subject metatable with a known row, then look up one
            % of its fields.
            id = 'Subject-abc-001';
            tbl = table({id}, {'Male'}, {'TestStrainA'}, ...
                'VariableNames', {'SubjectIdentifier','BiologicalSex','Strain'});
            ndi.nansen.metatable.merge(tbl, 'Subject');

            value = ndi.nansen.fun.getMetaTableValue( ...
                'Subject', 'BiologicalSex', id);
            testCase.verifyEqual(value, {'Male'});

            value2 = ndi.nansen.fun.getMetaTableValue( ...
                'Subject', 'Strain', id);
            testCase.verifyEqual(value2, {'TestStrainA'});
        end

        function getMetaTableValueAcceptsStringInputs(testCase)
            id = 'Subject-def-002';
            tbl = table({id}, {'Female'}, ...
                'VariableNames', {'SubjectIdentifier','BiologicalSex'});
            ndi.nansen.metatable.merge(tbl, 'Subject');

            value = ndi.nansen.fun.getMetaTableValue( ...
                "Subject", "BiologicalSex", string(id));
            testCase.verifyEqual(value, {'Female'});
        end

        function getMetaTableValueReturnsEmptyOnMissingTable(testCase)
            % addMissingVarsToMetaTable triggers each variable's update
            % during the first merge of a new metatable, so a Session
            % var that looks up Subject data fires before the Subject
            % metatable exists. Silently returning '' keeps the
            % cell-typed assignment well-formed and avoids the warning
            % storm; a later updateAll pass fills in real values.
            value = ndi.nansen.fun.getMetaTableValue( ...
                'Subject', 'BiologicalSex', 'no-such-id');
            testCase.verifyEqual(value, '');
        end

        function listUniqueReturnsDefaultOnMissingTable(testCase)
            value = ndi.nansen.fun.listUniqueMetaTableValues( ...
                'pulakat.tablevariable.session.BiologicalSexName', ...
                'Subject', struct('SubjectIdentifier', 'no-such-id'));
            testCase.verifyEqual(value, ...
                pulakat.tablevariable.session.BiologicalSexName.DEFAULT_VALUE);
        end

        function countUniqueReturnsDefaultOnMissingTable(testCase)
            value = ndi.nansen.fun.countUniqueMetaTableValues( ...
                'pulakat.tablevariable.session.NumFiles', ...
                'File', struct('SessionIdentifier', 'no-such-id'));
            testCase.verifyEqual(value, ...
                pulakat.tablevariable.session.NumFiles.DEFAULT_VALUE);
        end

        function isAutoColumnReadsFlag(testCase)
            % Mixed auto/non-auto entries — caller should get one
            % logical per entry matching the flag.
            entries = struct( ...
                'value', {'A','B','C'}, ...
                'name',  {'A','B','C'}, ...
                'auto',  {false, true, false});
            mask = ndi.nansen.fun.isAutoColumn(entries);
            testCase.verifyEqual(mask, [false, true, false]);
        end

        function isAutoColumnDefaultsFalseWhenFieldMissing(testCase)
            % project_info.json files predating the auto flag don't
            % have it; helpers must default to "not auto" so existing
            % configs continue to work.
            entries = struct('value', {'A','B'}, 'name', {'A','B'});
            mask = ndi.nansen.fun.isAutoColumn(entries);
            testCase.verifyEqual(mask, [false, false]);
        end

        % Note: datasetID2Object requires ndi.dataset.dir to open a
        % valid NDI dataset on disk, which in turn depends on ndi_install
        % having run to register internal dependencies. That's not
        % feasible in the current CI environment (ndi_install fails on
        % openMINDS's own startup.m), so the lookup is exercised
        % end-to-end via the cloud-tests job instead.
    end
end
