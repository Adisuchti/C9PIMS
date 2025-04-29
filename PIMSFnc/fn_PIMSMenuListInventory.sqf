params ["_containerId", "_inventoryId", "_enableVehicles", "_isAdmin"];

private _stringGlobal = "";
private _uidGlobal = getPlayerUID player;

//_stringGlobal = format ["PIMS DEBUG: fn_PIMSMenuListInventory called."];
//[_stringGlobal] remoteExec ["systemChat", 0];

uiNamespace setVariable ["PIMS_selectedItem", ""];
uiNamespace setVariable ["PIMS_listOfItems", []];
uiNamespace setVariable ["PIMS_selectedIndex", 0];
uiNamespace setVariable ["PIMS_market", []];
uiNamespace setVariable ["PIMS_inventoryMoney", 0];
uiNamespace setVariable ["PIMS_inventoryId", _inventoryId];
uiNamespace setVariable ["PIMS_containerId", _containerId];
uiNamespace setVariable ["PIMS_allInventories", []];
uiNamespace setVariable ["PIMS_allContentItems", []];
uiNamespace setVariable ["PIMS_isAdmin", _isAdmin];
uiNamespace setVariable ["PIMS_quantity", 1];
uiNamespace setVariable ["PIMS_ViewMode", 0]; //0 = inventory, 1 = market, 2 = Bank, 3 = vehicles, 4 = vehicles market, 5 = admin panel
uiNamespace setVariable ["PIMS_allVehicles", []];
uiNamespace setVariable ["PIMS_vehicleMarket", []];
uiNamespace setVariable ["PIMS_enableVehicles", _enableVehicles];
uiNamespace setVariable ["PIMS_MoneyTypes", [["PIMS_Money_1", 1], ["PIMS_Money_10", 10], ["PIMS_Money_50", 50], ["PIMS_Money_100", 100], ["PIMS_Money_500", 500], ["PIMS_Money_1000", 1000]]];
uiNamespace setVariable ["PIMS_listOfVehicles", []];
uiNamespace setVariable ["PIMS_marketSaturation", []];
uiNamespace setVariable ["PIMS_InventoryMarketSaturation", []];
uiNamespace setVariable ["PIMS_Uid", _uidGlobal];
missionNamespace setVariable ["PIMS_closeMenu_" + _uidGlobal, false];

fn_updateView = {
    private _string = "";
    //_string = format ["PIMS DEBUG: fn_updateView called."];
    //[_string] remoteExec ["systemChat", 0];
    private _listOfItems = uiNamespace getVariable ["PIMS_listOfItems", "None"];
    private _viewMode = uiNamespace getVariable ["PIMS_ViewMode", 0];
    private _market = uiNamespace getVariable ["PIMS_market", []];
    private _allInventories = uiNamespace getVariable ["PIMS_allInventories", []];
    private _allContentItems = uiNamespace getVariable ["PIMS_allContentItems", []];
    private _moneyTypes = uiNamespace getVariable ["PIMS_MoneyTypes", []];
    private _inventoryMoney = uiNamespace getVariable ["PIMS_inventoryMoney", 0];
    private _listOfVehicles = uiNamespace getVariable ["PIMS_listOfVehicles", []];
    private _vehicleMarket = uiNamespace getVariable ["PIMS_vehicleMarket", []];
    //_string = format ["PIMS DEBUG: updating view. count of Items: %1, _viewMode: %2", count _listOfItems, _viewMode];
    //[_string] remoteExec ["systemChat", 0];
    private _listBoxEntries = [];
    if (_viewMode == 0) then {
        private _marketButtonCtrl = (findDisplay 142351) displayCtrl 1700;
        private _marketButtonText = format ["Inventory"];
        _marketButtonCtrl ctrlSetText _marketButtonText;
        for "_i" from 0 to ((count _listOfItems) - 1) do {
            private _value = [_i] call fn_convertDbItemToText;
            private _imagePath = [(_listOfItems select _i) select 2] call fn_getImagePathOfClass;
            //_ctrl lbAdd (_value);
            //_ctrl lbSetPicture[_i, _imagePath];
            _listBoxEntries pushback [_value, _imagePath];
        };
    };
    if (_viewMode == 1) then {
        for "_i" from 0 to ((count _market) - 1) do {
            //_string = format ["PIMS DEBUG: _i: %1", _i];
            //[_string] remoteExec ["systemChat", 0];
            private _value = (_market select _i) select 1;
            //_string = format ["PIMS DEBUG: _value: %1", _value];
            //[_string] remoteExec ["systemChat", 0];
            private _imagePath = [(_market select _i) select 1] call fn_getImagePathOfClass;
            //_string = format ["PIMS DEBUG: _imagePath: %1", _imagePath];
            //[_string] remoteExec ["systemChat", 0];
            //_ctrl lbAdd (_value);
            //_ctrl lbSetPicture[_i, _imagePath];
            _listBoxEntries pushback [_value, _imagePath];
        };

        private _marketButtonCtrl = (findDisplay 142351) displayCtrl 1700;
        private _marketButtonText = format ["Market"];
        _marketButtonCtrl ctrlSetText _marketButtonText;
    };
    if (_viewMode == 2) then {

        for "_i" from 0 to ((count _moneyTypes) - 1) do {
            private _displayName = [(_moneyTypes select _i) select 0] call fn_getDisplayNameOfClass;
            //_ctrl lbAdd (_displayName);
            private _imagePath = [(_moneyTypes select _i) select 0] call fn_getImagePathOfClass;
            //_ctrl lbSetPicture[_i, _imagePath];
            _listBoxEntries pushback [_displayName, _imagePath];
        };

        private _marketButtonCtrl = (findDisplay 142351) displayCtrl 1700;
        private _marketButtonText = format ["Bank"];
        _marketButtonCtrl ctrlSetText _marketButtonText;
    };
    if (_viewMode == 3) then {
        private _marketButtonCtrl = (findDisplay 142351) displayCtrl 1700;
        private _marketButtonText = format ["vehicles"];
        _marketButtonCtrl ctrlSetText _marketButtonText;

        for "_i" from 0 to ((count _listOfVehicles) - 1) do {
            private _value = [_i] call fn_convertDbItemToText;
            private _imagePath = [(_listOfVehicles select _i) select 2] call fn_getImagePathOfClass;
            //_ctrl lbAdd (_value);
            //_ctrl lbSetPicture[_i, _imagePath];
            _listBoxEntries pushback [_value, _imagePath];
        };
    };
    if (_viewMode == 4) then {
        private _marketButtonCtrl = (findDisplay 142351) displayCtrl 1700;
        private _marketButtonText = format ["vehicles market"];
        _marketButtonCtrl ctrlSetText _marketButtonText;
        
        for "_i" from 0 to ((count _vehicleMarket) - 1) do {
            private _value = [_i] call fn_convertDbItemToText;
            private _imagePath = [(_vehicleMarket select _i) select 2] call fn_getImagePathOfClass;
            //_ctrl lbAdd (_value);
            //_ctrl lbSetPicture[_i, _imagePath];
            _listBoxEntries pushback [_value, _imagePath];
        };
    };
    if (_viewMode == 5) then {
        private _marketButtonCtrl = (findDisplay 142351) displayCtrl 1700;
        private _marketButtonText = format ["Admin"];
        _marketButtonCtrl ctrlSetText _marketButtonText;

        for "_i" from 0 to ((count _allInventories) - 1) do {
            private _value = (str ((_allInventories select _i) select 0)) + " ; " + (str ((_allInventories select _i) select 1));
            //_ctrl lbAdd (_value);
            _listBoxEntries pushback [_value, ""];
        };
    };
    private _ctrl = (findDisplay 142351) displayCtrl 1500;
    lbClear _ctrl;
    for "_i" from 0 to ((count _listBoxEntries) - 1) do {
        private _entry = _listBoxEntries select _i;
        _ctrl lbAdd (_entry select 0);
        if(_entry select 1 != "") then {
            _ctrl lbSetPicture[_i, _entry select 1];
        };
    };
};

fn_convertDbItemToText = {
    params ["_index"];
    //_string = format ["PIMS DEBUG: fn_convertDbItemToText called. _index: %1", _index];
    //[_string] remoteExec ["systemChat", 0];
    private _viewMode = uiNamespace getVariable ["PIMS_ViewMode", 0];
    private _value = "";
    if(_viewMode == 0 || _viewMode == 1 || _viewMode == 2) then {
        private _listOfItems = uiNamespace getVariable ["PIMS_listOfItems", "None"];
        private _paddingZeroes = "0000000000";
        private _formatTotalLength = 3;
        private _quantity = str ((_listOfItems select _index) select 3);

        private _formattedStringOfQuantity =  (_paddingZeroes select [0, (_formatTotalLength - (count _quantity))]) + _quantity;

        private _displayName = [((_listOfItems select _index) select 2)] call fn_getDisplayNameOfClass;
        _value = (_formattedStringOfQuantity + "x " + _displayName);
        _value = _value + " ; " + ((_listOfItems select _index) select 4);
    } else {
        private _listOfVehicles = uiNamespace getVariable ["PIMS_listOfVehicles", []];
        private _displayName = [((_listOfVehicles select _index) select 2)] call fn_getDisplayNameOfClass;
        _value = _displayName;
    };
    _value;
};

