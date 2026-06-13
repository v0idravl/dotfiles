# Workflow Cheatsheet

The whole desktop workflow on one page: **sway** (window manager), **waybar**
(status bar), **tmux** (terminal multiplexer), and the **zsh prompt**. Theme is
Kanagawa Dragon throughout.

- **Sway mod key** = `Super` (the Windows/⌘ key), written `Mod` below.
- **Tmux prefix** = `Ctrl+a` (then release, then the key), written `⌘a` below.
- Reload sway after editing its config: `Mod+Shift+c`. Reload tmux: `⌘a r`.

---

## Sway — windows & session

| Keys | Action |
|------|--------|
| `Mod+Return` | New terminal (alacritty) |
| `Mod+d` | App launcher (fuzzel) |
| `Mod+q` | Close focused window |
| `Mod+h/j/k/l` *or* arrows | Move focus left/down/up/right |
| `Mod+Shift+h/j/k/l` | Move the window left/down/up/right |
| `Mod+b` | Split next window horizontally |
| `Mod+v` | Split next window vertically |
| `Mod+f` | Fullscreen toggle |
| `Mod+Shift+Space` | Float/unfloat the window |
| `Mod+Space` | Toggle focus between tiled and floating |
| `Mod+r` | Enter **resize** mode → `h/j/k/l` to size → `Enter`/`Esc` to exit |
| `Mod+Shift+c` | Reload sway config |
| `Mod+Shift+e` | Exit sway (asks to confirm) |

### Workspaces
| Keys | Action |
|------|--------|
| `Mod+1` … `Mod+9` | Switch to workspace 1–9 |
| `Mod+Shift+1` … `Mod+Shift+9` | Move focused window to workspace 1–9 |

### Media, brightness, screenshots, lock
| Keys | Action |
|------|--------|
| `Fn` volume keys (`XF86Audio*`) | Volume up / down / mute (wireplumber)¹ |
| `Fn+F5` / `Fn+F6` (`XF86MonBrightness*`) | Screen brightness down / up |
| `Print` *or* `Mod+Shift+s` | Region screenshot → clipboard (grim + slurp) |
| `Mod+Escape` | Lock screen now (swaylock) |

Idle behavior (swayidle): lock at 5 min, screen off at 10 min, lock before sleep.

¹ Volume keys are wired but currently silent — **no audio device is detected**
(see Known Issues).

---

## Waybar — the bottom bar

Left → right. Flat Kanagawa Dragon styling, no dividers; the focused workspace
is bold yellow.

**Left:** workspaces · resize-mode badge (shows `RESIZE` only while in `Mod+r`
mode) · focused window title.

**Right cluster:**

| Module | Icon | Interaction |
|--------|------|-------------|
| CPU |  | — |
| Memory | 󰍛 | — |
| Temperature |  | turns red past 85 °C |
| Brightness |  | **scroll** to adjust |
| Caffeine (idle inhibitor) |  /  | **click** to keep the screen awake (blocks idle lock); icon goes yellow when active |
| Volume |  | **click** → pavucontrol · **scroll** → volume¹ |
| Network |  /  | **click** → nm-connection-editor |
| Battery |  …  | charging shows a bolt; warns <30%, critical <15% |
| Tray | — | nm-applet / polkit live here |
| Power |  | **click** → menu: Lock / Logout / Reboot / Poweroff |

The clock is intentionally **not** on the bar — tmux already shows the time.

Restart the bar after editing its config (a plain `swaymsg reload` won't, since
sway `exec`s it once at login):
```bash
killall waybar 2>/dev/null; swaymsg exec waybar
```

---

## Tmux — terminal multiplexer

Prefix is `Ctrl+a` (`⌘a`). Windows and panes are 1-indexed.

### Panes
| Keys | Action |
|------|--------|
| `⌘a \|` | Split pane horizontally (keeps current dir) |
| `⌘a -` | Split pane vertically (keeps current dir) |
| `⌘a h/j/k/l` | Move to pane left/down/up/right |
| `Alt+arrows` | Move between panes (no prefix — fast switching) |
| `⌘a S` | Toggle **synchronize-panes** (type into all panes at once) |
| `⌘a z` | Zoom/unzoom the focused pane (tmux default) |
| `⌘a x` | Kill the focused pane (tmux default) |

### Windows & session
| Keys | Action |
|------|--------|
| `⌘a c` | New window |
| `⌘a 1…9` | Go to window N |
| `⌘a n` / `⌘a p` | Next / previous window |
| `⌘a ,` | Rename window |
| `⌘a d` | Detach session |
| `⌘a r` | Reload `~/.tmux.conf` |

### Copy mode (vi keys)
| Keys | Action |
|------|--------|
| `⌘a [` | Enter copy mode (scroll back with `k`/`j`, `Ctrl-u`/`Ctrl-d`) |
| `Space` | Start selection |
| `y` | Yank selection → system clipboard (xclip) |
| `q` | Leave copy mode |

Mouse is on (click panes, drag borders, wheel-scroll into copy mode). Scrollback
is 50k lines.

---

## The zsh prompt

```
┌──( )-[ ~/Projects/dotfiles]
└─
```
- **Host:** opens with the **dragon** glyph () — just the dragon, no username
  (by preference). Two-line prompt: top line is dragon + current path; bottom
  line is the input caret.
- **Kali (over SSH):** the prompt uses the **skull** glyph () and a red palette
  so you always know which box you're on. Its tmux bar shows the dragon + a star
  separator before the session name.
- The repo ships an "evil twin" Kali variant of `.zshrc`, `.tmux.conf`, and the
  nvim config — deployed with `./deploy.sh --kali`.

---

## Deploy

```bash
./deploy.sh            # host: symlinks configs, installs desktop stack
./deploy.sh --kali     # kali: swaps in the kali/ variants, headless (no sway/waybar)
./deploy.sh --dry-run  # show what would change, touch nothing
```
Originals are backed up to `~/.dotfiles-backup/<timestamp>/` before being replaced.

---

## Known issues

- **No audio device.** The kernel detects no soundcard (`/proc/asound/cards` is
  empty) even though `firmware-sof-signed` is installed, so volume keys and the
  waybar volume control have nothing to drive. This is a driver/kernel-enablement
  issue, parked for a separate session (start with `lspci | grep -i audio`,
  `lsmod | grep snd`, `sudo dmesg | grep -i sof`).
