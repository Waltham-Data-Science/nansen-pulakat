classdef SpeciesName < nansen.metadata.abstract.TableVariable & nansen.metadata.abstract.TableColumnFormatter
%SPECIESNAME Definition for table variable
%   Detailed explanation goes here
%
%   See also nansen.metadata.abstract.TableVariable
    
    properties (Constant)
        IS_EDITABLE = false
        DEFAULT_VALUE = {'N/A'}
    end
    
    methods
        function obj = SpeciesName(varargin)
            obj@nansen.metadata.abstract.TableVariable(varargin{:});
        end

        function value = getCellDisplayString(obj)
            value = {obj.Value};
        end

        function value = getCellTooltipString(obj)
            if strcmp(obj.Value,obj.DEFAULT_VALUE{1})
                classParts = strsplit(class(obj),'.');
                variableName = classParts{end};
                value = sprintf('%s will be automatically filled in when NDI documents are created.',variableName);
            else
                value = '';
            end
        end
    end
end
