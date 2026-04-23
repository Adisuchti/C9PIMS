[{
    player addAction[
        "Where's my box?",    // title
        {
            params ["_target", "_caller", "_actionId", "_arguments"]; // script
            WMB_PFH = [{
                {
                    drawIcon3D
                    [
                        "\a3\ui_f\data\igui\cfg\simpletasks\types\rearm_ca.paa",
                        [1,0.718,0, 0.75],
                        (getPosVisual _x),
                        1,
                        1,
                        0,
                        "Your Box!",
                        2
                    ];
                } forEach (player getVariable ["C9_OwnedBoxes", []]);
            }] call CBA_fnc_addPerFrameHandler;
            [{[WMB_PFH] call CBA_fnc_removePerFrameHandler;},[],10] call CBA_fnc_WaitAndExecute;
        },
        nil,        // arguments
        1.5,        // priority
        false,        // showWindow
        true,        // hideOnUse
        "",            // shortcut
        "(player getVariable ['C9_OwnedBoxes', []]) findIf { player distance2D _x < 50 } != -1",        // condition
        50,            // radius
        false,        // unconscious
        "",            // selection
        ""            // memoryPoint
    ];
},[],15] call CBA_fnc_waitAndExecute;