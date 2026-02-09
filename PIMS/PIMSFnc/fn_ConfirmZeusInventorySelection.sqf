/*
 * Author: Adrian Misterov
 * Function: PIMS_fnc_ConfirmZeusInventorySelection
 * 
 * Description:
 * Called when Zeus confirms inventory selection in the dialog.
 * Sends the selection to the server to spawn the box.
 * 
 * Arguments:
 * None (reads from dialog controls and uiNamespace)
 * 
 * Return Value:
 * None
 * 
 * Execution:
 * Client only (Zeus player)
 */

if (!hasInterface) exitWith {};

private _display = findDisplay 142352;
if (isNull _display) exitWith {
	systemChat "PIMS ERROR: Dialog not found!";
};

private _listbox = _display displayCtrl 1500;
private _selectedIndex = lbCurSel _listbox;

if (_selectedIndex < 0) exitWith {
	systemChat "PIMS ERROR: No inventory selected!";
};

// Get the inventory ID from the selected item
private _inventoryIdStr = _listbox lbData _selectedIndex;
private _inventoryId = parseNumber _inventoryIdStr;

// Get stored data from uiNamespace
private _position = uiNamespace getVariable ["PIMS_Zeus_SpawnPosition", [0,0,0]];
private _logic = uiNamespace getVariable ["PIMS_Zeus_LogicObject", objNull];

// Send to server to spawn the box
[_inventoryId, _position, _logic] remoteExec ["PIMS_fnc_PIMSZeusSpawnBox", 2];

// Close the dialog
closeDialog 0;

// Confirm to Zeus
systemChat format ["PIMS: Spawning box for inventory ID %1...", _inventoryId];