fn_updateDetailText = {
    private _string = "";
    //_string = format ["PIMS DEBUG: fn_updateDetailText called."];
    //[_string] remoteExec ["systemChat", 0];
    private _selectedIndex = uiNamespace getVariable ["PIMS_selectedIndex", "None"]; //TODO what if list is empty and therefore index 0 is not a valid item
    private _listOfItems = uiNamespace getVariable ["PIMS_listOfItems", "None"];
    private _inventoryMoney = uiNamespace getVariable ["PIMS_inventoryMoney", 0];
    private _viewMode = uiNamespace getVariable ["PIMS_ViewMode", 0];
    private _allInventories = uiNamespace getVariable ["PIMS_allInventories", []];
    private _allContentItems = uiNamespace getVariable ["PIMS_allContentItems", []];
    private _inventoryId = uiNamespace getVariable ["PIMS_inventoryId", []];
    private _editQuantity = uiNamespace getVariable ["PIMS_quantity", 1];
    private _moneyTypes = uiNamespace getVariable ["PIMS_MoneyTypes", []];
    private _listOfVehicles = uiNamespace getVariable ["PIMS_listOfVehicles", []];
    private _vehicleMarket = uiNamespace getVariable ["PIMS_vehicleMarket", []];
    private _areMarketsEnabled = missionNamespace getVariable ["PIMS_areMarketsEnabled", false];
    private _inventoryMarketSaturation = uiNamespace getVariable ["PIMS_InventoryMarketSaturation", []];
    private _marketSaturation = uiNamespace getVariable ["PIMS_marketSaturation", []];
    private _market = uiNamespace getVariable ["PIMS_market", []];
    private _inventoryItemLimit = uiNamespace getVariable ["PIMS_InventoryTypeLimit", []];
    private _itemTypeCountAndLimit = [] call fn_getItemTypeCountAndLimit;
    private _customItemTypes = uiNamespace getVariable ["PIMS_CustomItemTypes", []];

    if (_viewMode == 0 || _viewMode == 1) then {
        private _selectedItem = nil;
        private _selectedItemClass = "";
        private _selectedItemQuantity = 0;
        private _selectedItemState = 0;
        if(_viewMode == 0) then {
            _selectedItem = (_listOfItems select _selectedIndex);
            _selectedItemClass = _selectedItem select 2;
            _selectedItemQuantity = _selectedItem select 3;
            _selectedItemState = _selectedItem select 4;
        } else {
            _selectedItem = (_market select _selectedIndex);
            _selectedItemClass = _selectedItem select 1;
        };
        private _prices = [] call fn_getPrices;
        private _pricesWithSaturation = [_editQuantity] call fn_getPricesWithSaturation;
        private _sellPrice = _prices select 1;
        private _sellPriceWithSaturation = _pricesWithSaturation select 1;
        private _purchasePrice = _prices select 0;
        private _displayName = [_selectedItemClass] call fn_getDisplayNameOfClass;
        private _weightKg = [_selectedItemClass] call fn_getWeightOfClass;
        private _availableQuantityOnMarket = [_selectedItemClass] call fn_getAvailableMarketQuantity;

        private _category = ([_selectedItemClass] call BIS_fnc_itemType) select 1;
        private _customCategory = _category;
        private _itemLimit = -1;
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
        } forEach _inventoryItemLimit;
        private _currentCountOfType = [_customCategory] call fn_currentAmountOFItemsOfCertainType;
        private _allowedBuyingQuantity = _itemLimit - _currentCountOfType;

        private _currentAmountOfTypeText = "";
        if(_itemLimit == (-1)) then {
            _currentAmountOfTypeText = parseText format["%1 of infinite", _currentCountOfType];
        } else {
            _currentAmountOfTypeText = parseText format["%1 of %2", _currentCountOfType, _itemLimit];
        };
        
        private _quantityEntry = (findDisplay 142351) displayCtrl 1800;
        _quantityEntry ctrlShow true;

        if (_viewMode == 0) then {
            private _structuredText = parseText format["<t size='2.0' color='#00ff00'>Money: %1</t>", _inventoryMoney];
            private _moneyText = (findDisplay 142351) displayCtrl 1001;
            _moneyText ctrlSetStructuredText _structuredText;

            _structuredText = parseText format["<t size='2.0' color='#ffffff'>%1</t><br/>
            <br/><t>class: </t><t color='#ffff00'>%2</t>
            <br/><t>inventory quantity: </t><t color='#ffff00'>%3</t>
            <br/><t>weight: </t><t color='#ffff00'>%4</t>
            <br/><t>sell price (nominal): </t><t color='#ffff00'>%5</t>
            <br/><t>purchase price: </t><t color='#ffff00'>%6</t>
            <br/><t>quantity on market: </t><t color='#ffff00'>%7</t>
            <br/><br/><t>ammo count: </t><t color='#ffff00'>%8</t>
            <br/><t>type: </t><t color='#ffff00'>%9</t>
            <br/><t>current amount of this type: </t><t color='#ffff00'>%10</t>
            <br/><br/><t>current market saturation (nominal): </t><t color='#ffff00'>%11</t>
            <br/><t>market saturation extra taxes:</t>
            <br/>",
            _displayName, _selectedItemClass, _selectedItemQuantity, _weightKg, _sellPrice, _purchasePrice, _availableQuantityOnMarket, _selectedItemState, _customCategory, _currentAmountOfTypeText, _inventoryMarketSaturation];

            for "_i" from 0 to ((count _marketSaturation) - 1) do {
                private _currentMarketSaturation = _marketSaturation select _i;
                private _currentStructuredText = parseText format["<t color='#ffff00' size='0.75'>$%1</t><t size='0.75'> - </t><t color='#00cdff' size='0.75'>%2%3</t><br/>", _currentMarketSaturation select 0, _currentMarketSaturation select 1, "%"];
                _structuredText = composeText [_structuredText, _currentStructuredText];
            };

            private _itemTypeLimitText = parseText format["<br/><t>item types with limits:</t><br/>"];
            _structuredText = composeText [_structuredText, _itemTypeLimitText];

            for "_i" from 0 to ((count _itemTypeCountAndLimit) - 1) do {
                private _itemTypeCountAndLimitEntry = _itemTypeCountAndLimit select _i;
                private _currentStructuredText = parseText format["<t color='#ffff00' size='0.75'>%1</t><t size='0.75'> - </t><t color='#00cdff' size='0.75'>%2 of %3</t><br/>", _itemTypeCountAndLimitEntry select 0, _itemTypeCountAndLimitEntry select 1, _itemTypeCountAndLimitEntry select 2];
                _structuredText = composeText [_structuredText, _currentStructuredText];
            };

            private _itemTextCtrl = (findDisplay 142351) displayCtrl 1000;
            _itemTextCtrl ctrlSetStructuredText _structuredText;

            private _sellButton = (findDisplay 142351) displayCtrl 1600;
            _sellButton ctrlShow true;

            private _sellButtonText =  parseText format ["sell %1:<br/>%2", _editQuantity, _sellPriceWithSaturation];
            _sellButton ctrlSetStructuredText _sellButtonText;
            if(_editQuantity > _selectedItemQuantity) then {
                _sellButton ctrlEnable false;
            } else {
                _sellButton ctrlEnable true;
            };

            private _buyButton = (findDisplay 142351) displayCtrl 1601;

            private _buyButtonext =  parseText format ["buy %1:<br/>%2", _editQuantity, (_purchasePrice * _editQuantity)];
            if(_purchasePrice == -1) then {
                _buyButtonext =  parseText format ["buy %1:<br/>%2", _editQuantity, _purchasePrice];
            };
            _buyButton ctrlSetStructuredText _buyButtonext;
            _buyButton ctrlShow true;

            if((_purchasePrice == (-1)) or ((_purchasePrice * _editQuantity) > _inventoryMoney) or ((_allowedBuyingQuantity < _editQuantity) && (_itemLimit != (-1)))) then {
                _buyButton ctrlEnable false;
            } else {
                _buyButton ctrlEnable true;
            };

            private _retrieveButton = (findDisplay 142351) displayCtrl 1602;
            _retrieveButton ctrlShow true;
            private _retrieveButtonText = parseText format ["Retrieve<br/>%1", _editQuantity];
            _retrieveButton ctrlSetStructuredText _retrieveButtonText;

            private _retrieveAllButton = (findDisplay 142351) displayCtrl 1603;
            _retrieveAllButton ctrlShow true;
            private _retrieveAllButtonText = parseText format ["Retrieve<br/>All Items"];
            _retrieveAllButton ctrlSetStructuredText _retrieveAllButtonText;

            if(_editQuantity > _selectedItemQuantity) then {
                _retrieveButton ctrlEnable false;
            } else {
                _retrieveButton ctrlEnable true;
            };
        };
        if (_viewMode == 1) then {
            private _structuredText = parseText format["<t size='2.0' color='#00ff00'>Money: %1</t>", _inventoryMoney];
            private _moneyText = (findDisplay 142351) displayCtrl 1001;
            _moneyText ctrlSetStructuredText _structuredText;

            _structuredText = parseText format["<t size='2.0' color='#ffffff'>%1</t>
            <br/><br/><t>class: </t><t color='#ffff00'>%2</t>
            <br/><t>weight: </t><t color='#ffff00'>%3</t>
            <br/><t>sell price: </t><t color='#ffff00'>%4</t>
            <br/><t>purchase price: </t><t color='#ffff00'>%5</t>
            <br/><t>available quantity: </t><t color='#ffff00'>%6</t>
            <br/><t>type: </t><t color='#ffff00'>%7</t>
            <br/><t>current amount of this type: </t><t color='#ffff00'>%8</t>",
            _displayName, _selectedItemClass, _weightKg, _sellPrice, _purchasePrice, _availableQuantityOnMarket, _customCategory, _currentAmountOfTypeText];

            private _itemTextCtrl = (findDisplay 142351) displayCtrl 1000;
            _itemTextCtrl ctrlSetStructuredText _structuredText;

            private _sellButton = (findDisplay 142351) displayCtrl 1600;
            _sellButton ctrlShow false;

            private _buyButton = (findDisplay 142351) displayCtrl 1601;
            private _buyButtonext =  parseText format ["buy %1:<br/>%2", _editQuantity, (_purchasePrice * _editQuantity)];
            _buyButton ctrlSetStructuredText _buyButtonext;
            _buyButton ctrlShow true;
            if((_purchasePrice == (-1)) or ((_purchasePrice * _editQuantity) > _inventoryMoney) or ((_allowedBuyingQuantity < _editQuantity) && (_itemLimit != (-1)))) then {
                _buyButton ctrlEnable false;
            } else {
                _buyButton ctrlEnable true;
            };
            private _retrieveButton = (findDisplay 142351) displayCtrl 1602;
            _retrieveButton ctrlShow false;

            private _retrieveAllButton = (findDisplay 142351) displayCtrl 1603;
            _retrieveAllButton ctrlShow false;
        };

        if((_availableQuantityOnMarket < _editQuantity) && (_availableQuantityOnMarket != -1)) then {
            private _buyButton = (findDisplay 142351) displayCtrl 1601;
            _buyButton ctrlEnable false;
        };
    };
    if (_viewMode == 2) then {
        private _structuredText = parseText format["<t size='2.0' color='#00ff00'>Money: %1</t>", _inventoryMoney];
        private _moneyText = (findDisplay 142351) displayCtrl 1001;
        _moneyText ctrlSetStructuredText _structuredText;

        private _quantityEntry = (findDisplay 142351) displayCtrl 1800;
        _quantityEntry ctrlShow true;

        private _imagePath = [(_moneyTypes select _selectedIndex) select 0] call fn_getImagePathOfClass;

        _structuredText = parseText format["<t size='2.0'>Bill: </t><t color='#ffff00' size='2.0'>$%1</t>
        <br/><br/><t>class: </t><t color='#ffff00'>%2</t>
        <br/><img size='4' image='%3'/>",
        ((_moneyTypes select _selectedIndex) select 1), ((_moneyTypes select _selectedIndex) select 0), _imagePath];
        
        private _itemTextCtrl = (findDisplay 142351) displayCtrl 1000;
        _itemTextCtrl ctrlSetStructuredText _structuredText;

        private _sellButton = (findDisplay 142351) displayCtrl 1600;
        _sellButton ctrlShow false;

        private _buyButton = (findDisplay 142351) displayCtrl 1601;
        _buyButton ctrlShow false;

        private _retrieveButton = (findDisplay 142351) displayCtrl 1602;
        _retrieveButton ctrlShow true;
        if((((_moneyTypes select _selectedIndex) select 1) * _editQuantity) <= _inventoryMoney) then {
            _retrieveButton ctrlEnable true;
        } else {
            _retrieveButton ctrlEnable false;
        };
        private _retrieveButtonText = parseText format ["Retrieve<br/>%1", _editQuantity];
        _retrieveButton ctrlSetStructuredText _retrieveButtonText;

        private _retrieveAllButton = (findDisplay 142351) displayCtrl 1603;
        _retrieveAllButton ctrlShow true;
        private _retrieveAllButtonText = parseText format ["Retrieve<br/>All"];
        _retrieveAllButton ctrlSetStructuredText _retrieveAllButtonText;
    };
    if (_viewMode == 3 || _viewMode == 4) then {
        private _prices = [] call fn_getPricesVehicles;
        private _sellPrice = _prices select 1;
        private _purchasePrice = _prices select 0;

        private _quantityEntry = (findDisplay 142351) displayCtrl 1800;
        _quantityEntry ctrlShow false;

        uiNamespace setVariable ["PIMS_quantity", 1];

        if (_viewMode == 3) then {
            private _selectedVehicle = (_listOfVehicles select _selectedIndex);
            private _selectedVehicleClass = _selectedVehicle select 2;
            private _selectedVehicleFuel = _selectedVehicle select 3;
            private _selectedVehicleHitpoints = _selectedVehicle select 4;
            private _selectedVehicleAceCargo = _selectedVehicle select 5;
            private _selectedVehicleAmmo = _selectedVehicle select 6;
            _displayName = [_selectedVehicleClass] call fn_getDisplayNameOfClass;

            private _structuredText = parseText format["<t size='2.0' color='#00ff00'>Money: %1</t>", _inventoryMoney];
            private _moneyText = (findDisplay 142351) displayCtrl 1001;
            _moneyText ctrlSetStructuredText _structuredText;

            _structuredText = parseText format["<t size='2.0' color='#ffffff'>%1</t>
            <br/><br/><t>class: </t><t color='#ffff00'>%2</t>
            <br/><t>sell price: </t><t color='#ffff00'>%3</t>
            <br/><t>purchase price: </t><t color='#ffff00'>%4</t>
            <br/><br/><t>fuel: </t><t color='#ffff00'>%5</t>
            <br/><t>Ace Cargo: </t><t color='#ffff00'>%6</t>
            <br/><t size='0.5'>damage: </t><t color='#ffff00'>%7</t>
            <br/><t size='0.5'>ammo: </t><t color='#ffff00'>%8</t>",
            _displayName, _selectedVehicleClass, _sellPrice, _purchasePrice, _selectedVehicleFuel, _selectedVehicleAceCargo, _selectedVehicleHitpoints, _selectedVehicleAmmo];
            
            private _itemTextCtrl = (findDisplay 142351) displayCtrl 1000;
            _itemTextCtrl ctrlSetStructuredText _structuredText;

            private _sellButton = (findDisplay 142351) displayCtrl 1600;
            _sellButton ctrlShow true;

            private _sellButtonText =  parseText format ["sell:<br/>%1", _sellPrice]; //TODO implement fn_getPricesWithSaturation but with vehicels.
            _sellButton ctrlSetStructuredText _sellButtonText;
            _sellButton ctrlEnable true;

            private _buyButton = (findDisplay 142351) displayCtrl 1601;
            _buyButton ctrlShow false;

            private _retrieveButton = (findDisplay 142351) displayCtrl 1602;
            _retrieveButton ctrlShow true;
            private _retrieveButtonText = parseText format ["Retrieve"];
            _retrieveButton ctrlSetStructuredText _retrieveButtonText;
            _retrieveButton ctrlEnable true;

            private _retrieveAllButton = (findDisplay 142351) displayCtrl 1603;
            _retrieveAllButton ctrlShow false;
        };
        if (_viewMode == 4) then {
            private _selectedVehicle = (_vehicleMarket select _selectedIndex);
            private _selectedVehicleClass = _selectedVehicle select 1;
            private _selectedVehicleFuel = 1;
            private _selectedVehicleHitpoints = [];
            private _selectedVehicleAceCargo = [];
            private _selectedVehicleAmmo = [];
            private _selectedInventory = _allInventories select _selectedIndex;
            _displayName = [_selectedVehicleClass] call fn_getDisplayNameOfClass;

            private _quantityEntry = (findDisplay 142351) displayCtrl 1800;
            _quantityEntry ctrlShow true;

            private _structuredText = parseText format["<t size='2.0' color='#00ff00'>Money: %1</t>", (_selectedInventory select 2)];
            private _moneyText = (findDisplay 142351) displayCtrl 1001;
            _moneyText ctrlSetStructuredText _structuredText;

            _structuredText = parseText format["<t size='2.0' color='#ffffff'>%1</t>
            <br/><br/><t>class: </t><t color='#ffff00'>%2</t>
            <br/><t>sell price: </t><t color='#ffff00'>%3</t>
            <br/><t>purchase price: </t><t color='#ffff00'>%4</t>
            <br/><br/><t>fuel: </t><t color='#ffff00'>%5</t>
            <br/><t size='0.5'>Ace Cargo: </t><t color='#ffff00'>%6</t>
            <br/><br/><t size='0.5'>damage: </t><t color='#ffff00'>%7</t>
            <br/><br/><t size='0.5'>ammo: </t><t color='#ffff00'>%8</t>",
            _displayName, _selectedVehicleClass, _sellPrice, _purchasePrice, _selectedVehicleFuel, _selectedVehicleAceCargo, _selectedVehicleHitpoints, _selectedVehicleAmmo];
            
            private _itemTextCtrl = (findDisplay 142351) displayCtrl 1000;
            _itemTextCtrl ctrlSetStructuredText _structuredText;

            private _sellButton = (findDisplay 142351) displayCtrl 1600;
            _sellButton ctrlShow false;

            private _retrieveButton = (findDisplay 142351) displayCtrl 1602;
            _retrieveButton ctrlShow false;

            private _buyButton = (findDisplay 142351) displayCtrl 1601;
            private _buyButtonext =  parseText format ["buy:<br/>%1", _purchasePrice];
            _buyButton ctrlSetStructuredText _buyButtonext;
            _buyButton ctrlShow true;
            if((_purchasePrice == (-1)) || (_purchasePrice > _inventoryMoney)) then {
                _buyButton ctrlEnable false;
            } else {
                _buyButton ctrlEnable true;
            };

            private _retrieveAllButton = (findDisplay 142351) displayCtrl 1603;
            _retrieveAllButton ctrlShow false;

            //TODO vehicle market (test)
        };
    };
    if (_viewMode == 5) then {
        private _selectedInventory = _allInventories select _selectedIndex;
        private _structuredText = parseText format["<t size='2.0' color='#00ff00'>Money: %1</t>", (_selectedInventory select 2)];
        private _moneyText = (findDisplay 142351) displayCtrl 1001;
        _moneyText ctrlSetStructuredText _structuredText;

        private _quantityEntry = (findDisplay 142351) displayCtrl 1800;
        _quantityEntry ctrlShow true;

        private _itemsInThisInventory = [];
        for "_i" from 0 to ((count _allContentItems) - 1) do {
            if(((_allContentItems select _i) select 1) == (_selectedInventory select 0)) then {
                _itemsInThisInventory pushBack (_allContentItems select _i);
            };
        };
        _structuredText = parseText format["<t size='0.5' color='#00ff00'>%1</t>", _itemsInThisInventory];
        private _itemTextCtrl = (findDisplay 142351) displayCtrl 1000;
        _itemTextCtrl ctrlSetStructuredText _structuredText;
        
        private _sellButton = (findDisplay 142351) displayCtrl 1600;
        private _sellButtonext =  parseText format ["remove:<br/>%1",  _editQuantity];
        _sellButton ctrlSetStructuredText _sellButtonext;
        _sellButton ctrlShow true;
        _sellButton ctrlEnable true;

        private _buyButton = (findDisplay 142351) displayCtrl 1601;
        private _buyButtonext =  parseText format ["give:<br/>%1", _editQuantity];
        _buyButton ctrlSetStructuredText _buyButtonext;
        _buyButton ctrlShow true;
        _buyButton ctrlEnable true;

        private _retrieveButton = (findDisplay 142351) displayCtrl 1602;
        _retrieveButton ctrlShow false;

        private _retrieveAllButton = (findDisplay 142351) displayCtrl 1603;
        _retrieveAllButton ctrlShow false;
    };

    if(!_areMarketsEnabled) then {
        private _sellButton = (findDisplay 142351) displayCtrl 1600;
        private _sellButtonText =  parseText format ["Markets<br/>Disabled"];
        _sellButton ctrlSetStructuredText _sellButtonText;
        _sellButton ctrlEnable false;

        private _buyButton = (findDisplay 142351) displayCtrl 1601;
        private _buyButtonText =  parseText format ["Markets<br/>Disabled"];
        _buyButton ctrlSetStructuredText _buyButtonText;
        _buyButton ctrlEnable false;
    };

    //_string = format ["PIMS DEBUG: gui detailText changed"];
    //[_string] remoteExec ["systemChat", 0];
};

