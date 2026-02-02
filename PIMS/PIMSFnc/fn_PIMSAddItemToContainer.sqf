/*
 * Add item to container
 * Handles weapons, magazines, items, backpacks, and money
 */

params ["_container", "_className", "_quantity", "_properties"];

// Determine item type and add accordingly
private _configWeapon = configFile >> "CfgWeapons" >> _className;
private _configMagazine = configFile >> "CfgMagazines" >> _className;
private _configVehicle = configFile >> "CfgVehicles" >> _className;
private _success = false;

if (isClass _configWeapon) then {
	// It's a weapon or item
	private _itemInfo = _configWeapon >> "ItemInfo";
	if (isClass _itemInfo) then {
		// It's an item
		for "_i" from 1 to _quantity do {
			_container addItemCargoGlobal [_className, 1];
			_success = true;
		};
	} else {
		// It's a weapon
		_container addWeaponCargoGlobal [_className, _quantity];
		_success = true;
	};
} else {
	if (isClass _configMagazine) then {
		// It's a magazine
		if(_properties == "") then {
			_container addMagazineCargoGlobal [_className, _quantity];
			_success = true;
		} else {
			private _propertiesNumber = parseNumber _properties;
			_container addMagazineAmmoCargo  [_className, _quantity, _propertiesNumber];
			_success = true;
		};
	} else {
		if (isClass _configVehicle) then {
			// It's a backpack
			_container addBackpackCargoGlobal [_className, _quantity];
			_success = true;
		} else {
			// Unknown type, try adding as item
			_container addItemCargoGlobal [_className, _quantity];
			_success = true;
		};
	};
};

_success