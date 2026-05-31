classdef Document < nansen.metadata.abstract.TableVariable
%DOCUMENT Definition for table variable
%   Detailed explanation goes here
%
%   See also nansen.metadata.abstract.TableVariable
    
    properties (Constant)
        IS_EDITABLE = false
        DEFAULT_VALUE = false
    end
    
    methods
        function obj = Document(varargin)
            obj@nansen.metadata.abstract.TableVariable(varargin{:});
        end
    end

    methods (Static)
        function value = update(varargin)
            className = mfilename('class');
            value = pulakat.tablevariable.subject.Document.DEFAULT_VALUE;
            if nargin < 1
                return
            end
            classParts = strsplit(className,'.');
            tableName = classParts{end-1}; tableName(1) = upper(tableName(1));
            docIDField = [tableName,'DocumentIdentifier'];

            % An un-documented row leaves value at DEFAULT_VALUE. NANSEN
            % hands us partial row shapes during refresh — sometimes the
            % document-identifier field is absent, sometimes it is present
            % but carries NaN (the table default for unpopulated cells).
            % Both cases mean "no document yet"; only fall through to the
            % real comparison when we have a usable identifier.
            if ~isfield(varargin{1}, docIDField); return; end
            docIDValue = varargin{1}.(docIDField);
            if iscell(docIDValue); docIDValue = docIDValue{1}; end
            if isempty(docIDValue) || ...
                    (isnumeric(docIDValue) && all(isnan(docIDValue)))
                return
            end

            docIDDefault = eval(strjoin([classParts(1:end-1),...
                [tableName,'DocumentIdentifier'],'DEFAULT_VALUE'],'.'));
            if ~strcmp(docIDValue,docIDDefault{1})
                value = true;
            end
        end
    end
end
