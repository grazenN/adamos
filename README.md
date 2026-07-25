# adamos — Machine Inspired Workstation

A curated Debian-based Linux workstation configuration blending:

- **Debian** stability and package management
- **CachyOS** kernel performance optimizations
- **Omarchy** style, workflow, and aesthetics

## Components

| Layer | Choice | Rationale |
|-------|--------|-----------|
| Base | Debian Trixie (testing) | Stability + rolling-ish updates |
| Desktop | Cinnamon 6.6.8 | Traditional layout, mature, customizable |
| Theme | Orchis-Dark | Modern, rounded, dark aesthetic |
| Icons | Tela-circle-dark | Clean, minimal icon set |
| Kernel | Linux 7.1.3 (Debian) + CachyOS patches | Options below |
| Display | X11 (GDM3) | Stable, fully supported |
| Workflow | Keyboard-driven + horizontal workspaces | Omarchy-inspired |

## Repository Structure

```
adamos/
├── README.md          ← this file
├── config/
│   ├── dconf.sh       ← dconf/GSettings dump for Cinnamon
│   ├── gdm.conf       ← GDM greeter configuration
│   └── os-release     ← adamos OS identification
├── kernel/
│   └── build.sh       ← CachyOS-inspired kernel build script
├── wallpapers/
│   └── adamos-wallpaper.png
└── themes/            ← Included configs for Orchis, Tela, etc.
```

## Quick Install

```bash
# Clone and apply
git clone <repo-url> ~/adamos
cd ~/adamos
./config/dconf.sh
```

## Kernel Strategy

Two options for CachyOS-style performance:

1. **linux-psycachy** (prebuilt .deb) — easiest path
2. **Build from source** using cachyos-deb scripts — full control

## Workflow

- Super+1-6 — switch workspace
- Shift+Super+arrows — move window between workspaces
- Super+arrows — switch workspace left/right
- Hot corner top-left — Expo view (all workspaces)
- Edge tiling enabled — drag windows to edges
