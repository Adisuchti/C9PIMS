class PIMS_ModuleInit: Module_F
{
	scope = 2;
	displayName = "PIMS Init (v2 DLL)";
	category = "PIMS_Modules";
	function = "PIMS_fnc_PIMSInit";
	icon = "\a3\ui_f\data\igui\cfg\actions\gear_ca.paa";
	functionPriority = 3;
	isGlobal = 0;
	isTriggerActivated = 0;
	isDisposable = 1;

	class Attributes: AttributesBase
	{
		class ModuleDescription: ModuleDescription{};
	};

	class ModuleDescription: ModuleDescription
	{
		description[] =
		{
			"Initialize PIMS system with database connection",
			"Place once per mission",
			"Database settings read from pims_config.json (same folder as DLL)"
		};
	};
};
