using System.Collections.Concurrent;
using System.Runtime.InteropServices;
using System.Text;
using System.Text.Json;
using PIMSExt.Models;
using PIMSExt.Database;

namespace PIMSExt
{
    public enum LogLevel
    {
        Info,
        Warning,
        Error
    }

    public static class ArmaEntry
    {
        private static DatabaseManager? _dbManager;
        private static bool _isLogInitialized = false;
        private static bool _configLoaded = false;
        private static readonly object _initLockObject = new object(); // Only for initialization
        
        // Per-inventory locks for fine-grained concurrency control
        private static readonly ConcurrentDictionary<int, object> _inventoryLocks = new ConcurrentDictionary<int, object>();
        
        // Thread-safe caches using ConcurrentDictionary
        private static readonly ConcurrentDictionary<int, List<InventoryItem>> _inventoryCache = new ConcurrentDictionary<int, List<InventoryItem>>();
        private static readonly ConcurrentDictionary<int, double> _moneyCache = new ConcurrentDictionary<int, double>();
        
        // Change tracking: stores hash of last inventory state for change detection
        private static readonly ConcurrentDictionary<int, string> _inventoryHashCache = new ConcurrentDictionary<int, string>();
        
        // Background refresh tracking: stores pending hash (computed in background) and last refresh time
        private static readonly ConcurrentDictionary<int, string> _pendingHashCache = new ConcurrentDictionary<int, string>();
        private static readonly ConcurrentDictionary<int, DateTime> _lastRefreshTime = new ConcurrentDictionary<int, DateTime>();
        private static readonly ConcurrentDictionary<int, bool> _refreshInProgress = new ConcurrentDictionary<int, bool>();
        
        // Static data caches - these rarely change during a mission
        // Inventory names are immutable during gameplay
        private static readonly ConcurrentDictionary<int, string> _inventoryNameCache = new ConcurrentDictionary<int, string>();
        
        // Admin status - cache with TTL (checked once per player per session typically)
        private static readonly ConcurrentDictionary<string, (bool IsAdmin, DateTime CachedAt)> _adminCache = new ConcurrentDictionary<string, (bool, DateTime)>();
        private static readonly TimeSpan _adminCacheTTL = TimeSpan.FromMinutes(5); // Re-check every 5 minutes
        
        // Permission cache - key is "inventoryId:playerUid"
        private static readonly ConcurrentDictionary<string, (bool HasPermission, DateTime CachedAt)> _permissionCache = new ConcurrentDictionary<string, (bool, DateTime)>();
        private static readonly TimeSpan _permissionCacheTTL = TimeSpan.FromMinutes(5); // Re-check every 5 minutes
        
        // Helper to get or create a lock for a specific inventory
        private static object GetInventoryLock(int inventoryId)
        {
            return _inventoryLocks.GetOrAdd(inventoryId, _ => new object());
        }

        [UnmanagedCallersOnly(EntryPoint = "RVExtension")]
        public static unsafe void RVExtension(byte* output, int outputSize, byte* function)
        {
            try
            {
                string? inputData = Marshal.PtrToStringAnsi((IntPtr)function);

                if (inputData == null)
                {
                    ReturnString(output, outputSize, "Error: Input was null");
                    return;
                }

                if (inputData == "ping")
                {
                    ReturnString(output, outputSize, "pong");
                    return;
                }

                string result = HandleLogic(inputData);
                ReturnString(output, outputSize, result);
            }
            catch (Exception ex)
            {
                ReturnString(output, outputSize, $"CRASH: {ex.Message}");
            }
        }

        private static unsafe void ReturnString(byte* output, int outputSize, string data)
        {
            if (string.IsNullOrEmpty(data)) data = "";
            byte[] bytes = Encoding.ASCII.GetBytes(data);
            int len = Math.Min(bytes.Length, outputSize - 1);
            Marshal.Copy(bytes, 0, (IntPtr)output, len);
            output[len] = 0; // Null terminator
        }

