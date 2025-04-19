params ["_vehicleType", "_inventoryId"];

private _vehicle = _vehicleType createVehicle [0, 0, 1000];
private _vehicleNetId = NetId _vehicle;

clearItemCargoGlobal _vehicle;   // Removes all regular inventory items
clearMagazineCargoGlobal _vehicle; // Removes all magazines
clearWeaponCargoGlobal _vehicle;  // Removes all weapons
clearBackpackCargoGlobal _vehicle; // Removes all backpacks

[_vehicleNetId, _inventoryId] remoteExec ["PIMS_fnc_PIMSUploadVehicle", 2];