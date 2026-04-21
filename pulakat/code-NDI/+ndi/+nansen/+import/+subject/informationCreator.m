classdef informationCreator < ndi.setup.NDIMaker.SubjectInformationCreator
%INFORMATIONCREATOR Creates NDI subject information and openMINDS objects.
%
%   This class implements the 'create' method to generate subject identifiers
%   and openMINDS objects based on the specific metadata structure used in
%   experimental tables.
%
%   Methods:
%      create - Generates subject data from a table row.
%
%   See also: NDI.SETUP.NDIMAKER.SUBJECTINFORMATIONCREATOR

methods
    function [subjectIdentifier, strain, species, biologicalSex] = create(obj, tableRow)
        %CREATE Generates subject data from a table row.
        %
        %   [SUBJECTIDENTIFIER, STRAIN, SPECIES, BIOLOGICALSEX] = CREATE(OBJ, TABLEROW)
        %
        %   This method processes a single table row to generate a unique subject
        %   identifier and corresponding openMINDS objects for the subject's
        %   species, strain, and biological sex.
        %
        %   Inputs:
        %      obj (ndi.nansen.import.subject.informationCreator): The creator instance.
        %      tableRow (table): A single row from a MATLAB table containing
        %         subject metadata.
        %
        %   Outputs:
        %      subjectIdentifier (char): Unique local identifier string.
        %      strain (openminds.core.research.Strain): openMINDS strain object.
        %      species (openminds.controlledterms.Species): openMINDS species object.
        %      biologicalSex (openminds.controlledterms.BiologicalSex): openMINDS sex object.
        %
        %   See also: NDI.SETUP.NDIMAKER.SUBJECTINFORMATIONCREATOR
        arguments
            obj ndi.setup.NDIMaker.SubjectInformationCreator
            tableRow (1,:) table
        end

        % Get project info
        labName = tableRow.LabName; if iscell(labName), labName = labName{1}; end
        projectInfo = ndi.nansen.fun.readProjectInfo(labName);

        % --- Validate required columns ---
        requiredVariableNames = {projectInfo.subjectFileColumns.name};
        missingColumns = setdiff(requiredVariableNames, tableRow.Properties.VariableNames);
        if ~isempty(missingColumns)
            error('ndi:validators:MissingRequiredColumns',...
                ['The subject table for the %s lab is missing required ' ...
                 'column(s): %s.\nExpected columns: %s.'], ...
                labName, strjoin(missingColumns, ', '), ...
                strjoin(requiredVariableNames, ', '));
        end

        % --- Populate openMINDS Objects by calling helper methods ---
        selectedStrainInfo = obj.getStrainInfo(tableRow);
        species = obj.createSpeciesObject(selectedStrainInfo);
        strain = obj.createStrainObject(selectedStrainInfo,species);
        biologicalSex = obj.createBiologicalSexObject(tableRow);
        subjectIdentifier = obj.constructSubjectIdentifier(tableRow,projectInfo);
    end
end % methods

methods (Access = private, Static)
    function selectedStrainInfo = getStrainInfo(tableRow)
        % --- Load strains info ---
        [thisPath, ~, ~] = fileparts(mfilename('fullpath'));
        strainsFile = fullfile(thisPath, 'strains.json');
        strainsInfo = jsondecode(fileread(strainsFile));

        % --- Check if strain name is missing ---
        if isempty(tableRow.StrainName{1})
            error('ndi:createSubjectInformation:MissingStrain', ...
                'The strain name is missing.');
        end

        % --- Find correct strain from name or alias ---
        strainNames = {strainsInfo.value};
        indStrain = strcmp(strainNames, tableRow.StrainName);
        if ~any(indStrain)
            for i = 1:numel(strainsInfo)
                if any(strcmp(strainsInfo(i).aliases, tableRow.StrainName))
                    indStrain(i) = true;
                    break;
                end
            end
        end

        % --- Check that matching strain was found ---
        if ~any(indStrain)
             error('ndi:createSubjectInformation:InvalidStrain',...
                'The strain "%s" was not found in the strains configuration file.', tableRow.StrainName{1});
        end
        selectedStrainInfo = strainsInfo(indStrain);

    end

    function species = createSpeciesObject(selectedStrainInfo)
        % Creates an openMINDS species object
        species = openminds.controlledterms.Species;
        try
            % Look up ontology information
            [ontologyID,name,~,definition,synonyms] = ...
                ndi.ontology.lookup(selectedStrainInfo.speciesOntology);

            % Add species information
            species.name = name;
            species.preferredOntologyIdentifier = ontologyID;
            species.description = definition;
            species.synonym = string(synonyms);
        catch ME
            error('ndi:createSubjectInformation:SpeciesCreationFailed',...
                'Could not create openMINDS Species object: %s', ME.message);
        end
    end

    function strain = createStrainObject(selectedStrainInfo,species)
        % Creates an openMINDS strain object based on the table row data.
        strain = openminds.core.research.Strain;
        try
            % Look up ontology information
            [ontologyID,name,~,definition,synonyms] = ...
                ndi.ontology.lookup(selectedStrainInfo.strainOntology);

            % Add strain information
            strain.name = name;
            strain.ontologyIdentifier = ontologyID;
            strain.description = definition;
            strain.synonym = string(synonyms);
            strain.geneticStrainType = selectedStrainInfo.geneticStrainType;
            strain.species = species;
        catch ME
            error('ndi:createSubjectInformation:StrainCreationFailed',...
                'Could not create openMINDS Strain object: %s', ME.message);
        end
    end

    function biologicalSex = createBiologicalSexObject(tableRow)
        % Creates an openMINDS biological sex object.
        biologicalSex = openminds.controlledterms.BiologicalSex;
        if isempty(tableRow.BiologicalSexName{1})
            error('ndi:createSubjectInformation:BiologicalSexMissing',...
                'The biological sex name is missing.')
        end
        try
            % Look up ontology information
            [ontologyID,name,~,definition,synonyms] = ...
                ndi.ontology.lookup(['PATO:',lower(tableRow.BiologicalSexName{1})]);
            
            biologicalSex.name = name;
            biologicalSex.preferredOntologyIdentifier = ontologyID;
            biologicalSex.description = definition;
            biologicalSex.synonym = string(synonyms);
        catch ME
            error('ndi:createSubjectInformation:BiologicalSexCreationFailed',...
                'Could not create openMINDS BiologicalSex object: %s', ME.message);
        end
    end

    function subjectIdentifier = constructSubjectIdentifier(tableRow,projectInfo)
        % Constructs the subject identifier string.
        subjectIdentifier = NaN;
            
        % Get the subject identifier values
        subjectParts = cellfun(@(f) char(tableRow.(f){1}), ...
            projectInfo.subjectIdentifierFields, 'UniformOutput', false);

        % Check there are no missing parts
        indEmpty = cellfun(@isempty, subjectParts);
        if any(indEmpty)
            error('ndi:createSubjectInformation:MissingSubjectIdentifier',...
                'The following subject identifiers are missing: %s', ...
                strjoin(projectInfo.subjectIdentifierFields(indEmpty),', '));
        end

        try
            % Combine and append the lab-specific suffix
            subjectIdentifier = [strjoin(subjectParts, '_'),projectInfo.subjectSuffix];
        catch ME
            error('ndi:createSubjectInformation:IdentifierCreationFailed',...
                'Could not construct the subject identifier string: %s', ME.message);
        end
    end
end % private static methods
end % classdef