fn_getAvailableMarketQuantity = {
    params ["_itemClass"];
    private _selectedIndex = uiNamespace getVariable ["PIMS_selectedIndex", "None"];
    private _listOfItems = uiNamespace getVariable ["PIMS_listOfItems", "None"];
    private _market = uiNamespace getVariable ["PIMS_market", []];
    private _availableQuantity = 0;

    //_string = format ["PIMS DEBUG: fn_getAvailableMarketQuantity. _itemClass: %1", _itemClass];
    //[_string] remoteExec ["systemChat", 0];
    //_string = format ["PIMS DEBUG: fn_getAvailableMarketQuantity. count _market: %1", count _market];
    //[_string] remoteExec ["systemChat", 0];

    for "_i" from 0 to ((count _market) - 1) do {
        private _marketEntry = _market select _i;
        if((_marketEntry select 1) isEqualTo _itemClass) then {
            _availableQuantity = _marketEntry select 5;
            //_string = format ["PIMS DEBUG: fn_getAvailableMarketQuantity. _marketEntry: %1", _marketEntry];
            //[_string] remoteExec ["systemChat", 0];
        };
    };
    _availableQuantity;
};

fn_getPrices = {
    //_string = format ["PIMS DEBUG: fn_getPurchasePrice called."];
    //[_string] remoteExec ["systemChat", 0];
    private _purchasePrice = -1;
    private _sellingPrice = 0;
    private _selectedIndex = uiNamespace getVariable ["PIMS_selectedIndex", "None"];
    private _listOfItems = uiNamespace getVariable ["PIMS_listOfItems", "None"];
    private _market = uiNamespace getVariable ["PIMS_market", []];
    private _viewMode = uiNamespace getVariable ["PIMS_ViewMode", 0];

    //_selectedItem = _listOfItems select _selectedIndex;
    //_selectedItemState = _selectedItem select 4;
    //_selectedItemClass = _selectedItem select 2;
    //_configPathAndParent = [_selectedItemClass] call fn_getConfigPathAndParentPath;
    //_configPath = _configPathAndParent select 0;
    //_parentPath = _configPathAndParent select 1;

    private _configPath = "";
    private _parentPath = "";
    private _selectedItemState = "";
    private _selectedItemClass = "";

    private _selectedItemClass = "";
    if(_viewMode == 0) then {
        private _selectedItem = (_listOfItems select _selectedIndex);
        _selectedItemClass = _selectedItem select 2;
        _selectedItemState = _selectedItem select 4;
        private _configPathAndParent = [_selectedItemClass] call fn_getConfigPathAndParentPath;
        _configPath = _configPathAndParent select 0;
        _parentPath = _configPathAndParent select 1;
    };
    if(_viewMode == 1) then {
        _selectedItemClass = (_market select _selectedIndex) select 1;
    };
    for "_i" from 0 to ((count _market) - 1) do {
        private _marketEntry = _market select _i;
        if((_marketEntry select 1) isEqualTo _selectedItemClass) then {
            _purchasePrice = _marketEntry select 2;
            _sellingPrice = _marketEntry select 3;
        };
    };

    if(_viewMode == 0 && _parentPath == "CfgMagazines") then {
        private _magazineCapacity = getNumber (_configPath >> "count");
        _selectedItemState = parseNumber _selectedItemState;
        //_string = format ["PIMS DEBUG: _magazineCapacity: %1, _selectedItemState: %2", _magazineCapacity, _selectedItemState];
        //[_string] remoteExec ["systemChat", 0];
        _sellingPrice = (_sellingPrice / _magazineCapacity) * _selectedItemState;
    };

    private _priceList = [_purchasePrice, _sellingPrice];
    //_string = format ["PIMS DEBUG: _priceList: %1", _priceList];
    //[_string] remoteExec ["systemChat", 0];
    _priceList;
};

