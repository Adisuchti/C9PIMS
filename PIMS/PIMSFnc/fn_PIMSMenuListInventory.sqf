/*
 * fn_PIMSMenuListInventory.sqf
 *
 * Client-side GUI controller for the PIMS inventory dialog.
 * Initializes all dialog controls, defines event handler functions for item
 * selection, retrieval, money withdrawal, and view switching, then starts
 * an auto-refresh loop that polls the server every 3 seconds.
 *
 * Called by: PIMS_fnc_PIMSOpenMenu (spawned)
 * Execution: Client only
 * Parameters: _containerNetId (String), _inventoryId (Number), _isAdmin (Boolean)
 * Returns: true
 */

params ["_containerNetId", "_inventoryId", "_isAdmin"];

disableSerialization;

private _playerUid = getPlayerUID player;

// #region Session State
// Store dialog session state in uiNamespace so all handlers can access it
uiNamespace setVariable ["PIMS_containerNetId", _containerNetId];
uiNamespace setVariable ["PIMS_inventoryId", _inventoryId];
uiNamespace setVariable ["PIMS_isAdmin", _isAdmin];
uiNamespace setVariable ["PIMS_selectedIndex", 0];
uiNamespace setVariable ["PIMS_quantity", 1];
uiNamespace setVariable ["PIMS_Uid", _playerUid];
uiNamespace setVariable ["PIMS_ViewMode", 0]; // 0 = Inventory, 2 = Bank
uiNamespace setVariable ["PIMS_MoneyTypes", [["PIMS_Money_1", 1], ["PIMS_Money_10", 10], ["PIMS_Money_50", 50], ["PIMS_Money_100", 100], ["PIMS_Money_500", 500], ["PIMS_Money_1000", 1000]]];
uiNamespace setVariable ["PIMS_isUpdating", false];
missionNamespace setVariable ["PIMS_closeMenu_" + _playerUid, false];
// #endregion

// #region Dialog Controls
// Look up the dialog and grab references to key controls
private _display = findDisplay 142351;
if (isNull _display) exitWith {
	systemChat "PIMS ERROR: Dialog not found";
};

//systemChat "PIMS DEBUG: Dialog found, initializing...";

private _listBox = _display displayCtrl 1500;
private _infoGroup = _display displayCtrl 1003;
private _infoText = _infoGroup controlsGroupCtrl 1000;
private _quantityEdit = _display displayCtrl 1800;
private _titleCtrl = _display displayCtrl 1001;

// Set initial button states
private _topButton = _display displayCtrl 1700;
_topButton ctrlSetText "Inventory";

// Hide unused buy button
private _buyButton = _display displayCtrl 1601;
_buyButton ctrlShow false;

// Show retrieve, retrieve-all, and retrieve-everything buttons
private _retrieveButton = _display displayCtrl 1602;
_retrieveButton ctrlShow true;

private _retrieveAllButton = _display displayCtrl 1603;
_retrieveAllButton ctrlShow true;

private _retrieveAllItemsButton = _display displayCtrl 1600;
_retrieveAllItemsButton ctrlShow true;

// Show and initialize the quantity input field
_quantityEdit ctrlShow true;
_quantityEdit ctrlSetText "1";
// #endregion

// #region Helper Functions
// Resolve an item class to its config path (CfgWeapons/Magazines/Vehicles/Glasses) and mass
fn_getConfigPathAndWeight = {
	params ["_itemClass"];
	
	private _cfg = configFile >> "CfgWeapons" >> _itemClass;
	private _parentPath = "CfgWeapons";
	if (!isClass _cfg) then {
		_cfg = configFile >> "CfgMagazines" >> _itemClass;
		_parentPath = "CfgMagazines";
	};
	if (!isClass _cfg) then {
		_cfg = configFile >> "CfgVehicles" >> _itemClass;
		_parentPath = "CfgVehicles";
	};
	if (!isClass _cfg) then {
		_cfg = configFile >> "CfgGlasses" >> _itemClass;
		_parentPath = "CfgGlasses";
	};
	
	private _mass = 0;
	if (_parentPath == "CfgWeapons") then {
		_mass = getNumber (_cfg >> "ItemInfo" >> "mass");
		if (_mass == 0) then {
			_mass = getNumber (_cfg >> "WeaponSlotsInfo" >> "mass");
		};
	} else {
		if (_parentPath == "CfgMagazines") then {
			_mass = getNumber (_cfg >> "mass");
		} else {
			if (_parentPath == "CfgVehicles") then {
				_mass = getNumber (_cfg >> "mass");
			};
		};
	};
	
	[_cfg, _parentPath, _mass]
};
uiNamespace setVariable ["PIMS_fnc_getConfigPathAndWeight", fn_getConfigPathAndWeight];
// #endregion

