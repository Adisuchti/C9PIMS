/*
 * SERVER-ONLY: Get inventory data from database
 * Called via remoteExec from client
 */

if (!isServer) exitWith {};

// Spawn into scheduled environment to prevent blocking the SQF scheduler
// and Server FPS if the extension call or parsing takes multiple seconds
_this spawn {
	params ["_inventoryId", "_playerUid"];

	// Get inventory name
	private _nameQuery = format ["getinventoryname|%1", _inventoryId];
	private _inventoryName = "PIMS-Ext" callExtension _nameQuery;

	// Get inventory items
	private _getQuery = format ["getinventory|%1", _inventoryId];
	private _resultStr = "PIMS-Ext" callExtension _getQuery;
	private _items = [];
	if (_resultStr != "" && _resultStr != "ERROR" && {_resultStr find "Error" != 0}) then {
		try {
			_items = parseSimpleArray _resultStr;
		} catch {
			diag_log format ["PIMS ERROR: Failed to parse inventory data: %1 (Result: %2)", _exception, _resultStr];
		};
	};

	// Get inventory money balance
	private _moneyQuery = format ["getinventorymoney|%1", _inventoryId];
	private _moneyStr = "PIMS-Ext" callExtension _moneyQuery;
	private _inventoryMoney = 0;
	if (_moneyStr != "" && _moneyStr != "ERROR" && {_moneyStr find "Error" != 0}) then {
		_inventoryMoney = parseNumber _moneyStr;
	};

	// Find player object from UID to send data back privately
	private _player = objNull;
	if (_playerUid != "") then {
		{
			if (getPlayerUID _x == _playerUid) exitWith {
				_player = _x;
			};
		} forEach allPlayers;
	};

	if (!isNull _player) then {
		// Store results in mission namespace for client to retrieve (Private to the player)
		[format ["PIMS_InventoryName_%1", _playerUid], _inventoryName] remoteExec ["missionNamespace setVariable", _player];
		[format ["PIMS_InventoryItems_%1", _playerUid], _items] remoteExec ["missionNamespace setVariable", _player];
		[format ["PIMS_InventoryMoney_%1", _playerUid], _inventoryMoney] remoteExec ["missionNamespace setVariable", _player];
		[format ["PIMS_InventoryDataReady_%1", _playerUid], true] remoteExec ["missionNamespace setVariable", _player];
	} else {
		diag_log format ["PIMS ERROR: Could not find player %1 to send inventory data", _playerUid];
	};
};

true