fn_getPricesWithSaturation = {
    params ["_quantity"];
    //_string = format ["PIMS DEBUG: fn_getPricesWithSaturation called."];
    //[_string] remoteExec ["systemChat", 0];
    private _prices = [] call fn_getPrices;
    private _uid = getPlayerUID player;
    private _marketSaturation = uiNamespace getVariable ["PIMS_marketSaturation", []];
    private _marketSaturationZero = [[0, 0]];

    //_string = format ["PIMS DEBUG: fn_getPricesWithSaturation. _marketSaturation: %1", _marketSaturation];
    //[_string] remoteExec ["systemChat", 0];
    //_string = format ["PIMS DEBUG: fn_getPricesWithSaturation. _marketSaturationZero: %1", _marketSaturationZero];
    //[_string] remoteExec ["systemChat", 0];

    _marketSaturationZero append _marketSaturation;
    _marketSaturation = _marketSaturationZero;
    _marketSaturation append [[1e15, 100]];
    private _inventoryMarketSaturation = uiNamespace getVariable ["PIMS_InventoryMarketSaturation", 0];

    //_string = format ["PIMS DEBUG: fn_getPricesWithSaturation. _quantity: %1", _quantity];
    //[_string] remoteExec ["systemChat", 0];
    //_string = format ["PIMS DEBUG: fn_getPricesWithSaturation. _prices: %1", _prices];
    //[_string] remoteExec ["systemChat", 0];
    //_string = format ["PIMS DEBUG: fn_getPricesWithSaturation. _inventoryMarketSaturation: %1", _inventoryMarketSaturation];
    //[_string] remoteExec ["systemChat", 0];
    //_string = format ["PIMS DEBUG: fn_getPricesWithSaturation. _marketSaturation: %1", _marketSaturation];
    //[_string] remoteExec ["systemChat", 0];

    private _remaining = (_prices select 1) * _quantity;
    private _currentInventorySaturation = _inventoryMarketSaturation;
    private _sellingPrice = 0;
    private _currentMarketSaturationIndex = 0;
    private _currentMarketSaturationTax = 0;
    private _currentMarketSaturation = _marketSaturation select _currentMarketSaturationIndex;

    while {_remaining > 0} do {
        if((_currentInventorySaturation >= (_currentMarketSaturation select 0)) && ((_currentMarketSaturationIndex + 1) < (count _marketSaturation))) then {
            _currentMarketSaturationTax = _currentMarketSaturation select 1;
            _currentMarketSaturationIndex = _currentMarketSaturationIndex + 1;
            _currentMarketSaturation = _marketSaturation select _currentMarketSaturationIndex;
            //_string = format ["PIMS DEBUG: fn_getPricesWithSaturation _currentMarketSaturation: %1, _currentMarketSaturationTax: %2, _currentMarketSaturationIndex: %3", _currentMarketSaturation, _currentMarketSaturationTax, _currentMarketSaturationIndex];
            //[_string] remoteExec ["systemChat", 0];
        } else {
            //_string = format ["PIMS DEBUG: fn_getPricesWithSaturation _currentMarketSaturation: %1, _currentInventorySaturation: %2, _remaining: %3", _currentMarketSaturation, _currentInventorySaturation, _remaining];
            //[_string] remoteExec ["systemChat", 0];
            private _difference = selectMin[((_currentMarketSaturation select 0) - _currentInventorySaturation), _remaining];
            _currentInventorySaturation = _currentInventorySaturation + _difference;
            private _priceIncrease = round  (_difference * ((100 - _currentMarketSaturationTax) / 100));
            _sellingPrice = _sellingPrice + _priceIncrease;
            _remaining = _remaining - _difference;
            if(_difference == 0) then {
                _string = format ["PIMS ERROR: _difference equals zero."];
                [_string] remoteExec ["systemChat", 0];
                break;
            };
        };
    };

    private _priceList = [_prices select 0, _sellingPrice];
    //_string = format ["PIMS DEBUG: fn_getPricesWithSaturation output: %1.", _priceList];
    //[_string] remoteExec ["systemChat", 0];
    _priceList;
};

