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

    methods (Static)
        function value = update(obj)

            % Initialize output value with the default value.
            className = mfilename('class');
            classParts = strsplit(className,'.');
            tableName = classParts{end-1}; tableName(1) = upper(tableName(1));
            value = eval([className,'.DEFAULT_VALUE']);

            % Return default value if no input is given (used during config).
            if nargin < 1 || ~isfield(obj,[tableName,'DocumentIdentifier'])
                return;
            end

            % Get dataset
            dataset = ndi.nansen.fun.datasetID2Object(obj.DatasetIdentifier);

            % Add cloud status
            statusTable = ndi.nansen.sync.status(dataset);
            ind = strcmp(statusTable.DocumentIdentifier,obj.([tableName,'DocumentIdentifier']));
            if any(ind)
                value = statusTable.Cloud(ind);
            else
                return
            end
        end
    end
end