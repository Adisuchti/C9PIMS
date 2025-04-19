params ["_player", "_storageObjectNetId", "_inventoryId"];

private _string = "";

private _itemArray = [_storageObjectNetId] call PIMS_fnc_PIMSGetItemArrayFromContainer;

private _success = true;
private _success2 = true;
for "_i" from 0 to ((count _itemArray) - 1) do {
    private _currentItem = _itemArray select _i;
    _success2 = [_inventoryId, _currentItem select 0, _currentItem select 1, _currentItem select 2] call PIMS_fnc_PIMSAddItemToDbInventory;
    if(_success2 == false) then {
        _success = false;
    };
};
if(_success) then {
    private _container = objectFromNetId _storageObjectNetId;
    clearItemCargoGlobal _container;   // Removes all regular inventory items
    clearMagazineCargoGlobal _container; // Removes all magazines
    clearWeaponCargoGlobal _container;  // Removes all weapons
    clearBackpackCargoGlobal _container; // Removes all backpacks
} else {
    _string = format ["PIMS ERROR: could not upload all items to database"];
    [_string] remoteExec ["systemChat", 0];
};