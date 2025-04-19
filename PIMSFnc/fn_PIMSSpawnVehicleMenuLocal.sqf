params ["_vehicleClass"];

private _string = "";

//_string = format ["_vehicleClass: %1", _vehicleClass];
//[_string] remoteExec ["systemChat", 0];

private _uid = getPlayerUID player;
missionNamespace setVariable ["VehicleSpawnGuiVehicleClass-" + _uid, _vehicleClass, true];

//#include "\a3\ui_f\hpp\definedikcodes.inc" //TODO maybe implement

//_string = format ["PIMS DEBUG: local vehicle spawning started"];
//[_string] remoteExec ["systemChat", 0];

uiNamespace setVariable ["onRlcLoad", {
    params ["_display"];
	//_string = format ["PIMS DEBUG: onRscLoad started"];
	//[_string] remoteExec ["systemChat", 0];

	private _display = _this select 0;

	//_string = format ["_display: %1", _display];
	//[_string] remoteExec ["systemChat", 0];

	private _uid = getPlayerUID player;
	private _vehicleClass = missionNamespace getVariable ["VehicleSpawnGuiVehicleClass-" + _uid, "none"];

	//_string = format ["_vehicleClass: %1", _vehicleClass];
	//[_string] remoteExec ["systemChat", 0];

    private _ctrl = _display displayCtrl 1000;
	private _text = parseText format["<t>Vehicle: %1. press 'E' and '+' to rotate. press 'Up' and 'Down' to move closer and further. press 'Enter' or 'T' to spawn.</t>", _vehicleClass];
    _ctrl ctrlSetStructuredText _text;
    _ctrl ctrlCommit 0.1;
}];

onRscDestroy = {
	params ["_control", "_exitCode"];
	//_string = format ["onRscDestroy called"];
	//[_string] remoteExec ["systemChat", 0];

	private _uid = getPlayerUID player;
	missionNamespace setVariable ["PIMS_VehicleCancel_" + _uid, Nil, true];
	missionNamespace setVariable ["PIMS_VehicleCancel_" + _uid, Nil, true];
};

//uinameSpace setVariable ["onRlcKeyDown", {
findDisplay 46 displayAddEventHandler ["KeyDown", {
	params ["_displayOrControl", "_key", "_shift", "_ctrl", "_alt"];

	private _uid = getPlayerUID player;

	private _display = findDisplay 142352;

	private _keyE = 18;
	private _keyQ = 16;

	private _keyT = 20;
	private _keyEnter = 28;

	private _keyEsc = 1;
	private _keyTab = 15;

	private _keyUp = 200;
	private _keyDown = 208;

	//_string = format ["PIMS DEBUG: keyDown._key: %1, _ctrl: %2", _key, _ctrl];
	//[_string] remoteExec ["systemChat", 0];

	//_string = format ["_display: %1, _displayOrControl: %2", _display, _displayOrControl];
	//[_string] remoteExec ["systemChat", 0];

	if(_key isEqualTo _keyEsc || _key isEqualTo _keyTab) then {
		[_display] call fn_closeGui;
	};
	if(_key isEqualTo _keyT || _key isEqualTo _keyEnter) then {
		[_display] call fn_spawnVehicle;
	};

	if(_key isEqualTo _keyE) then {
		missionNamespace setVariable ["PIMS_RotateRight_" + _uid, true, true];
	};
	if(_key isEqualTo _keyQ) then {
		missionNamespace setVariable ["PIMS_RotateLeft_" + _uid, true, true];
	};

	if(_key isEqualTo _keyUp) then {
		missionNamespace setVariable ["PIMS_IncreaseDistance_" + _uid, true, true];
	};
	if(_key isEqualTo _keyDown) then {
		missionNamespace setVariable ["PIMS_DecreaseDistance_" + _uid, true, true];
	};
}];

fn_closeGui = {
	params ["_display"];
	private _uid = getPlayerUID player;
	missionNamespace setVariable ["PIMS_VehicleCancel_" + _uid, true, true];
	
	//_string = format ["_display: %1, _uid: %2", _display, _uid];
	//[_string] remoteExec ["systemChat", 0];
	523 cutFadeOut 0;
};

fn_spawnVehicle = {
	params ["_display"];
	private _uid = getPlayerUID player;
	missionNamespace setVariable ["PIMS_VehicleSpawn_" + _uid, true, true];

	//_string = format ["_display: %1, _uid: %2", _display, _uid];
	//[_string] remoteExec ["systemChat", 0];
	523 cutFadeOut 0;
};

//_string = format ["PIMS DEBUG: local vehicle spawning started 2"];
//[_string] remoteExec ["systemChat", 0];

523 cutRsc ["PIMSVehicleSpawnGui", "PLAIN", 2, true];
