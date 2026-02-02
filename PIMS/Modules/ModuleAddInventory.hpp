class PIMS_ModuleAddInventory: Module_F
{
	scope = 2;
	displayName = "PIMS Add Inventory (v2)";
	category = "PIMS_Modules";
	function = "PIMS_fnc_PIMSAddInventory";
	icon = "\a3\ui_f\data\igui\cfg\actions\gear_ca.paa";
	functionPriority = 3;
	isGlobal = 0;
	isTriggerActivated = 0;
	isDisposable = 1;

	class Attributes: AttributesBase
	{
		class PIMS_Inventory_Id_Edit: Edit
		{
			property = "PIMS_Inventory_Id_Edit";
			displayName = "Inventory Id";
			tooltip = "Which inventory from database will the synced objects connect to";
			typeName = "NUMBER";
			defaultValue = 0;
		};

		class ModuleDescription: ModuleDescription{};
	};

	class ModuleDescription: ModuleDescription
	{
		description[] =
		{
			"Connect objects to a database inventory",
			"Synchronize this module to boxes/containers",
			"Set the inventory ID that matches your database"
		};
	};
};
