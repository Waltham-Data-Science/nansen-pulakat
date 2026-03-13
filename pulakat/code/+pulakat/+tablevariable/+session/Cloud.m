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
        function value = update(sessionObject)

            % Initialize output value with the default value.
            value = eval([mfilename('class'),'.DEFAULT_VALUE']);

            % Return default value if no input is given (used during config).
            if nargin < 1; return; end

            % Get dataset
            dataset = ndi.nansen.fun.datasetID2Object(sessionObject.DatasetIdentifier);

            % Add cloud status
            statusTable = ndi.nansen.sync.status(dataset);
            ind = strcmp(statusTable.DocumentIdentifier,sessionObject.SessionDocumentIdentifier);
            value = statusTable.Cloud(ind);

        end
    end
end