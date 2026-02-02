namespace PIMSExt.Models
{
    /// <summary>
    /// Represents an item in an inventory
    /// </summary>
    public class InventoryItem
    {
        public int ContentItemId { get; set; }
        public int InventoryId { get; set; }
        public string ItemClass { get; set; } = "";
        public string Properties { get; set; } = "";
        public int Quantity { get; set; }
    }

    /// <summary>
    /// Represents an inventory
    /// </summary>
    public class Inventory
    {
        public int InventoryId { get; set; }
        public string InventoryName { get; set; } = "";
    }

    /// <summary>
    /// Represents player permission for an inventory
    /// </summary>
    public class Permission
    {
        public int PermissionId { get; set; }
        public int InventoryId { get; set; }
        public string PlayerId { get; set; } = "";
    }

    /// <summary>
    /// Represents an admin user
    /// </summary>
    public class Admin
    {
        public int AdminId { get; set; }
        public string PlayerId { get; set; } = "";
    }

    /// <summary>
    /// Money denomination types
    /// </summary>
    public static class MoneyTypes
    {
        public const string Credits1 = "PIMS_Money_1";
        public const string Credits10 = "PIMS_Money_10";
        public const string Credits50 = "PIMS_Money_50";
        public const string Credits100 = "PIMS_Money_100";
        public const string Credits500 = "PIMS_Money_500";
        public const string Credits1000 = "PIMS_Money_1000";

        public static readonly Dictionary<string, int> MoneyValues = new()
        {
            { Credits1, 1 },
            { Credits10, 10 },
            { Credits50, 50 },
            { Credits100, 100 },
            { Credits500, 500 },
            { Credits1000, 1000 }
        };

        public static bool IsMoneyItem(string itemClass)
        {
            return MoneyValues.ContainsKey(itemClass);
        }

        public static int GetMoneyValue(string itemClass)
        {
            return MoneyValues.TryGetValue(itemClass, out int value) ? value : 0;
        }
    }

    /// <summary>
    /// Result of batch remove operation
    /// </summary>
    public class RemoveItemsResult
    {
        public bool Success { get; set; }
        public string ErrorMessage { get; set; } = "";
        public List<(string ItemClass, string Properties, int Quantity)> RemovedItems { get; set; } = new();
        public List<(string ItemClass, string ErrorReason)> FailedItems { get; set; } = new();
    }
}
