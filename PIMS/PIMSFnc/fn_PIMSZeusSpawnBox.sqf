/*
 * Author: Adrian Misterov
 * Function: PIMS_fnc_PIMSZeusSpawnBox
 * 
 * Description:
 * Server-side function that spawns and configures a PIMS box for the selected inventory.
 * Adds interactions for all players with permission.
 * 
 * Arguments:
 * 0: _inventoryId <Number> - The inventory ID to assign to the box
 * 1: _position <Array> - Position where box should be spawned [x,y,z]
 * 2: _logic <Object> - The Zeus module logic object to delete
 * 
 * Return Value:
 * <Object> - The spawned PIMS box
 * 
 * Execution:
 * Server only
 */

params ["_inventoryId", "_position", "_logic"];

if (!isServer) exitWith {objNull};

// Spawn the PIMS box
private _box = createVehicle ["PIMS_Box", _position, [], 0, "CAN_COLLIDE"];
_box setPosATL _position;

// Configure the box
_box lockInventory false;
_box allowDamage false;
_box setDamage [0, false, objNull, objNull, true];

// Store the inventory ID on the box for reference
_box setVariable ["PIMS_Inventory_Id", _inventoryId, true];

// Register in global tracking array so PlayerConnected and monitor loop can find it
if (isNil "PIMS_ZeusSpawnedBoxes") then {
	PIMS_ZeusSpawnedBoxes = [];
};
PIMS_ZeusSpawnedBoxes pushBack [_box, _inventoryId];

// Get inventory name
private _nameQuery = format ["getinventoryname|%1", _inventoryId];
private _inventoryName = "PIMS-Ext" callExtension _nameQuery;

// Set up actions for all connected players who have permission
{
	private _player = _x;
	private _playerUid = getPlayerUID _player;
	
	if (_playerUid != "" && _playerUid != "1") then {
		// Check permission via extension
		private _permCheck = format ["checkpermission|%1|%2", _inventoryId, _playerUid];
		private _hasPermission = ("PIMS-Ext" callExtension _permCheck) == "1";
		
		if (_hasPermission) then {
			// Check if admin
			private _adminCheck = format ["isadmin|%1", _playerUid];
			private _isAdmin = ("PIMS-Ext" callExtension _adminCheck) == "1";
			
			private _interactionLabelUpload = format ["Upload Content to: %1", _inventoryName];
			private _interactionLabelOpen = format ["Open Menu: %1", _inventoryName];
			
			// Add Upload action
			[_box,
				[
					_interactionLabelUpload,
					{
						params ["_target", "_caller", "_actionId", "_arguments"];
						private _objectNetId = _arguments select 0;
						private _inventoryId = _arguments select 1;
						private _playerUid = getPlayerUID _caller;
						
						[_objectNetId, _inventoryId, _playerUid] remoteExec ["PIMS_fnc_PIMSUploadInventory", 2];
					},
					[netId _box, _inventoryId],
					1.5,
					true,
					true,
					"",
					"true",
					5,
					false,
					"",
					""
				]
			] remoteExec ["addAction", owner _player];
			
			// Add Open Menu action
			[_box,
				[
					_interactionLabelOpen,
					{
						params ["_target", "_caller", "_actionId", "_arguments"];
						private _objectNetId = _arguments select 0;
						private _inventoryId = _arguments select 1;
						private _isAdmin = _arguments select 2;
						private _ownerUid = getPlayerUID _caller;
						
						[_ownerUid, _objectNetId, _inventoryId, _isAdmin] call PIMS_fnc_PIMSOpenMenu;
					},
					[netId _box, _inventoryId, _isAdmin],
					1.5,
					true,
					true,
					"",
					"true",
					5,
					false,
					"",
					""
				]
			] remoteExec ["addAction", owner _player];
		};
	};
} forEach allPlayers;

// Make box editable by all curators
{
	_x addCuratorEditableObjects [[_box], true];
} forEach allCurators;

diag_log format ["PIMS INFO: Zeus spawned PIMS box for inventory %1 (%2) at %3", _inventoryId, _inventoryName, _position];

// Notify all curators
{
	private _zeusUnit = getAssignedCuratorUnit _x;
	if (!isNull _zeusUnit) then {
		[format ["PIMS: Box placed for inventory '%1' (ID: %2)", _inventoryName, _inventoryId]] remoteExec ["systemChat", owner _zeusUnit];
	};
} forEach allCurators;

// Delete the logic module
deleteVehicle _logic;

_box
