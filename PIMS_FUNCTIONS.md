This file is AI generated. Sadly, I acknowledge that AI can be useful tool.
# PIMS SQF Functions Reference

## Overview

All PIMS functions use the prefix `PIMS_fnc_` and are defined in `config.cpp` under `CfgFunctions`. They are automatically compiled by Arma 3 on mission start.

## Function Index

| Function | Execution | Description |
|----------|-----------|-------------|
| `PIMS_fnc_PIMSInit` | Server | Initialize PIMS system |
| `PIMS_fnc_PIMSAddInventory` | Server | Module setup for inventory links |
| `PIMS_fnc_PIMSOpenMenu` | Client | Open inventory GUI |
| `PIMS_fnc_PIMSMenuListInventory` | Client | Populate GUI with items |
| `PIMS_fnc_PIMSUploadInventory` | Server | Upload container contents to DB |
| `PIMS_fnc_PIMSUploadInventoryToExtension` | Server | Refresh extension cache |
| `PIMS_fnc_PIMSGetInventoryData` | Server | Fetch inventory data for client |
| `PIMS_fnc_PIMSGetItemArrayFromContainer` | Any | Extract items from container |
| `PIMS_fnc_PIMSAddItemToContainer` | Server | Add item to container |
| `PIMS_fnc_PIMSRetrieveItemFromDatabase` | Server | Retrieve single item type |
| `PIMS_fnc_PIMSRetrieveAllItems` | Server | Retrieve all items at once |
| `PIMS_fnc_PIMSWithdrawMoney` | Server | Withdraw money from balance |
| `PIMS_fnc_PIMSCheckBoxMoney` | Any | Calculate money in container |
| `PIMS_fnc_PIMSReportVersion` | Client | Report client version to server |
| `PIMS_fnc_PIMSCheckVersion` | Server | Verify client/server version match |

---

## PIMS_fnc_PIMSInit

**File:** `fn_PIMSInit.sqf`  
**Execution:** Server only  
**Called by:** PIMS_ModuleInit module  

### Purpose
Initialize the PIMS system, connect to database, set up player connection handlers, manage player UID hashmap, and start the monitor display loop with change detection.

### Parameters
| Name | Type | Description |
|------|------|-------------|
| `_logic` | Object | The module logic object |
| `_synced` | Array | Synchronized objects (unused) |

### Returns
`Boolean` - Always `true`

### Behavior
1. Calls `"PIMS-Ext" callExtension "initdb"` to initialize database
2. If successful:
   - Initializes `PIMS_PlayerUIDMap` hashmap for O(1) player lookups
   - Defines `PIMS_fnc_getPlayerByUID` helper function
   - Adds `PlayerConnected` event handler (updates hashmap, sets up actions)
   - Adds `PlayerDisconnected` event handler (cleans up hashmap)
   - Caches AddInventory modules once at startup (performance optimization)
   - Starts monitor display update loop (20s interval) with change detection
3. If failed:
   - Logs error and displays to all clients

### Variables Set
| Scope | Variable | Purpose |
|-------|----------|---------|
| Global | `PIMS_PlayerUIDMap` | Hashmap: UID → player object |
| Global | `PIMS_fnc_getPlayerByUID` | Helper function for O(1) lookups |
| Module | `PIMS_Inventory_Id_Edit` | Read inventory ID |
| Object | `PIMS_LabelObject` | Monitor object reference |

### Event Handlers Added
- `PlayerConnected` - Sets up actions for new players, updates UID hashmap
- `PlayerDisconnected` - Removes player from UID hashmap

### Extension Commands Used
- `initdb`
- `checkpermission|{inventoryId}|{playerUid}`
- `getinventoryname|{inventoryId}`
- `isadmin|{playerUid}`
- `hasinventorychanged|{inventoryId}` (monitor loop - change detection)
- `getinventory|{inventoryId}`
- `getinventorymoney|{inventoryId}`

---

## PIMS_fnc_PIMSAddInventory

