/*
 * Tool Builder (LuauExporter) — Builds a single .rbxm Model from a tool source directory.
 *
 * Design:
 * - Reads tool.json (name, version, entry, rootType). Builds Model named {Name}-v{Version}.
 * - Root init.luau = ModuleScript named after the tool (shared API, never auto-runs).
 * - server/init.luau = Script (auto-runs on server); client/init.luau = LocalScript (auto-runs on client).
 * - All other .luau files = ModuleScript.
 * - Folders containing init.luau become script instances (not folders), with children nested under them.
 * - .rbxmx under tool dir are loaded and their root children reparented into the tree (by name).
 * - .json files in RobloxDom format are loaded and their root children reparented into the tree.
 * - inject.json enables object injection: scripts can be injected into specific RBXMX descendants.
 * - misc/INSTALLATION.luau and misc/LICENSE.luau included as ModuleScripts.
 * - Saves via BinaryRobloxFile: root.Parent = file; file.Save(stream). No RobloxFile.WriteBinary in library.
 *
 * Execution Model:
 * - Only Script and LocalScript auto-execute in Roblox.
 * - ModuleScripts never auto-run; they must be required.
 * - Root init is a ModuleScript that both server and client scripts require.
 * - See EXECUTION_MODEL.md for detailed documentation.
 */

using System;
using System.Collections.Generic;
using System.IO;
using System.Reflection;
using System.Text.Json;
using System.Text.Json.Serialization;

using RobloxFiles;
using RobloxFiles.DataTypes;
using RobloxFiles.Enums;

namespace LuauExporter
{
    internal static class Program
    {
        static int Main(string[] args)
        {
            var parsed = ParseArgs(args);

            if (!parsed.TryGetValue("tooldir", out var toolDir))
            {
                Console.Error.WriteLine("Error: missing required argument --tooldir");
                return 1;
            }

            if (!Directory.Exists(toolDir))
            {
                Console.Error.WriteLine($"Error: directory not found: {toolDir}");
                return 1;
            }

            var metadataPath = Path.Combine(toolDir, "tool.json");
            ToolMetadata metadata;
            if (!File.Exists(metadataPath))
            {
                Console.WriteLine("Warning: tool.json not found, using default metadata");
                metadata = new ToolMetadata
                {
                    Name = Path.GetFileName(toolDir),
                    Version = "1.0.0",
                    Author = "Unknown",
                    Entry = "init.luau",
                    RootType = "Model"
                };
            }
            else
            {
                metadata = LoadMetadata(metadataPath);
            }

            Console.WriteLine($"Building tool '{metadata.Name}' v{metadata.Version}");

            var root = BuildModel(toolDir, metadata);
            
            // Print the structure of the generated model
            Console.WriteLine();
            Console.WriteLine("Generated Model Structure:");
            Console.WriteLine("==========================");
            PrintInstanceTree(root, 0);
            Console.WriteLine();

            var defaultOut = $"{metadata.Name}-v{metadata.Version}.rbxm";
            var outPath = parsed.TryGetValue("out", out var outArg) && !string.IsNullOrWhiteSpace(outArg)
                ? outArg
                : Path.Combine(Directory.GetCurrentDirectory(), defaultOut);

            var dir = Path.GetDirectoryName(outPath);
            if (!string.IsNullOrEmpty(dir) && !Directory.Exists(dir))
                Directory.CreateDirectory(dir);

            using (var fs = File.Create(outPath))
            {
                var file = new BinaryRobloxFile();
                root.Parent = file;
                file.Save(fs);
            }

            Console.WriteLine($"Wrote {outPath}");
            return 0;
        }

        static void PrintInstanceTree(Instance instance, int depth)
        {
            var indent = new string(' ', depth * 2);
            
            Console.Write(indent);
            Console.Write($"[{instance.ClassName}] ");
            Console.Write(instance.Name);
            
            // Check if this instance has a Source property by type checking
            if (instance is Script || instance is LocalScript || instance is ModuleScript || instance is AuroraScript)
            {
                Console.Write(" (has source property)");
            }
            
            Console.WriteLine();

            foreach (var child in instance.Children)
            {
                PrintInstanceTree(child, depth + 1);
            }
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
                    value = parts[1];
                else if (i + 1 < args.Length && !args[i + 1].StartsWith("--"))
                    value = args[++i];
                else
                    value = "true";
                dict[key] = value;
            }
            return dict;
        }

