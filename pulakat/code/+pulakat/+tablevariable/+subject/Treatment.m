classdef Treatment < nansen.metadata.abstract.TableVariable
%TREATMENT Definition for table variable
%   Detailed explanation goes here
%
%   See also nansen.metadata.abstract.TableVariable
    
    properties (Constant)
        IS_EDITABLE = false
        DEFAULT_VALUE = {'N/A'}
    end
    
    methods
        function obj = Treatment(varargin)
            obj@nansen.metadata.abstract.TableVariable(varargin{:});
        end
    end

     methods (Static)
        function subjectObject = onCellDoubleClick(subjectObject)
            % Get table type and variable name
            classParts = strsplit(mfilename('class'),'.');
            tableName = classParts{end-1}; tableName(1) = upper(tableName(1));
            variableName = classParts{end};

            % Check that the NDI document has not already been created
            defaultDocID = eval(strjoin([classParts(1:end-1),...
                     [tableName,'DocumentIdentifier'],'DEFAULT_VALUE'],'.'));
            if strcmp(subjectObject.([tableName,'DocumentIdentifier']),defaultDocID)

                % Query user for updated value
                defaultValue = cellstr(subjectObject.(variableName));
                if isempty(defaultValue)
                    defaultValue = {''};
                end
                newValue = inputdlg(variableName,'Input',1,defaultValue);

                if ~isequal(newValue,defaultValue)
                    % Get metatable
                    project = nansen.getCurrentProject;
                    metaTable = project.MetaTableCatalog.getMetaTable(tableName);

                    % Replace value
                    rowInd = metaTable.getIndexById(subjectObject.(metaTable.MetaTableIdVarname));
                    metaTable.editEntries(rowInd,variableName,newValue);

                    % Save and update table
                    metaTable.save();
                    nansen.App.updateTable;
                end
            else
                message = sprintf('This %s has already been added to the database and cannot be edited.',tableName);
                warndlg(message);
            end
        end
    end
end
