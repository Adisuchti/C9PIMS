/*
 * fn_PIMSVerifyAddons.sqf
 *
 * Server-side function that receives an enhanced addon payload from a client
 * and submits it to the C# DLL for background database saving.
 * 
 * Parameters:
 *   _playerUid      - Player's Steam UID
 *   _enhancedPayload - The addon payload with all hashes (engine + DLL-computed)
 */

if (!isServer) exitWith {};

params [["_playerUid", ""], ["_enhancedPayload", ""]];

if (_playerUid == "" || _enhancedPayload == "") exitWith {};

// Submit to DLL for async DB logging and addon saving.
"PIMS-Ext" callExtension format ["saveplayeraddons|%1|%2", _playerUid, _enhancedPayload];
