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
            docIDDefault = eval(strjoin([classParts(1:end-1),...
                [tableName,'DocumentIdentifier'],'DEFAULT_VALUE'],'.'));
            docIDValue = varargin{1}.([tableName,'DocumentIdentifier']);
            if ~strcmp(docIDValue,docIDDefault{1})
                value = true;
            end
        end
    end
end
