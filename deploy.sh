#!/bin/bash
# adamos workstation — full deploy script
# Run: sudo bash deploy.sh
set -euo pipefail

RED='\033[0;31m'; GREEN='\033[0;32m'; BLUE='\033[0;34m'; NC='\033[0m'
info()  { echo -e "${BLUE}[INFO]${NC}  $*"; }
ok()    { echo -e "${GREEN}[ OK ]${NC}  $*"; }
fail()  { echo -e "${RED}[FAIL]${NC}  $*"; }

[ "$(id -u)" -ne 0 ] && { fail "Must run as root."; exit 1; }

ADAMOS_DIR="$(cd "$(dirname "$0")" && pwd)"
ADAM_USER="${SUDO_USER:-adam}"

info "1/8 — Adding Brave Origin Nightly repo"
curl -fsSL https://brave-browser-apt-release.s3.brave.com/brave-browser-archive-keyring.gpg | \
  gpg --dearmor -o /usr/share/keyrings/brave-browser.gpg 2>/dev/null
cat > /etc/apt/sources.list.d/brave-origin-nightly.list << 'APT'
deb [arch=amd64 signed-by=/usr/share/keyrings/brave-browser.gpg] https://brave-browser-apt-nightly.s3.brave.com/ stable main
APT

info "2/8 — Installing packages"
apt-get update -qq
apt-get install -y --no-install-recommends \
  brave-origin-nightly \
  kitty \
  picom \
  fastfetch \
  fonts-jetbrains-mono \
  neovim tmux htop curl git

info "3/8 — Applying adamos theme and wallpaper"
cp "$ADAMOS_DIR/wallpapers/adamos-wallpaper.png" /usr/share/backgrounds/
sudo -u "$ADAM_USER" gsettings set org.cinnamon.theme name "Orchis-Dark"
sudo -u "$ADAM_USER" gsettings set org.cinnamon.desktop.interface gtk-theme "Orchis-Dark"
sudo -u "$ADAM_USER" gsettings set org.cinnamon.desktop.interface icon-theme "Tela-circle-dark"
sudo -u "$ADAM_USER" gsettings set org.cinnamon.desktop.background picture-uri "file:///usr/share/backgrounds/adamos-wallpaper.png"
sudo -u "$ADAM_USER" gsettings set org.cinnamon.desktop.background picture-options "zoom"

info "4/8 — Setting kitty as default terminal"
update-alternatives --set x-terminal-emulator /usr/bin/kitty 2>/dev/null || true
sudo -u "$ADAM_USER" gsettings set org.cinnamon.desktop.default-applications.terminal exec "kitty"
sudo -u "$ADAM_USER" gsettings set org.cinnamon.desktop.default-applications.terminal exec-arg ""
ln -sf /usr/bin/kitty /usr/local/bin/cinnamon-terminal 2>/dev/null || true

info "5/8 — Configuring workspaces and keybindings"
sudo -u "$ADAM_USER" gsettings set org.cinnamon.desktop.wm.preferences num-workspaces 6
sudo -u "$ADAM_USER" gsettings set org.cinnamon.muffin dynamic-workspaces false
sudo -u "$ADAM_USER" gsettings set org.cinnamon.muffin edge-tiling true
sudo -u "$ADAM_USER" gsettings set org.cinnamon.muffin workspace-cycle true
sudo -u "$ADAM_USER" gsettings set org.cinnamon.desktop.keybindings.media-keys terminal "['<Super>t']"
sudo -u "$ADAM_USER" gsettings set org.cinnamon.desktop.keybindings.wm switch-to-workspace-1 "['<Super>1']"
sudo -u "$ADAM_USER" gsettings set org.cinnamon.desktop.keybindings.wm switch-to-workspace-2 "['<Super>2']"
sudo -u "$ADAM_USER" gsettings set org.cinnamon.desktop.keybindings.wm switch-to-workspace-3 "['<Super>3']"
sudo -u "$ADAM_USER" gsettings set org.cinnamon.desktop.keybindings.wm switch-to-workspace-4 "['<Super>4']"
sudo -u "$ADAM_USER" gsettings set org.cinnamon.desktop.keybindings.wm switch-to-workspace-5 "['<Super>5']"
sudo -u "$ADAM_USER" gsettings set org.cinnamon.desktop.keybindings.wm switch-to-workspace-6 "['<Super>6']"
sudo -u "$ADAM_USER" gsettings set org.cinnamon.desktop.keybindings.wm switch-to-workspace-left "['<Super>Left']"
sudo -u "$ADAM_USER" gsettings set org.cinnamon.desktop.keybindings.wm switch-to-workspace-right "['<Super>Right']"
sudo -u "$ADAM_USER" gsettings set org.cinnamon.desktop.keybindings.wm move-to-workspace-left "['<Shift><Super>Left']"
sudo -u "$ADAM_USER" gsettings set org.cinnamon.desktop.keybindings.wm move-to-workspace-right "['<Shift><Super>Right']"

