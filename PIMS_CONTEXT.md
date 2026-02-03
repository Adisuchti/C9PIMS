This file is AI generated. Sadly, I acknowledge that AI can be useful tool.
# PIMS - Persistent Inventory Management System v2

## Overview

PIMS (Persistent Inventory Management System) is an Arma 3 mod that provides persistent storage inventories connected to a MySQL/MariaDB database. Players can store and retrieve items from database-linked containers that persist across server restarts.

**Version 2** is a complete rewrite that moves heavy processing from SQF (interpreted at runtime) to a native C# DLL extension, resulting in 10-100x performance improvements.

## Architecture

### Component Structure

```
┌─────────────────────────────────────────────────────────────────┐
│                         ARMA 3 GAME                             │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │                    PIMS ADDON (PBO)                      │    │
│  │  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐   │    │
│  │  │   Modules    │  │   GUI/UI     │  │ SQF Functions │   │    │
│  │  │  (Eden 3D)   │  │  (Dialog)    │  │   (Logic)     │   │    │
│  │  └──────────────┘  └──────────────┘  └──────────────┘   │    │
│  │                           │                              │    │
│  │                      callExtension                       │    │
│  │                           │                              │    │
│  └───────────────────────────┼──────────────────────────────┘    │
│                              │                                   │
│  ┌───────────────────────────▼──────────────────────────────┐    │
│  │                 PIMS-EXT DLL (C#/.NET 8)                  │    │
│  │  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐   │    │
│  │  │ ArmaEntry.cs │  │  DatabaseMgr │  │   Models     │   │    │
│  │  │ (Commands)   │  │  (MySQL)     │  │   (Data)     │   │    │
│  │  └──────────────┘  └──────────────┘  └──────────────┘   │    │
│  └───────────────────────────┼──────────────────────────────┘    │
└──────────────────────────────┼───────────────────────────────────┘
                               │
                    ┌──────────▼──────────┐
                    │   MySQL/MariaDB     │
                    │     Database        │
                    └─────────────────────┘
```

### Client-Server Architecture

- **Server-Side**: Database operations, permission checks, item transfers, cache management
- **Client-Side**: GUI rendering, user input handling, display updates
- **Communication**: `remoteExec` for client→server calls, `missionNamespace` variables for responses

```
┌─────────────────┐          ┌─────────────────┐          ┌─────────────┐
│     CLIENT      │          │     SERVER      │          │  DATABASE   │
│                 │          │                 │          │             │
│ Open Menu ──────┼──remoteExec──► Get Data ───┼────DLL──►│   Query     │
│                 │          │                 │          │             │
│ Update GUI ◄────┼─variables─── Parse Result ◄┼──────────│   Result    │
│                 │          │                 │          │             │
│ Retrieve Item ──┼──remoteExec──► Remove DB ──┼────DLL──►│   Update    │
│                 │          │      │          │          │             │
│ Receive Item ◄──┼─addItemCargo── Add to Box  │          │             │
└─────────────────┘          └─────────────────┘          └─────────────┘
```

## Database Schema

### Tables

#### `inventories`
Main inventory definitions.
| Column | Type | Description |
|--------|------|-------------|
| `inventory_id` | INT (PK) | Unique inventory identifier |
| `inventory_name` | VARCHAR | Display name |
| `inventory_money` | DOUBLE | Cash balance (not physical items) |

#### `content_items`
Items stored in inventories.
| Column | Type | Description |
|--------|------|-------------|
| `Content_Item_Id` | INT (PK, AUTO) | Unique item entry ID |
| `Inventory_Id` | INT (FK) | Parent inventory |
| `Item_Class` | VARCHAR | Arma 3 classname |
| `Item_Properties` | TEXT | Additional data (e.g., ammo count) |
| `Item_Quantity` | INT | Stack quantity |

