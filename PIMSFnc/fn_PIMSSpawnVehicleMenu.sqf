params ["_vehicleDbItem", "_playerNetId"]; //TODO vehicles are buggy as hell right now

private _string = "";

private _vehicleId = _vehicleDbItem select 0;
private _vehicleClass = _vehicleDbItem select 2;
private _vehicleFuel = _vehicleDbItem select 3;
private _vehicleDamage = _vehicleDbItem select 4;
private _vehicleAcecargo = _vehicleDbItem select 5;
private _vehicleAmmo = _vehicleDbItem select 6;

//_string = format ["PIMS DEBUG: _vehicleId: %1, _vehicleClass: %2, _vehicleFuel: %3, _vehicleAcecargo: %4", _vehicleId, _vehicleClass, _vehicleFuel, _vehicleAcecargo];
//[_string] remoteExec ["systemChat", 0];

private _player = objectFromNetId _playerNetId;
private _owner = owner _player;
private _uid = getPlayerUID _player;
private _playerPos = getPos _player;
private _playerVectorDir = vectorDir _player;
private _objectDistance = 5;
private _objectDirection = (_playerVectorDir select 0) atan2 (_playerVectorDir select 1);
_objectDirection = (_objectDirection + 360) % 360;

missionNamespace setVariable ["PIMS_VehicleSpawn_" + _uid, false, true];
missionNamespace setVariable ["PIMS_VehicleCancel_" + _uid, false, true];
missionNamespace setVariable ["PIMS_IncreaseDistance_" + _uid, false, true];
missionNamespace setVariable ["PIMS_DecreaseDistance_" + _uid, false, true];
missionNamespace setVariable ["PIMS_RotateLeft_" + _uid, false, true];
missionNamespace setVariable ["PIMS_RotateRight_" + _uid, false, true];

missionNamespace setVariable ["PIMS_distance_" + _uid, _objectDistance, true];
missionNamespace setVariable ["PIMS_rotation_" + _uid, _objectDirection, true];

private _objectPos = _playerPos vectorAdd (_playerVectorDir vectorMultiply _objectDistance);

//_modelPath = getText (configFile >> "CfgVehicles" >> _vehicleClass >> "model");

//_string = format ["PIMS DEBUG: _modelPath: %1", _modelPath];
//[_string] remoteExec ["systemChat", 0];

//_object = createSimpleObject[_modelPath, _objectPos, false]; //TODO maybe simple object?

//_string = format ["PIMS DEBUG: spawning preview vehicle. class: %1, _objectPos: %2, _objectDirection : %3", _vehicleClass, _objectPos, _objectDirection];
//[_string] remoteExec ["systemChat", 0];

private _allVehicles = vehicles;
private _object = createVehicle [_vehicleClass, _objectPos, [], 0, "CAN_COLLIDE"];

_object setPhysicsCollisionFlag false; //Ignore sqflint error. 

_object setMass 0;
_object setDir _objectDirection;
_object enableSimulationGlobal false;
_object allowDamage false;

//_string = format ["PIMS DEBUG: vehicle spawned"];
//[_string] remoteExec ["systemChat", 0];

clearItemCargoGlobal _object; // Removes all regular inventory items
clearMagazineCargoGlobal _object; // Removes all magazines
clearWeaponCargoGlobal _object; // Removes all weapons
clearBackpackCargoGlobal _object; // Removes all backpacks

//_string = format ["PIMS DEBUG: vehicle inventory emptied"];
//[_string] remoteExec ["systemChat", 0];

_object setFuel 0;
_object lock true;
private _aceCargo = _object getVariable ["ace_cargo_loaded", []];
for "_i" from 0 to ((count _aceCargo) - 1) do {
    private _cargoItem = _aceCargo select _i;
    [_cargoItem, _object, 1] call ace_cargo_fnc_removeCargoItem;
};

//_string = format ["PIMS DEBUG: starting vehicle Menu on player net Id: %1", _playerNetId];
//[_string] remoteExec ["systemChat", 0];

[_vehicleClass] remoteExec ["PIMS_fnc_PIMSSpawnVehicleMenuLocal", _owner];

private _canceled = false;