        private static string HandleLogic(string input)
        {
            if (string.IsNullOrEmpty(input)) return "Error: Input was null";

            // Initialize logging only once (thread-safe)
            if (!_isLogInitialized)
            {
                lock (_initLockObject)
                {
                    if (!_isLogInitialized)
                    {
                        ResetLogs();
                        _isLogInitialized = true;
                    }
                }
            }

            WriteToLog($"Received input: {input}", LogLevel.Info);

            string[] parts = input.Split('|');
            if (parts.Length == 0) return "Error: No parts found";

            string command = parts[0].ToLower();

            try
            {
                string result = command switch
                {
                    "initdb" => HandleInitDb(parts),
                    "checkpermission" => HandleCheckPermission(parts),
                    "uploadinventory" => HandleUploadInventory(parts),
                    "getinventory" => HandleGetInventory(parts),
                    "additem" => HandleAddItem(parts),
                    "additems" => HandleAddItems(parts),
                    "removeitem" => HandleRemoveItem(parts),
                    "removeitems" => HandleRemoveItems(parts),
                    "getinventoryname" => HandleGetInventoryName(parts),
                    "isadmin" => HandleIsAdmin(parts),
                    "getinventorymoney" => HandleGetInventoryMoney(parts),
                    "withdrawmoney" => HandleWithdrawMoney(parts),
                    "hasinventorychanged" => HandleHasInventoryChanged(parts),
                    "queuerefresh" => HandleQueueRefresh(parts),
                    "ping" => "pong",
                    _ => $"Error: Unknown command '{command}'"
                };
                
                WriteToLog($"Returning: {result}\n", LogLevel.Info);
                return result;
            }
            catch (Exception ex)
            {
                WriteToLog($"in {command}: {ex.Message}\n{ex.StackTrace}", LogLevel.Error);
                return $"Error: {ex.Message}";
            }
        }

        #region Command Handlers

        /// <summary>
        /// Initialize database connection from config file
        /// Format: initdb (no parameters needed)
        /// Reads from pims_config.json in same directory as DLL
        /// </summary>
        private static string HandleInitDb(string[] parts)
        {
            if (_dbManager != null && _configLoaded)
            {
                WriteToLog("Database already initialized", LogLevel.Info);
                return "OK";
            }

            try
            {
                // Get config file path (same directory as DLL)
                string dllPath = AppDomain.CurrentDomain.BaseDirectory;
                string configPath = Path.Combine(dllPath, "pims_config.json");

                if (!File.Exists(configPath))
                {
                    WriteToLog($"Config file not found at: {configPath}", LogLevel.Error);
                    return $"Error: Config file not found at {configPath}";
                }

                // Read and parse config
                string jsonContent = File.ReadAllText(configPath);
                using JsonDocument doc = JsonDocument.Parse(jsonContent);
                
                var dbConfig = doc.RootElement.GetProperty("database");
                string server = dbConfig.GetProperty("server").GetString() ?? "localhost";
                string database = dbConfig.GetProperty("database").GetString() ?? "pims_db";
                string user = dbConfig.GetProperty("user").GetString() ?? "root";
                string password = dbConfig.GetProperty("password").GetString() ?? "";
                int port = dbConfig.GetProperty("port").GetInt32();

                WriteToLog($"Loaded config: Server={server}, Database={database}, Port={port}", LogLevel.Info);

                _dbManager = new DatabaseManager(server, database, user, password, port);
                
                if (_dbManager.TestConnection(out string errorMessage))
                {
                    _configLoaded = true;
                    WriteToLog("Database connection initialized successfully", LogLevel.Info);
                    return "OK";
                }
                else
                {
                    WriteToLog($"Database connection failed: {errorMessage}, Stack trace: {errorMessage}", LogLevel.Error);
                    return $"Error: Could not connect to database - {errorMessage}";
                }
            }
            catch (Exception ex)
            {
                WriteToLog($"Error loading config: {ex.Message}, Stack trace: {ex.StackTrace}", LogLevel.Error);
                return $"Error: Failed to load config - {ex.Message}";
            }
        }

        /// <summary>
        /// Check if player has permission to access inventory
        /// Format: checkpermission|inventoryId|playerUid
        /// Returns: "1" if has permission, "0" if not
        /// </summary>
        private static string HandleCheckPermission(string[] parts)
        {
            if (_dbManager == null)
                return "Error: Database not initialized";

            if (parts.Length < 3)
                return "Error: checkpermission requires 2 parameters: inventoryId|playerUid";

            if (!int.TryParse(parts[1], out int inventoryId))
                return "Error: inventoryId must be a number";

            string playerUid = parts[2];
            string cacheKey = $"{inventoryId}:{playerUid}";
            
            // Check cache first
            if (_permissionCache.TryGetValue(cacheKey, out var cached))
            {
                // Return cached value if not expired
                if (DateTime.UtcNow - cached.CachedAt < _permissionCacheTTL)
                {
                    return cached.HasPermission ? "1" : "0";
                }
            }
            
            // Cache miss or expired - query database
            bool hasPermission = _dbManager.CheckPermission(inventoryId, playerUid);
            _permissionCache[cacheKey] = (hasPermission, DateTime.UtcNow);
            return hasPermission ? "1" : "0";
        }

