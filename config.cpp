#include "BIS_AddonInfo.hpp"
#include "\a3\3DEN\UI\macros.inc"
#include "\a3\3DEN\UI\macroexecs.inc"

#define GUI_GRID_X    (0)
#define GUI_GRID_Y    (0)
#define GUI_GRID_W    (0.025)
#define GUI_GRID_H    (0.04)

//TODO responsive GUI for variable display resolutions
//#define GUI_GRID_X    (safezoneX)
//#define GUI_GRID_Y    (safezoneY)
//#define GUI_GRID_W    safeZoneW
//#define GUI_GRID_H    safeZoneH

//#define GUI_GRID_W (pixelW * pixelGrid)	// one grid width
//#define GUI_GRID_H (pixelH * pixelGrid)	// one grid height

#define GUI_GRID_CENTER_X  (0)
#define GUI_GRID_CENTER_Y  (0)
#define GUI_GRID_CENTER_W  (0.025)
#define GUI_GRID_CENTER_H  (0.04)
#define RECOMPILE_FUNCTIONS 0
class RscText;
class RscFrame;
class RscButton;
class RscListbox;
class RscStructuredText;
class RscEdit;
class RscShortcutButton;
class RscPicture;
class RscHTML;
class RscDisplayAttributes;

class CfgPatches
{
	class PIMS_patches
	{
		units[]={
            "PIMS_ModuleInit",
            "PIMS_ModuleAddInventory",
            "PIMS_ModuleEnableMarket",
            "PIMS_ModuleDisableMarket",
            "PIMS_ModuleReduceMarketSaturation",
            "PIMS_ModuleReportStatus",
            "PIMS_Money_1_Item",
            "PIMS_Money_10_Item",
            "PIMS_Money_50_Item",
            "PIMS_Money_100_Item",
            "PIMS_Money_500_Item",
            "PIMS_Money_1000_Item"
			};
        weapons[] = {
            "PIMS_Money_1",
            "PIMS_Money_10",
            "PIMS_Money_50",
            "PIMS_Money_100",
            "PIMS_Money_500",
            "PIMS_Money_1000"
        };
        requiredVersion = 1.00;
		requiredAddons[] =
        {
			"A3_Modules_F",
			"3DEN"
        };
        author = "Adrian Misterov";
        name = "Persistent Inventory Management System";
        version = "1.0";
	};
};
class CfgFactionClasses
{
    class PIMS_modules
    {
        displayname = "Pers. Inv. Man. Sys.";
        priority = 1;
        side = 7;
    };
};

class CfgFunctions
{
    class PIMS
    {
        class PIMSFnc
        {
            tag = "PIMS";
            file = "\PIMS\PIMSFnc";
            class PIMSInit {
				recompile = RECOMPILE_FUNCTIONS;
			};
            class PIMSOpenMenu {
				recompile = RECOMPILE_FUNCTIONS;
			};
            class PIMSMenuListInventory {
				recompile = RECOMPILE_FUNCTIONS;
			};
            class PIMSAddInventory {
				recompile = RECOMPILE_FUNCTIONS;
			};
            class PIMSUploadInventory {
				recompile = RECOMPILE_FUNCTIONS;
			};
            class PIMSGetItemArrayFromContainer {
				recompile = RECOMPILE_FUNCTIONS;
			};
            class PIMSRetrieveItemFromDatabase {
                recompile = RECOMPILE_FUNCTIONS;
            };
            class PIMSRemoveItemFromDatabase {
                recompile = RECOMPILE_FUNCTIONS;
            };
            class PIMSChangeMoneyOfInventory {
                recompile = RECOMPILE_FUNCTIONS;
            };
            class PIMSAddItemToDbInventory {
                recompile = RECOMPILE_FUNCTIONS;
            };
            class PIMSUpdateGuiInfoForPlayer {
                recompile = RECOMPILE_FUNCTIONS;
            };
            class PIMSUploadVehicle {
                recompile = RECOMPILE_FUNCTIONS;
            };
            class PIMSManageUploadVehicleAction {
                recompile = RECOMPILE_FUNCTIONS;
            };
            class PIMSAddVehicleToDatabase {
                recompile = RECOMPILE_FUNCTIONS;
            };
            class PIMSSpawnVehicleMenu {
                recompile = RECOMPILE_FUNCTIONS;
            };
            class PIMSSpawnVehicleMenuLocal {
                recompile = RECOMPILE_FUNCTIONS;
            };
            class PIMSRemoveVehicleFromDatabase {
                recompile = RECOMPILE_FUNCTIONS;
            };
            class PIMSDisableMarket {
                recompile = RECOMPILE_FUNCTIONS;
            };
            class PIMSEnableMarket {
                recompile = RECOMPILE_FUNCTIONS;
            };
            class PIMSReduceMarketSaturation {
                recompile = RECOMPILE_FUNCTIONS;
            };
            class PIMSReportStatus {
                recompile = RECOMPILE_FUNCTIONS;
            };
            class PIMSModuleDelete {
                recompile = RECOMPILE_FUNCTIONS;
            };
            class PIMSIncreaseMarketSaturation {
                recompile = RECOMPILE_FUNCTIONS;
            };
            class PIMSChangeMarketAvailableQuantity {
                recompile = RECOMPILE_FUNCTIONS;
            };
            class PIMSReduceMarketSaturationOnDatabase {
                recompile = RECOMPILE_FUNCTIONS;
            }
        };
	};
};

