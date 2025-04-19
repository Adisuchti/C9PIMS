params ["_mode", "_display"];

_display = _display select 0;

private _stringGlobal = "";
//_stringGlobal = format ["PIMS DEBUG: Reduce Market Saturation called."];
//[_stringGlobal] remoteExec ["systemChat", 0];

//_stringGlobal = format ["PIMS DEBUG: player %1", getPlayerUID player];
//[_stringGlobal] remoteExec ["systemChat", 0];

//_stringGlobal = format ["PIMS DEBUG: _display %1", _display];
//[_stringGlobal] remoteExec ["systemChat", 0];

uiNamespace setVariable ["PIMS_reduceMarketSaturationAmmount", 0];
uiNamespace setVariable ["PIMS_reduceMarketSaturationDisplay", _display];

private _titleText = (findDisplay 142353) displayCtrl 1100;
private _titleTextText = format ["PIMS Reduce Market Saturation"];
_titleText ctrlSetText _titleTextText;

private _descriptionText = (findDisplay 142353) displayCtrl 1101;
private _descriptionTextText = format ["Set the ammount in PIMS Dollars"];
_descriptionText ctrlSetText _descriptionTextText;

private _rightButton = (findDisplay 142353) displayCtrl 1601;
private _rightButtonText = format ["Apply"];
_rightButton ctrlSetText _rightButtonText;

private _lefttButton = (findDisplay 142353) displayCtrl 1600;
private _lefttButtonText = format ["Cancel"];
_lefttButton ctrlSetText _lefttButtonText;

onQuantityChanged = {
    params ["_control", "_newText"];

    private _parsedNumber = parseNumber _newText;
    if(_parsedNumber <= 0) then {
        _parsedNumber = 1;
    };

    uiNamespace setVariable ["PIMS_reduceMarketSaturationAmmount", _parsedNumber];
};

onApplyButtonPress = {
    params ["_control", "_button", "_xPos", "_yPos", "_shift", "_ctrl", "_alt"];

    private _string = "";

    private _editQuantity = uiNamespace getVariable ["PIMS_reduceMarketSaturationAmmount", 0];
    private _thisDisplay = uiNamespace getVariable ["PIMS_reduceMarketSaturationDisplay", 0];

    [_editQuantity] remoteExec ["PIMS_fnc_PIMSReduceMarketSaturationOnDatabase", 2];

    _thisDisplay closeDisplay 1;
};

onCancelButtonPress = {
    params ["_control", "_button", "_xPos", "_yPos", "_shift", "_ctrl", "_alt"];

    private _string = "";

    private _thisDisplay = uiNamespace getVariable ["PIMS_reduceMarketSaturationDisplay", 0];

    _thisDisplay closeDisplay 1;
};