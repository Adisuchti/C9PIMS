params ["_module"];
private _owner = clientOwner;
if(_owner == 2) then {
	private _string = format ["PIMS INFO: markets disabled."];
	[_string] remoteExec ["systemChat", 0];

	missionNamespace setVariable ["PIMS_areMarketsEnabled", false];
};
deleteVehicle _this;