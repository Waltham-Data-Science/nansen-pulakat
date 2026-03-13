classdef NumFiles < nansen.metadata.abstract.TableVariable
%NUMFILES Definition for table variable
%   Detailed explanation goes here
%
%   See also nansen.metadata.abstract.TableVariable

    properties (Constant)
        IS_EDITABLE = false
        DEFAULT_VALUE = 0
    end

    methods
        function obj = NumFiles(varargin)
            obj@nansen.metadata.abstract.TableVariable(varargin{:});
        end
    end

    methods (Static)
        function value = update(subjectObject)

            % Initialize output value with the default value.
            value = eval([mfilename('class'),'.DEFAULT_VALUE']);

            % Return default value if no input is given (used during config).
            if nargin < 1; return; end

            % Get file table
            project = nansen.getCurrentProject;
            fileTable = project.MetaTableCatalog.getMetaTable('File');
            files = fileTable.entries;

            if isempty(files)
                return
            end

            % Find # of files with matching subject id
            ind = strcmp(files.SubjectIdentifier,subjectObject.SubjectIdentifier);
            uniqueFiles = files.FileIdentifier(ind);
            value = numel(uniqueFiles);
        end
    end
end