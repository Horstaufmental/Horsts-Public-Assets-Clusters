# Object Injection Feature

## Overview

The LuauExporter tool supports **object injection**, which allows you to inject scripts into specific descendants of imported `.rbxmx` files rather than having them become siblings.

## Use Case

Some scripts need to be placed deep within an RBXMX DOM structure. For example, `healthHandler.server.luau` must be injected into `Tag/Container/Health` within the `Tag.rbxmx` file, rather than being placed alongside the Tag as a sibling.

## Metadata Format

Create an `inject.json` file in the same directory as your `.rbxmx` file:

```json
{
  "inject": [
    {
      "target": "Tag/Container/Health",
      "type": "Script",
      "name": "HealthHandler",
      "source": "healthHandler.server.luau",
      "properties": {
        "Disabled": true
      }
    }
  ]
}
```

### Fields

- **`target`**: Path relative to the RBXMX root instance. Use forward slashes (`/`) to separate path components.
  - If the path starts with the root instance's name, it will be automatically handled (e.g., `Tag/Container/Health` works even though `Tag` is the root)
  
- **`type`**: The type of script to create. Valid values:
  - `"Script"` - Creates a Script instance
  - `"LocalScript"` - Creates a LocalScript instance
  - `"ModuleScript"` - Creates a ModuleScript instance

- **`name`**: The name of the injected script instance

- **`source`**: Path to the source file (relative to the directory containing `inject.json`)

- **`properties`** (optional): Additional properties to set on the injected instance
  - Currently supported properties:
    - `"Disabled"` (boolean) - For Script and LocalScript instances

## Behavior

1. **Injection Timing**: Injection occurs *after* loading the RBXMX DOM but *before* attaching it to the final model tree

2. **Error Handling**: 
   - Missing target paths are **fatal errors** - the build will fail
   - Missing source files are **fatal errors** - the build will fail

3. **Multiple Injections**: You can inject multiple scripts into different locations by adding more objects to the `inject` array

4. **Path Resolution**: The tool traverses the DOM by instance name to resolve the target path

5. **Instance Replacement**: If an instance with the same name already exists at the target location, it will be replaced with the injected instance

6. **Source File Exclusion**: Source files used for injection are automatically excluded from being processed as standalone modules

## Example

Given this RBXMX structure:
```
[BillboardGui] Tag
  [Frame] Container
    [Frame] Health
```

And this `inject.json`:
```json
{
  "inject": [
    {
      "target": "Tag/Container/Health",
      "type": "Script",
      "name": "HealthHandler",
      "source": "healthHandler.server.luau"
    }
  ]
}
```

The result will be:
```
[BillboardGui] Tag
  [Frame] Container
    [Frame] Health
      [Script] HealthHandler  ← Injected script with source from healthHandler.server.luau
```

## Notes

- The `inject.json` file is optional - if it doesn't exist, RBXMX files are loaded normally without injection
- Injected instances behave like normal scripts in the final model
- The injection metadata belongs to the directory containing the RBXMX file, not the global tool configuration
