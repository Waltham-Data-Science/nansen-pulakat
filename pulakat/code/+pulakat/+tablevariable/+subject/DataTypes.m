classdef DataTypes < nansen.metadata.abstract.TableVariable
%DATATYPES Definition for table variable
%   Detailed explanation goes here
%
%   See also nansen.metadata.abstract.TableVariable

    properties (Constant)
        IS_EDITABLE = false
        DEFAULT_VALUE = ''
    end

    methods
        function obj = DataTypes(varargin)
            obj@nansen.metadata.abstract.TableVariable(varargin{:});
        end
    end

    methods (Static)
        function value = update(obj)

            % Initialize output value with the default value.
            className = mfilename('class');
            classParts = strsplit(className,'.');
            tableName = classParts{end-1};
            variableName = classParts{end};
            value = eval([className,'.DEFAULT_VALUE']);

            % Return default value if no input is given (used during config).
            if nargin < 1; return; end

            % Get subject table
            project = nansen.getCurrentProject;
            fileTable = project.MetaTableCatalog.getMetaTable('File');
            files = fileTable.entries;

            if isempty(files)
                return
            end

            % Find unique values with matching session id
            ind = strcmp(files.([tableName,'Identifier']),obj.([tableName,'Identifier']));
            defaultValue = eval(strjoin([classParts(1:end-2),'file',...
                variableName,'DEFAULT_VALUE'],'.'));
            uniqueValues = setdiff(files.(variableName)(ind),defaultValue);
            if isempty(uniqueValues)
                return
            else
                value = strjoin(uniqueValues,',');
            end
        end
    end
end
