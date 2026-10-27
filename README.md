# komorebi setup

My Windows tiling setup: [komorebi](https://github.com/LGUG2Z/komorebi) for tiling,
AutoHotkey for hotkeys, and [YASB](https://github.com/amnweb/yasb) as a bottom bar
that replaces the Windows taskbar (Aura Dark theme).

## What's in here

| File | What it does |
| --- | --- |
| `komorebi.json` | Main komorebi config (workspaces, borders, padding, extra manage rules) |
| `applications.json` | Community app rules, downloaded with `komorebic fetch-asc` |
| `komorebi.ahk` | Hotkeys (AutoHotkey v2) and hides the Windows taskbar |
| `switcher.ahk` | Alt+E window switcher, one row per monitor (included by `komorebi.ahk`) |
| `yasb/config.yaml` | YASB bar layout and widgets |
| `yasb/styles.css` | YASB theme (Aura Dark) |
| `komorebi.bar.json`, `komorebic2.bar.json` | Old komorebi-bar configs, no longer used |
| `test.ahk` | Scratch script for testing AutoHotkey hotkeys |

## Setting it up on a new PC

### 1. Install the apps

```powershell
winget install LGUG2Z.komorebi
winget install AutoHotkey.AutoHotkey
winget install AmN.yasb
```

Also install the **Geist Mono** font (https://vercel.com/font). The bar uses it.

### 2. Get the configs

Clone this repo to `C:\komorebi`. The configs use that path, so keep it there or
update the paths in `komorebi.json` and `yasb/config.yaml`.

```powershell
git clone <this repo> C:\komorebi
```

### 3. Point komorebi and YASB at the repo

```powershell
[Environment]::SetEnvironmentVariable('KOMOREBI_CONFIG_HOME', 'C:\komorebi', 'User')
[Environment]::SetEnvironmentVariable('YASB_CONFIG_HOME', 'C:\komorebi\yasb', 'User')
```

Sign out and back in (or restart) so every app picks these up.
`KOMOREBI_CONFIG_HOME` is what lets `--ahk` find `komorebi.ahk`. Without it,
komorebi starts but the hotkeys don't.

### 4. Start everything when Windows starts

komorebi starts from a Task Scheduler task that runs as soon as you sign in. A
Startup-folder shortcut (what `komorebic enable-autostart` makes) also works, but
Windows runs those only after every other startup app, which took 6+ minutes here.

```powershell
$u = "$env:USERDOMAIN\$env:USERNAME"
$action = New-ScheduledTaskAction -Execute 'C:\Program Files\komorebi\bin\komorebic-no-console.exe' `
  -Argument 'start --config "C:\komorebi\komorebi.json" --ahk' -WorkingDirectory 'C:\komorebi'
$trigger = New-ScheduledTaskTrigger -AtLogOn -User $u
$settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries `
  -ExecutionTimeLimit ([TimeSpan]::Zero) -Priority 4
$principal = New-ScheduledTaskPrincipal -UserId $u -LogonType Interactive -RunLevel Limited
Register-ScheduledTask -TaskName 'komorebi' -Action $action -Trigger $trigger `
  -Settings $settings -Principal $principal

yasbc enable-autostart
```

Don't add `--bar`, since YASB replaces komorebi-bar. To test the task without
restarting, run `Start-ScheduledTask -TaskName komorebi`.

### 5. Turn on taskbar auto-hide

Settings → Personalization → Taskbar → Taskbar behaviors →
**Automatically hide the taskbar**.

`komorebi.ahk` hides the taskbar completely, but auto-hide still needs to be on so
Windows doesn't keep reserving empty space for it. If space at the bottom still
looks reserved after turning it on, restart Explorer:

```powershell
Stop-Process -Name explorer -Force
```

### 6. Start it now

```powershell
komorebic start --config "C:\komorebi\komorebi.json" --ahk
yasbc start
```

## Hotkeys

| Keys | Action |
| --- | --- |
| `Alt + A/S/W/D` | Focus left / down / up / right |
| `Alt + Shift + A/S/W/D` | Move window left / down / up / right |
| `Alt + Arrow keys` | Stack window in that direction |
| `Alt + L` | Unstack |
| `Alt + J / K` | Previous / next window in the stack |
| `Alt + Shift + J / K` | Cycle focus previous / next |
| `Alt + 1–8` | Go to workspace |
| `Alt + Shift + 1–8` | Move window to workspace |
| `Alt + Shift + M` | Move window to the other monitor |
| `Alt + Q` | Close window |
| `Alt + M` | Minimize window |
| `Alt + U` | Promote window |
| `Alt + T` | Toggle float |
| `Alt + F` | Toggle monocle (fill the screen) |
| `Alt + R` | Retile (fixes ghost windows / gaps) |
| `Alt + P` | Pause / unpause komorebi |
| `Alt + X / Y` | Flip layout horizontally / vertically |
| `Alt + = / -` | Resize width |
| `Alt + Shift + = / _` | Resize height |
| `Alt + Shift + B` | Show / hide the Windows taskbar |
| `Alt + E` | Open / close the window switcher: top row is this monitor, bottom row the other one |
| `H/L` (in the switcher) | Left / right |
| `J/K` (in the switcher) | Down / up a row |
| `Tab` / `Shift + Tab` (in the switcher) | Next / previous window |
| `Enter`, `Space` or click (in the switcher) | Switch to the selected window |
| `Esc` or click elsewhere (in the switcher) | Close without switching |
| `Shift + PrtSc` / `Shift + Pause` | Volume down / up |
| `ScrollLock` | Play / pause media |
| `Alt + Pause` / `Alt + PrtSc` | Next / previous track |

## The bar (YASB)

Left to right: workspaces, the windows in the focused stack (click to switch,
scroll to cycle, middle-click to close), a taskbar of every open app including
minimized ones, then media and the clock.

YASB reloads automatically when you save `yasb/config.yaml` or `yasb/styles.css`.
The colours come from the Aura palette, and komorebi's window borders use it
too (`border_colours` in `komorebi.json`: blue single, purple stack, pink
monocle, orange floating):
https://github.com/daltonmenezes/aura-theme/blob/main/packages/color-palettes/aura-colors.css

## Tips

- **Updating app rules:** run `komorebic fetch-asc` to refresh `applications.json`.
  Put your own rules in `komorebi.json` instead, because `fetch-asc` overwrites
  `applications.json`.
- **Forcing an app to tile:** add it to `manage_rules` in `komorebi.json`. If it's a
  transparent or Electron app (like Claude), it may also need to go in
  `layered_applications`.
- **Reload vs restart:** `komorebic reload-configuration` picks up *new* rules, but
  removed rules stay active until komorebi restarts:
  `komorebic stop --ahk`, then `komorebic start --config "C:\komorebi\komorebi.json" --ahk`.
- **Minimized windows:** komorebi doesn't track them, so they disappear from the
  workspace icons. They still show in YASB's taskbar.
- **Logs:** komorebi writes logs to `%TEMP%\komorebi*.log`, and YASB writes
  `yasb/yasb.log` (ignored by git).
