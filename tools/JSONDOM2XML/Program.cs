/*
 * JSONDOM2XML — Rebuild Roblox Instances from canonical JSON DOM and write .rbxmx/.rbxlx.
 */

using System;
using System.Collections.Generic;
using System.IO;
using System.Reflection;
using System.Text.Json;

using RobloxFiles;
using RobloxFiles.DataTypes;
using RobloxFiles.Enums;

namespace JSONDOM2XML
{
    internal static class Program
    {
        private static readonly Assembly RobloxAssembly = typeof(Instance).Assembly;
        private static int _referentCounter;

        static int Main(string[] args)
        {
            if (args.Length < 2)
            {
                Console.Error.WriteLine("Usage: JSONDOM2XML <input.json> <output.rbxmx|.rbxlx>");
                return 1;
            }

            var inputPath = args[0];
            var outputPath = args[1];

            if (!File.Exists(inputPath))
            {
                Console.Error.WriteLine($"File not found: {inputPath}");
                return 1;
            }

            var json = File.ReadAllText(inputPath);
            using var doc = JsonDocument.Parse(json);
            var root = doc.RootElement;

            if (!root.TryGetProperty("schema", out var schemaEl) || schemaEl.GetString() != "RobloxDom")
            {
                Console.Error.WriteLine("Invalid or unsupported JSON schema (expected schema: RobloxDom)");
                return 1;
            }

            if (!root.TryGetProperty("root", out var rootEl))
            {
                Console.Error.WriteLine("Missing 'root' in JSON");
                return 1;
            }

            _referentCounter = 0;
            var refMap = new Dictionary<string, Instance>(StringComparer.Ordinal);

            var file = new XmlRobloxFile();
            if (root.TryGetProperty("metadata", out var metadataEl) && metadataEl.ValueKind == JsonValueKind.Object)
            {
                foreach (var prop in metadataEl.EnumerateObject())
                {
                    var val = prop.Value.ValueKind == JsonValueKind.String ? prop.Value.GetString() : prop.Value.GetRawText();
                    if (val != null)
                        file.Metadata[prop.Name] = val;
                }
            }

            file.WriteAllProperties = true;

            if (!rootEl.TryGetProperty("children", out var childrenEl))
            {
                Console.Error.WriteLine("Missing 'children' on root");
                return 1;
            }

            foreach (var childEl in childrenEl.EnumerateArray())
            {
                var inst = BuildInstance(childEl, refMap);
                if (inst != null)
                    inst.Parent = file;
            }

            int childIndex = 0;
            foreach (var childEl in childrenEl.EnumerateArray())
            {
                if (childIndex < file.Children.Count)
                {
                    var inst = file.Children[childIndex];
                    ApplyPropertiesAndChildren(childEl, inst, refMap);
                }
                childIndex++;
            }

            using (var fs = File.Create(outputPath))
                file.Save(fs);

            Console.WriteLine($"Wrote {outputPath}");
            return 0;
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
                    var refId = refEl.GetString();
                    return refId != null && refMap.TryGetValue(refId, out var target) ? target : null;
                }
                if (el.TryGetProperty("enum", out var enumNameEl) && el.TryGetProperty("value", out var enumValEl))
                {
                    var enumName = enumNameEl.GetString();
                    var enumVal = enumValEl.GetUInt32();
                    var enumType = RobloxAssembly.GetType($"RobloxFiles.Enums.{enumName}");
                    if (enumType != null && enumType.IsEnum)
                        return Enum.ToObject(enumType, enumVal);
                }
                if (el.TryGetProperty("Enum", out var e2) && el.TryGetProperty("Value", out var v2))
                {
                    var enumName = e2.GetString();
                    var enumVal = v2.GetUInt32();
                    var enumType = RobloxAssembly.GetType($"RobloxFiles.Enums.{enumName}");
                    if (enumType != null && enumType.IsEnum)
                        return Enum.ToObject(enumType, enumVal);
                }

