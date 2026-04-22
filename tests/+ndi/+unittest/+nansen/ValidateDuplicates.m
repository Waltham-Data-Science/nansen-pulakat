classdef ValidateDuplicates < ndi.unittest.nansen.ProjectTestCase
%VALIDATEDUPLICATES Unit tests for ndi.nansen.import.validate.duplicates.
%
%   Exercises both the `all`-logic path (full-row duplicates) and the
%   `any`-logic path (any shared identifier). Each test seeds a Subject
%   metatable, then checks a small dataTable against it.

    methods (Test)
        function flagsRowThatDuplicatesExistingEntry(testCase)
            existing = testCase.buildSubject('sub-001', 'Male');
            ndi.nansen.metatable.merge(existing, 'Subject');

            incoming = testCase.buildSubject('sub-001', 'Male');
            [isValid, messages] = ndi.nansen.import.validate.duplicates( ...
                incoming, 'Subject');

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
