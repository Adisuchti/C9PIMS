private ["_logic"];
private _module = _this select 0;
private _inventoryId = _module getVariable ["PIMS_Inventory_Id", 0];

missionNamespace setVariable ["PIMS_ActionParameters", []];