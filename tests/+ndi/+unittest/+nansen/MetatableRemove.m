classdef MetatableRemove < ndi.unittest.nansen.ProjectTestCase
%METATABLEREMOVE Unit tests for ndi.nansen.metatable.remove.
%
%   Exercises the happy path (remove a subset of rows), the
%   missing-id-column error, and verifies the short-circuit &&
%   fix in the function's guard condition doesn't break the
%   existing-metatable branch.

    methods (Test)
        function removesOneRow(testCase)
            seed = testCase.buildSubjectTable(3);
            ndi.nansen.metatable.merge(seed, 'Subject');

            toRemove = seed(1,:);
            mt = ndi.nansen.metatable.remove(toRemove, 'Subject');

            testCase.verifyEqual(height(mt.entries), 2);
            testCase.verifyFalse(any(strcmp(mt.entries.SubjectIdentifier, ...
                seed.SubjectIdentifier{1})));
        end

        function removesMultipleRows(testCase)
            seed = testCase.buildSubjectTable(4);
            ndi.nansen.metatable.merge(seed, 'Subject');

            toRemove = seed(1:3,:);
            mt = ndi.nansen.metatable.remove(toRemove, 'Subject');

            testCase.verifyEqual(height(mt.entries), 1);
            testCase.verifyEqual(mt.entries.SubjectIdentifier{1}, ...
                seed.SubjectIdentifier{4});
        end

        function errorsWhenIdColumnMissing(testCase)
            seed = testCase.buildSubjectTable(1);
            ndi.nansen.metatable.merge(seed, 'Subject');

            bad = table({'junk'}, 'VariableNames', {'NotAnId'});
            testCase.verifyError( ...
                @() ndi.nansen.metatable.remove(bad, 'Subject'), ...
                ?MException);
        end
    end

    methods (Access = private)
        function tbl = buildSubjectTable(testCase, nRows) %#ok<INUSD>
            ids = ndi.nansen.fun.getIdentifier( ...
                table((1:nRows)', 'VariableNames', {'N'}), 'Subject');
            tbl = table(ids, repmat({'Male'}, nRows, 1), ...
                'VariableNames', {'SubjectIdentifier','BiologicalSex'});
        end
    end
end