**File:** `fn_PIMSAddInventory.sqf`  
**Execution:** Server only  
**Called by:** PIMS_ModuleAddInventory module  

### Purpose
Module initialization - validates the inventory configuration.

### Parameters
| Name | Type | Description |
|------|------|-------------|
| `_logic` | Object | The module logic object |
| `_synced` | Array | Synchronized objects |

### Returns
`Boolean` - Always `true`

### Behavior
Simply reads the inventory ID and logs a confirmation message. Actual functionality is handled by `PIMSInit` which iterates all AddInventory modules.

---

## PIMS_fnc_PIMSOpenMenu

**File:** `fn_PIMSOpenMenu.sqf`  
**Execution:** Client  
**Called by:** Player interaction action  

### Purpose
Opens the PIMS inventory GUI dialog.

### Parameters
| Name | Type | Description |
|------|------|-------------|
| `_ownerUid` | String | Player's Steam UID |
| `_containerNetId` | String | Network ID of the container |
| `_inventoryId` | Number | Database inventory ID |
| `_isAdmin` | Boolean | Whether player is admin |

### Returns
Nothing (void)

### Behavior
1. Creates dialog `"PIMSMenuDialog"` (IDD: 142351)
2. Spawns `PIMS_fnc_PIMSMenuListInventory` to populate items

### Easter Egg
1 in 1000 chance to display a random funny message hint.

---

## PIMS_fnc_PIMSMenuListInventory

**File:** `fn_PIMSMenuListInventory.sqf`  
**Execution:** Client  
**Called by:** `PIMS_fnc_PIMSOpenMenu`  

### Purpose
Populate and manage the inventory GUI, handle all user interactions.

### Parameters
| Name | Type | Description |
|------|------|-------------|
| `_containerNetId` | String | Network ID of the container |
| `_inventoryId` | Number | Database inventory ID |
| `_isAdmin` | Boolean | Whether player is admin |

### Returns
`Boolean` - `true` on success

### uiNamespace Variables Set
| Variable | Type | Description |
|----------|------|-------------|
| `PIMS_containerNetId` | String | Current container network ID |
| `PIMS_inventoryId` | Number | Current inventory ID |
| `PIMS_isAdmin` | Boolean | Admin status |
| `PIMS_selectedIndex` | Number | Selected listbox index |
| `PIMS_quantity` | Number | Quantity input value |
| `PIMS_Uid` | String | Current player UID |
| `PIMS_ViewMode` | Number | 0=Inventory, 2=Bank |
| `PIMS_MoneyTypes` | Array | Money class/value pairs |
| `PIMS_isUpdating` | Boolean | Update lock flag |
| `PIMS_currentItems` | Array | Cached inventory items |
| `PIMS_inventoryMoney` | Number | Cash balance |
| `PIMS_cachedListBoxItems` | Array | Listbox cache for diff |

### Internal Functions Defined

#### `fn_updateInventoryView`
Refreshes the inventory display from server data.
- Calls `PIMS_fnc_PIMSGetInventoryData` via remoteExec
- Waits for `PIMS_InventoryDataReady_{uid}`
- Updates listbox incrementally (only changed items)
- Handles view mode switching

#### `fn_getConfigPathAndWeight`
Gets config info for an item class.
- **Parameters:** `_itemClass` (String)
- **Returns:** `[_cfg, _parentPath, _mass]`
- Searches: CfgWeapons → CfgMagazines → CfgVehicles → CfgGlasses

### GUI Event Handlers

#### `onListboxSelectionChanged`
Updates item detail panel when selection changes.

#### `onRetrieveButtonPressed`
Retrieves specified quantity of selected item.
- Uses `PIMS_fnc_PIMSRetrieveItemFromDatabase`
- In Bank mode, withdraws money

#### `onRetrieveAllButtonPressed`
Retrieves all of selected item type.

#### `onRetrieveAllItemsTotalButtonPressed`
Retrieves entire inventory contents.
- Uses `PIMS_fnc_PIMSRetrieveAllItems`