#### `permissions`
Player access control.
| Column | Type | Description |
|--------|------|-------------|
| `Permission_Id` | INT (PK, AUTO) | Permission entry ID |
| `Inventory_Id` | INT (FK) | Inventory access granted to |
| `Player_Id` | VARCHAR | Steam UID (64-bit) |

#### `admins`
Admin privileges.
| Column | Type | Description |
|--------|------|-------------|
| `AdminId` | INT (PK, AUTO) | Admin entry ID |
| `PlayerId` | VARCHAR | Steam UID |

#### `logs`
Transaction history.
| Column | Type | Description |
|--------|------|-------------|
| `Transaction_Item` | VARCHAR | Item class or "MONEY" |
| `Transaction_Quantity` | INT | Quantity (+add, -remove) |
| `Transaction_Inventory_Id` | INT | Affected inventory |
| `isMarketActivity` | BOOL | Legacy field |

#### Supporting Tables
- `items` - Item metadata (type classification)
- `item_types` - Item type definitions
- `item_sorting` - Display order configuration

## Money System

PIMS implements a dual money system:

### Physical Money Items
Inventory items representing currency:
| Class | Value | Description |
|-------|-------|-------------|
| `PIMS_Money_1` | 1 | 1 Credit note |
| `PIMS_Money_10` | 10 | 10 Credit note |
| `PIMS_Money_50` | 50 | 50 Credit note |
| `PIMS_Money_100` | 100 | 100 Credit note |
| `PIMS_Money_500` | 500 | 500 Credit note |
| `PIMS_Money_1000` | 1000 | 1000 Credit note |

### Bank Balance
Each inventory has an `inventory_money` column that stores a digital balance. When physical money is uploaded to an inventory, it's converted to balance. Players can withdraw balance as physical money items.

**Flow:**
1. Upload physical money → Converted to balance (money items removed)
2. Withdraw from balance → Physical money items spawned in container

## System States

### Initialization States

| State | Indicator | Description |
|-------|-----------|-------------|
| Uninitialized | Extension returns error | DLL not loaded or `initdb` not called |
| Initializing | During `initdb` | Reading config, connecting to DB |
| Ready | `initdb` returns "OK" | System operational |
| Error | `initdb` returns error message | Config missing, DB unreachable, auth failed |

### Cache States

The extension maintains thread-safe in-memory caches using ConcurrentDictionary:

| Cache | Invalidated By | Auto-Refresh |
|-------|----------------|--------------|
| `_inventoryCache` | `additem`, `removeitem` | On `uploadinventory` or cache miss |
| `_moneyCache` | `additem`, `withdrawmoney` | On `uploadinventory` or cache miss |
| `_inventoryHashCache` | `additem`, `removeitem`, `withdrawmoney` | On `hasinventorychanged` |

**Cache Miss Handling:** If cache is empty, queries DB automatically on `getinventory`/`getinventorymoney`.

**Change Detection:** The `hasinventorychanged` command computes a hash of the current inventory state and compares it to the cached hash. This allows the monitor display system to skip expensive texture updates when no changes occurred.

### Container States

| State | Variable | Description |
|-------|----------|-------------|
| Unlocked | `lockInventory false` | Normal interaction |
| Locked (Upload) | `lockInventory true` | During upload operation |
| Locked (Retrieve) | `lockInventory true` | During retrieve operation |
| Locked (No Permission) | `lockInventory true` | Player lacks access |

### GUI View Modes

| Mode | Value | Description |
|------|-------|-------------|
| Inventory | 0 | Shows all items, retrieve buttons visible |
| Bank | 2 | Shows money denominations for withdrawal |

## Error Handling

### Extension Errors

| Error Pattern | Cause | Resolution |
|---------------|-------|------------|
| `Error: Database not initialized` | `initdb` not called | Call `initdb` first |
| `Error: Config file not found` | Missing `pims_config.json` | Create config file |
| `Error: Could not connect to database` | Wrong credentials/server down | Check config and MySQL |
| `Error: inventoryId must be a number` | Invalid parameter | Check calling code |