        /// <summary>
        /// Get inventory name by ID
        /// Format: getinventoryname|inventoryId
        /// Returns: inventory name or error
        /// </summary>
        private static string HandleGetInventoryName(string[] parts)
        {
            if (_dbManager == null)
                return "Error: Database not initialized";

            if (parts.Length < 2)
                return "Error: getinventoryname requires 1 parameter: inventoryId";

            if (!int.TryParse(parts[1], out int inventoryId))
                return "Error: inventoryId must be a number";

            // Inventory names never change during mission - use permanent cache
            if (_inventoryNameCache.TryGetValue(inventoryId, out string? cachedName))
            {
                return cachedName;
            }
            
            // Cache miss - query database once
            string? name = _dbManager.GetInventoryName(inventoryId);
            if (name != null)
            {
                _inventoryNameCache[inventoryId] = name;
            }
            return name ?? "Error: Inventory not found";
        }

        /// <summary>
        /// Check if player is admin
        /// Format: isadmin|playerUid
        /// Returns: "1" if admin, "0" if not
        /// </summary>
        private static string HandleIsAdmin(string[] parts)
        {
            if (_dbManager == null)
                return "Error: Database not initialized";

            if (parts.Length < 2)
                return "Error: isadmin requires 1 parameter: playerUid";

            string playerUid = parts[1];
            
            // Check cache first
            if (_adminCache.TryGetValue(playerUid, out var cached))
            {
                // Return cached value if not expired
                if (DateTime.UtcNow - cached.CachedAt < _adminCacheTTL)
                {
                    return cached.IsAdmin ? "1" : "0";
                }
            }
            
            // Cache miss or expired - query database
            bool isAdmin = _dbManager.IsAdmin(playerUid);
            _adminCache[playerUid] = (isAdmin, DateTime.UtcNow);
            return isAdmin ? "1" : "0";
        }

        /// <summary>
        /// Upload inventory from database to extension cache
        /// Format: uploadinventory|inventoryId
        /// Returns: "OK" or error
        /// </summary>
        private static string HandleUploadInventory(string[] parts)
        {
            if (_dbManager == null)
                return "Error: Database not initialized";

            if (parts.Length < 2)
                return "Error: uploadinventory requires 1 parameter: inventoryId";

            if (!int.TryParse(parts[1], out int inventoryId))
                return "Error: inventoryId must be a number";

            WriteToLog($"Uploading inventory {inventoryId} to cache", LogLevel.Info);
            
            // Query database and store in cache with per-inventory lock
            List<InventoryItem> items = _dbManager.GetInventoryItems(inventoryId);
            double money = _dbManager.GetInventoryMoney(inventoryId);

            lock (GetInventoryLock(inventoryId))
            {
                _inventoryCache[inventoryId] = items;
                _moneyCache[inventoryId] = money;
                
                // Update hash for change detection
                string newHash = ComputeInventoryHash(items, money);
                _inventoryHashCache[inventoryId] = newHash;
            }

            WriteToLog($"Cached {items.Count} items and {money} credits for inventory {inventoryId}", LogLevel.Info);
            return "OK";
        }

        /// <summary>
        /// Get all items from inventory cache
        /// Format: getinventory|inventoryId
        /// Returns: SQF array of items
        /// </summary>
        private static string HandleGetInventory(string[] parts)
        {
            if (_dbManager == null)
                return "Error: Database not initialized";

            if (parts.Length < 2)
                return "Error: getinventory requires 1 parameter: inventoryId";

            if (!int.TryParse(parts[1], out int inventoryId))
                return "Error: inventoryId must be a number";

            List<InventoryItem> items;
            lock (GetInventoryLock(inventoryId))
            {
                if (!_inventoryCache.TryGetValue(inventoryId, out items!) || items == null)
                {
                    // Cache miss - upload first
                    WriteToLog($"Cache miss for inventory {inventoryId}, uploading now", LogLevel.Warning);
                    items = _dbManager.GetInventoryItems(inventoryId);
                    double money = _dbManager.GetInventoryMoney(inventoryId);
                    _inventoryCache[inventoryId] = items;
                    _moneyCache[inventoryId] = money;
                    
                    // Update hash for change detection
                    string newHash = ComputeInventoryHash(items, money);
                    _inventoryHashCache[inventoryId] = newHash;
                }
            }
            
            WriteToLog($"Returning {items.Count} cached items for inventory {inventoryId}", LogLevel.Info);
            
            // Format as SQF array: [[contentItemId,class,properties,quantity],...]
            // IMPORTANT: Escape special characters in strings for SQF
            var itemArrays = items.Select(item => 
            {
                // Escape quotes in SQF strings by doubling them
                string escapedClass = item.ItemClass.Replace("\"", "\"\"");
                string escapedProps = item.Properties.Replace("\"", "\"\"");
                
                return $"[{item.ContentItemId},\"{escapedClass}\",\"{escapedProps}\",{item.Quantity}]";
            });
            
            return "[" + string.Join(",", itemArrays) + "]";
        }