#### `onChangeView`
Toggles between Inventory (0) and Bank (2) views.

#### `onUpdateInfo`
Manual refresh button handler.

#### `onQuantityChanged`
Validates quantity input (minimum 1).

### Auto-Refresh
Spawns a loop that refreshes GUI every 3 seconds while dialog is open.

---

## PIMS_fnc_PIMSUploadInventory

**File:** `fn_PIMSUploadInventory.sqf`  
**Execution:** Server only  
**Called by:** Player interaction action via remoteExec  

### Purpose
Upload all items from a container to the database inventory.

### Parameters
| Name | Type | Description |
|------|------|-------------|
| `_containerNetId` | String | Network ID of the container |
| `_inventoryId` | Number | Target inventory ID |
| `_playerUid` | String | (Optional) Player UID for feedback |

### Returns
`Boolean` - `true` on completion

### Behavior
1. Locks container inventory
2. Checks for concurrent upload (lock variable)
3. Extracts items via `PIMS_fnc_PIMSGetItemArrayFromContainer`
4. For each item, calls extension `additem|{inventoryId}|{class}|{props}|{qty}`
5. Clears container cargo
6. Refreshes extension cache
7. Unlocks container

### Concurrency Protection
Uses `PIMS_UploadLock_{containerNetId}` in missionNamespace.

### Extension Commands Used
- `additem|{inventoryId}|{itemClass}|{properties}|{quantity}`

---

## PIMS_fnc_PIMSUploadInventoryToExtension

**File:** `fn_PIMSUploadInventoryToExtension.sqf`  
**Execution:** Server only  
**Called by:** After database modifications  

### Purpose
Refresh the extension's in-memory cache for an inventory.

### Parameters
| Name | Type | Description |
|------|------|-------------|
| `_inventoryId` | Number | Inventory ID to refresh |

### Returns
`Boolean` - Success status

### Behavior
Calls `"PIMS-Ext" callExtension format ["uploadinventory|%1", _inventoryId]`

---

## PIMS_fnc_PIMSGetInventoryData

**File:** `fn_PIMSGetInventoryData.sqf`  
**Execution:** Server only  
**Called by:** Client GUI via remoteExec  

### Purpose
Fetch inventory data from database and store for client retrieval.

### Parameters
| Name | Type | Description |
|------|------|-------------|
| `_inventoryId` | Number | Inventory ID to query |
| `_playerUid` | String | Requesting player's UID |

### Returns
`Boolean` - Always `true`

### Variables Set (missionNamespace, publicVariable)
| Variable | Type | Description |
|----------|------|-------------|
| `PIMS_InventoryName_{uid}` | String | Inventory display name |
| `PIMS_InventoryItems_{uid}` | Array | Item list `[[id,class,props,qty],...]` |
| `PIMS_InventoryMoney_{uid}` | Number | Cash balance |
| `PIMS_InventoryDataReady_{uid}` | Boolean | Ready flag for client |

### Extension Commands Used
- `getinventoryname|{inventoryId}`
- `getinventory|{inventoryId}`
- `getinventorymoney|{inventoryId}`

---

## PIMS_fnc_PIMSGetItemArrayFromContainer

**File:** `fn_PIMSGetItemArrayFromContainer.sqf`  
**Execution:** Any  
**Called by:** `PIMS_fnc_PIMSUploadInventory`  

### Purpose
Extract all items from a container into a structured array.

### Parameters
| Name | Type | Description |
|------|------|-------------|
| `_container` | Object | Container to scan |

### Returns
`Array` - `[[className, quantity, properties], ...]`

### Behavior
1. Gets weapon cargo (classname array)
2. Gets magazine cargo with ammo counts
3. Gets item cargo
4. Gets backpack cargo
5. Aggregates by classname+properties, stacking quantities

### Item Properties
- Weapons: `""` (empty)
- Magazines: `str _ammoCount` (ammo remaining)
- Items: `""` (empty)
- Backpacks: `""` (empty)

---

