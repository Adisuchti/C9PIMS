params ["_changeAmmount"];

private _query = format ["0:SQLProtocol:UPDATE inventories SET Inventory_Market_Saturation = GREATEST(Inventory_Market_Saturation - %1, 0);", _changeAmmount];
private _result = "extDB3" callExtension _query;
_result = parseSimpleArray _result;

if((str (_result select 0)) == "0") then {
	_string = format ["PIMS ERROR: SQL error. %1", _query];
	[_string] remoteExec ["systemChat", 0];
} else {
	_string = format ["PIMS INFO: Market Saturation reduced by $%1", _changeAmmount];
	[_string] remoteExec ["systemChat", 0];
};