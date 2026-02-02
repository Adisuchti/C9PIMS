/*
 * Upload inventory data from database to extension cache
 * SERVER-ONLY: Must be called via remoteExec from client or init script
 * This caches the inventory data in the extension to avoid repeated database queries
 */

if (!isServer) exitWith {};

params ["_inventoryId"];

if (isNil "_inventoryId" || {!(_inventoryId isEqualType 0)}) exitWith {
	systemChat "PIMS ERROR: Invalid inventoryId for upload";
	false
};

// Call extension to upload inventory to cache
private _uploadCommand = format ["uploadinventory|%1", _inventoryId];
private _result = "PIMS-Ext" callExtension _uploadCommand;

if (_result == "OK") then {
	diag_log format ["PIMS: Successfully uploaded inventory %1 to extension cache", _inventoryId];
	true
} else {
	diag_log format ["PIMS ERROR: Failed to upload inventory %1: %2", _inventoryId, _result];
	false
};
