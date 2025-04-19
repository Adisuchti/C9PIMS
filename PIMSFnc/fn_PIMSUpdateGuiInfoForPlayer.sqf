params ["_uid","_inventoryId"];

private _string = "";

_string = format ["PIMS DEBUG: PIMSUpdateGuiInfoForPlayer started."];
[_string] remoteExec ["systemChat", 0];

private _query = format ["0:SQLProtocol:SELECT `AdminId`, `PlayerId` FROM `admins` WHERE `PlayerId` = %1;", _uid];
private _result = "extDB3" callExtension _query;
private _adminPermission = parseSimpleArray _result;

if((str (_adminPermission select 0)) == "0") then {
	_string = format ["PIMS ERROR: SQL error. %1", _query];
	[_string] remoteExec ["systemChat", 0];
};

_adminPermission = _adminPermission select 1;
private _isAdmin = false;
if((count _adminPermission) > 0) then {
    _isAdmin = true;
};

private _allInventories = [];
private _allContentItems = [];

If(_isAdmin) then{
    _query = format ["0:SQLProtocol:SELECT `Inventory_Id`, `Inventory_Name`, `Inventory_Money` FROM `inventories`;"];
    _result = "extDB3" callExtension _query;
    _allInventories = parseSimpleArray _result;

    if((str (_allInventories select 0)) == "0") then {
		_string = format ["PIMS ERROR: SQL error. %1", _query];
		[_string] remoteExec ["systemChat", 0];
	};

	//_string = format ["PIMS DEBUG: PIMSUpdateGuiInfoForPlayer: _allInventories: %1", _allInventories];
	//[_string] remoteExec ["systemChat", 0];

	_allInventories = _allInventories select 1;

	_query = format ["0:SQLProtocol:SELECT `Content_Item_Id`, `Inventory_Id`, `Item_Class`, `Item_Quantity`, `Item_Properties` FROM `content_items`;"];
	_result = "extDB3" callExtension _query;
	_allContentItems = parseSimpleArray _result;

	if((str (_allContentItems select 0)) == "0") then {
		_string = format ["PIMS ERROR: SQL error. %1", _query];
		[_string] remoteExec ["systemChat", 0];
	};

	//_string = format ["PIMS DEBUG: PIMSUpdateGuiInfoForPlayer: _allContentItems: %1", _allContentItems];
	//[_string] remoteExec ["systemChat", 0];

	_allContentItems = _allContentItems select 1;
};