        static ToolMetadata LoadMetadata(string path)
        {
            var json = File.ReadAllText(path);
            var options = new JsonSerializerOptions { PropertyNameCaseInsensitive = true };
            var meta = JsonSerializer.Deserialize<ToolMetadata>(json, options);
            if (meta == null)
                throw new Exception("Invalid tool.json");
            if (string.IsNullOrWhiteSpace(meta.Name) || string.IsNullOrWhiteSpace(meta.Version) || string.IsNullOrWhiteSpace(meta.Entry))
                throw new Exception("tool.json missing required fields (name, version, entry)");
            return meta;
        }

        static Instance BuildModel(string toolDir, ToolMetadata meta)
        {
            var rootType = string.IsNullOrWhiteSpace(meta.RootType) ? "Model" : meta.RootType.Trim();
            var rootName = $"{meta.Name}-v{meta.Version}";

            Instance root = rootType switch
            {
                "Model" => new Model { Name = rootName },
                "Folder" => new Folder { Name = rootName },
                _ => new Model { Name = rootName }
            };

            // Check if there's an init.luau at root level
            // This becomes a ModuleScript named after the tool (without version)
            Instance? initScript = null;
            var rootInitPath = Path.Combine(toolDir, "init.luau");
            if (File.Exists(rootInitPath))
            {
                var source = File.ReadAllText(rootInitPath);
                var protectedSource = new ProtectedString(source);
                // Name the root init as the tool name (without version)
                initScript = new ModuleScript { Name = meta.Name, Source = protectedSource, Parent = root };
                Console.WriteLine($"Created root init script: [{initScript.ClassName}] {initScript.Name}");
            }

            BuildDirectory(toolDir, root, toolDir, meta, initScript);
            return root;
        }

        static void BuildDirectory(string baseDir, Instance parent, string currentDir, ToolMetadata meta, Instance? rootInitScript)
        {
            BuildDirectoryContents(baseDir, parent, currentDir, meta, null, rootInitScript, null);
        }

        /// <summary>
        /// Traverses the DOM by name to resolve a target path like "Tag/Health"
        /// </summary>
        static Instance? ResolveTargetPath(Instance root, string targetPath)
        {
            var parts = targetPath.Split('/');
            Instance current = root;
            int startIndex = 0;

            // If the first part of the path matches the root's name, skip it
            if (parts.Length > 0 && string.Equals(parts[0], root.Name, StringComparison.Ordinal))
            {
                startIndex = 1;
            }

            for (int i = startIndex; i < parts.Length; i++)
            {
                var part = parts[i];
                if (string.IsNullOrWhiteSpace(part))
                    continue;

                Instance? found = null;
                foreach (var child in current.Children)
                {
                    if (string.Equals(child.Name, part, StringComparison.Ordinal))
                    {
                        found = child;
                        break;
                    }
                }

                if (found == null)
                    return null;

                current = found;
            }

            return current;
        }

