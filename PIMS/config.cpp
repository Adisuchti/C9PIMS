#include "BIS_AddonInfo.hpp"
#include "\a3\3DEN\UI\macros.inc"
#include "\a3\3DEN\UI\macroexecs.inc"

#define RECOMPILE_FUNCTIONS 0
#define PIMS_VERSION "2.0.0"

#define GUI_GRID_X    (0)
#define GUI_GRID_Y    (0)
#define GUI_GRID_W    (0.025)
#define GUI_GRID_H    (0.04)
#define GUI_GRID_CENTER_X  (0)
#define GUI_GRID_CENTER_Y  (0)
#define GUI_GRID_CENTER_W  (0.025)
#define GUI_GRID_CENTER_H  (0.04)
#define RECOMPILE_FUNCTIONS 0

class RscText;
class RscFrame;
class RscShortcutButton;
class RscListbox;
class RscStructuredText;
class RscEdit;
class RscButton;
class RscPicture;
class RscHTML;
class RscDisplayAttributes;
class RscControlsGroup;
class ScrollBar;

class CfgPatches
{
	class PIMS_patches
	{
		units[]={
            "PIMS_ModuleInit",
            "PIMS_ModuleAddInventory",
            "PIMS_Money_1_Item",
            "PIMS_Money_10_Item",
            "PIMS_Money_50_Item",
            "PIMS_Money_100_Item",
            "PIMS_Money_500_Item",
            "PIMS_Money_1000_Item",
            "PIMS_Box"
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
		requiredAddons[] = {
			"A3_Modules_F",
			"3DEN",
            "ace_common"
        };
        author = "Adrian Misterov";
        name = "Persistent Inventory Management System v2";
        version = PIMS_VERSION;
	};
};

class CfgFactionClasses
{
    class PIMS_modules
    {
        displayname = "Pers. Inv. Man. Sys.";
        priority = 3;
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
            class PIMSUploadInventoryToExtension {
                recompile = RECOMPILE_FUNCTIONS;
            };
            class PIMSGetItemArrayFromContainer {
				recompile = RECOMPILE_FUNCTIONS;
			};
            class PIMSRetrieveItemFromDatabase {
                recompile = RECOMPILE_FUNCTIONS;
            };
            class PIMSCheckBoxMoney {
                recompile = RECOMPILE_FUNCTIONS;
            };
            class PIMSAddItemToContainer {
                recompile = RECOMPILE_FUNCTIONS;
            };
            class PIMSGetInventoryData {
                recompile = RECOMPILE_FUNCTIONS;
            };
            class PIMSWithdrawMoney {
                recompile = RECOMPILE_FUNCTIONS;
            };
            class PIMSRetrieveAllItems {
                recompile = RECOMPILE_FUNCTIONS;
            };
            class PIMSCheckVersion {
                recompile = RECOMPILE_FUNCTIONS;
            };
            class PIMSReportVersion {
                recompile = RECOMPILE_FUNCTIONS;
            };
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
            class Edit;
            class Combo;
            class CheckBox;
            class CheckBoxNumber;
            class ModuleDescription;
        };
        class ModuleDescription
        {
            class Anything;
        };
    };

	// Money Items (placeable)
	class PIMS_Money_1_Item: Item_Base_F
	{
		author="Adrian Misterov";
		scope=2;
		scopeCurator=2;
		displayName="Credits 1";
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
		displayName="Credits 10";
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
		displayName="Credits 50";
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
		displayName="Credits 100";
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
		displayName="Credits 500";
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
		displayName="Credits 1000";
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

	// Modules
	#include "Modules\ModuleInit.hpp"
	#include "Modules\ModuleAddInventory.hpp"

	// Storage Container
	class TKE_Crate1RBlue;
	class PIMS_Box: TKE_Crate1RBlue
	{
		author="Adrian Misterov";
		scope=2;
		scopeCurator=2;
		displayName="PIMS Box";
		editorCategory="EdCat_Supplies";
		editorSubcategory="EdSubcat_SupplyContainers";
		transportMaxWeapons=9999;
		transportMaxMagazines=9999;
		transportMaxBackpacks=999;
		maximumLoad=999999;
	};
};

class CfgWeapons
{
	class ACE_ItemCore;
	class CBA_MiscItem_ItemInfo;

