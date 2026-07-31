# hypr-adaptive

A custom Hyprland desktop environment for handheld gaming PCs, built for the
ASUS ROG Ally X running a custom Bazzite image. It dynamically switches
between two environments, like a modern, correctly-executed Windows 8
Continuum:

- **Handheld mode** — portable. Touchscreen and controller first. Large UI,
  big touch targets (>= 48 px), virtual keyboard, touch-friendly launcher,
  reduced animations, conservative battery habits.
- **Desktop mode** — an external monitor and/or keyboard is present. Standard
  keyboard-and-mouse desktop, multi-monitor, smaller UI, normal window
  management.

Bazzite's controller stack (Steam Input, gamescope, handheld-daemon,
asusctl, supergfxctl, power-profiles-daemon) is **not** replaced. Only the
KDE Desktop Mode gets swapped for Hyprland.

## Architecture

```
ROG Ally X
|
├── Internal display only
│   Detect: no HDMI/USB-C monitor, controller present, no keyboard/mouse
│   └── Handheld profile
│
└── External display detected
    Detect: HDMI connected, USB-C display connected, keyboard/mouse available
    └── Desktop profile
```

### Mode detection priority

1. External monitor detected? -> **desktop**
2. Keyboard detected? -> **desktop**
3. Controller detected? -> **handheld**
4. Default -> **handheld**

Detection is implemented in `config/lua/main.lua` (`main.detect()`).

## Layout

```
hypr-adaptive/
├── config/
│   ├── lua/
│   │   ├── main.lua          entry: loads modules, detects state, applies profile
│   │   ├── profiles.lua      profile registry / dispatcher
│   │   ├── monitors.lua      hyprctl monitor discovery (external/internal)
│   │   ├── input.lua         libinput-based keyboard/touchscreen/controller detection
│   │   └── appearance.lua    hyprctl appearance keywords per profile
│   ├── handheld/
│   │   ├── waybar.jsonc      big-touch-button status bar
│   │   ├── waybar.css
│   │   └── launcher.lua      fullscreen rofi/wofi app grid
│   └── desktop/
│       ├── waybar.jsonc      compact desktop bar
│       ├── waybar.css
│       └── launcher.lua
├── scripts/
│   ├── paths.lua             package-root resolution (shared helper)
│   ├── detect-mode.lua       CLI entry: apply once, or --watch for auto-switch
│   ├── switch-profile.lua    manual override: `lua switch-profile.lua handheld`
│   ├── launcher.lua          mode-aware launcher keybind dispatcher
│   ├── enable-handheld.lua   apply handheld profile
│   ├── enable-desktop.lua    apply desktop profile
│   └── read-sensor.lua       waybar sensor modules (cpu/gpu/fan/tdp)
├── services/
│   └── hypr-profile-switch.service
├── hyprland.conf             base Hyprland config (deployed to ~/.config/hypr/)
├── Containerfile             Bazzite custom-image build (base: bazzite-deck)
├── build_files/
│   └── build.sh              image build steps (packages, session swap, units)
├── system_files/             image files layered onto / (see below)
├── disk_config/              bootc-image-builder configs (qcow2/ISO)
├── .github/workflows/        build container + disk images in CI
├── image-template.env        build metadata (IMAGE_NAME, REPO_ORGANIZATION)
├── Justfile                  local build helpers (`just build`, `just build-iso`)
└── README.md
```

`system_files/` layers the following onto the image:

```
system_files/
├── usr/bin/
│   └── hyprland-launcher     session entrypoint: env + exec Hyprland
├── usr/share/wayland-sessions/
│   └── hyprland.desktop      SDDM/steamos-manager session entry
├── usr/lib/systemd/user/
│   └── hypr-profile-switch.service
└── usr/lib/systemd/user-preset/
    └── 50-hypr-adaptive.preset
```

## Requirements

- `hyprland`, `waybar`
- `lua` (5.2+; Fedora/Bazzite ships 5.4)
- `squeekboard` (virtual keyboard; needs the wlr virtual-keyboard protocol,
  which Hyprland supports)
- `rofi` or `wofi` (launcher)
- `libinput` tools (`libinput list-devices` for input detection)
- `brightnessctl`, `pipewire-pulse`/`pulseaudio`, NetworkManager, BlueZ
- `power-profiles-daemon` (`powerprofilesctl`) for per-mode power profiles
- Optional: `ryzenadj` for the TDP cycle button