//_query = format ["0:SQLProtocol:SELECT `Content_Item_Id`, `Inventory_Id`, `Item_Class`, `Item_Quantity`, `Item_Properties` FROM `content_items` WHERE `Inventory_Id` = %1 ORDER BY `Item_Class`, `Item_Properties`", _inventoryId];
_query = format ["0:SQLProtocol:SELECT content_items.Content_Item_Id, content_items.Inventory_Id,
content_items.Item_Class, content_items.Item_Quantity, content_items.Item_Properties, item_types.item_classification
FROM content_items
LEFT JOIN items ON items.item_class COLLATE utf8mb4_general_ci = content_items.Item_Class COLLATE utf8mb4_general_ci
LEFT JOIN item_types ON item_types.Item_Type_Id = items.Item_Type
LEFT JOIN item_sorting ON item_sorting.Item_Sorting_Type COLLATE utf8mb4_general_ci = item_types.item_classification COLLATE utf8mb4_general_ci
WHERE Inventory_Id = %1 ORDER BY item_sorting.Item_Sorting_Number, content_items.Item_Class, content_items.Item_Properties;", _inventoryId];
_result = "extDB3" callExtension _query;
private _inventoryItemList = parseSimpleArray _result;

if((str (_inventoryItemList select 0)) == "0") then {
    _string = format ["PIMS ERROR: SQL error. %1", _query];
   [_string] remoteExec ["systemChat", 0];
};

_inventoryItemList = _inventoryItemList select 1;
_query = format ["0:SQLProtocol:SELECT `Inventory_Id`, `Inventory_Money` FROM `inventories` WHERE `Inventory_Id` = %1", _inventoryId];
_result = "extDB3" callExtension _query;

private _money = parseSimpleArray _result;
if((str (_money select 0)) == "0") then {
    _string = format ["PIMS ERROR: SQL error. %1", _query];
   [_string] remoteExec ["systemChat", 0];
};
_money = _money select 1;
_money = _money select 0;
_money = _money select 1;

_query = format ["0:SQLProtocol:SELECT * FROM `market`"];
_result = "extDB3" callExtension _query;
private _market = parseSimpleArray _result;
if((str (_market select 0)) == "0") then {
    _string = format ["PIMS ERROR: SQL error. %1", _query];
   [_string] remoteExec ["systemChat", 0];
};
_market = _market select 1;

private _quotationMark = """";

_query = format ["0:SQLProtocol:SELECT `Vehicle_Id`, `Inventory_Id`, `Vehicle_Class`, `Vehicle_Fuel`, REPLACE(`Vehicle_Hitpoints`, '" + _quotationMark + "', '`'), REPLACE(`Vehicle_Ace_Cargo`, '" + _quotationMark + "', '`'), REPLACE(`Vehicle_Ammo`, '" + _quotationMark + "', '`') FROM `vehicles`;"];
_result = "extDB3" callExtension _query;

//_string = format ["PIMS DEBUG: PIMSUpdateGuiInfoForPlayer: select `vehicles` _result: %1", _result];
//[_string] remoteExec ["systemChat", 0];

private _allVehicles = parseSimpleArray _result;
if((str (_allVehicles select 0)) == "0") then {
    _string = format ["PIMS ERROR: SQL error. %1", _query];
   [_string] remoteExec ["systemChat", 0];
};
_allVehicles = _allVehicles select 1;

private _listOfVehicles = [];
for "_i" from 0 to ((count _allVehicles) - 1) do {
    private _inventoryIdOfVehicle = (_allVehicles select _i) select 1;
    if(_inventoryIdOfVehicle == _inventoryId) then {
        _listOfVehicles pushback (_allVehicles select _i);
    };
};

_query = format ["0:SQLProtocol:SELECT `Vehicle_Market_Id`, `Vehicle_Market_Class`, `Vehicle_Market_Purchase_Price`, `Vehicle_Market_Selling_Price`, `Vehicle_Market_Spawn_With_Ace_Cargo` FROM `vehicle_market`;"];
_result = "extDB3" callExtension _query;
private _vehicleMarket = parseSimpleArray _result;
if((str (_vehicleMarket select 0)) == "0") then {
    _string = format ["PIMS ERROR: SQL error. %1", _query];
   [_string] remoteExec ["systemChat", 0];
};
_vehicleMarket = _vehicleMarket select 1;

_query = format ["0:SQLProtocol:SELECT `Value_For_Penalty_To_Apply`, `Percentage_Extra_Tax` FROM `market_saturation` ORDER BY 'Value_For_Penalty_To_Apply';"];
_result = "extDB3" callExtension _query;
private _marketSaturation = parseSimpleArray _result;
if((str (_marketSaturation select 0)) == "0") then {
    _string = format ["PIMS ERROR: SQL error. %1", _query];
   [_string] remoteExec ["systemChat", 0];
};
_marketSaturation = _marketSaturation select 1;

_query = format ["0:SQLProtocol:SELECT `Inventory_Market_Saturation`, `Inventory_Id` FROM `inventories` WHERE `Inventory_Id` = %1;", _inventoryId];
_result = "extDB3" callExtension _query;
private _inventoryMarketSaturation = parseSimpleArray _result;
if((str (_inventoryMarketSaturation select 0)) == "0") then {
    _string = format ["PIMS ERROR: SQL error. %1", _query];
   [_string] remoteExec ["systemChat", 0];
};
_inventoryMarketSaturation = _inventoryMarketSaturation select 1;
_inventoryMarketSaturation = _inventoryMarketSaturation select 0;
_inventoryMarketSaturation = _inventoryMarketSaturation select 0;

_string = format ["PIMS DEBUG: PIMSUpdateGuiInfoForPlayer: count _inventoryItemList: %1, count _market: %2, _money: %3, count _allInventories %4, count _allContentItems: %5, _isAdmin: %6", count _inventoryItemList, count _market, _money, count _allInventories, count _allContentItems, _isAdmin];
[_string] remoteExec ["systemChat", 0];

//_string = format ["PIMS DEBUG: PIMSUpdateGuiInfoForPlayer: _allInventories: %1, _allContentItems: %2", _allInventories,  _allContentItems];
//[_string] remoteExec ["systemChat", 0];

//_string = format ["PIMS DEBUG: PIMSUpdateGuiInfoForPlayer: _listOfVehicles: %1, _vehicleMarket: %2, _allVehicles: %3", _listOfVehicles,  _vehicleMarket, _allVehicles];
//[_string] remoteExec ["systemChat", 0];

missionNamespace setVariable ["PIMSListOfItems" + _uid, _inventoryItemList, true];
missionNamespace setVariable ["PIMSMoney" + _uid, _money, true];
missionNamespace setVariable ["PIMSMarket" + _uid, _market, true];
missionNamespace setVariable ["PIMSIsAdmin" + _uid, _isAdmin, true];
missionNamespace setVariable ["PIMSAllInventories" + _uid, _allInventories, true];
missionNamespace setVariable ["PIMSAllContentItems" + _uid, _allContentItems, true];
missionNamespace setVariable ["PIMSAllVehicles" + _uid, _allVehicles, true];
missionNamespace setVariable ["PIMSListOfVehicles" + _uid, _listOfVehicles, true];
missionNamespace setVariable ["PIMSVehicleMarket" + _uid, _vehicleMarket, true];
missionNamespace setVariable ["PIMSMarketSaturation" + _uid, _marketSaturation, true];
missionNamespace setVariable ["PIMSInventoryMarketSaturation" + _uid, _inventoryMarketSaturation, true];

missionNamespace setVariable ["PIMSDone" + _uid, true, true];