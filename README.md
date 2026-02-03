This file is AI generated. Sadly, I acknowledge that AI can be useful tool.
# PIMS - Persistent Inventory Management System

## What is PIMS?

PIMS is an Arma 3 mod that provides **persistent storage containers** connected to a MySQL/MariaDB database. Players can store and retrieve items from special containers that persist across server restarts, player disconnects, and mission changes.

### Key Features

- **Persistent Storage** - Items stored in PIMS containers are saved to a database and persist indefinitely
- **Permission System** - Control which players can access which inventories via database permissions
- **Admin System** - Designate admins who have elevated access privileges
- **Money System** - Physical money items that convert to digital balance when deposited
- **Real-time Monitors** - Optional display screens showing inventory contents
- **Eden Editor Integration** - Easy setup using 3D editor modules
- **Version Check** - Automatic client/server version mismatch detection
- **High Performance** - Native C# extension handles database operations (10-100x faster than pure SQF)

---

## How It Works

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                              ARMA 3                                         │
│  ┌────────────────────────────────────────────────────────────────────┐     │
│  │                    PIMS ADDON (SQF/PBO)                            │     │
│  │                                                                    │     │
│  │   Eden Modules          GUI Dialog           SQF Functions         │     │
│  │   ┌──────────┐         ┌──────────┐         ┌──────────────┐       │     │
│  │   │  Init    │         │ Inventory│         │ Upload/      │       │     │
│  │   │  Module  │         │   Menu   │         │ Retrieve     │       │     │
│  │   └──────────┘         └──────────┘         └──────────────┘       │     │
│  │   ┌──────────┐                                                     │     │
│  │   │  Add     │                                                     │     │
│  │   │Inventory │                                                     │     │
│  │   └──────────┘                                                     │     │
│  └────────────────────────────────────────────────────────────────────┘     │
│                                    │                                        │
│                           callExtension                                     │
│                                    │                                        │
│  ┌─────────────────────────────────▼──────────────────────────────────┐     │
│  │                    PIMS-EXT (C# DLL)                               │     │
│  │                                                                    │     │
│  │   Command Router        Database Manager         Caching Layer     │     │
│  │   ┌──────────┐         ┌──────────────┐         ┌──────────┐       │     │
│  │   │ Parse &  │────────►│    MySQL     │◄───────►│ In-Memory│       │     │
│  │   │ Route    │         │  Operations  │         │  Cache   │       │     │
│  │   └──────────┘         └──────────────┘         └──────────┘       │     │
│  └─────────────────────────────────┬──────────────────────────────────┘     │
└────────────────────────────────────┼────────────────────────────────────────┘
                                     │
                          ┌──────────▼──────────┐
                          │   MySQL/MariaDB     │
                          │     Database        │
                          └─────────────────────┘
```

### Data Flow

1. **Player Interaction** → Player uses action menu on a PIMS container
2. **SQF Processing** → Addon handles UI and sends commands to extension
3. **Extension Processing** → C# DLL executes database operations
4. **Database Storage** → Items are stored/retrieved from MySQL
5. **Response** → Results flow back through extension to SQF to player

---

## Installation

### Requirements

- Arma 3 Dedicated Server (or local for testing)
- MySQL or MariaDB server
- .NET 8.0 Runtime (x64) - for the extension

### Server Setup

1. **Install the Addon (PBO)**
   - Copy `PIMS.pbo` to your server's `@PIMS/addons/` folder
   - Add `@PIMS` to your server's `-mod=` parameter

2. **Install the Extension (DLL)**
   - Copy `PIMS-Ext_x64.dll` to your Arma 3 root directory (same folder as `arma3server_x64.exe`)

3. **Configure Database Connection**
   - Create `pims_config.json` in the Arma 3 root directory (same folder as the DLL and server executable):
   ```json
   {
     "database": {
       "server": "localhost",
       "database": "pims_db",
       "user": "pims_user",
       "password": "your_secure_password",
       "port": 3306
     }
   }
   ```

4. **Set Up Database**
   - Create the database and required tables (see Database Schema section)
   - Add player permissions to the `permissions` table
   - Optionally add admins to the `admins` table

5. **Client Setup**
   - Clients need the PIMS addon (`@PIMS`) but NOT the DLL or config file

### Mission Setup (Eden Editor)

1. Place a **PIMS Init Module** (found under Modules → PIMS) - required once per mission
2. Place a **PIMS Add Inventory Module** for each storage location
3. Set the `Inventory ID` attribute to match a database inventory
4. Sync the module to the container object(s) players will interact with

---

## Database Schema

### Required Tables

```sql
-- Main inventory definitions
CREATE TABLE inventories (
    inventory_id INT PRIMARY KEY,
    inventory_name VARCHAR(255),
    inventory_money DOUBLE DEFAULT 0
);

-- Items stored in inventories
CREATE TABLE content_items (
    Content_Item_Id INT PRIMARY KEY AUTO_INCREMENT,
    Inventory_Id INT,
    Item_Class VARCHAR(255),
    Item_Properties TEXT,
    Item_Quantity INT,
    FOREIGN KEY (Inventory_Id) REFERENCES inventories(inventory_id)
);

-- Player access permissions
CREATE TABLE permissions (
    Permission_Id INT PRIMARY KEY AUTO_INCREMENT,
    Inventory_Id INT,
    Player_Id VARCHAR(50),  -- Steam UID
    FOREIGN KEY (Inventory_Id) REFERENCES inventories(inventory_id)
);

-- Admin users
CREATE TABLE admins (
    AdminId INT PRIMARY KEY AUTO_INCREMENT,
    PlayerId VARCHAR(50)  -- Steam UID
);

-- Transaction logs
CREATE TABLE logs (
    Transaction_Item VARCHAR(255),
    Transaction_Quantity INT,
    Transaction_Inventory_Id INT,
    isMarketActivity BOOLEAN DEFAULT FALSE
);
```

### Example Setup

```sql
-- Create an inventory
INSERT INTO inventories (inventory_id, inventory_name) VALUES (1, 'Team Alpha Storage');

-- Grant access to a player (use their Steam64 ID)
INSERT INTO permissions (Inventory_Id, Player_Id) VALUES (1, '76561198012345678');

-- Make someone an admin
INSERT INTO admins (PlayerId) VALUES ('76561198012345678');
```

---

## Money System

PIMS includes a currency system with physical money items:

| Item Class | Value | Description |
|------------|-------|-------------|
| `PIMS_Money_1` | 1 | 1 Credit note |
| `PIMS_Money_10` | 10 | 10 Credit note |
| `PIMS_Money_50` | 50 | 50 Credit note |
| `PIMS_Money_100` | 100 | 100 Credit note |
| `PIMS_Money_500` | 500 | 500 Credit note |
| `PIMS_Money_1000` | 1000 | 1000 Credit note |

**How it works:**
- Upload physical money → Converts to digital balance in the inventory
- Withdraw from balance → Spawns physical money items in the container

---

## Building from Source

### Addon (PBO)

Use Arma 3 Tools (Addon Builder) or PBOManager to pack the `PIMS/` folder.

### Extension (DLL)

```powershell
cd PIMS-Ext
dotnet publish -r win-x64 -c Release
```

Output: `bin\Release\net8.0\win-x64\publish\PIMS-Ext_x64.dll`

---

## Logging & Debugging

The extension produces two log files in the Arma 3 root directory:

| File | Contents |
|------|----------|
| `PIMS_logs.txt` | General logs - commands, responses, debug info |
| `PIMS_errors.txt` | Error logs - database errors, exceptions |

---

## Version Compatibility

PIMS automatically checks that clients have the same addon version as the server. On mismatch, a global warning is broadcast:

```
PIMS WARNING: Player JohnDoe has version mismatch! Client: 1.9.0, Server: 2.0.0
```

---

## Additional Documentation

For detailed technical documentation, see:

- [PIMS_CONTEXT.md](PIMS_CONTEXT.md) - Full system architecture and concepts
- [PIMS_EXTENSION.md](PIMS_EXTENSION.md) - C# extension command reference
- [PIMS_FUNCTIONS.md](PIMS_FUNCTIONS.md) - SQF function reference
- [PIMS_REMAINING_ISSUES.md](PIMS_REMAINING_ISSUES.md) - Known issues and optimization notes

---

## Dependencies

### Server
- .NET 8.0 Runtime (x64)
- MySQL/MariaDB 5.7+

### Addon
- Arma 3 Modules Framework (A3_Modules_F)
- ACE3 (ace_common)
