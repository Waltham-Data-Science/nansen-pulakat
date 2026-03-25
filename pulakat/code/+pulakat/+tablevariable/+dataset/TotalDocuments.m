classdef TotalDocuments < nansen.metadata.abstract.TableVariable
%TOTALDOCUMENTS Definition for table variable
%   Detailed explanation goes here
%
%   See also nansen.metadata.abstract.TableVariable

    properties (Constant)
        IS_EDITABLE = false
        DEFAULT_VALUE = NaN
    end

    methods
        function obj = TotalDocuments(varargin)
            obj@nansen.metadata.abstract.TableVariable(varargin{:});
        end
    end

    methods (Static)
        function value = update(datasetObject)

            % Initialize output value with the default value.
            value = eval([mfilename('class'),'.DEFAULT_VALUE']);

            % Return default value if no input is given (used during config).
            if nargin < 1; return; end

            % Get dataset
            dataset = ndi.nansen.fun.datasetID2Object(datasetObject.DatasetIdentifier);

            % Get # of documents
            [~, localDocumentIds] = ndi.cloud.sync.internal.listLocalDocuments(dataset);
            value = numel(localDocumentIds);

        end
    end
end
