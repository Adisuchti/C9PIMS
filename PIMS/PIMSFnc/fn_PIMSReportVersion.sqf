/*
 * PIMS Report Version Function
 * Called on CLIENT by server to request the client's mod version
 * Responds back to server with the local version
 * 
 * Parameters:
 *   _playerUid - Player UID requesting version check
 */

params [["_playerUid", ""]];

if (!hasInterface) exitWith {}; // Only run on clients with interface

// Get version from config - this reads the addon's version
private _clientVersion = getText (configFile >> "CfgPatches" >> "PIMS_patches" >> "version");

// If version not found in config, use fallback
if (_clientVersion == "") then {
	_clientVersion = "UNKNOWN";
};

// Report version back to server
[_playerUid, _clientVersion] remoteExec ["PIMS_fnc_PIMSCheckVersion", 2];
