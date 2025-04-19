class PIMS_ModuleAddInventory: Module_F
{
	scope = 2;
	displayName = "PIMS Add Inventory";
	category = "PIMS_Modules";
	function = "PIMS_fnc_PIMSAddInventory";
	icon = "\a3\ui_f\data\igui\cfg\actions\gear_ca.paa";
	functionPriority = 4;
	isGlobal = 0;
	isTriggerActivated = 0;
	isDisposable = 1;

	class Attributes: AttributesBase
	{
		class PIMS_Inventory_Id_Edit: Edit
		{
			property = "PIMS_Inventory_Id_Edit";
			displayName = "Inventory Id";
			tooltip = "Which inventories will the synced objects be connected to";
			typeName = "NUMBER";
			defaultValue = 0;
		};

		class PIMS_Enable_Vehicles_CheckBox: CheckBox
		{
			property = "PIMS_Enable_Vehicles_CheckBox";
			displayName = "Enable Vehicles";
			tooltip = "allow uploading and retrieving vehicles";
			typeName = "BOOL";
			defaultValue = "False";
		};

		class ModuleDescription: ModuleDescription{};
	};

	class ModuleDescription: ModuleDescription
	{
		description[] =
		{
			"PIMS Add Inventory"
		};
	};
};