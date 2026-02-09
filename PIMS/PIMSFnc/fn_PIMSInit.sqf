/*
 * fn_PIMSInit.sqf
 *
 * Server-side initialization for the Persistent Inventory Management System (PIMS).
 * Connects to the database via the C# extension DLL, sets up global state,
 * registers player connect/disconnect event handlers for permission-based
 * action assignment, and starts the monitor display update loop.
 *
 * Called by: PIMS_ModuleInit (Eden Editor module)
 * Execution: Server only
 * Parameters: _logic (Object) - Module logic, _synced (Array) - Synchronized objects
 * Returns: true
 */

params [["_logic", objNull], ["_synced", []]];

if (!isServer) exitWith {};

// Connect to the database via the C# extension DLL
private _result = "PIMS-Ext" callExtension "initdb";

if (_result != "OK") then {
	format ["PIMS ERROR: Failed to initialize database: %1", _result] remoteExec ["systemChat", 0];
	diag_log format ["PIMS ERROR: Failed to initialize database: %1", _result];
} else {
	"PIMS INFO: Database initialized successfully" remoteExec ["systemChat", 0];
	diag_log "PIMS INFO: Database initialized successfully";
	
	// #region Global Variables & Helpers
	// HashMap for O(1) player lookups by UID (key: playerUID, value: player object)
	if (isNil "PIMS_PlayerUIDMap") then {
		PIMS_PlayerUIDMap = createHashMap;
	};
	
	// Tracking array for Zeus-spawned PIMS boxes — each entry: [box, inventoryId]
	if (isNil "PIMS_ZeusSpawnedBoxes") then {
		PIMS_ZeusSpawnedBoxes = [];
	};
	
	// Look up a player object by UID from the hashmap; returns objNull if not found or disconnected
	PIMS_fnc_getPlayerByUID = {
		params ["_uid"];
		private _player = PIMS_PlayerUIDMap getOrDefault [_uid, objNull];
		if (!isNull _player && {isPlayer _player}) then {
			_player
		} else {
			objNull
		}
	};
	// #endregion
	
	// #region Container Unlock
	// Unlock all PIMS containers and disable damage before any player events fire.
	// Some parent classes default lockInventory to true, so this must run early.
	private _allInitModules = allMissionObjects "Logic" select {
		typeOf _x == "PIMS_ModuleAddInventory"
	};
	{
		private _objects = synchronizedObjects _x select {!isNil "_x"};
		{
			_x lockInventory false;
			if (typeOf _x == "PIMS_Box") then {
				_x allowDamage false;
				_x setDamage [0, false, objNull, objNull, true];
			};
		} forEach _objects;
	} forEach _allInitModules;
	diag_log format ["PIMS INFO: Unlocked containers for %1 inventory modules at init", count _allInitModules];
	// #endregion
	
	// #region PlayerConnected Handler
	// When a player connects, wait for their object to appear, then check
	// permissions on every inventory module and add interaction actions.
	addMissionEventHandler ["PlayerConnected", {
		params ["_id", "_uid", "_name", "_jip", "_owner", "_idstr"];
		
		if (_uid == "1" || _uid == "") exitWith {};
		
		// CBA_fnc_waitUntilAndExecute: condition polls each frame (unscheduled) for the
		// player object, statement fires once when found — zero scheduler threads.
		[{
			// Condition: search allPlayers for this UID and register in the hashmap
			params ["_uid", "_owner"];
			private _found = false;
			{
				if (getPlayerUID _x == _uid) exitWith {
					PIMS_PlayerUIDMap set [_uid, _x];
					_found = true;
					diag_log format ["PIMS INFO: added player %1 to UID hashmap", _uid];
				};
			} forEach allPlayers;
			_found
		}, {
			// Statement: runs once after the player object is found
			params ["_uid", "_owner"];
			
			// Ask the client to report its addon version for mismatch detection
			[_uid] remoteExec ["PIMS_fnc_PIMSReportVersion", _owner];
			
			// Query admin status once — reused across all modules for this player
			private _adminCheck = format ["isadmin|%1", _uid];
			private _isAdmin = ("PIMS-Ext" callExtension _adminCheck) == "1";
			
			// Local name cache to avoid repeated getinventoryname calls for the same ID
			private _nameCache = createHashMap;
			
			// Collect all editor-placed AddInventory modules
			private _addInventoryModules = allMissionObjects "Logic" select {
				typeOf _x == "PIMS_ModuleAddInventory"
			};
			
			{
				private _module = _x;
				private _inventoryId = _module getVariable ["PIMS_Inventory_Id_Edit", 0];
				private _objects = synchronizedObjects _module select {!isNil "_x"};
				
				// Check if this player has access to this inventory
				private _permCheck = format ["checkpermission|%1|%2", _inventoryId, _uid];
				private _hasPermission = ("PIMS-Ext" callExtension _permCheck) == "1";
				
				if (_hasPermission) then {
					// Resolve inventory display name (cached per ID to avoid repeat queries)
					private _inventoryName = _nameCache getOrDefault [_inventoryId, ""];
					if (_inventoryName == "") then {
						private _nameQuery = format ["getinventoryname|%1", _inventoryId];
						_inventoryName = "PIMS-Ext" callExtension _nameQuery;
						_nameCache set [_inventoryId, _inventoryName];
					};
					
					// #region Action Assignment — Editor-Placed Modules
					{
						private _object = _x;
						
						private _interactionLabelUpload = format ["Upload Content to: %1", _inventoryName];
						private _interactionLabelOpen = format ["Open Menu: %1", _inventoryName];
						
						// "Upload" action — sends container contents to the database
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
						
						// "Open Menu" action — opens the PIMS inventory GUI dialog
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
					// #endregion
				};
				// Players without permission receive no addAction — per-player, no global lock
			} forEach _addInventoryModules;
			
			// #region Action Assignment — Zeus-Spawned Boxes
			if (!isNil "PIMS_ZeusSpawnedBoxes") then {
				{
					_x params ["_box", "_inventoryId"];
					
					if (isNull _box) then {continue};
					
					// Check if this player has access to this Zeus-spawned inventory
					private _permCheck = format ["checkpermission|%1|%2", _inventoryId, _uid];
					private _hasPermission = ("PIMS-Ext" callExtension _permCheck) == "1";
					
					if (_hasPermission) then {
						// Resolve inventory display name (cached per ID)
						private _inventoryName = _nameCache getOrDefault [_inventoryId, ""];
						if (_inventoryName == "") then {
							private _nameQuery = format ["getinventoryname|%1", _inventoryId];
							_inventoryName = "PIMS-Ext" callExtension _nameQuery;
							_nameCache set [_inventoryId, _inventoryName];
						};
						
						private _interactionLabelUpload = format ["Upload Content to: %1", _inventoryName];
						private _interactionLabelOpen = format ["Open Menu: %1", _inventoryName];
						
						// "Upload" action — sends container contents to the database
						[_box,
							[
								_interactionLabelUpload,
								{
									params ["_target", "_caller", "_actionId", "_arguments"];
									private _objectNetId = _arguments select 0;
									private _inventoryId = _arguments select 1;
									private _playerUid = getPlayerUID _caller;
									
									[_objectNetId, _inventoryId, _playerUid] remoteExec ["PIMS_fnc_PIMSUploadInventory", 2];
								},
								[netId _box, _inventoryId],
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
						
						// "Open Menu" action — opens the PIMS inventory GUI dialog
						[_box,
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
								[netId _box, _inventoryId, _isAdmin],
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
					};
				} forEach PIMS_ZeusSpawnedBoxes;
			};
			// #endregion
		}, [_uid, _owner]] call CBA_fnc_waitUntilAndExecute;
	}];
	// #endregion
	
	// #region PlayerDisconnected Handler
	// Remove the player from the UID hashmap when they leave
	addMissionEventHandler ["PlayerDisconnected", {
		params ["_id", "_uid", "_name", "_jip", "_owner", "_idstr"];
		
		if (_uid != "" && _uid != "1") then {
			PIMS_PlayerUIDMap deleteAt _uid;
			diag_log format ["PIMS INFO: Removed player %1 from UID hashmap", _uid];
		};
	}];
	// #endregion
	
	// #region Monitor Display System
	// Delayed one-time setup followed by a CBA Per Frame Handler that checks for
	// inventory changes every 8 seconds and updates in-world monitor screen textures.
	// Runs entirely in unscheduled environment — zero SQF scheduler cost.
	[{
		// #region Monitor Setup (runs once after 10-second delay)
		
		// Collect all AddInventory modules — they don't change during the mission
		private _addInventoryModules = allMissionObjects "Logic" select {
			typeOf _x == "PIMS_ModuleAddInventory"
		};
		
		// Build inventoryId -> [boxes] map as a global variable.
		// Must be global — CBA PFH args serialize HashMaps into plain arrays,
		// which breaks 'keys' and other HashMap commands inside the callback.
		PIMS_MonitorBoxMap = createHashMap;
		PIMS_MonitorNameCache = createHashMap;
		
		{
			private _module = _x;
			private _inventoryId = _module getVariable ["PIMS_Inventory_Id_Edit", 0];
			private _objects = synchronizedObjects _module select {typeOf _x isEqualTo "PIMS_Box"};
			
			if (count _objects > 0) then {
				private _existingBoxes = PIMS_MonitorBoxMap getOrDefault [_inventoryId, []];
				_existingBoxes append _objects;
				PIMS_MonitorBoxMap set [_inventoryId, _existingBoxes];
			};
		} forEach _addInventoryModules;
		
		// Cache inventory display names — they never change during the mission
		{
			private _nameQuery = format ["getinventoryname|%1", _x];
			private _inventoryName = "PIMS-Ext" callExtension _nameQuery;
			PIMS_MonitorNameCache set [_x, _inventoryName];
		} forEach (keys PIMS_MonitorBoxMap);
		
		// Cache for item class -> displayName lookups (populated lazily)
		PIMS_MonitorDisplayNameCache = createHashMap;
		
		// Trigger initial background DB refresh so the first PFH tick has cached data
		{ "PIMS-Ext" callExtension format ["queuerefresh|%1", _x]; } forEach (keys PIMS_MonitorBoxMap);
		// #endregion
		
		// #region Per Frame Handler (runs every 8 seconds in unscheduled environment)
		[{
			// Read HashMaps from globals (PFH args would serialize them to plain arrays)
			private _inventoryBoxMap = PIMS_MonitorBoxMap;
			private _inventoryNameCache = PIMS_MonitorNameCache;
			private _displayNameCache = PIMS_MonitorDisplayNameCache;
			private _inventoryIds = keys _inventoryBoxMap;
			
			// Pick up any Zeus-spawned boxes that appeared since the last tick
			if (!isNil "PIMS_ZeusSpawnedBoxes") then {
				{
					_x params ["_box", "_inventoryId"];
					if (!isNull _box) then {
						private _existingBoxes = _inventoryBoxMap getOrDefault [_inventoryId, []];
						if !(_box in _existingBoxes) then {
							_existingBoxes pushBack _box;
							_inventoryBoxMap set [_inventoryId, _existingBoxes];
							
							// Cache the display name for this newly tracked inventory ID
							if (isNil {_inventoryNameCache get _inventoryId}) then {
								private _nameQuery = format ["getinventoryname|%1", _inventoryId];
								private _inventoryName = "PIMS-Ext" callExtension _nameQuery;
								_inventoryNameCache set [_inventoryId, _inventoryName];
							};
							
							_inventoryIds = keys _inventoryBoxMap;
							diag_log format ["PIMS INFO: Monitor loop picked up Zeus-spawned box for inventory %1", _inventoryId];
						};
					};
				} forEach PIMS_ZeusSpawnedBoxes;
			};
			
			// Compare cached hashes to detect inventory changes since last background refresh
			{
				private _inventoryId = _x;
				private _boxes = _inventoryBoxMap get _inventoryId;
				
				// Single extension call per inventory ID — compares cached hash, no DB query
				private _changeCheck = format ["hasinventorychanged|%1", _inventoryId];
				private _hasChanged = ("PIMS-Ext" callExtension _changeCheck) == "1";
				
				if (_hasChanged) then {
					// Retrieve cached inventory name, items, and money balance from the extension
					private _inventoryName = _inventoryNameCache get _inventoryId;
					
					private _itemsQuery = format ["getinventory|%1", _inventoryId];
					private _itemsResult = "PIMS-Ext" callExtension _itemsQuery;
					
					private _moneyQuery = format ["getinventorymoney|%1", _inventoryId];
					private _moneyResult = "PIMS-Ext" callExtension _moneyQuery;
					private _moneyTotal = parseNumber _moneyResult;
					
					// Build formatted display lines for the monitor texture
					private _data = [];
					
					if (_itemsResult != "" && _itemsResult != "[]") then {
						try {
							private _items = parseSimpleArray _itemsResult;
							{
								private _itemClass = _x select 1;
								private _itemQty = _x select 3;
								
								// Add the value of any physical money items to the total balance
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
								
								// Resolve display name: check cache first, then config categories
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
					
					// Scale font size down when item count exceeds the visible row limit
					private _maxRows = 10;
					private _baseFontSize = 0.1;
					private _itemCount = count _data;
					private _listFontSize = _baseFontSize;
					
					if (_itemCount > _maxRows) then {
						_listFontSize = _baseFontSize * (_maxRows / _itemCount);
						_listFontSize = _listFontSize max 0.02;
					};
					
					// Build procedural texture strings for the monitor screens
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
					
					// Apply textures to every box linked to this inventory ID
					{
						private _crate = _x;
						private _label = _crate getVariable ["PIMS_LabelObject", objNull];
						
						// Spawn a monitor object attached to the crate if one doesn't exist yet
						if (!(toUpper (typeName _label) isEqualTo "STRING")) then {
							if (isNull _label) then {
								private _cratePos = getPosATL _crate;
								_cratePos set [2, (_cratePos select 2) + 1];
								_label = "Land_MultiScreenComputer_01_olive_F" createVehicle _cratePos;
								_label attachTo [_crate, [0, 0, 0.65]];
								_label setVectorDirAndUp [[-1,0,0], [0,0,1]];
								_label setObjectScale 1;
								_crate setVariable ["PIMS_LabelObject", _label, true];
							};
						};
						
						// Set header, item list, and logo textures on the monitor
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
			
			// Queue a non-blocking background DB refresh for the next cycle
			{ "PIMS-Ext" callExtension format ["queuerefresh|%1", _x]; } forEach _inventoryIds;
		}, 8, []] call CBA_fnc_addPerFrameHandler;
		// #endregion
	}, [], 10] call CBA_fnc_waitAndExecute;
	// #endregion
};

true
