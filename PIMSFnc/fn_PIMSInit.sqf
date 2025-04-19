private ["_logic"];

missionNamespace setVariable ["PIMS_areMarketsEnabled", true, true];

private _stringGeneral = "";
private _result = "";
private _query= "";

addMissionEventHandler ["PlayerConnected", {
    params ["_id", "_uid", "_name", "_jip", "_owner", "_idstr"];

    private _stringPlayerConnected = "";
    private _resultPlayerConnected = "";
    private _queryPlayerConnected = "";

    _stringPlayerConnected = format ["PIMS DEBUG: player connected. _uid: %1, name: %2", _uid, _name];
    [_stringPlayerConnected] remoteExec ["systemChat", 0];

    if(_uid != "1" && _uid != "") then {
        //_stringPlayerConnected = format ["PIMS DEBUG: player connected 2. _uid: %1, name: %2", _uid, _name];
        //[_stringPlayerConnected] remoteExec ["systemChat", 0];
        private _PIMSallModules = allMissionObjects "Logic";
        private _PIMSallAddIventoryModules = _PIMSallModules select {
            configName(configFile >> "CfgVehicles" >> typeOf _x) == "PIMS_ModuleAddInventory"
        };

        {
            private _module = _x;
            private _objects = synchronizedObjects _module;
            _objects = _objects select {!isNil "_x"};

            private _inventoryId = _module getVariable ["PIMS_Inventory_Id_Edit", 0];
            _queryPlayerConnected = format ["0:SQLProtocol:SELECT `inventory_name` FROM `inventories` WHERE `inventory_id` = %1;", _inventoryId];
            _resultPlayerConnected = "extDB3" callExtension _queryPlayerConnected;
        
            private _inventoryNameList = parseSimpleArray _resultPlayerConnected;

            if((str (_inventoryNameList select 0)) == "0") then {
                _stringPlayerConnected = format ["PIMS ERROR: SQL error. %1", _queryPlayerConnected];
                [_stringPlayerConnected] remoteExec ["systemChat", 0];
            };

            private _interactionLabelUpload = format ["Upload Conent to Inventory: %1", ((_inventoryNameList select 1) select 0)];
            private _interactionLabelOpen = format ["Open Menu to Inventory: %1", ((_inventoryNameList select 1) select 0)];

            _queryPlayerConnected = format ["0:SQLProtocol:SELECT `Permission_Id`, `Inventory_Id`, `Player_Id` FROM `permissions` WHERE `Inventory_Id` = %1 AND `Player_Id` = '%2';", _inventoryId, _uid];
            _resultPlayerConnected = "extDB3" callExtension _queryPlayerConnected;

            _inventoryPermissionsForInventory = parseSimpleArray _resultPlayerConnected;

            if((str (_inventoryPermissionsForInventory select 0)) == "0") then {
                _stringPlayerConnected = format ["PIMS ERROR: SQL error. %1", _queryPlayerConnected];
                [_stringPlayerConnected] remoteExec ["systemChat", 0];
            };
            
            if((count (_inventoryPermissionsForInventory select 1)) > 0) then {
                for "_i" from 0 to ((count _objects) - 1) do {
                    _object = (_objects select _i);
                    _objectNetId = NetId _object;
                    _owner1 = _uid;
                    _inventoryId1 = _inventoryId;

                    private _allInventories = [];
                    private _allContentItems = [];

                    _queryPlayerConnected = format ["0:SQLProtocol:SELECT `AdminId`, `PlayerId` FROM `admins` WHERE `PlayerId` = %1;", _uid];
                    _resultPlayerConnected = "extDB3" callExtension _queryPlayerConnected;
                    private _adminPermission = parseSimpleArray _resultPlayerConnected;

                    _adminPermission = _adminPermission select 1;
                    private _isAdmin = false;
                    if((count _adminPermission) > 0) then {
                        _isAdmin = true;
                    };

                    private _enablevehicles = _module getVariable ["PIMS_Enable_Vehicles_CheckBox", false];

                    //_stringPlayerConnected = format ["PIMS DEBUG: _objectNetId: %1, _inventoryId1: %2", _objectNetId, _inventoryId1];
                    //[_stringPlayerConnected] remoteExec ["systemChat", 0];

                    [_object,
                        [_interactionLabelUpload,
                            {
                                params ["_target", "_caller", "_actionId", "_arguments"];
                                //_string = format ["PIMS DEBUG: _arguments content: %1", _arguments];
                                //[_string] remoteExec ["systemChat", 0];

                                private _PIMSUploadInventoryOwner = _arguments select 0;
                                private _PIMSUploadInventoryObjectNetId = _arguments select 1;
                                private _PIMSUploadInventoryInventoryId = _arguments select 2;

                                [_PIMSUploadInventoryOwner, _PIMSUploadInventoryObjectNetId,  _PIMSUploadInventoryInventoryId] remoteExec ["PIMS_fnc_PIMSUploadInventory", 2];
                            }, //script
                            [_owner1, _objectNetId, _inventoryId1], //arguments
                            1.5,        // priority
                            true,		// showWindow
                            true,		// hideOnUse
                            "",			// shortcut
                            "true",		// condition
                            5,			// radius
                            false,		// unconscious
                            "",			// selection
                            ""			// memoryPoint
                        ]
                    ] remoteExec ["addAction", _owner];

                    [_object,
                        [_interactionLabelOpen,
                            {
                                params ["_target", "_caller", "_actionId", "_arguments"];
                                //_string = format ["PIMS DEBUG: _arguments content: %1", _arguments];
                                //[_string] remoteExec ["systemChat", 0];

                                private _PIMSOpenMenuOwner = _arguments select 0; 
                                private _PIMSOpenMenutObjectNetId = _arguments select 1;
                                private _PIMSOpenMenutInventoryId = _arguments select 2;
                                private _PIMSOpenMenuIsAdmin = _arguments select 3;
                                private _PIMSOpenMenuEnableVehicles = _arguments select 4;
                                [_PIMSOpenMenuOwner, _PIMSOpenMenutObjectNetId, _PIMSOpenMenutInventoryId, _PIMSOpenMenuIsAdmin, _PIMSOpenMenuEnableVehicles] remoteExec ["PIMS_fnc_PIMSOpenMenu", 2];
                            }, //script
                            [_owner1, _objectNetId, _inventoryId1, _isAdmin, _enableVehicles], //arguments
                            1.5,        // priority
                            true,		// showWindow
                            true,		// hideOnUse
                            "",			// shortcut
                            "true",		// condition
                            5,			// radius
                            false,		// unconscious
                            "",			// selection
                            ""			// memoryPoint
                        ]
                    ] remoteExec ["addAction", _owner];

                    //_stringPlayerConnected = format ["PIMS DEBUG: actions created"];
                    //[_stringPlayerConnected] remoteExec ["systemChat", 0];
                };
            };
        } forEach _PIMSallAddIventoryModules;
    };
}];

