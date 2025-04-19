class PIMS_ModuleInit: Module_F
{
	scope = 2;
	displayName = "PIMS Init";
	category = "PIMS_Modules";
	function = "PIMS_fnc_PIMSInit";
	icon = "\a3\ui_f\data\igui\cfg\actions\gear_ca.paa";
	functionPriority = 2;
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
			"PIMS Init"
		};
	};
};