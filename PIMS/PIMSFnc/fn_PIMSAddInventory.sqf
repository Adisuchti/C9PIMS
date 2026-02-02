/*
 * Module function for AddInventory
 * Simply validates the module - actual work done in PIMSInit via PlayerConnected event
 */

params [["_logic", objNull], ["_synced", []]];

if (!isServer) exitWith {};

private _inventoryId = _logic getVariable ["PIMS_Inventory_Id_Edit", 0];

format ["PIMS: Inventory module configured for ID %1", _inventoryId] remoteExec ["systemChat", 0];

true