# nixos-config

One NixOS + Home Manager flake: GRUB (dual boot with Windows), Hyprland (Lua config), and a Quickshell desktop
shell built around a Code Geass (Lelouch) theme. Everything is declarative, so a new machine is a clone and a rebuild.

## Layout

    flake.nix                      inputs (nixpkgs unstable, home-manager) and the host list
    hosts/<machine>/               one machine: hostname, user, timezone, which modules it uses
    modules/nixos/                 system features (boot, audio, laptop, firewall-opening apps, Syncthing, PAM)
    home/                          your user environment (Home Manager)
      desktop/                     behaviour: keybinds, wallpaper command, idle and capture
      rices/lelouch/               the look: Hyprland visuals, matugen colours, kitty, the Quickshell shell
      rices/usogui/                an older rice, kept as a fallback (switch with one import in home/default.nix)
    scripts/verify.sh              checks that files, tools and services are in place

Rule of thumb: needs root, opens a port or touches hardware means `modules/nixos/`; an app or its settings means `home/`.

## Everyday commands

    rebuild            switch NixOS and Home Manager, then commit and push
    rebuild update     the same, after updating nixpkgs and Home Manager
    wallpaper          pick a wallpaper (also recolours everything through matugen)
    bash scripts/verify.sh

The shell restarts itself after a rebuild. To try QML changes without rebuilding:

    systemctl --user stop quickshell
    qs --path ~/nixos-config/home/rices/lelouch/shell      # live-reloads on save
    systemctl --user start quickshell

## The shell (home/rices/lelouch/shell)

- Singletons hold state: `Theme` (colours), `Ui` (what is open), `Media`, `Net`, `SysInfo`, `Focus`, `Agenda`,
  `Tasks`, `Notes`, `Board`, `History` (notifications), `LockState`.
- `TextStore` is the one way a file is read and saved. Use it for any new data file.
- `Panel` is a centred modal (launcher, wallpaper picker, scratchpad). `DropPanel` drops down from the bar (calendar,
  media, notifications, focus). `CommandCenter` is the right-hand drawer (system, controls, connect).
- `*Page.qml` is the content of a tab or popup; give it an `implicitHeight` and it sizes its container.
- Adding a popup: write `FooPage.qml`, add one `DropPanel { name: "foo"; page: Component { FooPage {} } }` to
  `Popups.qml`, and a `BarButton` that calls `Ui.togglePopup("foo")`.

## Data (not in the repo)

    ~/.config/lelouch/calendar-url      your private calendar address (Google: Integrate calendar, iCal format)
    ~/Sync/todo/todo.txt                tasks, todo.txt format, shared with the phone by Syncthing
    ~/Sync/notes/notes.md               quick notes, notes separated by a line of ---
    ~/Sync/notes/whiteboard.json        the whiteboard strokes (whiteboard.png is an export)
    ~/.local/state/lelouch/             notification history and the note draft

## New machine

1. Install NixOS, clone this repo, copy the new `hardware-configuration.nix` into `hosts/<machine>/`.
2. Add the machine to `flake.nix` and `sudo nixos-rebuild switch --flake .#<machine>`.
3. Put the calendar link back, set up Syncthing (http://127.0.0.1:8384), put a picture at `~/.face`.

## Apps (home/apps.nix)

- Zen Browser and Spicetify come from their own flakes (inputs in `flake.nix`); Vesktop is from nixpkgs.
- Home Manager modules receive the flake inputs as the `inputs` argument.
- Colours from the wallpaper reach Vesktop (`~/.config/vesktop/settings/quickCss.css`, live) through a matugen template in `apps.nix`. Zen is configured inside Zen.


## Design rule for panels

A panel's window must be exactly as big as its card and must not use a click `mask`. Windows with a mask made bar
clicks unreliable (see `DropPanel.qml`). `Panel.qml` is full-screen only when it is modal (launcher, wallpaper picker).

## Layouts and workspace labels

- The tiling layout (dwindle, master, scrolling, monocle) is chosen from the layout button in the bar or with
  `Super+Y`. It is applied live with `hyprctl eval` and remembered in `~/.local/state/lelouch/layout.lua`,
  which `home/rices/lelouch/tiling.nix` loads at every Hyprland config load.
- Workspace labels: edit `glyphs` in `shell/Workspaces.qml`, or drop pictures into `shell/assets/workspaces/`.

## Rices and sessions

Each rice belongs to one login session: `hyprland` runs `home/rices/lelouch`, `mango` runs `home/rices/mango`.
Both are always built; the session you start decides which one runs (the Lelouch shell is tied to Hyprland's session
target, Mango's config only loads in Mango). The lock screen's SESSION buttons, or `switch-session NAME`, end the
current session and log straight back in to the other one (`modules/nixos/sessions.nix` + SDDM Relogin); the last
choice is kept in `~/.config/lelouch/session`. `git checkout lelouch-rice` is the snapshot taken before Mango.
Rules for building a rice are in `home/rices/mango/README.md`.

## Performance and network

`modules/nixos/performance.nix` (Zen kernel, sched_ext LAVD scheduler, zram, earlyoom, thermald, power profile by AC
state, Intel video decoding) and `modules/nixos/network.nix` (Wi-Fi power saving off, regulatory domain, BBR, cached
DNS). Check and compare ping before and after with `bash scripts/verify-performance.sh [--baseline]`. Left out on
purpose: `mitigations=off`, automatic garbage collection (old generations are kept for GRUB), overclocking.
The shell never lets an nmcli query trigger a Wi-Fi scan (`--rescan no`): scans cause ping spikes.
