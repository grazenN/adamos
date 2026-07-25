# updater

Safe, schedulable system updater for the **adamos** Debian 13 server.

Started life as an interactive desktop update script; rewritten to run headless on a
server packed with always-on services (Onyx, Nextcloud, media stack, Gitea, Vaultwarden,
the OAM knowledge-graph extraction, etc.).

## Files
- `updater.sh` -> installed on adamos as `/usr/local/sbin/adamos-update.sh`
- `adamos-maint-reboot.sh` -> guarded monthly reboot (only if a kernel is pending, and
  only after any in-progress update has finished). Installed as
  `/usr/local/sbin/adamos-maint-reboot.sh`
- `systemd/` -> the timers + services that schedule it

## Behaviour
Runs two ways:
- **Interactive (TTY):** shows `fastfetch`, offers reboot / shutdown / continue
- **Non-interactive (systemd timer):** logs only, no prompt, **never auto-reboots**

Each run: `apt update` -> `apt upgrade` (or `--full` for `full-upgrade`) ->
`autoremove --purge` -> `autoclean` -> `flatpak update` -> `snap refresh` ->
kernel/reboot detection. Keeps existing configs (`--force-confold`), single-instance
`flock`, logs to `/var/log/adamos-update/` (last 20 kept).

## Schedule (systemd, on adamos)
- `adamos-update.timer` — **Saturday 05:30**, the weekly sweep
- `adamos-maint-reboot.timer` — **first Saturday 05:45**, reboots *only* if a kernel is pending

Security patches are handled separately and **daily** by `unattended-upgrades`; this script
is the broader weekly sweep, deliberately scheduled clear of the OAM extraction windows.

## Manual use
    sudo adamos-update.sh          # standard sweep, with interactive prompt
    sudo adamos-update.sh --full   # include full-upgrade (kernels)
    sudo adamos-update.sh --quiet  # minimal output (used by the timer)

## Install on a fresh box
    sudo install -m0755 updater.sh /usr/local/sbin/adamos-update.sh
    sudo install -m0755 adamos-maint-reboot.sh /usr/local/sbin/adamos-maint-reboot.sh
    sudo cp systemd/* /etc/systemd/system/
    sudo systemctl daemon-reload
    sudo systemctl enable --now adamos-update.timer adamos-maint-reboot.timer
