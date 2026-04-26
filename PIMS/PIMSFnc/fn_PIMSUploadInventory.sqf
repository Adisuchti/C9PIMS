/*
 * Upload inventory contents to database via extension
 * SERVER-ONLY: Must be called via remoteExec from client
 */

if (!isServer) exitWith {};

params ["_containerNetId", "_inventoryId", ["_playerUid", ""]];

// Get container object first
private _container = objectFromNetId _containerNetId;
if (isNull _container) exitWith {
	false
};

// Lock inventory immediately and record the lock timestamp for stale-lock detection
_container lockInventory true;
[_container, true] remoteExec ["lockInventory", 0];
_container setVariable ["PIMS_OpLockTime", diag_tickTime, true];

// Find player object from UID
private _player = objNull;
if (_playerUid != "") then {
	{
		if (getPlayerUID _x == _playerUid) exitWith {
			_player = _x;
		};
	} forEach allPlayers;
};

["PIMS DEBUG: Starting upload..."] remoteExec ["systemChat", _player];

// Check if upload already in progress
private _lockVar = format ["PIMS_UploadLock_%1", _containerNetId];
if (missionNamespace getVariable [_lockVar, false]) exitWith {
	if (!isNull _player) then {
		["PIMS: Upload already in progress for this container"] remoteExec ["systemChat", _player];
	};
	// Must unlock container since we already locked it above
	_container lockInventory false;
	[_container, false] remoteExec ["lockInventory", 0];
	_container setVariable ["PIMS_OpLockTime", nil, true];
};

missionNamespace setVariable [_lockVar, true, true];

try {
	// Get items from container
	private _items = [_container] call PIMS_fnc_PIMSGetItemArrayFromContainer;
	
	if (count _items == 0) then {
		if (!isNull _player) then {
			["PIMS: Container is empty, nothing to upload"] remoteExec ["systemChat", _player];
		};
	} else {
		// Build batch array for single extension call
		// Format: [[class,props,qty],[class,props,qty],...]
		private _batchArray = [];
		{
			_x params ["_className", "_quantity", "_properties"];
			_batchArray pushBack [_className, _properties, _quantity];
		} forEach _items;
		
		// Build comment string for transaction logging
		private _playerName = if (!isNull _player) then {name _player} else {"Unknown"};
		private _comment = format ["%1 (%2)", _playerName, _playerUid];
		
		// Convert to string for extension call
		private _batchString = str _batchArray;
		private _addCommand = format ["additems|%1|%2|%3", _inventoryId, _batchString, _comment];
		private _result = "PIMS-Ext" callExtension _addCommand;
		
		// Parse result: "OK|count" or "Error: ..."
		if ((_result select [0, 2]) == "OK") then {
			private _parts = _result splitString "|";
			private _uploadCount = if (count _parts > 1) then {parseNumber (_parts select 1)} else {count _items};
			
			// Clear container
			clearWeaponCargoGlobal _container;
			clearMagazineCargoGlobal _container;
			clearItemCargoGlobal _container;
			clearBackpackCargoGlobal _container;
			
			if (!isNull _player) then {
				[format ["PIMS: Uploaded %1 item types to inventory", _uploadCount]] remoteExec ["systemChat", _player];
			};
			
			// Upload inventory to refresh extension cache
			[_inventoryId] call PIMS_fnc_PIMSUploadInventoryToExtension;
		} else {
			if (!isNull _player) then {
				[format ["PIMS ERROR: Batch upload failed: %1", _result]] remoteExec ["systemChat", _player];
			};
		};
	};
} catch {
	if (!isNull _player) then {
		[format ["PIMS ERROR: Upload failed: %1", _exception]] remoteExec ["systemChat", _player];
	};
};

_container lockInventory false;
[_container, false] remoteExec ["lockInventory", 0];
_container setVariable ["PIMS_OpLockTime", nil, true];

missionNamespace setVariable [_lockVar, false, true];

["PIMS DEBUG: Upload complete."] remoteExec ["systemChat", _player];

true
