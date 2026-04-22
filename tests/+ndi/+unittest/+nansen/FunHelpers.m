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

        function datasetID2ObjectLooksUpPath(testCase)
            % datasetID2Object reads DatasetPath from the Dataset
            % metatable and constructs an ndi.dataset.dir from it.
            % ndi.dataset.dir(path) (the single-arg form) opens an
            % existing dataset, so the path must already be a valid
            % NDI dataset on disk — create one here first with the
            % 2-arg constructor, then look it up via datasetID2Object.
            datasetDir = [tempname, '_ds']; mkdir(datasetDir);
            testCase.addTeardown(@rmdir, datasetDir, 's');
            seeded = ndi.dataset.dir('datasetid2object_test', datasetDir); %#ok<NASGU>

            id = 'Dataset-zzz-999';
            tbl = table({id}, {'unit-test-dataset'}, {datasetDir}, ...
                'VariableNames', {'DatasetIdentifier','DatasetName','DatasetPath'});
            ndi.nansen.metatable.merge(tbl, 'Dataset');

            ds = ndi.nansen.fun.datasetID2Object(id);
            testCase.verifyClass(ds, 'ndi.dataset.dir');
            testCase.verifyEqual(ds.path, datasetDir);
        end
    end
end
