# Omarchy Logitech Mouse

The battery of a wireless Logitech mouse in the Omarchy bar, and a shortcut to [Piper](https://github.com/libratbag/piper) for buttons, DPI and profiles. Built and tested against a G502 X Plus (LIGHTSPEED).

## Features

- Mouse icon and battery percentage in the bar. Accent colour while charging, urgent colour at or below the low threshold, hidden when the mouse is off, unplugged or out of range (optionally greyed with the last percentage instead).
- Tooltip: device name, percentage, charging state and time of the last update.
- Left click opens Piper (the distro package, or the Flatpak if that is what is installed).
- Right click opens a small menu: Open Piper, Open Solaar, Refresh.
- One low-battery notification per episode, sent through the normal desktop notification service so notification archives pick it up. It re-arms once the battery is 5 points above the threshold or the mouse starts charging.

## How it reads the battery

`bin/mouse-battery` runs `solaar show <name>` (read only) and prints one line of JSON. The bar polls it every three minutes by default. UPower and sysfs do not expose this mouse, so Solaar is the source. Nothing in Solaar's or Piper's configuration is touched. The last good reading is cached in `~/.local/state/omarchy-logitech-mouse/state.json`.

Needs: `solaar`, `python3`, and `piper` (or its Flatpak) for the click action.

## Install

```bash
ln -s ~/Projects/omarchy-plugins/omarchy-logitech-mouse ~/.config/omarchy/plugins/diegodiaz1256.logitech-mouse
omarchy plugin enable diegodiaz1256.logitech-mouse
flock /tmp/omarchy-shell-restart.lock sh -c 'omarchy-restart-shell; sleep 15'
```

Once it lives in a git repository, `omarchy plugin add <git-url> --enable` works too.

## Settings

| Setting | Default | |
|---|---|---|
| Device name | `G502` | Part of the name Solaar shows. |
| Refresh interval | 180 s | 60 to 3600. |
| Low battery at | 15 % | 0 turns the notification off. |
| Low battery notification | On | |
| When the mouse is not connected | Hide | Hide the widget, or show it greyed with the last percentage. It looks again every minute while away. |
| Percentage in the bar | On | Icon only when off. Vertical bars always show the icon only. |

## Tests

```bash
python3 -m unittest discover -s test
omarchy plugin validate .
```
