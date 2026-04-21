function refreshAppTable()
%REFRESHAPPTABLE Refresh the Nansen GUI table if the app is open.
%
%   A safe wrapper around nansen.App.updateTable that is a no-op when the
%   Nansen GUI is not running. nansen.App.updateTable calls
%   nansen.App.getInstance which throws if the app is closed, so a direct
%   call from a scripted / headless context fails the caller at the last
%   line of an otherwise-successful operation.
%
%   See also: NANSEN.APP, NANSEN.APP/ISOPEN, NANSEN.APP/UPDATETABLE

if nansen.App.isOpen()
    nansen.App.updateTable;
end

end
