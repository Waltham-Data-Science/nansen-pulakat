classdef ExportMetadata < ndi.unittest.nansen.ProjectTestCase
%EXPORTMETADATA Unit tests for ndi.nansen.export.metadata.
%
%   Seeds Subject and File metatables, then exercises the filter
%   combinations (none, SessionIdentifier, SubjectIdentifier) and
%   the SubjectOnly shortcut.

    methods (Test)
        function subjectOnlyReturnsSubjectTable(testCase)
            subj = testCase.buildSubject('subj-001', 'Male');
            ndi.nansen.metatable.merge(subj, 'Subject');

            out = ndi.nansen.export.metadata('SubjectOnly', true);
            testCase.verifyTrue(height(out) >= 1);
            testCase.verifyTrue(ismember('SubjectIdentifier', ...
                out.Properties.VariableNames));
            testCase.verifyFalse(ismember('FileIdentifier', ...
                out.Properties.VariableNames));
        end

        function noFilterReturnsJoinedTable(testCase)
            subj = testCase.buildSubject('subj-001', 'Male');
            ndi.nansen.metatable.merge(subj, 'Subject');
            file = testCase.buildFile('file-001', 'subj-001', 'sess-A');
            ndi.nansen.metatable.merge(file, 'File');

            out = ndi.nansen.export.metadata();
            testCase.verifyTrue(ismember('FileIdentifier', ...
                out.Properties.VariableNames));
            testCase.verifyTrue(ismember('SubjectIdentifier', ...
                out.Properties.VariableNames));
        end

        function sessionFilterNarrowsResults(testCase)
            subj = testCase.buildSubject('subj-001', 'Male');
            ndi.nansen.metatable.merge(subj, 'Subject');
            file1 = testCase.buildFile('file-001', 'subj-001', 'sess-A');
            file2 = testCase.buildFile('file-002', 'subj-001', 'sess-B');
            ndi.nansen.metatable.merge([file1; file2], 'File');

            out = ndi.nansen.export.metadata( ...
                'SessionIdentifier', 'sess-A', ...
                'MetaDataOnly', true);
            testCase.verifyTrue(all(strcmp(out.SessionIdentifier, 'sess-A')));
        end

        function outputColumnsAreSorted(testCase)
            subj = testCase.buildSubject('subj-001', 'Male');
            ndi.nansen.metatable.merge(subj, 'Subject');

            out = ndi.nansen.export.metadata('SubjectOnly', true);
            names = out.Properties.VariableNames;
            testCase.verifyEqual(names, sort(names));
        end
    end

    methods (Access = private)
        function tbl = buildSubject(testCase, id, sex) %#ok<INUSD>
            tbl = table({id}, {sex}, ...
                'VariableNames', {'SubjectIdentifier','BiologicalSex'});
        end

        function tbl = buildFile(testCase, fileId, subjectId, sessionId) %#ok<INUSD>
            tbl = table({fileId}, {subjectId}, {sessionId}, ...
                'VariableNames', {'FileIdentifier','SubjectIdentifier','SessionIdentifier'});
        end
    end
end
