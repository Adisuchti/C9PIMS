class PIMS_ModuleZeusPlaceInventory: Module_F
{
	scope = 2;
	scopeCurator = 2;
	displayName = "Place PIMS Inventory Box";
	category = "PIMS_Modules";
	function = "PIMS_fnc_PIMSZeusPlaceInventory";
	icon = "\a3\ui_f\data\igui\cfg\actions\gear_ca.paa";
	functionPriority = 1;
	isGlobal = 0;
	isTriggerActivated = 0;
	isDisposable = 1;
	curatorCanAttach = 1;

	class Attributes: AttributesBase
	{
		class ModuleDescription: ModuleDescription{};
	};

	class ModuleDescription: ModuleDescription
	{
		description[] =
		{
			"Zeus module for dynamic PIMS box placement",
			"Opens a menu to select which inventory to assign",
			"Box will spawn with full player interactions configured"
		};
		sync[] = {};
	};
};
