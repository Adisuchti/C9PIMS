/*
 * Author: Adrian Misterov
 * Function: PIMS_fnc_PIMSZeusPlaceInventory
 * 
 * Description:
 * Zeus module that allows dynamic placement of PIMS boxes with inventory selection.
 * Opens a menu for Zeus to select which inventory to assign to the spawned box.
 * 
 * Arguments:
 * 0: _logic <Object> - The Zeus module logic object
 * 1: _synced <Array> - Synchronized objects (unused)
 * 
 * Return Value:
 * <Boolean> - Always returns true
 * 
 * Execution:
 * Server only
 */

params [["_logic", objNull], ["_synced", []]];

if (!isServer) exitWith {true};

// Get all available inventories from database via extension
private _inventoriesResult = "PIMS-Ext" callExtension "getallinventories";
private _inventoriesArray = [];

// Parse result - expected format: [[id1,"name1"],[id2,"name2"],...]
if (_inventoriesResult != "" && _inventoriesResult != "[]") then {
	try {
		_inventoriesArray = parseSimpleArray _inventoriesResult;
	} catch {
		diag_log format ["PIMS ERROR: Failed to parse inventories result: %1", _inventoriesResult];
	};
};

// Fallback: If extension query failed, get inventories from existing editor-placed modules
if (count _inventoriesArray == 0) then {
	private _addInventoryModules = allMissionObjects "Logic" select {
		typeOf _x == "PIMS_ModuleAddInventory"
	};
	
	{
		private _inventoryId = _x getVariable ["PIMS_Inventory_Id_Edit", 0];
		if (_inventoryId > 0) then {
			private _nameQuery = format ["getinventoryname|%1", _inventoryId];
			private _inventoryName = "PIMS-Ext" callExtension _nameQuery;
			_inventoriesArray pushBack [_inventoryId, _inventoryName];
		};
	} forEach _addInventoryModules;
};

// If no inventories available, exit
if (count _inventoriesArray == 0) exitWith {
	diag_log "PIMS ERROR: No inventories found for Zeus placement";
	{
		private _zeusUnit = getAssignedCuratorUnit _x;
		if (!isNull _zeusUnit) then {
			["No inventories found in database!"] remoteExec ["systemChat", owner _zeusUnit];
		};
	} forEach allCurators;
	deleteVehicle _logic;
	true
};

// Find the curator who placed this module
private _zeusPlayer = objNull;
{
	private _curator = _x;
	private _unit = getAssignedCuratorUnit _curator;
	if (!isNull _unit) then {
		_zeusPlayer = _unit;
	};
} forEach allCurators;

if (isNull _zeusPlayer) exitWith {
	diag_log "PIMS ERROR: Could not find any Zeus player for placement module";
	deleteVehicle _logic;
	true
};

// Send inventory list to Zeus player and open selection dialog
[_inventoriesArray, getPosATL _logic, _logic] remoteExec ["PIMS_fnc_PIMSZeusSelectInventoryDialog", owner _zeusPlayer];

true