        /// <summary>
        /// Get inventory money from cache
        /// Format: getinventorymoney|inventoryId
        /// Returns: money amount or error
        /// </summary>
        private static string HandleGetInventoryMoney(string[] parts)
        {
            if (_dbManager == null)
                return "Error: Database not initialized";

            if (parts.Length < 2)
                return "Error: getinventorymoney requires 1 parameter: inventoryId";

            if (!int.TryParse(parts[1], out int inventoryId))
                return "Error: inventoryId must be a number";

            double money;
            lock (GetInventoryLock(inventoryId))
            {
                if (!_moneyCache.TryGetValue(inventoryId, out money))
                {
                    // Cache miss - query and cache
                    WriteToLog($"Money cache miss for inventory {inventoryId}, querying now", LogLevel.Warning);
                    money = _dbManager.GetInventoryMoney(inventoryId);
                    _moneyCache[inventoryId] = money;
                }
            }

            return money.ToString();
        }

        /// <summary>
        /// Add item to inventory
        /// Format: additem|inventoryId|itemClass|properties|quantity
        /// Returns: "OK" or error
        /// </summary>
        private static string HandleAddItem(string[] parts)
        {
            if (_dbManager == null)
                return "Error: Database not initialized";

            if (parts.Length < 5)
                return "Error: additem requires 4 parameters: inventoryId|itemClass|properties|quantity";

            if (!int.TryParse(parts[1], out int inventoryId))
                return "Error: inventoryId must be a number";

            string itemClass = parts[2];
            string properties = parts[3];
            
            if (!int.TryParse(parts[4], out int quantity))
                return "Error: quantity must be a number";

            bool success = _dbManager.AddItem(inventoryId, itemClass, properties, quantity);
            
            // Invalidate cache so next upload will refresh
            if (success)
            {
                lock (GetInventoryLock(inventoryId))
                {
                    _inventoryCache.TryRemove(inventoryId, out _);
                    _moneyCache.TryRemove(inventoryId, out _);
                    _inventoryHashCache.TryRemove(inventoryId, out _);
                }
                WriteToLog($"Cache invalidated for inventory {inventoryId} after adding item", LogLevel.Info);
            }
            
            return success ? "OK" : "Error: Failed to add item to database";
        }

        /// <summary>
        /// Add multiple items to inventory in a single batch operation
        /// Format: additems|inventoryId|[[class,props,qty],[class,props,qty],...]
        /// Returns: "OK|count" or error
        /// This is much faster than calling additem multiple times
        /// </summary>
        private static string HandleAddItems(string[] parts)
        {
            if (_dbManager == null)
                return "Error: Database not initialized";

            if (parts.Length < 3)
                return "Error: additems requires 2 parameters: inventoryId|itemsArray";

            if (!int.TryParse(parts[1], out int inventoryId))
                return "Error: inventoryId must be a number";

            string itemsArrayStr = parts[2];
            
            // Parse SQF array format: [[class,props,qty],[class,props,qty],...]
            var items = ParseSqfItemsArray(itemsArrayStr);
            if (items == null || items.Count == 0)
                return "Error: Failed to parse items array or array is empty";

            int successCount = _dbManager.AddItems(inventoryId, items);
            
            // Invalidate cache
            if (successCount > 0)
            {
                lock (GetInventoryLock(inventoryId))
                {
                    _inventoryCache.TryRemove(inventoryId, out _);
                    _moneyCache.TryRemove(inventoryId, out _);
                    _inventoryHashCache.TryRemove(inventoryId, out _);
                }
                WriteToLog($"Batch added {successCount} items to inventory {inventoryId}, cache invalidated", LogLevel.Info);
            }
            
            return $"OK|{successCount}";
        }

