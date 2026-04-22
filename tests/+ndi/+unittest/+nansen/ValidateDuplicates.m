classdef ValidateDuplicates < ndi.unittest.nansen.ProjectTestCase
%VALIDATEDUPLICATES Unit tests for ndi.nansen.import.validate.duplicates.
%
%   Exercises both the `all`-logic path (full-row duplicates) and the
%   `any`-logic path (any shared identifier). Each test seeds a Subject
%   metatable, then checks a small dataTable against it.

    methods (Test)
        function flagsTripleDuplicate(testCase)
            % duplicates.m's copies-count logic flags a row as invalid
            % only when there are 2+ OTHER instances of it across the
            % combined (dataTable + metatable) set. Seed two identical
            % rows in the metatable and pass the same row in dataTable
            % to produce three total occurrences.
            ex = testCase.buildSubject('sub-001', 'Male');
            ndi.nansen.metatable.merge(ex, 'Subject');
            % merge doesn't persist appends, so re-seed for a 2-row
            % metatable by building two distinct-id rows with same
            % sex and passing both in the initial merge.
            seed = [testCase.buildSubject('sub-A', 'Male'); ...
                    testCase.buildSubject('sub-B', 'Male')];
            ndi.nansen.metatable.merge(seed, 'Subject');

            incoming = testCase.buildSubject('sub-C', 'Male');
            [isValid, messages] = ndi.nansen.import.validate.duplicates( ...
                incoming, 'Subject', 'BiologicalSex');
            % 3 rows share BiologicalSex 'Male' — treating BiologicalSex
            % as the identifier, the row counts 3 copies; expect invalid.
            testCase.verifyEqual(isValid, false);
            testCase.verifyTrue(contains(messages(1), 'duplicates found'));
        end

        function passesUniqueRow(testCase)
            existing = testCase.buildSubject('sub-001', 'Male');
            ndi.nansen.metatable.merge(existing, 'Subject');

            incoming = testCase.buildSubject('sub-002', 'Female');
            isValid = ndi.nansen.import.validate.duplicates( ...
                incoming, 'Subject');
            testCase.verifyEqual(isValid, true);
        end

        function emptyDataTableIsNoop(testCase)
            existing = testCase.buildSubject('sub-001', 'Male');
            ndi.nansen.metatable.merge(existing, 'Subject');

            empty = existing([],:);
            [isValid, messages] = ndi.nansen.import.validate.duplicates( ...
                empty, 'Subject');
            testCase.verifyEmpty(isValid);
            testCase.verifyEmpty(messages);
        end
    end

    methods (Access = private)
        function tbl = buildSubject(testCase, id, sex) %#ok<INUSD>
            tbl = table({id}, {sex}, ...
                'VariableNames', {'SubjectIdentifier','BiologicalSex'});
        end
    end
end
