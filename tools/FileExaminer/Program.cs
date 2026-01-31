/*
 * Simple program to examine the structure of a Roblox .rbxm file using the RobloxFileFormat library
 */

using System;
using System.IO;
using RobloxFiles;

namespace FileExaminer
{
    internal static class Program
    {
        static int Main(string[] args)
        {
            if (args.Length == 0)
            {
                Console.WriteLine("Usage: FileExaminer <file_path.rbxm | file_path.rbxmx>");
                Console.WriteLine("   or: FileExaminer --file <file_path.rbxm | file_path.rbxmx>");
                return 1;
            }

            string filePath = "";

            // Parse command-line arguments
            if (args.Length >= 2 && (args[0] == "--file" || args[0] == "-f"))
            {
                filePath = args[1];
            }
            else
            {
                filePath = args[0];
            }

            if (!File.Exists(filePath))
            {
                Console.Error.WriteLine($"Error: File not found: {filePath}");
                return 1;
            }

            try
            {
                Console.WriteLine($"Examining file: {filePath}");
                Console.WriteLine(new string('=', 60));

                var bytes = File.ReadAllBytes(filePath);
                Console.WriteLine($"File size: {bytes.Length} bytes");
                
                var file = RobloxFile.Open(bytes);
                Console.WriteLine($"File type: {file.GetType().Name}");
                Console.WriteLine($"Children count: {file.Children.Count}");
                Console.WriteLine();

                foreach (var child in file.Children)
                {
                    PrintInstanceTree(child, 0);
                }

                return 0;
            }
            catch (Exception ex)
            {
                Console.Error.WriteLine($"Error: {ex.Message}");
                Console.Error.WriteLine(ex.StackTrace);
                return 1;
            }
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
    }
}