classdef DataTypeName < nansen.metadata.abstract.TableVariable
%DATATYPENAME Definition for table variable
%   Detailed explanation goes here
%
%   See also nansen.metadata.abstract.TableVariable
    
    properties (Constant)
        IS_EDITABLE = false
        DEFAULT_VALUE = {'N/A'}
    end
    
    methods
        function obj = DataTypeName(varargin)
            obj@nansen.metadata.abstract.TableVariable(varargin{:});
        end
    end
end