                if (el.TryGetProperty("x", out var xEl) && el.TryGetProperty("y", out var yEl) &&
                    xEl.ValueKind == JsonValueKind.Number && yEl.ValueKind == JsonValueKind.Number)
                {
                    if (el.TryGetProperty("z", out var zEl) && zEl.ValueKind == JsonValueKind.Number)
                        return new Vector3((float)xEl.GetDouble(), (float)yEl.GetDouble(), (float)zEl.GetDouble());
                    return new Vector2((float)xEl.GetDouble(), (float)yEl.GetDouble());
                }
                if (el.TryGetProperty("r", out var rEl) && el.TryGetProperty("g", out var gEl) && el.TryGetProperty("b", out var bEl))
                {
                    return new Color3((float)rEl.GetDouble(), (float)gEl.GetDouble(), (float)bEl.GetDouble());
                }
                if (el.TryGetProperty("x", out var xUDim) && el.TryGetProperty("y", out var yUDim) &&
                    xUDim.TryGetProperty("scale", out var xs) && xUDim.TryGetProperty("offset", out var xo) &&
                    yUDim.TryGetProperty("scale", out var ys) && yUDim.TryGetProperty("offset", out var yo))
                {
                    return new UDim2((float)xs.GetDouble(), xo.GetInt32(), (float)ys.GetDouble(), yo.GetInt32());
                }
                if (el.TryGetProperty("scale", out var scaleEl) && el.TryGetProperty("offset", out var offsetEl))
                    return new UDim((float)scaleEl.GetDouble(), offsetEl.GetInt32());
                if (el.TryGetProperty("position", out var posEl) && el.TryGetProperty("rotation", out var rotEl))
                {
                    var px = posEl.TryGetProperty("x", out var pxEl) ? (float)pxEl.GetDouble() : 0;
                    var py = posEl.TryGetProperty("y", out var pyEl) ? (float)pyEl.GetDouble() : 0;
                    var pz = posEl.TryGetProperty("z", out var pzEl) ? (float)pzEl.GetDouble() : 0;
                    var r = rotEl.EnumerateArray();
                    var m = new float[12];
                    int i = 0;
                    foreach (var v in r) { if (i < 12) m[i++] = (float)v.GetDouble(); }
                    if (i >= 12)
                        return new CFrame(px, py, pz, m[0], m[1], m[2], m[3], m[4], m[5], m[6], m[7], m[8], m[9], m[10], m[11]);
                }
                if (el.TryGetProperty("number", out var numEl))
#pragma warning disable CS0612
                    return BrickColor.FromNumber(numEl.GetInt32());
#pragma warning restore CS0612
                if (el.TryGetProperty("min", out var minEl) && el.TryGetProperty("max", out var maxEl))
                {
                    if (minEl.ValueKind == JsonValueKind.Number && maxEl.ValueKind == JsonValueKind.Number)
                        return new NumberRange((float)minEl.GetDouble(), (float)maxEl.GetDouble());
                    var min = DeserializeVector2(minEl);
                    var max = DeserializeVector2(maxEl);
                    if (min != null && max != null)
                        return new Rect(min, max);
                }
                if (el.TryGetProperty("origin", out var oEl) && el.TryGetProperty("direction", out var dEl))
                {
                    var origin = DeserializeVector3(oEl);
                    var direction = DeserializeVector3(dEl);
                    if (origin != null && direction != null)
                        return new Ray(origin, direction);
                }
                if (el.TryGetProperty("keypoints", out var kpEl))
                {
                    var arr = kpEl.EnumerateArray();
                    var list = new List<object>();
                    foreach (var k in arr)
                        list.Add(k);
                    if (list.Count >= 2)
                    {
                        if (list[0] is JsonElement je && je.TryGetProperty("value", out var v) && v.ValueKind == JsonValueKind.Object)
                        {
                            var keypoints = new List<ColorSequenceKeypoint>();
                            foreach (var k in kpEl.EnumerateArray())
                            {
                                var t = k.TryGetProperty("time", out var te) ? (float)te.GetDouble() : 0;
                                var env = k.TryGetProperty("envelope", out var ee) ? ee.GetInt32() : 0;
                                Color3 c = Color3.FromRGB(0, 0, 0);
                                if (k.TryGetProperty("value", out var ve) && ve.TryGetProperty("r", out var re))
                                    c = new Color3((float)re.GetDouble(), (float)ve.GetProperty("g").GetDouble(), (float)ve.GetProperty("b").GetDouble());
                                keypoints.Add(new ColorSequenceKeypoint(t, c, env));
                            }
                            return new ColorSequence(keypoints.ToArray());
                        }
                        var nkList = new List<NumberSequenceKeypoint>();
                        foreach (var k in kpEl.EnumerateArray())
                        {
                            var t = k.TryGetProperty("time", out var te) ? (float)te.GetDouble() : 0;
                            var val = k.TryGetProperty("value", out var ve) ? (float)ve.GetDouble() : 0;
                            var env = k.TryGetProperty("envelope", out var ee) ? (float)ee.GetDouble() : 0;
                            nkList.Add(new NumberSequenceKeypoint(t, val, env));
                        }
                        return new NumberSequence(nkList.ToArray());
                    }
                }
                if (el.TryGetProperty("density", out _))
                {
                    var density = el.TryGetProperty("density", out var de) ? (float)de.GetDouble() : 1f;
                    var friction = el.TryGetProperty("friction", out var fe) ? (float)fe.GetDouble() : 1f;
                    var elasticity = el.TryGetProperty("elasticity", out var ee) ? (float)ee.GetDouble() : 0.5f;
                    var fw = el.TryGetProperty("frictionWeight", out var fwe) ? (float)fwe.GetDouble() : 1f;
                    var ew = el.TryGetProperty("elasticityWeight", out var ewe) ? (float)ewe.GetDouble() : 1f;
                    var ac = el.TryGetProperty("acousticAbsorption", out var ace) ? (float)ace.GetDouble() : 1f;
                    return new PhysicalProperties(density, friction, elasticity, fw, ew, ac);
                }
            }

