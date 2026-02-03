This file is AI generated. Sadly, I acknowledge that AI can be useful tool.
# PIMS Extension Reference (C# DLL)

## Overview

The PIMS Extension is a native C# DLL that handles database operations for the PIMS Arma 3 mod. It replaces the slow extDB3 intermediary with direct MySQL connections for significant performance gains.

**Technology Stack:**
- .NET 8.0 (x64)
- MySqlConnector NuGet package (with connection pooling)
- Native Arma 3 extension interface (RVExtension)

## File Structure

```
PIMS-Ext/
├── PIMS-Ext.csproj          # Project configuration
├── pims_config.json          # Database configuration (template)
├── pims_config.json.example  # Example configuration
├── ArmaEntry.cs              # Entry point & command routing
├── Database/
│   └── DatabaseManager.cs    # All database operations
└── Models/
    └── DataModels.cs         # Data transfer objects
```

## Building

```powershell
cd PIMS-Ext
dotnet publish -r win-x64 -c Release
```

**Output:** `bin\Release\net8.0\win-x64\publish\PIMS-Ext_x64.dll`

## Installation

1. Copy `PIMS-Ext_x64.dll` to Arma 3 root directory (where `arma3.exe` is located)
2. Create `pims_config.json` in the same Arma 3 root directory with database credentials
3. Start Arma 3 - extension loads automatically when called

**Important:** Both files must be in the same directory as `arma3.exe` / `arma3server.exe`.

## Configuration

### pims_config.json

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

**Security Note:** This file contains plaintext credentials. Protect appropriately.

---

## ArmaEntry.cs - Command Router

### Entry Point

```csharp
[UnmanagedCallersOnly(EntryPoint = "RVExtension")]
public static unsafe void RVExtension(byte* output, int outputSize, byte* function)
```

This is the function Arma 3 calls when using `callExtension`. It:
1. Reads input string from pointer
2. Routes to appropriate handler
3. Returns result string

### Thread Safety

The extension uses per-inventory locks for fine-grained concurrency control:

```csharp
private static readonly ConcurrentDictionary<int, object> _inventoryLocks = new();

private static object GetInventoryLock(int inventoryId)
{
    return _inventoryLocks.GetOrAdd(inventoryId, _ => new object());
}
```

This allows operations on different inventories to run concurrently while protecting same-inventory operations.

### Caching System

Thread-safe in-memory caches using ConcurrentDictionary:

```csharp
private static readonly ConcurrentDictionary<int, List<InventoryItem>> _inventoryCache;
private static readonly ConcurrentDictionary<int, double> _moneyCache;
private static readonly ConcurrentDictionary<int, string> _inventoryHashCache;
```

**Cache Invalidation:**
- `additem` → Removes inventory from cache + hash
- `removeitem` → Removes inventory from cache + hash (if ID provided)
- `withdrawmoney` → Removes from money cache + hash

**Cache Miss:** If inventory not in cache, auto-queries database.

**Change Detection:**
The `_inventoryHashCache` stores a hash of each inventory's state for efficient change detection.

### Connection Pooling

Connection pooling is enabled with optimized settings:
```
Pooling=true;MinPoolSize=2;MaxPoolSize=50;ConnectionIdleTimeout=300
```

---

## Commands Reference

### initdb

**Purpose:** Initialize database connection from config file  
**Format:** `"PIMS-Ext" callExtension "initdb"`  
**Returns:** `"OK"` or `"Error: {message}"`

**Behavior:**
1. Reads `pims_config.json` from DLL directory
2. Parses JSON for database credentials
3. Creates `DatabaseManager` instance
4. Tests connection
5. Sets `_configLoaded = true` on success

**Errors:**
- `"Error: Config file not found at {path}"`
- `"Error: Failed to load config - {message}"`
- `"Error: Could not connect to database - {message}"`

---

### checkpermission

**Purpose:** Check if player can access an inventory  
**Format:** `"PIMS-Ext" callExtension "checkpermission|{inventoryId}|{playerUid}"`  
**Returns:** `"1"` (has permission) or `"0"` (no permission)

**SQL:**
```sql
SELECT COUNT(*) FROM permissions 
WHERE Inventory_Id = @inventoryId AND Player_Id = @playerUid
```