// #region Update Function
// fn_updateInventoryView — Master refresh routine for the dialog listbox.
// Requests the latest inventory data from the server via remoteExec, waits for the
// response, then performs an incremental diff against the current listbox entries to
// minimise flicker.  Handles both Inventory view (item list) and Bank view (money
// denominations), adjusts button visibility per view mode, and restores the previous
// selection after the refresh to prevent unwanted auto-scrolling.
fn_updateInventoryView = {
	//systemChat "PIMS DEBUG: fn_updateInventoryView called";
	
	// Guard — skip if another refresh is already running to avoid overlapping server calls
	private _isUpdating = uiNamespace getVariable ["PIMS_isUpdating", false];
	if (_isUpdating) exitWith {
		//systemChat "PIMS DEBUG: Update already in progress, exiting";
	};
	
	uiNamespace setVariable ["PIMS_isUpdating", true];
	
	private _display = findDisplay 142351;
	if (isNull _display) exitWith {
		uiNamespace setVariable ["PIMS_isUpdating", false];
	};
	
	private _inventoryId = uiNamespace getVariable ["PIMS_inventoryId", 0];
	private _listBox = _display displayCtrl 1500;
	private _infoGroup = _display displayCtrl 1003;
	private _infoText = _infoGroup controlsGroupCtrl 1000;
	private _playerUid = getPlayerUID player;
	private _viewMode = uiNamespace getVariable ["PIMS_ViewMode", 0];
	
	// Fire a server-side request for the latest inventory contents and money balance
	missionNamespace setVariable [format ["PIMS_InventoryDataReady_%1", _playerUid], false];
	[_inventoryId, _playerUid] remoteExec ["PIMS_fnc_PIMSGetInventoryData", 2];
	
	// Block until the server writes the response into missionNamespace (100 ms poll)
	waitUntil {
		sleep 0.1;
		missionNamespace getVariable [format ["PIMS_InventoryDataReady_%1", _playerUid], false]
	};
	
	// Read the server's response — item array, money balance, and display name
	private _items = missionNamespace getVariable [format ["PIMS_InventoryItems_%1", _playerUid], []];
	private _inventoryMoney = missionNamespace getVariable [format ["PIMS_InventoryMoney_%1", _playerUid], 0];
	private _inventoryName = missionNamespace getVariable [format ["PIMS_InventoryName_%1", _playerUid], "Unknown"];
	
	// Set the dialog title to the inventory's display name
	private _titleCtrl = _display displayCtrl 1001;
	_titleCtrl ctrlSetStructuredText parseText format ["<t align='center' size='1.5' color='#ff00ff66'>%1</t>", _inventoryName];
	
	// Retrieve the previous listbox snapshot and view mode for incremental diff
	private _cachedItems = uiNamespace getVariable ["PIMS_cachedListBoxItems", []];
	private _cachedViewMode = uiNamespace getVariable ["PIMS_cachedViewMode", -1];
	
	// If the user switched views since last refresh, wipe the listbox and cache
	private _viewModeChanged = (_cachedViewMode != _viewMode);
	if (_viewModeChanged) then {
		lbClear _listBox;
		uiNamespace setVariable ["PIMS_cachedListBoxItems", []];
		uiNamespace setVariable ["PIMS_cachedViewMode", _viewMode];
	};
	
	// Cache the latest data so event handlers can read it without another server call
	uiNamespace setVariable ["PIMS_currentItems", _items];
	uiNamespace setVariable ["PIMS_inventoryMoney", _inventoryMoney];
	
	//systemChat format ["PIMS DEBUG: Item count: %1, Money: %2", count _items, _inventoryMoney];
	
	// Snapshot the current selection so it can be restored after the diff
	private _selectedIndex = lbCurSel _listBox;
	private _selectedData = "";
	if (_selectedIndex >= 0) then {
		_selectedData = _listBox lbData _selectedIndex;
	};
	
	// Assemble the target listbox entries depending on the active view mode
	private _newListBoxItems = [];

	private _back1 = _display displayCtrl 16020;
	private _back2 = _display displayCtrl 16030;
	private _back3 = _display displayCtrl 16000;
	
	if (_viewMode == 0) then {
		// Inventory view — build one row per stored item with name, quantity, and icon
		{
			_x params ["_contentItemId", "_itemClass", "_properties", "_quantity"];
			
			// Get display name from config
			private _configData = [_itemClass] call fn_getConfigPathAndWeight;
			_configData params ["_cfg", "_parentPath", "_mass"];
			
			private _displayName = getText (_cfg >> "displayName");
			if (_displayName == "") then {
				_displayName = _itemClass;
			};
			
			private _text = format ["%1 (x%2)", _displayName, _quantity];
			private _data = str _contentItemId;
			private _value = _quantity;
			private _picture = getText (_cfg >> "picture");
			
			_newListBoxItems pushBack [_text, _data, _value, _picture];
		} forEach _items;

		_back1 ctrlShow true;
		_back2 ctrlShow true;
		_back3 ctrlShow true;
	} else {
		if (_viewMode == 2) then {
			// Bank view — list each money denomination with its icon
			private _moneyTypes = uiNamespace getVariable ["PIMS_MoneyTypes", []];
			{
				_x params ["_moneyClass", "_moneyValue"];
				
				private _cfg = configFile >> "CfgWeapons" >> _moneyClass;
				private _displayName = getText (_cfg >> "displayName");
				if (_displayName == "") then {
					_displayName = _moneyClass;
				};
				
				private _text = format ["%1", _displayName];
				private _data = _moneyClass;
				private _value = _moneyValue;
				private _picture = getText (_cfg >> "picture");
				
				_newListBoxItems pushBack [_text, _data, _value, _picture];
			} forEach _moneyTypes;
		};
		_back1 ctrlShow true;
		_back2 ctrlShow false; 
		_back3 ctrlShow false;
	};
	
	// --- Incremental listbox diff: update, add, or remove rows as needed ---
	private _currentSize = lbSize _listBox;
	private _newSize = count _newListBoxItems;
	
	// Pass 1 — overwrite rows that already exist but whose content changed
	private _minSize = _currentSize min _newSize;
	for [{private _i = 0}, {_i < _minSize}, {_i = _i + 1}] do {
		private _newItem = _newListBoxItems select _i;
		_newItem params ["_text", "_data", "_value", "_picture"];
		
		// Check if entry needs update
		private _currentText = _listBox lbText _i;
		private _currentData = _listBox lbData _i;
		
		if (_currentText != _text || _currentData != _data) then {
			_listBox lbSetText [_i, _text];
			_listBox lbSetData [_i, _data];
			_listBox lbSetValue [_i, _value];
			if (_picture != "") then {
				_listBox lbSetPicture [_i, _picture];
			};
		};
	};
	
	// Pass 2 — append new rows if the target list is longer than the current listbox
	if (_newSize > _currentSize) then {
		for [{private _i = _currentSize}, {_i < _newSize}, {_i = _i + 1}] do {
			private _newItem = _newListBoxItems select _i;
			_newItem params ["_text", "_data", "_value", "_picture"];
			
			private _index = _listBox lbAdd _text;
			_listBox lbSetData [_index, _data];
			_listBox lbSetValue [_index, _value];
			if (_picture != "") then {
				_listBox lbSetPicture [_index, _picture];
			};
		};
	};
	
	// Pass 3 — trim excess rows from the bottom if the target list is shorter
	if (_currentSize > _newSize) then {
		for [{private _i = _currentSize - 1}, {_i >= _newSize}, {_i = _i - 1}] do {
			lbDelete [_listBox, _i];
		};
	};
	
	// Persist the new snapshot for the next diff cycle
	uiNamespace setVariable ["PIMS_cachedListBoxItems", _newListBoxItems];
	
	// Restore the previous selection by matching lbData (index-independent).
	// Only call lbSetCurSel when the index actually differs to prevent auto-scrolling.
	private _currentSelection = lbCurSel _listBox;
	
	if (_selectedData != "") then {
		private _found = false;
		private _targetIndex = -1;
		for [{private _i = 0}, {_i < (lbSize _listBox)}, {_i = _i + 1}] do {
			if ((_listBox lbData _i) == _selectedData) exitWith {
				_targetIndex = _i;
				_found = true;
			};
		};
		
		// Only restore selection if it changed (avoids auto-scroll on refresh)
		if (_found && _currentSelection != _targetIndex) then {
			_listBox lbSetCurSel _targetIndex;
		};
		
		// If previous selection not found, select first
		if (!_found && (lbSize _listBox) > 0 && _currentSelection < 0) then {
			_listBox lbSetCurSel 0;
			[_listBox, 0] call onListboxSelectionChanged;
		};
	} else {
		// No previous selection, select first item only if nothing is selected
		if ((lbSize _listBox) > 0 && _currentSelection < 0) then {
			_listBox lbSetCurSel 0;
			[_listBox, 0] call onListboxSelectionChanged;
		};
	};
	
	// Relabel the top toggle button to reflect the current view mode
	private _topButton = _display displayCtrl 1700;
	if (_viewMode == 0) then {
		_topButton ctrlSetText "Inventory";
	} else {
		if (_viewMode == 2) then {
			_topButton ctrlSetText "Bank";
		};
	};
	
	// Show or hide action buttons depending on view mode (bank hides bulk retrieve)
	private _retrieveButton = _display displayCtrl 1602;
	private _retrieveAllButton = _display displayCtrl 1603;
	private _retrieveAllItemsButton = _display displayCtrl 1600;
	private _quantityEdit = _display displayCtrl 1800;
	
	if (_viewMode == 0) then {
		_retrieveButton ctrlShow true;
		_retrieveAllButton ctrlShow true;
		_retrieveAllItemsButton ctrlShow true;
		_quantityEdit ctrlShow true;
	} else {
		if (_viewMode == 2) then {
			_retrieveButton ctrlShow true;
			_retrieveAllButton ctrlShow false;
			_retrieveAllItemsButton ctrlShow false;
			_quantityEdit ctrlShow true;
		};
	};
	
	// Release the concurrent-update guard so the next refresh cycle can proceed
	uiNamespace setVariable ["PIMS_isUpdating", false];
};
uiNamespace setVariable ["PIMS_fnc_updateInventoryView", fn_updateInventoryView];
// #endregion

