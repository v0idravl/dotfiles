# Waybar Redesign Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the stock default waybar with a repo-managed `config.jsonc` + `style.css` that match the tmux status line (Kanagawa Dragon), using built-in modules only, deployed host-only.

**Architecture:** Two new files under `.config/waybar/` wired into `deploy.sh`'s `FILES` map and `unset` under `--kali` (same host-only pattern as the sway/GTK configs). `waybar` is already installed by the existing greetd block; no package changes. Validation is parse-check + glyph-cmap verification + a live launch on the host — there is no unit-test surface for declarative config.

**Tech Stack:** waybar (built-in modules: sway/workspaces, sway/mode, sway/window, cpu, memory, temperature, backlight, idle_inhibitor, pulseaudio, network, battery, clock, tray, custom/power), GTK CSS, JetBrainsMono Nerd Font, swaynag, bash deploy script.

**Reference spec:** `docs/superpowers/specs/2026-06-13-waybar-redesign-design.md`

---

## File Structure

- **Create** `.config/waybar/config.jsonc` — module layout + per-module behavior (single responsibility: *what* is on the bar and how each module acts).
- **Create** `.config/waybar/style.css` — Kanagawa Dragon styling (single responsibility: *how* the bar looks).
- **Modify** `deploy.sh` — register both files in `FILES`; `unset` both under `--kali`.

Hardware facts already probed on this host (do not re-guess): battery `BAT0`, backlight `intel_backlight`, CPU package temp `thermal-zone` index `7` (`x86_pkg_temp`), audio via `pipewire-pulse` (so the `pulseaudio` module works), wifi `wlp0s20f3` / wired `enp0s31f6` (network module follows the default route, ignoring libvirt `virbr0`/`vnet0`).

---

### Task 1: Verify every Nerd Font glyph resolves in the installed font

The config in Task 2 uses the codepoints below. Per established practice, confirm each one exists in the installed `JetBrainsMonoNerdFont-Regular.ttf` cmap **before** trusting it — do not rely on web codepoint tables. If a primary glyph is absent, use the listed fallback and adjust Task 2's config accordingly.

**Files:** none (verification only)

- [ ] **Step 1: Run the cmap check**

Run:
```bash
python3 - <<'PY'
from fontTools.ttLib import TTFont
import glob, os
path = glob.glob(os.path.expanduser("~/.local/share/fonts/JetBrainsMonoNerdFont-Regular.ttf"))[0]
cmap = TTFont(path).getBestCmap()
# name: (primary_codepoint, fallback_codepoint)
glyphs = {
    "cpu":            (0xF4BC, 0xF2DB),  # oct-cpu        -> fa-microchip
    "memory":         (0xF035B, 0xF2DB), # md-memory      -> fa-microchip
    "temperature":    (0xF2C9, 0xE20A),  # fa-thermometer -> mdi thermometer
    "backlight":      (0xF185, 0xF0335), # fa-sun         -> md-brightness
    "idle_on":        (0xF06E, 0xF06E),  # fa-eye (awake/inhibited)
    "idle_off":       (0xF070, 0xF070),  # fa-eye-slash (idle allowed)
    "vol_off":        (0xF026, 0xF026),  # fa-volume-off
    "vol_down":       (0xF027, 0xF027),  # fa-volume-down
    "vol_up":         (0xF028, 0xF028),  # fa-volume-up
    "vol_mute":       (0xF6A9, 0xF026),  # fa-volume-mute -> volume-off
    "net_wifi":       (0xF1EB, 0xF1EB),  # fa-wifi
    "net_eth":        (0xF0E8, 0xF0E8),  # fa-sitemap
    "net_off":        (0xF127, 0xF127),  # fa-chain-broken
    "bat_0":          (0xF244, 0xF244),  # fa-battery-empty
    "bat_1":          (0xF243, 0xF243),  # fa-battery-quarter
    "bat_2":          (0xF242, 0xF242),  # fa-battery-half
    "bat_3":          (0xF241, 0xF241),  # fa-battery-three-quarters
    "bat_4":          (0xF240, 0xF240),  # fa-battery-full
    "bat_charge":     (0xF0E7, 0xF0E7),  # fa-bolt
    "clock":          (0xF073, 0xF073),  # fa-calendar
    "power":          (0xF011, 0xF011),  # fa-power-off
}
for name,(p,f) in glyphs.items():
    use = p if p in cmap else (f if f in cmap else None)
    status = "OK" if p in cmap else (f"FALLBACK -> {hex(f)}" if f in cmap else "MISSING")
    print(f"{name:14} primary={hex(p):8} {status}  glyph={chr(use) if use else '∅'}")
PY
```