fn_getPricesVehicles = {
    private _purchasePrice = -1;
    private _sellingPrice = 0;
    private _selectedIndex = uiNamespace getVariable ["PIMS_selectedIndex", "None"];
    private _vehicleMarket = uiNamespace getVariable ["PIMS_vehicleMarket", []];
    private _viewMode = uiNamespace getVariable ["PIMS_ViewMode", 0];
    private _listOfVehicles = uiNamespace getVariable ["PIMS_listOfVehicles", []];

    private _selectedVehicleClass = "";

    if(_viewMode == 0) then {
        private _selectedVehicle = (_listOfVehicles select _selectedIndex);
        _selectedVehicleClass = _selectedVehicle select 2;
    };
    if(_viewMode == 1) then {
        _selectedVehicleClass = (_vehicleMarket select _selectedIndex) select 1;
    };

    for "_i" from 0 to ((count _vehicleMarket) - 1) do {
        private _marketEntry = _vehicleMarket select _i;
        if((_marketEntry select 1) isEqualTo _selectedVehicleClass) then {
            _purchasePrice = _marketEntry select 2;
            _sellingPrice = _marketEntry select 3;
        };
    };
    private _priceList = [_purchasePrice, _sellingPrice];
    _priceList;
};

fn_getDisplayNameOfClass = {
    params ["_selectedItemClass"];
    //_string = format ["PIMS DEBUG: fn_getDisplayNameOfClass called. _selectedItemClass: %1", _selectedItemClass];
    //[_string] remoteExec ["systemChat", 0];
    private _configPathAndParent = [_selectedItemClass] call fn_getConfigPathAndParentPath;
    private _configPath = _configPathAndParent select 0;
    private _displayName = _selectedItemClass;
    _displayName = [_configPath] call BIS_fnc_displayName;
    //_string = format ["PIMS DEBUG: fn_getDisplayNameOfClass output: %1", _displayName];
    //[_string] remoteExec ["systemChat", 0];
    _displayName;
};

fn_getImagePathOfClass = {
    params ["_selectedItemClass"];
    //_string = format ["PIMS DEBUG: fn_getImagePathOfClass called. _selectedItemClass: %1.", _selectedItemClass];
    //[_string] remoteExec ["systemChat", 0];
    private _configPathAndParent = [_selectedItemClass] call fn_getConfigPathAndParentPath;
    private _configPath = _configPathAndParent select 0;
    private _picturePath = "";
    //_string = format ["PIMS DEBUG: fn_getImagePathOfClass. _configPath: %1.", _configPath];
    //[_string] remoteExec ["systemChat", 0];
    if(not (_configPath isEqualTo "")) then {
        //_string = format ["PIMS DEBUG: fn_getImagePathOfClass. _configPath is not empty."];
        //[_string] remoteExec ["systemChat", 0];
        _picturePath = getText (_configPath >> "picture");
    };
    //_string = format ["PIMS DEBUG: fn_getImagePathOfClass output: %1.", _picturePath];
    //[_string] remoteExec ["systemChat", 0];
    _picturePath;
};

fn_getWeightOfClass = {
    params ["_selectedItemClass"];
    //_string = format ["PIMS DEBUG: fn_getWeightOfClass called. _selectedItemClass: %1", _selectedItemClass];
    //[_string] remoteExec ["systemChat", 0];
    private _configPathAndParent = [_selectedItemClass] call fn_getConfigPathAndParentPath;
    private _configPath = _configPathAndParent select 0;
    private _parentPath = _configPathAndParent select 1;
    private _itemMass = 0;
    if(not (_configPath isEqualTo "")) then {
        if(_parentPath == "CfgWeapons") then {
            _itemMass = getNumber (_configPath >> "WeaponSlotsInfo" >> "mass");
        };
        if(_parentPath == "CfgMagazines") then {
            _itemMass = getNumber (_configPath >> "mass");
        };
        if(_itemMass == 0) then {
            _itemMass = getNumber (_configPath >> "ItemInfo" >> "mass");
        };
    };
    private _weightKg = _itemMass * 0.1;
    //_string = format ["PIMS DEBUG: fn_getWeightOfClass output: %1", _weightKg];
    //[_string] remoteExec ["systemChat", 0];
    _weightKg;
};

fn_getConfigPathAndParentPath = {
    params ["_selectedItemClass"];
    //_string = format ["PIMS DEBUG: fn_getConfigPathAndParentPath called. _selectedItemClass: %1", _selectedItemClass];
    //[_string] remoteExec ["systemChat", 0];
    private _configPath = "";
    private _parentPath = "";
    if (isClass (configFile >> "CfgWeapons" >> _selectedItemClass)) then {
        _configPath = configFile >> "CfgWeapons" >> _selectedItemClass;
        _parentPath = "CfgWeapons";
    } else {
        if (isClass (configFile >> "CfgMagazines" >> _selectedItemClass)) then {
            _configPath = configFile >> "CfgMagazines" >> _selectedItemClass;
            _parentPath = "CfgMagazines";
        } else {
            if (isClass (configFile >> "CfgVehicles" >> _selectedItemClass)) then {
                _configPath = configFile >> "CfgVehicles" >> _selectedItemClass;
                _parentPath = "CfgVehicles";
            } else {
                if (isClass (configFile >> "CfgGlasses" >> _selectedItemClass)) then {
                    _configPath = configFile >> "CfgGlasses" >> _selectedItemClass;
                    _parentPath = "CfgGlasses";
               };
            };
        };
    };
    //_string = format ["fn_getConfigPathAndParentPath output: %1, %2", _configPath, _parentPath];
    //[_string] remoteExec ["systemChat", 0];
    private _result = [_configPath, _parentPath];
    _result;
};


fn_removeOneItemFromInventory = {
    params ["_index", "_quantity"];
    //_string = format ["PIMS DEBUG: fn_removeOneItemFromInventory called. _quantity: %1", _quantity];
    //[_string] remoteExec ["systemChat", 0];
    
    private _listOfItems = uiNamespace getVariable ["PIMS_listOfItems", "None"];
    private _selectedItem = _listOfItems select _index;
    private _selectedItemClass = _selectedItem select 2;
    private _selectedItemQuantity = _selectedItem select 3;
    private _selectedItemState = _selectedItem select 4;
    private _selectedItemId = _selectedItem select 0;
    private _ctrl2 = (findDisplay 142351) displayCtrl 1500;

    if(_selectedItemQuantity > _quantity) then {
        private _currentItem = _listOfItems select _index;
        private _newText = (str _selectedItemQuantity) + "x " + _selectedItemClass;
        private _currentItem set [3, (_selectedItemQuantity - _quantity)];
        _listOfItems set [_index, _currentItem];
        private _value = [_index] call fn_convertDbItemToText;
        _ctrl2 lbSetText [_index, _value];
    } else {
        _ctrl2 lbDelete (_index);
        _listOfItems deleteAt _index;
    };
    //_string = format ["PIMS DEBUG: calling PIMS_fnc_PIMSRemoveItemFromDatabase._selectedItemId: %1, _quantity2: %2", _selectedItemId, _quantity2];
    //[_string] remoteExec ["systemChat", 0];
    [_selectedItemId, _quantity] remoteExec ["PIMS_fnc_PIMSRemoveItemFromDatabase", 2];
};

