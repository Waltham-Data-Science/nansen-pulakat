classdef GetIdentifier < matlab.unittest.TestCase
%GETIDENTIFIER Unit tests for ndi.nansen.fun.getIdentifier.
%
%   Exercises the UUID format, per-row uniqueness, and the mustBeMember
%   check on the type argument.

    methods (Test)
        function identifierPerRow(testCase)
            tbl = table({'a';'b';'c'},'VariableNames',{'Col'});
            ids = ndi.nansen.fun.getIdentifier(tbl, 'Subject');
            testCase.verifyClass(ids, 'cell');
            testCase.verifySize(ids, [3 1]);
        end

        function identifiersAreUnique(testCase)
            tbl = table((1:100)', 'VariableNames', {'N'});
            ids = ndi.nansen.fun.getIdentifier(tbl, 'File');
            testCase.verifyEqual(numel(unique(ids)), 100, ...
                'Each row should receive a distinct UUID.');
        end

        function typePrefixed(testCase)
            tbl = table({'x'},'VariableNames',{'Col'});
            ids = ndi.nansen.fun.getIdentifier(tbl, 'Dataset');
            testCase.verifyTrue(startsWith(ids{1}, 'Dataset-'), ...
                'Identifier should be prefixed with the type.');
        end

        function uuidLookingShape(testCase)
            tbl = table({'x'},'VariableNames',{'Col'});
            ids = ndi.nansen.fun.getIdentifier(tbl, 'Session');
            % Format: Session-<8-4-4-4-12 hex>
            pattern = '^Session-[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$';
            testCase.verifyNotEmpty(regexp(ids{1}, pattern, 'once'), ...
                'Identifier should be of the form Session-<UUID>.');
        end

        function acceptsAllDocumentedTypes(testCase)
            tbl = table({'x'},'VariableNames',{'Col'});
            for type = ["Subject","File","Session","Dataset"]
                testCase.verifyWarningFree( ...
                    @() ndi.nansen.fun.getIdentifier(tbl, char(type)));
            end
        end

        function rejectsUnknownType(testCase)
            tbl = table({'x'},'VariableNames',{'Col'});
            testCase.verifyError( ...
                @() ndi.nansen.fun.getIdentifier(tbl, 'NotAType'), ...
                'MATLAB:validators:mustBeMember');
        end

        function emptyTableReturnsEmptyCell(testCase)
            tbl = table('Size',[0 1],'VariableTypes',{'cell'}, ...
                'VariableNames',{'Col'});
            ids = ndi.nansen.fun.getIdentifier(tbl, 'Subject');
            testCase.verifyEmpty(ids);
        end
    end
end