while {alive _object} do {
    private _objectDistance = missionNamespace getVariable ["PIMS_distance_" + _uid, 5];
    private _objectAngle = missionNamespace getVariable ["PIMS_rotation_" + _uid, 0];

    private _playerPos = getPos _player;
    private _playerVectorDir = vectorDir _player;
    private _objectPos = _playerPos vectorAdd (_playerVectorDir vectorMultiply _objectDistance);

    _object setPos _objectPos;
    _object setDir _objectAngle;

    private _sizeOfObject = sizeOf _vehicleClass;

    private _collidingObjects = nearestObjects [_object, [], _sizeOfObject];

    if (count _collidingObjects > 1) then {
        _object setObjectTextureGlobal [0, "#(argb,8,8,3)color(1.0,0.0,0.0,1.0,CA)"]; //TODO make transparent maybe (dunno how)
    } else {
        _object setObjectTextureGlobal [0, "#(argb,8,8,3)color(0.0,1.0,0.0,1.0,CA)"];
    };

    private _spawnVehicle = missionNamespace getVariable ["PIMS_VehicleSpawn_" + _uid, false];
    private _spawnCancel = missionNamespace getVariable ["PIMS_VehicleCancel_" + _uid, false];
    private _spawnIncreaseDistance = missionNamespace getVariable ["PIMS_IncreaseDistance_" + _uid, false];
    private _spawnDecreaseDistance = missionNamespace getVariable ["PIMS_DecreaseDistance_" + _uid, false];
    private _spawnRotateLeft = missionNamespace getVariable ["PIMS_RotateLeft_" + _uid, false];
    private _spawnRotateRight = missionNamespace getVariable ["PIMS_RotateRight_" + _uid, false];

    if(_spawnCancel) then {
        _canceled = true;
        break;
    };
    if(_spawnVehicle) then {
        break;
    };
    if(_spawnIncreaseDistance) then {
        missionNamespace setVariable ["PIMS_distance_" + _uid, _objectDistance + 1, true];
        missionNamespace setVariable ["PIMS_IncreaseDistance_" + _uid, false, true];
    };
    if(_spawnDecreaseDistance) then {
        missionNamespace setVariable ["PIMS_distance_" + _uid, _objectDistance - 1, true];
        missionNamespace setVariable ["PIMS_DecreaseDistance_" + _uid, false, true];
    };
    if(_spawnRotateLeft) then {
        _objectAngle = _objectAngle - 5;
        if(_objectAngle < 0) then {
            _objectAngle = _objectAngle + 360;
        };

        missionNamespace setVariable ["PIMS_rotation_" + _uid, _objectAngle, true];
        missionNamespace setVariable ["PIMS_RotateLeft_" + _uid, false, true];
    };
    if(_spawnRotateRight) then {
        _objectAngle = _objectAngle + 5;
        if(_objectAngle > 360) then {
            _objectAngle = _objectAngle - 360;
        };

        missionNamespace setVariable ["PIMS_rotation_" + _uid, _objectAngle, true];
        missionNamespace setVariable ["PIMS_RotateRight_" + _uid, false, true];
    };
};

