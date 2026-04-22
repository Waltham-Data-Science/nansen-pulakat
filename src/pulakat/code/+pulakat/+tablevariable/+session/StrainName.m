classdef StrainName < nansen.metadata.abstract.TableVariable
%STRAINNAME Definition for table variable
%   Detailed explanation goes here
%
%   See also nansen.metadata.abstract.TableVariable
    
    properties (Constant)
        IS_EDITABLE = false
        DEFAULT_VALUE = {'N/A'}
    end
    
    methods
        function obj = StrainName(varargin)
            obj@nansen.metadata.abstract.TableVariable(varargin{:});
        end
    end

    methods (Static)
        function value = update(varargin)
            className = mfilename('class');
            dataName = 'Subject';
            value = ndi.nansen.fun.listUniqueMetaTableValues(className,dataName,varargin{:});
        end
    end
end
