params ["_itemClass", "_changeQuantity"];

_string = format ["PIMS DEBUG: ChangeMarketAvailabilableQuantity called. _itemClass: %1, _changeQuantity: %2.", _itemClass, _changeQuantity];
[_string] remoteExec ["systemChat", 0];

private _success = true;
private _string = "";

private _query = format ["0:SQLProtocol:SELECT `Available_Quantity` FROM `market` WHERE `Market_Item_Class`='%2';", _itemClass];
private _result = "extDB3" callExtension _query;
private _resultArray = parseSimpleArray _result;
if(str (_resultArray select 0) isEqualTo "0") then {
	_success = false;
	_string = format ["PIMS ERROR: SQL error. %1", _query];
	[_string] remoteExec ["systemChat", 0];
} else {
	private _availableQuantity = (_resultArray select 0) select 0;
	if(_availableQuantity != -1) then {
		if(_availableQuantity + _changeQuantity < 0) then {
			_success = false;
			_string = format ["PIMS ERROR: attempting to change market availability by illegal ammount."];
			[_string] remoteExec ["systemChat", 0];
			_changeQuantity = _availableQuantity * (-1);
		};
		_query = format ["0:SQLProtocol:UPDATE `market` SET `Available_Quantity`=(`Available_Quantity` + %1) WHERE `Market_Item_Class`='%2';", _changeQuantity, _itemClass];
		_result = "extDB3" callExtension _query;
		_resultArray = parseSimpleArray _result;
		if(str (_resultArray select 0) isEqualTo "0") then {
			_success = false;
			_string = format ["PIMS ERROR: SQL error. %1", _query];
			[_string] remoteExec ["systemChat", 0];
		};
	};
};

//_string = format ["PIMS DEBUG: ChangeMarketAvailabilableQuantity finished. _success: %1.", _success];
//[_string] remoteExec ["systemChat", 0];

_success;