Expected: every line ends in `OK` (or, acceptably, `FALLBACK -> 0x...`). Any line printing `MISSING` is a blocker — pick a different glyph before proceeding.

- [ ] **Step 2: Record the resolved codepoints**

If all lines say `OK`, Task 2's config is correct as written. If any say `FALLBACK -> 0x...`, note which glyph to substitute in the corresponding module in Task 2. No commit (verification only).

---

### Task 2: Create the waybar config

**Files:**
- Create: `.config/waybar/config.jsonc`

- [ ] **Step 1: Write the config**

Write `.config/waybar/config.jsonc` exactly as below (substitute any fallback glyphs identified in Task 1). The literal characters in the strings are the Nerd Font glyphs for the codepoints verified above.

```jsonc
{
    "layer": "bottom",
    "position": "bottom",
    "height": 26,
    "spacing": 0,

    "modules-left": ["sway/workspaces", "sway/mode", "sway/window"],
    "modules-center": [],
    "modules-right": [
        "cpu", "memory", "temperature", "backlight", "idle_inhibitor",
        "pulseaudio", "network", "battery", "clock", "tray", "custom/power"
    ],

    "sway/workspaces": {
        "all-outputs": true,
        "format": "{name}"
    },

    "sway/mode": {
        "format": "{}",
        "tooltip": false
    },

    "sway/window": {
        "format": "{title}",
        "max-length": 60,
        "tooltip": false
    },

    "cpu": {
        "interval": 5,
        "format": " {usage}%",
        "tooltip": false
    },

    "memory": {
        "interval": 5,
        "format": " {used:0.1f}G",
        "tooltip": false
    },

    "temperature": {
        "thermal-zone": 7,
        "critical-threshold": 85,
        "format": " {temperatureC}°",
        "tooltip": false
    },

    "backlight": {
        "device": "intel_backlight",
        "format": " {percent}%",
        "on-scroll-up": "brightnessctl set 5%+",
        "on-scroll-down": "brightnessctl set 5%-",
        "tooltip": false
    },

    "idle_inhibitor": {
        "format": "{icon}",
        "format-icons": { "activated": "", "deactivated": "" },
        "tooltip": false
    },

    "pulseaudio": {
        "format": "{icon} {volume}%",
        "format-muted": " muted",
        "format-icons": { "default": ["", "", ""] },
        "on-click": "pavucontrol",
        "on-scroll-up": "wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+",
        "on-scroll-down": "wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-",
        "tooltip": false
    },

    "network": {
        "format-wifi": " {essid}",
        "format-ethernet": " {ifname}",
        "format-disconnected": " offline",
        "on-click": "nm-connection-editor",
        "tooltip": false
    },

    "battery": {
        "states": { "warning": 30, "critical": 15 },
        "format": "{icon} {capacity}%",
        "format-charging": " {capacity}%",
        "format-plugged": " {capacity}%",
        "format-icons": ["", "", "", "", ""]
    },

    "clock": {
        "interval": 30,
        "format": " {:%d %b  %H:%M}",
        "tooltip": false
    },

    "tray": {
        "icon-size": 16,
        "spacing": 8
    },

    "custom/power": {
        "format": "",
        "tooltip": false,
        "on-click": "swaynag -t warning -m 'Power' -b 'Lock' 'swaylock -f -c 0d0d0d' -b 'Logout' 'swaymsg exit' -b 'Reboot' 'systemctl reboot' -b 'Poweroff' 'systemctl poweroff'"
    }
}
```

