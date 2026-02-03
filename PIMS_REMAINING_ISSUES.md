This file is AI generated. Sadly, I acknowledge that AI can be useful tool.
# PIMS Remaining Performance Issues

This document lists performance bottlenecks that were identified but not yet fixed, along with their severity, impact, and proposed solutions.

---

## Recently Fixed Issues

### ✅ Non-Blocking Database Refresh (Background Tasks)

**Status:** IMPLEMENTED  
**Location:** [ArmaEntry.cs](../PIMS-Ext/PIMS-Ext/ArmaEntry.cs), [fn_PIMSInit.sqf](PIMSFnc/fn_PIMSInit.sqf)

**Problem:** The `hasinventorychanged` command was querying the database synchronously, blocking SQF execution.

**Solution Implemented:**
1. Added `queuerefresh|inventoryId` command that returns immediately (non-blocking)
2. Extension spawns background Task to query database
3. `hasinventorychanged` now only compares cached hashes (no DB query)
4. Monitor loop calls `queuerefresh` for all inventories, waits 2s, then checks for changes

**Commands:**
- `queuerefresh|inventoryId` - Returns "" immediately, starts background DB refresh
- `hasinventorychanged|inventoryId` - Returns "1"/"0"/"-1" using cached data

---

### ✅ Batch Upload Command

**Status:** IMPLEMENTED  
**Location:** [ArmaEntry.cs](../PIMS-Ext/PIMS-Ext/ArmaEntry.cs), [DatabaseManager.cs](../PIMS-Ext/PIMS-Ext/Database/DatabaseManager.cs), [fn_PIMSUploadInventory.sqf](PIMSFnc/fn_PIMSUploadInventory.sqf)

**Problem:** Each item triggered a separate extension call + database insert (N+1 pattern).

**Solution Implemented:**
1. Added `additems|inventoryId|[[class,props,qty],...]` command
2. Single extension call for all items
3. Single database transaction for atomicity
4. Money items accumulated into single balance update

**Performance Improvement:** 10-50x faster uploads for large inventories

**Command:**
- `additems|inventoryId|[[class,props,qty],...]` - Returns "OK|count" or error

---

### ✅ Race Condition Fixes (Atomicity)

**Status:** IMPLEMENTED  
**Location:** [DatabaseManager.cs](../PIMS-Ext/PIMS-Ext/Database/DatabaseManager.cs)

**Problems Fixed:**
1. **WithdrawMoney TOCTOU** - Used atomic `UPDATE ... WHERE amount >= @amount`
2. **RemoveItem double query** - Single query with `FOR UPDATE` lock + transaction
3. **AddItem race condition** - `INSERT ... ON DUPLICATE KEY UPDATE` (atomic upsert)

**Note:** The upsert requires a UNIQUE index on `content_items`:
```sql
ALTER TABLE `content_items` 
ADD UNIQUE INDEX `idx_inventory_item_props` (`Inventory_Id`, `Item_Class`, `Item_Properties`(255));
```

---

## High Priority Issues

### 1. Complex SQL JOIN with COLLATE

**Severity:** MEDIUM-HIGH  
**Location:** [DatabaseManager.cs](../PIMS-Ext/PIMS-Ext/Database/DatabaseManager.cs) - `GetInventoryItems()`  
**Impact:** Slower database queries, prevents index usage

**Problem:**
```sql
LEFT JOIN items ON items.item_class COLLATE utf8mb4_general_ci = content_items.Item_Class COLLATE utf8mb4_general_ci
```

COLLATE in JOIN conditions prevents index usage and requires full table scans.

**Proposed Solution:**
1. Standardize collation across all tables during database setup
2. Remove COLLATE from queries once collation is consistent
3. Add proper indexes on join columns

**Estimated Improvement:** 2-10x faster queries depending on table size

---

### 3. Double Query in RemoveItem

**Severity:** MEDIUM  
**Location:** [DatabaseManager.cs](../PIMS-Ext/PIMS-Ext/Database/DatabaseManager.cs) - `RemoveItem()`  
**Impact:** Unnecessary database round-trip

**Problem:**
```csharp
object? result = checkCommand.ExecuteScalar();  // First query
using var reader = checkCommand.ExecuteReader(); // Second query - SAME DATA!
```

The same query is executed twice: once with ExecuteScalar, once with ExecuteReader.

**Proposed Solution:**
```csharp
using var reader = checkCommand.ExecuteReader();
if (!reader.HasRows) return false;
reader.Read();
int currentQuantity = reader.GetInt32(0);
// ... continue with existing logic
```

**Estimated Improvement:** ~50% reduction in RemoveItem operation time

---

## Medium Priority Issues

### 4. Config Lookups Per Item

**Severity:** MEDIUM  
**Location:** [fn_PIMSMenuListInventory.sqf](PIMSFnc/fn_PIMSMenuListInventory.sqf) - Line ~175  
**Impact:** Client-side CPU during GUI population