## PIMS_fnc_PIMSAddItemToContainer

**File:** `fn_PIMSAddItemToContainer.sqf`  
**Execution:** Server  
**Called by:** Retrieve functions  

### Purpose
Add an item to a container based on its type.

### Parameters
| Name | Type | Description |
|------|------|-------------|
| `_container` | Object | Target container |
| `_className` | String | Item classname |
| `_quantity` | Number | Quantity to add |
| `_properties` | String | Item properties (ammo count for mags) |

### Returns
`Boolean` - Success status

### Type Detection Order
1. `CfgWeapons` → Check `ItemInfo` subclass
   - Has ItemInfo → `addItemCargoGlobal` (item)
   - No ItemInfo → `addWeaponCargoGlobal` (weapon)
2. `CfgMagazines` → `addMagazineCargoGlobal` or `addMagazineAmmoCargo`
3. `CfgVehicles` → `addBackpackCargoGlobal`
4. Unknown → `addItemCargoGlobal` (fallback)

### Magazine Handling
If `_properties` is not empty, uses `addMagazineAmmoCargo` to preserve ammo count.

---

## PIMS_fnc_PIMSRetrieveItemFromDatabase

**File:** `fn_PIMSRetrieveItemFromDatabase.sqf`  
**Execution:** Server only  
**Called by:** Client GUI via remoteExec  

### Purpose
Retrieve a specific quantity of an item from database to container.

### Parameters
| Name | Type | Description |
|------|------|-------------|
| `_containerNetId` | String | Target container network ID |
| `_inventoryId` | Number | Source inventory ID |
| `_contentItemId` | Number | Database item entry ID |
| `_itemClass` | String | Item classname |
| `_properties` | String | Item properties |
| `_quantity` | Number | Quantity to retrieve |
| `_playerUid` | String | Requesting player UID |

### Returns
`Boolean` - Always `true` (result in variables)

### Variables Set (missionNamespace)
| Variable | Description |
|----------|-------------|
| `PIMS_retrieveSuccess_{uid}` | `true` if successful |
| `PIMS_retrieveDone_{uid}` | `true` when complete |

### Behavior
1. Locks container
2. Removes item from database via `removeitem` command
3. Adds item to container
4. If add fails: rolls back database removal
5. Refreshes extension cache
6. Unlocks container

### Extension Commands Used
- `removeitem|{contentItemId}|{quantity}|{inventoryId}`
- `additem|{inventoryId}|{itemClass}|{properties}|{quantity}` (rollback)

---

## PIMS_fnc_PIMSRetrieveAllItems

**File:** `fn_PIMSRetrieveAllItems.sqf`  
**Execution:** Server only  
**Called by:** Client GUI via remoteExec  

### Purpose
Retrieve all items from an inventory to a container at once.

### Parameters
| Name | Type | Description |
|------|------|-------------|
| `_containerNetId` | String | Target container network ID |
| `_inventoryId` | Number | Source inventory ID |
| `_playerUid` | String | Requesting player UID |

### Returns
`Boolean` - Success status

### Variables Set (missionNamespace)
| Variable | Description |
|----------|-------------|
| `PIMS_retrieveAllSuccess_{uid}` | `true` if any items retrieved |
| `PIMS_retrieveAllDone_{uid}` | `true` when complete |

### Behavior
1. Gets all items via `getinventory` command
2. For each item:
   - Removes from database
   - Adds to container
   - On failure: rolls back and tracks failed items
3. Reports success/failure counts
4. Refreshes extension cache

---

## PIMS_fnc_PIMSWithdrawMoney

**File:** `fn_PIMSWithdrawMoney.sqf`  
**Execution:** Server only  
**Called by:** Client GUI via remoteExec (Bank view)  

### Purpose
Withdraw money from inventory balance and spawn physical money items.

### Parameters
| Name | Type | Description |
|------|------|-------------|
| `_containerNetId` | String | Target container network ID |
| `_inventoryId` | Number | Source inventory ID |
| `_moneyClass` | String | Money item class to spawn |
| `_quantity` | Number | Number of items to spawn |
| `_playerUid` | String | Requesting player UID |

