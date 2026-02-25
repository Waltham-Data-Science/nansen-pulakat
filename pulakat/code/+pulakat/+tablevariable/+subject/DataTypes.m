classdef DataTypes < nansen.metadata.abstract.TableVariable
%DATATYPES Definition for table variable
%   Detailed explanation goes here
%
%   See also nansen.metadata.abstract.TableVariable

    properties (Constant)
        IS_EDITABLE = false
        DEFAULT_VALUE = ''
    end

    methods
        function obj = DataTypes(varargin)
            obj@nansen.metadata.abstract.TableVariable(varargin{:});
        end
    end
end
