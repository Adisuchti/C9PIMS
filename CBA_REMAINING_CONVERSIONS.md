# CBA Remaining Conversion Opportunities

This documents client-side `spawn`/`waitUntil`/`sleep` patterns that could be converted to CBA
unscheduled equivalents. These are **medium/low impact** since they only affect individual clients
(not the server), but collectively they reduce scheduled thread count on each client to near zero.

The two **high-impact server-side** conversions are already implemented:
- ✅ `PlayerConnected` handler → `CBA_fnc_waitUntilAndExecute` (zero scheduler threads per connecting player)
- ✅ Monitor display loop → `CBA_fnc_waitAndExecute` + `CBA_fnc_addPerFrameHandler` (zero permanent scheduler thread)

---

## 1. `fn_updateInventoryView` — Keystone Change

**File:** `fn_PIMSMenuListInventory.sqf` ~line 127  
**Impact:** 🟡 MEDIUM (enables all other client-side conversions)  
**Difficulty:** Medium  

### Current Pattern
```sqf
fn_updateInventoryView = {
    // ... setup ...
    remoteExec ["PIMS_fnc_PIMSGetInventoryData", 2];
    
    waitUntil {
        sleep 0.1;
        missionNamespace getVariable [format ["PIMS_InventoryDataReady_%1", _playerUid], false]
    };
    
    // ... 200+ lines of UI update code ...
};
```

