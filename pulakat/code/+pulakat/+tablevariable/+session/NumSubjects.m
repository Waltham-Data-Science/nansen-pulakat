classdef NumSubjects < nansen.metadata.abstract.TableVariable
%NUMSUBJECTS Definition for table variable
%   Detailed explanation goes here
%
%   See also nansen.metadata.abstract.TableVariable

    properties (Constant)
        IS_EDITABLE = false
        DEFAULT_VALUE = 0
    end

    methods
        function obj = NumSubjects(varargin)
            obj@nansen.metadata.abstract.TableVariable(varargin{:});
        end
    end

    methods (Static)
        function value = update(obj)
            className = mfilename('class');
            dataName = 'Subject';
            value = ndi.nansen.fun.countMetaTableValues(className,obj,dataName);
        end
    end
end
