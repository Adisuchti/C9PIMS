/*
 * Extract all items from container into structured array
 * Returns: [[className, quantity, properties], ...]
 * 
 * This is the only function that needs to scan container - done ONCE per upload
 */

params ["_container"];

private _items = [];

// Get cargo arrays
private _weaponCargo = weaponCargo _container;
private _magazineCargo = magazinesAmmoCargo _container; // Returns [classname, ammoCount] pairs
private _itemCargo = itemCargo _container;
private _backpackCargo = backpackCargo _container;

// Helper function to add/update item in array
private _addOrUpdateItem = {
	params ["_className", "_properties"];
	
	private _found = false;
	{
		if ((_x select 0) == _className && (_x select 2) == _properties) exitWith {
			_x set [1, (_x select 1) + 1];
			_found = true;
		};
	} forEach _items;
	
	if (!_found) then {
		_items pushBack [_className, 1, _properties];
	};
};

// Process weapons (simple classname array)
{
	[_x, ""] call _addOrUpdateItem;
} forEach _weaponCargo;

// Process magazines (array of [classname, ammoCount] pairs)
{
	_x params ["_className", "_ammoCount"];
	[_className, str _ammoCount] call _addOrUpdateItem;
} forEach _magazineCargo;

// Process items (simple classname array)
{
	[_x, ""] call _addOrUpdateItem;
} forEach _itemCargo;

// Process backpacks (simple classname array)
{
	[_x, ""] call _addOrUpdateItem;
} forEach _backpackCargo;

_items
