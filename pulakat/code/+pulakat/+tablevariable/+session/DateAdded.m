classdef DateAdded < nansen.metadata.abstract.TableVariable
%DATEADDED Definition for table variable
%   Detailed explanation goes here
%
%   See also nansen.metadata.abstract.TableVariable

    properties (Constant)
        IS_EDITABLE = false
        DEFAULT_VALUE = NaT('TimeZone','UTC')
    end

    methods
        function obj = DateAdded(varargin)
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

            % Get session document
            query = ndi.query('base.id','exact_string',sessionObject.SessionDocumentIdentifier);
            doc = dataset.database_search(query);

            % Get date added
            datestamp = doc{1}.document_properties.base.datestamp;
            value = datetime(datestamp,'InputFormat', ...
                'yyyy-MM-dd''T''HH:mm:ss.SSS''Z''','TimeZone','UTC');
        end
    end
end