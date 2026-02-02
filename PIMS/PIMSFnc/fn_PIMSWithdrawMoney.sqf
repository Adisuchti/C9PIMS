/*
 * Withdraw money from inventory balance and add physical money item to container
 * SERVER-ONLY: Must be called via remoteExec from client
 */

if (!isServer) exitWith {};

params ["_containerNetId", "_inventoryId", "_moneyClass", "_quantity", "_playerUid"];

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
		[format ["PIMS_withdrawDone_%1", _playerUid], true] remoteExec ["missionNamespace setVariable", _player];
		[format ["PIMS_withdrawSuccess_%1", _playerUid], false] remoteExec ["missionNamespace setVariable", _player];
	};
	false
};

_container lockInventory true;

try {
	// Calculate total withdrawal amount
	private _moneyValue = switch (_moneyClass) do {
		case "PIMS_Money_1": {1};
		case "PIMS_Money_10": {10};
		case "PIMS_Money_50": {50};
		case "PIMS_Money_100": {100};
		case "PIMS_Money_500": {500};
		case "PIMS_Money_1000": {1000};
		default {0};
	};
	
	if (_moneyValue == 0) exitWith {
		if (!isNull _player) then {
			["PIMS ERROR: Invalid money denomination"] remoteExec ["systemChat", _player];
			[format ["PIMS_withdrawDone_%1", _playerUid], true] remoteExec ["missionNamespace setVariable", _player];
			[format ["PIMS_withdrawSuccess_%1", _playerUid], false] remoteExec ["missionNamespace setVariable", _player];
		};
	};
	
	private _totalAmount = _moneyValue * _quantity;
	
	// Withdraw from database via extension
	private _withdrawCommand = format ["withdrawmoney|%1|%2", _inventoryId, _totalAmount];
	private _result = "PIMS-Ext" callExtension _withdrawCommand;
	
	if (_result == "OK") then {
		// Add money items to container
		[_container, _moneyClass, _quantity] call PIMS_fnc_PIMSAddItemToContainer;
		
		// Upload inventory to refresh extension cache
		[_inventoryId] call PIMS_fnc_PIMSUploadInventoryToExtension;
		
		if (!isNull _player) then {
			[format ["PIMS: Withdrew %1 credits (%2x %3)", _totalAmount, _quantity, _moneyClass]] remoteExec ["systemChat", _player];
			[format ["PIMS_withdrawDone_%1", _playerUid], true] remoteExec ["missionNamespace setVariable", _player];
			[format ["PIMS_withdrawSuccess_%1", _playerUid], true] remoteExec ["missionNamespace setVariable", _player];
		};
	} else {
		if (!isNull _player) then {
			[format ["PIMS ERROR: Failed to withdraw money: %1", _result]] remoteExec ["systemChat", _player];
			[format ["PIMS_withdrawDone_%1", _playerUid], true] remoteExec ["missionNamespace setVariable", _player];
			[format ["PIMS_withdrawSuccess_%1", _playerUid], false] remoteExec ["missionNamespace setVariable", _player];
		};
	};
} catch {
	if (!isNull _player) then {
		[format ["PIMS ERROR: Withdraw failed: %1", _exception]] remoteExec ["systemChat", _player];
		[format ["PIMS_withdrawDone_%1", _playerUid], true] remoteExec ["missionNamespace setVariable", _player];
		[format ["PIMS_withdrawSuccess_%1", _playerUid], false] remoteExec ["missionNamespace setVariable", _player];
	};
};

_container lockInventory false;

true