class CfgVehicles
{
    class Logic;
    class Item_Base_F;
    class Module_F: Logic
    {
        class AttributesBase
        {
            class Default;
            class Edit; // Default edit box (i.e., text input field)
            class Combo; // Default combo box (i.e., drop-down menu)
            class CheckBox; // Tickbox, returns true/false
            class CheckBoxNumber; // Tickbox, returns 1/0
            class ModuleDescription; // Module description
        };
        class ModuleDescription
        {
            class Anything;
        };
    };

	class PIMS_Money_1_Item: Item_Base_F
	{
		author="Adrian Misterov";
		scope=2;
		scopeCurator=2;
		displayName="PIMS Money 1";
		vehicleClass="Items";
		class TransportItems
		{
			class _xx_PIMS_Money_1
			{
				name="PIMS_Money_1";
				count=1;
			};
		};
	};
	class PIMS_Money_10_Item: Item_Base_F
	{
		author="Adrian Misterov";
		scope=2;
		scopeCurator=2;
		displayName="PIMS Money 10";
		vehicleClass="Items";
		class TransportItems
		{
			class _xx_PIMS_Money_10
			{
				name="PIMS_Money_10";
				count=1;
			};
		};
	};
    class PIMS_Money_50_Item: Item_Base_F
	{
		author="Adrian Misterov";
		scope=2;
		scopeCurator=2;
		displayName="PIMS Money 50";
		vehicleClass="Items";
		class TransportItems
		{
			class _xx_PIMS_Money_50
			{
				name="PIMS_Money_50";
				count=1;
			};
		};
	};
    class PIMS_Money_100_Item: Item_Base_F
	{
		author="Adrian Misterov";
		scope=2;
		scopeCurator=2;
		displayName="PIMS Money 100";
		vehicleClass="Items";
		class TransportItems
		{
			class _xx_PIMS_Money_100
			{
				name="PIMS_Money_100";
				count=1;
			};
		};
	};
    class PIMS_Money_500_Item: Item_Base_F
	{
		author="Adrian Misterov";
		scope=2;
		scopeCurator=2;
		displayName="PIMS Money 500";
		vehicleClass="Items";
		class TransportItems
		{
			class _xx_PIMS_Money_500
			{
				name="PIMS_Money_500";
				count=1;
			};
		};
	};
    class PIMS_Money_1000_Item: Item_Base_F
	{
		author="Adrian Misterov";
		scope=2;
		scopeCurator=2;
		displayName="PIMS Money 1'000";
		vehicleClass="Items";
		class TransportItems
		{
			class _xx_PIMS_Money_1000
			{
				name="PIMS_Money_1000";
				count=1;
			};
		};
	};

    #include "Modules\PIMS_ModuleInit.hpp"
    #include "Modules\PIMS_ModuleAddInventory.hpp"
    #include "Modules\PIMS_ModuleEnableMarket.hpp"
    #include "Modules\PIMS_ModuleDisableMarket.hpp"
    #include "Modules\PIMS_ModuleReduceMarketSaturation.hpp"
    #include "Modules\PIMS_ModuleReportStatus.hpp"
};

