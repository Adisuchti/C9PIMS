class PIMS_ModuleReduceMarketSaturation: Module_F
{
	scope = 2;
	displayName = "PIMS Reduce Market Saturation";
	category = "PIMS_Modules";
	function = "PIMS_fnc_PIMSModuleDelete";
	icon = "\a3\ui_f\data\igui\cfg\actions\gear_ca.paa";
	functionPriority = 2;
	isGlobal = 0;
	isTriggerActivated = 0;
	isDisposable = 1;
	scopeCurator = 2;
	curatorInfoType = "PIMSReduceMarketSaturationGui";

	class ModuleDescription: ModuleDescription
	{
		description[] =
		{
			"PIMS Reduce Market Saturation"
		};
	};
};