	// Money Items (inventory items)
	class PIMS_Money_1: ACE_ItemCore
	{
		author="Adrian Misterov";
		scope=2;
		displayName="Credits 1";
		descriptionShort="Currency - 1 Credit";
		model="\PIMS\data\pimsMoney";
		picture="\PIMS\data\icons\icon_money_1_ca.paa";
		class ItemInfo: CBA_MiscItem_ItemInfo
		{
			mass=0;
		};
	};
	class PIMS_Money_10: ACE_ItemCore
	{
		author="Adrian Misterov";
		scope=2;
		displayName="Credits 10";
		descriptionShort="Currency - 10 Credits";
		model="\PIMS\data\pimsMoney";
		picture="\PIMS\data\icons\icon_money_10_ca.paa";
		class ItemInfo: CBA_MiscItem_ItemInfo
		{
			mass=0;
		};
	};
	class PIMS_Money_50: ACE_ItemCore
	{
		author="Adrian Misterov";
		scope=2;
		displayName="Credits 50";
		descriptionShort="Currency - 50 Credits";
		model="\PIMS\data\pimsMoney";
		picture="\PIMS\data\icons\icon_money_50_ca.paa";
		class ItemInfo: CBA_MiscItem_ItemInfo
		{
			mass=0;
		};
	};
	class PIMS_Money_100: ACE_ItemCore
	{
		author="Adrian Misterov";
		scope=2;
		displayName="Credits 100";
		descriptionShort="Currency - 100 Credits";
		model="\PIMS\data\pimsMoney";
		picture="\PIMS\data\icons\icon_money_100_ca.paa";
		class ItemInfo: CBA_MiscItem_ItemInfo
		{
			mass=0;
		};
	};
	class PIMS_Money_500: ACE_ItemCore
	{
		author="Adrian Misterov";
		scope=2;
		displayName="Credits 500";
		descriptionShort="Currency - 500 Credits";
		model="\PIMS\data\pimsMoney";
		picture="\PIMS\data\icons\icon_money_500_ca.paa";
		class ItemInfo: CBA_MiscItem_ItemInfo
		{
			mass=0;
		};
	};
	class PIMS_Money_1000: ACE_ItemCore
	{
		author="Adrian Misterov";
		scope=2;
		displayName="Credits 1000";
		descriptionShort="Currency - 1000 Credits";
		model="\PIMS\data\pimsMoney";
		picture="\PIMS\data\icons\icon_money_1000_ca.paa";
		class ItemInfo: CBA_MiscItem_ItemInfo
		{
			mass=0;
		};
	};
};

//I have a dream, that one day the UI will implement a button class that supports flat colors and borders.
class PIMS_FlatButton {
    type = 1;         // CT_BUTTON
    style = 0x02;     // ST_CENTER
    shadow = 0;
    colorText[] = {1,1,1,1}; 
    colorDisabled[] = {0.5,0.5,0.5,1};
    colorBackground[] = {0,0,0,0}; 
    colorBackgroundActive[] = {1,1,1,0.1}; 
    colorBackgroundDisabled[] = {0,0,0,0};
    colorFocused[] = {1,1,1,0.05};
    colorShadow[] = {0,0,0,0};
    colorBorder[] = {0,0,0,0};
    borderSize = 0;
    font = "RobotoCondensed";
    sizeEx = 0.04; // Standard size required for Type 1
    text = "";
    
    // Required offsets for standard buttons to prevent the error
    offsetX = 0;
    offsetY = 0;
    offsetPressedX = 0;
    offsetPressedY = 0;

    soundEnter[] = {"\A3\ui_f\data\sound\RscButton\soundEnter",0.09,1};
    soundPush[] = {"\A3\ui_f\data\sound\RscButton\soundPush",0.09,1};
    soundClick[] = {"\A3\ui_f\data\sound\RscButton\soundClick",0.09,1};
    soundEscape[] = {"\A3\ui_f\data\sound\RscButton\soundEscape",0.09,1};
};

////////////////////////////////////////////////////////
// GUI EDITOR OUTPUT START (by Adrian Brachyukani, v1.063, #Biqyhe)
////////////////////////////////////////////////////////

class PIMSMenuDialog {
    idd = 142351; // Unique dialog ID
    movingEnable = 0;
    enableSimulation = 1;
    onLoad = "_this call onLoad;";
	onUnload = "_this call onUnload;";

	class ControlsBackground
	{
		// Full-screen backdrop to darken game world
		class Backdrop: RscText
		{
			idc = -1;
			x = safezoneX;
			y = safezoneY;
			w = safezoneW;
			h = safezoneH;
			colorBackground[] = {0, 0, 0, 0.7};
		};

