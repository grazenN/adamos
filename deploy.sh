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
install -m0644 "$ADAMOS_DIR/config/brave-browser.gpg" /usr/share/keyrings/ 2>/dev/null || true
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
  fonts-jetbrains-mono \
  neovim tmux htop curl git

info "3/8 — Applying theme"
sudo -u "$ADAM_USER" gsettings set org.cinnamon.theme name "Orchis-Dark"
sudo -u "$ADAM_USER" gsettings set org.cinnamon.desktop.interface gtk-theme "Orchis-Dark"
sudo -u "$ADAM_USER" gsettings set org.cinnamon.desktop.interface icon-theme "Tela-circle-dark"
sudo -u "$ADAM_USER" gsettings set org.cinnamon.desktop.background picture-uri "file:///usr/share/backgrounds/adamos-wallpaper.png"
sudo -u "$ADAM_USER" gsettings set org.cinnamon.desktop.background picture-options "zoom"

info "4/8 — Setting kitty as default terminal"
update-alternatives --set x-terminal-emulator /usr/bin/kitty
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
update-alternatives --set x-www-browser /usr/bin/brave-origin-nightly 2>/dev/null || true

info "7/8 — Installing kitty config"
mkdir -p "/home/$ADAM_USER/.config/kitty"
cp "$ADAMOS_DIR/config/kitty/kitty.conf" "/home/$ADAM_USER/.config/kitty/"
chown -R "$ADAM_USER:$ADAM_USER" "/home/$ADAM_USER/.config/kitty"

info "8/8 — Installing adamos updater"
install -m0755 "$ADAMOS_DIR/updater/updater.sh" /usr/local/sbin/adamos-update.sh
install -m0755 "$ADAMOS_DIR/updater/adamos-maint-reboot.sh" /usr/local/sbin/adamos-maint-reboot.sh
cp "$ADAMOS_DIR/updater/systemd/"*.service "$ADAMOS_DIR/updater/systemd/"*.timer /etc/systemd/system/ 2>/dev/null || true
systemctl daemon-reload
systemctl enable --now adamos-update.timer adamos-maint-reboot.timer 2>/dev/null || true

ok "adamos deploy complete! Log out/in to see changes."
