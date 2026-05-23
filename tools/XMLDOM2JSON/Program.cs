/*
 * XMLDOM2JSON — Roblox XML (.rbxmx / .rbxlx) to canonical JSON DOM.
 */

using System;
using System.Collections.Generic;
using System.IO;
using System.Text.Json;
using System.Text.Json.Serialization;

using RobloxFiles;
using RobloxFiles.DataTypes;
using RobloxFiles.Utility;

namespace XMLDOM2JSON
{
    internal static class Program
    {
        private const int SchemaVersion = 1;

        static int Main(string[] args)
        {
            if (args.Length < 2)
            {
                Console.Error.WriteLine("Usage: XMLDOM2JSON <input.rbxmx|.rbxlx> <output.json>");
                return 1;
            }

            var inputPath = args[0];
            var outputPath = args[1];

            if (!File.Exists(inputPath))
            {
                Console.Error.WriteLine($"File not found: {inputPath}");
                return 1;
            }

            RobloxFile file;
            using (var fs = File.OpenRead(inputPath))
            {
                file = RobloxFile.Open(fs);
            }

            var rootNode = SerializeInstance(file);

            var wrapper = new JsonDomRoot
            {
                Schema = "RobloxDom",
                Version = SchemaVersion,
                Root = rootNode
            };

            if (file is XmlRobloxFile xmlFile && xmlFile.Metadata != null && xmlFile.Metadata.Count > 0)
            {
                wrapper.Metadata = new SortedDictionary<string, string>(StringComparer.Ordinal);
                foreach (var kv in xmlFile.Metadata)
                    wrapper.Metadata[kv.Key] = kv.Value;
            }

            var options = new JsonSerializerOptions
            {
                WriteIndented = true,
                DefaultIgnoreCondition = JsonIgnoreCondition.WhenWritingNull,
                PropertyNamingPolicy = JsonNamingPolicy.CamelCase
            };

            File.WriteAllText(outputPath, JsonSerializer.Serialize(wrapper, options));
            return 0;
        }

        private static JsonInstance SerializeInstance(Instance inst)
        {
            var node = new JsonInstance
            {
                ClassName = inst.ClassName,
                Name = inst.Name,
                Referent = string.IsNullOrEmpty(inst.Referent) ? null : inst.Referent,
                Properties = SerializeProperties(inst),
                Attributes = SerializeAttributes(inst),
                Children = new List<JsonInstance>()
            };

            foreach (var child in inst.Children)
                node.Children.Add(SerializeInstance(child));

            return node;
        }

        private static SortedDictionary<string, object?>? SerializeProperties(Instance inst)
        {
            var dict = new SortedDictionary<string, object?>(StringComparer.Ordinal);

            foreach (var kv in inst.Properties)
            {
                var propName = kv.Key;
                var prop = kv.Value;
                var value = prop.Value;

                // Only serialize non-default properties
                var defaultValue = DefaultProperty.Get(inst.ClassName, propName);
                if (value != null && !value.Equals(defaultValue))
                {
                    var serialized = SerializeValue(value);
                    if (serialized != null)
                        dict[propName] = serialized;
                }
            }

            return dict.Count == 0 ? null : dict;
        }

        private static SortedDictionary<string, object?>? SerializeAttributes(Instance inst)
        {
            if (inst.Attributes == null || inst.Attributes.Count == 0)
                return null;

            var dict = new SortedDictionary<string, object?>(StringComparer.Ordinal);
            foreach (var kv in inst.Attributes)
            {
                var serialized = SerializeValue(kv.Value.Value);
                if (serialized != null)
                    dict[kv.Key] = serialized;
            }
            return dict.Count == 0 ? null : dict;
        }

        private static object? SerializeValue(object? value)
        {
            if (value == null)
                return null;

            if (value is System.Enum e)
            {
                return new JsonEnum
                {
                    Enum = e.GetType().Name,
                    Value = Convert.ToUInt32(e)
                };
            }

