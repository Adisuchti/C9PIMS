params ["_inventoryId", "_moneyChange"];
private _string = "";
private _query = format ["0:SQLProtocol:UPDATE `inventories` SET `Inventory_Money`=(%1 + `Inventory_Money`) WHERE `Inventory_Id`= %2", _moneyChange, _inventoryId];
//_string = format ["SQL Query: ", _query];
//[_string] remoteExec ["systemChat", 0];
private _result = "extDB3" callExtension _query;
private _resultArray = parseSimpleArray _result;
if((_resultArray select 0) == 1) then {
    //_string = format ["SQL Query succeeded."];
    //[_string] remoteExec ["systemChat", 0];
    _resultArray = _resultArray select 1;
    _query = format ["0:SQLProtocol:INSERT INTO `logs` (`Transaction_Item`, `Transaction_Quantity`, `Transaction_Inventory_Id`) VALUES ('%1', %2, '%3');", "Money", _moneyChange, _inventoryId];
    _result = "extDB3" callExtension _query;
    _resultArray = parseSimpleArray _result;
    if(str (_resultArray select 0) isEqualTo "0") then {
        _string = format ["PIMS ERROR: SQL error Logs. %1", _query];
        [_string] remoteExec ["systemChat", 0];
    };
} else {
    _string = format ["PIMS ERROR: SQL error. %1", _query];
    [_string] remoteExec ["systemChat", 0];
};