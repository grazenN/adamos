#!/bin/bash
# adamos Cinnamon configuration restore script

echo "Applying adamos Cinnamon configuration..."

# Theme
gsettings set org.cinnamon.theme name "Orchis-Dark"
gsettings set org.cinnamon.desktop.interface gtk-theme "Orchis-Dark"
gsettings set org.cinnamon.desktop.interface icon-theme "Tela-circle-dark"
gsettings set org.cinnamon.desktop.background picture-uri "file:///usr/share/backgrounds/adamos-wallpaper.png"

# Workspaces
gsettings set org.cinnamon.desktop.wm.preferences num-workspaces 6
gsettings set org.cinnamon.muffin dynamic-workspaces false
gsettings set org.cinnamon.muffin edge-tiling true
gsettings set org.cinnamon.muffin workspace-cycle true
gsettings set org.cinnamon.desktop.wm.preferences focus-mode 'sloppy'

# Keybindings (Omarchy-inspired)
gsettings set org.cinnamon.desktop.keybindings.wm switch-to-workspace-1 "['<Super>1']"
gsettings set org.cinnamon.desktop.keybindings.wm switch-to-workspace-2 "['<Super>2']"
gsettings set org.cinnamon.desktop.keybindings.wm switch-to-workspace-3 "['<Super>3']"
gsettings set org.cinnamon.desktop.keybindings.wm switch-to-workspace-4 "['<Super>4']"
gsettings set org.cinnamon.desktop.keybindings.wm switch-to-workspace-5 "['<Super>5']"
gsettings set org.cinnamon.desktop.keybindings.wm switch-to-workspace-6 "['<Super>6']"
gsettings set org.cinnamon.desktop.keybindings.wm switch-to-workspace-left "['<Super>Left','<Control><Alt>Left']"
gsettings set org.cinnamon.desktop.keybindings.wm switch-to-workspace-right "['<Super>Right','<Control><Alt>Right']"
gsettings set org.cinnamon.desktop.keybindings.wm move-to-workspace-left "['<Shift><Super>Left','<Control><Shift><Alt>Left']"
gsettings set org.cinnamon.desktop.keybindings.wm move-to-workspace-right "['<Shift><Super>Right','<Control><Shift><Alt>Right']"

# Hot corners
gsettings set org.cinnamon hotcorner-layout "['expo:true:0:0', 'scale:false:0:0', 'scale:false:0:0', 'desklet:false:0:0']"

# Panel
gsettings set org.cinnamon panels-enabled "['1:0:bottom']"

echo "Done. Log out and back in for full effect."
