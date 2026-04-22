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

        % Note: datasetID2Object requires ndi.dataset.dir to open a
        % valid NDI dataset on disk, which in turn depends on ndi_install
        % having run to register internal dependencies. That's not
        % feasible in the current CI environment (ndi_install fails on
        % openMINDS's own startup.m), so the lookup is exercised
        % end-to-end via the cloud-tests job instead.
    end
end