        /// <summary>
        /// Parse SQF array format: [[class,props,qty],[class,props,qty],...]
        /// </summary>
        private static List<(string itemClass, string properties, int quantity)>? ParseSqfItemsArray(string input)
        {
            var result = new List<(string, string, int)>();
            
            try
            {
                // Remove outer brackets
                input = input.Trim();
                if (input.StartsWith("[")) input = input.Substring(1);
                if (input.EndsWith("]")) input = input.Substring(0, input.Length - 1);
                
                if (string.IsNullOrWhiteSpace(input))
                    return result;
                
                // Parse each item array: [class,props,qty]
                int depth = 0;
                int itemStart = -1;
                
                for (int i = 0; i < input.Length; i++)
                {
                    char c = input[i];
                    
                    if (c == '[')
                    {
                        if (depth == 0) itemStart = i;
                        depth++;
                    }
                    else if (c == ']')
                    {
                        depth--;
                        if (depth == 0 && itemStart >= 0)
                        {
                            string itemStr = input.Substring(itemStart + 1, i - itemStart - 1);
                            var parsed = ParseSingleItem(itemStr);
                            if (parsed.HasValue)
                                result.Add(parsed.Value);
                            itemStart = -1;
                        }
                    }
                }
                
                return result;
            }
            catch (Exception ex)
            {
                WriteToLog($"Failed to parse SQF items array: {ex.Message}", LogLevel.Error);
                return null;
            }
        }

        /// <summary>
        /// Parse a single item: "class,props,qty" or ""class"",""props"",qty"
        /// </summary>
        private static (string itemClass, string properties, int quantity)? ParseSingleItem(string input)
        {
            try
            {
                // Handle SQF string format with quotes
                var parts = new List<string>();
                bool inQuotes = false;
                var current = new StringBuilder();
                
                for (int i = 0; i < input.Length; i++)
                {
                    char c = input[i];
                    
                    if (c == '"')
                    {
                        inQuotes = !inQuotes;
                    }
                    else if (c == ',' && !inQuotes)
                    {
                        parts.Add(current.ToString().Trim().Trim('"'));
                        current.Clear();
                    }
                    else
                    {
                        current.Append(c);
                    }
                }
                parts.Add(current.ToString().Trim().Trim('"'));
                
                if (parts.Count >= 3)
                {
                    string itemClass = parts[0];
                    string properties = parts[1];
                    if (int.TryParse(parts[2], out int quantity))
                    {
                        return (itemClass, properties, quantity);
                    }
                }
                
                return null;
            }
            catch
            {
                return null;
            }
        }

        /// <summary>
        /// Remove item from inventory
        /// Format: removeitem|contentItemId|quantity|inventoryId (optional)
        /// Returns: "OK" or error
        /// </summary>
        private static string HandleRemoveItem(string[] parts)
        {
            if (_dbManager == null)
                return "Error: Database not initialized";

            if (parts.Length < 3)
                return "Error: removeitem requires at least 2 parameters: contentItemId|quantity";

            if (!int.TryParse(parts[1], out int contentItemId))
                return "Error: contentItemId must be a number";

            if (!int.TryParse(parts[2], out int quantity))
                return "Error: quantity must be a number";

            bool success = _dbManager.RemoveItem(contentItemId, quantity);
            
            // Invalidate cache if inventoryId provided
            if (success && parts.Length >= 4 && int.TryParse(parts[3], out int inventoryId))
            {
                lock (GetInventoryLock(inventoryId))
                {
                    _inventoryCache.TryRemove(inventoryId, out _);
                    _moneyCache.TryRemove(inventoryId, out _);
                    _inventoryHashCache.TryRemove(inventoryId, out _);
                }
                WriteToLog($"Cache invalidated for inventory {inventoryId} after removing item", LogLevel.Info);
            }
            
            return success ? "OK" : "Error: Failed to remove item from database";
        }

