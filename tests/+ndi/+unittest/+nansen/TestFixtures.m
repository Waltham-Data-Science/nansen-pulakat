classdef TestFixtures
%TESTFIXTURES Synthetic fixtures for nansen-pulakat unit tests.
%
%   Static helpers for writing a synthetic "testlab" project config and
%   associated fixture data to a tempdir, so tests can exercise the
%   codebase's core logic without depending on any real lab's data.
%
%   Typical usage inside a TestClassSetup:
%
%       testCase.FixtureRoot = tempname;
%       mkdir(testCase.FixtureRoot);
%       ndi.unittest.nansen.TestFixtures.installTestlab(testCase.FixtureRoot);
%       addpath(testCase.FixtureRoot);
%       testCase.addTeardown(@() rmpath(testCase.FixtureRoot));
%       testCase.addTeardown(@() rmdir(testCase.FixtureRoot, 's'));
%
%   After that, ndi.nansen.fun.readProjectInfo('testlab') resolves
%   against the synthetic config instead of the shipped Pulakat one.

    properties (Constant)
        % Synthetic animal roster used as CSV fixture content. Deliberately
        % chosen to be obviously fake: sequential integer ids, made-up
        % strain codes, the 'Saline'/'Treatment' treatment group names.
        SyntheticAnimals = table( ...
            (1:5)', ...
            {'CAGE01';'CAGE01';'CAGE02';'CAGE02';'CAGE03'}, ...
            {'T-01-01';'T-01-02';'T-02-03';'T-02-04';'T-03-05'}, ...
            {'Mouse';'Mouse';'Mouse';'Mouse';'Mouse'}, ...
            {'TestStrainA';'TestStrainA';'TestStrainB';'TestStrainB';'TestStrainA'}, ...
            {'Male';'Female';'Male';'Female';'Male'}, ...
            {'Saline';'Treatment';'Saline';'Treatment';'Saline'}, ...
            'VariableNames', ...
            {'Animal','Cage','Label','Species','Strain','BiologicalSex','Treatment'});
    end

    methods (Static)
        function testlabDir = installTestlab(baseDir)
            %INSTALLTESTLAB Write a synthetic +testlab project under baseDir.
            %
            %   Returns the full path to the +testlab directory. The
            %   caller is responsible for addpath(baseDir) and for
            %   cleaning up baseDir when done.
            arguments
                baseDir (1,:) char {mustBeFolder}
            end
            testlabDir = fullfile(baseDir, '+ndi', '+setup', '+conv', '+testlab');
            if ~isfolder(testlabDir)
                mkdir(testlabDir);
            end

            ndi.unittest.nansen.TestFixtures.writeJson( ...
                fullfile(testlabDir, 'project_info.json'), ...
                ndi.unittest.nansen.TestFixtures.projectInfo());

            ndi.unittest.nansen.TestFixtures.writeJson( ...
                fullfile(testlabDir, 'strains.json'), ...
                ndi.unittest.nansen.TestFixtures.strains());

            ndi.unittest.nansen.TestFixtures.writeJson( ...
                fullfile(testlabDir, 'tableDoc_dictionary.json'), ...
                ndi.unittest.nansen.TestFixtures.tableDocDictionary());
        end

        function info = projectInfo()
            %PROJECTINFO Synthetic project_info.json content as a struct.
            info = struct();
            info.name = 'testlab';
            info.URL = 'https://github.com/test-org/testlab';
            info.cloudDatasetID = '00000000000000000000testl';
            info.subjectSuffix = '@testlab.example.com';
            info.subjectFileName = 'animal_roster';
            info.subjectIdentifierFields = {'Animal','Cage'};

            % In the project_info schema, `value` is the column header
            % in the source CSV and `name` is what the column gets
            % renamed to before NDI consumes it. For the synthetic
            % testlab fixture we keep them identical so the CSV and
            % the post-rename table have the same column layout.
            info.subjectFileColumns = [ ...
                makeColumn('Animal',        'Animal',        'ontologyTableRow'); ...
                makeColumn('Cage',          'Cage',          'ontologyTableRow'); ...
                makeColumn('Label',         'Label',         'ontologyTableRow'); ...
                makeColumn('Species',       'Species',       'metadata'); ...
                makeColumn('Strain',        'Strain',        'metadata'); ...
                makeColumn('BiologicalSex', 'BiologicalSex', 'metadata'); ...
                makeColumn('Treatment',     'Treatment',     'ontologyTableRow') ...
            ];

            info.dataFileColumns = [ ...
                makeColumn('DataTypeName',       'DataTypeName',       'metadata'); ...
                makeColumn('ElectronicFileName', 'ElectronicFileName', 'ontologyTableRow') ...
            ];

            info.dataFileTypes = [ ...
                makeDataFileType('imagingFile', {'imaging_'}, ...
                    'EMPTY:testlab_imaging_format', false, false); ...
                makeDataFileType('metadataFile', {'roster'}, ...
                    'EMPTY:testlab_metadata_format', false, false) ...
            ];
        end

        function s = strains()
            %STRAINS Synthetic strains.json content.
            %
            %   Uses NCBITaxon and RRID ontology IDs that the testlab
            %   would conceptually accept. Unit tests that do not
            %   exercise ontology lookup should use testlab strains
            %   without calling ndi.ontology.lookup; tests that DO
            %   exercise documents may need network access.
            s = [ ...
                struct( ...
                    'value',             'TestStrainA', ...
                    'speciesOntology',   'NCBITaxon:10090', ...
                    'strainOntology',    'RRID:IMSR_JAX:000664', ...
                    'aliases',           {{'Strain-A','test_strain_a'}}, ...
                    'geneticStrainType', 'wildtypeStrain'); ...
                struct( ...
                    'value',             'TestStrainB', ...
                    'speciesOntology',   'NCBITaxon:10090', ...
                    'strainOntology',    'RRID:IMSR_JAX:000664', ...
                    'aliases',           {{'Strain-B','test_strain_b'}}, ...
                    'geneticStrainType', 'wildtypeStrain') ...
            ];
        end

        function d = tableDocDictionary()
            %TABLEDOCDICTIONARY Minimal column-to-ontology mapping.
            %
            %   Every column that flows into an ontologyTableRow document
            %   must have an entry. The identifying columns used in
            %   import/documents.m (SubjectIdentifier, ElectronicFileName)
            %   also need entries since import.validate.ontologyTableRow
            %   checks for them explicitly.
            d = struct( ...
                'Animal',             'EMPTY:testlab_animal', ...
                'Cage',               'EMPTY:testlab_cage', ...
                'Label',              'EMPTY:testlab_label', ...
                'Treatment',          'EMPTY:testlab_treatment', ...
                'ElectronicFileName', 'EMPTY:testlab_filename', ...
                'SubjectIdentifier',  'EMPTY:testlab_subject_id');
        end

        function csvPath = writeAnimalMappingCsv(destDir, rows)
            %WRITEANIMALMAPPINGCSV Write an animal-mapping CSV fixture.
            %
            %   destDir: directory to write the CSV into
            %   rows:    optional subset (row indices) of SyntheticAnimals.
            %            Default = all rows.
            %
            %   Returns the path to the written CSV.
            arguments
                destDir (1,:) char {mustBeFolder}
                rows (1,:) double = []
            end
            if isempty(rows)
                tbl = ndi.unittest.nansen.TestFixtures.SyntheticAnimals;
            else
                tbl = ndi.unittest.nansen.TestFixtures.SyntheticAnimals(rows,:);
            end
            csvPath = fullfile(destDir, 'animal_roster.csv');
            writetable(tbl, csvPath);
        end

        function filePath = writeSyntheticDataFile(destDir, baseName)
            %WRITESYNTHETICDATAFILE Create an empty data file with a
            %given base name so import flows can be exercised without
            %real binary payloads.
            arguments
                destDir  (1,:) char {mustBeFolder}
                baseName (1,:) char = 'imaging_testlab_001.bin'
            end
            filePath = fullfile(destDir, baseName);
            fid = fopen(filePath, 'w');
            if fid < 0
                error('ndi:unittest:WriteFailed', ...
                    'Could not create fixture file at %s', filePath);
            end
            fclose(fid);
        end

        function writeJson(filePath, value)
            %WRITEJSON Write a struct/cell to disk as UTF-8 JSON.
            fid = fopen(filePath, 'w');
            if fid < 0
                error('ndi:unittest:WriteFailed', ...
                    'Could not open %s for writing', filePath);
            end
            fwrite(fid, jsonencode(value, 'PrettyPrint', true));
            fclose(fid);
        end
    end
end


function c = makeColumn(name, value, document)
% Tiny factory to keep subjectFileColumns / dataFileColumns rows uniform.
c = struct('name', name, 'value', value, 'document', document);
end


function t = makeDataFileType(name, contains, format, zipFlag, deleteFlag)
% Tiny factory for dataFileTypes rows.
t = struct( ...
    'DataTypeName', name, ...
    'contains',     {contains}, ...
    'format',       format, ...
    'zip',          zipFlag, ...
    'delete',       deleteFlag);
end