### Problem
This function uses `waitUntil` internally, which forces **every caller** to use `spawn` 
(you can't `call` a function that contains `waitUntil` from unscheduled env). This cascades 
through all button handlers and the auto-refresh loop.

### CBA Conversion
Split into request + callback:
```sqf
fn_updateInventoryView = {
    // ... setup ...
    remoteExec ["PIMS_fnc_PIMSGetInventoryData", 2];
    
    [{
        // Condition: server data ready
        params ["_playerUid"];
        missionNamespace getVariable [format ["PIMS_InventoryDataReady_%1", _playerUid], false]
    }, {
        // Statement: update UI (runs once data arrives)
        params ["_playerUid"];
        // ... 200+ lines of UI update code (unchanged) ...
    }, [_playerUid]] call CBA_fnc_waitUntilAndExecute;
};
```

### Cascade Effect
Once this function no longer uses `waitUntil`, its callers no longer need `spawn`:
- `fn_PIMSOpenMenu.sqf` line 25: `spawn` → `call`
- All button handlers that end with `call fn_updateInventoryView` no longer need `spawn`

---

## 2. Retrieve Button Handler (Inventory Mode)

**File:** `fn_PIMSMenuListInventory.sqf` ~line 485  
**Impact:** 🟡 MEDIUM  
**Difficulty:** Easy (after #1 is done)

### Current Pattern
```sqf
[_containerNetId, _playerUid, _selectedIndex, _quantityEdit] spawn {
    // ... setup + remoteExec to server ...
    
    waitUntil {
        sleep 0.1;
        missionNamespace getVariable [format ["PIMS_retrieveDone_%1", _playerUid], false]
    };
    
    // ... handle result + refresh UI ...
};
```

### CBA Conversion
```sqf
// ... setup + remoteExec to server (no spawn needed) ...

[{
    missionNamespace getVariable [format ["PIMS_retrieveDone_%1", _playerUid], false]
}, {
    // Handle result
    if (_success) then { call fn_updateInventoryView; };
}, [_playerUid, ...]] call CBA_fnc_waitUntilAndExecute;
```

---

## 3. Withdraw Money Handler (Bank Mode)

**File:** `fn_PIMSMenuListInventory.sqf` ~line 530  
**Impact:** 🟡 MEDIUM  
**Difficulty:** Easy (after #1 is done)

### Current Pattern
Same `spawn { setup; remoteExec; waitUntil { sleep 0.1; doneFlag }; handle result }` pattern.

### CBA Conversion
Same approach as #2 — replace `spawn`+`waitUntil` with `CBA_fnc_waitUntilAndExecute`.

---

## 4. Retrieve All of Type Handler

**File:** `fn_PIMSMenuListInventory.sqf` ~line 591  
**Impact:** 🟡 MEDIUM  
**Difficulty:** Easy (after #1 is done)

### Current Pattern
Identical spawn+waitUntil pattern as #2 and #3.

### CBA Conversion
Same approach — `CBA_fnc_waitUntilAndExecute` with done flag as condition.

---

## 5. Retrieve All Items Handler

**File:** `fn_PIMSMenuListInventory.sqf` ~line 634  
**Impact:** 🟡 MEDIUM  
**Difficulty:** Easy (after #1 is done)

### Current Pattern
Identical spawn+waitUntil pattern.

### CBA Conversion
Same approach — `CBA_fnc_waitUntilAndExecute`.

---

## 6. Auto-Refresh Loop

**File:** `fn_PIMSMenuListInventory.sqf` ~line 764  
**Impact:** 🟢 LOW-MEDIUM  
**Difficulty:** Easy

### Current Pattern
```sqf
[] spawn {
    while {true} do {
        if (dialogClosed) exitWith {};
        sleep 3;
        if (!updating) then { call fn_updateInventoryView; };
    };
};
```

### Problem
Creates a permanent scheduled thread for the entire time the dialog is open.

### CBA Conversion
```sqf
private _pfhId = [{
    private _playerUid = getPlayerUID player;
    private _closeMenu = missionNamespace getVariable [format ["PIMS_closeMenu_%1", _playerUid], false];
    
    if (_closeMenu || isNull (findDisplay 142351)) exitWith {
        missionNamespace setVariable [format ["PIMS_closeMenu_%1", _playerUid], false];
        [_this select 1] call CBA_fnc_removePerFrameHandler;  // Self-remove
    };
    
    private _isUpdating = uiNamespace getVariable ["PIMS_isUpdating", false];
    if (!_isUpdating) then {
        call fn_updateInventoryView;
    };
}, 3, []] call CBA_fnc_addPerFrameHandler;
```

**Note:** The PFH self-removes when the dialog closes. No scheduler thread while open.

---

## 7. `fn_PIMSOpenMenu` spawn

**File:** `fn_PIMSOpenMenu.sqf` line 25  
**Impact:** 🟢 LOW  
**Difficulty:** Trivial (after #1 is done)

### Current Pattern
```sqf
[_containerNetId, _inventoryId, _isAdmin] spawn PIMS_fnc_PIMSMenuListInventory;
```

### Why it needs spawn
`PIMS_fnc_PIMSMenuListInventory` calls `fn_updateInventoryView` which uses `waitUntil`.

### CBA Conversion
Once #1 is implemented and `fn_updateInventoryView` no longer uses `waitUntil`, this becomes:
```sqf
[_containerNetId, _inventoryId, _isAdmin] call PIMS_fnc_PIMSMenuListInventory;
```

---

## Implementation Priority

| # | Target | Impact | Depends On | Effort |
|---|--------|--------|------------|--------|
| 1 | `fn_updateInventoryView` | 🟡 Medium | — | Medium |
| 2 | Retrieve button | 🟡 Medium | #1 (for refresh) | Easy |
| 3 | Withdraw button | 🟡 Medium | #1 (for refresh) | Easy |
| 4 | Retrieve all type | 🟡 Medium | #1 (for refresh) | Easy |
| 5 | Retrieve all items | 🟡 Medium | #1 (for refresh) | Easy |
| 6 | Auto-refresh loop | 🟢 Low-Med | #1 (calls refresh) | Easy |
| 7 | OpenMenu spawn | 🟢 Low | #1 | Trivial |

**Recommended order:** Implement #1 first (the keystone), then #2-#5 become trivial.
After that, #6 and #7 are quick wins.

## Net Effect After Full Conversion

**Before (current client):**
- Opening one PIMS menu creates ~3 scheduled threads (menu init, auto-refresh, button handler on use)
- Each button press adds another temporary scheduled thread

**After full CBA conversion:**
- Opening a PIMS menu creates **zero** scheduled threads
- All polling runs in unscheduled CBA handlers
- Combined with the server-side conversions already implemented, the entire PIMS system
  operates with **zero permanent scheduled threads**
