/*
 * PIMS Check Version Function
 * Called on SERVER by client to report their version
 * Compares client version with server version and warns if mismatch
 * 
 * Parameters:
 *   _playerUid     - Player UID who is reporting version
 *   _clientVersion - Client's PIMS version string
 */

params [["_playerUid", ""], ["_clientVersion", ""]];

if (!isServer) exitWith {};

// Get server version from config - read versionStr (not version, which Arma binarizes as a number)
private _serverVersion = getText (configFile >> "CfgPatches" >> "PIMS_patches" >> "versionStr");

if (_serverVersion == "") then {
	_serverVersion = "UNKNOWN";
};

// Get player name for the message
private _player = PIMS_PlayerUIDMap getOrDefault [_playerUid, objNull];
private _playerName = if (!isNull _player) then { name _player } else { "Unknown Player" };

// Compare versions
if (_clientVersion != _serverVersion) then {
	// Version mismatch - warn all players
	private _warningMsg = format [
		"PIMS WARNING: Player %1 has version mismatch! Client: %2, Server: %3",
		_playerName,
		_clientVersion,
		_serverVersion
	];
	
	// Broadcast to all players
	_warningMsg remoteExec ["systemChat", 0];
	
	// Also log to server RPT
	diag_log _warningMsg;
} else {
	// Version match - log success (optional, can be removed for less spam)
	diag_log format ["PIMS INFO: Player %1 version check passed (v%2)", _playerName, _clientVersion];
};
