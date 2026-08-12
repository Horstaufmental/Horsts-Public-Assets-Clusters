<div align="left">
    <picture>
        <img src="https://media.githubusercontent.com/media/Horstaufmental/Horsts-Public-Assets-Clusters/refs/heads/main/misc/HPAC_Full.png" width="90%">
    </picture>
</div>

# Horst's Public Assets Clusters

where i houses most of my assets for free public release that i've made/modified over my time in programming career

# Installation

> [!NOTE]
> For developers who wanted to build from source, check [Build from Source](#build-from-source).

Each asset versions will have their own corresponding tags (e.g. NameRankTitles-v1.0.0), which can you use to navigate and find your desired target, which can be accessed [here.](https://github.com/Horstaufmental/Horsts-Public-Assets-Clusters/tags)

**NOTE:** Only the binaries for the latest versions will be available, you'll have to download the source file from a specific tag then set them up yourself if you wanted to use a older version.

Every asset will have an Installation guide (both in the source tree and the file) usually in a form of a markdown document.

The source code of each asset is available in `src/ASSETNAME/src/`

# Build from Source

## Roblox Assets (Luau)

The building process are automated by `LuauExporter`, a CLI tool written in C#.

`LuauExporter` depends on a [fork](https://github.com/Horstaufmental/Roblox-File-Format) of MaximumADHD's [Roblox-File-Format](https://github.com/MaximumADHD/Roblox-File-Format) for creating and manipulating
Roblox DOM files (`.rbxm`, `.rbxmx`, etc).

### Prerequisites

- [.NET SDK 10](https://dotnet.microsoft.com/en-us/download)

### Instructions

#### CLI (dotnet)

1. Clone the repository
```bash
git clone --recurse-submodules https://github.com/Horstaufmental/Horsts-Public-Assets-Clusters.git
```

2. Compile the tool in `tools/LuauExporter`
```bash
# Assuming you're in the repository root
dotnet build --project tools/LuauExporter
```

3. If everything goes smooth, run the tool to build the asset
```bash
# Syntax: LuauExporter --tooldir <DIR/src> [--out <FILE>]
# If `--out` is omitted, the output file will be named
# in "{NAME}-v{VERSION}" format.

# Example: NameRankTitles (without --out)

dotnet run --project tools/LuauExporter --tooldir src/NameRankTitles/src
# Outputs "NameRankTitles-v1.4.0.rbxm"

#-------------------------------------#
# Example: RankTitlesUtils (with --out)

dotnet run --project tools/LuauExporter --tooldir src/RankTitlesUtils/src --out "Utils.rbxm"
# Outputs "Utils.rbxm"
```

Files are outputted in the same directory as where the command was ran.

In this case, it will be in the repository root.

```
Horsts-Public-Assets-Clusters
├── extern/
├── src/
├── tools/
├── ...
└── Utils.rbxm <-- our file!
```

## Others

Build instructions will be provided under the asset's respective `README.md`,
with their own set of dependencies.

# License

All assets, unless explicitly told otherwise are licensed under the [MPL-2.0, Mozilla Public License Version 2.0.](/LICENSE)

You are free to:

- Use, modify, and include in any project.

- If you redistribute an MPL-licensed file that you’ve changed, you must provide the modified source for that file.
  
- No obligation applies to your own code or assets that simply use or interact with MPL files.
