params ["_module"];

private _owner = clientOwner;
if(_owner == 2) then {
    private _areMarketsEnabled = missionNamespace getVariable ["PIMS_areMarketsEnabled", true];

    private _string = format ["PIMS INFO:"];
    [_string] remoteExec ["systemChat", 0];
    _string = format ["markets enabled: %1", _areMarketsEnabled];
    [_string] remoteExec ["systemChat", 0];

    private _query = format ["0:SQLProtocol:SELECT Inventory_Id, Inventory_Name, Inventory_Market_Saturation FROM inventories;"];
    private _result = "extDB3" callExtension _query;
    _result = parseSimpleArray _result;

    if((str (_result select 0)) == "1") then {
        _result = _result select 1;
        _string = format ["Inventory ID , Inventory Name , Market Saturation:"];
        [_string] remoteExec ["systemChat", 0];
        for "_i" from 0 to ((count _result) - 1) do {
            _string = format ["%1 , %2 , %3", _result select 0, _result select 1, _result select 2];
            [_string] remoteExec ["systemChat", 0];
        };
    };
};
deleteVehicle _this;