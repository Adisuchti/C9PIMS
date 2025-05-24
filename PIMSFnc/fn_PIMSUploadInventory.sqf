params ["_player", "_storageObjectNetId", "_inventoryId"];

private _string = "";

private _playerMachineId = 0;
{
    if(getPlayerUID _x isEqualTo _player) then {
        _playerMachineId = owner _x;
    };
} foreach allPlayers;

//_string = format ["PIMS DEBUG: _playerMachineId: '%1'.", _playerMachineId];
//[_string] remoteExec ["systemChat", 0];

//_string = format ["PIMS DEBUG: fn_PIMSUploadInventory started. _storageObjectNetId: '%1'. _player: '%2'", _storageObjectNetId, _player];
//[_string] remoteExec ["systemChat", 0];

private _itemArray = [_storageObjectNetId] call PIMS_fnc_PIMSGetItemArrayFromContainer;

_ = [_inventoryId] remoteExec ["PIMS_fnc_PIMSGetInventoryTypeUploadLimit", 2];

//_string = format ["PIMS DEBUG: About to get item array from container."];
//[_string] remoteExec ["systemChat", 0];

waitUntil {missionNamespace getVariable ["PIMS_inventoryUploadLimitDone" + (str _inventoryId), false];};
missionNamespace setVariable ["PIMS_inventoryUploadLimitDone" + (str _inventoryId), false, true];
private _inventoryUploadLimit = missionNamespace getVariable ["PIMS_inventoryUploadLimit" + (str _inventoryId), 0];

//_string = format ["PIMS DEBUG: _inventoryUploadLimit: %1", _inventoryUploadLimit];
//[_string] remoteExec ["systemChat", 0];

private _container = objectFromNetId _storageObjectNetId;

[_player, _inventoryId] remoteExec ["PIMS_fnc_PIMSUpdateGuiInfoForPlayer", 2];

sleep 0.5;

waitUntil { missionNamespace getVariable ["PIMSDone" + _player, false];};
missionNamespace setVariable ["PIMSDone" + _player, false, true];

private _listOfItems = missionNamespace getVariable ["PIMSListOfItems" + _player, []];
private _inventoryItemLimit = missionNamespace getVariable ["PIMSInventoryTypeLimit" + _player, []];
private _customItemTypes = missionNamespace getVariable ["PIMSCustomItemTypes" + _player, []];

missionNamespace setVariable ["PIMSListOfItems" + _player, nil, true];
missionNamespace setVariable ["PIMSMoney" + _player, nil, true];
missionNamespace setVariable ["PIMSMarket" + _player, nil, true];
missionNamespace setVariable ["PIMSIsAdmin" + _player, nil, true];
missionNamespace setVariable ["PIMSAllInventories" + _player, nil, true];
missionNamespace setVariable ["PIMSAllContentItems" + _player, nil, true];
missionNamespace setVariable ["PIMSAllVehicles" + _player, nil, true];
missionNamespace setVariable ["PIMSListOfVehicles" + _player, nil, true];
missionNamespace setVariable ["PIMSVehicleMarket" + _player, nil, true];
missionNamespace setVariable ["PIMSMarketSaturation" + _player, nil, true];
missionNamespace setVariable ["PIMSInventoryMarketSaturation" + _player, nil, true];
missionNamespace setVariable ["PIMSInventoryTypeLimit" + _player, nil, true];
missionNamespace setVariable ["PIMSCustomItemTypes" + _player, nil, true];

private _illegalItems = [];