- [ ] **Step 2: Validate JSON structure**

waybar tolerates `//` comments and trailing newlines (jsonc), but the structure must be valid JSON once comments are stripped. This config has no comments, so check it directly:

Run: `python3 -c "import json; json.load(open('.config/waybar/config.jsonc')); print('valid json')"`
Expected: `valid json`

- [ ] **Step 3: Commit**

```bash
git add .config/waybar/config.jsonc
git commit -m "feat(waybar): add Kanagawa Dragon bar config (host-only)

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

### Task 3: Create the stylesheet

**Files:**
- Create: `.config/waybar/style.css`

- [ ] **Step 1: Write the stylesheet**

Write `.config/waybar/style.css` exactly as below. The vertical `│` dividers between right-cluster modules are rendered as a 1px `border-left` in muted `#54546d` (cleaner than literal `│` chars, same visual result).

```css
* {
    font-family: "JetBrainsMono Nerd Font";
    font-size: 13px;
    min-height: 0;
}

window#waybar {
    background: #181616;
    color: #c5c9c5;
}

/* ── left: workspaces ───────────────────────────────── */
#workspaces button {
    padding: 0 8px;
    color: #727169;
    background: transparent;
    border: none;
    border-radius: 0;
}
#workspaces button.focused,
#workspaces button.visible {
    color: #e6c384;
    font-weight: bold;
}
#workspaces button.urgent {
    color: #c4746e;
}

/* resize-mode badge */
#mode {
    color: #181616;
    background: #e6c384;
    font-weight: bold;
    padding: 0 8px;
}

#window {
    color: #c5c9c5;
    padding: 0 10px;
}

/* ── right cluster: flat, │ dividers via border-left ── */
#cpu, #memory, #temperature, #backlight, #idle_inhibitor,
#pulseaudio, #network, #battery, #clock, #tray, #custom-power {
    padding: 0 10px;
    border-left: 1px solid #54546d;
}

#cpu, #memory, #temperature, #backlight { color: #c5c9c5; }
#temperature.critical { color: #c4746e; }

#idle_inhibitor { color: #727169; }
#idle_inhibitor.activated { color: #e6c384; }

#pulseaudio { color: #c5c9c5; }
#pulseaudio.muted { color: #727169; }

#network { color: #7fb4ca; }
#network.disconnected { color: #c4746e; }

#battery { color: #c5c9c5; }
#battery.warning { color: #e6c384; }
#battery.critical { color: #c4746e; }
#battery.charging { color: #98bb6c; }

#clock { color: #938aa9; }

#tray { color: #c5c9c5; }

#custom-power { color: #c4746e; }
```

- [ ] **Step 2: Commit**

```bash
git add .config/waybar/style.css
git commit -m "feat(waybar): add Kanagawa Dragon stylesheet

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

### Task 4: Validate the bar launches cleanly against the repo files

This is the "test" for the config + stylesheet: waybar must start with no parse errors and stay up.

**Files:** none (validation only)

- [ ] **Step 1: Launch waybar against the repo files and capture stderr**

Run:
```bash
timeout 4 waybar -c .config/waybar/config.jsonc -s .config/waybar/style.css 2>/tmp/waybar-check.log; cat /tmp/waybar-check.log
```
Expected: no lines containing `error` (CSS or JSON parse failures print to stderr). A bar appears at the bottom of the screen for ~4 seconds then exits via the timeout. Warnings about an already-running waybar instance are fine.

- [ ] **Step 2: Confirm no parse errors**

Run: `grep -iE 'error|failed to parse' /tmp/waybar-check.log || echo "clean"`
Expected: `clean`

If errors appear, fix the offending file (Task 2 or Task 3) and re-run Step 1 before continuing.

---

### Task 5: Wire the files into deploy.sh (host-only)

**Files:**
- Modify: `deploy.sh` — `FILES` map (~line 36) and the `--kali` `unset` block (~line 49).

- [ ] **Step 1: Add both files to the FILES map**

In the `declare -A FILES=( ... )` block, add these two entries alongside the existing `.config/sway/config` entry:

```bash
  [".config/waybar/config.jsonc"]="$HOME/.config/waybar/config.jsonc"
  [".config/waybar/style.css"]="$HOME/.config/waybar/style.css"