info "6/8 — Setting Brave Origin Nightly as default browser"
sudo -u "$ADAM_USER" xdg-settings set default-web-browser brave-origin-nightly.desktop

info "7/8 — Installing kitty config"
mkdir -p "/home/$ADAM_USER/.config/kitty"
cp "$ADAMOS_DIR/config/kitty/kitty.conf" "/home/$ADAM_USER/.config/kitty/"
chown -R "$ADAM_USER:$ADAM_USER" "/home/$ADAM_USER/.config/kitty"

info "8/8 — Installing fastfetch config"
mkdir -p "/home/$ADAM_USER/.config/fastfetch"
cp "$ADAMOS_DIR/config/fastfetch/config.jsonc" "/home/$ADAM_USER/.config/fastfetch/"
chown -R "$ADAM_USER:$ADAM_USER" "/home/$ADAM_USER/.config/fastfetch"

info "9/9 — Installing adamos updater"
install -m0755 "$ADAMOS_DIR/updater/updater.sh" /usr/local/sbin/adamos-update.sh
install -m0755 "$ADAMOS_DIR/updater/adamos-maint-reboot.sh" /usr/local/sbin/adamos-maint-reboot.sh
cp "$ADAMOS_DIR/updater/systemd/"*.service "$ADAMOS_DIR/updater/systemd/"*.timer /etc/systemd/system/ 2>/dev/null || true
systemctl daemon-reload
systemctl enable --now adamos-update.timer 2>/dev/null || true

ok "adams deploy complete! Log out/in to see changes."

info " — Enabling /usr/local/sbin in sudo PATH"
echo 'Defaults secure_path="/usr/local/sbin:/usr/sbin:/usr/bin:/sbin:/bin"' > /etc/sudoers.d/adamos-path

info "9/9 — Configuring boot (plymouth + GRUB)"
# Install plymouth if not present
apt-get install -y --no-install-recommends plymouth plymouth-themes 2>/dev/null || true

# Install custom adamos boot logo
cp "$ADAMOS_DIR/boot/plymouth/logo.png" /usr/share/plymouth/themes/ceratopsian/logo.png

# Set plymouth theme
plymouth-set-default-theme ceratopsian 2>/dev/null || true

# Enable splash in GRUB
sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT="quiet"/GRUB_CMDLINE_LINUX_DEFAULT="quiet splash"/' /etc/default/grub
update-grub 2>/dev/null

# Update UEFI boot entry description
efibootmgr -B -b 0001 2>/dev/null || true
efibootmgr -c -d /dev/mmcblk0 -p 1 -L "adamos" -l '\EFI\debian\shimx64.efi' 2>/dev/null || true

update-initramfs -u 2>/dev/null

info " — Setting up window opacity shortcuts"
apt-get install -y --no-install-recommends x11-apps 2>/dev/null || true
sudo -u "$ADAM_USER" gsettings set org.cinnamon.desktop.keybindings.custom-keybinding:/org/cinnamon/desktop/keybindings/custom-keybindings/custom0/ name "Opacity 80%"
sudo -u "$ADAM_USER" gsettings set org.cinnamon.desktop.keybindings.custom-keybinding:/org/cinnamon/desktop/keybindings/custom-keybindings/custom0/ binding "['<Alt><Super>8']"
sudo -u "$ADAM_USER" gsettings set org.cinnamon.desktop.keybindings.custom-keybinding:/org/cinnamon/desktop/keybindings/custom-keybindings/custom0/ command "transset -a 0.8"
sudo -u "$ADAM_USER" gsettings set org.cinnamon.desktop.keybindings.custom-keybinding:/org/cinnamon/desktop/keybindings/custom-keybindings/custom1/ name "Opacity 60%"
sudo -u "$ADAM_USER" gsettings set org.cinnamon.desktop.keybindings.custom-keybinding:/org/cinnamon/desktop/keybindings/custom-keybindings/custom1/ binding "['<Alt><Super>6']"
sudo -u "$ADAM_USER" gsettings set org.cinnamon.desktop.keybindings.custom-keybinding:/org/cinnamon/desktop/keybindings/custom-keybindings/custom1/ command "transset -a 0.6"
sudo -u "$ADAM_USER" gsettings set org.cinnamon.desktop.keybindings.custom-keybinding:/org/cinnamon/desktop/keybindings/custom-keybindings/custom2/ name "Opacity 100%"
sudo -u "$ADAM_USER" gsettings set org.cinnamon.desktop.keybindings.custom-keybinding:/org/cinnamon/desktop/keybindings/custom-keybindings/custom2/ binding "['<Alt><Super>0']"
sudo -u "$ADAM_USER" gsettings set org.cinnamon.desktop.keybindings.custom-keybinding:/org/cinnamon/desktop/keybindings/custom-keybindings/custom2/ command "transset -a 1"
sudo -u "$ADAM_USER" gsettings set org.cinnamon.desktop.keybindings custom-list "['custom0', 'custom1', 'custom2']"
