params ["_vehicleNetId", "_objectNetId", "_inventoryId", "_interactionLabel", "_addOrRemove"]; //_addOrRemove true means add, false means remove
private _string = "";
//_string = format ["PIMS DEBUG: PIMSManageUploadVehicleAction: _vehicleNetId: %1, _objectNetId: %2", _vehicleNetId, _objectNetId];
//[_string] remoteExec ["systemChat", 0];
private _uid = getPlayerUID player;
private _object = objectFromNetId _objectNetId;
private _vehicle = objectFromNetId _vehicleNetId;

private _vehicleNetIdString = str _vehicleNetId;
private _objectNetIdString = str _objectNetId;

_vehicleNetIdString = _vehicleNetIdString select [1, (count _vehicleNetIdString) - 2];
_objectNetIdString = _objectNetIdString select [1, (count _objectNetIdString) - 2];

_vehicleNetIdString = _vehicleNetIdString splitString ":" joinString "-";
_objectNetIdString = _objectNetIdString splitString ":" joinString "-";

if(_uid != "1" && _vehicleNetIdString != _objectNetIdString) then {
	//_string = format ["PIMS DEBUG: PIMSManageUploadVehicleAction: _vehicleNetId: %1, _objectNetId: %2, _uid: %3", _vehicleNetId, _objectNetId, _uid];
	//[_string] remoteExec ["systemChat", 0];
	private _currentActionId = -1;
	_currentActionId = missionNamespace getVariable [("PIMS-Vehicle-" + _uid + "-" + _vehicleNetIdString + "-" + _objectNetIdString), (-1)];
	//_string = format ["PIMS DEBUG: PIMSManageUploadVehicleAction: _currentActionId: %1", _currentActionId];
	//[_string] remoteExec ["systemChat", 0];

	if(_currentActionId == (-1) && _addOrRemove == true) then {
		//_string = format ["PIMS DEBUG: _currentActionId: %1, _addOrRemove: %2", _currentActionId, _addOrRemove];
		//[_string] remoteExec ["systemChat", 0];
		private _actionID = _vehicle addAction[
			_interactionLabel,
			{
				params ["_target", "_caller", "_actionId", "_arguments"];
                private _vehicleNetId2 = _arguments select 0;
                private _inventoryId2 = _arguments select 1;
				[_vehicleNetId2, _inventoryId2] remoteExec ["PIMS_fnc_PIMSUploadVehicle", 2];
			},			//script
			[_vehicleNetId, _inventoryId],		// arguments
			1.5,		// priority
			true,		// showWindow
			true,		// hideOnUse
			"",			// shortcut
			"true",		// condition
			10,			// radius
			false,		// unconscious
			"",			// selection
			""			// memoryPoint
		];
		//_string = format ["PIMS DEBUG: vehicle action added. _actionID: %1", _actionID];
		//[_string] remoteExec ["systemChat", 0];
		missionNamespace setVariable [("PIMS-Vehicle-" + _uid + "-" + _vehicleNetIdString + "-" + _objectNetIdString), _actionID, true];
		//_currentActionId = missionNamespace getVariable [("PIMS-Vehicle-" + _uid + "-" + _vehicleNetIdString + "-" + _objectNetIdString), false];
		//_string = format ["PIMS DEBUG: missionNamespace variable changed. name: %1: %2", ("PIMS-Vehicle-" + _uid + "-" + _vehicleNetIdString + "-" + _objectNetIdString), _currentActionId];
		//[_string] remoteExec ["systemChat", 0];
	} else {
		if(_currentActionId != (-1) && _addOrRemove == false) then {
			//_string = format ["PIMS DEBUG: removing vehicle action."];
			//[_string] remoteExec ["systemChat", 0];
			//_string = format ["PIMS DEBUG: removing vehicle action. _currentActionId: %1", _currentActionId];
			//[_string] remoteExec ["systemChat", 0];
			_vehicle removeAction _currentActionId;
			missionNamespace setVariable [("PIMS-Vehicle-" + _uid + "-" + _vehicleNetIdString + "-" + _objectNetIdString), Nil, true];
			//_string = format ["PIMS DEBUG: vehicle action removed."];
			//[_string] remoteExec ["systemChat", 0];
		};
	};
};