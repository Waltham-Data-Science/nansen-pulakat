function [dataTable] = data(session,documentID)
%DATA Summary of this function goes here
%   Detailed explanation goes here

% Input argument validation
arguments
    session {mustBeA(session,{'ndi.session.dir'})}
    documentID {mustBeText} = '';
end

% Permanently remove document(s) from the database
session.database_rm(documentID);

% Update data table
dataTable = pulakat.import.data.tableFromSession(session);

end

