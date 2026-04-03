/*
 * fn_PIMSCheckAudits.sqf
 *
 * Server-side function called on PlayerConnected.
 * Checks the database (via DLL) to see if this player has any pending PBO audits.
 * If so, fires an RPC to the client to begin the audit process.
 *
 * Parameters:
 *   _uid   - Player's Steam UID
 *   _owner - Owner ID of the client machine
 */

if (!isServer) exitWith {};

params [["_uid", ""], ["_owner", -1]];

if (_uid == "" || _uid == "1" || _owner < 0) exitWith {};

// Let the DLL check the audit tables
private _audits = "PIMS-Ext" callExtension format ["checkaudits|%1", _uid];

// "NONE" or "Error" means no audits pending
if (_audits != "" && _audits != "NONE" && (_audits select [0, 5]) != "Error") then {
    diag_log format ["PIMS INFO: Found pending audits for %1: %2. Dispatching request.", _uid, _audits];
    
    // Dispatch the string of prefixes to the specific client
    [_audits] remoteExec ["PIMS_fnc_PIMSClientAudit", _owner];
};