		class BackgroundBorder: RscText
		{
			idc = -2;
			x = -0.5 * GUI_GRID_W + GUI_GRID_X;
			y = -0.5 * GUI_GRID_H + GUI_GRID_Y;
			w = 41 * GUI_GRID_W;
			h = 26 * GUI_GRID_H;
			colorBackground[] = {0, 0, 0, 1};
		};
		
		class Background: RscText
		{
			idc = -3;
			x = 0 * GUI_GRID_W + GUI_GRID_X;
			y = 0 * GUI_GRID_H + GUI_GRID_Y;
			w = 40 * GUI_GRID_W;
			h = 25 * GUI_GRID_H;
			colorBackground[] = {0.15, 0.2, 0, 1};
		};
	};

	class Controls
	{
		// --- ITEM LISTBOX (LEFT SIDE) ---
		class list: RscListBox
		{
			idc = 1500;
			onLBSelChanged = "_this call onListboxSelectionChanged";

			x = 0.5 * GUI_GRID_W + GUI_GRID_X;
			y = 2.5 * GUI_GRID_H + GUI_GRID_Y;
			w = 19.5 * GUI_GRID_W;
			h = 22 * GUI_GRID_H;
			colorBackground[] = {0.15,0.15,0,1};
			colorBackground2[] = {0.15,0.15,0,1};
		};

		// --- ITEM DESCRIPTION TEXT (RIGHT SIDE) ---
		class itemText: RscControlsGroup
		{
			idc = 1003;
			x = 20.5 * GUI_GRID_W + GUI_GRID_X;
			y = 2.5 * GUI_GRID_H + GUI_GRID_Y;
			w = 18.5 * GUI_GRID_W;
			h = 18.5 * GUI_GRID_H;
			class Controls
			{
				class itemText: RscStructuredText
				{
					idc = 1000;
					x = 0;
					y = 0;
					w = 18.5 * GUI_GRID_W;
					h = 30 * GUI_GRID_H;
					colorBackground[] = {0.2,0.3,0.1,1};
					colorBackground2[] = {0.2,0.3,0.1,1};
				};
			};

			colorBackground[] = {0.2,0.3,0.1,1};
			colorBackground2[] = {0.2,0.3,0.1,1};
			colorBackgroundActive[] = {0, 0, 0, 0.2};
		};

		// --- HEADER TEXT (TOP RIGHT) ---
		class headerText: RscStructuredText
		{
			idc = 1001;

			x = 21 * GUI_GRID_W + GUI_GRID_X;
			y = 0.5 * GUI_GRID_H + GUI_GRID_Y;
			w = 18 * GUI_GRID_W;
			h = 2 * GUI_GRID_H;
		};
		class QuantitySelect: RscEdit
		{
			idc = 1800;
			maxChars = 4;
			onEditChanged = "_this call onQuantityChanged";

			x = 20.3 * GUI_GRID_W + GUI_GRID_X;
			y = 21.5 * GUI_GRID_H + GUI_GRID_Y;
			w = 3.75 * GUI_GRID_W;
			h = 2.5 * GUI_GRID_H;
			colorBackground[] = {0,0,0,1};
		};

		// --- RELOAD BUTTON (TOP LEFT) ---
		class reloadButtonIcon: RscPicture
		{
			idc = 1701;
			text = "\A3\ui_f\data\IGUI\RscTitles\MPProgress\respawn_ca.paa";

			x = 0.5 * GUI_GRID_W + GUI_GRID_X;
			y = 0.5 * GUI_GRID_H + GUI_GRID_Y;
			w = 2 * GUI_GRID_W;
			h = 2 * GUI_GRID_H;
		};
		class reloadButton: PIMS_FlatButton {
			idc = 1702;
			x = 0.5 * GUI_GRID_W + GUI_GRID_X;
			y = 0.5 * GUI_GRID_H + GUI_GRID_Y;
			w = 2 * GUI_GRID_W;
			h = 2 * GUI_GRID_H;
			colorBackground[] = {0,0,0,0.2};
			colorBackground2[] = {0,0,0,0.2};
            colorBackgroundActive[] = {0.2, 0.2, 0.2, 0.2};
			tooltip = "Refresh inventory list";
			onMouseButtonClick = "_this call onUpdateInfo";
		};

