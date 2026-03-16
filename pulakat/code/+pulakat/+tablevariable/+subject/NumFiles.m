classdef NumFiles < nansen.metadata.abstract.TableVariable
%NUMFILES Definition for table variable
%   Detailed explanation goes here
%
%   See also nansen.metadata.abstract.TableVariable

    properties (Constant)
        IS_EDITABLE = false
        DEFAULT_VALUE = 0
    end

    methods
        function obj = NumFiles(varargin)
            obj@nansen.metadata.abstract.TableVariable(varargin{:});
        end
    end

    methods (Static)
        function value = update(obj)
            className = mfilename('class');
            dataName = 'File';
            value = ndi.nansen.fun.countUniqueMetaTableValues(className,obj,dataName);
        end
    end
end