            return value switch
            {
                Vector3 v => new { x = v.X, y = v.Y, z = v.Z },
                Vector2 v => new { x = v.X, y = v.Y },
                Vector3int16 v => new { x = v.X, y = v.Y, z = v.Z },
                Vector2int16 v => new { x = v.X, y = v.Y },
                Color3 c => new { r = c.R, g = c.G, b = c.B },
                Color3uint8 c => new { r = c.R, g = c.G, b = c.B },
                UDim u => new { scale = u.Scale, offset = u.Offset },
                UDim2 u => new
                {
                    x = new { scale = u.X.Scale, offset = u.X.Offset },
                    y = new { scale = u.Y.Scale, offset = u.Y.Offset }
                },
                CFrame cf => SerializeCFrame(cf),
                Ray r => new { origin = SerializeValue(r.Origin), direction = SerializeValue(r.Direction) },
                Rect r => new { min = SerializeValue(r.Min), max = SerializeValue(r.Max) },
                BrickColor bc => new { number = bc.Number },
                NumberRange nr => new { min = nr.Min, max = nr.Max },
                NumberSequence ns => new { keypoints = SerializeNumberSequenceKeypoints(ns.Keypoints) },
                ColorSequence cs => new { keypoints = SerializeColorSequenceKeypoints(cs.Keypoints) },
                PhysicalProperties pp => new
                {
                    density = pp.Density,
                    friction = pp.Friction,
                    elasticity = pp.Elasticity,
                    frictionWeight = pp.FrictionWeight,
                    elasticityWeight = pp.ElasticityWeight,
                    acousticAbsorption = pp.AcousticAbsorption
                },
                Faces f => (int)f,
                Axes a => (int)a,
                FontFace ff => new { family = ff.Family.ToString(), weight = (int)ff.Weight, style = (int)ff.Style },
                UniqueId uid => new { time = uid.Time, index = uid.Index, random = uid.Random },
                Content c => c.ToString(),
                ContentId c => c.ToString(),
                SharedString ss => ss.Key,
                ProtectedString ps => "[ProtectedString]",
                Instance refInst => new { @ref = refInst?.Referent ?? "null" },
                _ => value
            };
        }

        private static object SerializeCFrame(CFrame cf)
        {
            var m = cf.GetComponents();
            return new
            {
                position = new { x = m[0], y = m[1], z = m[2] },
                rotation = new[]
                {
                    m[3], m[4], m[5],
                    m[6], m[7], m[8],
                    m[9], m[10], m[11]
                }
            };
        }

        private static object[] SerializeNumberSequenceKeypoints(NumberSequenceKeypoint[] keypoints)
        {
            var arr = new object[keypoints.Length];
            for (int i = 0; i < keypoints.Length; i++)
            {
                var k = keypoints[i];
                arr[i] = new { time = k.Time, value = k.Value, envelope = k.Envelope };
            }
            return arr;
        }

        private static object[] SerializeColorSequenceKeypoints(ColorSequenceKeypoint[] keypoints)
        {
            var arr = new object[keypoints.Length];
            for (int i = 0; i < keypoints.Length; i++)
            {
                var k = keypoints[i];
                var v = (Color3)k.Value; // Convert Color3uint8 to Color3 (0-1 range)
                arr[i] = new { time = k.Time, value = new { r = v.R, g = v.G, b = v.B }, envelope = k.Envelope };
            }
            return arr;
        }
    }

    internal sealed class JsonDomRoot
    {
        public string Schema { get; set; } = "";
        public int Version { get; set; }

        [JsonIgnore(Condition = JsonIgnoreCondition.WhenWritingNull)]
        public SortedDictionary<string, string>? Metadata { get; set; }

        public JsonInstance Root { get; set; } = null!;
    }

    internal sealed class JsonEnum
    {
        public string Enum { get; set; } = "";
        public uint Value { get; set; }
    }

    internal sealed class JsonInstance
    {
        public string ClassName { get; set; } = "";
        public string Name { get; set; } = "";

        /// <summary>Preserved for round-trip; used by Ref resolution in JSONDOM2XML.</summary>
        [JsonIgnore(Condition = JsonIgnoreCondition.WhenWritingNull)]
        public string? Referent { get; set; }

        [JsonIgnore(Condition = JsonIgnoreCondition.WhenWritingNull)]
        public SortedDictionary<string, object?>? Properties { get; set; }

        [JsonIgnore(Condition = JsonIgnoreCondition.WhenWritingNull)]
        public SortedDictionary<string, object?>? Attributes { get; set; }

        public List<JsonInstance> Children { get; set; } = new();
    }
}
