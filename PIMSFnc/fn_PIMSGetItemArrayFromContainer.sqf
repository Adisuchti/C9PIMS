params ["_containerNetId"]; //TODO currently uniform and backpack contents are not extracted

private _container = objectFromNetId _containerNetId;
//_string = format ["starting PIMS_Fn_GetItemArrayFromContainer. typeOf _container: %1", typeOf _container];
//[_string] remoteExec ["systemChat", 0];

private _itemArray = [];

private _items = itemCargo _container;
private _magazines = magazinesAmmoCargo _container;
private _weapons = weaponCargo _container;

private _found = false;

//_string = format ["_items: %1", _items];
//[_string] remoteExec ["systemChat", 0];
//_string = format ["_magazines: %1", _magazines];
//[_string] remoteExec ["systemChat", 0];
//_string = format ["_weapons: %1", _weapons];
//[_string] remoteExec ["systemChat", 0];

{
    private _itemClass = _x;
    _found = false;
    {
        if (_x select 0 == _itemClass) then {
            _x set [1, (_x select 1) + 1];
            _found = true;
        };
    } forEach _itemArray;

    if (!_found) then {
        _itemArray pushBack [_itemClass, 1, ""];
    };
} forEach _items;

{
    private _magClass = _x select 0;
    private _magAmmo = _x select 1;

    _found = false;
    {
        if (((_x select 0) == _magClass) && ((_x select 2) isEqualTo _magAmmo)) then {
            _x set [1, (_x select 1) + 1];
            _found = true;
        };
    } forEach _itemArray;

    if (!_found) then {
        _itemArray pushBack [_magClass, 1, _magAmmo];
    };
} forEach _magazines;

{
    private _weapClass = _x;

    _found = false;
    {
        if (_x select 0 == _weapClass) then {
            _x set [1, (_x select 1) + 1];
            _found = true;
        };
    } forEach _itemArray;

    if (!_found) then {
        _itemArray pushBack [_weapClass, 1, ""];
    };
} forEach _weapons;
_itemArray;