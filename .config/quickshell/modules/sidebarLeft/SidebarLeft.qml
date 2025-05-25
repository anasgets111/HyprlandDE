import "root:/"
import "root:/services"
import "root:/modules/common"
import "root:/modules/common/widgets"
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Effects
import Qt5Compat.GraphicalEffects
import Quickshell.Io
import Quickshell
import Quickshell.Widgets
import Quickshell.Wayland
import Quickshell.Hyprland

Scope { // Scope
    id: root
    property int sidebarPadding: 15
    property var tabButtonList: [{"icon": "neurology", "name": qsTr("Intelligence")}, {"icon": "bookmark_heart", "name": qsTr("Anime")}]

    Loader {
        id: sidebarLoader
        active: false
        onActiveChanged: {
            GlobalStates.sidebarLeftOpen = sidebarLoader.active
        }
        
        PanelWindow { // Window
            id: sidebarRoot
            visible: sidebarLoader.active
            
            property int selectedTab: 0
            property bool extend: false
            property bool pin: false
            property real sidebarWidth: sidebarRoot.extend ? Appearance.sizes.sidebarWidthExtended : Appearance.sizes.sidebarWidth

            function hide() {
                sidebarLoader.active = false
            }

            exclusiveZone: sidebarRoot.pin ? sidebarWidth : 0
            implicitWidth: Appearance.sizes.sidebarWidthExtended
            WlrLayershell.namespace: "quickshell:sidebarLeft"
            // Hyprland 0.49: OnDemand is Exclusive, Exclusive just breaks click-outside-to-close
            // WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
            color: "transparent"

            anchors {
                top: true
                left: true
                bottom: true
            }

            mask: Region {
                item: sidebarLeftBackground
            }

            HyprlandFocusGrab { // Click outside to close
                id: grab
                windows: [ sidebarRoot ]
                active: sidebarRoot.visible && !sidebarRoot.pin
                onActiveChanged: { // Focus the selected tab
                    if (active) swipeView.currentItem.forceActiveFocus()
                }
                onCleared: () => {
                    if (!active) sidebarRoot.hide()
                }
            }

            // Background
            Rectangle {
                id: sidebarLeftBackground

                anchors.top: parent.top
                anchors.left: parent.left
                anchors.topMargin: Appearance.sizes.hyprlandGapsOut
                anchors.leftMargin: Appearance.sizes.hyprlandGapsOut
                width: sidebarRoot.sidebarWidth - Appearance.sizes.hyprlandGapsOut * 2
                height: parent.height - Appearance.sizes.hyprlandGapsOut * 2
                color: Qt.rgba(
                    Appearance.colors.colLayer0.r,
                    Appearance.colors.colLayer0.g,
                    Appearance.colors.colLayer0.b,
                    1 - AppearanceSettingsState.sidebarTransparency
                )
                radius: Appearance.rounding.screenRounding - Appearance.sizes.elevationMargin + 1
                focus: sidebarRoot.visible

                // Add border
                Rectangle {
                    id: border
                    anchors.fill: parent
                    color: "transparent"
                    radius: parent.radius
                    border.width: 2
                    border.color: Qt.rgba(1, 1, 1, 0.2)
                }

                layer.enabled: true
                layer.effect: MultiEffect {
                    source: sidebarLeftBackground
                    anchors.fill: sidebarLeftBackground
                    shadowEnabled: true
                    shadowColor: Appearance.colors.colShadow
                    shadowVerticalOffset: 1
                    shadowBlur: 0.5
                }

                Behavior on width {
                    animation: Appearance.animation.elementMove.numberAnimation.createObject(this)
                }

                Behavior on color {
                    ColorAnimation {
                        duration: Appearance.animation.elementMoveFast.duration
                        easing.type: Appearance.animation.elementMoveFast.type
                    }
                }

                Keys.onPressed: (event) => {
                    // console.log("Key pressed: " + event.key)
                    if (event.key === Qt.Key_Escape) {
                        sidebarRoot.hide();
                    }
                    if (event.modifiers === Qt.ControlModifier) {
                        if (event.key === Qt.Key_PageDown) {
                            sidebarRoot.selectedTab = Math.min(sidebarRoot.selectedTab + 1, root.tabButtonList.length - 1)
                        } 
                        else if (event.key === Qt.Key_PageUp) {
                            sidebarRoot.selectedTab = Math.max(sidebarRoot.selectedTab - 1, 0)
                        }
                        else if (event.key === Qt.Key_Tab) {
                            sidebarRoot.selectedTab = (sidebarRoot.selectedTab + 1) % root.tabButtonList.length;
                        }
                        else if (event.key === Qt.Key_Backtab) {
                            sidebarRoot.selectedTab = (sidebarRoot.selectedTab - 1 + root.tabButtonList.length) % root.tabButtonList.length;
                        }
                        else if (event.key === Qt.Key_O) {
                            sidebarRoot.extend = !sidebarRoot.extend;
                        }
                        else if (event.key === Qt.Key_P) {
                            sidebarRoot.pin = !sidebarRoot.pin;
                        }
                        event.accepted = true;
                    }
                }

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: sidebarPadding
                    
                    spacing: sidebarPadding

                    PrimaryTabBar { // Tab strip
                        id: tabBar
                        tabButtonList: root.tabButtonList
                        externalTrackedTab: sidebarRoot.selectedTab
                        function onCurrentIndexChanged(currentIndex) {
                            sidebarRoot.selectedTab = currentIndex
                        }
                    }

                    SwipeView { // Content pages
                        id: swipeView
                        Layout.topMargin: 5
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        spacing: 10
                        
                        currentIndex: tabBar.externalTrackedTab
                        onCurrentIndexChanged: {
                            tabBar.enableIndicatorAnimation = true
                            sidebarRoot.selectedTab = currentIndex
                        }

                        clip: true
                        layer.enabled: true
                        layer.effect: OpacityMask {
                            maskSource: Rectangle {
                                width: swipeView.width
                                height: swipeView.height
                                radius: Appearance.rounding.small
                            }
                        }

                        AiChat {
                            panelWindow: sidebarRoot
                        }
                        Anime {
                            panelWindow: sidebarRoot
                        }
                    }
                    
                }
            }

        }
    }

    IpcHandler {
        target: "sidebarLeft"

        function toggle(): void {
            sidebarLoader.active = !sidebarLoader.active
            if(sidebarLoader.active) Notifications.timeoutAll();
        }

        function close(): void {
            sidebarLoader.active = false
        }

        function open(): void {
            sidebarLoader.active = true
            if(sidebarLoader.active) Notifications.timeoutAll();
        }
    }

    GlobalShortcut {
        name: "sidebarLeftToggle"
        description: qsTr("Toggles left sidebar on press")

        onPressed: {
            sidebarLoader.active = !sidebarLoader.active;
            if(sidebarLoader.active) Notifications.timeoutAll();
        }
    }

    GlobalShortcut {
        name: "sidebarLeftOpen"
        description: qsTr("Opens left sidebar on press")

        onPressed: {
            sidebarLoader.active = true;
            if(sidebarLoader.active) Notifications.timeoutAll();
        }
    }

    GlobalShortcut {
        name: "sidebarLeftClose"
        description: qsTr("Closes left sidebar on press")

        onPressed: {
            sidebarLoader.active = false;
        }
    }

}