---

### isadmin

**Purpose:** Check if player is an admin  
**Format:** `"PIMS-Ext" callExtension "isadmin|{playerUid}"`  
**Returns:** `"1"` (admin) or `"0"` (not admin)

**SQL:**
```sql
SELECT COUNT(*) FROM admins WHERE PlayerId = @playerUid
```

---

### getinventoryname

**Purpose:** Get display name of an inventory  
**Format:** `"PIMS-Ext" callExtension "getinventoryname|{inventoryId}"`  
**Returns:** Inventory name string or `"Error: Inventory not found"`

**SQL:**
```sql
SELECT inventory_name FROM inventories WHERE inventory_id = @inventoryId
```

---

### getinventorymoney

**Purpose:** Get cash balance of an inventory  
**Format:** `"PIMS-Ext" callExtension "getinventorymoney|{inventoryId}"`  
**Returns:** Money amount as string (e.g., `"1500.5"`)

**Cache:** Uses `_moneyCache`, auto-queries on miss.

---

### hasinventorychanged

**Purpose:** Check if inventory contents have changed since last check  
**Format:** `"PIMS-Ext" callExtension "hasinventorychanged|{inventoryId}"`  
**Returns:** `"1"` if changed, `"0"` if unchanged

**Behavior:**
1. Queries current inventory state from database
2. Computes hash of items + money
3. Compares with previously cached hash
4. If changed, updates cache with new data and returns `"1"`
5. If unchanged, returns `"0"` (no cache update needed)

**Use Case:** Monitor display system calls this to avoid expensive texture updates when inventory hasn't changed.

**Performance:** Queries database but avoids SQF processing and texture updates when no changes detected.

---

### uploadinventory

**Purpose:** Load inventory from database into extension cache  
**Format:** `"PIMS-Ext" callExtension "uploadinventory|{inventoryId}"`  
**Returns:** `"OK"` or `"Error: {message}"`

**Behavior:**
1. Queries all items for inventory
2. Queries money balance
3. Computes and stores hash for change detection
4. Stores in `_inventoryCache` and `_moneyCache`

---

### getinventory

**Purpose:** Get all items from an inventory  
**Format:** `"PIMS-Ext" callExtension "getinventory|{inventoryId}"`  
**Returns:** SQF-formatted array string

**Return Format:**
```
[[contentItemId,"itemClass","properties",quantity],...]
```

**Example:**
```
[[1,"arifle_MX_F","",5],[2,"30Rnd_65x39_caseless_mag","30",10]]
```

**Cache:** Uses `_inventoryCache`, auto-queries on miss.

**SQL (on cache miss):**
```sql
SELECT content_items.Content_Item_Id, content_items.Inventory_Id, 
       content_items.Item_Class, content_items.Item_Quantity, 
       content_items.Item_Properties, item_types.item_classification 
FROM content_items 
LEFT JOIN items ON items.item_class = content_items.Item_Class 
LEFT JOIN item_types ON item_types.Item_Type_Id = items.Item_Type 
LEFT JOIN item_sorting ON item_sorting.Item_Sorting_Type = item_types.item_classification 
WHERE Inventory_Id = @inventoryId 
ORDER BY item_sorting.Item_Sorting_Number, 
         (content_items.Item_Class IS NULL), 
         content_items.Item_Properties
```

---

### additem

**Purpose:** Add item to an inventory  
**Format:** `"PIMS-Ext" callExtension "additem|{inventoryId}|{itemClass}|{properties}|{quantity}"`  
**Returns:** `"OK"` or `"Error: {message}"`

**Special Handling - Money Items:**
If `itemClass` is a money class (`PIMS_Money_X`), converts to balance:
```sql
UPDATE inventories SET Inventory_Money = Inventory_Money + @amount 
WHERE Inventory_Id = @inventoryId
```

**Regular Items - Existing Check:**
```sql
SELECT Content_Item_Id, Item_Quantity FROM content_items 
WHERE Inventory_Id = @inventoryId AND Item_Class = @itemClass 
AND Item_Properties = @properties
```

