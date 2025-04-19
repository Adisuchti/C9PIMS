class PIMS_ModuleReportStatus: Module_F
{
	scope = 2;
	displayName = "PIMS Report Status";
	category = "PIMS_Modules";
	function = "PIMS_fnc_PIMSReportStatus";
	icon = "\a3\ui_f\data\igui\cfg\actions\gear_ca.paa";
	functionPriority = 2;
	isGlobal = 1;
	isTriggerActivated = 0;
	isDisposable = 1;
	scopeCurator = 2;

	class Attributes: AttributesBase
	{
		class ModuleDescription: ModuleDescription{};
	};

	class ModuleDescription: ModuleDescription
	{
		description[] =
		{
			"PIMS Report Status"
		};
	};
};