classdef SpeciesOntology < nansen.metadata.abstract.TableVariable
%SPECIESONTOLOGY Definition for table variable
%   Detailed explanation goes here
%
%   See also nansen.metadata.abstract.TableVariable
    
    properties (Constant)
        IS_EDITABLE = false
        DEFAULT_VALUE = {'N/A'}
    end
    
    methods
        function obj = SpeciesOntology(varargin)
            obj@nansen.metadata.abstract.TableVariable(varargin{:});
        end
    end

    methods (Static)
        function value = update(obj)

            % Initialize output value with the default value.
            className = mfilename('class');
            classParts = strsplit(className,'.');
            variableName = classParts{end};
            value = eval([className,'.DEFAULT_VALUE']);

            % Return default value if no input is given (used during config).
            if nargin < 1; return; end

            % Get subject table
            project = nansen.getCurrentProject;
            subjectTable = project.MetaTableCatalog.getMetaTable('Subject');
            subjects = subjectTable.entries;

            if isempty(subjects)
                return
            end

            % Find unique values with matching session id
            ind = strcmp(subjects.SessionIdentifier,obj.SessionIdentifier);
            defaultValue = eval(strjoin([classParts(1:end-2),'subject',...
                variableName,'DEFAULT_VALUE'],'.'));
            uniqueValues = setdiff(subjects.(variableName)(ind),defaultValue);
            if isempty(uniqueValues)
                return
            else
                value = strjoin(uniqueValues,',');
            end
        end
    end
end