**If Exists - Update:**
```sql
UPDATE content_items SET Item_Quantity = @newQuantity 
WHERE Content_Item_Id = @contentItemId
```

**If New - Insert:**
```sql
INSERT INTO content_items (Inventory_Id, Item_Class, Item_Properties, Item_Quantity) 
VALUES (@inventoryId, @itemClass, @properties, @quantity)
```

**Logging:**
```sql
INSERT INTO logs (Transaction_Item, Transaction_Quantity, Transaction_Inventory_Id, isMarketActivity) 
VALUES (@itemClass, @quantity, @inventoryId, 0)
```

---

### removeitem

**Purpose:** Remove item from inventory  
**Format:** `"PIMS-Ext" callExtension "removeitem|{contentItemId}|{quantity}|{inventoryId}"`  
**Returns:** `"OK"` or `"Error: {message}"`

**Note:** Third parameter (inventoryId) is optional but enables cache invalidation.

**Behavior:**
1. Gets current quantity
2. If quantity ≤ remove amount → Deletes row
3. If quantity > remove amount → Decrements quantity

**Delete:**
```sql
DELETE FROM content_items WHERE Content_Item_Id = @contentItemId
```

**Decrement:**
```sql
UPDATE content_items SET Item_Quantity = @newQuantity 
WHERE Content_Item_Id = @contentItemId
```

---

### withdrawmoney

**Purpose:** Withdraw from inventory cash balance  
**Format:** `"PIMS-Ext" callExtension "withdrawmoney|{inventoryId}|{amount}"`  
**Returns:** `"OK"` or `"Error: {message}"`

**Pre-check:**
```csharp
if (currentMoney < amount) return false; // "Insufficient funds"
```

**SQL:**
```sql
UPDATE inventories SET Inventory_Money = Inventory_Money - @amount 
WHERE Inventory_Id = @inventoryId
```

---

## DatabaseManager.cs

### Connection String

```csharp
$"Server={server};Database={database};Uid={user};Pwd={password};Port={port};SslMode=None;AllowPublicKeyRetrieval=True;"
```

**Note:** SSL disabled for compatibility with local/self-signed setups.

### Method Reference

| Method | Parameters | Returns | Description |
|--------|------------|---------|-------------|
| `TestConnection` | `out string errorMessage` | `bool` | Verify DB connection |
| `CheckPermission` | `inventoryId, playerUid` | `bool` | Check player access |
| `IsAdmin` | `playerUid` | `bool` | Check admin status |
| `GetInventoryName` | `inventoryId` | `string?` | Get display name |
| `GetInventoryMoney` | `inventoryId` | `double` | Get cash balance |
| `WithdrawMoney` | `inventoryId, amount` | `bool` | Deduct from balance |
| `GetInventoryItems` | `inventoryId` | `List<InventoryItem>` | Get all items |
| `AddItem` | `inventoryId, itemClass, properties, quantity` | `bool` | Add/update item |
| `RemoveItem` | `contentItemId, quantity` | `bool` | Remove/decrement item |

### Error Handling

All methods use try-catch and log to `ArmaEntry.WriteToLog()`:
```csharp
catch (Exception ex)
{
    ArmaEntry.WriteToLog($"Database error: {ex.Message}\nStack trace: {ex.StackTrace}", LogLevel.Error);
    return false;
}
```

---

## DataModels.cs

### InventoryItem

```csharp
public class InventoryItem
{
    public int ContentItemId { get; set; }
    public int InventoryId { get; set; }
    public string ItemClass { get; set; } = "";
    public string Properties { get; set; } = "";
    public int Quantity { get; set; }
}
```

### Inventory

```csharp
public class Inventory
{
    public int InventoryId { get; set; }
    public string InventoryName { get; set; } = "";
}
```

### Permission

```csharp
public class Permission
{
    public int PermissionId { get; set; }
    public int InventoryId { get; set; }
    public string PlayerId { get; set; } = "";
}
```

### Admin

```csharp
public class Admin
{
    public int AdminId { get; set; }
    public string PlayerId { get; set; } = "";
}
```

### MoneyTypes

Static helper for money denomination handling:

```csharp
public static class MoneyTypes
{
    public const string Credits1 = "PIMS_Money_1";
    // ... etc
    
    public static readonly Dictionary<string, int> MoneyValues = new()
    {
        { Credits1, 1 },
        { Credits10, 10 },
        { Credits50, 50 },
        { Credits100, 100 },
        { Credits500, 500 },
        { Credits1000, 1000 }
    };
    
    public static bool IsMoneyItem(string itemClass);
    public static int GetMoneyValue(string itemClass);
}
```

---

## Logging System

### Log Files

| File | Content |
|------|---------|
| `PIMS_logs.txt` | All log entries |
| `PIMS_logs_Error.txt` | Warnings and errors only |

Both located in DLL directory (Arma 3 root).

### Log Levels

```csharp
public enum LogLevel
{
    Info,     // General operations
    Warning,  // Cache misses, non-fatal issues
    Error     // Exceptions, failures
}
```

### Log Rotation

When log exceeds 20MB, older half is deleted:
```csharp
if (logFileInfo.Length > 20 * 1024 * 1024)
{
    string[] lines = File.ReadAllLines(logPath);
    File.WriteAllLines(logPath, lines.Skip(lines.Length / 2));
}
```

### Log Format

```
[2026-02-01 14:30:45] [INFO] Received input: getinventory|5
[2026-02-01 14:30:45] [INFO] Returning: [[1,"arifle_MX_F","",5]]
```

---

## Error Scenarios

### Configuration Errors

| Error | Cause | Solution |
|-------|-------|----------|
| Config file not found | `pims_config.json` missing | Create config in DLL directory |
| JSON parse error | Invalid JSON syntax | Validate JSON structure |
| Missing property | Required field absent | Add missing database properties |

### Connection Errors

| Error | Cause | Solution |
|-------|-------|----------|
| Connection refused | MySQL not running | Start MySQL service |
| Access denied | Wrong credentials | Check user/password |
| Unknown database | Database doesn't exist | Create database |
| SSL error | SSL configuration mismatch | Already disabled in connection string |

### Runtime Errors

| Error | Cause | Solution |
|-------|-------|----------|
| Database not initialized | `initdb` not called | Call `initdb` first |
| Parameter must be number | Invalid input format | Check calling SQF code |
| Table not found | Schema mismatch | Run database setup script |

---

## Performance Characteristics

### Optimizations

1. **Connection Pooling:** MySqlConnector handles internally
2. **In-Memory Caching:** Reduces redundant queries
3. **Thread Locking:** Prevents concurrent access issues
4. **Parameterized Queries:** Prevents SQL injection, enables plan caching

### Benchmarks (Approximate)

| Operation | Time |
|-----------|------|
| `initdb` | 50-200ms (connection setup) |
| `checkpermission` | 1-5ms |
| `getinventory` (cached) | <1ms |
| `getinventory` (DB query) | 5-20ms |
| `additem` | 5-15ms |
| `removeitem` | 5-15ms |

### Bottlenecks

- Large inventories (1000+ items) increase serialization time
- Concurrent requests are serialized (single lock)
- No connection reuse across calls (new connection per query)

---

## Extending the Extension

### Adding New Commands

1. Add handler method in `ArmaEntry.cs`:
```csharp
private static string HandleMyCommand(string[] parts)
{
    if (_dbManager == null)
        return "Error: Database not initialized";
    // Implementation
    return "OK";
}
```

2. Add to command router switch:
```csharp
string result = command switch
{
    // ... existing commands
    "mycommand" => HandleMyCommand(parts),
    _ => $"Error: Unknown command '{command}'"
};
```

### Adding Database Methods

1. Add method in `DatabaseManager.cs`:
```csharp
public bool MyDatabaseOperation(int param1, string param2)
{
    try
    {
        using var connection = new MySqlConnection(_connectionString);
        connection.Open();
        // SQL operations
        return true;
    }
    catch (Exception ex)
    {
        ArmaEntry.WriteToLog($"Error: {ex.Message}", LogLevel.Error);
        return false;
    }
}
```

### Testing

Use Arma 3's extension testing:
```sqf
private _result = "PIMS-Ext" callExtension "ping";
// Returns "pong" if extension loaded
```

Check logs in `PIMS_logs.txt` for debugging.
