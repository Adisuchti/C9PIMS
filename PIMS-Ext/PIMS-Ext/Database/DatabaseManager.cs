using MySqlConnector;
using PIMSExt.Models;

namespace PIMSExt.Database
{
    /// <summary>
    /// Handles all database operations for PIMS
    /// Replaces extDB3 calls from SQF with direct MySQL connections
    /// Uses connection pooling for optimal performance (enabled by default in MySqlConnector)
    /// </summary>
    public class DatabaseManager
    {
        private readonly string _connectionString;

        public DatabaseManager(string server, string database, string user, string password, int port = 3306)
        {
            // Connection pooling is enabled by default in MySqlConnector
            // Pooling=true is default, but we set it explicitly for clarity
            // MinPoolSize=0, MaxPoolSize=100 are defaults, ConnectionIdleTimeout=180 seconds
            _connectionString = $"Server={server};Database={database};Uid={user};Pwd={password};Port={port};SslMode=None;AllowPublicKeyRetrieval=True;Pooling=true;MinPoolSize=2;MaxPoolSize=50;ConnectionIdleTimeout=300;";
        }

        public bool TestConnection(out string errorMessage)
        {
            try
            {
                using var connection = new MySqlConnection(_connectionString);
                connection.Open();
                errorMessage = "";
                return true;
            }
            catch (Exception ex)
            {
                // Build detailed error message including inner exceptions
                var sb = new System.Text.StringBuilder();
                sb.AppendLine($"Error: {ex.Message}");
                
                var innerEx = ex.InnerException;
                int depth = 1;
                while (innerEx != null && depth < 5)
                {
                    sb.AppendLine($"Inner Exception {depth}: {innerEx.Message}");
                    innerEx = innerEx.InnerException;
                    depth++;
                }
                
                errorMessage = sb.ToString();
                ArmaEntry.WriteToLog($"Database connection error: {errorMessage}\nStack trace: {ex.StackTrace}", LogLevel.Error);
                return false;
            }
        }

        #region Permissions

        /// <summary>
        /// Check if player has permission to access inventory
        /// </summary>
        public bool CheckPermission(int inventoryId, string playerUid)
        {
            try
            {
                using var connection = new MySqlConnection(_connectionString);
                connection.Open();

                string query = "SELECT COUNT(*) FROM `permissions` WHERE `Inventory_Id` = @inventoryId AND `Player_Id` = @playerUid";
                using var command = new MySqlCommand(query, connection);
                command.Parameters.AddWithValue("@inventoryId", inventoryId);
                command.Parameters.AddWithValue("@playerUid", playerUid);

                long count = (long)(command.ExecuteScalar() ?? 0);
                return count > 0;
            }
            catch (Exception ex)
            {
                ArmaEntry.WriteToLog($"Database permission check error: {ex.Message}\nStack trace: {ex.StackTrace}", LogLevel.Error);
                return false;
            }
        }

        /// <summary>
        /// Check if player is admin
        /// </summary>
        public bool IsAdmin(string playerUid)
        {
            try
            {
                using var connection = new MySqlConnection(_connectionString);
                connection.Open();

                string query = "SELECT COUNT(*) FROM `admins` WHERE `PlayerId` = @playerUid";
                using var command = new MySqlCommand(query, connection);
                command.Parameters.AddWithValue("@playerUid", playerUid);

                long count = (long)(command.ExecuteScalar() ?? 0);
                return count > 0;
            }
            catch (Exception ex)
            {
                ArmaEntry.WriteToLog($"Database admin check error: {ex.Message}\nStack trace: {ex.StackTrace}", LogLevel.Error);
                return false;
            }
        }

        #endregion

        #region Inventory Management