        /// <summary>
        /// Remove multiple items from inventory in a single transaction (batch operation)
        /// Format: removeitems|inventoryId|[[contentItemId,quantity,itemClass,properties],...]
        /// Returns: "OK|count|[[class,props,qty],...]" with items successfully removed, or error
        /// The returned array contains items that should be spawned in the container
        /// </summary>
        private static string HandleRemoveItems(string[] parts)
        {
            if (_dbManager == null)
                return "Error: Database not initialized";

            if (parts.Length < 3)
                return "Error: removeitems requires 2 parameters: inventoryId|itemsArray";

            if (!int.TryParse(parts[1], out int inventoryId))
                return "Error: inventoryId must be a number";

            string itemsArrayStr = parts[2];
            
            // Handle case where array might have been split by pipes within it
            if (parts.Length > 3)
            {
                itemsArrayStr = string.Join("|", parts.Skip(2));
            }

            try
            {
                // Parse the SQF array: [[contentItemId,quantity,itemClass,properties],...]
                var itemsToRemove = ParseRemoveItemsArray(itemsArrayStr);
                
                if (itemsToRemove.Count == 0)
                    return "Error: No valid items to remove";

                lock (GetInventoryLock(inventoryId))
                {
                    // Call database batch remove - returns list of successfully removed items
                    var result = _dbManager.RemoveItems(inventoryId, itemsToRemove);
                    
                    if (result.Success)
                    {
                        // Invalidate cache
                        _inventoryCache.TryRemove(inventoryId, out _);
                        _moneyCache.TryRemove(inventoryId, out _);
                        _inventoryHashCache.TryRemove(inventoryId, out _);
                        
                        // Return removed items in SQF format for spawning
                        // Format: OK|count|[[class,props,qty],...]
                        var removedItemsStr = FormatRemovedItemsForSqf(result.RemovedItems);
                        return $"OK|{result.RemovedItems.Count}|{removedItemsStr}";
                    }
                    else
                    {
                        return $"Error: {result.ErrorMessage}";
                    }
                }
            }
            catch (Exception ex)
            {
                WriteToLog($"HandleRemoveItems error: {ex.Message}", LogLevel.Error);
                return $"Error: {ex.Message}";
            }
        }

        /// <summary>
        /// Parse SQF array format for batch remove: [[contentItemId,quantity,itemClass,properties],...]
        /// </summary>
        private static List<(int ContentItemId, int Quantity, string ItemClass, string Properties)> ParseRemoveItemsArray(string arrayStr)
        {
            var result = new List<(int, int, string, string)>();
            
            arrayStr = arrayStr.Trim();
            if (!arrayStr.StartsWith("[") || !arrayStr.EndsWith("]"))
                return result;
            
            // Remove outer brackets
            arrayStr = arrayStr.Substring(1, arrayStr.Length - 2).Trim();
            if (string.IsNullOrEmpty(arrayStr))
                return result;
            
            // Parse each [contentItemId,quantity,itemClass,properties] element
            int depth = 0;
            int itemStart = -1;
            
            for (int i = 0; i < arrayStr.Length; i++)
            {
                char c = arrayStr[i];
                
                if (c == '[')
                {
                    if (depth == 0) itemStart = i;
                    depth++;
                }
                else if (c == ']')
                {
                    depth--;
                    if (depth == 0 && itemStart >= 0)
                    {
                        string itemStr = arrayStr.Substring(itemStart, i - itemStart + 1);
                        var item = ParseSingleRemoveItem(itemStr);
                        if (item.HasValue)
                        {
                            result.Add(item.Value);
                        }
                        itemStart = -1;
                    }
                }
            }
            
            return result;
        }

        /// <summary>
        /// Parse a single item: [contentItemId,quantity,itemClass,properties]
        /// </summary>
        private static (int ContentItemId, int Quantity, string ItemClass, string Properties)? ParseSingleRemoveItem(string itemStr)
        {
            try
            {
                itemStr = itemStr.Trim();
                if (!itemStr.StartsWith("[") || !itemStr.EndsWith("]"))
                    return null;
                
                itemStr = itemStr.Substring(1, itemStr.Length - 2);
                
                // Split by comma, respecting quotes
                var parts = new List<string>();
                bool inQuote = false;
                int partStart = 0;
                
                for (int i = 0; i < itemStr.Length; i++)
                {
                    char c = itemStr[i];
                    if (c == '"') inQuote = !inQuote;
                    else if (c == ',' && !inQuote)
                    {
                        parts.Add(itemStr.Substring(partStart, i - partStart).Trim());
                        partStart = i + 1;
                    }
                }
                parts.Add(itemStr.Substring(partStart).Trim());
                
                if (parts.Count < 3) return null;
                
                int contentItemId = int.Parse(parts[0]);
                int quantity = int.Parse(parts[1]);
                string itemClass = parts[2].Trim('"');
                string properties = parts.Count > 3 ? parts[3].Trim('"') : "";
                
                return (contentItemId, quantity, itemClass, properties);
            }
            catch
            {
                return null;
            }
        }

        /// <summary>
        /// Format removed items list for SQF: [[class,props,qty],...]
        /// </summary>
        private static string FormatRemovedItemsForSqf(List<(string ItemClass, string Properties, int Quantity)> items)
        {
            if (items.Count == 0) return "[]";
            
            var formatted = items.Select(i => $"[\"{i.ItemClass}\",\"{i.Properties}\",{i.Quantity}]");
            return "[" + string.Join(",", formatted) + "]";
        }

