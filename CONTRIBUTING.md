# Contributing to Horst's Public Assets Clusters

Thanks for your interest in contributing!

This document explains how to propose changes, work with the existing tooling, and keep contributions consistent across the repository.

---

## Code of Conduct

- Be respectful and constructive in all interactions.
- Focus feedback on code and documentation, not people.
- Assume good intent and be open to review and iteration.

If you are unsure about anything, feel free to open a draft pull request or start a discussion before doing large amounts of work.

---

## Repository Overview

This repo contains multiple assets and tools:

- **Roblox assets** (Luau + `.rbxmx`/`.rbxm` models) under `src/ASSETNAME/`
- **TempleOS / other utilities** (e.g. HolyC Apple) under `src/HolyCApple/`
- **CLI build tools and converters** under `tools/` (C# /.NET)
- **External libraries** as submodules under `extern/`

See `README.md` for a deeper overview before adding new assets or tools.

---

## Getting Started (Development Environment)

### Prerequisites

Depending on what you work on, you may need:

- **Roblox Studio** for Roblox assets
- **.NET SDK 10** (as documented in `README.md`) for building tools in `tools/`
- A modern C# IDE or editor (Visual Studio, Rider, VS Code) for `.cs` projects
- Git with submodules enabled (`--recurse-submodules`) when cloning

### Cloning

```bash
git clone --recurse-submodules https://github.com/Horstaufmental/Horsts-Public-Assets-Clusters.git
cd Horsts-Public-Assets-Clusters
```

If you forgot `--recurse-submodules`:

```bash
git submodule update --init --recursive
```

---

## Project Layout & Conventions

### Assets under `src/`

Each asset lives in its own directory:

- `src/ASSETNAME/README.md` — installation & usage docs for that asset
- `src/ASSETNAME/src/` — source files used for building/exporting
- Roblox assets typically mirror Roblox services:
  - `Plugins/`
  - `ServerScriptService/`
  - `StarterPlayer/`
  - `ReplicatedStorage/`

### Tools under `tools/`

- Tools are .NET console applications (e.g. `LuauExporter`)
- Prefer consistent CLI argument style (`--flag value` or `--flag=value`)
- Keep tool-specific docs either in the tool directory (e.g. `README.md`) or in the main `README.md` if broadly relevant

When updating `LuauExporter` or other tools, ensure:

- You do **not** break existing CLI usage documented in `README.md` without updating the docs
- The default behavior is safe for existing pipelines (e.g. sane defaults, clear error messages)

---

## Style Guidelines

### Luau / Lua

- Keep code **readable and self-documenting**; use meaningful variable and function names
- Prefer modules (`ModuleScript`) over large scripts when sharing code
- Use consistent indentation (spaces) and avoid mixing tabs/spaces in the same file
- Group related functions together and keep public API surface at the top where reasonable
- Use comments to explain *why* something is done in a non-obvious way, not to restate what the code already says

### C# (.NET tools)

- Follow standard C# conventions:
  - `PascalCase` for types and methods
  - `camelCase` for locals and parameters
  - `SCREAMING_SNAKE_CASE` for constants where appropriate
- Keep tools library-independent except for clearly justified dependencies (e.g. Roblox DOM libraries)
- Fail fast with clear error messages when inputs are invalid
- Log high-level build steps and any non-trivial decisions to `stdout`/`stderr` (as done in `LuauExporter`)

### Documentation

- Use Markdown (`.md`) for all docs
- Prefer short, focused sections with heading hierarchy (`#`, `##`, `###`)
- Include commands in fenced code blocks with appropriate language hints
- When introducing a new asset/tool, document:
  - What it does
  - How to install it
  - How to use it (basic examples)
  - Any notable limitations or caveats

---

## Licensing

This repository is licensed under **MPL-2.0** unless stated otherwise.

Key points (informal summary; the license text prevails):

- If you **modify an MPL-licensed file** and redistribute it, you must make the source of that *file* available.
- Your own projects that merely **use** these assets/tools are **not** required to be MPL-licensed.
- Some configuration files (e.g. certain `Config.luau` files) may have additional exceptions described in comments.

When contributing:

- Keep existing license headers intact in modified files.
- Do not remove or alter copyright notices.
- If you add new source files, include appropriate MPL-2.0 header comments if the surrounding code does so.

---

## Making Changes

### 1. Open an Issue (Recommended)

Before spending time on a non-trivial change, it’s recommended to:

- Open a GitHub issue describing the problem or feature
- Provide context, motivation, and (if applicable) screenshots or example use cases

This helps avoid duplicated work and ensures the change aligns with the project’s direction.

### 2. Create a Branch

```bash
git checkout -b feature/short-description
```

Use short, descriptive branch names (`feature/holyC-improvements`, `fix/nameranktitles-trello-error`, etc.).

### 3. Implement Your Changes

- Keep commits logically grouped and atomic where possible.
- Ensure code builds and runs locally:
  - For Roblox assets: verify in Roblox Studio/test place
  - For tools: run
    - `dotnet build --project tools/LuauExporter`
    - And/or `dotnet run --project tools/LuauExporter --tooldir <some/src>` as a smoke test

### 4. Update Documentation

- Update `README.md`, or asset-specific `README.md` if behavior, structure, or workflow changes.
- If you add a new asset, include it in any relevant index sections (e.g. "Current Assets").

### 5. Run Checks

There is no strict CI definition documented here yet, but you should at minimum:

- Ensure there are **no compile errors** in C# projects (`dotnet build`)
- Open and run the modified Roblox assets in Studio to check for runtime errors
- Run any asset-specific scripts or tests if they exist

If you add new checks (e.g. scripts under `.github/` or `tools/`), document them.

### 6. Submit a Pull Request

When opening a PR:

- Use a clear title ("Fix Trello error handling in NameRankTitles" rather than "misc fixes")
- In the description, include:
  - What you changed
  - Why you changed it
  - How you tested it
- If your change is large or potentially breaking, mark it clearly and describe migration steps if relevant.

---

## Versioning & Releases

Assets are versioned using tags of the form:

- `NameRankTitles-vX.Y.Z`
- `RankTitlesUtils-vX.Y.Z`
- Other assets follow `AssetName-vX.Y.Z` where applicable

Guidelines:

- Do **not** create tags yourself unless explicitly agreed upon.
- If your change is user-visible, suggest an appropriate version bump (patch / minor / major) in the PR description.
- Keep changelog notes in PRs so they can be aggregated into release notes later.

---

## Adding New Assets or Tools

When proposing a **new asset**:

1. Add it under `src/YourAssetName/`.
2. Provide a clear README with installation and usage.
3. Follow the existing asset layout and naming conventions.

When proposing a **new tool** under `tools/`:

1. Place it in `tools/ToolName/` as a .NET console app.
2. Add a short README and/or extend the main `README.md` with usage examples.
3. Keep external dependencies minimal and justified.

---

## Questions & Support

If you’re unsure about anything:

- Open an issue with your questions and ideas.
- Or start a draft PR to get early feedback on direction and structure.

Thanks again for contributing and helping improve this project!