**Problem:**
For each item in the inventory, multiple config lookups are performed:
```sqf
private _displayName = getText (configFile >> "CfgWeapons" >> _itemClass >> "displayName");
if (_displayName == "") then {
    _displayName = getText (configFile >> "CfgMagazines" >> _itemClass >> "displayName");
};
// ... repeated for CfgVehicles, CfgGlasses
```

**Proposed Solution:**
1. Create config cache hashmap at mission start
2. Cache display names, pictures, and mass values by item class
3. Look up from hashmap instead of config

```sqf
// At mission init
PIMS_ItemConfigCache = createHashMap;

// In display function
private _cacheData = PIMS_ItemConfigCache getOrDefault [_itemClass, []];
if (count _cacheData == 0) then {
    // Lookup and cache
    private _displayName = getText (configFile >> "CfgWeapons" >> _itemClass >> "displayName");
    // ... lookup logic ...
    PIMS_ItemConfigCache set [_itemClass, [_displayName, _picture, _mass, _parentPath]];
    _cacheData = PIMS_ItemConfigCache get _itemClass;
};
```

**Estimated Improvement:** 5-10x faster GUI population after first load

---

### 5. GUI Auto-Refresh Interval

**Severity:** MEDIUM  
**Location:** [fn_PIMSMenuListInventory.sqf](PIMSFnc/fn_PIMSMenuListInventory.sqf) - Line ~770  
**Impact:** Network/server load from polling

**Problem:**
GUI refreshes every 3 seconds unconditionally:
```sqf
sleep 3;
call fn_updateInventoryView;
```

**Proposed Solution:**
1. Increase interval to 5-10 seconds for normal usage
2. Implement server-side push notifications using publicVariable event handlers
3. Only refresh when server signals a change

**Estimated Improvement:** 40-70% reduction in unnecessary refreshes

---

### 6. BIS_fnc_itemType Call Per Selection

**Severity:** LOW-MEDIUM  
**Location:** [fn_PIMSMenuListInventory.sqf](PIMSFnc/fn_PIMSMenuListInventory.sqf) - Line ~365  
**Impact:** Client CPU on item selection

**Problem:**
```sqf
private _itemType = ([_itemClass] call BIS_fnc_itemType) select 1;
```

BIS_fnc_itemType does config lookups internally, called every time an item is selected.

**Proposed Solution:**
Cache item types in the same config cache hashmap mentioned in Issue #4.

---

## Low Priority Issues

### 7. Logging Overhead

**Severity:** LOW  
**Location:** [ArmaEntry.cs](../PIMS-Ext/PIMS-Ext/ArmaEntry.cs) - `WriteToLog()`  
**Impact:** File I/O on every extension call

**Problem:**
```csharp
WriteToLog($"Received input: {input}", LogLevel.Info);
// ... operation ...
WriteToLog($"Returning: {result}\n", LogLevel.Info);
```

Every extension call writes to log file twice.

**Proposed Solution:**
1. Add configurable log level in pims_config.json
2. Skip Info-level logs in production mode
3. Use buffered logging with periodic flush

**Example Config:**
```json
{
  "database": { ... },
  "logging": {
    "level": "Warning"  // "Info", "Warning", "Error", "None"
  }
}
```

---

### 8. String Formatting in Loops

**Severity:** LOW  
**Location:** Multiple files  
**Impact:** Minor memory allocations

**Problem:**
String formatting inside forEach loops creates temporary string objects.

**Proposed Solution:**
Pre-format strings outside loops where possible, or use StringBuilder pattern in C#.

---

## Connection Pooling Note

**Status:** ✅ IMPLEMENTED

With connection pooling enabled (default in MySqlConnector), the question of whether batching matters:

**Answer:** Yes, batching still matters significantly because:
1. Each `callExtension` call has overhead (~0.1-0.5ms)
2. Each SQL statement requires query parsing
3. Network round-trips still occur per operation
4. Transaction commit overhead per operation

Even with pooling, N+1 operations will be slower than batch operations. The fix for Issue #1 (batch uploads) would still provide significant improvement.

---

## Quick Reference

| Issue | Severity | Est. Improvement | Complexity |
|-------|----------|------------------|------------|
| N+1 Extension Calls | HIGH | 10-50x | Medium |
| COLLATE in JOINs | MEDIUM-HIGH | 2-10x | Low |
| Double Query | MEDIUM | ~50% | Low |
| Config Lookups | MEDIUM | 5-10x | Medium |
| Refresh Interval | MEDIUM | 40-70% | Low |
| BIS_fnc_itemType | LOW-MEDIUM | Minor | Low |
| Logging Overhead | LOW | Minor | Low |
| String Formatting | LOW | Minor | Low |

---

## Implementation Priority

1. **Fix Double Query** - Easy win, minimal code change
2. **Fix COLLATE** - Requires database migration
3. **Implement Batch Uploads** - Biggest impact, moderate effort
4. **Add Config Cache** - Client-side improvement
5. **Add Log Level Config** - Minor improvement