        /// <summary>
        /// Performs object injection based on inject.json metadata
        /// Returns a list of source file names that were used for injection
        /// </summary>
        static HashSet<string> PerformInjections(string currentDir, Instance rbxmxRoot, string rbxmxFileName)
        {
            var injectedFiles = new HashSet<string>(StringComparer.OrdinalIgnoreCase);
            var injectJsonPath = Path.Combine(currentDir, "inject.json");
            if (!File.Exists(injectJsonPath))
                return injectedFiles;

            InjectionMetadata? injectionMeta;
            try
            {
                var json = File.ReadAllText(injectJsonPath);
                var options = new JsonSerializerOptions { PropertyNameCaseInsensitive = true };
                injectionMeta = JsonSerializer.Deserialize<InjectionMetadata>(json, options);
            }
            catch (Exception ex)
            {
                Console.Error.WriteLine($"Warning: could not parse inject.json: {ex.Message}");
                return injectedFiles;
            }

            if (injectionMeta?.Inject == null || injectionMeta.Inject.Count == 0)
                return injectedFiles;

            foreach (var injection in injectionMeta.Inject)
            {
                if (string.IsNullOrWhiteSpace(injection.Target) || 
                    string.IsNullOrWhiteSpace(injection.Type) || 
                    string.IsNullOrWhiteSpace(injection.Name) || 
                    string.IsNullOrWhiteSpace(injection.Source))
                {
                    Console.Error.WriteLine($"Warning: invalid injection definition in inject.json");
                    continue;
                }

                // Resolve the target path
                var targetInstance = ResolveTargetPath(rbxmxRoot, injection.Target);
                if (targetInstance == null)
                {
                    Console.Error.WriteLine($"Fatal error: injection target '{injection.Target}' not found in {rbxmxFileName}");
                    throw new Exception($"Injection target '{injection.Target}' not found in {rbxmxFileName}");
                }

                // Read the source file
                var sourcePath = Path.Combine(currentDir, injection.Source);
                if (!File.Exists(sourcePath))
                {
                    Console.Error.WriteLine($"Fatal error: injection source file '{injection.Source}' not found");
                    throw new Exception($"Injection source file '{injection.Source}' not found");
                }

                // Track this file so it won't be included as an artifact
                injectedFiles.Add(injection.Source);

                var source = File.ReadAllText(sourcePath);
                var protectedSource = new ProtectedString(source);

                // Check if an instance with the same name already exists and remove it
                Instance? existingInstance = null;
                foreach (var child in targetInstance.Children)
                {
                    if (string.Equals(child.Name, injection.Name, StringComparison.Ordinal))
                    {
                        existingInstance = child;
                        break;
                    }
                }

                if (existingInstance != null)
                {
                    existingInstance.Parent = null; // Remove from parent
                    Console.WriteLine($"Replaced existing [{existingInstance.ClassName}] {existingInstance.Name}");
                }

                // Create the appropriate script type
                Instance scriptInstance = injection.Type.ToLowerInvariant() switch
                {
                    "script" => new Script { Name = injection.Name, Source = protectedSource, Parent = targetInstance },
                    "localscript" => new LocalScript { Name = injection.Name, Source = protectedSource, Parent = targetInstance },
                    "modulescript" => new ModuleScript { Name = injection.Name, Source = protectedSource, Parent = targetInstance },
                    _ => throw new Exception($"Unknown script type '{injection.Type}' in injection definition")
                };

                // Apply additional properties if specified
                if (injection.Properties != null)
                {
                    foreach (var prop in injection.Properties)
                    {
                        try
                        {
                            // Handle JsonElement from deserialization
                            var value = prop.Value;
                            if (value is System.Text.Json.JsonElement jsonElement)
                            {
                                // Handle common property types
                                if (prop.Key == "Disabled" && scriptInstance is Script script)
                                {
                                    script.Disabled = jsonElement.GetBoolean();
                                }
                                else if (prop.Key == "Disabled" && scriptInstance is LocalScript localScript)
                                {
                                    localScript.Disabled = jsonElement.GetBoolean();
                                }
                                // Add more property handlers as needed
                            }
                        }
                        catch (Exception ex)
                        {
                            Console.Error.WriteLine($"Warning: could not set property '{prop.Key}': {ex.Message}");
                        }
                    }
                }

                Console.WriteLine($"Injected [{scriptInstance.ClassName}] {scriptInstance.Name} into {injection.Target}");
            }

            return injectedFiles;
        }

        private static readonly Assembly RobloxAssembly = typeof(Instance).Assembly;
        private static int _referentCounter;