// #region Selection Handler
// onListboxSelectionChanged — Populates the right-hand detail panel when the user
// clicks a listbox row.  In Inventory view it shows the item image, class name,
// type, quantity, per-unit and total weight, state/properties, and description.
// In Bank view it shows the denomination value, current balance, and a brief note.
onListboxSelectionChanged = {
	params ["_control", "_selectedIndex"];
	
	uiNamespace setVariable ["PIMS_selectedIndex", _selectedIndex];
	
	private _viewMode = uiNamespace getVariable ["PIMS_ViewMode", 0];
	private _items = uiNamespace getVariable ["PIMS_currentItems", []];
	private _inventoryMoney = uiNamespace getVariable ["PIMS_inventoryMoney", 0];
	
	private _display = findDisplay 142351;
	private _infoGroup = _display displayCtrl 1003;
	private _infoCtrl = _infoGroup controlsGroupCtrl 1000;
	
	if (_viewMode == 0) then {
		// Inventory view — show full item details or a summary if nothing is selected
		if (_selectedIndex < 0 || _selectedIndex >= count _items) exitWith {
			_infoCtrl ctrlSetStructuredText parseText format [
				"<t align='center' size='1.3'>Inventory</t><br/><br/>" +
				"<t size='1.0'>Total Items: %1</t><br/>" +
				"<t size='1.0'>Balance: %2 Credits</t><br/><br/>" +
				"<t size='0.9'>Select an item to view details</t>",
				count _items,
				_inventoryMoney
			];
		};
		
		private _item = _items select _selectedIndex;
		_item params ["_contentItemId", "_itemClass", "_properties", "_quantity"];
		
		private _configData = [_itemClass] call fn_getConfigPathAndWeight;
		_configData params ["_cfg", "_parentPath", "_mass"];

		private _itemType = ([_itemClass] call BIS_fnc_itemType) select 1;
		
		private _displayName = getText (_cfg >> "displayName");
		private _description = getText (_cfg >> "descriptionShort");
		private _descriptionLong = getText (_cfg >> "description");
		private _picture = getText (_cfg >> "picture");
		
		// Derive total stack weight from per-unit mass × quantity
		private _totalWeight = _mass * _quantity;
		
		// Compose the structured-text detail string (title, image, stats, description)
		private _detailText = format [
			"<t align='center' size='1.3'>%1</t><br/><br/>",
			_displayName
		];
		
		// Insert the item picture if one is defined in config
		if (_picture != "") then {
			_detailText = _detailText + format [
				"<img image='%1' size='3'/><br/><br/>",
				_picture
			];
		};
		
		_detailText = _detailText + format [
			"<t size='1.0'>Class: </t><t size='0.9'>%1</t><br/>" +
			"<t size='1.0'>Type: </t><t size='0.9'>%2</t><br/>" +
			"<t size='1.0'>Quantity: </t><t size='0.9'>%3</t><br/>" +
			"<t size='1.0'>Weight (each): </t><t size='0.9'>%4</t><br/>" +
			"<t size='1.0'>Weight (total): </t><t size='0.9'>%5</t><br/>" +
			"<t size='1.0'>State: </t><t size='0.9'>%6</t><br/><br/>",
			_itemClass,
			_itemType,
			_quantity,
			_mass,
			_totalWeight,
			_properties
		];
		
		if (_description != "") then {
			_detailText = _detailText + format [
				"<t size='0.9'>%1</t>",
				_description
			];
		};
		
		_infoCtrl ctrlSetStructuredText parseText _detailText;
		
	} else {
		if (_viewMode == 2) then {
			// Bank view — show denomination details or a summary if nothing is selected
			private _moneyTypes = uiNamespace getVariable ["PIMS_MoneyTypes", []];
			
			if (_selectedIndex < 0 || _selectedIndex >= count _moneyTypes) exitWith {
				_infoCtrl ctrlSetStructuredText parseText format [
					"<t align='center' size='1.3'>Bank</t><br/><br/>" +
					"<t size='1.0'>Balance: %1 Credits</t><br/><br/>" +
					"<t size='0.9'>Select a denomination to withdraw</t>",
					_inventoryMoney
				];
			};
			
			private _moneyType = _moneyTypes select _selectedIndex;
			_moneyType params ["_moneyClass", "_moneyValue"];
			
			private _cfg = configFile >> "CfgWeapons" >> _moneyClass;
			private _displayName = getText (_cfg >> "displayName");
			private _picture = getText (_cfg >> "picture");
			
			private _detailText = format [
				"<t align='center' size='1.3'>%1</t><br/><br/>",
				_displayName
			];
			
			if (_picture != "") then {
				_detailText = _detailText + format [
					"<img image='%1' size='3'/><br/><br/>",
					_picture
				];
			};
			
			_detailText = _detailText + format [
				"<t size='1.0'>Value: </t><t size='0.9'>%1 Credits</t><br/>" +
				"<t size='1.0'>Current Balance: </t><t size='0.9'>%2 Credits</t><br/><br/>" +
				"<t size='0.9'>Withdrawing money will convert your balance into physical currency items.</t>",
				_moneyValue,
				_inventoryMoney
			];
			
			_infoCtrl ctrlSetStructuredText parseText _detailText;
		};
	};
};
// #endregion