        /// <summary>
        /// Get inventory name by ID
        /// </summary>
        public string? GetInventoryName(int inventoryId)
        {
            try
            {
                using var connection = new MySqlConnection(_connectionString);
                connection.Open();

                string query = "SELECT `inventory_name` FROM `inventories` WHERE `inventory_id` = @inventoryId";
                using var command = new MySqlCommand(query, connection);
                command.Parameters.AddWithValue("@inventoryId", inventoryId);

                return command.ExecuteScalar() as string;
            }
            catch (Exception ex)
            {
                ArmaEntry.WriteToLog($"Database get inventory name error: {ex.Message}\nStack trace: {ex.StackTrace}", LogLevel.Error);
                return null;
            }
        }

        /// <summary>
        /// Get all inventories (id + name) from database
        /// </summary>
        public List<(int Id, string Name)> GetAllInventories()
        {
            var result = new List<(int Id, string Name)>();
            try
            {
                using var connection = new MySqlConnection(_connectionString);
                connection.Open();

                string query = "SELECT `inventory_id`, `inventory_name` FROM `inventories` ORDER BY `inventory_id`";
                using var command = new MySqlCommand(query, connection);
                using var reader = command.ExecuteReader();

                while (reader.Read())
                {
                    int id = reader.GetInt32(0);
                    string name = reader.GetString(1);
                    result.Add((id, name));
                }
            }
            catch (Exception ex)
            {
                ArmaEntry.WriteToLog($"Database get all inventories error: {ex.Message}\nStack trace: {ex.StackTrace}", LogLevel.Error);
            }
            return result;
        }

        /// <summary>
        /// Get inventory money by ID
        /// </summary>
        public double GetInventoryMoney(int inventoryId)
        {
            try
            {
                using var connection = new MySqlConnection(_connectionString);
                connection.Open();

                string query = "SELECT `inventory_money` FROM `inventories` WHERE `inventory_id` = @inventoryId";
                using var command = new MySqlCommand(query, connection);
                command.Parameters.AddWithValue("@inventoryId", inventoryId);

                object? result = command.ExecuteScalar();
                if (result != null && double.TryParse(result.ToString(), out double money))
                {
                    return money;
                }
                return 0.0;
            }
            catch (Exception ex)
            {
                ArmaEntry.WriteToLog($"Database get inventory money error: {ex.Message}\nStack trace: {ex.StackTrace}", LogLevel.Error);
                return 0.0;
            }
        }

        /// <summary>
        /// Withdraw money from inventory balance (atomic operation)
        /// </summary>
        public bool WithdrawMoney(int inventoryId, double amount)
        {
            try
            {
                using var connection = new MySqlConnection(_connectionString);
                connection.Open();

                // Atomic update - only deduct if sufficient funds (prevents TOCTOU race condition)
                string query = "UPDATE `inventories` SET `Inventory_Money` = `Inventory_Money` - @amount " +
                               "WHERE `Inventory_Id` = @inventoryId AND `Inventory_Money` >= @amount";
                using var command = new MySqlCommand(query, connection);
                command.Parameters.AddWithValue("@amount", amount);
                command.Parameters.AddWithValue("@inventoryId", inventoryId);
                int rowsAffected = command.ExecuteNonQuery();
                
                if (rowsAffected == 0)
                {
                    ArmaEntry.WriteToLog($"Insufficient funds for withdrawal of {amount} from inventory {inventoryId}", LogLevel.Warning);
                    return false;
                }

                string logQuery = "INSERT INTO `logs` (`Transaction_Item`, `Transaction_Quantity`, `Transaction_Inventory_Id`, `isMarketActivity`) " +
                                  "VALUES ('MONEY', -@amount, @inventoryId, 0)";
                using var logCommand = new MySqlCommand(logQuery, connection);
                logCommand.Parameters.AddWithValue("@amount", amount);
                logCommand.Parameters.AddWithValue("@inventoryId", inventoryId);
                logCommand.ExecuteNonQuery();

                return true;
            }
            catch (Exception ex)
            {
                ArmaEntry.WriteToLog($"Database withdraw money error: {ex.Message}\nStack trace: {ex.StackTrace}", LogLevel.Error);
                return false;
            }
        }

