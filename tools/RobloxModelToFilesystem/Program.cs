/*
 * RobloxModelToFilesystem — Converts a Roblox .rbxm model to the tool source filesystem layout.
 *
 * Design:
 * - Treats Folders as structural containers (directories)
 * - Script type is inferred from instance class (Script / LocalScript / ModuleScript)
 * - Handles script source extraction
 * - Preserves special script types (server/init.luau, client/init.luau, etc.)
 * - Ignores or handles non-script instances appropriately (metadata or explicit rules)
 */

using System;
using System.Collections.Generic;
using System.IO;
using RobloxFiles;
using RobloxFiles.DataTypes;

namespace RobloxModelToFilesystem
{
    internal static class Program
    {
        static int Main(string[] args)
        {
            var parsed = ParseArgs(args);

            if (!parsed.TryGetValue("model", out var modelPath) || !File.Exists(modelPath))
            {
                Console.Error.WriteLine("Error: missing or invalid --model argument");
                PrintUsage();
                return 1;
            }

            if (!parsed.TryGetValue("out", out var outputDir))
            {
                outputDir = Path.Combine(Directory.GetCurrentDirectory(), "output");
            }

            Console.WriteLine($"Converting model: {modelPath}");
            Console.WriteLine($"Output directory: {outputDir}");

            // Load the Roblox model
            var file = RobloxFile.Open(modelPath);
            Console.WriteLine($"Model contains {file.Children.Count} top-level children");

            // Create output directory
            if (Directory.Exists(outputDir))
            {
                // Clean existing directory
                try
                {
                    Directory.Delete(outputDir, true);
                }
                catch (Exception ex)
                {
                    Console.WriteLine($"Warning: Could not delete existing output directory: {ex.Message}");
                    Console.WriteLine("Continuing with existing directory (files may be overwritten)");
                }
            }
            
            if (!Directory.Exists(outputDir))
            {
                Directory.CreateDirectory(outputDir);
            }

            // Process all top-level children
            foreach (var rootChild in file.Children)
            {
                if (rootChild is Model)
                {
                    // If top-level is a Model, process its children directly
                    foreach (var modelChild in rootChild.Children)
                    {
                        ProcessInstance(modelChild, outputDir);
                    }
                }
                else
                {
                    ProcessInstance(rootChild, outputDir);
                }
            }

            // Create a default tool.json file if not present
            var toolJsonPath = Path.Combine(outputDir, "tool.json");
            if (!File.Exists(toolJsonPath))
            {
                // Try to extract model name and version from filename
                string modelName = "UnknownTool";
                string modelVersion = "1.0.0";
                string originalModelPath = parsed.TryGetValue("model", out var modelArg) ? modelArg : "";
                if (!string.IsNullOrEmpty(originalModelPath))
                {
                    string fileName = Path.GetFileNameWithoutExtension(originalModelPath);
                    if (fileName.Contains("-v"))
                    {
                        string[] parts = fileName.Split(new[] { "-v" }, StringSplitOptions.None);
                        modelName = parts[0];
                        if (parts.Length > 1)
                        {
                            modelVersion = parts[1];
                        }
                    }
                    else
                    {
                        modelName = fileName;
                    }
                }

                var defaultToolJson = $@"{{
    ""name"": ""{modelName}"",
    ""version"": ""{modelVersion}"",
    ""author"": ""Unknown"",
    ""entry"": ""init.luau"",
    ""rootType"": ""Model""
}}";
                File.WriteAllText(toolJsonPath, defaultToolJson);
                Console.WriteLine($"Created tool.json: {toolJsonPath}");
            }

            Console.WriteLine("Conversion complete");
            return 0;
        }

        static void PrintUsage()
        {
            Console.WriteLine("Usage: RobloxModelToFilesystem --model <path_to_model.rbxm> [--out <output_directory>]");
            Console.WriteLine();
            Console.WriteLine("Options:");
            Console.WriteLine("  --model    Path to the Roblox .rbxm model file");
            Console.WriteLine("  --out      Output directory (default: ./output)");
        }

        static Dictionary<string, string> ParseArgs(string[] args)
        {
            var dict = new Dictionary<string, string>(StringComparer.OrdinalIgnoreCase);
            for (int i = 0; i < args.Length; i++)
            {
                var arg = args[i];
                if (!arg.StartsWith("--")) continue;

                var parts = arg.Substring(2).Split('=', 2);
                var key = parts[0];
                string value;

                if (parts.Length > 1)
                {
                    value = parts[1];
                }
                else if (i + 1 < args.Length && !args[i + 1].StartsWith("--"))
                {
                    value = args[++i];
                }
                else
                {
                    value = "true";
                }

                dict[key] = value;
            }

            return dict;
        }

        static void ProcessInstance(Instance instance, string parentDir)
        {
            if (instance is Script || instance is LocalScript || instance is ModuleScript)
            {
                // Handle script types
                ProcessScript(instance, parentDir);
            }
            else if (instance is Folder)
            {
                // Handle folders as directories
                ProcessFolder(instance, parentDir);
            }
            else
            {
                // Handle other types (e.g., BindableEvent, BillboardGui, etc.)
                ProcessSpecialInstance(instance, parentDir);
            }
        }

        static void ProcessScript(Instance instance, string parentDir)
        {
            // Determine file extension (using .luau as standard)
            string ext = ".luau";
            
            // Check if instance has source property
            if (!instance.Properties.TryGetValue("Source", out var sourceProp) || sourceProp == null)
            {
                Console.WriteLine($"Warning: Script {instance.Name} has no source property");
                return;
            }

            // Extract source from Property value
            string source = "";
            if (sourceProp.Value is ProtectedString protectedStr)
            {
                source = protectedStr.ToString();
            }
            else if (sourceProp.Value is string str)
            {
                source = str;
            }

            // Create filename
            string filename = $"{instance.Name}{ext}";
            string fullPath = Path.Combine(parentDir, filename);

            // Write to file
            File.WriteAllText(fullPath, source);
            Console.WriteLine($"Written: {fullPath}");
        }

        static void ProcessFolder(Instance instance, string parentDir)
        {
            // Create directory for this folder
            string folderPath = Path.Combine(parentDir, instance.Name);
            Directory.CreateDirectory(folderPath);

            Console.WriteLine($"Created directory: {folderPath}");

            // Process all children (copy collection to avoid modification during iteration)
            var children = new List<Instance>(instance.Children);
            foreach (var child in children)
            {
                ProcessInstance(child, folderPath);
            }
        }

        static void ProcessSpecialInstance(Instance instance, string parentDir)
        {
            // Handle special instances like BindableEvents, BillboardGui, etc.
            // Export them as .rbxmx files for preservation (like the original src structure)
            string rbxmxPath = Path.Combine(parentDir, $"{instance.Name}.rbxmx");
            
            try
            {
                var rbxmxFile = new XmlRobloxFile();
                instance.Parent = rbxmxFile;
                
                using (var fs = File.Create(rbxmxPath))
                {
                    rbxmxFile.Save(fs);
                }
                
                // Re-parent back to original parent (optional, but cleaner)
                instance.Parent = null;

                Console.WriteLine($"Saved special instance: {rbxmxPath}");
            }
            catch (Exception ex)
            {
                Console.WriteLine($"Warning: Failed to save special instance {instance.Name}: {ex.Message}");
            }
        }
    }
}