if(!_canceled) then {
    //_string = format ["PIMS DEBUG: spawning actual vehicle. class: " + _vehicleClass];
    //[_string] remoteExec ["systemChat", 0];

    //TODO check in db if vehicle still exists.

    deleteVehicle _object;
    sleep 0.2; //TODO maybe remove.

    private _objectDistance = missionNamespace getVariable ["PIMS_distance_" + _uid, 5];
    private _objectDirection = missionNamespace getVariable ["PIMS_rotation_" + _uid, 0];

    private _playerPos = getPos _player;
    private _playerVectorDir = vectorDir _player;
    private _objectPos = _playerPos vectorAdd (_playerVectorDir vectorMultiply _objectDistance);
    _object = createVehicle [_vehicleClass, _objectPos, [], 0, "NONE"];
    //_object allowDamage false;
    _object setDir _objectDirection;

    clearItemCargoGlobal _object;   // Removes all regular inventory items
    clearMagazineCargoGlobal _object; // Removes all magazines
    clearWeaponCargoGlobal _object;  // Removes all weapons
    clearBackpackCargoGlobal _object; // Removes all backpacks

    //Ammo
    private _mags = magazinesAllTurrets _object;
    for "_i" from 0 to ((count _mags) - 1) do {
        _magazineName = (_mags select _i) select 0;
        _turretPath = (_mags select _i) select 1;
        _object removeMagazinesTurret [_magazineName, _turretPath]
    };
    _mags = magazinesAllTurrets _object;
    //_string = format ["PIMS DEBUG: _mags after deleting all: %1", _mags];
    //[_string] remoteExec ["systemChat", 0];

    //_string = format ["PIMS DEBUG: _vehicleAmmo: %1", _vehicleAmmo];
    //[_string] remoteExec ["systemChat", 0];
    _vehicleAmmo = _vehicleAmmo regexReplace ["`", """"];
    _vehicleAmmo = parseSimpleArray _vehicleAmmo;
    //_string = format ["PIMS DEBUG: _vehicleAmmo: %1", _vehicleAmmo];
    //[_string] remoteExec ["systemChat", 0];
    for "_i" from 0 to ((count _vehicleAmmo) - 1) do {
        //_string = format ["PIMS DEBUG: adding magazine: %1", (_vehicleAmmo select _i)];
        //[_string] remoteExec ["systemChat", 0];
        _magazineName = (_vehicleAmmo select _i) select 0;
        _turretPath = (_vehicleAmmo select _i) select 1;
        _ammoCount = (_vehicleAmmo select _i) select 2;

        _object addMagazineTurret [_magazineName, _turretPath, _ammoCount];
        //_string = format ["PIMS DEBUG: adding magazine: %1, %2, %3", _magazineName, _turretPath, _ammoCount];
        //[_string] remoteExec ["systemChat", 0];

        _object addMagazineTurret [_magazineName, _turretPath, _ammoCount];

        //_string = format ["PIMS DEBUG: typeNames : %1, %2, %3", typeName _magazineName, typeName _turretPath, typeName _ammoCount];
        //[_string] remoteExec ["systemChat", 0];
    };

    //Damage
    //_string = format ["PIMS DEBUG: _vehicleDamage: %1", _vehicleDamage];
    //[_string] remoteExec ["systemChat", 0];

    _vehicleDamage = _vehicleDamage regexReplace ["`", """"];
    _vehicleDamage = parseSimpleArray _vehicleDamage;

    //_string = format ["PIMS DEBUG: _vehicleDamage: %1", _vehicleDamage];
    //[_string] remoteExec ["systemChat", 0];
    for "_i" from 0 to ((count _vehicleDamage) - 1) do {
        private _hitPointName = (_vehicleDamage select _i) select 0;
        private _hitPointDamage = (_vehicleDamage select _i) select 1;

        //_string = format ["PIMS DEBUG: _hitPointName: %1, _hitPointDamage: %2", _hitPointName, _hitPointDamage];
        //[_string] remoteExec ["systemChat", 0];

        //_string = format ["PIMS DEBUG: typeNames _hitPointName: %1, _hitPointDamage: %2", typeName _hitPointName, typeName _hitPointDamage];
        //[_string] remoteExec ["systemChat", 0];

        _object setHitPointDamage [_hitPointName, _hitPointDamage];
    };

    //Fuel
    _object setFuel _vehicleFuel;

    //_string = format ["PIMS DEBUG: fuel set"];
    //[_string] remoteExec ["systemChat", 0];

    //Ace Cargo
    private _aceCargo = _object getVariable ["ace_cargo_loaded", []];
    for "_i" from 0 to ((count _aceCargo) - 1) do {
        private _cargoItem = _aceCargo select _i;
        [_cargoItem, _object, 1] call ace_cargo_fnc_removeCargoItem;
    };

    //_string = format ["PIMS DEBUG: _vehicleAcecargo: %1", _vehicleAcecargo];
    //[_string] remoteExec ["systemChat", 0];

    _vehicleAcecargo = _vehicleAcecargo regexReplace ["`", """"];

    //_string = format ["PIMS DEBUG: _vehicleAcecargo: %1", _vehicleAcecargo];
    //[_string] remoteExec ["systemChat", 0];

    _vehicleAcecargo = parseSimpleArray _vehicleAcecargo;

    //_string = format ["PIMS DEBUG: _vehicleAcecargo: %1", _vehicleAcecargo];
    //[_string] remoteExec ["systemChat", 0];

    for "_i" from 0 to ((count _vehicleAcecargo) - 1) do {
        private _cargoItem = _vehicleAcecargo select _i;
        [_cargoItem, _object] call ace_cargo_fnc_loadItem;
    };

    //_string = format ["PIMS DEBUG: ace cargo added"];
    //[_string] remoteExec ["systemChat", 0];

    sleep 0.2; //TODO maybe remove.
    _object allowDamage true;

    private _quotationMark = """";
    private _query = format ["0:SQLProtocol:SELECT `Vehicle_Id`, `Inventory_Id`, `Vehicle_Class`, `Vehicle_Fuel`, REPLACE(`Vehicle_Hitpoints`, '" + _quotationMark + "', '`'), REPLACE(`Vehicle_Ace_Cargo`, '" + _quotationMark + "', '`'), REPLACE(`Vehicle_Ammo`, '" + _quotationMark + "', '`') FROM `vehicles`;"];
    private _result = "extDB3" callExtension _query;

    //_string = format ["PIMS DEBUG: _result: %1", _result];
    //[_string] remoteExec ["systemChat", 0];

    private _resultArray = parseSimpleArray _result;

    //_string = format ["PIMS DEBUG: _resultArray: %1", _resultArray];
    //[_string] remoteExec ["systemChat", 0];

    if((str (_resultArray select 0)) == "0") then {
        _string = format ["PIMS ERROR: SQL error. SELECT query failed."];
        [_string] remoteExec ["systemChat", 0];
        deleteVehicle _object;
    } else {
        _query = format ["0:SQLProtocol:DELETE FROM `vehicles` WHERE `Vehicle_Id` = %1;", _vehicleId];
        _result = "extDB3" callExtension _query;
        _resultArray = parseSimpleArray _result;

        //_string = format ["PIMS DEBUG: _resultArray: %1", _resultArray];
        //[_string] remoteExec ["systemChat", 0];

        if((str (_resultArray select 0)) == "0") then {
            _string = format ["PIMS ERROR: SQL error. DELETE query failed."];
            [_string] remoteExec ["systemChat", 0];
            deleteVehicle _object;
        };
    };
} else {
    deleteVehicle _object;
};