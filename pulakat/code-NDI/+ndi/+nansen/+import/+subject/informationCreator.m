classdef informationCreator < ndi.setup.NDIMaker.SubjectInformationCreator
% PULAKAT - Creates NDI subject information for the Pulakat Lab.
%
% This class implements the 'create' method to generate subject identifiers
% and openMINDS objects based on the specific metadata structure used in the
% Pulakat lab's experimental tables for Rattus norvegicus.

methods
    function [subjectIdentifier, strain, species, biologicalSex] = create(obj, tableRow)
        % CREATE - Generates subject data from a Pulakat Lab table row.
        %
        %   [SUBJECTIDENTIFIER, STRAIN, SPECIES, BIOLOGICALSEX] = CREATE(OBJ, TABLEROW)
        %
        %   This method processes a single table row to generate a unique subject
        %   identifier and corresponding openMINDS objects for the subject's
        %   species, strain, and biological sex.
        %
        %   Inputs:
        %       obj (ndi.setup.NDIMaker.SubjectInformationCreator) - The instance of this creator class.
        %       tableRow (table) - A single row from a MATLAB table. It must contain the columns
        %                          'Strain', 'SubjectCageIdentifier', and 'SubjectTextIdentifier'.
        %
        %   Outputs:
        %       subjectIdentifier (char) - The unique local identifier string for the subject.
        %                                  Returns NaN on failure.
        %       strain (openminds.core.research.Strain) - The corresponding openMINDS strain object.
        %                                                   Returns NaN on failure.
        %       species (openminds.controlledterms.Species) - The openMINDS species object.
        %                                                       Returns NaN on failure.
        %       biologicalSex (openminds.controlledterms.BiologicalSex) - The openMINDS biological sex object.
        %                                                                   Returns NaN on failure.
        %
        %   See also: ndi.setup.NDIMaker.SubjectInformationCreator
        %
        arguments
            obj ndi.setup.NDIMaker.SubjectInformationCreator
            tableRow (1,:) table
        end

        % Get project info
        projectFile = fullfile('+ndi','+setup','+conv',['+',tableRow.LabName],'project_info.json');
        projectInfo = jsondecode(fileread(projectFile));

        % --- Validate required columns ---
        requiredVariableNames = {projectInfo.subjectFileColumns.name};
        if ~all(ismember(requiredVariableNames, tableRow.Properties.VariableNames))
            error('ndi:validators:MissingRequiredColumns',...
                'The tableRow is missing one or more required columns for the Pulakat subject creator.');
        end

        % --- Load strains info ---
        [thisPath, ~, ~] = fileparts(mfilename('fullpath'));
        strainsFile = fullfile(thisPath, 'strains.json');
        strainsInfo = jsondecode(fileread(strainsFile));

        % --- Find correct strain from name or alias ---
        strainNames = {strainsInfo.value};
        indStrain = strcmp(strainNames, tableRow.Strain);
        if ~any(indStrain)
            for i = 1:numel(strainsInfo)
                if any(strcmp(strainsInfo(i).aliases, tableRow.Strain))
                    indStrain(i) = true;
                    break;
                end
            end
        end

        if ~any(indStrain)
             error('ndi:validators:InvalidStrain',...
                'The strain "%s" was not found in the strains configuration.', tableRow.Strain{1});
        end
        selectedStrainInfo = strainsInfo(indStrain);

        % --- Populate openMINDS Objects by calling helper methods ---
        species = obj.createSpeciesObject(tableRow,selectedStrainInfo);
        strain = obj.createStrainObject(tableRow,species,selectedStrainInfo);
        biologicalSex = obj.createBiologicalSexObject(tableRow);
        subjectIdentifier = obj.constructSubjectIdentifier(tableRow,projectInfo);
    end
end % methods

methods (Access = private, Static)
    function species = createSpeciesObject(tableRow,selectedStrainInfo)
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
            warning('ndi:createSubjectInformation:SpeciesCreationFailed',...
                'Could not create openMINDS Species object: %s', ME.message);
        end
    end

    function strain = createStrainObject(tableRow,species,selectedStrainInfo)
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
            warning('ndi:createSubjectInformation:StrainCreationFailed',...
                'Could not create openMINDS Strain object: %s', ME.message);
        end
    end

    function biologicalSex = createBiologicalSexObject(tableRow)
        % Creates an openMINDS biological sex object.
        biologicalSex = openminds.controlledterms.BiologicalSex;
        try
            % Look up ontology information
            [ontologyID,name,~,definition,synonyms] = ...
                ndi.ontology.lookup(['PATO:',lower(tableRow.BiologicalSex{1})]);
            
            biologicalSex.name = name;
            biologicalSex.preferredOntologyIdentifier = ontologyID;
            biologicalSex.description = definition;
            biologicalSex.synonym = string(synonyms);
        catch ME
            warning('ndi:createSubjectInformation:BiologicalSexCreationFailed',...
                'Could not create openMINDS BiologicalSex object: %s', ME.message);
        end
    end

    function subjectIdentifier = constructSubjectIdentifier(tableRow,projectInfo)
        % Constructs the subject identifier string.
        subjectIdentifier = NaN;
        try
            % Get the subject identifier values
            subjectParts = cellfun(@(f) char(tableRow.(f){1}), ...
                projectInfo.subjectIdentifierFields, 'UniformOutput', false);
            
            % Combine and append the lab-specific suffix
            subjectIdentifier = [strjoin(subjectParts, '_'),projectInfo.subjectSuffix];
        catch ME
            warning('ndi:createSubjectInformation:IdentifierCreationFailed',...
                'Could not construct the subject identifier string: %s', ME.message);
        end
    end
end % private static methods
end % classdef