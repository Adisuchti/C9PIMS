params ["_vehicleId"];

private _string = "";

private _query = format ["0:SQLProtocol:DELETE FROM `vehicles` WHERE `Vehicle_Id` = %1;", _vehicleId];
private _result = "extDB3" callExtension _query;
private _resultArray = parseSimpleArray _result;

if((str (_resultArray select 0)) == "0") then {
	_string = format ["PIMS ERROR: SQL error. DELETE query failed."];
	[_string] remoteExec ["systemChat", 0];
}; //TODO Logs