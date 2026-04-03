/*
 * fn_PIMSClientAudit.sqf
 *
 * Client-side script spawned by the server's checkaudits loop.
 * Passes the requested mod prefixes to the background C# task,
 * awaits completion, and sends the massive payload back to the server in chunks.
 *
 * Parameters:
 *   _prefixes - Comma-separated list of expected $PBOPREFIX$es to audit.
 */

params [["_prefixes", ""]];

if (_prefixes == "") exitWith {};
if (!hasInterface) exitWith {};

// Background this so it never blocks Arma 3 game loop
[_prefixes] spawn {
    params ["_prefixes"];

    // 1. Kickstart async C# task
    "PIMS-Ext" callExtension format ["runaudit|%1", _prefixes];

    // 2. Poll until "READY"
    private _auditReady = false;
    private _timeout = diag_tickTime + 60; // Max 60 seconds
    
    waitUntil {
        private _status = "PIMS-Ext" callExtension "getauditstatus";
        if (_status == "READY") then {
            _auditReady = true;
            true
        } else {
            if (diag_tickTime > _timeout) then {
                diag_log "PIMS ERROR: Client Audit timed out";
                true // break waiter
            } else {
                sleep 0.5; // Yield half second
                false
            };
        };
    };

    if (!_auditReady) exitWith {
        diag_log "PIMS ERROR: Audit processing failed or timed out.";
    };

    // 3. Harvest chunks
    private _payload = "";
    private _offset = 0;
    while {true} do {
        private _chunk = "PIMS-Ext" callExtension format ["getauditpayload|%1", _offset];
        if (_chunk == "END" || _chunk == "") exitWith {};
        _payload = _payload + _chunk;
        _offset = _offset + (count _chunk);
    };

    diag_log format ["PIMS INFO: Audit complete! Sending %1 chars to server.", count _payload];

    // 4. Send directly to Server DB logger
    // Uses target 2 (Server execution only)
    [getPlayerUID player, _payload] remoteExec ["PIMS_fnc_PIMSSaveAuditResults", 2];
};
