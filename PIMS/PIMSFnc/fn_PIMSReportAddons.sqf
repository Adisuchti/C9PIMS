/*
 * fn_PIMSReportAddons.sqf
 *
 * Client-side function called by the server's challenge-response flow.
 * Receives a nonce from the server, gathers the local addon list,
 * kicks off async DLL signing (PBO scanning + hashing runs in background),
 * polls until ready, reads the enhanced payload in chunks,
 * and sends everything to the server for verification.
 *
 * The entire function is spawned to avoid blocking the game.
 * All DLL work (PBO scanning, hashing, signing) runs in a background thread.
 * If PBO hashing fails, the raw prefix list is still uploaded.
 *
 * Parameters:
 *   _playerUid - Player's Steam UID
 *   _nonce     - Cryptographic nonce from the server DLL
 */

params [["_playerUid", ""]];

// Only run on clients (which have an interface) or if explicitly called by the server for itself
if (!hasInterface && _playerUid != "server") exitWith {};

if (_playerUid == "") exitWith {};

// Spawn the entire flow so nothing blocks the game
[_playerUid] spawn {
    params ["_playerUid"];

    diag_log format ["PIMS DEBUG: fn_PIMSReportAddons started for player %1", _playerUid];

    // Step 1: Gather all loaded addon information
    private _addons = allAddonsInfo;
    diag_log format ["PIMS DEBUG: allAddonsInfo returned %1 entries", count _addons];

    // Build combined prefix:hash entries (colon separator avoids DLL pipe conflicts)
    private _combinedAddons = [];
    {
        private _prefix = _x select 0;
        private _hash = _x select 4;
        _combinedAddons pushBack (format ["%1:%2", _prefix, _hash]);
    } forEach _addons;

    private _payload = _combinedAddons joinString ",";

    // Step 2: Kick off async enhancing in the DLL
    // Returns "PROCESSING" immediately — PBO scanning + hashing runs in background
    "PIMS-Ext" callExtension format ["enhanceaddons|%1", _payload];

    // Step 3: Poll for result (non-blocking — sleep yields to scheduler)
    private _enhancedReady = false;
    private _timeout = diag_tickTime + 30; // 30s max wait
    waitUntil {
        private _status = "PIMS-Ext" callExtension "getenhancestatus";
        if (_status == "READY") then {
            _enhancedReady = true;
            true
        } else {
            if (diag_tickTime > _timeout) then {
                diag_log "PIMS ERROR: Enhance task timed out";
                true // exit waitUntil
            } else {
                sleep 0.5; // yield to scheduler, check again in 500ms
                false
            };
        };
    };

    if (!_enhancedReady) exitWith {
        diag_log "PIMS ERROR: Enhance result failed, aborting upload";
    };

    // Step 4: Read enhanced payload in chunks (each call is instant — just substring return)
    private _enhancedPayload = "";
    private _offset = 0;
    while {true} do {
        private _chunk = "PIMS-Ext" callExtension format ["getenhancedpayload|%1", _offset];
        if (_chunk == "END" || _chunk == "") exitWith {};
        _enhancedPayload = _enhancedPayload + _chunk;
        _offset = _offset + (count _chunk);
    };

    diag_log format ["PIMS INFO: Addon enhancing complete (%1 chars), sending to server", count _enhancedPayload];

    // Step 5: Send to server — server saves all addon entries
    [_playerUid, _enhancedPayload] remoteExec ["PIMS_fnc_PIMSVerifyAddons", 2];
};