fn_updateInfo = {
    private _inventoryId = uiNamespace getVariable ["PIMS_inventoryId", "None"];

    private _oldListOfItems = uiNamespace getVariable ["PIMS_listOfItems", []];
    private _oldMoney = uiNamespace getVariable ["PIMS_inventoryMoney", 0];
    private _oldMarket = uiNamespace getVariable ["PIMS_market", []];
    private _oldAllInventories = uiNamespace getVariable ["PIMS_allInventories", []];
    private _oldAllContentItems = uiNamespace getVariable ["PIMS_allContentItems", []];
    private _oldIsAdmin = uiNamespace getVariable ["PIMS_isAdmin", false];
    private _oldAllVehicles = uiNamespace getVariable ["PIMS_allVehicles", []];
    private _oldListOfVehicles = uiNamespace getVariable ["PIMS_listOfVehicles", []];
    private _oldVehicleMarket = uiNamespace getVariable ["PIMS_vehicleMarket", []];
    private _oldMarketSaturation = uiNamespace getVariable ["PIMS_marketSaturation", []];
    private _oldInventoryMarketSaturation = uiNamespace getVariable ["PIMS_InventoryMarketSaturation", 0];
    private _oldInventoryItemLimit = uiNamespace getVariable ["PIMS_InventoryTypeLimit", []];
    private _oldCustomItemTypes = uiNamespace getVariable ["PIMS_CustomItemTypes", []];

    private _uid = getPlayerUID player;
    [_uid, _inventoryId] remoteExec ["PIMS_fnc_PIMSUpdateGuiInfoForPlayer", 2];

    //sleep 1;

    waitUntil {(missionNamespace getVariable ["PIMSDone" + _uid, false])};
    missionNamespace setVariable ["PIMSDone" + _uid, false, true];

    private _listOfItems = missionNamespace getVariable ["PIMSListOfItems" + _uid, _oldListOfItems];
    private _money = missionNamespace getVariable ["PIMSMoney" + _uid, _oldMoney];
    private _market = missionNamespace getVariable ["PIMSMarket" + _uid, _oldMarket];
    private _allInventories = missionNamespace getVariable ["PIMSAllInventories" + _uid, _oldAllInventories];
    private _allContentItems = missionNamespace getVariable ["PIMSAllContentItems" + _uid, _oldAllContentItems];
    private _isAdmin = missionNamespace getVariable ["PIMSIsAdmin" + _uid, _oldIsAdmin];
    private _allVehicles = missionNamespace getVariable ["PIMSAllVehicles" + _uid, _oldAllVehicles];
    private _listOfVehicles = missionNamespace getVariable ["PIMSListOfVehicles" + _uid, _oldListOfVehicles];
    private _vehicleMarket = missionNamespace getVariable ["PIMSVehicleMarket" + _uid, _oldVehicleMarket];
    private _marketSaturation = missionNamespace getVariable ["PIMSMarketSaturation" + _uid, _oldMarketSaturation];
    private _inventoryMarketSaturation = missionNamespace getVariable ["PIMSInventoryMarketSaturation" + _uid, _oldInventoryMarketSaturation];
    private _inventoryItemLimit = missionNamespace getVariable ["PIMSInventoryTypeLimit" + _uid, _oldInventoryItemLimit];
    private _customItemTypes = missionNamespace getVariable ["PIMSCustomItemTypes" + _uid, _oldCustomItemTypes];

    //_string = format ["PIMS DEBUG: fn_updateInfo: count _listOfItems: %1, count _market: %2, _money: %3, count _allInventories %4, count _allContentItems: %5, _isAdmin: %6", count _listOfItems, count _market, _money, count _allInventories, count _allContentItems, _isAdmin];
    //[_string] remoteExec ["systemChat", 0];

    uiNamespace setVariable ["PIMS_listOfItems", _listOfItems];
    uiNamespace setVariable ["PIMS_market", _market];
    uiNamespace setVariable ["PIMS_inventoryMoney", _money];
    uiNamespace setVariable ["PIMS_allInventories", _allInventories];
    uiNamespace setVariable ["PIMS_allContentItems", _allContentItems];
    uiNamespace setVariable ["PIMS_isAdmin", _isAdmin];
    uiNamespace setVariable ["PIMS_allVehicles", _allVehicles];
    uiNamespace setVariable ["PIMS_listOfVehicles", _listOfVehicles];
    uiNamespace setVariable ["PIMS_vehicleMarket", _vehicleMarket];
    uiNamespace setVariable ["PIMS_marketSaturation", _marketSaturation];
    uiNamespace setVariable ["PIMS_InventoryMarketSaturation", _inventoryMarketSaturation];
    uiNamespace setVariable ["PIMS_InventoryTypeLimit", _inventoryItemLimit];
    uiNamespace setVariable ["PIMS_CustomItemTypes", _customItemTypes];

    missionNamespace setVariable ["PIMSListOfItems" + _uid, nil, true];
    missionNamespace setVariable ["PIMSMoney" + _uid, nil, true];
    missionNamespace setVariable ["PIMSMarket" + _uid, nil, true];
    missionNamespace setVariable ["PIMSIsAdmin" + _uid, nil, true];
    missionNamespace setVariable ["PIMSAllInventories" + _uid, nil, true];
    missionNamespace setVariable ["PIMSAllContentItems" + _uid, nil, true];
    missionNamespace setVariable ["PIMSAllVehicles" + _uid, nil, true];
    missionNamespace setVariable ["PIMSListOfVehicles" + _uid, nil, true];
    missionNamespace setVariable ["PIMSVehicleMarket" + _uid, nil, true];
    missionNamespace setVariable ["PIMSMarketSaturation" + _uid, nil, true];
    missionNamespace setVariable ["PIMSInventoryMarketSaturation" + _uid, nil, true];
    missionNamespace setVariable ["PIMSInventoryTypeLimit" + _uid, nil, true];
    missionNamespace setVariable ["PIMSCustomItemTypes" + _uid, nil, true];

    //_string = format ["PIMS DEBUG: local Information updated."];
    //[_string] remoteExec ["systemChat", 0];

    //_string = format ["PIMS DEBUG: _listOfVehicles: %1, _allVehicles: %2, _vehicleMarket: %3", _listOfVehicles, _allVehicles, _vehicleMarket];
    //[_string] remoteExec ["systemChat", 0];

    //call fn_updateView; //TODO update smartly (only update necessary elements instead of deleting all and reinserting all)
    //call fn_updateDetailText;
};

fn_currentAmountOFItemsOfCertainType = {
    params ["_type"];
    //_string = format ["PIMS DEBUG: fn_currentAmountOFItemsOfCertainType. _type: %1.", _type];
    //[_string] remoteExec ["systemChat", 0];
    private _listOfItems = uiNamespace getVariable ["PIMS_listOfItems", []];
    private _customItemTypes = uiNamespace getVariable ["PIMS_CustomItemTypes", []];

    private _itemCount = 0;
    {
        private _category = ([_x select 2] call BIS_fnc_itemType) select 1;
        private _customCategory = _category;
        {
            if((_x select 1) isEqualTo _category) then {
                _customCategory = (_x select 2);
                break;
            };
        } forEach _customItemTypes;
        if(_type isEqualTo _customCategory) then {
            _itemCount = _itemCount + (_x select 3);
        };
    } forEach _listOfItems;

    _itemCount;
};

fn_getItemTypeCountAndLimit = {
    private _customItemTypes = uiNamespace getVariable ["PIMS_InventoryTypeLimit", []];
    private _itemTypeCountAndLimit = [];
    {
        private _currentAmount = [(_x select 1)] call fn_currentAmountOFItemsOfCertainType;
        _itemTypeCountAndLimit pushback [(_x select 1), _currentAmount, (_x select 2)];
    } forEach _customItemTypes;
    _itemTypeCountAndLimit;
};

onListboxSelectionChanged = {
    params ["_control", "_selectedIndex"];
    //_string = format ["PIMS DEBUG: onListboxSelectionChanged called. _control: %1, _selectedIndex: %2", _control, _selectedIndex];
    //[_string] remoteExec ["systemChat", 0];
    private _selectedText = lbText [1500, _selectedIndex];

    uiNamespace setVariable ["PIMS_selectedItem", _selectedText];
    uiNamespace setVariable ["PIMS_selectedIndex", _selectedIndex];
    [] call fn_updateDetailText;
};

onSellButtonPressed = {
    params ["_control", "_button", "_xPos", "_yPos", "_shift", "_ctrl", "_alt"];
    //_string = format ["PIMS DEBUG: onSellButtonPressed called."];
    //[_string] remoteExec ["systemChat", 0];

    private _sellButton = (findDisplay 142351) displayCtrl 1600;
    _sellButton ctrlEnable false;

    private _uid = uinamespace getvariable ["PIMS_Uid", -1];
    missionNamespace setVariable ["PIMS_updateInfo_" + _uid, true, true];
    waitUntil {(missionNamespace getVariable ["PIMS_updateInfo_" + _uid, false]) == false};
    //[] call fn_updateInfo;

    private _editQuantity = uiNamespace getVariable ["PIMS_quantity", 1];
    private _viewMode = uiNamespace getVariable ["PIMS_ViewMode", "None"];
    private _allInventories = uiNamespace getVariable ["PIMS_allInventories", []];
    private _selectedIndex = uiNamespace getVariable ["PIMS_selectedIndex", "None"];
    private _inventoryId = uiNamespace getVariable ["PIMS_inventoryId", "None"];
    private _inventoryMoney = uiNamespace getVariable ["PIMS_inventoryMoney", 0];
    private _listOfItems = uiNamespace getVariable ["PIMS_listOfItems", "None"];


    if(_viewMode == 0 || _viewMode == 1) then {
        private _price = [] call fn_getPrices;
        private _priceWithSaturation = [_editQuantity] call fn_getPricesWithSaturation;
        uiNamespace setVariable ["PIMS_inventoryMoney", (_inventoryMoney + (_priceWithSaturation select 1))];
        [_inventoryId, (_priceWithSaturation select 1)] remoteExec ["PIMS_fnc_PIMSChangeMoneyOfInventory", 2];
        [_selectedIndex, _editQuantity] call fn_removeOneItemFromInventory;
        [_inventoryId, (_price select 1)] remoteExec ["PIMS_fnc_PIMSIncreaseMarketSaturation", 2];

        private _selectedItem = _listOfItems select _selectedIndex;
        private _selectedItemClass = _selectedItem select 2;

        [_selectedItemClass, _editQuantity] remoteExec ["PIMS_fnc_PIMSChangeMarketAvailableQuantity", 2];
    };
    if(_viewMode == 3) then {
        private _price = [] call fn_getPrices;
        private _priceWithSaturation = [_editQuantity] call fn_getPricesWithSaturation;
        private _listOfVehicles = missionNamespace getVariable ["PIMS_listOfVehicles", []];
        private _vehicleId = (_listOfVehicles select _selectedIndex) select 0;

        uiNamespace setVariable ["PIMS_inventoryMoney", (_inventoryMoney + (_priceWithSaturation select 1))];
        [_inventoryId, (_priceWithSaturation select 1)] remoteExec ["PIMS_fnc_PIMSChangeMoneyOfInventory", 2];
        [_vehicleId] remoteExec ["PIMS_fnc_PIMSRemoveVehicleFromDatabase", 2];
        [_inventoryId, (_price select 1)] remoteExec ["PIMS_fnc_PIMSIncreaseMarketSaturation", 2];
    };
    if(_viewMode == 5) then {
        private _selectedInventory = _allInventories select _selectedIndex;
        private _selectedInventoryId = _selectedInventory select 0;
        if(_selectedInventoryId == _inventoryId) then {
            uiNamespace setVariable ["PIMS_inventoryMoney", (_inventoryMoney - _editQuantity)];
        };
        private _selectedInventoryMoney = _selectedInventory select 2;
        _selectedInventory set [2, (_selectedInventoryMoney + _editQuantity)];
        _allInventories set [_selectedIndex, _selectedInventory];
        uiNamespace setVariable ["PIMS_allInventories", _allInventories];
        [_selectedInventoryId, (_editQuantity * (-1))] remoteExec ["PIMS_fnc_PIMSChangeMoneyOfInventory", 2];
    };
    _sellButton ctrlEnable true;

    missionNamespace setVariable ["PIMS_updateInfo_" + _uid, true, true];
    waitUntil {(missionNamespace getVariable ["PIMS_updateInfo_" + _uid, false]) == false};

    //[] call fn_updateInfo;
    //[] call fn_updateDetailText;
};

