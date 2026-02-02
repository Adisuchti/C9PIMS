/*
 * PIMS Init Function (v2 - DLL Extension)
 * Initializes the PIMS system with database connection via extension DLL
 * 
 * This version is MUCH simpler than v1 - all heavy lifting done in C# DLL
 */

params [["_logic", objNull], ["_synced", []]];

if (!isServer) exitWith {};

// Initialize database connection in extension (reads from pims_config.json)
private _result = "PIMS-Ext" callExtension "initdb";

if (_result != "OK") then {
	format ["PIMS ERROR: Failed to initialize database: %1", _result] remoteExec ["systemChat", 0];
	diag_log format ["PIMS ERROR: Failed to initialize database: %1", _result];
} else {
	"PIMS INFO: Database initialized successfully" remoteExec ["systemChat", 0];
	diag_log "PIMS INFO: Database initialized successfully";
	
	// Initialize player UID hashmap for O(1) lookups
	// Key: playerUID, Value: player object
	if (isNil "PIMS_PlayerUIDMap") then {
		PIMS_PlayerUIDMap = createHashMap;
	};
	
	// Helper function to get player by UID using hashmap (O(1) instead of O(n))
	PIMS_fnc_getPlayerByUID = {
		params ["_uid"];
		private _player = PIMS_PlayerUIDMap getOrDefault [_uid, objNull];
		// Validate player is still valid (might have disconnected)
		if (!isNull _player && {isPlayer _player}) then {
			_player
		} else {
			objNull
		}
	};
	
	// Set up player connected event handler
	addMissionEventHandler ["PlayerConnected", {
		params ["_id", "_uid", "_name", "_jip", "_owner", "_idstr"];
		
		if (_uid == "1" || _uid == "") exitWith {}; // Skip invalid UIDs
		
		// Update hashmap with new player (will be updated once player object is available)
		[_uid, _owner] spawn {
			params ["_uid", "_owner"];
			
			// Wait for player object to be available
			waitUntil {
				sleep 0.5;
				private _found = false;
				{
					if (getPlayerUID _x == _uid) exitWith {
						PIMS_PlayerUIDMap set [_uid, _x];
						_found = true;
					};
				} forEach allPlayers;
				_found
			};
			
			// Find all AddInventory modules and set up permissions
			private _addInventoryModules = allMissionObjects "Logic" select {
				typeOf _x == "PIMS_ModuleAddInventory"
			};
			
			{
				private _module = _x;
				private _inventoryId = _module getVariable ["PIMS_Inventory_Id_Edit", 0];
				private _objects = synchronizedObjects _module select {!isNil "_x"};
				
				// Check permission via extension
				private _permCheck = format ["checkpermission|%1|%2", _inventoryId, _uid];
				private _hasPermission = ("PIMS-Ext" callExtension _permCheck) == "1";
				
				if (_hasPermission) then {
					// Get inventory name
					private _nameQuery = format ["getinventoryname|%1", _inventoryId];
					private _inventoryName = "PIMS-Ext" callExtension _nameQuery;
					
					// Check if admin
					private _adminCheck = format ["isadmin|%1", _uid];
					private _isAdmin = ("PIMS-Ext" callExtension _adminCheck) == "1";
					
					{
						private _object = _x;
						_object lockInventory false;
						[_object, false] remoteExec ["lockInventory", 0];
						
						private _interactionLabelUpload = format ["Upload Content to: %1", _inventoryName];
						private _interactionLabelOpen = format ["Open Menu: %1", _inventoryName];
						
						// Add Upload action
						[_object,
							[
								_interactionLabelUpload,
								{
									params ["_target", "_caller", "_actionId", "_arguments"];
									private _objectNetId = _arguments select 0;
									private _inventoryId = _arguments select 1;
									private _playerUid = getPlayerUID _caller;
									
									[_objectNetId, _inventoryId, _playerUid] remoteExec ["PIMS_fnc_PIMSUploadInventory", 2];
								},
								[netId _object, _inventoryId],
								1.5,
								true,
								true,
								"",
								"true",
								5,
								false,
								"",
								""
							]
						] remoteExec ["addAction", _owner];
						
						// Add Open Menu action
						[_object,
							[
								_interactionLabelOpen,
								{
									params ["_target", "_caller", "_actionId", "_arguments"];
									private _objectNetId = _arguments select 0;
									private _inventoryId = _arguments select 1;
									private _isAdmin = _arguments select 2;
									private _ownerUid = getPlayerUID _caller;
									
									[_ownerUid, _objectNetId, _inventoryId, _isAdmin] call PIMS_fnc_PIMSOpenMenu;
								},
								[netId _object, _inventoryId, _isAdmin],
								1.5,
								true,
								true,
								"",
								"true",
								5,
								false,
								"",
								""
							]
						] remoteExec ["addAction", _owner];
					} forEach _objects;
				} else {
					// No permission - lock inventory
					{
						_x lockInventory true;
						[_x, true] remoteExec ["lockInventory", 0];
					} forEach _objects;
				};
			} forEach _addInventoryModules;
		};
	}];
	
	// Clean up hashmap when player disconnects
	addMissionEventHandler ["PlayerDisconnected", {
		params ["_id", "_uid", "_name", "_jip", "_owner", "_idstr"];
		
		if (_uid != "" && _uid != "1") then {
			PIMS_PlayerUIDMap deleteAt _uid;
			diag_log format ["PIMS INFO: Removed player %1 from UID hashmap", _uid];
		};
	}];
	
	// Monitor display system - continuously updates text on monitors showing inventory contents
	// Uses non-blocking change detection to avoid blocking SQF
	// OPTIMIZED: Queries per inventory ID, not per box. Caches names and display data.
	[] spawn {
		waitUntil {time > 10};
		
		// Cache modules once at startup - they don't change during mission
		private _addInventoryModules = allMissionObjects "Logic" select {
			typeOf _x == "PIMS_ModuleAddInventory"
		};
		
		// Build a map of inventory ID -> list of boxes
		// This allows us to check changes once per inventory ID, then update all boxes
		private _inventoryBoxMap = createHashMap; // inventoryId -> [boxes]
		private _inventoryNameCache = createHashMap; // inventoryId -> name (cached permanently)
		private _inventoryModuleMap = createHashMap; // inventoryId -> module
		
		{
			private _module = _x;
			private _inventoryId = _module getVariable ["PIMS_Inventory_Id_Edit", 0];
			private _objects = synchronizedObjects _module select {typeOf _x isEqualTo "PIMS_Box"};
			
			if (count _objects > 0) then {
				private _existingBoxes = _inventoryBoxMap getOrDefault [_inventoryId, []];
				_existingBoxes append _objects;
				_inventoryBoxMap set [_inventoryId, _existingBoxes];
				_inventoryModuleMap set [_inventoryId, _module];
			};
		} forEach _addInventoryModules;
		
		// Get unique inventory IDs
		private _inventoryIds = keys _inventoryBoxMap;
		
		// Pre-cache inventory names (they never change during mission)
		{
			private _nameQuery = format ["getinventoryname|%1", _x];
			private _inventoryName = "PIMS-Ext" callExtension _nameQuery;
			_inventoryNameCache set [_x, _inventoryName];
		} forEach _inventoryIds;
		
		// Display name cache for items (class -> displayName)
		private _displayNameCache = createHashMap;
		
		while {true} do {
			// Phase 1: Queue background refresh for all inventories (non-blocking)
			// This returns immediately while the extension fetches data in the background
			{
				private _refreshCmd = format ["queuerefresh|%1", _x];
				"PIMS-Ext" callExtension _refreshCmd;
			} forEach _inventoryIds;
			
			// Wait for background refresh to complete (give it some time)
			sleep 5;
			
			// Phase 2: Check for changes ONCE per inventory ID, then update all boxes for that ID
			{
				private _inventoryId = _x;
				private _boxes = _inventoryBoxMap get _inventoryId;
				
				// Check if inventory has changed using cached data (ONE call per inventory ID)
				private _changeCheck = format ["hasinventorychanged|%1", _inventoryId];
				private _hasChanged = ("PIMS-Ext" callExtension _changeCheck) == "1";
				
				// Only process if changes occurred
				if (_hasChanged) then {
					// Get inventory name from SQF cache (no extension call)
					private _inventoryName = _inventoryNameCache get _inventoryId;
					
					// Get inventory items (cached in extension after background refresh)
					private _itemsQuery = format ["getinventory|%1", _inventoryId];
					private _itemsResult = "PIMS-Ext" callExtension _itemsQuery;
					
					private _moneyQuery = format ["getinventorymoney|%1", _inventoryId];
					private _moneyResult = "PIMS-Ext" callExtension _moneyQuery;
					private _moneyTotal = parseNumber _moneyResult;
					
					// Build display data ONCE for this inventory
					private _data = [];
					
					if (_itemsResult != "" && _itemsResult != "[]") then {
						try {
							private _items = parseSimpleArray _itemsResult;
							{
								private _itemClass = _x select 1;
								private _itemQty = _x select 3;
								
								// Calculate money
								private _moneyValue = switch (_itemClass) do {
									case "PIMS_Money_1": {1};
									case "PIMS_Money_10": {10};
									case "PIMS_Money_50": {50};
									case "PIMS_Money_100": {100};
									case "PIMS_Money_500": {500};
									case "PIMS_Money_1000": {1000};
									default {0};
								};
								_moneyTotal = _moneyTotal + (_moneyValue * _itemQty);
								
								// Get display name from cache or config
								private _displayName = _displayNameCache getOrDefault [_itemClass, ""];
								if (_displayName == "") then {
									_displayName = getText (configFile >> "CfgWeapons" >> _itemClass >> "displayName");
									if (_displayName == "") then {
										_displayName = getText (configFile >> "CfgMagazines" >> _itemClass >> "displayName");
									};
									if (_displayName == "") then {
										_displayName = getText (configFile >> "CfgVehicles" >> _itemClass >> "displayName");
									};
									if (_displayName == "") then {
										_displayName = getText (configFile >> "CfgGlasses" >> _itemClass >> "displayName");
									};
									if (_displayName == "") then {
										_displayName = _itemClass;
									};
									_displayNameCache set [_itemClass, _displayName];
								};
								
								_data pushBack format ["%1x %2", _itemQty, _displayName];
							} forEach _items;
						} catch {
							diag_log format ["PIMS ERROR: Failed to parse inventory items: %1", _itemsResult];
						};
					};
					
					private _listText = _data joinString "\n";
					
					// Calculate dynamic font size
					private _maxRows = 10;
					private _baseFontSize = 0.1;
					private _itemCount = count _data;
					private _listFontSize = _baseFontSize;
					
					if (_itemCount > _maxRows) then {
						_listFontSize = _baseFontSize * (_maxRows / _itemCount);
						_listFontSize = _listFontSize max 0.02;
					};
					
					// Pre-compute texture strings
					private _topTexture = format [
						"#(rgb,512,512,3)text(1,0,""RobotoCondensed"",0.1,""#333333"",""#00ff00"",""%1\n$ %2"")", 
						_inventoryName, 
						_moneyTotal
					];
					private _mainTexture = format [
						"#(rgb,512,512,3)text(1,1,""RobotoCondensed"",%2,""#333333"",""#00ff00"",""%1"")", 
						_listText, 
						_listFontSize
					];
					
					// Update ALL boxes for this inventory ID (texture data computed once)
					{
						private _crate = _x;
						private _label = _crate getVariable ["PIMS_LabelObject", objNull];
						
						// Create monitor if it doesn't exist
						if (!(toUpper (typeName _label) isEqualTo "STRING")) then {
							if (isNull _label) then {
								private _cratePos = getPosATL _crate;
								_label = "Land_MultiScreenComputer_01_olive_F" createVehicle _cratePos;
								_label attachTo [_crate, [0, 0, 0.65]];
								_label setVectorDirAndUp [[-1,0,0], [0,0,1]];
								_label setObjectScale 1;
								_crate setVariable ["PIMS_LabelObject", _label, true];
							};
						};
						
						if (!isNull _label) then {
							_label setObjectTextureGlobal [2, _topTexture];
							_label setObjectTextureGlobal [1, _mainTexture];
							_label setObjectTextureGlobal [3, "C9 Tweaks\Flags\C9_Logo_co.paa"];
							_crate setVariable ["PIMS_LabelObject", _label, true];
						};
					} forEach _boxes;
					
					diag_log format ["PIMS INFO: Updated %1 monitors for inventory %2", count _boxes, _inventoryId];
				};
			} forEach _inventoryIds;
			
			// Wait before next refresh cycle
			sleep 3;
		};
	};
};

true
