# py_collisiondetector | made by Python (dc: python.gg)

## Overview

py_collisiondetector is a standalone, server-side FiveM resource that scans all loaded resources for duplicated GTA asset filenames that can cause MLO, collision, and map loading issues.

The script recursively scans resource directories and reports filename collisions across resources directly in the server console.

This resource is partially made with AI and intended for **developers and server owners** who work with many MLOs, map packs, or custom assets and want a fast way to detect conflicts.

**Note:** This script is intended for debugging purposes only and should be used by developers or server owners with full access to a localhost or Windows server. If you do not meet these requirements or do not intend to use the script, set Config.Enabled to false.

---

## What It Detects

py_collisiondetector scans for duplicate filenames of the following GTA asset types:

- `.ymap` – MLOs / map files
- `.ydr` – Props / models
- `.ybn` – Collision files
- `.ytyp` – Archetype definitions

Only files located in the following folders are scanned:

- `stream/`
- `maps/`

All script files (`.lua`, `.js`, etc.) are ignored.

---

## Why This Is Important

When multiple resources contain files with the same name:

- GTA will only load **one** of them
- Load order is unpredictable
- This can result in:

  - Missing interiors
  - Invisible walls or floors
  - Broken MLOs
  - Players getting stuck

py_collisiondetector helps identify these problems early by clearly listing all conflicting files.

---

## How It Works

- Runs automatically when the resource starts
- Waits briefly to ensure all resources are loaded
- Recursively scans all resources on disk
- Groups files by filename (case-insensitive)
- Logs duplicates with resource name and relative path

No client-side code is used.

---

## Installation

1. Place the `py_collisiondetector` folder in your server's `resources` directory
2. Add the following line to your `server.cfg`:

```
ensure py_collisiondetector
```

3. Start or restart your server

---

## Example Console Output

```
[CollisionChecker] COLLISION DETECTED: hei_kt1_rd.ymap
  → resource_one | stream/hei_kt1/hei_kt1_rd.ymap
  → resource_two | stream/maps/hei_kt1_rd.ymap
```

---

## Limitations

- Detects filename collisions only (not physical world overlap)
- Does not calculate file hashes
- Does not determine which file GTA will load

Despite these limitations, filename duplication is the most common cause of MLO and collision issues.

---

## Compatibility

- Works on both Linux and Windows servers
- Compatible with all FiveM frameworks
- Server-side only

---

## Contributions

Pull requests and improvements are welcome.
Feel free to extend the script with commands, exports or hash-based detection.
