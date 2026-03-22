classdef SubjectLocalIdentifier < nansen.metadata.abstract.TableVariable & nansen.metadata.abstract.TableColumnFormatter
%SUBJECTLOCALIDENTIFIER Definition for table variable
%   Detailed explanation goes here
%
%   See also nansen.metadata.abstract.TableVariable
    
    properties (Constant)
        IS_EDITABLE = false
        DEFAULT_VALUE = {'N/A'}
    end
    
    methods
        function obj = SubjectLocalIdentifier(varargin)
            obj@nansen.metadata.abstract.TableVariable(varargin{:});
        end

        function value = getCellTooltipString(obj)
            if strcmp(obj.Value,obj.DEFAULT_VALUE{1})
                classParts = strsplit(class(obj),'.');
                variableName = classParts{end};
                value = sprintf('%s will be filled in when NDI documents are created.',variableName);
            else
                value = '';
            end
        end
    end
end