        static void BuildDirectoryContents(string baseDir, Instance parent, string currentDir, ToolMetadata meta, string? skipInitFile, Instance? rootInitScript, HashSet<string>? injectedFiles = null)
        {
            var isRoot = currentDir == baseDir;

            // Process .rbxmx files first and collect injected source files
            var allInjectedFiles = injectedFiles ?? new HashSet<string>(StringComparer.OrdinalIgnoreCase);
            foreach (var filePath in Directory.GetFiles(currentDir, "*.rbxmx"))
            {
                try
                {
                    var fileName = Path.GetFileName(filePath);
                    using var fs = File.OpenRead(filePath);
                    var file = RobloxFile.Open(fs);
                    var children = new List<Instance>(file.Children);
                    
                    // Perform injections before attaching to parent
                    foreach (var child in children)
                    {
                        var childInjectedFiles = PerformInjections(currentDir, child, fileName);
                        foreach (var injectedFile in childInjectedFiles)
                        {
                            allInjectedFiles.Add(injectedFile);
                        }
                        child.Parent = parent;
                    }
                }
                catch (Exception ex)
                {
                    Console.Error.WriteLine($"Warning: could not load {filePath}: {ex.Message}");
                }
            }

            // Process .luau files in current directory (after RBXMX so we know which files to skip)
            foreach (var filePath in Directory.GetFiles(currentDir, "*.luau"))
            {
                var fileName = Path.GetFileName(filePath);
                var name = Path.GetFileNameWithoutExtension(filePath);
                
                // Skip the init file if we're processing children (it was already used for the parent Script)
                if (skipInitFile != null && string.Equals(fileName, skipInitFile, StringComparison.OrdinalIgnoreCase))
                {
                    continue;
                }
                
                // Skip init.luau at root level (already handled in BuildModel)
                if (isRoot && string.Equals(fileName, "init.luau", StringComparison.OrdinalIgnoreCase))
                {
                    continue;
                }
                
                // Skip files that were used for injection
                if (allInjectedFiles.Contains(fileName))
                {
                    Console.WriteLine($"Skipped injected file: {fileName}");
                    continue;
                }
                
                // .luau file = Check for type
                {
                    var source = File.ReadAllText(filePath);
                    var protectedSource = new ProtectedString(source);
                    if (fileName.Contains("server", StringComparison.OrdinalIgnoreCase))
                    {
                        var script = new Script { Name = name, Source = protectedSource, Parent = parent };
                        Console.WriteLine($"Created script: [{script.ClassName}] {script.Name}");
                    } else if (fileName.Contains("client", StringComparison.OrdinalIgnoreCase)
                                || fileName.Contains("local", StringComparison.OrdinalIgnoreCase))
                    {
                        var script = new LocalScript { Name = name, Source = protectedSource, Parent = parent };
                        Console.WriteLine($"Created local script: [{script.ClassName}] {script.Name}");
                    } else 
                    {
                        var script = new ModuleScript { Name = name, Source = protectedSource, Parent = parent };
                        Console.WriteLine($"Created module: [{script.ClassName}] {script.Name}");
                    }
                }
            }
            
            // Process .json files in current directory (RobloxDom format files)
            foreach (var filePath in Directory.GetFiles(currentDir, "*.json"))
            {
                var fileName = Path.GetFileName(filePath);
                
                // Skip tool.json and inject.json as they are metadata files
                if (string.Equals(fileName, "tool.json", StringComparison.OrdinalIgnoreCase) ||
                    string.Equals(fileName, "inject.json", StringComparison.OrdinalIgnoreCase))
                {
                    continue;
                }
                
                try
                {
                    var json = File.ReadAllText(filePath);
                    var options = new JsonSerializerOptions { PropertyNameCaseInsensitive = true };
                    using var doc = JsonDocument.Parse(json);
                    var root = doc.RootElement;
                    
                    // Check if this is a RobloxDom format file
                    if (root.TryGetProperty("schema", out var schemaEl) &&
                        schemaEl.GetString() == "RobloxDom" &&
                        root.TryGetProperty("root", out var rootEl))
                    {
                        // Parse the RobloxDom structure and build instances
                        var refMap = new Dictionary<string, Instance>();
                        var instances = BuildInstance(rootEl, refMap);
                        
                        if (instances != null && instances.ClassName == "XmlRobloxFile")
                        {
                            // Add children of XmlRobloxFile to parent
                            foreach (var child in instances.Children.ToList())
                            {
                                child.Parent = parent;
                            }
                            Console.WriteLine($"Loaded RobloxDom file: {fileName}");
                        }
                    }
                }
                catch (Exception ex)
                {
                    Console.Error.WriteLine($"Warning: could not load {filePath}: {ex.Message}");
                }
            }
            
            // Process subdirectories with two-pass approach
            foreach (var dir in Directory.GetDirectories(currentDir))
            {
                var dirName = Path.GetFileName(dir);
                var isMisc = string.Equals(dirName, "misc", StringComparison.OrdinalIgnoreCase);
                
                // Special case: misc directory - place its contents directly in root
                if (isRoot && isMisc)
                {
                    Console.WriteLine($"Processing misc directory - placing contents in root");
                    BuildDirectoryContents(baseDir, parent, dir, meta, null, rootInitScript, allInjectedFiles);
                    continue;
                }
                
                // Determine parent for this directory
                // If we're at root and there's a root init script, place directories under it
                Instance targetParent = (isRoot && rootInitScript != null) ? rootInitScript : parent;
                
                // PASS 1: Check if directory contains an init*.luau file
                var initFile = DetectInitFile(dir);
                
                Instance container;
                
                if (initFile != null)
                {
                    // Directory contains init file = create Script instance
                    var source = File.ReadAllText(initFile.FullPath);
                    var protectedSource = new ProtectedString(source);
                    
                    container = initFile.Type switch
                    {
                        InitFileType.Script => new Script { Name = dirName, Source = protectedSource, Parent = targetParent },
                        InitFileType.LocalScript => new LocalScript { Name = dirName, Source = protectedSource, Parent = targetParent },
                        InitFileType.ModuleScript => new ModuleScript { Name = dirName, Source = protectedSource, Parent = targetParent },
                        _ => new ModuleScript { Name = dirName, Source = protectedSource, Parent = targetParent }
                    };
                    
                    Console.WriteLine($"Created script from directory: [{container.ClassName}] {container.Name}");
                }
                else
                {
                    // No init file = create Folder
                    container = new Folder
                    {
                        Name = dirName,
                        Parent = targetParent
                    };
                }
                
                // PASS 2: Recursively build children (they become children of the Script or Folder)
                BuildDirectoryContents(baseDir, container, dir, meta, initFile?.FileName, rootInitScript, allInjectedFiles);
            }
        }