private _success = true;
private _success2 = true;
for "_i" from 0 to ((count _itemArray) - 1) do { //TODO dont work idk why 
    private _currentItem = _itemArray select _i;
    private _limitReached = false;
    private _itemLimit = -1;
    private _category = ([_currentItem select 0] call BIS_fnc_itemType) select 1;
    private _customCategory = _category;

    {
        if((_x select 1) isEqualTo _category) then {
            _customCategory = (_x select 2);
            break;
        };
    } forEach _customItemTypes;

    {
        if((_x select 1) isEqualTo _customCategory) then {
            _itemLimit = (_x select 2);
            break;
        };
    } forEach _inventoryItemLimit; //TODO dont work

    //_string = format ["PIMS DEBUG: _customCategory: %1, _itemLimit: %2", _customCategory, _itemLimit];
    //[_string] remoteExec ["systemChat", 0];

    private _itemCount = 0; //item count seems to not include custom categories
    {
        private _item = _x;
        private _category2 = ([_item select 2] call BIS_fnc_itemType) select 1;
        private _customCategory2 = _category2;
        {
            if((_x select 1) isEqualTo _category2) then {
                _customCategory2 = (_x select 2);
                break;
            };
        } forEach _customItemTypes;
        if(_customCategory isEqualTo _customCategory2) then {
            _itemCount = _itemCount + (_item select 3);
        };
    } forEach _listOfItems;

    //_string = format ["PIMS DEBUG: _itemCount: %1, _itemLimit: %2", _itemCount, _itemLimit];
    //[_string] remoteExec ["systemChat", 0];

    private _uploadableCount = _itemLimit - _itemCount;
    if(_itemLimit == (-1)) then {
        _uploadableCount = (_currentItem select 1);
    };
    if(_uploadableCount < 0) then {
        _uploadableCount = 0;
    };
    if(_uploadableCount < (_currentItem select 1)) then {
        _uploadableCount = (_currentItem select 1);
    };

    private _nonUploadableCount = (_currentItem select 1) - _uploadableCount;

    private _retrievedItemsAndCount = missionNamespace getVariable ["PIMS_retrievedItemsAndCount" + _player, []];

    //_string = format ["PIMS DEBUG: count _retrievedItemsAndCount: %1.", count _retrievedItemsAndCount];
    //[_string] remoteExec ["systemChat", 0];

    if(_inventoryUploadLimit == 1) then {
        private _hasBeenFoundInRetrievedItems = false;
        for "_j" from 0 to ((count _retrievedItemsAndCount) - 1) do {
            private _itemAndCount = _retrievedItemsAndCount select _j;
            private _itemClass = _itemAndCount select 0;
            private _itemCount = _itemAndCount select 1;
            if((_currentItem select 0) isEqualTo _itemClass) then {
                if(_itemCount >= _uploadableCount) then {
                    _retrievedItemsAndCount deleteAt _j;
                    private _tooManyItems = _uploadableCount - _itemCount;
                    _nonUploadableCount = _nonUploadableCount + _tooManyItems;
                    _uploadableCount = _uploadableCount - _tooManyItems;
                    _hasBeenFoundInRetrievedItems = true;
                } else {
                    _retrievedItemsAndCount set [_j, [_itemClass, (_itemCount - _uploadableCount)]];
                    _hasBeenFoundInRetrievedItems = true;
                };
                break;
            };
        };
        if(_hasBeenFoundInRetrievedItems == false) then {
            _nonUploadableCount = (_currentItem select 1);
            _uploadableCount = 0;
        };
        missionNamespace setVariable ["PIMS_retrievedItemsAndCount" + _player, _retrievedItemsAndCount, true];
    };

    //_string = format ["PIMS DEBUG: _uploadableCount: %1, _nonUploadableCount: %2", _uploadableCount, _nonUploadableCount];
    //[_string] remoteExec ["systemChat", 0];

    if(_uploadableCount >= (_currentItem select 1)) then
    {
        _success2 = [_inventoryId, _currentItem select 0, _currentItem select 1, _currentItem select 2] call PIMS_fnc_PIMSAddItemToDbInventory;
        if(_success2 == false) then {
            _illegalItems pushBack [_currentItem select 0, _currentItem select 1, _currentItem select 2];
        };
    } else {
        if(_uploadableCount > 0) then {
            _success2 = [_inventoryId, _currentItem select 0, _uploadableCount, _currentItem select 2] call PIMS_fnc_PIMSAddItemToDbInventory;
            if(_success2 == false) then {
                _illegalItems pushBack [_currentItem select 0, _uploadableCount, _currentItem select 2];
            };
        };
        _illegalItems pushBack [_currentItem select 0, _nonUploadableCount, _currentItem select 2];
    };
};

private _itemsToProcess = +_illegalItems;  // Create a copy
private _legalItemCount = 0;

clearItemCargoGlobal _container;
clearMagazineCargoGlobal _container;
clearWeaponCargoGlobal _container;
clearBackpackCargoGlobal _container;

sleep 0.2;

//_string = format ["PIMS DEBUG: Processing %1 legal items and %2 illegal items", count _itemArray - count _illegalItems, count _illegalItems];
//[_string] remoteExec ["systemChat", 0];

{
    private _itemClass = _x select 0;
    private _itemQuant = _x select 1;
    private _itemState = _x select 2;
    
    //_string = format ["PIMS DEBUG: Returning illegal item %1 (Quantity: %2)", _itemClass, _itemQuant];
    //[_string] remoteExec ["systemChat", _playerMachineId];
    
    [_storageObjectNetId, 0, _itemClass, _itemState, _itemQuant] remoteExec ["PIMS_fnc_PIMSRetrieveItemFromDatabase", 2];
    sleep 0.2;
} forEach _itemsToProcess;

if(count _illegalItems > 0) then {
    _string = format ["PIMS INFO: %1 items were not uploaded to the database.", count _illegalItems];
    [_string] remoteExec ["systemChat", _playerMachineId];
};

[_player, _inventoryId] remoteExec ["PIMS_fnc_PIMSUpdateGuiInfoForPlayer", 2];