class CfgWeapons
{
    class ItemCore;
	class ACE_ItemCore;
	class CBA_MiscItem_ItemInfo;
    class PIMS_Money_1: ACE_ItemCore
	{
		author="Adrian Misterov";
		scope=2;
		displayName="PIMS Money 1";
		descriptionShort="moneys";
        //model = "\A3\weapons_f\Ammo\mag_mxrifle.p3d";
        model = "\PIMS\data\pimsMoney";
		picture = "\PIMS\data\icons\icon_money_1_ca.paa";
		class ItemInfo: CBA_MiscItem_ItemInfo
		{
			mass=0;
		};
    };
    class PIMS_Money_10: ACE_ItemCore
	{
		author="Adrian Misterov";
		scope=2;
		displayName="PIMS Money 10";
		descriptionShort="moneys";
        model = "\PIMS\data\pimsMoney";
		picture = "\PIMS\data\icons\icon_money_10_ca.paa";
		class ItemInfo: CBA_MiscItem_ItemInfo
		{
			mass=0;
		};
    };
    class PIMS_Money_50: ACE_ItemCore
	{
		author="Adrian Misterov";
		scope=2;
		displayName="PIMS Money 50";
		descriptionShort="moneys";
        model = "\PIMS\data\pimsMoney";
		picture = "\PIMS\data\icons\icon_money_50_ca.paa";
		class ItemInfo: CBA_MiscItem_ItemInfo
		{
			mass=0;
		};
    };
    class PIMS_Money_100: ACE_ItemCore
	{
		author="Adrian Misterov";
		scope=2;
		displayName="PIMS Money 100";
		descriptionShort="moneys";
        model = "\PIMS\data\pimsMoney";
		picture = "\PIMS\data\icons\icon_money_100_ca.paa";
		class ItemInfo: CBA_MiscItem_ItemInfo
		{
			mass=0;
		};
    };
    class PIMS_Money_500: ACE_ItemCore
	{
		author="Adrian Misterov";
		scope=2;
		displayName="PIMS Money 500";
		descriptionShort="moneys";
		model = "\PIMS\data\pimsMoney";
		picture = "\PIMS\data\icons\icon_money_500_ca.paa";
		class ItemInfo: CBA_MiscItem_ItemInfo
		{
			mass=0;
		};
    };
    class PIMS_Money_1000: ACE_ItemCore
	{
		author="Adrian Misterov";
		scope=2;
		displayName="PIMS Money 1'000";
		descriptionShort="moneys";
		model = "\PIMS\data\pimsMoney";
		picture = "\PIMS\data\icons\icon_money_1000_ca.paa";
		class ItemInfo: CBA_MiscItem_ItemInfo
		{
			mass=0;
		};
    };
};

////////////////////////////////////////////////////////
// GUI EDITOR OUTPUT START (by S-223 'Adrian', v1.063, #Quxozu)
////////////////////////////////////////////////////////

class PIMSMenuDialog {
    idd = 142351; // Unique dialog ID
    movingEnable = 0;
    enableSimulation = 1;

    class ControlsBackground
    {
        class Background : RscText
        {
            idc = -1;
            x = GUI_GRID_CENTER_X;
            y = GUI_GRID_CENTER_Y;
            w = 40 * GUI_GRID_CENTER_W;
            h = 25 * GUI_GRID_CENTER_H;
            colorBackground[] = {0,0,0,0.8};
        };
    };

