/*
 * fn_PIMSSaveAddons.sqf
 *
 * Server-side function that receives a player's addon list from the
 * client and passes it to the C# extension for asynchronous DB storage.
 * The extension returns immediately — no server blocking.
 *
 * Parameters:
 *   _playerUid   - Player's Steam UID
 *   _modPrefixes - Array of addon prefix strings
 */

if (!isServer) exitWith {};

params [["_playerUid", ""], ["_modPrefixes", []]];

if (_playerUid == "" || count _modPrefixes == 0) exitWith {};

// Join into comma-separated string for the extension
private _modList = _modPrefixes joinString ",";

// Fire-and-forget: extension returns "" immediately, saves in background
"PIMS-Ext" callExtension format ["saveplayeraddons|%1|%2", _playerUid, _modList];