// #region Retrieve Handlers
// onRetrieveButtonPressed — Handles the main "Retrieve" button.
// In Inventory mode, takes the user-specified quantity of the selected item from the
// database and spawns it into the linked container.  In Bank mode, converts the
// selected denomination × quantity into physical money items, deducting the balance.
// Both paths use spawn + waitUntil so the UI stays responsive during the server call.
onRetrieveButtonPressed = {
	params ["_control", "_button", "_xPos", "_yPos", "_shift", "_ctrl", "_alt"];
	
	private _display = findDisplay 142351;
	private _listBox = _display displayCtrl 1500;
	private _quantityEdit = _display displayCtrl 1800;
	private _viewMode = uiNamespace getVariable ["PIMS_ViewMode", 0];
	
	private _selectedIndex = lbCurSel _listBox;
	if (_selectedIndex < 0) exitWith {
		systemChat "PIMS WARNING: No item selected";
	};
	
	private _containerNetId = uiNamespace getVariable ["PIMS_containerNetId", ""];
	private _playerUid = getPlayerUID player;
	
	if (_viewMode == 0) then {
		// Inventory mode — retrieve the requested quantity of the selected item
		[_containerNetId, _playerUid, _selectedIndex, _quantityEdit] spawn {
			params ["_containerNetId", "_playerUid", "_selectedIndex", "_quantityEdit"];
			
			private _items = uiNamespace getVariable ["PIMS_currentItems", []];
			private _item = _items select _selectedIndex;
			_item params ["_contentItemId", "_itemClass", "_properties", "_quantity"];
			
			private _retrieveQty = parseNumber (ctrlText _quantityEdit);
			if (_retrieveQty <= 0) exitWith {
				systemChat "PIMS WARNING: Invalid quantity";
			};
			if (_retrieveQty > _quantity) then {
				_retrieveQty = _quantity;
			};
			
			private _inventoryId = uiNamespace getVariable ["PIMS_inventoryId", 0];
			
			// Clear completion flags before issuing the server request
			missionNamespace setVariable [format ["PIMS_retrieveDone_%1", _playerUid], false];
			missionNamespace setVariable [format ["PIMS_retrieveSuccess_%1", _playerUid], false];
			
			// Ask the server to remove the items from the DB and add them to the container
			[_containerNetId, _inventoryId, _contentItemId, _itemClass, _properties, _retrieveQty, _playerUid] remoteExec ["PIMS_fnc_PIMSRetrieveItemFromDatabase", 2];
			
			systemChat format ["PIMS INFO: Retrieving %1x %2...", _retrieveQty, _itemClass];
			
			// Block until the server signals completion
			waitUntil {
				sleep 0.1;
				missionNamespace getVariable [format ["PIMS_retrieveDone_%1", _playerUid], false]
			};
			
			private _success = missionNamespace getVariable [format ["PIMS_retrieveSuccess_%1", _playerUid], false];
			if (_success) then {
				systemChat "PIMS INFO: Item retrieved successfully";
				
				// Immediately refresh the listbox to reflect the change
				call fn_updateInventoryView;
			} else {
				systemChat "PIMS ERROR: Failed to retrieve item";
			};
		};
	} else {
		if (_viewMode == 2) then {
			// Bank mode — withdraw the selected denomination as physical money items
			[_containerNetId, _playerUid, _selectedIndex, _quantityEdit] spawn {
				params ["_containerNetId", "_playerUid", "_selectedIndex", "_quantityEdit"];
				
				private _moneyTypes = uiNamespace getVariable ["PIMS_MoneyTypes", []];
				private _moneyType = _moneyTypes select _selectedIndex;
				_moneyType params ["_moneyClass", "_moneyValue"];
				
				private _withdrawQty = parseNumber (ctrlText _quantityEdit);
				if (_withdrawQty <= 0) exitWith {
					systemChat "PIMS WARNING: Invalid quantity";
				};
				
				private _inventoryMoney = uiNamespace getVariable ["PIMS_inventoryMoney", 0];
				private _totalAmount = _moneyValue * _withdrawQty;
				
				if (_totalAmount > _inventoryMoney) exitWith {
					systemChat format ["PIMS WARNING: Insufficient funds. You have %1 credits, need %2 credits", _inventoryMoney, _totalAmount];
				};
				
				private _inventoryId = uiNamespace getVariable ["PIMS_inventoryId", 0];
				
				// Clear completion flags before issuing the server request
				missionNamespace setVariable [format ["PIMS_withdrawDone_%1", _playerUid], false];
				missionNamespace setVariable [format ["PIMS_withdrawSuccess_%1", _playerUid], false];
				
				// Ask the server to deduct the balance and spawn money items into the container
				[_containerNetId, _inventoryId, _moneyClass, _withdrawQty, _playerUid] remoteExec ["PIMS_fnc_PIMSWithdrawMoney", 2];
				
				systemChat format ["PIMS INFO: Withdrawing %1 credits (%2x %3)...", _totalAmount, _withdrawQty, _moneyClass];
				
				// Block until the server signals completion
				waitUntil {
					sleep 0.1;
					missionNamespace getVariable [format ["PIMS_withdrawDone_%1", _playerUid], false]
				};
				
				private _success = missionNamespace getVariable [format ["PIMS_withdrawSuccess_%1", _playerUid], false];
				if (_success) then {
					// Immediately refresh the listbox to reflect the updated balance
					call fn_updateInventoryView;
				} else {
					systemChat "PIMS ERROR: Failed to withdraw money";
				};
			};
		};
	};
};

