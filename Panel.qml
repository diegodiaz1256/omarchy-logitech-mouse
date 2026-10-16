import QtQuick
import qs.Commons
import qs.Ui

// Logitech mouse: battery in the bar, Piper one click away.
//
// Left click opens Piper (buttons, DPI, profiles). Right click opens a small
// menu with Piper, Solaar and a refresh. The tooltip carries the detail.
Panel {
  id: root

  moduleName: "diegodiaz1256.logitech-mouse"
  ipcTarget: "diegodiaz1256.logitech-mouse"

  readonly property color foreground: bar ? bar.foreground : Color.foreground
  readonly property color urgent: bar ? bar.urgent : Color.urgent
  readonly property color accent: Color.accent
  readonly property color dim: Qt.darker(foreground, 1.55)
  readonly property string fontFamily: bar ? bar.fontFamily : Style.font.family

  readonly property bool vertical: bar ? bar.vertical : false
  property bool showPercent: true
  // "hide" (default) removes the widget while the mouse is not connected;
  // "grey" keeps it with the last known percentage.
  property string whenDisconnected: "hide"
  readonly property bool shown: MouseStore.online || (whenDisconnected === "grey" && MouseStore.loaded)

  // Disconnected or unknown: greyed. Low: urgent. Charging: accent.
  readonly property color barIconColor: {
    if (!MouseStore.online) return Qt.darker(foreground, 1.9)
    if (MouseStore.charging) return accent
    if (MouseStore.low) return urgent
    return foreground
  }

  // Panel is a bare Item: without an explicit size the bar gives it zero width
  // and the widget paints but cannot be clicked.
  readonly property bool textShown: showPercent && !vertical
  readonly property int barContentWidth: Style.bar.iconFont + (textShown ? measure.implicitWidth + Style.space(4) : 0)
  readonly property int barSlot: barContentWidth + Style.space(10)
  readonly property real openPanelIndicatorWidth: barContentWidth
  readonly property real openPanelIndicatorHeight: Style.bar.iconFont
  // Hidden means no space at all, not just no paint.
  visible: shown
  implicitWidth: !shown ? 0 : (vertical ? (bar ? bar.barSize : Style.bar.sizeHorizontal) : barSlot)
  implicitHeight: !shown ? 0 : (vertical ? barSlot : (bar ? bar.barSize : Style.bar.sizeHorizontal))

  Text {
    id: measure
    visible: false
    text: "100%"
    font.family: root.fontFamily
    font.pixelSize: Style.font.caption
  }

  function applySettings() {
    MouseStore.fontFamily = root.fontFamily
    MouseStore.deviceMatch = String(root.setting("deviceMatch", "G502")) || "G502"
    MouseStore.refreshIntervalSec = Number(root.setting("refreshIntervalSec", 180))
    MouseStore.lowThreshold = Number(root.setting("lowThreshold", 15))
    MouseStore.notifications = String(root.setting("notifications", "on")) !== "off"
    root.showPercent = String(root.setting("showPercent", "on")) !== "off"
    root.whenDisconnected = String(root.setting("whenDisconnected", "hide")) === "grey" ? "grey" : "hide"
  }

  // The host assigns settings after construction, so read them on change too.
  onSettingsChanged: root.applySettings()
  Component.onCompleted: root.applySettings()

  onOpenedChanged: if (opened) MouseStore.refresh()

  BarIconButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    slotSize: root.barSlot
    opticalSize: root.barContentWidth
    tooltipText: MouseStore.plain(MouseStore.tooltip)

    iconComponent: Component {
      Item {
        Row {
          anchors.centerIn: parent
          spacing: Style.space(4)

          Text {
            anchors.verticalCenter: parent.verticalCenter
            text: MouseStore.iconMouse
            textFormat: Text.PlainText
            font.family: root.fontFamily
            font.pixelSize: Style.bar.iconFont
            renderType: Text.NativeRendering
            color: root.barIconColor
          }

          Text {
            anchors.verticalCenter: parent.verticalCenter
            visible: root.textShown
            text: MouseStore.percentText
            textFormat: Text.PlainText
            font.family: root.fontFamily
            font.pixelSize: Style.font.caption
            renderType: Text.NativeRendering
            color: root.barIconColor
          }
        }
      }
    }

    onPressed: function(buttonCode) {
      if (buttonCode === Qt.RightButton) root.toggle()
      else MouseStore.openPiper()
    }
  }

  KeyboardPanel {
    id: panel
    anchorItem: button
    owner: root
    bar: root.bar
    open: root.opened
    focusTarget: keyCatcher

    contentWidth: Math.min(Style.space(260),
                           panel.availableCardWidth > 0 ? panel.availableCardWidth : Style.space(260))
    contentHeight: panel.fittedContentHeight(menuColumn.implicitHeight, Style.space(400))

    PanelKeyCatcher {
      id: keyCatcher
      anchors.fill: parent
      onCloseRequested: root.close()

      Column {
        id: menuColumn
        width: parent.width
        spacing: 0

        Text {
          width: parent.width
          text: MouseStore.deviceName !== "" ? MouseStore.deviceName : "Logitech mouse"
          textFormat: Text.PlainText
          elide: Text.ElideRight
          color: root.foreground
          font.family: root.fontFamily
          font.pixelSize: Style.font.body
        }

        Text {
          width: parent.width
          topPadding: Style.space(2)
          bottomPadding: Style.space(8)
          text: {
            if (!MouseStore.loaded) return "Reading battery..."
            if (!MouseStore.online) {
              return (MouseStore.error !== "" ? MouseStore.error : "Disconnected")
                     + (MouseStore.known ? ", last seen at " + MouseStore.lastSeenText()
                                           + " with " + MouseStore.percent + "%" : "")
            }
            return MouseStore.percent + "%, " + (MouseStore.charging ? "charging" : "not charging")
                   + ", updated " + MouseStore.lastSeenText()
          }
          textFormat: Text.PlainText
          wrapMode: Text.WordWrap
          color: MouseStore.low ? root.urgent : root.dim
          font.family: root.fontFamily
          font.pixelSize: Style.font.caption
        }

        PanelSeparator { width: parent.width; foreground: root.foreground }

        MenuRow {
          width: parent.width
          label: "Open Piper…"
          foreground: root.foreground
          fontFamily: root.fontFamily
          onClicked: { MouseStore.openPiper(); root.close() }
        }

        MenuRow {
          width: parent.width
          label: "Open Solaar…"
          foreground: root.foreground
          fontFamily: root.fontFamily
          onClicked: { MouseStore.openSolaar(); root.close() }
        }

        PanelSeparator { width: parent.width; foreground: root.foreground }

        MenuRow {
          width: parent.width
          label: "Refresh"
          foreground: root.foreground
          fontFamily: root.fontFamily
          onClicked: MouseStore.refresh()
        }
      }
    }
  }
}