            if (el.ValueKind == JsonValueKind.String)
            {
                var s = el.GetString();
                if (prop.Type == PropertyType.String || prop.Name == "Source")
                    return new ProtectedString(s ?? "");
                return s;
            }
            if (el.ValueKind == JsonValueKind.Number)
            {
                if (el.TryGetInt32(out var i32))
                    return i32;
                if (el.TryGetInt64(out var i64))
                    return i64;
                return el.GetDouble();
            }
            if (el.ValueKind == JsonValueKind.True || el.ValueKind == JsonValueKind.False)
                return el.GetBoolean();

            return null;
        }

        private static object? DeserializeAttributeValue(JsonElement el)
        {
            if (el.ValueKind == JsonValueKind.Object)
            {
                if (el.TryGetProperty("Enum", out var e) && el.TryGetProperty("Value", out var v))
                {
                    var enumType = RobloxAssembly.GetType($"RobloxFiles.Enums.{e.GetString()}");
                    if (enumType != null && enumType.IsEnum)
                        return Enum.ToObject(enumType, v.GetUInt32());
                }
                if (el.TryGetProperty("x", out var xEl) && el.TryGetProperty("y", out var yEl) &&
                    xEl.ValueKind == JsonValueKind.Number && yEl.ValueKind == JsonValueKind.Number)
                {
                    if (el.TryGetProperty("z", out var zEl) && zEl.ValueKind == JsonValueKind.Number)
                        return new Vector3((float)xEl.GetDouble(), (float)yEl.GetDouble(), (float)zEl.GetDouble());
                    return new Vector2((float)xEl.GetDouble(), (float)yEl.GetDouble());
                }
                if (el.TryGetProperty("r", out var rEl) && el.TryGetProperty("g", out var gEl) && el.TryGetProperty("b", out var bEl))
                    return new Color3((float)rEl.GetDouble(), (float)gEl.GetDouble(), (float)bEl.GetDouble());
                if (el.TryGetProperty("x", out var ax) && el.TryGetProperty("y", out var ay) &&
                    ax.TryGetProperty("scale", out var sEl) && ax.TryGetProperty("offset", out var oEl))
                {
                    var ys = ay.TryGetProperty("scale", out var ysEl) ? (float)ysEl.GetDouble() : 0f;
                    var yo = ay.TryGetProperty("offset", out var yoEl) ? yoEl.GetInt32() : 0;
                    return new UDim2((float)sEl.GetDouble(), oEl.GetInt32(), ys, yo);
                }
                if (el.TryGetProperty("scale", out var sEl2) && el.TryGetProperty("offset", out var oEl2))
                    return new UDim((float)sEl2.GetDouble(), oEl2.GetInt32());
            }
            if (el.ValueKind == JsonValueKind.Number)
            {
                if (el.TryGetInt32(out var i))
                    return i;
                return (float)el.GetDouble();
            }
            if (el.ValueKind == JsonValueKind.True || el.ValueKind == JsonValueKind.False)
                return el.GetBoolean();
            if (el.ValueKind == JsonValueKind.String)
                return el.GetString();
            return null;
        }

        private static Vector3? DeserializeVector3(JsonElement el)
        {
            if (el.TryGetProperty("x", out var x) && el.TryGetProperty("y", out var y) && el.TryGetProperty("z", out var z))
                return new Vector3((float)x.GetDouble(), (float)y.GetDouble(), (float)z.GetDouble());
            return null;
        }

        private static Vector2? DeserializeVector2(JsonElement el)
        {
            if (el.TryGetProperty("x", out var x) && el.TryGetProperty("y", out var y))
                return new Vector2((float)x.GetDouble(), (float)y.GetDouble());
            return null;
        }
    }
}
