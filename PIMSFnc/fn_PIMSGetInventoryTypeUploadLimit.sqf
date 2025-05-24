params ["_inventoryId"];

private _query = format ["0:SQLProtocol:SELECT limit_uploads FROM inventories LEFT JOIN inventory_types ON Inventory_Type_Id = inventories.Inventory_Type WHERE inventories.Inventory_Id = %1;", _inventoryId];
private _result = "extDB3" callExtension _query;

//private _string = format ["PIMS DEBUG: _result: %1.", _result];
//[_string] remoteExec ["systemChat", 0];

private _inventoryUploadLimit = parseSimpleArray _result;
if((str (_inventoryUploadLimit select 0)) isEqualTo "0") then {
    _string = format ["PIMS ERROR: SQL error. %1", _query];
   [_string] remoteExec ["systemChat", 0];
   _inventoryUploadLimit = 0;
} else {
    _inventoryUploadLimit = ((_inventoryUploadLimit select 1) select 0) select 0;
};

missionNamespace setVariable ["PIMS_inventoryUploadLimit" + (str _inventoryId), _inventoryUploadLimit, true];
missionNamespace setVariable ["PIMS_inventoryUploadLimitDone" + (str _inventoryId), _inventoryUploadLimit, true];

//_string = format ["PIMS DEBUG: saved _inventoryUploadLimit: '%1'.", _inventoryUploadLimit];
//[_string] remoteExec ["systemChat", 0];
