params ["_vehicleNetId", "_inventoryId"]; //TODO vehicles are buggy as hell right now. ace cargo items are fucked and ammo is fucked. also the uploading of some vehicles is fucked.

private _string = "";

//_string = format ["PIMS DEBUG: PIMSUploadVehicle: _vehicleNetId: %1, _inventoryId: %2", _vehicleNetId, _inventoryId];
//[_string] remoteExec ["systemChat", 0];

[player, _vehicleNetId, _inventoryId] call PIMS_fnc_PIMSUploadInventory;

//_string = format ["PIMS DEBUG: vehicle inventory uploaded."];
//[_string] remoteExec ["systemChat", 0];

private _vehicle = objectFromNetId _vehicleNetId;

private _fuelLevel = fuel _vehicle;

private _vehicleType = typeOf _vehicle;

private _gethitPointsArray = getAllHitPointsDamage _vehicle;
private _gethitPointsNameArray = _gethitPointsArray select 0;
private _gethitPointsDamageArray = _gethitPointsArray select 2;
private _hitPointsArray = [];
for "_i" from 0 to ((count _gethitPointsNameArray) - 1) do {
	_hitPointsArray pushback [(_gethitPointsNameArray select _i), (_gethitPointsDamageArray select _i)];
};

private _aceCargo = [];

//_loadedMods = getLoadedModsInfo; //TODO maybe check if ACE3 is among loaded mods before accessing "ace_cargo_loaded"

_aceCargo = _vehicle getVariable ["ace_cargo_loaded", []];

//_ammo = _vehicle magazinesTurret [[0], false]; //works but without ammo count.
private _ammo = magazinesAllTurrets _vehicle; //TODO try. alternatively use "magazinesDetail"

private _ammo2 = [];

for "_i" from 0 to ((count _ammo) - 1) do {
	private _currentAmmo = _ammo select _i;
	_ammo2 pushback [(_currentAmmo select 0), (_currentAmmo select 1), (_currentAmmo select 2)];
};


//_string = format ["PIMS DEBUG: PIMSUploadVehicle: _vehicleType: %1, _fuelLevel: %2, _hitPointsArray: %3, _aceCargo: %4, _ammo2: %5", _vehicleType, _fuelLevel, _hitPointsArray, _aceCargo, _ammo2];
//[_string] remoteExec ["systemChat", 0];

if(_vehicleType != "") then {
	private _query = format ["0:SQLProtocol:INSERT INTO `vehicles`(`Inventory_Id`, `Vehicle_Class`, `Vehicle_Fuel`, `Vehicle_Hitpoints`, `Vehicle_Ace_Cargo`, `Vehicle_Ammo`) VALUES ('%1','%2','%3','%4','%5','%6')", _inventoryId, _vehicleType, _fuelLevel, _hitPointsArray, _aceCargo, _ammo2];
	private _result = "extDB3" callExtension _query;
	_result = parseSimpleArray _result;

	if((str (_result select 0)) == "0") then {
		_string = format ["PIMS ERROR: SQL error: %1", _result];
		[_string] remoteExec ["systemChat", 0];
		//_string = format ["PIMS ERROR: SQL error. _inventoryId: %1, _vehicleType: %2, Vehicle_Fuel: %3", _inventoryId, _vehicleType, _fuelLevel];
		//[_string] remoteExec ["systemChat", 0];
		//_string = format ["PIMS ERROR: SQL _hitPointsArray: %1", _hitPointsArray];
		//[_string] remoteExec ["systemChat", 0];
		//_string = format ["PIMS ERROR: SQL _ammo2: %1", _ammo2];
		//[_string] remoteExec ["systemChat", 0];
		//_string = format ["PIMS ERROR: SQL _aceCargo: %1", _aceCargo];
		//[_string] remoteExec ["systemChat", 0];
	} else {
		deleteVehicle _vehicle;
	};
} else {
	_string = format ["PIMS ERROR: attempt to upload non existing vehicle. _vehicleNetId: %1", _vehicleNetId];
	[_string] remoteExec ["systemChat", 0];
};