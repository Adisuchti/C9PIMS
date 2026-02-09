/*
 * Author: Adrian Misterov
 * Function: PIMS_fnc_PIMSZeusSelectInventoryDialog
 * 
 * Description:
 * Client-side dialog that allows Zeus to select which inventory to assign to a new PIMS box.
 * 
 * Arguments:
 * 0: _inventoriesArray <Array> - Array of [inventoryId, inventoryName] pairs
 * 1: _position <Array> - Position where box should be spawned [x,y,z]
 * 2: _logic <Object> - The Zeus module logic object
 * 
 * Return Value:
 * None
 * 
 * Execution:
 * Client only (Zeus player)
 */

params ["_inventoriesArray", "_position", "_logic"];

if (!hasInterface) exitWith {};

// Store data in uiNamespace for access by dialog controls
uiNamespace setVariable ["PIMS_Zeus_InventoriesArray", _inventoriesArray];
uiNamespace setVariable ["PIMS_Zeus_SpawnPosition", _position];
uiNamespace setVariable ["PIMS_Zeus_LogicObject", _logic];

// Create and open the dialog
createDialog "PIMSZeusInventorySelectionDialog";

// Populate the listbox with inventories
private _display = findDisplay 142352; // Dialog IDD
if (isNull _display) exitWith {
	systemChat "PIMS ERROR: Could not open inventory selection dialog!";
};

private _listbox = _display displayCtrl 1500;

{
	_x params ["_inventoryId", "_inventoryName"];
	private _index = _listbox lbAdd format ["%1 (ID: %2)", _inventoryName, _inventoryId];
	_listbox lbSetData [_index, str _inventoryId];
} forEach _inventoriesArray;

// Select first item by default
if (lbSize _listbox > 0) then {
	_listbox lbSetCurSel 0;
};