        /// <summary>
        /// Withdraw money from inventory balance
        /// Format: withdrawmoney|inventoryId|amount
        /// Returns: "OK" or error
        /// </summary>
        private static string HandleWithdrawMoney(string[] parts)
        {
            if (_dbManager == null)
                return "Error: Database not initialized";

            if (parts.Length < 3)
                return "Error: withdrawmoney requires 2 parameters: inventoryId|amount";

            if (!int.TryParse(parts[1], out int inventoryId))
                return "Error: inventoryId must be a number";

            if (!double.TryParse(parts[2], out double amount))
                return "Error: amount must be a number";

            bool success = _dbManager.WithdrawMoney(inventoryId, amount);
            
            // Invalidate money cache so next upload will refresh
            if (success)
            {
                lock (GetInventoryLock(inventoryId))
                {
                    _moneyCache.TryRemove(inventoryId, out _);
                    _inventoryHashCache.TryRemove(inventoryId, out _);
                }
                WriteToLog($"Money cache invalidated for inventory {inventoryId} after withdrawal", LogLevel.Info);
            }
            
            return success ? "OK" : "Error: Failed to withdraw money";
        }

        #endregion

        #region Change Detection & Background Refresh

        /// <summary>
        /// Queue a background refresh for an inventory - returns immediately
        /// Format: queuerefresh|inventoryId
        /// Returns: "" (empty string, non-blocking)
        /// The background task will update the cache with latest DB data
        /// </summary>
        private static string HandleQueueRefresh(string[] parts)
        {
            if (_dbManager == null)
                return ""; // Return empty, don't block SQF

            if (parts.Length < 2 || !int.TryParse(parts[1], out int inventoryId))
                return ""; // Return empty, don't block SQF

            // Atomically check and set refresh in progress
            // TryUpdate returns false if key doesn't exist or value doesn't match expected
            // AddOrUpdate with a check ensures only one refresh runs at a time
            bool alreadyRunning = false;
            _refreshInProgress.AddOrUpdate(
                inventoryId,
                addValueFactory: _ => true,  // Not running, start it
                updateValueFactory: (_, existing) =>
                {
                    if (existing)
                    {
                        alreadyRunning = true;
                        return true; // Keep it as true
                    }
                    return true; // Was false, now starting
                }
            );

            if (alreadyRunning)
            {
                WriteToLog($"Refresh already in progress for inventory {inventoryId}, skipping", LogLevel.Info);
                return ""; // Already refreshing, don't start another
            }

            // Start background task - fire and forget
            Task.Run(() =>
            {
                try
                {
                    // Query database in background
                    List<InventoryItem> items = _dbManager.GetInventoryItems(inventoryId);
                    double money = _dbManager.GetInventoryMoney(inventoryId);
                    string newHash = ComputeInventoryHash(items, money);

                    lock (GetInventoryLock(inventoryId))
                    {
                        // Store the pending hash (will be compared in hasinventorychanged)
                        _pendingHashCache[inventoryId] = newHash;
                        
                        // Also update the cache with fresh data
                        _inventoryCache[inventoryId] = items;
                        _moneyCache[inventoryId] = money;
                        _lastRefreshTime[inventoryId] = DateTime.Now;
                    }

                    WriteToLog($"Background refresh completed for inventory {inventoryId}", LogLevel.Info);
                }
                catch (Exception ex)
                {
                    WriteToLog($"Background refresh failed for inventory {inventoryId}: {ex.Message}", LogLevel.Error);
                }
                finally
                {
                    _refreshInProgress[inventoryId] = false;
                }
            });

            return ""; // Return immediately, don't block SQF
        }

