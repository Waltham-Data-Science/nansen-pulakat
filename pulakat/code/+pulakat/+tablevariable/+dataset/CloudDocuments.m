classdef CloudDocuments < nansen.metadata.abstract.TableVariable
%CLOUDDOCUMENTS Definition for table variable
%   Detailed explanation goes here
%
%   See also nansen.metadata.abstract.TableVariable

    properties (Constant)
        IS_EDITABLE = false
        DEFAULT_VALUE = NaN
    end

    methods
        function obj = CloudDocuments(varargin)
            obj@nansen.metadata.abstract.TableVariable(varargin{:});
        end
    end

    methods (Static)
        function value = update(datasetObject)

            % Initialize output value with the default value.
            value = eval([mfilename('class'),'.DEFAULT_VALUE']);

            % Return default value if no input is given (used during config).
            if nargin < 1; return; end

            % Test NDI-Cloud connection
            connected = ndi.cloud.testLogin();
            if ~connected
                ndi.cloud.uilogin(true);
            end

            % Get dataset metadata
            [success,datasetInfo] = ndi.cloud.api.datasets.getDataset(datasetObject.DatasetCloudIdentifier);
            if ~success
                error('Could not retrieve dataset information from cloud: %s',datasetInfo.error);
            end

            % Get # of cloud documents
            value = datasetInfo.documentCount;

        end
    end
end