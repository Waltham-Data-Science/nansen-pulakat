classdef Treatment < nansen.metadata.abstract.TableVariable
%TREATMENT Definition for table variable
%   Detailed explanation goes here
%
%   See also nansen.metadata.abstract.TableVariable
    
    properties (Constant)
        IS_EDITABLE = false
        DEFAULT_VALUE = {''}
    end
    
    methods
        function obj = Treatment(varargin)
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
