function [dataset] = datasetID2Object(datasetID)
%DATASETID2OBJECT Retrieves an NDI dataset object from its identifier.
%
%   This function looks up the dataset identifier in the master metatable
%   to find its local path and returns the corresponding NDI dataset object.
%
%   Inputs:
%       datasetID (char or string): The unique identifier of the dataset.
%
%   Outputs:
%       dataset (ndi.dataset.dir): The NDI dataset object.

datasetStruct = load('dataset_master_metatable.mat','MetaTableEntries');
datasetTable = datasetStruct.MetaTableEntries;
ind = strcmp(datasetTable.DatasetIdentifier,datasetID);
dataset = ndi.dataset.dir(datasetTable.DatasetPath{ind});

end

