classdef ValidateFileHasAllSubjects < ndi.unittest.nansen.ProjectTestCase
%VALIDATEFILEHASALLSUBJECTS Tests for import.validate.fileHasAllSubjects.
%
%   Verifies the rule that a file is only "complete" once every
%   subject referenced by it has a documented SubjectDocumentIdentifier
%   (not 'N/A' and not empty).

    methods (Test)
        function allSubjectsDocumentedIsValid(testCase)
            tbl = table( ...
                {'imaging_001.bin'; 'imaging_002.bin'}, ...
                {'imagingFile'; 'imagingFile'}, ...
                {'sess-01'; 'sess-01'}, ...
                {'subj-doc-A'; 'subj-doc-B'}, ...
                'VariableNames', {'ElectronicFileName','DataTypeName', ...
                    'SessionIdentifier','SubjectDocumentIdentifier'});
            ndi.nansen.metatable.merge(tbl, 'File');

            isValid = ndi.nansen.import.validate.fileHasAllSubjects(tbl);
            testCase.verifyEqual(isValid, [true; true]);
        end

        function missingSubjectIsInvalid(testCase)
            tbl = table( ...
                {'imaging_001.bin'}, {'imagingFile'}, {'sess-01'}, {'N/A'}, ...
                'VariableNames', {'ElectronicFileName','DataTypeName', ...
                    'SessionIdentifier','SubjectDocumentIdentifier'});
            ndi.nansen.metatable.merge(tbl, 'File');

            [isValid, msgs] = ndi.nansen.import.validate.fileHasAllSubjects(tbl);
            testCase.verifyEqual(isValid, false);
            testCase.verifyTrue(contains(msgs(1), 'missing subject'));
        end

        function emptyDataTableShortCircuits(testCase)
            existing = table( ...
                {'imaging_001.bin'}, {'imagingFile'}, {'sess-01'}, {'subj-doc-A'}, ...
                'VariableNames', {'ElectronicFileName','DataTypeName', ...
                    'SessionIdentifier','SubjectDocumentIdentifier'});
            ndi.nansen.metatable.merge(existing, 'File');

            empty = existing([],:);
            [isValid, msgs] = ndi.nansen.import.validate.fileHasAllSubjects(empty);
            testCase.verifyEmpty(isValid);
            testCase.verifyEmpty(msgs);
        end
    end
end