        private static Instance? BuildInstance(JsonElement node, Dictionary<string, Instance> refMap)
        {
            if (!node.TryGetProperty("className", out var classEl))
                return null;
            var className = classEl.GetString();
            if (string.IsNullOrEmpty(className))
                return null;

            var instType = RobloxAssembly.GetType($"RobloxFiles.{className}");
            if (instType == null)
            {
                Console.Error.WriteLine($"Unknown class: {className}");
                return null;
            }

            var inst = Activator.CreateInstance(instType) as Instance;
            if (inst == null)
                return null;

            if (node.TryGetProperty("name", out var nameEl))
                inst.Name = nameEl.GetString() ?? inst.Name;

            var referent = node.TryGetProperty("referent", out var refEl) ? refEl.GetString() : null;
            if (string.IsNullOrEmpty(referent))
                referent = "RBX" + (_referentCounter++);
            inst.Referent = referent;
            refMap[referent] = inst;

            if (node.TryGetProperty("children", out var childrenEl))
            {
                foreach (var childEl in childrenEl.EnumerateArray())
                {
                    var child = BuildInstance(childEl, refMap);
                    if (child != null)
                        child.Parent = inst;
                }
            }

            return inst;
        }

        private static void ApplyPropertiesAndChildren(JsonElement node, Instance inst, Dictionary<string, Instance> refMap)
        {
            ApplyProperties(node, refMap, inst);

            if (!node.TryGetProperty("children", out var childrenEl))
                return;

            int idx = 0;
            foreach (var childEl in childrenEl.EnumerateArray())
            {
                if (idx < inst.Children.Count)
                    ApplyPropertiesAndChildren(childEl, inst.Children[idx], refMap);
                idx++;
            }
        }

        private static void ApplyProperties(JsonElement node, Dictionary<string, Instance> refMap, Instance inst)
        {
            if (node.TryGetProperty("properties", out var propsEl) && propsEl.ValueKind == JsonValueKind.Object)
            {
                foreach (var prop in propsEl.EnumerateObject())
                {
                    if (!inst.Properties.TryGetValue(prop.Name, out var robloxProp))
                        continue;
                    var value = DeserializeValue(prop.Value, robloxProp, refMap);
                    if (value != null || robloxProp.Type == PropertyType.Ref)
                        robloxProp.Value = value;
                }
            }

            if (node.TryGetProperty("attributes", out var attrsEl) && attrsEl.ValueKind == JsonValueKind.Object)
            {
                foreach (var attr in attrsEl.EnumerateObject())
                {
                    var value = DeserializeAttributeValue(attr.Value);
                    if (value != null)
                        inst.SetAttribute(attr.Name, value);
                }
            }
        }

        private static object? DeserializeValue(JsonElement el, Property prop, Dictionary<string, Instance> refMap)
        {
            if (el.ValueKind == JsonValueKind.Null || el.ValueKind == JsonValueKind.Undefined)
                return null;

            if (el.ValueKind == JsonValueKind.Object)
            {
                if (el.TryGetProperty("ref", out var refEl))
                {
                    var refStr = refEl.GetString();
                    if (!string.IsNullOrEmpty(refStr) && refMap.TryGetValue(refStr, out var targetInst))
                        return targetInst;
                    return null;
                }
                // Handle other complex types as needed
                return null;
            }

            // Handle primitive types
            switch (prop.Type)
            {
                case PropertyType.String:
                    return el.GetString();
                case PropertyType.Bool:
                    return el.GetBoolean();
                case PropertyType.Int:
                    return el.GetInt32();
                case PropertyType.Float:
                    return el.GetSingle();
                case PropertyType.Double:
                    return el.GetDouble();
                default:
                    return null;
            }
        }