// onRetrieveAllButtonPressed — Retrieves the full quantity of the selected item in
// one server call, bypassing the quantity input field.
onRetrieveAllButtonPressed = {
	params ["_control", "_button", "_xPos", "_yPos", "_shift", "_ctrl", "_alt"];
	
	private _display = findDisplay 142351;
	private _listBox = _display displayCtrl 1500;
	
	private _selectedIndex = lbCurSel _listBox;
	if (_selectedIndex < 0) exitWith {
		systemChat "PIMS WARNING: No item selected";
	};
	
	// Spawn so waitUntil can suspend without blocking the UI
	[_selectedIndex] spawn {
		params ["_selectedIndex"];
		
		private _items = uiNamespace getVariable ["PIMS_currentItems", []];
		private _item = _items select _selectedIndex;
		_item params ["_contentItemId", "_itemClass", "_properties", "_quantity"];
		
		private _containerNetId = uiNamespace getVariable ["PIMS_containerNetId", ""];
		private _playerUid = getPlayerUID player;
		private _inventoryId = uiNamespace getVariable ["PIMS_inventoryId", 0];
		
		// Clear completion flags before issuing the server request
		missionNamespace setVariable [format ["PIMS_retrieveDone_%1", _playerUid], false];
		missionNamespace setVariable [format ["PIMS_retrieveSuccess_%1", _playerUid], false];
		
		// Ask the server to move the full stack from the DB into the container
		[_containerNetId, _inventoryId, _contentItemId, _itemClass, _properties, _quantity, _playerUid] remoteExec ["PIMS_fnc_PIMSRetrieveItemFromDatabase", 2];
		
		systemChat format ["PIMS INFO: Retrieving all %1x %2...", _quantity, _itemClass];
		
		// Block until the server signals completion
		waitUntil {
			sleep 0.1;
			missionNamespace getVariable [format ["PIMS_retrieveDone_%1", _playerUid], false]
		};
		
		private _success = missionNamespace getVariable [format ["PIMS_retrieveSuccess_%1", _playerUid], false];
		if (_success) then {
			systemChat "PIMS INFO: All items retrieved successfully";
			
			// Immediately refresh the listbox to reflect the change
			call fn_updateInventoryView;
		} else {
			systemChat "PIMS ERROR: Failed to retrieve items";
		};
	};
};

