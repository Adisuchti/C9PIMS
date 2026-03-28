/*
 * fn_PIMSReportAddons.sqf
 *
 * Client-side function called by the server on player connect.
 * Gathers all loaded addon prefixes via allAddonsInfo and reports
 * them back to the server for storage in the addon_list DB table.
 *
 * Parameters:
 *   _playerUid - Player's Steam UID
 */

params [["_playerUid", ""]];

if (!hasInterface) exitWith {}; // Only run on clients with interface

// allAddonsInfo returns [[prefix, version, isPatched, modIndex, hash], ...]
private _addons = allAddonsInfo;
private _modPrefixes = _addons apply { _x select 0 };
private _modHashes = _addons apply { _x select 4 };

// create a new list that combines prefixes and hashes for better tracking
private _combinedAddons = [];
{
    private _prefix = _x select 0;
    private _hash = _x select 4;
    private _combinedEntry = format ["%1|%2", _prefix, _hash];
    _combinedAddons pushBack _combinedEntry;
} forEach _addons;

// Send addon list back to server for DB storage
[_playerUid, _combinedAddons] remoteExec ["PIMS_fnc_PIMSSaveAddons", 2];
