/*
 * Calculate total money value in container
 * Returns total credit value
 */

params ["_container"];

private _totalMoney = 0;

private _moneyTypes = [
	["PIMS_Money_1", 1],
	["PIMS_Money_10", 10],
	["PIMS_Money_50", 50],
	["PIMS_Money_100", 100],
	["PIMS_Money_500", 500],
	["PIMS_Money_1000", 1000]
];

{
	_x params ["_moneyClass", "_value"];
	private _count = {_x == _moneyClass} count (items _container);
	_totalMoney = _totalMoney + (_count * _value);
} forEach _moneyTypes;

_totalMoney
