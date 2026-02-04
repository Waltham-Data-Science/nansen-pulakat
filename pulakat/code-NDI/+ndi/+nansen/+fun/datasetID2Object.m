function [dataset] = datasetID2Object(datasetID)
%GETDATASETOBJECT Summary of this function goes here
%   Detailed explanation goes here

datasetStruct = load('dataset_master_metatable.mat','MetaTableEntries');
datasetTable = datasetStruct.MetaTableEntries;
ind = strcmp(datasetTable.DatasetIdentifier,datasetID);
dataset = ndi.dataset.dir(datasetTable.DatasetPath{ind});

end