        /// <summary>
        /// Get all items from an inventory
        /// </summary>
        public List<InventoryItem> GetInventoryItems(int inventoryId)
        {
            var items = new List<InventoryItem>();

            try
            {
                using var connection = new MySqlConnection(_connectionString);
                connection.Open();
                ArmaEntry.WriteToLog($"Database connection opened for inventory {inventoryId}", LogLevel.Info);

                // First, check total row count in table
                string countQuery = "SELECT COUNT(*) FROM `content_items`";
                using var countCmd = new MySqlCommand(countQuery, connection);
                long totalRows = (long)(countCmd.ExecuteScalar() ?? 0);
                ArmaEntry.WriteToLog($"Total rows in content_items table: {totalRows}", LogLevel.Info);

                // If table has rows, use correct column names from schema
                string query = "SELECT content_items.Content_Item_Id, content_items.Inventory_Id, " +
                    "content_items.Item_Class, content_items.Item_Quantity, content_items.Item_Properties, item_types.item_classification " +
                    "FROM content_items " +
                    "LEFT JOIN items ON items.item_class COLLATE utf8mb4_general_ci = content_items.Item_Class COLLATE utf8mb4_general_ci " +
                    "LEFT JOIN item_types ON item_types.Item_Type_Id = items.Item_Type " +
                    "LEFT JOIN item_sorting ON item_sorting.Item_Sorting_Type COLLATE utf8mb4_general_ci = item_types.item_classification COLLATE utf8mb4_general_ci " +
                    "WHERE Inventory_Id = @inventoryId ORDER BY item_sorting.Item_Sorting_Number, (content_items.Item_Class IS NULL), content_items.Item_Properties";
                using var command = new MySqlCommand(query, connection);
                command.Parameters.AddWithValue("@inventoryId", inventoryId);

                ArmaEntry.WriteToLog($"Executing query: {query} with inventoryId={inventoryId}", LogLevel.Info);
                using var reader = command.ExecuteReader();
                int rowCount = 0;
                while (reader.Read())
                {
                    rowCount++;
                    items.Add(new InventoryItem
                    {
                        ContentItemId = reader.GetInt32(0),
                        InventoryId = reader.GetInt32(1),
                        ItemClass = reader.GetString(2),
                        Quantity = reader.GetInt32(3),
                        Properties = reader.IsDBNull(4) ? "" : reader.GetString(4),
                    });
                }
                ArmaEntry.WriteToLog($"Retrieved {rowCount} items from inventory {inventoryId}.", LogLevel.Info);
                reader.Close();
            }
            catch (Exception ex)
            {
                ArmaEntry.WriteToLog($"Database get inventory items error: {ex.Message}\nStack trace: {ex.StackTrace}", LogLevel.Error);
            }

            return items;
        }

