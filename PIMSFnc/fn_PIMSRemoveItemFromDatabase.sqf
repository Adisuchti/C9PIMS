params ["_itemId", "_removeQuantity"];

private _string = "";

//_string = format ["removing item from Database. _itemId: %1, _removeQuantity: %2", _itemId, _removeQuantity];
//[_string] remoteExec ["systemChat", 0];

private _query = format ["0:SQLProtocol:SELECT * FROM `content_items` WHERE `Content_Item_Id` = %1", _itemId];
private _result = "extDB3" callExtension _query;
private _resultArray = parseSimpleArray _result;
_resultArray = _resultArray select 1;

if(count _resultArray == 1) then {
    private _quantity = ((_resultArray select 0) select 3);
    private _class = ((_resultArray select 0) select 2);
    private _inventoryId = ((_resultArray select 0) select 1);

    if(_quantity <= _removeQuantity) then {
        _query = format ["0:SQLProtocol:DELETE FROM `content_items` WHERE `Content_Item_Id` = %1", _itemId];
        _result = "extDB3" callExtension _query;
        _resultArray = parseSimpleArray _result;
        if((str (_resultArray select 0)) == "0") then {
            _string = format ["PIMS ERROR: SQL error. %1", _query];
            [_string] remoteExec ["systemChat", 0];
        } else {
            _query = format ["0:SQLProtocol:INSERT INTO `logs` (`Transaction_Item`, `Transaction_Quantity`, `Transaction_Inventory_Id`) VALUES ('%1', %2, '%3');", _class, (_removeQuantity * (-1)), _inventoryId];
            _result = "extDB3" callExtension _query;
            _resultArray = parseSimpleArray _result;
            if(str (_resultArray select 0) isEqualTo "0") then {
                _string = format ["PIMS ERROR: SQL error Logs. %1", _query];
                [_string] remoteExec ["systemChat", 0];
            };
        };
        if(_quantity < _removeQuantity) then {
            _string = format ["PIMS ERROR: item quantity to be removed greater than quantity present. `Content_Item_Id` = %1", _itemId];
            [_string] remoteExec ["systemChat", 0];
        };
    } else {
        _query = format ["0:SQLProtocol:UPDATE `content_items` SET `Item_Quantity`='%1' WHERE `Content_Item_Id` = %2", (_quantity - _removeQuantity), _itemId];
        _result = "extDB3" callExtension _query;
        _resultArray = parseSimpleArray _result;
        if((str (_resultArray select 0)) == "0") then {
            _string = format ["PIMS ERROR: SQL error. %1", _query];
            [_string] remoteExec ["systemChat", 0];
        } else {
            _query = format ["0:SQLProtocol:INSERT INTO `logs` (`Transaction_Item`, `Transaction_Quantity`, `Transaction_Inventory_Id`) VALUES ('%1', %2, '%3');", _class, (_removeQuantity * (-1)), _inventoryId];
            _result = "extDB3" callExtension _query;
            _resultArray = parseSimpleArray _result;
            if(str (_resultArray select 0) isEqualTo "0") then {
                _string = format ["PIMS ERROR: SQL error Logs. %1", _query];
                [_string] remoteExec ["systemChat", 0];
            };
        };
    };
} else {
    if(count _resultArray == 0) then {
        _string = format ["PIMS ERROR: item could not be found in database. _itemId: %1", _itemId];
        [_string] remoteExec ["systemChat", 0];
    } else {
        _string = format ["PIMS ERROR: multiple entries with same ID found in database. _itemId: %1", _itemId];
        [_string] remoteExec ["systemChat", 0];
    };
};