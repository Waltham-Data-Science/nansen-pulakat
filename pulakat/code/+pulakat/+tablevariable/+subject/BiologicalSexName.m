classdef BiologicalSexName < nansen.metadata.abstract.TableVariable
%BIOLOGICALSEXNAME Definition for table variable
%   Detailed explanation goes here
%
%   See also nansen.metadata.abstract.TableVariable
    
    properties (Constant)
        IS_EDITABLE = false
        DEFAULT_VALUE = {''}
    end
    
    methods
        function obj = BiologicalSexName(varargin)
            obj@nansen.metadata.abstract.TableVariable(varargin{:});
        end
    end

     methods (Static)
        function obj = onCellDoubleClick(obj)
            className = mfilename('class');
            obj = ndi.nansen.fun.editMetaTableCell(className,obj,'Propagate','Session');
        end
    end
end