        /// <summary>
        /// Add item to inventory
        /// </summary>
        public bool AddItem(int inventoryId, string itemClass, string properties, int quantity)
        {
            try
            {
                using var connection = new MySqlConnection(_connectionString);
                connection.Open();

                // Check if item is money - if so, add to inventory balance instead of content_items
                int moneyValue = itemClass switch
                {
                    "PIMS_Money_1" => 1,
                    "PIMS_Money_10" => 10,
                    "PIMS_Money_50" => 50,
                    "PIMS_Money_100" => 100,
                    "PIMS_Money_500" => 500,
                    "PIMS_Money_1000" => 1000,
                    _ => 0
                };

                if (moneyValue > 0)
                {
                    // This is money - add to inventory balance
                    double totalValue = moneyValue * quantity;
                    string moneyQuery = "UPDATE `inventories` SET `Inventory_Money` = `Inventory_Money` + @amount WHERE `Inventory_Id` = @inventoryId";
                    using var moneyCommand = new MySqlCommand(moneyQuery, connection);
                    moneyCommand.Parameters.AddWithValue("@amount", totalValue);
                    moneyCommand.Parameters.AddWithValue("@inventoryId", inventoryId);
                    moneyCommand.ExecuteNonQuery();
                    
                    ArmaEntry.WriteToLog($"Added {totalValue} credits to inventory {inventoryId}", LogLevel.Info);

                    string moneyLogQuery = "INSERT INTO `logs` (`Transaction_Item`, `Transaction_Quantity`, `Transaction_Inventory_Id`, `isMarketActivity`) " +
                                      "VALUES ('MONEY', @amount, @inventoryId, 0)";
                    using var logMoneyCommand = new MySqlCommand(moneyLogQuery, connection);
                    logMoneyCommand.Parameters.AddWithValue("@amount", totalValue);
                    logMoneyCommand.Parameters.AddWithValue("@inventoryId", inventoryId);
                    logMoneyCommand.ExecuteNonQuery();
                    
                    return true;
                }

                // Check if item already exists with same properties - use INSERT ... ON DUPLICATE KEY UPDATE for atomicity
                // This prevents race conditions where two uploads of same item could both read quantity=5 and both write 10
                // Note: Requires UNIQUE index on (Inventory_Id, Item_Class, Item_Properties)
                
                // First try INSERT, if it fails due to duplicate, update instead
                string upsertQuery = "INSERT INTO `content_items` (`Inventory_Id`, `Item_Class`, `Item_Properties`, `Item_Quantity`) " +
                                    "VALUES (@inventoryId, @itemClass, @properties, @quantity) " +
                                    "ON DUPLICATE KEY UPDATE `Item_Quantity` = `Item_Quantity` + @quantity";
                
                using var upsertCommand = new MySqlCommand(upsertQuery, connection);
                upsertCommand.Parameters.AddWithValue("@inventoryId", inventoryId);
                upsertCommand.Parameters.AddWithValue("@itemClass", itemClass);
                upsertCommand.Parameters.AddWithValue("@properties", properties);
                upsertCommand.Parameters.AddWithValue("@quantity", quantity);
                upsertCommand.ExecuteNonQuery();

                string logQuery = "INSERT INTO `logs` (`Transaction_Item`, `Transaction_Quantity`, `Transaction_Inventory_Id`, `isMarketActivity`) " +
                                  "VALUES (@itemClass, @quantity, @inventoryId, 0)";
                using var logCommand = new MySqlCommand(logQuery, connection);
                logCommand.Parameters.AddWithValue("@itemClass", itemClass);
                logCommand.Parameters.AddWithValue("@quantity", quantity);
                logCommand.Parameters.AddWithValue("@inventoryId", inventoryId);
                logCommand.ExecuteNonQuery();

                return true;
            }
            catch (Exception ex)
            {
                ArmaEntry.WriteToLog($"Database add item error: {ex.Message}\nStack trace: {ex.StackTrace}", LogLevel.Error);
                return false;
            }
        }