## Install

Deploy the repo contents to `~/.config/hypr/` (the image does this for you
via `/etc/skel`):

```sh
git clone <this-repo> ~/.config/hypr
```

or symlink a checkout:

```sh
ln -s "$(pwd)/hypr-adaptive" ~/.config/hypr
```

Then copy `hyprland.conf` into place and enable the user service (the
`services/` unit is a manual-install copy of the one the image ships at
`/usr/lib/systemd/user/`):

```sh
cp hyprland.conf ~/.config/hypr/hyprland.conf
cp services/hypr-profile-switch.service ~/.config/systemd/user/
systemctl --user enable --now hypr-profile-switch
```

### hyprland.conf integration

`hypr-adaptive` manages monitor rules, gaps, rounding, cursor size, blur and
animations at runtime, so keep those out of `hyprland.conf`. A ready-made
base config ships in this repo (`hyprland.conf`) with the switcher, launcher,
profile-override and power binds wired up. Key lines:

```conf
exec-once = systemctl --user start hypr-profile-switch.service

# mode-aware launcher (touch grid vs compact list)
bind = SUPER, SPACE, exec, lua ~/.config/hypr/scripts/launcher.lua

bind = SUPER SHIFT, H, exec, lua ~/.config/hypr/scripts/switch-profile.lua handheld
bind = SUPER SHIFT, D, exec, lua ~/.config/hypr/scripts/switch-profile.lua desktop

# battery-conscious power profile binds
bind = SUPER, B, exec, powerprofilesctl set power-saver
bind = SUPER SHIFT, B, exec, powerprofilesctl set balanced
```

## How it works

1. `hypr-profile-switch.service` runs `detect-mode.lua --watch`.
2. The watcher blocks on `hyprctl events -m` (via `timeout`, so it also
   re-checks every 10 s), then calls `main.apply()`.
3. `main.detect()` checks `hyprctl monitors -j` for a non-internal output and
   `libinput list-devices` for a real keyboard.
4. If the detected mode differs from the last applied one (stored in
   `~/.local/state/hypr-adaptive/mode`), `switch-profile.lua` runs the
   matching `enable-*.lua` script, which:
   - restarts Waybar with the profile's config/CSS,
   - starts/stops `squeekboard` (handheld on / desktop off),
   - sets the power profile (`power-saver` handheld, `balanced` desktop),
   - reconfigures monitors (`external primary,preferred,scale 1`; internal
     `1920x1080,secondary,scale 1.5`),
   - applies appearance keywords via `appearance.lua`,
   - writes the state file.

Manual switching works the same way and survives because the state file is
only written when a profile is actually applied.

## Sensor modules (handheld bar)

`config/handheld/waybar.jsonc` calls `scripts/read-sensor.lua`:

| Module   | Source                                                               |
| -------- | -------------------------------------------------------------------- |
| CPU temp | `k10temp` hwmon `temp1_input` (Tctl)                                 |
| GPU temp | `amdgpu` hwmon `temp1_input`                                         |
| Fan RPM  | first `fan1_input` under `/sys/class/hwmon`                          |
| TDP      | cycles 15 W / 20 W / 28 W via `ryzenadj --stapm/--fast/--slow-limit` |

TDP state lives in `~/.local/state/hypr-adaptive/tdp`; tap the TDP button to
cycle. If `ryzenadj` is not available (or lacks permissions) it silently keeps
the stored preset. TDP presets are edited at the top of `read-sensor.lua`.

## Bazzite OCI integration