// onRetrieveAllItemsTotalButtonPressed — Empties the entire inventory in one
// server call, moving every stored item into the linked container.
onRetrieveAllItemsTotalButtonPressed = {
	params ["_control", "_button", "_xPos", "_yPos", "_shift", "_ctrl", "_alt"];
	
	// Spawn so waitUntil can suspend without blocking the UI
	[] spawn {
		private _containerNetId = uiNamespace getVariable ["PIMS_containerNetId", ""];
		private _playerUid = getPlayerUID player;
		private _inventoryId = uiNamespace getVariable ["PIMS_inventoryId", 0];
		
		// Clear completion flags before issuing the server request
		missionNamespace setVariable [format ["PIMS_retrieveAllDone_%1", _playerUid], false];
		missionNamespace setVariable [format ["PIMS_retrieveAllSuccess_%1", _playerUid], false];
		
		// Ask the server to move every item from the DB into the container
		[_containerNetId, _inventoryId, _playerUid] remoteExec ["PIMS_fnc_PIMSRetrieveAllItems", 2];
		
		// Block until the server signals completion
		waitUntil {
			sleep 0.1;
			missionNamespace getVariable [format ["PIMS_retrieveAllDone_%1", _playerUid], false]
		};
		
		private _success = missionNamespace getVariable [format ["PIMS_retrieveAllSuccess_%1", _playerUid], false];
		
		// Refresh the listbox regardless of outcome so the UI stays in sync
		call fn_updateInventoryView;
	};
};
// #endregion