    class controls {
        class list: RscListbox
        {
            //maybe implement CT_TREE to list items grouped by type
            idc = 1500;
            x = 0.5 * GUI_GRID_W + GUI_GRID_X;
            y = 2.5 * GUI_GRID_H + GUI_GRID_Y;
            w = 19.5 * GUI_GRID_W;
            h = 22 * GUI_GRID_H;
            colorBackground[] = {0.2,0.2,0.2,0.8};
            onLBSelChanged = "_this call onListboxSelectionChanged";
        };
        class itemText: RscStructuredText
        {
            //TODO maybe use RscHTML
            idc = 1000;
            x = 20.5 * GUI_GRID_W + GUI_GRID_X;
            y = 2.5 * GUI_GRID_H + GUI_GRID_Y;
            w = 18.5 * GUI_GRID_W;
            h = 18.5 * GUI_GRID_H;
        };
        class headerText: RscStructuredText
        {
            idc = 1001;
            x = 21 * GUI_GRID_W + GUI_GRID_X;
            y = 0.5 * GUI_GRID_H + GUI_GRID_Y;
            w = 18 * GUI_GRID_W;
            h = 2 * GUI_GRID_H;
        };
        class leftButton: RscShortcutButton
        {
            idc = 1600;
            style = ST_LEFT;
            x = 21.5 * GUI_GRID_W + GUI_GRID_X;
            y = 21.5 * GUI_GRID_H + GUI_GRID_Y;
            w = 4 * GUI_GRID_W;
            h = 2.5 * GUI_GRID_H;
            onMouseButtonClick = "_this call onSellButtonPressed";
            class TextPos
            {
                left = 0.1 * GUI_GRID_W;
                top = 0.1 * GUI_GRID_W;
                right = 0;
                bottom = 0;
            };
            animTextureNormal = "#(argb,8,8,3)color(0.8,0,0,1)";
            animTextureDefault = "#(argb,8,8,3)color(0.8,0,0,1)";
            animTextureOver = "#(argb,8,8,3)color(1,0,0,1)";
        };
        class QuantitySelect: RscEdit
        {
            idc = 1800;
            x = 25.8 * GUI_GRID_W + GUI_GRID_X;
            y = 21.5 * GUI_GRID_H + GUI_GRID_Y;
            w = 4 * GUI_GRID_W;
            h = 2.5 * GUI_GRID_H;
            maxChars = 4;
            colorBackground[] = {0,0,0,1};
            onEditChanged = "_this call onQuantityChanged";
        };
        class middleButton: RscShortcutButton
        {
            idc = 1601;
            style = ST_LEFT;
            x = 30.2 * GUI_GRID_W + GUI_GRID_X;
            y = 21.5 * GUI_GRID_H + GUI_GRID_Y;
            w = 4 * GUI_GRID_W;
            h = 2.5 * GUI_GRID_H;
            color[] = {1,1,1,1};
            colorDisabled[] = {1,1,1,0.25};
            onMouseButtonClick = "_this call onBuyButtonPressed";
            class TextPos
            {
                left = 0.1 * GUI_GRID_W;
                top = 0.1 * GUI_GRID_W;
                right = 0;
                bottom = 0;
            };
            animTextureNormal = "#(argb,8,8,3)color(0,0.8,0,1)";
            animTextureDefault = "#(argb,8,8,3)color(0,0.8,0,1)";
            animTextureOver = "#(argb,8,8,3)color(0,1,0,1)";
            animTextureDisabled = "#(argb,8,8,3)color(0.5,0.5,0.5,1)";
        };
        class rightButton: RscShortcutButton
        {
            idc = 1602;
            style = ST_LEFT;
            x = 34.5 * GUI_GRID_W + GUI_GRID_X;
            y = 21.5 * GUI_GRID_H + GUI_GRID_Y;
            w = 4 * GUI_GRID_W;
            h = 2.5 * GUI_GRID_H;
            color[] = {1,1,1,1};
            colorDisabled[] = {1,1,1,0.25};
            onMouseButtonClick = "_this call onRetrieveButtonPressed";
            class TextPos
            {
                left = 0.1 * GUI_GRID_W;
                top = 0.1 * GUI_GRID_W;
                right = 0;
                bottom = 0;
            };
            animTextureNormal = "#(argb,8,8,3)color(0,0,1.0,1)";
            animTextureDefault = "#(argb,8,8,3)color(0,0,1.0,1)";
            animTextureOver = "#(argb,8,8,3)color(0.2,0.2,1,1)";
            animTextureDisabled = "#(argb,8,8,3)color(0.5,0.5,0.5,1)";
        };
        class reloadButton: RscShortcutButton
        {
            style = ST_CENTER;
            textureNoShortcut = "\A3\ui_f\data\IGUI\RscTitles\MPProgress\respawn_ca.paa";
            idc = 1701;
            x = 0.5 * GUI_GRID_W + GUI_GRID_X;
            y = 0.5 * GUI_GRID_H + GUI_GRID_Y;
            w = 2 * GUI_GRID_W;
            h = 2 * GUI_GRID_H;
            colorBackground[] = {0,0,0,1};
            onMouseButtonClick = "_this call onUpdateInfo";
            class ShortcutPos
            {
                left = 0.1 * GUI_GRID_W;
                top = 0.1 * GUI_GRID_W;
                w = 1.8 * GUI_GRID_W;
                h = 1.8 * GUI_GRID_H;
            };
        };
        class topButton: RscButton
        {
            idc = 1700;
            x = 2.5 * GUI_GRID_W + GUI_GRID_X;
            y = 0.5 * GUI_GRID_H + GUI_GRID_Y;
            w = 17.5 * GUI_GRID_W;
            h = 2 * GUI_GRID_H;
            colorBackground[] = {0,0,0,1};
            colorBackgroundActive[] = {0.2, 0.2, 0.2, 1};
            onMouseButtonClick = "_this call onChangeView";
        };
    };
};

////////////////////////////////////////////////////////
// GUI EDITOR OUTPUT END
////////////////////////////////////////////////////////

class RscTitles
{
    class PIMSVehicleSpawnGui {
        idd = 142352; // Unique dialog ID
        fadeIn = 1;
        fadeOut = 1;
        duration = 60;