        /// <summary>
        /// Add multiple items to inventory in a single transaction (batch operation)
        /// Returns the number of successfully added items
        /// </summary>
        public int AddItems(int inventoryId, List<(string itemClass, string properties, int quantity)> items)
        {
            if (items == null || items.Count == 0)
                return 0;

            int successCount = 0;
            double totalMoneyAdded = 0;

            try
            {
                using var connection = new MySqlConnection(_connectionString);
                connection.Open();
                
                using var transaction = connection.BeginTransaction();
                
                try
                {
                    // Prepare the upsert command (reuse for all items)
                    string upsertQuery = "INSERT INTO `content_items` (`Inventory_Id`, `Item_Class`, `Item_Properties`, `Item_Quantity`) " +
                                        "VALUES (@inventoryId, @itemClass, @properties, @quantity) " +
                                        "ON DUPLICATE KEY UPDATE `Item_Quantity` = `Item_Quantity` + @quantity";
                    
                    // Prepare the log command for individual item logging
                    string logQuery = "INSERT INTO `logs` (`Transaction_Item`, `Transaction_Quantity`, `Transaction_Inventory_Id`, `isMarketActivity`) " +
                                     "VALUES (@itemClass, @quantity, @inventoryId, 0)";
                    
                    // Process all items
                    foreach (var (itemClass, properties, quantity) in items)
                    {
                        // Check if item is money
                        int moneyValue = itemClass switch
                        {
                            "PIMS_Money_1" => 1,
                            "PIMS_Money_10" => 10,
                            "PIMS_Money_50" => 50,
                            "PIMS_Money_100" => 100,
                            "PIMS_Money_500" => 500,
                            "PIMS_Money_1000" => 1000,
                            _ => 0
                        };

                        if (moneyValue > 0)
                        {
                            // Accumulate money for a single update at the end
                            totalMoneyAdded += moneyValue * quantity;
                            successCount++;
                        }
                        else
                        {
                            // Regular item - upsert
                            using var upsertCommand = new MySqlCommand(upsertQuery, connection, transaction);
                            upsertCommand.Parameters.AddWithValue("@inventoryId", inventoryId);
                            upsertCommand.Parameters.AddWithValue("@itemClass", itemClass);
                            upsertCommand.Parameters.AddWithValue("@properties", properties);
                            upsertCommand.Parameters.AddWithValue("@quantity", quantity);
                            upsertCommand.ExecuteNonQuery();
                            
                            // Log each item individually
                            using var logCommand = new MySqlCommand(logQuery, connection, transaction);
                            logCommand.Parameters.AddWithValue("@itemClass", itemClass);
                            logCommand.Parameters.AddWithValue("@quantity", quantity);
                            logCommand.Parameters.AddWithValue("@inventoryId", inventoryId);
                            logCommand.ExecuteNonQuery();
                            
                            successCount++;
                        }
                    }

                    // Add accumulated money in a single update
                    if (totalMoneyAdded > 0)
                    {
                        string moneyQuery = "UPDATE `inventories` SET `Inventory_Money` = `Inventory_Money` + @amount WHERE `Inventory_Id` = @inventoryId";
                        using var moneyCommand = new MySqlCommand(moneyQuery, connection, transaction);
                        moneyCommand.Parameters.AddWithValue("@amount", totalMoneyAdded);
                        moneyCommand.Parameters.AddWithValue("@inventoryId", inventoryId);
                        moneyCommand.ExecuteNonQuery();
                        
                        // Log money addition
                        string moneyLogQuery = "INSERT INTO `logs` (`Transaction_Item`, `Transaction_Quantity`, `Transaction_Inventory_Id`, `isMarketActivity`) " +
                                          "VALUES ('MONEY', @amount, @inventoryId, 0)";
                        using var logMoneyCommand = new MySqlCommand(moneyLogQuery, connection, transaction);
                        logMoneyCommand.Parameters.AddWithValue("@amount", totalMoneyAdded);
                        logMoneyCommand.Parameters.AddWithValue("@inventoryId", inventoryId);
                        logMoneyCommand.ExecuteNonQuery();
                        
                        ArmaEntry.WriteToLog($"Batch added {totalMoneyAdded} credits to inventory {inventoryId}", LogLevel.Info);
                    }

                    transaction.Commit();
                    ArmaEntry.WriteToLog($"Batch added {successCount} items to inventory {inventoryId}", LogLevel.Info);
                    return successCount;
                }
                catch (Exception ex)
                {
                    transaction.Rollback();
                    ArmaEntry.WriteToLog($"Batch add items failed, rolled back: {ex.Message}", LogLevel.Error);
                    throw;
                }
            }
            catch (Exception ex)
            {
                ArmaEntry.WriteToLog($"Database batch add items error: {ex.Message}\nStack trace: {ex.StackTrace}", LogLevel.Error);
                return 0;
            }
        }