// #region View & UI Handlers
// onChangeView — Toggles ViewMode between Inventory (0) and Bank (2), then
// spawns a full refresh so the listbox and detail panel update immediately.
onChangeView = {
	params ["_control", "_button", "_xPos", "_yPos", "_shift", "_ctrl", "_alt"];
	
	private _viewMode = uiNamespace getVariable ["PIMS_ViewMode", 0];
	
	// Flip the stored view mode between the two states
	if (_viewMode == 0) then {
		uiNamespace setVariable ["PIMS_ViewMode", 2];
	} else {
		uiNamespace setVariable ["PIMS_ViewMode", 0];
	};
	
	// Refresh the listbox and re-trigger selection to update the detail panel
	[] spawn {
		call fn_updateInventoryView;
		
		// Re-fire the selection handler so the detail panel matches the new view
		private _display = findDisplay 142351;
		private _listBox = _display displayCtrl 1500;
		private _selectedIndex = lbCurSel _listBox;
		if (_selectedIndex >= 0) then {
			[_listBox, _selectedIndex] call onListboxSelectionChanged;
		} else {
			[_listBox, -1] call onListboxSelectionChanged;
		};
	};
};

// onUpdateInfo — Manual refresh button.  Spawns a full inventory refresh and
// re-triggers the selection handler so the detail panel stays current.
onUpdateInfo = {
	params ["_control", "_button", "_xPos", "_yPos", "_shift", "_ctrl", "_alt"];
	
	//systemChat "PIMS INFO: Refreshing inventory...";
	// Spawn so waitUntil can suspend without blocking the UI
	[] spawn {
		call fn_updateInventoryView;
		
		// Re-fire the selection handler so the detail panel matches the refreshed data
		private _display = findDisplay 142351;
		private _listBox = _display displayCtrl 1500;
		private _selectedIndex = lbCurSel _listBox;
		if (_selectedIndex >= 0) then {
			[_listBox, _selectedIndex] call onListboxSelectionChanged;
		} else {
			[_listBox, -1] call onListboxSelectionChanged;
		};
	};
};

