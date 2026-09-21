import QtQuick
import Quickshell
import qs.Commons
import qs.Ui

Panel {
  id: root
  moduleName: "bernard.scripture"
  ipcTarget: "bernard.scripture"
  manageIpc: false

  property var anchorItem: null
  property var hostWidget: null
  readonly property var barIdentity: hostWidget || root

  property string reference: ""
  property string verseText: ""
  property string version: ""
  property string verseUrl: ""
  property bool copied: false

  readonly property string home: Quickshell.env("HOME") || ""

  readonly property color contentForeground: bar ? bar.foreground : Color.foreground
  readonly property string contentFontFamily: bar ? bar.fontFamily : Style.font.family

  readonly property string tooltip: reference === "" ? "" :
    reference + (version !== "" ? " (" + version + ")" : "") + "\n\n" + wrapText(verseText, 72)

  function open() {
    refresh()
    root.controller.show()
    Qt.callLater(function() {
      if (root.opened && keyCatcher) keyCatcher.forceActiveFocus()
    })
  }

  function close() {
    root.controller.hide()
  }

  function toggle() { opened ? close() : open() }

  function switchPanel(direction) {
    if (root.bar && typeof root.bar.switchPanelFrom === "function")
      return root.bar.switchPanelFrom(root.barIdentity, direction)
    return false
  }

  function refresh() {
    if (hostWidget && hostWidget.refresh) hostWidget.refresh()
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

  function copyVerse() {
    root.copied = true
    copiedReset.restart()
    if (root.bar) root.bar.run(home + "/.local/bin/scripture --copy")
  }

  function openPassage() {
    if (root.bar) root.bar.run(home + "/.local/bin/scripture --open")
  }

  Timer {
    id: copiedReset
    interval: 1500
    onTriggered: root.copied = false
  }

  Component.onCompleted: syncData()

  function syncData() {
    if (!hostWidget) return
    root.reference = hostWidget.reference || ""
    root.verseText = hostWidget.verseText || ""
    root.version = hostWidget.version || ""
    root.verseUrl = hostWidget.verseUrl || ""
  }

  onHostWidgetChanged: syncData()

  Connections {
    target: hostWidget
    function onReferenceChanged() { root.reference = hostWidget.reference || "" }
    function onVerseTextChanged() { root.verseText = hostWidget.verseText || "" }
    function onVersionChanged() { root.version = hostWidget.version || "" }
    function onVerseUrlChanged() { root.verseUrl = hostWidget.verseUrl || "" }
  }

  KeyboardPanel {
    id: panel
    anchorItem: root.anchorItem
    owner: root.barIdentity
    bar: root.bar
    open: root.opened
    centerOnBar: true
    focusTarget: keyCatcher
    contentWidth: panel.fittedContentWidth(Style.space(440))
    contentHeight: panel.fittedContentHeight(contentColumn.implicitHeight)

    PanelKeyCatcher {
      id: keyCatcher
      anchors.fill: parent
      onCloseRequested: root.close()
      onTabRequested: function(direction) { root.switchPanel(direction) }

      Flickable {
        id: scroll
        anchors.fill: parent
        contentWidth: width
        contentHeight: contentColumn.implicitHeight
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        interactive: contentHeight > height

        Column {
          id: contentColumn
          width: scroll.width
          spacing: Style.space(16)

          Item {
            width: parent.width
            implicitHeight: Math.max(headerLabel.implicitHeight, dateLabel.implicitHeight)

            PanelSectionHeader {
              id: headerLabel
              anchors.left: parent.left
              anchors.verticalCenter: parent.verticalCenter
              text: "Verse of the day"
              foreground: root.contentForeground
              fontFamily: root.contentFontFamily
            }

            Text {
              id: dateLabel
              anchors.right: parent.right
              anchors.verticalCenter: parent.verticalCenter
              text: Qt.formatDate(new Date(), "d MMM yyyy")
              color: Qt.darker(root.contentForeground, 1.6)
              font.family: root.contentFontFamily
              font.pixelSize: Style.font.caption
            }
          }

          BorderSurface {
            id: card
            width: parent.width
            implicitHeight: cardColumn.implicitHeight + card.topPadding + card.bottomPadding
            color: Util.alpha(Color.accent, 0.05)
            borderSpec: Border.flat(Util.alpha(Color.accent, 0.16), Style.spacing.hairline)
            radius: Style.cornerRadius
            padding: Style.spacing.panelPadding

            Text {
              id: watermark
              text: "󰘓"
              color: Util.alpha(Color.accent, 0.10)
              font.family: root.contentFontFamily
              font.pixelSize: Math.round(Style.font.display * 2.2)
              anchors.left: parent.left
              anchors.top: parent.top
              anchors.leftMargin: Style.space(2)
              anchors.topMargin: Style.space(2)
            }

            Column {
              id: cardColumn
              anchors.left: parent.left
              anchors.right: parent.right
              anchors.top: parent.top
              anchors.margins: Style.spacing.panelPadding
              spacing: Style.space(14)

              Row {
                id: verseRow
                width: parent.width
                spacing: Style.space(14)

                Rectangle {
                  id: accentRule
                  width: Math.max(2, Style.space(2))
                  height: verseText.height
                  radius: width / 2
                  color: Util.alpha(Color.accent, 0.55)
                }

                Text {
                  id: verseText
                  width: verseRow.width - accentRule.width - verseRow.spacing
                  text: root.verseText
                  color: root.contentForeground
                  font.family: root.contentFontFamily
                  font.pixelSize: Style.font.title
                  lineHeight: 1.7
                  wrapMode: Text.WordWrap
                  textFormat: Text.PlainText
                }
              }

              Item {
                width: parent.width
                implicitHeight: attribution.implicitHeight

                Row {
                  id: attribution
                  anchors.right: parent.right
                  spacing: Style.space(8)

                  Text {
                    text: "—"
                    color: Qt.darker(root.contentForeground, 1.6)
                    font.family: root.contentFontFamily
                    font.pixelSize: Style.font.body
                  }

                  Text {
                    text: root.reference
                    color: Color.accent
                    font.family: root.contentFontFamily
                    font.pixelSize: Style.font.body
                    font.bold: true
                  }

                  BorderSurface {
                    visible: root.version !== ""
                    implicitWidth: versionText.implicitWidth + Style.space(10)
                    implicitHeight: versionText.implicitHeight + Style.space(4)
                    anchors.verticalCenter: parent.verticalCenter
                    color: "transparent"
                    borderSpec: Border.flat(Util.alpha(root.contentForeground, 0.22), Style.spacing.hairline)
                    radius: Style.cornerRadius

                    Text {
                      id: versionText
                      anchors.centerIn: parent
                      text: root.version
                      color: Qt.darker(root.contentForeground, 1.6)
                      font.family: root.contentFontFamily
                      font.pixelSize: Style.font.caption
                      font.bold: true
                    }
                  }
                }
              }
            }
          }

          Column {
            width: parent.width
            spacing: Style.space(10)

            PanelSeparator { foreground: root.contentForeground }

            Item {
              width: parent.width
              implicitHeight: actions.implicitHeight

              Row {
                id: actions
                anchors.right: parent.right
                spacing: Style.space(6)

                PanelActionButton {
                  iconText: root.copied ? "󰄬" : "󰅱"
                  tooltipText: root.copied ? "Copied" : "Copy verse"
                  foreground: root.contentForeground
                  fontFamily: root.contentFontFamily
                  onClicked: root.copyVerse()
                }

                PanelActionButton {
                  iconText: "󰔅"
                  tooltipText: "Open passage in browser"
                  foreground: root.contentForeground
                  fontFamily: root.contentFontFamily
                  onClicked: root.openPassage()
                }
              }
            }
          }
        }
      }
    }
  }
}
