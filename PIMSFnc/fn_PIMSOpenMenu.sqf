params ["_owner", "_containerId", "_inventoryId", "_isAdmin", "_enableVehicles"];

private _string = "";

//_string = format ["PIMS DEBUG: starting PIMS_fnc_PIMSOpenMenu"];
//[_string] remoteExec ["systemChat", 0];

private _containerId2 = _containerId;
private _playerName = "unknown";
private _playerNetId = "unknown";
private _enableVehicles2 = _enableVehicles;
private _isAdmin2 = _isAdmin;
{
    if ((getPlayerUID _x) isEqualTo _owner) exitWith {
        _playerName = name _x;
        _playerNetId = owner _x;
    };
} forEach allPlayers;

["PIMSMenuDialog"] remoteExec ["createDialog", _playerNetId];

//_string = format ["PIMS DEBUG: running PIMS_fnc_PIMSMenuListInventory"];
//[_string] remoteExec ["systemChat", 0];
[_containerId2, _inventoryId, _enableVehicles, _isAdmin2] remoteExec ["PIMS_fnc_PIMSMenuListInventory", _playerNetId];