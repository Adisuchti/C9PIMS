params ["_inventoryId", "_increaseAmount"];

private _string = "";

//_string = format ["PIMS DEBUG: starting PIMS_fnc_PIMSIncreaseMarketSaturation"];
//[_string] remoteExec ["systemChat", 0];

private _query = format ["0:SQLProtocol:UPDATE `inventories` SET `Inventory_Market_Saturation`=(%1 + `Inventory_Market_Saturation`) WHERE `Inventory_Id`= %2", _increaseAmount, _inventoryId];
private _result = "extDB3" callExtension _query;
private _resultArray = parseSimpleArray _result;
if((_resultArray select 0) == 1) then {
    _resultArray = _resultArray select 1;
} else {
    _string = format ["PIMS ERROR: SQL error. %1", _query];
    [_string] remoteExec ["systemChat", 0];
};