        private static object? DeserializeAttributeValue(JsonElement el)
        {
            switch (el.ValueKind)
            {
                case JsonValueKind.String:
                    return el.GetString();
                case JsonValueKind.Number:
                    if (el.TryGetInt32(out var intVal))
                        return intVal;
                    if (el.TryGetDouble(out var doubleVal))
                        return doubleVal;
                    return null;
                case JsonValueKind.True:
                    return true;
                case JsonValueKind.False:
                    return false;
                default:
                    return null;
            }
        }

        enum InitFileType
        {
            Script,
            LocalScript,
            ModuleScript
        }

        class InitFileInfo
        {
            public string FullPath { get; set; } = "";
            public string FileName { get; set; } = "";
            public InitFileType Type { get; set; }
        }

        static InitFileInfo? DetectInitFile(string directory)
        {
            var dirName = Path.GetFileName(directory.TrimEnd(Path.DirectorySeparatorChar, Path.AltDirectorySeparatorChar));
            
            // Check for init.client.luau = LocalScript
            var clientInit = Path.Combine(directory, "init.client.luau");
            if (File.Exists(clientInit))
            {
                return new InitFileInfo
                {
                    FullPath = clientInit,
                    FileName = "init.client.luau",
                    Type = InitFileType.LocalScript
                };
            }

            // Check for init.module.luau = ModuleScript
            var moduleInit = Path.Combine(directory, "init.module.luau");
            if (File.Exists(moduleInit))
            {
                return new InitFileInfo
                {
                    FullPath = moduleInit,
                    FileName = "init.module.luau",
                    Type = InitFileType.ModuleScript
                };
            }

            // Check for init.server.luau = ModuleScript
            var serverInit = Path.Combine(directory, "init.server.luau");
            if (File.Exists(serverInit))
            {
                return new InitFileInfo
                {
                    FullPath = serverInit,
                    FileName = "init.server.luau",
                    Type = InitFileType.Script
                };
            }

            // Check for init.luau
            var plainInit = Path.Combine(directory, "init.luau");
            if (File.Exists(plainInit))
            {
                // Determine type based on directory name
                InitFileType type;
                if (string.Equals(dirName, "client", StringComparison.OrdinalIgnoreCase))
                {
                    type = InitFileType.LocalScript;
                }
                else if (string.Equals(dirName, "server", StringComparison.OrdinalIgnoreCase))
                {
                    type = InitFileType.Script;
                }
                else
                {
                    // Default to ModuleScript for other directories
                    type = InitFileType.ModuleScript;
                }
                
                return new InitFileInfo
                {
                    FullPath = plainInit,
                    FileName = "init.luau",
                    Type = type
                };
            }

            return null;
        }

        static InitFileInfo? GetInitFileInfo(string fileName)
        {
            if (string.Equals(fileName, "init.client.luau", StringComparison.OrdinalIgnoreCase))
            {
                return new InitFileInfo
                {
                    FileName = fileName,
                    Type = InitFileType.LocalScript
                };
            }

            if (string.Equals(fileName, "init.module.luau", StringComparison.OrdinalIgnoreCase))
            {
                return new InitFileInfo
                {
                    FileName = fileName,
                    Type = InitFileType.ModuleScript
                };
            }

            if (string.Equals(fileName, "init.luau", StringComparison.OrdinalIgnoreCase))
            {
                return new InitFileInfo
                {
                    FileName = fileName,
                    Type = InitFileType.Script
                };
            }

            return null;
        }
    }

    internal sealed class ToolMetadata
    {
        [JsonPropertyName("name")]
        public string Name { get; set; } = "";

        [JsonPropertyName("version")]
        public string Version { get; set; } = "";

        [JsonPropertyName("entry")]
        public string Entry { get; set; } = "";

        [JsonPropertyName("author")]
        public string? Author { get; set; }

        [JsonPropertyName("rootType")]
        public string? RootType { get; set; }
    }

    internal sealed class InjectionMetadata
    {
        [JsonPropertyName("inject")]
        public List<InjectionDefinition>? Inject { get; set; }
    }

    internal sealed class InjectionDefinition
    {
        [JsonPropertyName("target")]
        public string Target { get; set; } = "";

        [JsonPropertyName("type")]
        public string Type { get; set; } = "";

        [JsonPropertyName("name")]
        public string Name { get; set; } = "";

        [JsonPropertyName("source")]
        public string Source { get; set; } = "";

        [JsonPropertyName("properties")]
        public Dictionary<string, object>? Properties { get; set; }
    }
}