### SQF Error Handling

Functions use `try-catch` blocks and return status via `missionNamespace` variables:
- `PIMS_retrieveDone_{uid}` - Operation complete flag
- `PIMS_retrieveSuccess_{uid}` - Operation success flag
- `PIMS_withdrawDone_{uid}` - Withdraw complete flag
- `PIMS_withdrawSuccess_{uid}` - Withdraw success flag

### Rollback Behavior

If adding items to container fails after database removal:
1. Item is added back to database via `additem` command
2. User receives warning message
3. Cache is invalidated for fresh state

## Threading & Concurrency

### Extension Thread Safety

The extension uses per-inventory locks with ConcurrentDictionary for fine-grained concurrency:

```csharp
private static readonly ConcurrentDictionary<int, object> _inventoryLocks = new();
private static readonly ConcurrentDictionary<int, List<InventoryItem>> _inventoryCache = new();
private static readonly ConcurrentDictionary<int, double> _moneyCache = new();
private static readonly ConcurrentDictionary<int, string> _inventoryHashCache = new();
```

This allows:
- Operations on different inventories to run concurrently
- Same-inventory operations to be serialized safely
- Thread-safe cache access without global locking

### Connection Pooling

MySQL connection pooling is enabled with optimized settings:
```
Pooling=true;MinPoolSize=2;MaxPoolSize=50;ConnectionIdleTimeout=300
```

### SQF Concurrency

Upload operations use per-container locks:
```sqf
private _lockVar = format ["PIMS_UploadLock_%1", _containerNetId];
if (missionNamespace getVariable [_lockVar, false]) exitWith {...};
missionNamespace setVariable [_lockVar, true, true];
```

GUI update operations use flag-based locking:
```sqf
if (uiNamespace getVariable ["PIMS_isUpdating", false]) exitWith {};
uiNamespace setVariable ["PIMS_isUpdating", true];
```

### Player UID Hashmap

For O(1) player lookups, a hashmap is maintained server-side:
```sqf
PIMS_PlayerUIDMap = createHashMap;  // Key: UID, Value: player object
PIMS_fnc_getPlayerByUID = {...};    // Helper function
```

Updated on `PlayerConnected` and cleaned on `PlayerDisconnected`.

## Module System

### PIMS_ModuleInit
**Purpose:** Initialize the PIMS system  
**Placement:** Once per mission  
**Behavior:**
1. Calls extension `initdb`
2. Sets up `PlayerConnected` event handler
3. Starts monitor display update loop (every 20s)

### PIMS_ModuleAddInventory
**Purpose:** Link objects to a database inventory  
**Configuration:**
- `PIMS_Inventory_Id_Edit` (NUMBER) - Database inventory ID to connect

**Behavior:**
1. Synced objects receive interact actions when player has permission
2. Objects without permission have locked inventories
3. Actions added: "Upload Content to: X", "Open Menu: X"

## Version Check System

PIMS automatically verifies that clients have the same addon version as the server.

### Flow
1. Player connects to server
2. Server calls `PIMS_fnc_PIMSReportVersion` on client via `remoteExec`
3. Client reads version from `CfgPatches >> PIMS_patches >> version`
4. Client reports version back to server via `PIMS_fnc_PIMSCheckVersion`
5. Server compares versions:
   - **Match**: Logs success to RPT
   - **Mismatch**: Broadcasts warning to all players via `systemChat`

### Warning Message Example
```
PIMS WARNING: Player JohnDoe has version mismatch! Client: 1.9.0, Server: 2.0.0
```

### Purpose
- Helps identify outdated client installations
- Prevents compatibility issues between different PIMS versions
- Provides clear feedback to server admins and players

## Known Limitations

1. **Single-threaded extension**: All database operations are serialized
2. **Cache invalidation**: Adding/removing items clears entire inventory cache
3. **No offline mode**: Requires active database connection
4. **No transaction batching**: Each item upload is a separate DB call
5. **Monitor refresh rate**: Fixed 20-second interval for PIMS_Box displays

