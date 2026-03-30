using System;
using System.Collections.Generic;
using System.IO;
using System.Text;

namespace PIMSExt
{
    /// <summary>
    /// Reads $PBOPREFIX$ / prefix properties from PBO file headers.
    /// Used to map addon prefixes (from allAddonsInfo) to physical PBO files on disk,
    /// so the DLL can independently hash PBO files for unsigned addons.
    ///
    /// PBO binary format:
    ///  1. Entry records (filename\0, method:u32, origSize:u32, reserved:u32, timestamp:u32, dataSize:u32)
    ///  2. First entry with method=0x56657273 ("Vers") marks a product/properties entry
    ///  3. After Vers entry: null-terminated key=value pairs until empty key
    ///  4. Empty entry (filename="" + all u32 zeros) ends the header
    ///  5. File data follows
    /// </summary>
    public static class PboReader
    {
        private const uint VERS_METHOD = 0x56657273; // "Vers" as little-endian uint32

        /// <summary>
        /// Read the prefix property from a PBO file header.
        /// Looks for keys: "prefix", "$PBOPREFIX$" (case-insensitive).
        /// Returns null if not found or on read error.
        /// </summary>
        public static string? ReadPrefix(string pboPath)
        {
            try
            {
                using var fs = new FileStream(pboPath, FileMode.Open, FileAccess.Read, FileShare.Read);
                using var reader = new BinaryReader(fs, Encoding.ASCII);

                // Read first entry filename
                string firstFilename = ReadNullTerminatedString(reader);
                uint method = reader.ReadUInt32();

                if (method == VERS_METHOD)
                {
                    // Skip remaining header fields: origSize, reserved, timestamp, dataSize
                    reader.ReadUInt32();
                    reader.ReadUInt32();
                    reader.ReadUInt32();
                    reader.ReadUInt32();

                    // Read properties (key\0 value\0 pairs, terminated by empty key)
                    while (true)
                    {
                        string key = ReadNullTerminatedString(reader);
                        if (string.IsNullOrEmpty(key))
                            break;

                        string value = ReadNullTerminatedString(reader);

                        if (key.Equals("prefix", StringComparison.OrdinalIgnoreCase) ||
                            key.Equals("$PBOPREFIX$", StringComparison.OrdinalIgnoreCase))
                        {
                            return value;
                        }
                    }
                }

                // No prefix property found — fall back to filename without extension
                // as some older PBOs don't have a prefix entry
                return null;
            }
            catch
            {
                // Silently skip unreadable files
                return null;
            }
        }

        /// <summary>
        /// Scan directories for PBO files and build a mapping from
        /// normalized addon prefix to PBO file path.
        /// Searches both the given directories directly (if they have an Addons folder)
        /// and their subdirectories (assuming they contain @Mod folders).
        /// </summary>
        public static Dictionary<string, string> BuildPrefixMap(IEnumerable<string> searchDirectories)
        {
            var map = new Dictionary<string, string>(StringComparer.OrdinalIgnoreCase);

            foreach (string baseDir in searchDirectories)
            {
                if (!Directory.Exists(baseDir))
                    continue;

                try
                {
                    // 1. Check if the directory itself is a mod folder (has an "addons" subdirectory)
                    string directAddons = Path.Combine(baseDir, "addons");
                    if (Directory.Exists(directAddons))
                    {
                        ScanAddonsDir(directAddons, map);
                    }
                    else
                    {
                        string directAddonsUpper = Path.Combine(baseDir, "Addons");
                        if (Directory.Exists(directAddonsUpper))
                        {
                            ScanAddonsDir(directAddonsUpper, map);
                        }
                    }

                    // 2. Treat the directory as a base directory containing many @Mod folders
                    foreach (string modDir in Directory.GetDirectories(baseDir))
                    {
                        string addonsDir = Path.Combine(modDir, "addons");
                        if (!Directory.Exists(addonsDir))
                        {
                            addonsDir = Path.Combine(modDir, "Addons");
                            if (!Directory.Exists(addonsDir))
                                continue;
                        }

                        ScanAddonsDir(addonsDir, map);
                    }
                }
                catch (Exception ex)
                {
                    ArmaEntry.WriteToLog($"PboReader.BuildPrefixMap error scanning {baseDir}: {ex.Message}", LogLevel.Warning);
                }
            }

            return map;
        }

        private static void ScanAddonsDir(string addonsDir, Dictionary<string, string> map)
        {
            try
            {
                foreach (string pboFile in Directory.GetFiles(addonsDir, "*.pbo"))
                {
                    string? prefix = ReadPrefix(pboFile);
                    if (prefix != null)
                    {
                        string normalized = NormalizePrefix(prefix);
                        map.TryAdd(normalized, pboFile);
                    }
                }
            }
            catch
            {
                // Silently skip unreadable directories
            }
        }

        /// <summary>
        /// Normalize a prefix for comparison:
        /// - Convert forward slashes to backslashes
        /// - Lowercase
        /// - Remove trailing backslash
        /// </summary>
        public static string NormalizePrefix(string prefix)
        {
            string normalized = prefix.Replace('/', '\\').ToLowerInvariant().TrimEnd('\\');
            return normalized;
        }

        /// <summary>
        /// Read a null-terminated ASCII string from a binary reader.
        /// </summary>
        private static string ReadNullTerminatedString(BinaryReader reader)
        {
            var sb = new StringBuilder();
            while (true)
            {
                byte b = reader.ReadByte();
                if (b == 0)
                    break;
                sb.Append((char)b);
            }
            return sb.ToString();
        }
    }
}
