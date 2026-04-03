/*
 * fn_PIMSSaveAuditResults.sqf
 *
 * Receives the massive file tree payload from a Client Audit,
 * passes it into the async C# Database Manager to be sliced and inserted.
 * 
 * Parameters:
 *   _playerUid - Player's Steam UID
 *   _payload   - A concatenated string of `prefix||fileTree` using `|||` separators
 */

if (!isServer) exitWith {};

params [["_playerUid", ""], ["_payload", ""]];

if (_playerUid == "" || _payload == "") exitWith {};

// Run the save operation completely in the background via C# Task
"PIMS-Ext" callExtension format ["saveauditresults|%1|%2", _playerUid, _payload];
