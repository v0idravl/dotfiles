# Waybar redesign — design

**Date:** 2026-06-13
**Status:** approved (pending spec review)
**Scope:** Replace the stock default waybar with a repo-managed config + stylesheet
that visually matches the existing tmux status line (Kanagawa Dragon). Host-only,
following the same deploy pattern as the sway/GTK configs.

## Problem

`~/.config/sway/config` runs `exec waybar`, but there is **no waybar config in the
repo** — waybar falls back to the stock default at `/etc/xdg/waybar/`. That default
is visually incoherent with the rest of the setup (the tmux bar, the sway dragon
accent), which is why it looks out of place.

`waybar` is already installed by `deploy.sh` (in the greetd/sway package block), so
this is purely a configuration task: author `config.jsonc` + `style.css`, wire them
into `deploy.sh`, and confirm the bar comes up styled.

## Goals

- A single bottom bar that reads as the same design language as the tmux status line.
- Built-in modules only — **no new packages, no external helper scripts**. Nothing
  that can fail and take the bar down. Everything leans on what already runs
  (swayidle, sway IPC, pipewire-pulse, brightnessctl's sysfs).
- Repo-managed and deployed host-only (the Kali box is headless).

## Non-goals

- No IP address on the bar — the tmux status line already shows the local IP, and we
  are not duplicating it (no bar segment, no tooltip).
- No keyboard-layout/caps module (only the `us` layout is used).
- No hover tooltips drawer, no collapsible metrics drawer (considered, declined).
- No theming of anything beyond waybar in this work.

## Design language (from `.tmux.conf` + sway config)

Kanagawa Dragon palette, reused verbatim:

| Role                  | Hex       | Source / usage                          |
|-----------------------|-----------|-----------------------------------------|
| Bar background        | `#181616` | tmux `status-style bg`                  |
| Default foreground    | `#c5c9c5` | tmux `status-style fg`                  |
| Muted / inactive      | `#54546d` | tmux separators                         |
| Dim foreground        | `#727169` | tmux inactive window                    |
| Active / highlight    | `#e6c384` | tmux current window (yellow)            |
| Green accent          | `#98bb6c` | tmux session name                       |
| Blue accent           | `#7fb4ca` | tmux IP segment                         |
| Violet accent         | `#938aa9` / `#957fb8` | tmux date / sway focus border |
| Urgent / critical     | `#c4746e` | dragon red                              |

- Flat background, **no rounded pills, no powerline arrows**.
- Thin `│` dividers in `#54546d` between right-cluster modules (mirrors tmux).
- Font: `JetBrainsMono Nerd Font 10` (already installed, used for glyph icons).
- Bar height ~26px, bottom, full width.

## Layout

```
 1  2 [3]   nvim — dotfiles        [RESIZE]      1%  4.2G  48°   85%   42%   72%   13 Jun 14:32   ⏻
└──────── left ────────┘          └ mode ┘       └──────────── right cluster ───────────┘ └tray┘└pwr┘
```

### Left modules
- `sway/workspaces` — numbered. Active = bold `#e6c384`; inactive = `#727169`;
  urgent = `#c4746e`. Dynamic (sway default): workspaces appear/disappear as used,
  unchanged from current behavior. Click switches workspace.
- `sway/mode` — **resize-mode indicator.** Shows a bold accent `RESIZE` badge only
  while in the `resize` mode (entered with `Mod+r`); hidden otherwise.
- `sway/window` — focused window title, truncated to a max length.

### Right modules (left → right, `│`-separated)
1. `cpu` — load %, icon.
2. `memory` — used %, icon.
3. `temperature` — CPU package temp via `thermal-zone` 7 (`x86_pkg_temp`).
   Critical threshold colors the segment `#c4746e`.
4. `backlight` — `intel_backlight` device. Scroll to adjust (pairs with the
   `XF86MonBrightness*` keybinds). Percentage + icon.
5. `idle_inhibitor` — **caffeine toggle.** Click toggles swayidle inhibition;
   icon reflects state, accent (`#e6c384`) when active (idle inhibited).
6. `pulseaudio` — volume % + mute state via the pipewire-pulse shim. Click →
   `pavucontrol`; scroll → volume up/down (pairs with `XF86Audio*` keybinds).
7. `network` — wifi SSID / wired state with icon. **No IP shown.** Follows the
   default route, so libvirt `virbr0`/`vnet0` are ignored automatically.
   Disconnected = muted/red icon.
8. `battery` — `BAT0` percentage + charging state. States: warning <30%, critical
   <15% (colors shift to warn/red); charging shows a bolt/charging icon.
9. `clock` — format `  %d %b   %H:%M` (calendar icon + `13 Jun 14:32`), matching
   the tmux right-side date/time. Violet `#938aa9` accent on the date like tmux.
10. `tray` — system tray. **Required:** the sway config launches `nm-applet
    --indicator` and `lxqt-policykit-agent`, which need a tray to live in.
11. `custom/power` — power button (`⏻`). Click opens a `swaynag` menu:
    Lock / Logout / Reboot / Poweroff. Reuses the existing swaynag exit pattern
    already in the sway config (`swaynag -t warning ...`). This is the one custom
    module; its "script" is an inline `swaynag` invocation with no new dependency.

## Files & deploy

New files (repo-managed):
- `.config/waybar/config.jsonc` — module layout + behavior.
- `.config/waybar/style.css` — Kanagawa Dragon styling.

`deploy.sh` changes:
- Add both files to the `FILES` associative array (repo path → `$HOME/...`).
- Under `--kali`, `unset` both entries — host-only, exactly like the existing
  `unset 'FILES[.config/sway/config]'` / GTK treatment (the Kali box is headless).
- No package changes needed: `waybar` is already in the greetd install block, and
  the modules use `pipewire-pulse` / `brightnessctl` / swayidle which are already
  present.

## Glyph safety

Per established practice (see memory: "Nerd Font glyph selection"), every Nerd Font
icon codepoint in `config.jsonc` will be **verified against the installed font cmap
with `fonttools`** before committing — not trusted from web codepoint tables. Any
glyph that does not resolve in `JetBrainsMonoNerdFont` gets swapped for one that does.

## Verification

- `waybar -c .config/waybar/config.jsonc -s .config/waybar/style.css` launches with
  no JSON/CSS parse errors (waybar logs parse failures to stderr and falls back).
- Live iteration: `killall -SIGUSR2 waybar` reloads style; `swaymsg reload`
  respawns waybar fully.
- Visual check on the host: workspaces highlight correctly, resize badge appears on
  `Mod+r`, caffeine toggle flips state, volume/brightness scroll works, tray hosts
  nm-applet, clock matches the tmux format, power button opens the swaynag menu.
- `--kali` dry-run (`./deploy.sh --kali --dry-run`) shows the waybar files are NOT
  linked; host dry-run shows they ARE.

## Follow-up (separate task, not this spec)

After the bar is in and verified, write **one cohesive cheatsheet for the entire
workflow** (sway keybindings + tmux + the new bar interactions) as the final
deliverable.
