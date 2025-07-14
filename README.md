RetroArchive
============

RetroArchive is a modular PowerShell-based toolkit designed to manage, convert, 
and archive ROMs and game files for retro gaming systems. It supports both CHD-
based systems (like PSX, Saturn) and simpler ROM-based systems (like NES, SNES).

------------------------------------------------------------

Project Structure
-----------------

RetroArchive/
│
├── archive/           - Output folder for processed files
├── config/
│   ├── settings.json  - Main global settings file
│   └── systems/       - Folder for per-system config files (empty for now)
├── inbound/           - Incoming ROMs and game files
├── logs/              - Log files (optional, used later)
├── scripts/
│   ├── setup.ps1      - Creates required folders
│   └── read-config.ps1- Loads the main config
├── tools/             - External tools (chdman.exe, 7z.exe)
├── RetroArchive.ps1   - Main entry point script
└── README.txt         - This file

------------------------------------------------------------

Current Features
----------------

- Verifies and creates required folders
- Loads settings from config/settings.json
- Detects or creates a roms folder one level up or locally
- Portable design using relative paths
- Easy to expand for additional systems or tools

------------------------------------------------------------

How To Use
----------

1. Clone or download this folder
2. Open PowerShell and run:

   ./RetroArchive.ps1

This will:
- Ensure all folders are set up
- Load and resolve config paths
- Prepare the system for use

------------------------------------------------------------

Config File (config/settings.json)
----------------------------------

Example config file:

{
  "paths": {
    "roms": "../roms",
    "inbound": "inbound",
    "archive": "archive",
    "tools": "tools",
    "logs": "logs",
    "chdmanExe": "tools/chdman.exe",
    "sevenZipExe": "tools/7z.exe"
  }
}

------------------------------------------------------------

Planned Features
----------------

- System-specific conversion rules (PSX, NES, SNES, etc.)
- Multi-disc game detection
- Game scanning and metadata support
- ROM hashing/validation
- Auto-script updating from GitHub

------------------------------------------------------------

License
-------

MIT License (or change to your preferred license)

------------------------------------------------------------

