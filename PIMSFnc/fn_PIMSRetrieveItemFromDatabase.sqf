params ["_containerId", "_itemId", "_objectClass", "_objectProperties", "_quantity"];

private _string = "";

private _container = objectFromNetId _containerId;

if (isClass (configFile >> "CfgWeapons" >> _objectClass)) then {
    //_string = format ["%1 is a Weapon.", _objectClass];
    //[_string] remoteExec ["systemChat", 0];
    //_container addWeaponCargoGlobal [_objectClass, _quantity]; //TODO somehow my money items dont get spawned properly
    _container addItemCargoGlobal [_objectClass, _quantity];
} else {
    if (isClass (configFile >> "CfgMagazines" >> _objectClass)) then {
        //_string = format ["%1 is a Magazine.", _objectClass];
        //[_string] remoteExec ["systemChat", 0];
        private _objectProperties = parseNumber _objectProperties;
        //_string = format ["_objectProperties: %1", _objectProperties];
        //[_string] remoteExec ["systemChat", 0];
        _container addMagazineAmmoCargo  [_objectClass, _quantity, _objectProperties];
    } else {
        if (isClass (configFile >> "CfgVehicles" >> _objectClass)) then {
            if (inheritsFrom (configFile >> "CfgVehicles" >> _objectClass) == "Bag_Base") then {
                //_string = format ["%1 is a Backpack.", _objectClass];
                //[_string] remoteExec ["systemChat", 0];
                _container addBackpackCargoGlobal [_objectClass, _quantity];
            } else {
                //_string = format ["%1 is a Vehicle or other Object.", _objectClass];
                //[_string] remoteExec ["systemChat", 0];
                _container addItemCargoGlobal [_objectClass, _quantity];
            };
        } else {
            if (isClass (configFile >> "CfgGlasses" >> _objectClass)) then {
                //_string = format ["%1 is a Glasses/Facewear.", _objectClass];
                //[_string] remoteExec ["systemChat", 0];
                _container addItemCargoGlobal [_objectClass, _quantity];
            } else {
                if (isClass (configFile >> "CfgVehicles" >> _objectClass) && {inheritsFrom (configFile >> "CfgVehicles" >> _objectClass) == "Item_Base_F"}) then {
                    //_string = format ["%1 is a Generic Item.", _objectClass];
                    //[_string] remoteExec ["systemChat", 0];
                    _container addItemCargoGlobal [_objectClass, _quantity];
                } else {
                    //_string = format ["PIMS ERROR: %1 is an Unknown Item Type.", _objectClass];
                    //[_string] remoteExec ["systemChat", 0];
                    _container addItemCargoGlobal [_objectClass, _quantity];
                };
            };
        };
    };
};