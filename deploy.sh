#!/bin/bash
# adamos workstation — deploy from bundle
# Run this on a fresh Debian Trixie install

set -euo pipefail

echo "=== adamos workstation deploy ==="

# 1. Restore config repo
if [ -f adamos.bundle ]; then
  git clone adamos.bundle ~/adamos
fi

# 2. Apply dconf/gsettings
bash ~/adamos/config/dconf.sh

# 3. Copy os-release
sudo cp ~/adamos/config/os-release /etc/os-release

# 4. Copy GDM config
sudo cp ~/adamos/config/gdm.conf /etc/gdm3/greeter.dconf-defaults

# 5. Install wallpaper
sudo cp ~/adamos/wallpapers/adamos-wallpaper.png /usr/share/backgrounds/

# 6. Set hostname
sudo hostnamectl set-hostname adamos

echo "=== Done! Reboot for GDM changes ==="
