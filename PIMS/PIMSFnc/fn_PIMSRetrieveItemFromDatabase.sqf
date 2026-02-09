/*
 * Retrieve item from database to container via extension
 * SERVER-ONLY: Must be called via remoteExec from client
 */

if (!isServer) exitWith {};

params ["_containerNetId", "_inventoryId", "_contentItemId", "_itemClass", "_properties", "_quantity", "_playerUid"];

// Find player object from UID
private _player = objNull;
if (_playerUid != "") then {
	{
		if (getPlayerUID _x == _playerUid) exitWith {
			_player = _x;
		};
	} forEach allPlayers;
};

private _container = objectFromNetId _containerNetId;
if (isNull _container) exitWith {
	// Set variables directly on client using remoteExec
	if (!isNull _player) then {
		[format ["PIMS_retrieveSuccess_%1", _playerUid], false] remoteExec ["missionNamespace setVariable", _player];
		[format ["PIMS_retrieveDone_%1", _playerUid], true] remoteExec ["missionNamespace setVariable", _player];
	};
	false
};

_container lockInventory true;

private _success = false;

try {
	// Remove from database via extension
	private _removeCommand = format ["removeitem|%1|%2|%3", _contentItemId, _quantity, _inventoryId];
	private _result = "PIMS-Ext" callExtension _removeCommand;
	
	if (_result == "OK") then {
		// Add to container
		private _addSuccess = [_container, _itemClass, _quantity, _properties] call PIMS_fnc_PIMSAddItemToContainer;

		if (!_addSuccess) then {
			// Use 'then' instead of 'exitWith' to avoid skipping unlock
			private _errorString = format ["PIMS ERROR: Failed to add item %1 %2x to container from inventory %3.", _itemClass, _quantity, _inventoryId];
			[_errorString] remoteExec ["systemChat", 0];

			// Failed to add to container, rollback database removal
			private _rollbackCommand = format ["additem|%1|%2|%3|%4", _inventoryId, _itemClass, _properties, _quantity];
			"PIMS-Ext" callExtension _rollbackCommand;
			
			// Signal failure
			if (!isNull _player) then {
				[format ["PIMS_retrieveSuccess_%1", _playerUid], false] remoteExec ["missionNamespace setVariable", _player];
				[format ["PIMS_retrieveDone_%1", _playerUid], true] remoteExec ["missionNamespace setVariable", _player];
			};
		} else {
			// Success path
			_success = true;
			
			// Set variables directly on client using remoteExec
			if (!isNull _player) then {
				[format ["PIMS_retrieveSuccess_%1", _playerUid], true] remoteExec ["missionNamespace setVariable", _player];
				[format ["PIMS_retrieveDone_%1", _playerUid], true] remoteExec ["missionNamespace setVariable", _player];
			};
		};
	} else {
		if (!isNull _player) then {
			[format ["PIMS ERROR: Failed to retrieve item: %1", _result]] remoteExec ["systemChat", _player];
			[format ["PIMS_retrieveSuccess_%1", _playerUid], false] remoteExec ["missionNamespace setVariable", _player];
			[format ["PIMS_retrieveDone_%1", _playerUid], true] remoteExec ["missionNamespace setVariable", _player];
		};
	};
} catch {
	if (!isNull _player) then {
		[format ["PIMS ERROR: Retrieve failed: %1", _exception]] remoteExec ["systemChat", _player];
		[format ["PIMS_retrieveSuccess_%1", _playerUid], false] remoteExec ["missionNamespace setVariable", _player];
		[format ["PIMS_retrieveDone_%1", _playerUid], true] remoteExec ["missionNamespace setVariable", _player];
	};
};

// Use both local and remoteExec to ensure all clients see the unlock
_container lockInventory false;
[_container, false] remoteExec ["lockInventory", 0];

// Upload inventory to refresh extension cache (after unlock to minimize lock duration)
if (_success) then {
	[_inventoryId] call PIMS_fnc_PIMSUploadInventoryToExtension;
};

true
