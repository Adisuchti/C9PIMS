/*
 * fn_PIMSSaveAddons.sqf
 *
 * Server-side function that initiates the challenge-response handshake
 * for addon verification. Generates a cryptographic challenge via the
 * C# DLL and sends it to the client for signing.
 *
 * Parameters:
 *   _playerUid - Player's Steam UID
 *   _owner     - Owner ID of the client machine (from PlayerConnected)
 */

if (!isServer) exitWith {};

params [["_playerUid", ""], ["_owner", -1]];

if (_playerUid == "" || _owner < 0) exitWith {};

// Step 1: Request the client to report its addons
[_playerUid] remoteExec ["PIMS_fnc_PIMSReportAddons", _owner];
