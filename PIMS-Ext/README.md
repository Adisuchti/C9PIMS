# PIMS Extension (C# DLL)

## Overview

This C# extension DLL replaces the processor-heavy operations from the PIMS SQF mod, moving database operations and item processing to native code for significant performance improvements.

## Building

```powershell
cd PIMS-Ext
dotnet publish -r win-x64 -c Release
```

Output DLL will be in: `bin\Release\net8.0\win-x64\publish\PIMS-Ext_x64.dll`

## Installation

1. Build the DLL as described above
2. Copy `PIMS-Ext_x64.dll` to your Arma 3 directory (where the game exe is located)
3. Copy `pims_config.json` to your Arma 3 directory (same location as DLL)
4. Edit `pims_config.json` with your database credentials
5. Install the PIMS SQF addon (PBO)

## Configuration File

Create/edit `pims_config.json` in your Arma 3 directory:

```json
{
  "database": {
    "server": "localhost",
    "database": "pims_db",
    "user": "root",
    "password": "your_password_here",
    "port": 3306
  }
}
```

**Security Note:** This file contains database credentials. Protect it appropriately and never commit it to version control with real passwords.

## Extension Commands

### Database Initialization

**initdb** - Initialize database connection (reads from pims_config.json)
```
Format: "PIMS-Ext" callExtension "initdb"
Returns: "OK" or error message
Note: Automatically reads database settings from pims_config.json in same directory as DLL
Example: "PIMS-Ext" callExtension "initdb"
```

### Permission Checks

**checkpermission** - Check if player can access inventory
```
Format: "PIMS-Ext" callExtension "checkpermission|inventoryId|playerUid"
Returns: "1" (has permission) or "0" (no permission)
Example: "PIMS-Ext" callExtension "checkpermission|5|76561198012345678"
```

**isadmin** - Check if player is admin
```
Format: "PIMS-Ext" callExtension "isadmin|playerUid"
Returns: "1" (is admin) or "0" (not admin)
Example: "PIMS-Ext" callExtension "isadmin|76561198012345678"
```

### Inventory Operations

**getinventoryname** - Get inventory name
```
Format: "PIMS-Ext" callExtension "getinventoryname|inventoryId"
Returns: Inventory name or error
Example: "PIMS-Ext" callExtension "getinventoryname|5"
```

**getinventory** - Get all items from inventory
```
Format: "PIMS-Ext" callExtension "getinventory|inventoryId"
Returns: SQF array [[contentItemId,class,properties,quantity],...]
Example: "PIMS-Ext" callExtension "getinventory|5"
```

**additem** - Add item to inventory
```
Format: "PIMS-Ext" callExtension "additem|inventoryId|itemClass|properties|quantity"
Returns: "OK" or error
Example: "PIMS-Ext" callExtension "additem|5|arifle_MX_F||1"
```

**removeitem** - Remove item from inventory
```
Format: "PIMS-Ext" callExtension "removeitem|contentItemId|quantity"
Returns: "OK" or error
Example: "PIMS-Ext" callExtension "removeitem|1234|1"
```

## Database Schema

The extension expects the following MySQL/MariaDB tables:

### inventories
- `inventory_id` (INT, PRIMARY KEY)
- `inventory_name` (VARCHAR)

### content_items
- `Content_Item_Id` (INT, PRIMARY KEY, AUTO_INCREMENT)
- `Inventory_Id` (INT, FOREIGN KEY)
- `Object_Class` (VARCHAR) - Arma 3 class name
- `Object_Properties` (TEXT) - JSON or serialized properties
- `Quantity` (INT)

### permissions
- `Permission_Id` (INT, PRIMARY KEY, AUTO_INCREMENT)
- `Inventory_Id` (INT, FOREIGN KEY)
- `Player_Id` (VARCHAR) - Steam UID

### admins
- `AdminId` (INT, PRIMARY KEY, AUTO_INCREMENT)
- `PlayerId` (VARCHAR) - Steam UID

## Performance Benefits

- **Direct MySQL connections** instead of extDB3 intermediary
- **Compiled C# code** runs 10-100x faster than interpreted SQF
- **Batch operations** processed in single calls
- **Reduced network overhead** between game and extension

## Dependencies

- .NET 8.0 Runtime (x64)
- MySQL.Data NuGet package (included in build)
- MySQL/MariaDB server

## Logging

Extension logs to `PIMS_logs.txt` in the same directory as the DLL for debugging purposes.

## Money System

The extension recognizes the following money item classes and their values:

- `PIMS_Money_1` = 1 Credit
- `PIMS_Money_10` = 10 Credits
- `PIMS_Money_50` = 50 Credits
- `PIMS_Money_100` = 100 Credits
- `PIMS_Money_500` = 500 Credits
- `PIMS_Money_1000` = 1000 Credits

Money items are treated as regular inventory items with special class names.
