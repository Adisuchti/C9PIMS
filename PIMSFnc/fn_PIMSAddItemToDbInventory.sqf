params ["_inventoryId", "_itemClass", "_quantity", "_itemState"];
private _string = "";
private _query = format ["0:SQLProtocol:SELECT `Content_Item_Id`, `Inventory_Id`, `Item_Class`, `Item_Quantity`, `Item_Properties` FROM `content_items` WHERE `Inventory_Id` = '%1' AND `Item_Class` = '%2' AND `Item_Properties` = '%3'", _inventoryId, _itemClass, _itemState];
private _success = true;
private _result = "extDB3" callExtension _query;
private _resultArray = parseSimpleArray _result;
private _money = 0;

//TODO fn_getConfigPathAndParentPath and fn_getDisplayNameOfClass are duplicated in "PIMS MenuListInventory.sqf". if this were a proper project i wouldnt want unnecessary redundancy
fn_getConfigPathAndParentPath = {
    params ["_itemClass"];
    private _configPath = "";
    private _parentPath = "";
    if (isClass (configFile >> "CfgWeapons" >> _itemClass)) then {
        _configPath = configFile >> "CfgWeapons" >> _itemClass;
        _parentPath = "CfgWeapons";
    } else {
        if (isClass (configFile >> "CfgMagazines" >> _itemClass)) then {
            _configPath = configFile >> "CfgMagazines" >> _itemClass;
            _parentPath = "CfgMagazines";
        } else {
            if (isClass (configFile >> "CfgVehicles" >> _itemClass)) then {
                _configPath = configFile >> "CfgVehicles" >> _itemClass;
                _parentPath = "CfgVehicles";
            } else {
                if (isClass (configFile >> "CfgGlasses" >> _itemClass)) then {
                    _configPath = configFile >> "CfgGlasses" >> _itemClass;
                    _parentPath = "CfgGlasses";
               };
            };
        };
    };
    private _result = [_configPath, _parentPath];
    _result;
};
fn_getDisplayNameOfClass = {
    params ["_itemClass"];
    private _configPathAndParent = [_itemClass] call fn_getConfigPathAndParentPath;
    private _configPath = _configPathAndParent select 0;
    private _displayName = _itemClass;
    _displayName = [_configPath] call BIS_fnc_displayName;
    _displayName;
};

if(_itemClass == "PIMS_Money_1") then {
    _money = 1;
};
if(_itemClass == "PIMS_Money_10") then {
    _money = 10;
};
if(_itemClass == "PIMS_Money_50") then {
    _money = 50;
};
if(_itemClass == "PIMS_Money_100") then {
    _money = 100;
};
if(_itemClass == "PIMS_Money_500") then {
    _money = 500;
};
if(_itemClass == "PIMS_Money_1000") then {
    _money = 1000;
};

