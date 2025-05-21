params ["_player", "_storageObjectNetId", "_inventoryId"];

private _string = "";

//_string = format ["PIMS DEBUG: fn_PIMSUploadInventory started. _storageObjectNetId: '%1'. _player: '%2'", _storageObjectNetId, _player];
//[_string] remoteExec ["systemChat", 0];

private _itemArray = [_storageObjectNetId] call PIMS_fnc_PIMSGetItemArrayFromContainer;

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

    private _uploadableCount = _itemLimit - _itemCount;
    if(_itemLimit == (-1)) then {
        _uploadableCount = (_currentItem select 1);
    };
    if(_uploadableCount < 0) then {
        _uploadableCount = 0;
    };

    private _nonUploadableCount = (_currentItem select 1) - _uploadableCount;

    if(_uploadableCount >= (_currentItem select 1)) then
    {
        _success2 = [_inventoryId, _currentItem select 0, _currentItem select 1, _currentItem select 2] call PIMS_fnc_PIMSAddItemToDbInventory;
        if(_success2 == false) then {
            _success = false;
        };
    };
    
    if(_nonUploadableCount > 0) then {
        _currentItem set [1, _nonUploadableCount];
        _illegalItems pushback _currentItem;
    };
};
if(_success) then {
    clearItemCargoGlobal _container;   // Removes all regular inventory items
    clearMagazineCargoGlobal _container; // Removes all magazines
    clearWeaponCargoGlobal _container;  // Removes all weapons
    clearBackpackCargoGlobal _container; // Removes all backpacks

    {
        private _itemClass = _x select 0;
        private _itemQuant = _x select 1;
        private _itemState = _x select 2;
        [_storageObjectNetId, 0, _itemClass, _itemState, _itemQuant] remoteExec ["PIMS_fnc_PIMSRetrieveItemFromDatabase", 2];
    } forEach _illegalItems;
} else {
    _string = format ["PIMS ERROR: could not upload all items to database"];
    [_string] remoteExec ["systemChat", 0];
};