## Performance Considerations

### Optimizations Implemented
- Extension caches reduce database queries
- Incremental GUI updates (only changes are applied)
- Batch item array formatting in C#
- Connection pooling via MySqlConnector

### Potential Bottlenecks
- Large inventories (1000+ item types) may slow GUI
- High-frequency uploads/retrieves can cause DB contention
- Monitor loop iterates all modules every 20 seconds

## File Structure

```
PIMS/
├── config.cpp              # Main config (patches, functions, GUI, items)
├── BIS_AddonInfo.hpp       # Addon metadata
├── Modules/
│   ├── ModuleInit.hpp      # Init module definition
│   └── ModuleAddInventory.hpp  # Inventory module definition
├── PIMSFnc/
│   ├── fn_PIMSInit.sqf                 # System initialization
│   ├── fn_PIMSOpenMenu.sqf             # Open GUI dialog
│   ├── fn_PIMSMenuListInventory.sqf    # GUI population & handlers
│   ├── fn_PIMSAddInventory.sqf         # Module initialization
│   ├── fn_PIMSUploadInventory.sqf      # Upload items to DB
│   ├── fn_PIMSUploadInventoryToExtension.sqf  # Refresh extension cache
│   ├── fn_PIMSGetItemArrayFromContainer.sqf   # Extract items from box
│   ├── fn_PIMSRetrieveItemFromDatabase.sqf    # Retrieve single item
│   ├── fn_PIMSRetrieveAllItems.sqf     # Retrieve all items
│   ├── fn_PIMSCheckBoxMoney.sqf        # Calculate money in box
│   ├── fn_PIMSAddItemToContainer.sqf   # Add item to box
│   ├── fn_PIMSGetInventoryData.sqf     # Server-side data fetch
│   ├── fn_PIMSWithdrawMoney.sqf        # Withdraw cash from balance
│   ├── fn_PIMSReportVersion.sqf        # Report client version to server
│   └── fn_PIMSCheckVersion.sqf         # Verify client/server version match
└── data/
    ├── pimsMoney.p3d       # Money item 3D model
    └── icons/              # Money item icons

PIMS-Ext/
├── PIMS-Ext.csproj        # .NET project file
├── pims_config.json       # Database configuration
├── ArmaEntry.cs           # Extension entry point & command handlers
├── Database/
│   └── DatabaseManager.cs # MySQL operations
└── Models/
    └── DataModels.cs      # Data structures
```

## Dependencies

### Arma 3 Addon
- A3_Modules_F (Arma 3 Modules Framework)
- 3DEN (Eden Editor)
- ace_common (ACE3 mod - for item definitions)
- TKE_Crate1RBlue (Parent class for PIMS_Box - requires mod)

### Extension
- .NET 8.0 Runtime (x64)
- MySqlConnector NuGet package
- MySQL/MariaDB 5.7+ server

## Building

### Addon (PBO)
Use Arma 3 Tools (Addon Builder) or PBOManager to pack the PIMS folder.

### Extension (DLL)
```powershell
cd PIMS-Ext
dotnet publish -r win-x64 -c Release
```
Output: `bin\Release\net8.0\win-x64\publish\PIMS-Ext_x64.dll`

## Installation

1. Build/obtain PIMS.pbo → place in Arma 3 addons folder
2. Build PIMS-Ext_x64.dll → place in Arma 3 root directory (where `arma3.exe` is located)
3. Create pims_config.json → place in Arma 3 root directory (same folder as DLL and `arma3.exe`)
4. Set up MySQL database with required tables
5. Add permissions entries for players
6. Place modules in Eden Editor

**Logging:** The extension produces two log files in the Arma 3 root directory:
- `PIMS_logs.txt` - General extension logs
- `PIMS_errors.txt` - Error-specific logs