This repo _is_ the custom-image source. It follows the official
`ublue-os/image-template` layout (per
<https://docs.bazzite.gg/Advanced/creating_custom_image/>) and derives from
**`ghcr.io/ublue-os/bazzite-deck:stable`**, so the stock controller stack —
`gamescope-session`, `steam`, `steamos-compositor`, `handheld-daemon`,
`asusctl`, `supergfxctl`, `power-profiles-daemon` — is kept untouched. Only
the deck's **desktop session** is swapped from KDE Plasma to Hyprland;
Steam Gaming Mode stays the default boot session.

What the build does (`build_files/build.sh`):

1. Layers `system_files/` onto the image:
   - `/usr/share/wayland-sessions/hyprland.desktop` — the session entry,
     launched via `/usr/bin/hyprland-launcher`.
   - `/usr/lib/systemd/user/hypr-profile-switch.service` — the adaptive
     profile switcher, enabled for every user.
2. Installs Hyprland + friends (`hyprland`, `waybar`, `lua`, `squeekboard`,
   `rofi-wayland`, `brightnessctl`, `libinput`, `kitty`, `grim`, `slurp`,
   `wl-clipboard`, `hyprlock`, `swaybg`, plus optional `ryzenadj` for TDP
   cycling). Plasma remains installed as a fallback session.
3. Deploys this repo to `/etc/skel/.config/hypr/` so every new user gets a
   full editable copy (`hyprland.conf` included).
4. **Points the deck's desktop session at Hyprland**:
   - `[session] desktop` in `/usr/share/steamos-manager/platform.toml` is
     changed from `plasma.desktop` to `hyprland.desktop`. steamos-manager
     reads this when you pick "Exit to Desktop" from Steam Gaming Mode.
   - The legacy Steam-client path (`/usr/libexec/os-session-select`, and a
     `/usr/lib/os-session-select` symlink for gamescope-session-steam) is
     patched the same way.

### Building the image and an install ISO

In CI: push to your repo (default branch `main`) and the
`.github/workflows/build.yml` workflow builds and publishes
`ghcr.io/<you>/hypr-adaptive:latest`. Then run the `Build disk images`
workflow (`build-disk.yml`) with `platform: amd64` — the `anaconda-iso`
matrix entry produces an installable ISO.

Locally:

```sh
just build                        # build the container image
just build-iso                    # build output/bootiso/install.iso via BIB
```

Before building, set your GitHub org in `image-template.env`
(`REPO_ORGANIZATION`) and in `disk_config/iso.toml` (the `bootc switch`
registry). If your repo's default branch is not `main`, adjust the
workflow `branches:` lists.

### First boot expectations

- Boot lands in Steam Gaming Mode (unchanged).
- "Exit to Desktop" → Hyprland in **handheld** mode (big UI, 36 px cursor,
  squeekboard on tap, power-saver profile).
- Dock an external monitor / plug a keyboard → auto-switch to **desktop**
  mode.
- The "Return to Gaming Mode" desktop shortcut works as shipped.

## Controller mapping in desktop mode

Do not remap via Hyprland. Keep the Bazzite/Steam Input mappings:

- Right stick = mouse
- A = left click
- B = Escape / right click
- Triggers = mouse buttons

These are provided by Steam Input / gamescope and stay active in both modes.

## Troubleshooting

- **Waybar custom modules show "n/a"** — `read-sensor.lua` falls back
  gracefully; verify `ls /sys/class/hwmon/` names with
  `for d in /sys/class/hwmon/hwmon*; do echo "$d: $(cat $d/name)"; done`.
- **Switching loops** — check `~/.local/state/hypr-adaptive/mode`; the
  watcher only applies when the detected mode changes.
- **Virtual keyboard won't show** — confirm the compositor supports the
  wlr virtual-keyboard protocol and that `squeekboard` is installed and
  listed in `systemctl --user list-units`.
- **`cursor:size` ignored** — set `env = XCURSOR_SIZE,36` for handheld /
  `env = XCURSOR_SIZE,24` for desktop in `hyprland.conf` as a fallback; the
  runtime `hyprctl keyword cursor:size` is applied by `appearance.lua`.
- **"Exit to Desktop" still lands in Plasma** — the deck's desktop session
  comes from `[session] desktop` in `/usr/share/steamos-manager/platform.toml`
  and the legacy `os-session-select`. Rebuild the image with the patches in
  `build_files/build.sh`; if you'd rather switch a running install, edit both
  to `hyprland.desktop`.
- **Scaling** — internal panel scale is 1.5 in both modes and external
  monitors use scale 1. Tweak `enable-handheld.lua` /
  `enable-desktop.lua` monitor lines to taste.

## Development order

As specified: basic Hyprland boot (`hyprland.conf`) -> Lua config loader ->
monitor detection -> profile switching -> Waybar profiles -> virtual keyboard
-> touch optimisation -> controller integration testing -> Bazzite OCI image
integration (Containerfile + workflows + ISO).
