# IP Switch

English | [中文](README_CN.md)

A macOS menu bar application for quickly switching network interface IP configurations. Built with SwiftUI and designed with Apple's glass morphism aesthetic.

## Features

### Network Interface Management
- Automatically detects all network interfaces (Wi-Fi, Ethernet, USB adapters, Thunderbolt, etc.)
- Displays real-time status: IP address, subnet mask, router, DNS servers
- Supports both DHCP (automatic) and manual IP configuration
- One-click DHCP toggle for any interface
- Hot-plug detection — refresh to discover newly connected adapters

### Configuration Profiles
- Save current interface settings as reusable profiles
- Create custom profiles with specific IP/subnet/router/DNS values
- Choose from 10 icons for easy visual identification
- One-click profile application from the menu bar
- Applied profile indicator with green badge
- Edit, delete, and manage profiles with context menus

### Menu Bar Quick Switch
- Native macOS menu bar dropdown for instant access
- View all interface status at a glance
- Switch between saved profiles without opening the main window
- Keyboard shortcuts: `⌘R` refresh, `⌘,` settings, `⌘Q` quit

### Permanent Authorization
- One-time admin password setup via sudoers rule
- After authorization, all IP switches happen instantly without password prompts
- Revokable at any time from the settings sidebar
- Falls back to per-action admin prompt if not authorized

### Bilingual Interface
- Full English and Chinese (中文) localization
- Runtime language switching — no restart required
- Language preference persisted across sessions

### Smart Dock Behavior
- Runs as a menu bar app by default (no Dock icon)
- Dock icon appears when the settings window is open
- Dock icon hides automatically when the window is closed

## Screenshots

| Main Window | Menu Bar |
|:-----------:|:--------:|
| NavigationSplitView with interface details and glass cards | Native dropdown with quick profile switching |

## Requirements

- macOS 26.0 or later
- Xcode 26.0 or later (for building from source)

## Installation

### Build from Source

```bash
git clone https://github.com/ryanhe919/IP-Switch.git
cd IP-Switch
open IP-Switch.xcodeproj
```

Then build and run with `⌘R` in Xcode.

### First Run Setup

1. Launch the app — it appears as an icon in the menu bar
2. Click the menu bar icon → **Settings** to open the main window
3. (Optional) Click **Grant Permanent Access** in the Authorization section to enable password-free switching

## Architecture

```
IP-Switch/
├── IP_SwitchApp.swift              # App entry, MenuBarExtra, Dock behavior
├── Models/
│   ├── NetworkInterface.swift      # Network interface data model
│   └── IPProfile.swift             # IP configuration profile model
├── Services/
│   ├── NetworkService.swift        # networksetup commands, sudo/AppleScript
│   └── LocalizationManager.swift   # EN/CN bilingual runtime localization
├── ViewModels/
│   └── NetworkViewModel.swift      # Business logic, profile CRUD, auth management
├── Views/
│   ├── ContentView.swift           # Main window (NavigationSplitView)
│   ├── MenuBarView.swift           # Menu bar dropdown
│   ├── ProfileEditView.swift       # Profile create/edit sheet
│   └── Components/
│       └── GlassCard.swift         # Glass morphism UI components
└── Assets.xcassets/                # App icons and colors
```

### Key Design Decisions

| Decision | Rationale |
|----------|-----------|
| `networksetup` CLI | Apple's official tool for network config; no private APIs |
| sudoers.d rule | Permanent NOPASSWD for `networksetup` only; scoped and revokable |
| AppleScript fallback | Graceful degradation when sudoers not installed |
| `@Observable` macro | Modern SwiftUI state management (macOS 14+) |
| UserDefaults persistence | Lightweight storage for profiles and preferences |
| No external dependencies | Pure native Swift — no CocoaPods, SPM, or third-party packages |

## How It Works

### Network Detection
The app runs `networksetup -listallhardwareports` to discover all interfaces, then queries each with `networksetup -getinfo <service>` and `networksetup -getdnsservers <service>` to populate current configuration.

### IP Configuration
- **DHCP**: `sudo networksetup -setdhcp "<service>"`
- **Manual IP**: `sudo networksetup -setmanual "<service>" <ip> <subnet> <router>`
- **DNS**: `sudo networksetup -setdnsservers "<service>" <dns1> <dns2> ...`

### Authorization
When permanent access is granted, the app installs a sudoers rule:
```
<username> ALL=(root) NOPASSWD: /usr/sbin/networksetup
```
This file is placed at `/etc/sudoers.d/ip-switch` with `0440` permissions. It can be removed at any time via the app or manually with `sudo rm /etc/sudoers.d/ip-switch`.

## License

This project is licensed under the MIT License — see the [LICENSE](LICENSE) file for details.

## Author

**Yufan He** — [@ryanhe919](https://github.com/ryanhe919)