// onCloseButtonPressed — Closes the dialog and sets the per-player close flag so
// the auto-refresh loop knows to terminate.
onCloseButtonPressed = {
	closeDialog 142351;
	private _playerUid = getPlayerUID player;
	missionNamespace setVariable [format ["PIMS_closeMenu_%1", _playerUid], true];
};

// onQuantityChanged — Validates the quantity input field, clamping it to a
// minimum of 1, and stores the parsed value in uiNamespace for other handlers.
onQuantityChanged = {
	params ["_control", "_newText"];
	
	private _parsedNumber = parseNumber _newText;
	if (_parsedNumber <= 0) then {
		_parsedNumber = 1;
		_control ctrlSetText "1";
	};
	
	uiNamespace setVariable ["PIMS_quantity", _parsedNumber];
};

// Stub handlers for unused dialog events (buy, load, unload)
onBuyButtonPressed = {};
onLoad = {};
onUnload = {};
// #endregion

// #region Handler Registration
// Publish every handler into uiNamespace so the dialog's config.cpp event entries
// (via ctrlAddEventHandler / onLBSelChanged / buttonClick) can locate them at runtime.
uiNamespace setVariable ["PIMS_fnc_onRetrieveButtonPressed", onRetrieveButtonPressed];
uiNamespace setVariable ["PIMS_fnc_onRetrieveAllButtonPressed", onRetrieveAllButtonPressed];
uiNamespace setVariable ["PIMS_fnc_onRetrieveAllItemsTotalButtonPressed", onRetrieveAllItemsTotalButtonPressed];
uiNamespace setVariable ["PIMS_fnc_onChangeView", onChangeView];
uiNamespace setVariable ["PIMS_fnc_onUpdateInfo", onUpdateInfo];
uiNamespace setVariable ["PIMS_fnc_onCloseButtonPressed", onCloseButtonPressed];
uiNamespace setVariable ["PIMS_fnc_onQuantityChanged", onQuantityChanged];
uiNamespace setVariable ["PIMS_fnc_onBuyButtonPressed", onBuyButtonPressed];
uiNamespace setVariable ["PIMS_fnc_onLoad", onLoad];
uiNamespace setVariable ["PIMS_fnc_onUnload", onUnload];

//systemChat "PIMS DEBUG: All functions stored in uiNamespace";
// #endregion

// #region Initialization & Auto-Refresh
// Perform the first data fetch and populate the listbox, then select the first row
// so the detail panel is populated on open.
//systemChat "PIMS DEBUG: Calling fn_updateInventoryView for first time...";
call fn_updateInventoryView;

// Select the first row (or signal empty) to seed the detail panel
private _listBox = _display displayCtrl 1500;
if ((lbSize _listBox) > 0) then {
	_listBox lbSetCurSel 0;
	[_listBox, 0] call onListboxSelectionChanged;
} else {
	[_listBox, -1] call onListboxSelectionChanged;
};

// Spawn a background loop that refreshes the listbox every 3 seconds.
// The loop exits when the dialog is closed or the per-player close flag is set.
// Skips a cycle if a refresh is already in progress to prevent stacking.
[] spawn {
	private _playerUid = getPlayerUID player;
	
	while {true} do {
		// Exit the loop if the dialog was closed or the close flag was raised
		private _closeMenu = missionNamespace getVariable [format ["PIMS_closeMenu_%1", _playerUid], false];
		if (_closeMenu || isNull (findDisplay 142351)) exitWith {
			missionNamespace setVariable [format ["PIMS_closeMenu_%1", _playerUid], false];
		};
		
		sleep 3;
		
		// Only refresh if no other update is already running
		private _isUpdating = uiNamespace getVariable ["PIMS_isUpdating", false];
		if (!_isUpdating) then {
			// Pull the latest inventory data and diff the listbox
			call fn_updateInventoryView;
		};
	};
};
// #endregion

true
