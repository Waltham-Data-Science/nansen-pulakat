classdef Cloud < nansen.metadata.abstract.TableVariable
%CLOUD Definition for table variable
%   Detailed explanation goes here
%
%   See also nansen.metadata.abstract.TableVariable
    
    properties (Constant)
        IS_EDITABLE = false
        DEFAULT_VALUE = false
    end
    
    methods
        function obj = Cloud(varargin)
            obj@nansen.metadata.abstract.TableVariable(varargin{:});
        end
    end
end
