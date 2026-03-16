classdef SpeciesName < nansen.metadata.abstract.TableVariable & nansen.metadata.abstract.TableColumnFormatter
%SPECIESNAME Definition for table variable
%   Detailed explanation goes here
%
%   See also nansen.metadata.abstract.TableVariable
    
    properties (Constant)
        IS_EDITABLE = false
        DEFAULT_VALUE = {'N/A'}
    end
    
    methods
        function obj = SpeciesName(varargin)
            obj@nansen.metadata.abstract.TableVariable(varargin{:});
        end
    end

    methods (Static)
        function obj = onCellDoubleClick(obj)
            % Get table type and variable name
            classParts = strsplit(mfilename('class'),'.');
            tableName = classParts{end-1}; tableName(1) = upper(tableName(1));
            variableName = classParts{end};

            % Check that the NDI document has not already been created
            defaultDocID = eval(strjoin([classParts(1:end-1),...
                [tableName,'DocumentIdentifier'],'DEFAULT_VALUE'],'.'));
            if strcmp(obj.([tableName,'DocumentIdentifier']),defaultDocID)

                % Query user for updated value
                defaultValue = cellstr(obj.(variableName));
                if isempty(defaultValue)
                    defaultValue = {''};
                end
                newValue = inputdlg(variableName,'Input',1,defaultValue);

                if ~isequal(newValue,defaultValue)
                    % Get metatable
                    project = nansen.getCurrentProject;
                    metaTable = project.MetaTableCatalog.getMetaTable(tableName);

                    % Replace value
                    rowInd = metaTable.getIndexById(obj.(metaTable.MetaTableIdVarname));
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

        function str = getCellTooltipString(obj)
        %getCellTooltipString Get character vector to display as tooltip

            str = 'testing';
            % datalocStruct = obj.Value;
            % 
            % if isa(datalocStruct, 'cell')
            %     datalocStruct = datalocStruct{1};
            % end
            % 
            % if isempty(datalocStruct)
            %     str = '';
            % 
            % else
            %     % Create a html formatted string from values in struct
            %     str = cell(size(datalocStruct));
            %     strtab = '&nbsp;&nbsp;&nbsp;&nbsp;';
            % 
            %     for i = 1:numel(datalocStruct)
            %         str{i} = sprintf(['%s (%s)',...
            %             '<br/>%s Root Number: %d', ...
            %             '<br/>%s DiskName: %s', ...
            %             '<br/>%s RootPath: %s', ...
            %             '<br/>%s Folder: %s'], ...
            %             datalocStruct(i).Name, char( datalocStruct(i).Type ), ...
            %             strtab, datalocStruct(i).RootIdx,...
            %             strtab, datalocStruct(i).Diskname, ...
            %             strtab, datalocStruct(i).RootPath, ...
            %             strtab, datalocStruct(i).Subfolders);
            %     end
            % 
            %     str = strjoin(str, '<br /><br />'); % Add blank line between data locations
            %     str = sprintf('<html><div align="left"> %s </div>', str);
            % end
        end
    end
end
