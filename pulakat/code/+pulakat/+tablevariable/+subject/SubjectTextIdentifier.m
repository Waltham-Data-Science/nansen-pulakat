classdef SubjectTextIdentifier < nansen.metadata.abstract.TableVariable
%SUBJECTTEXTIDENTIFIER Definition for table variable
%   Detailed explanation goes here
%
%   See also nansen.metadata.abstract.TableVariable
    
    properties (Constant)
        IS_EDITABLE = false
        DEFAULT_VALUE = {''}
    end
    
    methods
        function obj = SubjectTextIdentifier(varargin)
            obj@nansen.metadata.abstract.TableVariable(varargin{:});
        end
    end

     methods (Static)
         function obj = onCellDoubleClick(obj)
            className = mfilename('class');
            obj = ndi.nansen.fun.editMetaTableCell(className,obj,'Propagate','File');
        end
    end
end