        /// <summary>
        /// Remove or decrement item quantity (uses transaction for atomicity)
        /// </summary>
        public bool RemoveItem(int contentItemId, int quantity)
        {
            try
            {
                using var connection = new MySqlConnection(_connectionString);
                connection.Open();
                
                // Use transaction to ensure atomicity
                using var transaction = connection.BeginTransaction();
                
                try
                {
                    // Get current quantity - single query, no double read
                    string checkQuery = "SELECT `Item_Quantity`, `Item_Class`, `Inventory_Id` FROM `content_items` WHERE `Content_Item_Id` = @contentItemId FOR UPDATE";
                    using var checkCommand = new MySqlCommand(checkQuery, connection, transaction);
                    checkCommand.Parameters.AddWithValue("@contentItemId", contentItemId);

                    using var reader = checkCommand.ExecuteReader();
                    if (!reader.Read())
                    {
                        reader.Close();
                        transaction.Rollback();
                        return false;
                    }
                    
                    int currentQuantity = reader.GetInt32(0);
                    string itemClass = reader.GetString(1);
                    int inventoryId = reader.GetInt32(2);
                    reader.Close();
                    
                    // Validate we have enough quantity
                    if (currentQuantity < quantity)
                    {
                        ArmaEntry.WriteToLog($"Insufficient quantity: have {currentQuantity}, requested {quantity}", LogLevel.Warning);
                        transaction.Rollback();
                        return false;
                    }

                    if (currentQuantity <= quantity)
                    {
                        // Delete item entirely
                        string deleteQuery = "DELETE FROM `content_items` WHERE `Content_Item_Id` = @contentItemId";
                        using var deleteCommand = new MySqlCommand(deleteQuery, connection, transaction);
                        deleteCommand.Parameters.AddWithValue("@contentItemId", contentItemId);
                        deleteCommand.ExecuteNonQuery();
                    }
                    else
                    {
                        // Decrement quantity atomically
                        string updateQuery = "UPDATE `content_items` SET `Item_Quantity` = `Item_Quantity` - @quantity " +
                                            "WHERE `Content_Item_Id` = @contentItemId AND `Item_Quantity` >= @quantity";
                        using var updateCommand = new MySqlCommand(updateQuery, connection, transaction);
                        updateCommand.Parameters.AddWithValue("@quantity", quantity);
                        updateCommand.Parameters.AddWithValue("@contentItemId", contentItemId);
                        int rowsAffected = updateCommand.ExecuteNonQuery();
                        
                        if (rowsAffected == 0)
                        {
                            transaction.Rollback();
                            return false;
                        }
                    }

                    string logQuery = "INSERT INTO `logs` (`Transaction_Item`, `Transaction_Quantity`, `Transaction_Inventory_Id`, `isMarketActivity`) " +
                                      "VALUES (@itemClass, @quantity, @inventoryId, 0)";
                    using var logCommand = new MySqlCommand(logQuery, connection, transaction);
                    logCommand.Parameters.AddWithValue("@itemClass", itemClass);
                    logCommand.Parameters.AddWithValue("@quantity", -quantity); // Negative for removal
                    logCommand.Parameters.AddWithValue("@inventoryId", inventoryId);
                    logCommand.ExecuteNonQuery();
                    
                    transaction.Commit();
                    return true;
                }
                catch (Exception ex)
                {
                    transaction.Rollback();
                    throw;
                }
            }
            catch (Exception ex)
            {
                ArmaEntry.WriteToLog($"Database remove item error: {ex.Message}\nStack trace: {ex.StackTrace}", LogLevel.Error);
                return false;
            }
        }

