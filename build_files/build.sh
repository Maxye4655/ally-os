#!/bin/bash

set -eoux pipefail

# 1. Lay down image config files (usr/..., etc.)
cp -avf "/ctx/system_files"/. /

# 2. Deploy Ally OS into the user skeleton so every new user gets a
#    full, editable copy under ~/.config/hypr/.
mkdir -p /etc/skel/.config/hypr
cp -avf /ctx/config /ctx/scripts /ctx/services /ctx/hyprland.conf /etc/skel/.config/hypr/

### Install packages

# hyprland/hyprlock were retired from Fedora after F42, so on the F43-based
# Bazzite image they (plus wvkbd) come from COPRs.
REL=$(. /etc/os-release; printf '%s' "${VERSION_ID%%.*}")
test -n "$REL" || { echo "!! could not detect Fedora release" >&2; exit 1; }
curl -fsSL \
  "https://copr.fedorainfracloud.org/coprs/nett00n/hyprland/repo/fedora-${REL}/nett00n-hyprland-fedora-${REL}.repo" \
  -o /etc/yum.repos.d/_copr_nett00n-hyprland.repo
curl -fsSL \
  "https://copr.fedorainfracloud.org/coprs/fed500/wvkbd/repo/fedora-${REL}/fed500-wvkbd-fedora-${REL}.repo" \
  -o /etc/yum.repos.d/_copr_fed500-wvkbd.repo

# Packages can be installed from any enabled yum repo on the image.
# RPMfusion repos are available by default in ublue main images
# List of rpmfusion packages can be found here:
# https://mirrors.rpmfusion.org/mirrorlist?path=free/fedora/updates/43/x86_64/repoview/index.html&protocol=https&redirect=1

dnf5 install -y \
    hyprland \
    waybar \
    lua \
    wvkbd \
    rofi-wayland \
    brightnessctl \
    libinput \
    kitty \
    grim \
    slurp \
    wl-clipboard \
    hyprlock \
    swaybg

# ryzenadj is optional: the handheld TDP cycle silently keeps the stored
# preset when it (or the required permissions) are missing.
if ! dnf5 install -y ryzenadj; then
    echo "!! ryzenadj unavailable; TDP cycling will be a no-op" >&2
fi

### Enable the adaptive profile switcher for every user
systemctl --global enable hypr-profile-switch.service hypr-profile-udev.service

### Point the deck's desktop session at Hyprland instead of Plasma
#
# /usr/share/steamos-manager/platform.toml ([session] desktop) is read by
# steamos-manager to decide which session "Exit to Desktop" launches from
# Steam Gaming Mode. Bazzite writes "plasma.desktop" there for the KDE deck
# image; we swap it for our Hyprland session entry.
if [ -f /usr/share/steamos-manager/platform.toml ]; then
    if grep -q 'desktop = "plasma.desktop"' /usr/share/steamos-manager/platform.toml; then
        sed -i 's/desktop = "plasma.desktop"/desktop = "hyprland.desktop"/' /usr/share/steamos-manager/platform.toml
    elif ! grep -q 'desktop = "hyprland.desktop"' /usr/share/steamos-manager/platform.toml; then
        printf '\n[session]\ndesktop = "hyprland.desktop"\n' >> /usr/share/steamos-manager/platform.toml
    fi
fi

# Legacy Steam-client path: gamescope-session-steam's steamos-session-select
# calls /usr/lib/os-session-select, which Bazzite provides at /usr/libexec.
if [ -f /usr/libexec/os-session-select ]; then
    sed -i 's/desktop_session="plasma.desktop"/desktop_session="hyprland.desktop"/' /usr/libexec/os-session-select
fi
if [ -e /usr/lib/os-session-select ] && [ ! -L /usr/lib/os-session-select ]; then
    echo "!! /usr/lib/os-session-select exists as a real file; leaving it alone" >&2
else
    ln -sf /usr/libexec/os-session-select /usr/lib/os-session-select
fi

rm -rf /var/tmp/*