onRetrieveButtonPressed = {
    params ["_control", "_button", "_xPos", "_yPos", "_shift", "_ctrl", "_alt"];
    //_string = format ["PIMS DEBUG: onRetrieveButtonPressed called."];
    //[_string] remoteExec ["systemChat", 0];
    private _viewMode = uiNamespace getVariable ["PIMS_ViewMode", "None"];
    private _selectedIndex = uiNamespace getVariable ["PIMS_selectedIndex", "None"];
    private _containerId = uiNamespace getVariable ["PIMS_containerId", "None"];
    private _listOfItems = uiNamespace getVariable ["PIMS_listOfItems", "None"];
    private _editQuantity = uiNamespace getVariable ["PIMS_quantity", 1];
    private _moneyTypes = uiNamespace getVariable ["PIMS_MoneyTypes", []];
    private _inventoryId = uiNamespace getVariable ["PIMS_inventoryId", "None"];
    private _listOfVehicles = uiNamespace getVariable ["PIMS_listOfVehicles", []];

    private _uid = uinamespace getvariable ["PIMS_Uid", -1];
    missionNamespace setVariable ["PIMS_updateInfo_" + _uid, true, true];
    waitUntil {(missionNamespace getVariable ["PIMS_updateInfo_" + _uid, false]) == false};

    if(_viewMode == 0) then {
        private _retrieveButton = (findDisplay 142351) displayCtrl 1602;
        _retrieveButton ctrlEnable false;

        //[] call fn_updateInfo;

        private _selectedItem = _listOfItems select _selectedIndex;
        private _selectedItemClass = _selectedItem select 2;
        private _selectedItemQuantity = _selectedItem select 3;
        private _selectedItemState = _selectedItem select 4;
        private _selectedItemId = _selectedItem select 0;

        [_containerId, _selectedItemId, _selectedItemClass, _selectedItemState, _editQuantity] remoteExec ["PIMS_fnc_PIMSRetrieveItemFromDatabase", 2];
        [_selectedIndex, _editQuantity] call fn_removeOneItemFromInventory;

        uiNamespace setVariable ["PIMS_listOfItems", _listOfItems];

        missionNamespace setVariable ["PIMS_updateInfo_" + _uid, true, true];
        waitUntil {(missionNamespace getVariable ["PIMS_updateInfo_" + _uid, false]) == false};

        //[] call fn_updateInfo;
        //[] call fn_updateDetailText;
        _retrieveButton ctrlEnable true;
    };
    if(_viewMode == 2) then {    
        private _moneyType = (_moneyTypes select _selectedIndex) select 0;
        [_containerId, Nil, _moneyType, "", _editQuantity] remoteExec ["PIMS_fnc_PIMSRetrieveItemFromDatabase", 2];
        [_inventoryId, (((_moneyTypes select _selectedIndex) select 1) * _editQuantity) * (-1)] remoteExec ["PIMS_fnc_PIMSChangeMoneyOfInventory", 2];

        missionNamespace setVariable ["PIMS_updateInfo_" + _uid, true, true];
        waitUntil {(missionNamespace getVariable ["PIMS_updateInfo_" + _uid, false]) == false};
    };
    if(_viewMode == 3) then {
        private _myVehicle = _listOfVehicles select _selectedIndex;
        private _playerNetId = netId player;
        closeDialog 1;
        [_myVehicle, _playerNetId] remoteExec ["PIMS_fnc_PIMSSpawnVehicleMenu", 2];
    };
};

onRetrieveAllButtonPressed = {
    params ["_control", "_button", "_xPos", "_yPos", "_shift", "_ctrl", "_alt"];
    private _listOfItems =[];
    _listOfItems = + (uiNamespace getVariable ["PIMS_listOfItems", []]);
    private _containerId = uiNamespace getVariable ["PIMS_containerId", "None"];
    private _moneyTypes = uiNamespace getVariable ["PIMS_MoneyTypes", []];
    private _inventoryMoney = uiNamespace getVariable ["PIMS_inventoryMoney", 0];
    private _inventoryId = uiNamespace getVariable ["PIMS_inventoryId", "None"];
    private _viewMode = uiNamespace getVariable ["PIMS_ViewMode", "None"];
    if(_viewMode == 0) then {
        for "_i" from ((count _listOfItems) - 1) to 0 step -1 do {
            private _selectedItem = _listOfItems select _i;
            private _selectedItemClass = _selectedItem select 2;
            private _selectedItemQuantity = _selectedItem select 3;
            private _selectedItemState = _selectedItem select 4;
            private _selectedItemId = _selectedItem select 0;

            [_containerId, _selectedItemId, _selectedItemClass, _selectedItemState, _selectedItemQuantity] remoteExec ["PIMS_fnc_PIMSRetrieveItemFromDatabase", 2];
            [_i, _selectedItemQuantity] call fn_removeOneItemFromInventory;
        };
    };
    if(_viewMode == 2) then {
        private _remainingAmmount = _inventoryMoney;
        for "_i" from ((count _moneyTypes) - 1) to 0 step -1 do {
            private _rest = _remainingAmmount mod ((_moneyTypes select _i) select 1);
            private _fits = floor (_remainingAmmount / ((_moneyTypes select _i) select 1));
            _remainingAmmount = _remainingAmmount - (_fits * ((_moneyTypes select _i) select 1));

            private _moneyType = (_moneyTypes select _i) select 0;
            [_containerId, Nil, _moneyType, "", _fits] remoteExec ["PIMS_fnc_PIMSRetrieveItemFromDatabase", 2];
        };
        [_inventoryId, _inventoryMoney * (-1)] remoteExec ["PIMS_fnc_PIMSChangeMoneyOfInventory", 2];
    };

    private _uid = uinamespace getvariable ["PIMS_Uid", -1];
    missionNamespace setVariable ["PIMS_updateInfo_" + _uid, true, true];
    waitUntil {(missionNamespace getVariable ["PIMS_updateInfo_" + _uid, false]) == false};
};

