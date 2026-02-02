/*
 * Open PIMS menu for player
 * Much simpler than v1 - just opens dialog and calls list function
 * Now runs on client machine directly
 */

params ["_ownerUid", "_containerNetId", "_inventoryId", "_isAdmin"];

// Create dialog (runs on local client)
createDialog "PIMSMenuDialog";

// 1 in 1000 chance for a funny message
if ((floor (random 1000)) == 0) then {
    private _messages = [
        "Nice Cock!",
        "The worms are under your skin!",
        "Do you hear the voices?",
        "The T-Dolls whisper in their sleep. Do not listen."
    ];
    private _randomMessage = selectRandom _messages;
    hint _randomMessage;
};

// Load inventory list
[_containerNetId, _inventoryId, _isAdmin] spawn PIMS_fnc_PIMSMenuListInventory;