        onLoad = "_this call (uiNamespace getVariable 'onRlcLoad');";
        onDestroy = "['onDestroy'] remoteExec ['systemChat', 0];";
        onKeyDown = "['onKeyDown 1'] remoteExec ['systemChat', 0];";
        class ControlsBackground
        {
            class Background : RscText
            {
                idc = -1;
                x = 0.5 * GUI_GRID_W + GUI_GRID_X;
                y = 21.5 * GUI_GRID_H + GUI_GRID_Y;
                w = 39 * GUI_GRID_W;
                h = 3 * GUI_GRID_H;
                colorBackground[] = {0,0,0,0.8};

                onKeyDown = "['onKeyDown 2'] remoteExec ['systemChat', 0];";
            };
        };
        class controls {
            class itemText: RscStructuredText
            {
                idc = 1000;
                x = 0.5 * GUI_GRID_W + GUI_GRID_X;
                y = 21.5 * GUI_GRID_H + GUI_GRID_Y;
                w = 39 * GUI_GRID_W;
                h = 3 * GUI_GRID_H;
                onKeyDown = "['onKeyDown 3'] remoteExec ['systemChat', 0];";
            };
        };
    };
};

////////////////////////////////////////////////////////
// GUI EDITOR OUTPUT START (by S-323 'Adrian', v1.063, #Nujaxe)
////////////////////////////////////////////////////////

class PIMSReduceMarketSaturationGui: RscDisplayAttributes {
    idd = 142353; // Unique dialog ID
    movingEnable = 0;
    enableSimulation = 1;
    //onLoad = "_this call PIMSReduceMarketSaturation;";
    //onLoad = "[0, _this] call fn_PIMSReduceMarketSaturation;";
    onLoad = "[0, _this] execVM 'PIMS\PIMSFnc\fn_PIMSReduceMarketSaturation.sqf';"
    //onLoad = "['PIMSReduceMarketSaturationGui loaded'] remoteExec ['systemChat', 0];"

    class ControlsBackground
    {
        class Background_1: RscText
        {
            idc = 2200;
            x = 5.5 * GUI_GRID_W + GUI_GRID_X;
            y = 6.5 * GUI_GRID_H + GUI_GRID_Y;
            w = 29 * GUI_GRID_W;
            h = 10.5 * GUI_GRID_H;
            colorBackground[] = {0,0,0,0.8};
        };
        class Background_2: RscText
        {
            idc = 2201;
            x = 5.5 * GUI_GRID_W + GUI_GRID_X;
            y = 4.5 * GUI_GRID_H + GUI_GRID_Y;
            w = 29 * GUI_GRID_W;
            h = 1.5 * GUI_GRID_H;
            colorBackground[] = {0,0,0,0.8};
        };
    };
    class controls {
        class QuantityEditField: RscEdit
        {
            idc = 1400;
            x = 7 * GUI_GRID_W + GUI_GRID_X;
            y = 10 * GUI_GRID_H + GUI_GRID_Y;
            w = 26 * GUI_GRID_W;
            h = 2.5 * GUI_GRID_H;
            onEditChanged = "_this call onQuantityChanged";
        };
        class LeftButton: RscButton
        {
            idc = 1600;
            x = 6.5 * GUI_GRID_W + GUI_GRID_X;
            y = 13.5 * GUI_GRID_H + GUI_GRID_Y;
            w = 12 * GUI_GRID_W;
            h = 2.5 * GUI_GRID_H;
            onMouseButtonClick = "_this call onCancelButtonPress";
        };
        class RightButton: RscButton
        {
            idc = 1601;
            x = 21.5 * GUI_GRID_W + GUI_GRID_X;
            y = 13.5 * GUI_GRID_H + GUI_GRID_Y;
            w = 12 * GUI_GRID_W;
            h = 2.5 * GUI_GRID_H;
            onMouseButtonClick = "_this call onApplyButtonPress";
        };
        class TitleText: RscStructuredText
        {
            idc = 1100;
            x = 7 * GUI_GRID_W + GUI_GRID_X;
            y = 7 * GUI_GRID_H + GUI_GRID_Y;
            w = 26 * GUI_GRID_W;
            h = 2.5 * GUI_GRID_H;
            color[] = {1,1,1,1};
        };
        class DescriptionText: RscStructuredText
        {
            idc = 1101;
            x = 5.5 * GUI_GRID_W + GUI_GRID_X;
            y = 4.5 * GUI_GRID_H + GUI_GRID_Y;
            w = 29 * GUI_GRID_W;
            h = 1.5 * GUI_GRID_H;
            color[] = {1,1,1,1};
        };
    };
};

////////////////////////////////////////////////////////
// GUI EDITOR OUTPUT END
////////////////////////////////////////////////////////