### Returns
`Boolean` - Always `true`

### Variables Set (missionNamespace)
| Variable | Description |
|----------|-------------|
| `PIMS_withdrawSuccess_{uid}` | `true` if successful |
| `PIMS_withdrawDone_{uid}` | `true` when complete |

### Behavior
1. Calculates total amount (denomination × quantity)
2. Withdraws from database via `withdrawmoney` command
3. Adds physical money items to container
4. Refreshes extension cache

### Extension Commands Used
- `withdrawmoney|{inventoryId}|{totalAmount}`

---

## PIMS_fnc_PIMSCheckBoxMoney

**File:** `fn_PIMSCheckBoxMoney.sqf`  
**Execution:** Any  
**Called by:** Legacy/utility  

### Purpose
Calculate total credit value of money items in a container.

### Parameters
| Name | Type | Description |
|------|------|-------------|
| `_container` | Object | Container to scan |

### Returns
`Number` - Total credit value

### Behavior
Iterates known money item classes and sums their values:
- `PIMS_Money_1` × 1
- `PIMS_Money_10` × 10
- `PIMS_Money_50` × 50
- `PIMS_Money_100` × 100
- `PIMS_Money_500` × 500
- `PIMS_Money_1000` × 1000

---

## Common Patterns

### Server-Side Function Template
```sqf
if (!isServer) exitWith {};

params ["_param1", "_param2"];

private _player = objNull;
{
    if (getPlayerUID _x == _playerUid) exitWith {
        _player = _x;
    };
} forEach allPlayers;

try {
    // Operation
} catch {
    ["Error message"] remoteExec ["systemChat", _player];
};
```

### Client-to-Server Call Pattern
```sqf
// Client side
missionNamespace setVariable ["PIMS_done_uid", false];
[param1, param2] remoteExec ["PIMS_fnc_ServerFunction", 2];

waitUntil {
    sleep 0.1;
    missionNamespace getVariable ["PIMS_done_uid", false]
};
```

### Extension Call Pattern
```sqf
private _command = format ["command|%1|%2", _param1, _param2];
private _result = "PIMS-Ext" callExtension _command;

if (_result == "OK") then {
    // Success
} else {
    // Error: _result contains message
};
```

---

## PIMS_fnc_PIMSReportVersion

**File:** `fn_PIMSReportVersion.sqf`  
**Execution:** Client only  
**Called by:** Server via `remoteExec` on player connect  

### Purpose
Report the client's PIMS addon version to the server for version compatibility checking.

### Parameters
| Name | Type | Description |
|------|------|-------------|
| `_playerUid` | String | Player's Steam UID |

### Returns
Nothing (void)

### Behavior
1. Reads version from `configFile >> "CfgPatches" >> "PIMS_patches" >> "version"`
2. Falls back to "UNKNOWN" if version not found
3. Calls `PIMS_fnc_PIMSCheckVersion` on server via `remoteExec`

---

## PIMS_fnc_PIMSCheckVersion

**File:** `fn_PIMSCheckVersion.sqf`  
**Execution:** Server only  
**Called by:** Client via `remoteExec` after reporting version  

### Purpose
Compare client version with server version and broadcast a warning if they don't match.

### Parameters
| Name | Type | Description |
|------|------|-------------|
| `_playerUid` | String | Player's Steam UID |
| `_clientVersion` | String | Client's reported PIMS version |

### Returns
Nothing (void)

### Behavior
1. Reads server version from `CfgPatches`
2. Looks up player name from `PIMS_PlayerUIDMap`
3. If versions don't match:
   - Broadcasts warning to all players via `systemChat`
   - Logs warning to server RPT
4. If versions match:
   - Logs success to server RPT (optional debug info)

### Output Example
```
PIMS WARNING: Player JohnDoe has version mismatch! Client: 1.9.0, Server: 2.0.0
```
