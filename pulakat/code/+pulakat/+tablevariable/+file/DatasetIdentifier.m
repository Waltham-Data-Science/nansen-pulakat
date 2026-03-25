classdef DatasetIdentifier < nansen.metadata.abstract.TableVariable
%DATASETIDENTIFIER Definition for table variable
%   Detailed explanation goes here
%
%   See also nansen.metadata.abstract.TableVariable
    
    properties (Constant)
        IS_EDITABLE = false
        DEFAULT_VALUE = {'N/A'}
    end
    
    methods
        function obj = DatasetIdentifier(varargin)
            obj@nansen.metadata.abstract.TableVariable(varargin{:});
        end
    end

    methods (Static)
        function value = update(varargin)
            className = mfilename('class');
            if nargin < 1
                value = eval([className,'.DEFAULT_VALUE']);
                return
            else
                classParts = strsplit(className,'.');
                dataName = 'Subject';
                variableName = classParts{end};
                obj = varargin{1};
                value = ndi.nansen.fun.getMetaTableValue(dataName,variableName,obj.([dataName,'Identifier']));
            end
        end
    end
end