onBuyButtonPressed = {
    params ["_control", "_button", "_xPos", "_yPos", "_shift", "_ctrl", "_alt"];
    //_string = format ["PIMS DEBUG: onBuyButtonPressed called."];
    //[_string] remoteExec ["systemChat", 0];

    private _buyButton = (findDisplay 142351) displayCtrl 1601;
    _buyButton ctrlEnable false;

    //[] call fn_updateInfo;

    private _uid = uinamespace getvariable ["PIMS_Uid", -1];
    missionNamespace setVariable ["PIMS_updateInfo_" + _uid, true, true];
    waitUntil {(missionNamespace getVariable ["PIMS_updateInfo_" + _uid, false]) == false};

    private _selectedItemText = uiNamespace getVariable ["PIMS_selectedItem", "None"];
    private _containerId = uiNamespace getVariable ["PIMS_containerId", "None"];
    private _selectedIndex = uiNamespace getVariable ["PIMS_selectedIndex", "None"];
    private _listOfItems = uiNamespace getVariable ["PIMS_listOfItems", "None"];
    private _inventoryId = uiNamespace getVariable ["PIMS_inventoryId", "None"];
    private _viewMode = uiNamespace getVariable ["PIMS_ViewMode", "None"];
    private _market = uiNamespace getVariable ["PIMS_market", []];
    private _inventoryMoney = uiNamespace getVariable ["PIMS_inventoryMoney", 0];
    private _allInventories = uiNamespace getVariable ["PIMS_allInventories", []];
    private _editQuantity = uiNamespace getVariable ["PIMS_quantity", 1];
    private _vehicleMarket = uiNamespace getVariable ["PIMS_vehicleMarket", []];

    if(_viewMode == 0) then {
        private _selectedItem = _listOfItems select _selectedIndex;
        private _selectedItemClass = _selectedItem select 2;

        private _selectedItemState = "";

        if (isClass (configFile >> "CfgMagazines" >> _selectedItemClass)) then {
            private _magazineConfig = configFile >> "CfgMagazines" >> _selectedItemClass;
            private _capacity = getNumber (_magazineConfig >> "count");
            _selectedItemState = str _capacity;

            //_string = format ["PIMS DEBUG: _capacity: %1", _capacity];
            //[_string] remoteExec ["systemChat", 0];
        };
        
        private _price = [] call fn_getPrices;

        //_string = format ["PIMS DEBUG: _selectedItemClass: %1, _selectedItemState: %2", _selectedItemClass, _selectedItemState];
        //[_string] remoteExec ["systemChat", 0];

        uiNamespace setVariable ["PIMS_inventoryMoney", (_inventoryMoney - ((_price select 0) * _editQuantity))];
        [_inventoryId, (((_price select 0)*_editQuantity) * (-1))] remoteExec ["PIMS_fnc_PIMSChangeMoneyOfInventory", 2];
        [_inventoryId, _selectedItemClass, _editQuantity, _selectedItemState] remoteExec ["PIMS_fnc_PIMSAddItemToDbInventory", 2];
        [_selectedItemClass, (_editQuantity * (-1))] remoteExec ["PIMS_fnc_PIMSChangeMarketAvailableQuantity", 2];
    };
    if(_viewMode == 1) then {
        private _selectedItem = _market select _selectedIndex;
        private _selectedItemClass = _selectedItem select 1;
        private _selectedItemState = "";

        if (isClass (configFile >> "CfgMagazines" >> _selectedItemClass)) then {
            private _magazineConfig = configFile >> "CfgMagazines" >> _selectedItemClass;
            private _capacity = getNumber (_magazineConfig >> "count");
            _selectedItemState = _capacity;
        };
        
        private _price = [] call fn_getPrices;

        uiNamespace setVariable ["PIMS_inventoryMoney", (_inventoryMoney - ((_price select 0) * _editQuantity))];
        [_inventoryId, (((_price select 0)*_editQuantity) * (-1))] remoteExec ["PIMS_fnc_PIMSChangeMoneyOfInventory", 2];
        [_inventoryId, _selectedItemClass, _editQuantity, _selectedItemState] remoteExec ["PIMS_fnc_PIMSAddItemToDbInventory", 2];
    };
    if(_viewMode == 4) then {
        private _selectedVehicle = _vehicleMarket select _selectedIndex;
        private _selectedVehicleClass = _selectedVehicle select 1;
        private _purchasePrice = _selectedVehicle select 2;
        [_selectedVehicleClass, _inventoryId] remoteExec ["PIMS_fnc_PIMSAddVehicleToDatabase", 2]; //TODO test
        [_inventoryId, (_purchasePrice * (-1))] remoteExec ["PIMS_fnc_PIMSChangeMoneyOfInventory", 2];
    };
    if(_viewMode == 5) then {
        private _selectedInventory = _allInventories select _selectedIndex;
        private _selectedInventoryId = _selectedInventory select 0;
        if(_selectedInventoryId == _inventoryId) then {
            uiNamespace setVariable ["PIMS_inventoryMoney", (_inventoryMoney + _editQuantity)];
        };
        private _selectedInventoryMoney = _selectedInventory select 2;
        _selectedInventory set [2, (_selectedInventoryMoney + _editQuantity)];
        _allInventories set [_selectedIndex, _selectedInventory];
        uiNamespace setVariable ["PIMS_allInventories", _allInventories];
        [_selectedInventoryId, _editQuantity] remoteExec ["PIMS_fnc_PIMSChangeMoneyOfInventory", 2];

        //_string = format ["PIMS DEBUG: money of inventory '%1': %2", _selectedInventoryId, (_inventoryMoney + _editQuantity)];
        //[_string] remoteExec ["systemChat", 0];
    };
    _buyButton ctrlEnable true;

    missionNamespace setVariable ["PIMS_updateInfo_" + _uid, true, true];
    waitUntil {(missionNamespace getVariable ["PIMS_updateInfo_" + _uid, false]) == false};

    //[] call fn_updateInfo;
    //[] call fn_updateDetailText;
};

onChangeView = {
    params ["_control", "_button", "_xPos", "_yPos", "_shift", "_ctrl", "_alt"];
    private _viewMode = uiNamespace getVariable ["PIMS_ViewMode", 0];
    private _isAdmin = uiNamespace getVariable ["PIMS_isAdmin", false];
    private _enableVehicles = uiNamespace getVariable ["PIMS_enableVehicles", false];
    _viewMode = _viewMode + 1;
    if(!_enableVehicles && (_viewMode == 3)) then {
        _viewMode = _viewMode + 2;
    };
    if(!_enableVehicles && (_viewMode == 4)) then {
        _viewMode = _viewMode + 1;
    };
    if(!_isAdmin && (_viewMode == 5)) then {
        _viewMode = 0;
    };
    if(_viewMode > 5) then {
        _viewMode = 0;
    };
    uiNamespace setVariable ["PIMS_ViewMode", _viewMode];
    uiNamespace setVariable ["PIMS_selectedItem", ""];
    uiNamespace setVariable ["PIMS_selectedIndex", 0];
    private _ctrl = (findDisplay 142351) displayCtrl 1500;
    _ctrl lbSetCurSel 0;

    private _uid = uinamespace getvariable ["PIMS_Uid", -1];
    missionNamespace setVariable ["PIMS_updateInfo_" + _uid, true, true];
    waitUntil {(missionNamespace getVariable ["PIMS_updateInfo_" + _uid, false]) == false};

    //call fn_updateInfo;
    //call fn_updateDetailText;
};

onQuantityChanged = {
    params ["_control", "_newText"];

    private _parsedNumber = parseNumber _newText;
    if(_parsedNumber <= 0) then {
        _parsedNumber = 1;
    };

    uiNamespace setVariable ["PIMS_quantity", _parsedNumber];

    private _uid = uinamespace getvariable ["PIMS_Uid", -1];
    missionNamespace setVariable ["PIMS_updateGui_" + _uid, true, true];
    waitUntil {(missionNamespace getVariable ["PIMS_updateGui_" + _uid, false]) == false};

    //[] call fn_updateDetailText;
};

onUpdateInfo = {
    params ["_control", "_button", "_xPos", "_yPos", "_shift", "_ctrl", "_alt"];

    private _uid = uinamespace getvariable ["PIMS_Uid", -1];
    missionNamespace setVariable ["PIMS_updateInfo_" + _uid, true, true];

    //call fn_updateInfo;
};

onUnload = {
    params ["_display", "_exitCode"];
    //_stringGlobal = format ["PIMS DEBUG: onUnload."];
    //[_stringGlobal] remoteExec ["systemChat", 0];
    private _uid = getPlayerUID player;
    missionNamespace setVariable ["PIMS_closeMenu_" + _uid, true];
};

/*
//auto update every x seconds task
[] spawn {
    private _uid = getPlayerUID player;
    while {true} do {
        //missionNamespace setVariable ["PIMS_updateInfo_" + _uid, false, true];
        0 = [] spawn {
            private _uid = getPlayerUID player;
            missionNamespace setVariable ["PIMS_updateInfo_" + _uid, true, true];

            //call fn_updateInfo;
            //call fn_updateDetailText;
        };
        waitUntil {(missionNamespace getVariable ["PIMS_updateInfo_" + _uid, false]) == false};
        private _closeMenu = missionNamespace getVariable ["PIMS_closeMenu_" + _uid, false];
        if (_closeMenu) then {
            break;
        } else {
            sleep 1;
        };
    };
    //_stringGlobal = format ["PIMS DEBUG: auto refresh closed."];
    //[_stringGlobal] remoteExec ["systemChat", 0];
};
*/
//update Gui task
[] spawn {
    private _uid = getPlayerUID player;
    while {true} do {
        private _updateGui = missionNamespace getVariable ["PIMS_updateGui_" + _uid, false];
        if(_updateGui) then {
            0 = [] spawn {
                private _uid = getPlayerUID player;
                call fn_updateDetailText;
                call fn_updateView;
                missionNamespace setVariable ["PIMS_updateGui_" + _uid, false, true];
            };
            waitUntil {(missionNamespace getVariable ["PIMS_updateGui_" + _uid, false]) == false};
        };
        private _closeMenu = missionNamespace getVariable ["PIMS_closeMenu_" + _uid, false];
        if (_closeMenu) then {
            break;
        } else {
            sleep 0.1;
        };
    };
};

//update Info task
[] spawn {
    private _uid = getPlayerUID player;
    while {true} do {
        private _updateGui = missionNamespace getVariable ["PIMS_updateInfo_" + _uid, false];
        if(_updateGui) then {
            0 = [] spawn {
                private _uid = getPlayerUID player;
                call fn_updateInfo;
                missionNamespace setVariable ["PIMS_updateInfo_" + _uid, false, true];
                missionNamespace setVariable ["PIMS_updateGui_" + _uid, true, true];
            };
            waitUntil {(missionNamespace getVariable ["PIMS_updateInfo_" + _uid, false]) == false};
        };
        private _closeMenu = missionNamespace getVariable ["PIMS_closeMenu_" + _uid, false];
        if (_closeMenu) then {
            break;
        } else {
            sleep 0.1;
        };
    };
};


//_stringGlobal = format ["PIMS DEBUG: populating menu list. count _listOfItems: %1"];
//[_stringGlobal] remoteExec ["systemChat", 0];
missionNamespace setVariable ["PIMS_updateInfo_" + _uidGlobal, true, true];
missionNamespace setVariable ["PIMS_updateGui_" + _uidGlobal, true, true];
//call fn_updateInfo;
//call fn_updateDetailText;
