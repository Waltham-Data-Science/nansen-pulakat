classdef NumSubjects < nansen.metadata.abstract.TableVariable
%NUMSUBJECTS Definition for table variable
%   Detailed explanation goes here
%
%   See also nansen.metadata.abstract.TableVariable

    properties (Constant)
        IS_EDITABLE = false
        DEFAULT_VALUE = 0
    end

    methods
        function obj = NumSubjects(varargin)
            obj@nansen.metadata.abstract.TableVariable(varargin{:});
        end
    end

    methods (Static)
        function value = update(sessionObject)

            % Initialize output value with the default value.
            value = eval([mfilename('class'),'.DEFAULT_VALUE']);

            % Return default value if no input is given (used during config).
            if nargin < 1; return; end

            % Get subject table
            project = nansen.getCurrentProject;
            subjectTable = project.MetaTableCatalog.getMetaTable('Subject');
            subjects = subjectTable.entries;

            if isempty(subjects)
                return
            end

            % Find # subjects with matching session id
            ind = strcmp(subjects.SessionIdentifier,sessionObject.SessionIdentifier);
            uniqueSubjects = subjects.SubjectIdentifier(ind);
            value = numel(uniqueSubjects);

        end
    end
end