if(_money > 0) then {
    [_inventoryId, (_money * _quantity)] call PIMS_fnc_PIMSChangeMoneyOfInventory;
} else {
    if((str (_resultArray select 0)) == "0") then {
        _string = format ["PIMS ERROR: SQL error. %1", _query];
        [_string] remoteExec ["systemChat", 0];
        _success = false;
    };

    if(count (_resultArray select 1) > 0) then {
        private _IdOfEntry = ((_resultArray select 1) select 0) select 0;
        private _currentQuantity = ((_resultArray select 1) select 0) select 3;
        private _addedQuantity = _quantity;
        _query = format ["0:SQLProtocol:UPDATE `content_items` SET `Item_Quantity`='%1' WHERE `Content_Item_Id`='%2';", (_currentQuantity + _addedQuantity), _IdOfEntry];
        //_string = format ["_query: %1", _query];
        //[_string] remoteExec ["systemChat", 0];
        _result = "extDB3" callExtension _query;
        _resultArray = parseSimpleArray _result;
        if(str (_resultArray select 0) isEqualTo "0") then {
            _success = false;
            _string = format ["PIMS ERROR: SQL error. %1", _query];
            [_string] remoteExec ["systemChat", 0];
        };
    } else {
        _query = format ["0:SQLProtocol:INSERT INTO `content_items` (`Inventory_Id`, `Item_Class`, `Item_Quantity`, `Item_Properties`) VALUES (%1, '%2', %3, '%4');", _inventoryId, _itemClass,  _quantity,  _itemState];
        //_string = format ["_query: %1", _query];
        //[_string] remoteExec ["systemChat", 0];
        _result = "extDB3" callExtension _query;
        _resultArray = parseSimpleArray _result;
        if(str (_resultArray select 0) isEqualTo "0") then {
            _success = false;
            _string = format ["PIMS ERROR: SQL error. %1", _query];
            [_string] remoteExec ["systemChat", 0];
        };
    };
    _query = format ["0:SQLProtocol:SELECT `Item_Id`, `Item_Class`, `Item_Type`, `Item_Display_Name` FROM `items` WHERE `Item_Class` = '%1';", _itemClass];
    _result = "extDB3" callExtension _query;
    _resultArray = parseSimpleArray _result;
    if(str (_resultArray select 0) isEqualTo "1") then {
        if(count (_resultArray select 1) == 0) then {
            private _category = [_itemClass] call BIS_fnc_itemType;
            //_string = format ["PIMS DEBUG: _category: %1", _category];
            //[_string] remoteExec ["systemChat", 0];
            _category = _category select 1;

            private _categoryId = -1;

            _query = format ["0:SQLProtocol:SELECT `Item_Type_Id`, `Item_Classification` FROM `item_types` WHERE `Item_Classification` = '%1';", _category];
            _result = "extDB3" callExtension _query;
            _resultArray = parseSimpleArray _result;

            if(str (_resultArray select 0) isEqualTo "1") then {
                if(count (_resultArray select 1) > 0) then {
                    _categoryId = ((_resultArray select 1) select 0) select 0;
                } else {
                    _query = format ["0:SQLProtocol:INSERT INTO `item_types` (`Item_Classification`) VALUES ('%1');", _category];
                    _result = "extDB3" callExtension _query;
                    _resultArray = parseSimpleArray _result;
                    if(str (_resultArray select 0) isEqualTo "1") then {
                        _query = format ["0:SQLProtocol:SELECT `Item_Type_Id` FROM `item_types` WHERE `Item_Classification` = '%1';", _category];
                        _result = "extDB3" callExtension _query;
                        _resultArray = parseSimpleArray _result;
                        if(str (_resultArray select 0) isEqualTo "1") then {
                            if(count (_resultArray select 1) > 0) then {
                                _categoryId = ((_resultArray select 1) select 0) select 0;
                            };
                        } else {
                            _string = format ["PIMS ERROR: SQL error. %1", _query];
                            [_string] remoteExec ["systemChat", 0];
                        };
                    } else {
                        _string = format ["PIMS ERROR: SQL error. %1", _query];
                        [_string] remoteExec ["systemChat", 0];
                    };
                };
            } else {
                _string = format ["PIMS ERROR: SQL error. %1", _query];
                [_string] remoteExec ["systemChat", 0];
            };

            //_string = format ["PIMS DEBUG: category of. %1: %2", _itemClass, _category];
            //[_string] remoteExec ["systemChat", 0];

            private _displayName = [_itemClass] call fn_getDisplayNameOfClass;

            _query = format ["0:SQLProtocol:INSERT INTO `items` (`Item_Class`, `Item_Type`, `Item_Display_Name`) VALUES ('%1', %2, '%3');", _itemClass, _categoryId, _displayName];
            _result = "extDB3" callExtension _query;
            _resultArray = parseSimpleArray _result;
            if(str (_resultArray select 0) isEqualTo "0") then {
                _string = format ["PIMS ERROR: SQL error. %1", _query];
                [_string] remoteExec ["systemChat", 0];
            };
        }
    } else {
        _string = format ["PIMS ERROR: SQL error. %1", _query];
        [_string] remoteExec ["systemChat", 0];
        _string = format ["PIMS ERROR: _result. %1", _result];
        [_string] remoteExec ["systemChat", 0];
    };
};
_success;