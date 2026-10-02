#!/bin/bash
# migrateArchAutoUpdate.sh
# One-time fix-up for remote dev boxes (see archRemoteSetup.sh) provisioned
# before the auto-update timer pinned its service to root. The old
# arch-auto-update.service had no `User=root` and the old arch-auto-update.sh
# had no root check, relying on systemd's implicit default for system units;
# if anything ever ran the script without root (manual testing, an unusual
# systemd default) it failed with pacman's "you cannot perform this operation
# unless you are root". This stops the old timer, redeploys the current
# script/service/timer (same content archRemoteSetup.sh's install_auto_updates
# would write — keep the two in sync), and re-enables it.
#
# Safe to run repeatedly: a box already on the fixed version is left alone.
# A box with no auto-update timer installed at all has nothing to migrate;
# run archRemoteSetup.sh's user stage instead to set one up from scratch.
#
# Usage, as root on the remote box:
#   bash migrateArchAutoUpdate.sh [--dry-run] [--target-user <name>]
#
# --target-user is normally unnecessary: it's recovered from the
# `runuser -l '<user>'` calls already embedded in the installed script. Pass
# it explicitly only if that recovery fails (e.g. a hand-edited script).

set -euo pipefail

SCRIPT_PATH=/usr/local/bin/arch-auto-update.sh
SERVICE_PATH=/etc/systemd/system/arch-auto-update.service
TIMER_PATH=/etc/systemd/system/arch-auto-update.timer

DRY_RUN=false
TARGET_USER=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --dry-run) DRY_RUN=true; shift ;;
        --target-user)
            [[ -n "${2:-}" ]] || { echo "Error: --target-user requires a name"; exit 1; }
            TARGET_USER="$2"; shift 2 ;;
        -h|--help) sed -n '2,/^$/{s/^# \{0,1\}//;p}' "$0"; exit 0 ;;
        *) echo "Unknown argument: $1"; exit 1 ;;
    esac
done

log()  { printf '\033[1;32m▶\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m!\033[0m %s\n' "$*" >&2; }
die()  { printf '\033[1;31m✗\033[0m %s\n' "$*" >&2; exit 1; }
run() {
    if $DRY_RUN; then
        echo "  [dry-run] $*"
    else
        "$@"
    fi
}

[[ -f /etc/arch-release ]] || die "This script targets Arch Linux (/etc/arch-release is missing)."
[[ $EUID -eq 0 ]] || die "Run this as root (it rewrites /etc/systemd/system units): sudo bash $0"

if [[ ! -f "$SCRIPT_PATH" && ! -f "$SERVICE_PATH" ]]; then
    die "No auto-update timer installed (no $SCRIPT_PATH or $SERVICE_PATH); nothing to migrate. Run archRemoteSetup.sh's user stage to set one up."
fi

if [[ -z "$TARGET_USER" && -f "$SCRIPT_PATH" ]]; then
    TARGET_USER=$(grep -oP "runuser -l '\K[^']+" "$SCRIPT_PATH" | head -n1 || true)
fi
[[ -n "$TARGET_USER" ]] || die "Couldn't determine the dev user from $SCRIPT_PATH; pass --target-user <name>."
id "$TARGET_USER" &>/dev/null || die "User '$TARGET_USER' doesn't exist on this box."

# Already on the fixed version: User=root in the service and the root check in
# the script. Content otherwise identical to install_auto_updates() just means
# a prior run of archRemoteSetup.sh already self-healed it; nothing to do.
if [[ -f "$SERVICE_PATH" ]] && grep -qx 'User=root' "$SERVICE_PATH" \
    && [[ -f "$SCRIPT_PATH" ]] && grep -q 'EUID -ne 0' "$SCRIPT_PATH"; then
    log "arch-auto-update is already on the fixed (root-enforced) version; nothing to migrate."
    exit 0
fi

log "Migrating arch-auto-update for user '$TARGET_USER' to the root-enforced version"

tmp_script=$(mktemp)
cat > "$tmp_script" << 'EOF'
#!/bin/bash
# Written by DotFiles/archRemoteSetup.sh. Must run as root (the
# arch-auto-update.service unit pins User=root); AUR updates and the Claude
# Code check run as __TARGET_USER__ via runuser.
set -euo pipefail