```

- [ ] **Step 2: Unset both under --kali**

In the `if $KALI; then` block, next to the existing host-only unsets, add:

```bash
  # waybar is host-only (the Kali box is headless)
  unset 'FILES[.config/waybar/config.jsonc]'
  unset 'FILES[.config/waybar/style.css]'
```

- [ ] **Step 3: Verify the script still parses**

Run: `bash -n deploy.sh && echo "syntax ok"`
Expected: `syntax ok`

- [ ] **Step 4: Confirm host links the files, kali does not**

Run: `./deploy.sh --dry-run 2>&1 | grep waybar`
Expected: two `[dry-run] would link:` lines for `config.jsonc` and `style.css`.

Run: `./deploy.sh --kali --dry-run 2>&1 | grep waybar || echo "not linked on kali (correct)"`
Expected: `not linked on kali (correct)`

- [ ] **Step 5: Commit**

```bash
git add deploy.sh
git commit -m "feat(waybar): deploy bar config host-only via deploy.sh

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

### Task 6: Deploy and verify live on the host

**Files:** none (deploy + manual verification)

- [ ] **Step 1: Deploy the real symlinks**

Run: `./deploy.sh`
Expected: `linked: ~/.config/waybar/config.jsonc` and `linked: ~/.config/waybar/style.css` in the output (any pre-existing real files are backed up to `~/.dotfiles-backup/...` first).

- [ ] **Step 2: Reload waybar in the running sway session**

Run: `swaymsg reload`
Expected: the bottom bar repaints with the new Kanagawa Dragon styling.

- [ ] **Step 3: Visual checklist (confirm each by eye)**

- Workspaces appear/disappear dynamically as you use them (sway default, unchanged); the focused one is bold yellow (`#e6c384`).
- `Mod+r` shows a bold `RESIZE` badge on the left; pressing `Escape` removes it.
- Clicking the caffeine (eye) icon toggles it to the accent color; clicking again reverts.
- Scrolling on the volume segment changes volume; clicking opens `pavucontrol`.
- Scrolling on the brightness segment changes screen brightness.
- The tray shows the nm-applet / polkit icons (they have somewhere to live now).
- The clock on the far right reads `  13 Jun  HH:MM`, matching the tmux format.
- Clicking the power icon (far right) opens a swaynag bar with Lock / Logout / Reboot / Poweroff buttons. (Dismiss with `Escape` — do not click Reboot/Poweroff during verification.)
- No IP address anywhere on the bar.

- [ ] **Step 4: Final confirmation**

Confirm `git status` is clean (all three commits landed) and the bar is styled. Implementation complete.

---

## Notes for the implementer

- **Live iteration:** while tweaking `style.css`, `killall -SIGUSR2 waybar` hot-reloads the stylesheet without a full sway reload. A `swaymsg reload` does a full waybar respawn.
- **Do not** add packages — every module here is built-in or uses a binary already installed (`brightnessctl`, `wpctl`, `pavucontrol` via `nm-applet`'s stack, `swaynag`, `nm-connection-editor`).
- **`pavucontrol`** is invoked on volume-click; it is not in the deploy apt list. If it is missing on the host the click is a no-op (not a crash). Adding it is out of scope for this plan — flag it as a possible follow-up if the user wants the click target to work.
