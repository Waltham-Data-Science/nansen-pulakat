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

            % Return if no doc id
            defaultDocID = eval(strjoin([classParts(1:end-1),...
                [tableName,'DocumentIdentifier'],'DEFAULT_VALUE'],'.'));
            if strcmp(obj.([tableName,'DocumentIdentifier']),defaultDocID)
                return;
            end

            % Get dataset
            dataset = ndi.nansen.fun.datasetID2Object(obj.DatasetIdentifier);

            % Get session document
            query = ndi.query('base.id','exact_string',obj.([tableName,'DocumentIdentifier']));
            doc = dataset.database_search(query);

            % Get date added
            datestamp = doc{1}.document_properties.base.datestamp;
            value = datetime(datestamp,'InputFormat', ...
                'yyyy-MM-dd''T''HH:mm:ss.SSS''Z''','TimeZone','UTC');
        end
    end
end