if [[ $EUID -ne 0 ]]; then
    echo "arch-auto-update.sh must run as root (it's meant to run via" \
         "arch-auto-update.service, e.g. 'sudo systemctl start arch-auto-update.service')" >&2
    exit 1
fi

pacman -Syu --noconfirm
if runuser -l '__TARGET_USER__' -c 'command -v yay' &>/dev/null; then
    runuser -l '__TARGET_USER__' -c 'yay -Syu --noconfirm'
fi
command -v paccache &>/dev/null && paccache -rk2

# Reboot into a newer kernel automatically, but only when it's safe: nobody
# logged in, and no Claude Code agent running (mid-edit or mid-plan) for
# __TARGET_USER__. Arch has no live-patching feed for its rolling kernel
# (kpatch needs a hand-built patch per kernel build), so this is the
# "no restarts needed" story instead: unattended, but deferred while in use.
# A skipped reboot is retried at the next Mon/Wed/Sat window.
running_kernel=$(uname -r)
installed_kernel=$(file -b /boot/vmlinuz-linux 2>/dev/null | grep -oP 'version \K\S+' || true)
if [[ -n "$installed_kernel" && "$installed_kernel" != "$running_kernel" ]]; then
    if [[ -n "$(who)" ]]; then
        logger -t arch-auto-update "Kernel update pending ($running_kernel -> $installed_kernel) but users are logged in; deferring reboot"
    elif runuser -l '__TARGET_USER__' -c 'pgrep -f claude' &>/dev/null; then
        logger -t arch-auto-update "Kernel update pending ($running_kernel -> $installed_kernel) but Claude Code is running; deferring reboot"
    else
        logger -t arch-auto-update "Kernel update pending ($running_kernel -> $installed_kernel); no active users or Claude Code sessions, rebooting"
        systemctl reboot
    fi
fi
exit 0
EOF
sed -i "s/__TARGET_USER__/$TARGET_USER/g" "$tmp_script"

tmp_service=$(mktemp)
cat > "$tmp_service" << 'EOF'
[Unit]
Description=Arch Linux system update (pacman + AUR)
Wants=network-online.target
After=network-online.target

[Service]
Type=oneshot
User=root
ExecStart=/usr/local/bin/arch-auto-update.sh
EOF

tmp_timer=$(mktemp)
cat > "$tmp_timer" << 'EOF'
[Unit]
Description=Run arch-auto-update.service Mon/Wed/Sat at 03:00

[Timer]
OnCalendar=Mon,Wed,Sat 03:00:00
Persistent=true

[Install]
WantedBy=timers.target
EOF

if $DRY_RUN; then
    echo "  [dry-run] stop+disable the old timer"
    echo "  [dry-run] back up existing $SCRIPT_PATH/$SERVICE_PATH/$TIMER_PATH to .bak"
    echo "  [dry-run] write the fixed script/service/timer, daemon-reload, reset-failed, re-enable"
    rm -f "$tmp_script" "$tmp_service" "$tmp_timer"
    exit 0
fi

log "Stopping the old timer"
systemctl stop arch-auto-update.timer 2>/dev/null || true
systemctl disable arch-auto-update.timer 2>/dev/null || true

log "Backing up the old files (.bak)"
for f in "$SCRIPT_PATH" "$SERVICE_PATH" "$TIMER_PATH"; do
    [[ -f "$f" ]] && cp -a "$f" "$f.bak"
done

install -m 755 "$tmp_script" "$SCRIPT_PATH"
install -m 644 "$tmp_service" "$SERVICE_PATH"
install -m 644 "$tmp_timer" "$TIMER_PATH"
rm -f "$tmp_script" "$tmp_service" "$tmp_timer"

systemctl daemon-reload
# Clears any "failed" state left by the old script erroring out under root's
# implicit default, if that's what actually happened on this box.
systemctl reset-failed arch-auto-update.service arch-auto-update.timer 2>/dev/null || true
systemctl enable --now arch-auto-update.timer

echo ""
echo "✓ Migrated. Old files kept as *.bak next to their originals."
echo "  Verify with: systemctl status arch-auto-update.timer"