		// --- RETRIEVE BUTTON (BLUE) ---
		class rightButton_BG: RscText {
			x = 24.24 * GUI_GRID_W + GUI_GRID_X;
			y = 21.5 * GUI_GRID_H + GUI_GRID_Y;
			w = 3.75 * GUI_GRID_W;
			h = 2.5 * GUI_GRID_H;
			colorBackground[] = {0,0,0.45,1};
		};
		class rightButton_Text: RscStructuredText {
			idc = 16020;
			x = 24.24 * GUI_GRID_W + GUI_GRID_X;
			y = 22.25 * GUI_GRID_H + GUI_GRID_Y;
			w = 3.75 * GUI_GRID_W;
			h = 1 * GUI_GRID_H;
			text = "<t align='center' size='0.7'>RETRIEVE</t>";
		};
		class rightButton: PIMS_FlatButton {
			idc = 1602;
			x = 24.24 * GUI_GRID_W + GUI_GRID_X;
			y = 21.5 * GUI_GRID_H + GUI_GRID_Y;
			w = 3.75 * GUI_GRID_W;
			h = 2.5 * GUI_GRID_H;
			tooltip = "Retrieve specified quantity of selected item";
			onMouseButtonClick = "_this call onRetrieveButtonPressed";
		};

		// --- RETRIEVE ALL (GREEN) ---
		class rightButton2_BG: RscText {
			x = 28.5 * GUI_GRID_W + GUI_GRID_X;
			y = 21.5 * GUI_GRID_H + GUI_GRID_Y;
			w = 5 * GUI_GRID_W;
			h = 2.5 * GUI_GRID_H;
			colorBackground[] = {0,0.3,0,1};
		};
		class rightButton2_Text: RscStructuredText {
			idc = 16030;
			x = 28.5 * GUI_GRID_W + GUI_GRID_X;
			y = 21.75 * GUI_GRID_H + GUI_GRID_Y;
			w = 5 * GUI_GRID_W;
			h = 2 * GUI_GRID_H;
			text = "<t align='center' size='0.7'>RETRIEVE<br/>ALL</t>";
		};
		class rightButton2: PIMS_FlatButton {
			idc = 1603;
			x = 28.5 * GUI_GRID_W + GUI_GRID_X;
			y = 21.5 * GUI_GRID_H + GUI_GRID_Y;
			w = 5 * GUI_GRID_W;
			h = 2.5 * GUI_GRID_H;
			tooltip = "Retrieve all of the selected item";
			onMouseButtonClick = "_this call onRetrieveAllButtonPressed";
		};

		// --- RETRIEVE EVERYTHING (RED) ---
		class rightButton3_BG: RscText {
			x = 34 * GUI_GRID_W + GUI_GRID_X;
			y = 21.5 * GUI_GRID_H + GUI_GRID_Y;
			w = 5.5 * GUI_GRID_W;
			h = 2.5 * GUI_GRID_H;
			colorBackground[] = {0.5,0,0,1};
		};
		class rightButton3_Text: RscStructuredText {
			idc = 16000;
			x = 34 * GUI_GRID_W + GUI_GRID_X;
			y = 21.75 * GUI_GRID_H + GUI_GRID_Y;
			w = 5.5 * GUI_GRID_W;
			h = 2 * GUI_GRID_H;
			text = "<t align='center' size='0.7'>RETRIEVE<br/>EVERYTHING</t>";
		};
		class rightButton3: PIMS_FlatButton {
			idc = 1600;
			x = 34 * GUI_GRID_W + GUI_GRID_X;
			y = 21.5 * GUI_GRID_H + GUI_GRID_Y;
			w = 5.5 * GUI_GRID_W;
			h = 2.5 * GUI_GRID_H;
			tooltip = "Retrieve all items from the database";
			onMouseButtonClick = "_this call onRetrieveAllItemsTotalButtonPressed";
		};

		// --- VIEW MODE TOGGLE BUTTON (TOP CENTER) ---
        class topButton: RscButton
        {
            idc = 1700;
            x = 2.5 * GUI_GRID_W + GUI_GRID_X;
            y = 0.5 * GUI_GRID_H + GUI_GRID_Y;
            w = 17.5 * GUI_GRID_W;
            h = 2 * GUI_GRID_H;
            colorBackground[] = {0,0,0,0.2};
            colorBackgroundActive[] = {0.2, 0.2, 0.2, 0.2};
            onMouseButtonClick = "_this call onChangeView";
			tooltip = "Change view mode";
        };
	};
};
////////////////////////////////////////////////////////
// GUI EDITOR OUTPUT END
////////////////////////////////////////////////////////
