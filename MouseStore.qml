pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// All mouse state lives here: a bar widget is instantiated once per monitor,
// so a Process or Timer in Panel.qml would run twice on a two-monitor setup.
//
// The battery comes from bin/mouse-battery, which asks Solaar (read only).
// Nothing is polled faster than refreshIntervalSec, default three minutes: the
// answer is a slow-moving number and every query wakes the radio.
Singleton {
  id: root

  readonly property string helper:
    Qt.resolvedUrl("bin/mouse-battery").toString().replace(/^file:\/\//, "")

  // Written as \u escapes: a literal private-use glyph can be lost between
  // editor and disk without any error.
  readonly property string iconMouse: "󰍽"

  // Settings, pushed by Panel.qml.
  property string fontFamily: ""
  property string deviceMatch: "G502"
  property int refreshIntervalSec: 180
  property int lowThreshold: 15
  property bool notifications: true

  // Reading.
  property bool loaded: false
  property bool online: false
  property string deviceName: ""
  property int percent: -1
  property bool charging: false
  property string status: ""
  property int lastSeen: 0
  property string error: ""

  readonly property bool known: percent >= 0
  readonly property bool low: known && !charging && percent <= lowThreshold
  property int clockTick: 0

  readonly property string percentText: known ? percent + "%" : "--"

  function plain(s) { return String(s).replace(/[<>&]/g, " ") }

  function lastSeenText() {
    clockTick   // re-evaluated by the minute timer
    if (lastSeen <= 0) return "never"
    var d = new Date(lastSeen * 1000)
    return Qt.formatDateTime(d, "HH:mm")
  }

  readonly property string tooltip: {
    var name = deviceName !== "" ? deviceName : "Logitech mouse"
    if (!loaded) return name + "\nReading battery..."
    var lines = [name]
    if (!online) {
      lines.push(error !== "" ? error : "Disconnected")
      if (known) lines.push("Last battery: " + percent + "%")
    } else {
      lines.push("Battery: " + percentText)
      lines.push(charging ? "Charging" : "Not charging")
    }
    lines.push("Updated: " + lastSeenText())
    return lines.join("\n")
  }

  function apply(raw) {
    var d
    try { d = JSON.parse(raw) } catch (e) { return }
    online = d.online === true
    deviceName = String(d.name || "")
    percent = (typeof d.percent === "number") ? d.percent : -1
    charging = d.charging === true
    status = String(d.status || "")
    lastSeen = Number(d.last_seen || 0)
    error = String(d.error || "")
    loaded = true
  }

  function refresh() {
    if (query.running) return
    var cmd = [helper, "--device", deviceMatch]
    if (notifications && lowThreshold > 0) cmd = cmd.concat(["--notify-below", String(lowThreshold)])
    query.command = cmd
    query.running = true
  }

  Process {
    id: query
    stdout: StdioCollector { onStreamFinished: root.apply(text) }
  }

  Timer {
    interval: Math.max(60, root.refreshIntervalSec) * 1000
    running: true
    repeat: true
    triggeredOnStart: true
    onTriggered: root.refresh()
  }

  Timer {
    interval: 60000
    running: true
    repeat: true
    onTriggered: root.clockTick++
  }

  // --- actions ------------------------------------------------------------

  // Piper from the distro package, else the Flatpak. Detached: closing the
  // panel or restarting the shell must not close Piper.
  function openPiper() {
    Quickshell.execDetached(["sh", "-c",
      "if command -v piper >/dev/null 2>&1; then exec piper; " +
      "else exec flatpak run org.freedesktop.Piper; fi"])
  }

  function openSolaar() {
    Quickshell.execDetached(["sh", "-c",
      "if command -v solaar >/dev/null 2>&1; then exec solaar; " +
      "else exec flatpak run io.github.pwr_solaar.solaar; fi"])
  }
}