if(isDedicated) then {
    ["starting PIMS..."] remoteExec ["systemChat", 0];

    _result  = "extDB3" callExtension "9:ADD_DATABASE:arma_inventories";
    _string = format ["PIMS INFO: ADD_DATABASE: %1", _result];
    [_string] remoteExec ["systemChat", 0];

    _result = "extDB3" callExtension "9:ADD_DATABASE_PROTOCOL:arma_inventories:SQL:SQLProtocol:TEXT";
    _string = format ["PIMS INFO: ADD_DATABASE_PROTOCOL: %1", _result];
    [_string] remoteExec ["systemChat", 0];

    _query = "0:SQLProtocol:SELECT `inventory_name` FROM `inventories`;";
    _result = "extDB3" callExtension _query;
    private _resultArray = parseSimpleArray _result;

    if((str (_resultArray select 0)) == "0") then {
        _string = format ["PIMS ERROR: SQL error. %1", _query];
        [_string] remoteExec ["systemChat", 0];
    };

    fn_removeAllInventorySyncedVehiclesFromList = {
        params["_allVehicles"];

        private _allVehicles2 = _allVehicles;

        //_string = format ["PIMS DEBUG: running fn_removeAllInventorySyncedVehiclesFromList"];
        //[_string] remoteExec ["systemChat", 0];

        private _allSyncedObjects = [];
        private _PIMSallModules = allMissionObjects "Logic";
        private _PIMSallAddIventoryModules = _PIMSallModules select {
            configName(configFile >> "CfgVehicles" >> typeOf _x) == "PIMS_ModuleAddInventory"
        };
        {
            private _module = _x;
            private _objects = synchronizedObjects _module;
            _allSyncedObjects = _allSyncedObjects + _objects;
        } forEach _PIMSallAddIventoryModules;
        for "_i" from 0 to ((count _allSyncedObjects) - 1) do {
            private _syncedObject = _allSyncedObjects select _i;
            for "_j" from ((count _allVehicles2) - 1) to 0 do {
                private _syncedObjectNetId = NetId _syncedObject;
                private _vehicleNetId = NetId (_allVehicles2 select _j);
                //_string = format ["PIMS DEBUG: _syncedObjectNetId: %1, _vehicleNetId: %2", _syncedObjectNetId, _vehicleNetId];
                //[_string] remoteExec ["systemChat", 0];
                if(_syncedObjectNetId isEqualTo _vehicleNetId) then {
                    _allVehicles2 deleteAt _j;
                };
            };
        };

        //_string = format ["PIMS DEBUG: ending fn_removeAllInventorySyncedVehiclesFromList"];
        //[_string] remoteExec ["systemChat", 0];
        _allVehicles2;
    };

    //Vehicles
    [] spawn {
        while {true} do {
            private _stringVehicleLoop = "";
            private _resultVehicleLoop = "";
            private _queryVehicleLoop = "";
            //_stringVehicleLoop = format ["PIMS DEBUG: updating vehicle interactions"];
            //[_stringVehicleLoop] remoteExec ["systemChat", 0];
            private _PIMSallModules = allMissionObjects "Logic";
            private _PIMSallAddIventoryModules = _PIMSallModules select {
                configName(configFile >> "CfgVehicles" >> typeOf _x) == "PIMS_ModuleAddInventory"
            };
            {
                private _module = _x;
                private _objects = synchronizedObjects _module;
                private _objects = _objects select {!isNil "_x"};

                private _inventoryId = _module getVariable ["PIMS_Inventory_Id_Edit", 0];
                private _enablevehicles = _module getVariable ["PIMS_Enable_Vehicles_CheckBox", false];

                if(_enablevehicles) then {
                    private _queryVehicleLoop = format ["0:SQLProtocol:SELECT `inventory_name` FROM `inventories` WHERE `inventory_id` = %1;", _inventoryId];
                    private _resultVehicleLoop = "extDB3" callExtension _queryVehicleLoop;
                    private _inventoryNameList = parseSimpleArray _resultVehicleLoop;

                    if((str (_inventoryNameList select 0)) == "0") then {
                        _stringVehicleLoop = format ["PIMS ERROR: SQL error. %1", _queryVehicleLoop];
                        [_stringVehicleLoop] remoteExec ["systemChat", 0];
                    };

                    //_stringVehicleLoop = format ["PIMS DEBUG: count _objects: %1, ((_inventoryNameList select 1) select 0): %2", count _objects, ((_inventoryNameList select 1) select 0)];
                    //[_stringVehicleLoop] remoteExec ["systemChat", 0];

                    private _interactionLabelVehicle = format ["Upload Vehicle to %1", ((_inventoryNameList select 1) select 0)];

                    for "_i" from 0 to ((count _objects) - 1) do {
                        private _object = (_objects select _i);
                        private _allVehicles = vehicles;
                        private _objectPos = getPos _object;
                        private _objectNetId = NetId _object;

                        private _allVehicles = [_allVehicles] call fn_removeAllInventorySyncedVehiclesFromList;

                        //_stringVehicleLoop = format ["PIMS DEBUG: count _allVehicles: %1, _objectNetId: %2", count _allVehicles, _objectNetId];
                        //[_stringVehicleLoop] remoteExec ["systemChat", 0];

                        for "_j" from 0 to ((count _allVehicles) - 1) do {
                            private _vehicle = (_allVehicles select _j);
                            private _distance = (getPos _vehicle) distance _objectPos;
                            private _vehicleNetId = NetId _vehicle;

                            //_stringVehicleLoop = format ["PIMS DEBUG: _distance: %1", _distance];
                            //[_stringVehicleLoop] remoteExec ["systemChat", 0];
                            {
                                //_uid = getPlayerUID _x;
                                private _owner = owner _x;
                                if(_owner != 2) then {
                                    if(_distance < 20) then {
                                        //_stringVehicleLoop = format ["PIMS DEBUG: starting 'PIMS_fnc_PIMSManageUploadVehicleAction'. _vehicleNetId: %1, _objectNetId: %2, _inventoryId: %3, true", _vehicleNetId, _objectNetId, _inventoryId];
                                        //[_stringVehicleLoop] remoteExec ["systemChat", 0];
                                        [_vehicleNetId, _objectNetId, _inventoryId, _interactionLabelVehicle, true] remoteExec ["PIMS_fnc_PIMSManageUploadVehicleAction", _owner];
                                    } else {
                                        //_stringVehicleLoop = format ["PIMS DEBUG: starting 'PIMS_fnc_PIMSManageUploadVehicleAction'. _vehicleNetId: %1, _objectNetId: %2, _inventoryId: %3, false, _distance: %4", _vehicleNetId, _objectNetId, _inventoryId, _distance];
                                        //[_stringVehicleLoop] remoteExec ["systemChat", 0];
                                        [_vehicleNetId, _objectNetId, _inventoryId, _interactionLabelVehicle, false] remoteExec ["PIMS_fnc_PIMSManageUploadVehicleAction", _owner];
                                    };
                                };
                            } forEach allPlayers;
                        };
                    };
                };
            } forEach _PIMSallAddIventoryModules;
            sleep 3;
        };
    };
};

if(!isDedicated) then {
    _string = format ["PIMS ERROR: game is not running on a dedicated server."];
    [_string] remoteExec ["systemChat", 0];
};