        /// <summary>
        /// Check if inventory has changed since last check (non-blocking, uses cached data)
        /// Format: hasinventorychanged|inventoryId
        /// Returns: "1" if changed, "0" if not changed, "-1" if no data yet (first run)
        /// </summary>
        private static string HandleHasInventoryChanged(string[] parts)
        {
            if (_dbManager == null)
                return "Error: Database not initialized";

            if (parts.Length < 2)
                return "Error: hasinventorychanged requires 1 parameter: inventoryId";

            if (!int.TryParse(parts[1], out int inventoryId))
                return "Error: inventoryId must be a number";

            lock (GetInventoryLock(inventoryId))
            {
                // Check if we have pending hash from background refresh
                if (_pendingHashCache.TryGetValue(inventoryId, out string? pendingHash))
                {
                    // Compare with current hash
                    if (_inventoryHashCache.TryGetValue(inventoryId, out string? currentHash))
                    {
                        bool hasChanged = currentHash != pendingHash;
                        
                        if (hasChanged)
                        {
                            // Promote pending hash to current
                            _inventoryHashCache[inventoryId] = pendingHash;
                            WriteToLog($"Inventory {inventoryId} has changed (pending hash promoted)", LogLevel.Info);
                        }
                        
                        // Clear pending hash - it's been processed
                        _pendingHashCache.TryRemove(inventoryId, out _);
                        
                        return hasChanged ? "1" : "0";
                    }
                    else
                    {
                        // No current hash, this is first check - promote pending to current
                        _inventoryHashCache[inventoryId] = pendingHash;
                        _pendingHashCache.TryRemove(inventoryId, out _);
                        WriteToLog($"First check for inventory {inventoryId}, pending hash promoted", LogLevel.Info);
                        return "1"; // Consider it changed on first check
                    }
                }
                else
                {
                    // No pending hash - either first run or background refresh hasn't completed
                    if (_inventoryHashCache.ContainsKey(inventoryId))
                    {
                        // We have a current hash but no pending - means no refresh happened yet
                        // or refresh is still in progress. Return 0 (no change detected yet)
                        return "0";
                    }
                    else
                    {
                        // First ever run, no data at all - do a synchronous load to initialize
                        WriteToLog($"First run for inventory {inventoryId}, doing synchronous init", LogLevel.Info);
                        List<InventoryItem> items = _dbManager.GetInventoryItems(inventoryId);
                        double money = _dbManager.GetInventoryMoney(inventoryId);
                        string hash = ComputeInventoryHash(items, money);
                        
                        _inventoryCache[inventoryId] = items;
                        _moneyCache[inventoryId] = money;
                        _inventoryHashCache[inventoryId] = hash;
                        _lastRefreshTime[inventoryId] = DateTime.Now;
                        
                        return "1"; // First load, consider it changed
                    }
                }
            }
        }

        /// <summary>
        /// Compute a simple hash of inventory state for change detection
        /// </summary>
        private static string ComputeInventoryHash(List<InventoryItem> items, double money)
        {
            var sb = new StringBuilder();
            sb.Append(money.ToString("F2"));
            sb.Append("|");
            
            foreach (var item in items.OrderBy(i => i.ContentItemId))
            {
                sb.Append($"{item.ContentItemId}:{item.ItemClass}:{item.Quantity}:{item.Properties};");
            }
            
            // Simple hash using string hash code
            return sb.ToString().GetHashCode().ToString();
        }

        #endregion

        #region Logging

        private static void ResetLogs()
        {
            try
            {
                string logPath = Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "PIMS_logs.txt");
                File.WriteAllText(logPath, $"=== PIMS Extension Log Started: {DateTime.Now} ===\n");
                
                string errorLogPath = Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "PIMS_logs_Error.txt");
                File.WriteAllText(errorLogPath, $"=== PIMS Extension Error Log Started: {DateTime.Now} ===\n");
            }
            catch { /* Ignore logging errors */ }
        }

        public static void WriteToLog(string message, LogLevel level = LogLevel.Info)
        {
            try
            {
                string timestamp = $"[{DateTime.Now:yyyy-MM-dd HH:mm:ss}]";
                string levelPrefix = level switch
                {
                    LogLevel.Warning => "WARNING",
                    LogLevel.Error => "ERROR",
                    _ => "INFO"
                };
                string formattedMessage = $"{timestamp} [{levelPrefix}] {message}\n";

                // Write to main log
                string logPath = Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "PIMS_logs.txt");
                FileInfo logFileInfo = new FileInfo(logPath);
                if (logFileInfo.Exists && logFileInfo.Length > 20 * 1024 * 1024) // 20MB
                {
                    string[] lines = File.ReadAllLines(logPath);
                    int halfIndex = lines.Length / 2;
                    File.WriteAllLines(logPath, lines.Skip(halfIndex));
                }
                File.AppendAllText(logPath, formattedMessage);

                // Write to error log if warning or error
                if (level == LogLevel.Warning || level == LogLevel.Error)
                {
                    string errorLogPath = Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "PIMS_logs_Error.txt");
                    FileInfo errorLogFileInfo = new FileInfo(errorLogPath);
                    if (errorLogFileInfo.Exists && errorLogFileInfo.Length > 20 * 1024 * 1024) // 20MB
                    {
                        string[] errorLines = File.ReadAllLines(errorLogPath);
                        int errorHalfIndex = errorLines.Length / 2;
                        File.WriteAllLines(errorLogPath, errorLines.Skip(errorHalfIndex));
                    }
                    File.AppendAllText(errorLogPath, formattedMessage);
                }
            }
            catch { /* Ignore logging errors */ }
        }

        #endregion
    }
}
