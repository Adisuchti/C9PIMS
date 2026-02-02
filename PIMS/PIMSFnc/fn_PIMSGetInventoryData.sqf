/*
 * SERVER-ONLY: Get inventory data from database
 * Called via remoteExec from client
 */

if (!isServer) exitWith {};

params ["_inventoryId", "_playerUid"];

// Get inventory name
private _nameQuery = format ["getinventoryname|%1", _inventoryId];
private _inventoryName = "PIMS-Ext" callExtension _nameQuery;

// Get inventory items
private _getQuery = format ["getinventory|%1", _inventoryId];
private _resultStr = "PIMS-Ext" callExtension _getQuery;
private _items = parseSimpleArray _resultStr;

// Get inventory money balance
private _moneyQuery = format ["getinventorymoney|%1", _inventoryId];
private _moneyStr = "PIMS-Ext" callExtension _moneyQuery;
private _inventoryMoney = parseNumber _moneyStr;

// Store results in mission namespace for client to retrieve
missionNamespace setVariable [format ["PIMS_InventoryName_%1", _playerUid], _inventoryName, true];
missionNamespace setVariable [format ["PIMS_InventoryItems_%1", _playerUid], _items, true];
missionNamespace setVariable [format ["PIMS_InventoryMoney_%1", _playerUid], _inventoryMoney, true];
missionNamespace setVariable [format ["PIMS_InventoryDataReady_%1", _playerUid], true, true];

true