        /// <summary>
        /// Batch remove multiple items in a single transaction (atomic operation)
        /// Returns result with list of successfully removed items for spawning
        /// </summary>
        public RemoveItemsResult RemoveItems(int inventoryId, List<(int ContentItemId, int Quantity, string ItemClass, string Properties)> items)
        {
            var result = new RemoveItemsResult();
            
            try
            {
                using var connection = new MySqlConnection(_connectionString);
                connection.Open();
                
                using var transaction = connection.BeginTransaction();
                
                try
                {
                    foreach (var item in items)
                    {
                        // Get current quantity with row lock
                        string checkQuery = "SELECT `Item_Quantity` FROM `content_items` " +
                                          "WHERE `Content_Item_Id` = @contentItemId AND `Inventory_Id` = @inventoryId FOR UPDATE";
                        using var checkCommand = new MySqlCommand(checkQuery, connection, transaction);
                        checkCommand.Parameters.AddWithValue("@contentItemId", item.ContentItemId);
                        checkCommand.Parameters.AddWithValue("@inventoryId", inventoryId);
                        
                        object? quantityResult = checkCommand.ExecuteScalar();
                        if (quantityResult == null)
                        {
                            result.FailedItems.Add((item.ItemClass, $"Item not found: {item.ContentItemId}"));
                            continue;
                        }
                        
                        int currentQuantity = Convert.ToInt32(quantityResult);
                        int removeQuantity = Math.Min(item.Quantity, currentQuantity);
                        
                        if (removeQuantity <= 0)
                        {
                            result.FailedItems.Add((item.ItemClass, "Insufficient quantity"));
                            continue;
                        }
                        
                        if (currentQuantity <= item.Quantity)
                        {
                            // Delete entire row
                            string deleteQuery = "DELETE FROM `content_items` WHERE `Content_Item_Id` = @contentItemId";
                            using var deleteCommand = new MySqlCommand(deleteQuery, connection, transaction);
                            deleteCommand.Parameters.AddWithValue("@contentItemId", item.ContentItemId);
                            deleteCommand.ExecuteNonQuery();
                        }
                        else
                        {
                            // Decrement quantity
                            string updateQuery = "UPDATE `content_items` SET `Item_Quantity` = `Item_Quantity` - @quantity " +
                                                "WHERE `Content_Item_Id` = @contentItemId";
                            using var updateCommand = new MySqlCommand(updateQuery, connection, transaction);
                            updateCommand.Parameters.AddWithValue("@quantity", removeQuantity);
                            updateCommand.Parameters.AddWithValue("@contentItemId", item.ContentItemId);
                            updateCommand.ExecuteNonQuery();
                        }
                        
                        // Log the removal
                        string logQuery = "INSERT INTO `logs` (`Transaction_Item`, `Transaction_Quantity`, `Transaction_Inventory_Id`, `isMarketActivity`) " +
                                         "VALUES (@itemClass, @quantity, @inventoryId, 0)";
                        using var logCommand = new MySqlCommand(logQuery, connection, transaction);
                        logCommand.Parameters.AddWithValue("@itemClass", item.ItemClass);
                        logCommand.Parameters.AddWithValue("@quantity", -removeQuantity);
                        logCommand.Parameters.AddWithValue("@inventoryId", inventoryId);
                        logCommand.ExecuteNonQuery();
                        
                        // Add to successfully removed list
                        result.RemovedItems.Add((item.ItemClass, item.Properties, removeQuantity));
                    }
                    
                    transaction.Commit();
                    result.Success = true;
                    return result;
                }
                catch (Exception ex)
                {
                    transaction.Rollback();
                    result.Success = false;
                    result.ErrorMessage = ex.Message;
                    return result;
                }
            }
            catch (Exception ex)
            {
                ArmaEntry.WriteToLog($"Database batch remove error: {ex.Message}\nStack trace: {ex.StackTrace}", LogLevel.Error);
                result.Success = false;
                result.ErrorMessage = ex.Message;
                return result;
            }
        }

        #endregion
    }
}
