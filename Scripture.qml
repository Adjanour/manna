import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui

BarWidget {
  id: root
  moduleName: "bernard.scripture"

  readonly property string home: Quickshell.env("HOME") || ""
  property string reference: ""
  property string verseText: ""
  property string version: ""
  property string verseUrl: ""

  function injectPanel() {
    var target = panelLoader.item
    if (!target) return
    if ("bar" in target) target.bar = root.bar
    if ("settings" in target) target.settings = root.settings
    if ("anchorItem" in target) target.anchorItem = button
    if ("hostWidget" in target) target.hostWidget = root
  }

  function refresh() {
    proc.running = true
  }

  function togglePanel() {
    if (panelLoader.item && panelLoader.item.toggle) panelLoader.item.toggle()
  }

  readonly property bool opened: panelLoader.item ? panelLoader.item.opened === true : false

  function open() {
    if (panelLoader.item && panelLoader.item.open) panelLoader.item.open()
  }

  function close() {
    if (panelLoader.item && panelLoader.item.close) panelLoader.item.close()
  }

  readonly property bool popoutSwitchClosing: panelLoader.item ? panelLoader.item.popoutSwitchClosing === true : false

  function closeForPopoutSwitch() {
    if (panelLoader.item && panelLoader.item.closeForPopoutSwitch) panelLoader.item.closeForPopoutSwitch()
  }

  function wrapText(text, width) {
    var words = String(text || "").split(/\s+/)
    var lines = []
    var line = ""
    for (var i = 0; i < words.length; i++) {
      var candidate = line === "" ? words[i] : line + " " + words[i]
      if (candidate.length > width && line !== "") {
        lines.push(line)
        line = words[i]
      } else {
        line = candidate
      }
    }
    if (line !== "") lines.push(line)
    return lines.join("\n")
  }

  readonly property string tooltip: reference === "" ? "" :
    reference + (version !== "" ? " (" + version + ")" : "") + "\n\n" + wrapText(verseText, 72)

  visible: reference !== ""
  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  onBarChanged: injectPanel()
  onSettingsChanged: injectPanel()

  Process {
    id: proc
    command: [root.home + "/.local/bin/scripture", "-j"]
    running: true
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        var raw = String(text || "").trim()
        if (!raw) return
        try {
          var data = JSON.parse(raw)
          root.reference = String(data.reference || "")
          root.verseText = String(data.text || "")
          root.version = String(data.version || "")
          root.verseUrl = String(data.url || "")
        } catch (e) {}
      }
    }
  }

  Timer {
    interval: 3600000
    running: true
    repeat: true
    triggeredOnStart: false
    onTriggered: { proc.running = true }
  }

  Loader {
    id: panelLoader
    active: true
    source: Qt.resolvedUrl("Panel.qml")
    visible: false
    onLoaded: {
      root.injectPanel()
      Qt.callLater(root.injectPanel)
    }
  }

  WidgetButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: root.reference
    labelVisible: true
    horizontalMargin: 8.75
    verticalPadding: 8.75
    tooltipText: root.tooltip
    onPressed: function(b) {
      if (b === Qt.RightButton) root.refresh()
      else if (b === Qt.MiddleButton) {
        if (root.bar) root.bar.run(home + "/.local/bin/scripture --notify")
      } else root.togglePanel()
    }
  }
}
