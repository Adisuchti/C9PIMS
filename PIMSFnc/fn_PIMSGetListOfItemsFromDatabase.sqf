params ["_inventoryId"];
private _string = "";
private _query = format ["0:SQLProtocol:SELECT * FROM `content_items` WHERE `Inventory_Id` = %1", _inventoryId];
//_string = format ["SQL Query: ", _query];
//[_string] remoteExec ["systemChat", 0];
private _result = "extDB3" callExtension _query;
private _resultArray = parseSimpleArray _result;
if((_resultArray select 0) == 1) then {
    //_string = format ["SQL Query succeeded. return count: %1", _resultArray select 1];
    //[_string] remoteExec ["systemChat", 0];
    _resultArray = _resultArray select 1;
} else {
    _string = format ["SQL Query error. %1", _query];
    [_string] remoteExec ["systemChat", 0];
};
_resultArray
//TODO implement 