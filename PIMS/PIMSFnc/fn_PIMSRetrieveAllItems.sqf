/*
 * Retrieve all items from inventory to container
 * SERVER-ONLY: This function runs on the server and retrieves all items at once
 * OPTIMIZED: Uses batch remove command - single DB transaction instead of N calls
 */

if (!isServer) exitWith {false};

params ["_containerNetId", "_inventoryId", "_playerUid"];

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
	if (!isNull _player) then {
		["PIMS ERROR: Container not found"] remoteExec ["systemChat", _player];
		[format ["PIMS_retrieveAllDone_%1", _playerUid], true] remoteExec ["missionNamespace setVariable", _player];
		[format ["PIMS_retrieveAllSuccess_%1", _playerUid], false] remoteExec ["missionNamespace setVariable", _player];
	};
	false
};

// Get all items from database using getinventory extension call
private _getItemsCommand = format ["getinventory|%1", _inventoryId];
private _result = "PIMS-Ext" callExtension _getItemsCommand;

if (_result == "" || _result == "ERROR" || {_result find "Error" == 0}) exitWith {
	if (!isNull _player) then {
		[format ["PIMS ERROR: Failed to get items from database: %1", _result]] remoteExec ["systemChat", _player];
		[format ["PIMS_retrieveAllDone_%1", _playerUid], true] remoteExec ["missionNamespace setVariable", _player];
		[format ["PIMS_retrieveAllSuccess_%1", _playerUid], false] remoteExec ["missionNamespace setVariable", _player];
	};
	false
};

// Parse items - getinventory returns SQF array format: [[contentItemId,class,properties,quantity],...]
private _itemsArray = [];
try {
	_itemsArray = parseSimpleArray _result;
} catch {
	if (!isNull _player) then {
		[format ["PIMS ERROR: Failed to parse inventory data: %1", _exception]] remoteExec ["systemChat", _player];
		[format ["PIMS_retrieveAllDone_%1", _playerUid], true] remoteExec ["missionNamespace setVariable", _player];
		[format ["PIMS_retrieveAllSuccess_%1", _playerUid], false] remoteExec ["missionNamespace setVariable", _player];
	};
};

private _initialItemCount = count _itemsArray;

if (_initialItemCount == 0) exitWith {
	if (!isNull _player) then {
		["PIMS INFO: No items to retrieve"] remoteExec ["systemChat", _player];
		[format ["PIMS_retrieveAllDone_%1", _playerUid], true] remoteExec ["missionNamespace setVariable", _player];
		[format ["PIMS_retrieveAllSuccess_%1", _playerUid], true] remoteExec ["missionNamespace setVariable", _player];
	};
	true
};

if (!isNull _player) then {
	[format ["PIMS INFO: Retrieving all %1 items...", _initialItemCount]] remoteExec ["systemChat", _player];
};

_container lockInventory true;

// Build batch array for single extension call: [[contentItemId,quantity,itemClass,properties],...]
private _batchArray = [];
{
	_x params ["_contentItemId", "_itemClass", "_properties", "_quantity"];
	_batchArray pushBack [_contentItemId, _quantity, _itemClass, _properties];
} forEach _itemsArray;

// Single extension call to remove all items from database (non-blocking for SQF scheduler)
private _batchString = str _batchArray;
private _removeCommand = format ["removeitems|%1|%2", _inventoryId, _batchString];
private _removeResult = "PIMS-Ext" callExtension _removeCommand;

private _successCount = 0;
private _failedItems = [];

// Parse result: "OK|count|[[class,props,qty],...]" or "Error: ..."
if ((_removeResult select [0, 2]) == "OK") then {
	private _parts = _removeResult splitString "|";
	
	// Parse returned items that were successfully removed
	private _removedItemsStr = "";
	if (count _parts >= 3) then {
		// Rejoin in case array contains pipes (unlikely but safe)
		_removedItemsStr = (_parts select [2, count _parts - 2]) joinString "|";
	};
	
	private _removedItems = [];
	try {
		_removedItems = parseSimpleArray _removedItemsStr;
	} catch {
		diag_log format ["PIMS ERROR: Failed to parse removed items: %1", _removedItemsStr];
	};
	
	// Add all successfully removed items to container
	{
		_x params ["_itemClass", "_properties", "_quantity"];
		
		private _addSuccess = [_container, _itemClass, _quantity, _properties] call PIMS_fnc_PIMSAddItemToContainer;
		
		if (_addSuccess) then {
			_successCount = _successCount + 1;
		} else {
			// Failed to add to container - need to rollback this item to database
			private _rollbackCommand = format ["additem|%1|%2|%3|%4", _inventoryId, _itemClass, _properties, _quantity];
			"PIMS-Ext" callExtension _rollbackCommand;
			_failedItems pushBack _itemClass;
			
			if (!isNull _player) then {
				[format ["PIMS WARNING: Failed to add %1 to container, rolled back", _itemClass]] remoteExec ["systemChat", _player];
			};
		};
	} forEach _removedItems;
} else {
	// Batch remove failed entirely
	if (!isNull _player) then {
		[format ["PIMS ERROR: Batch retrieve failed: %1", _removeResult]] remoteExec ["systemChat", _player];
	};
};

// Unlock container - use both local and remoteExec to ensure all clients see it
_container lockInventory false;
[_container, false] remoteExec ["lockInventory", 0];

// Upload inventory to refresh extension cache
[_inventoryId] call PIMS_fnc_PIMSUploadInventoryToExtension;

// Send results back to client
if (!isNull _player) then {
	[format ["PIMS INFO: Retrieved %1 of %2 item types", _successCount, _initialItemCount]] remoteExec ["systemChat", _player];
	
	if (count _failedItems > 0) then {
		[format ["PIMS WARNING: Failed items: %1", _failedItems joinString ", "]] remoteExec ["systemChat", _player];
	};
	
	[format ["PIMS_retrieveAllDone_%1", _playerUid], true] remoteExec ["missionNamespace setVariable", _player];
	[format ["PIMS_retrieveAllSuccess_%1", _playerUid], (_successCount > 0)] remoteExec ["missionNamespace setVariable", _player];
};

true
