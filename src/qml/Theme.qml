pragma Singleton
import QtQuick

QtObject {
    id: theme

    property bool isDark: false

    // Backgrounds
    readonly property color bg:           isDark ? "#1b2028" : "#f5f7f9"
    readonly property color surface:      isDark ? "#242b35" : "#ffffff"
    readonly property color surfaceAlt:   isDark ? "#1e252e" : "#f0f3f6"
    readonly property color surfaceHover: isDark ? "#2c3440" : "#eef1f5"
    readonly property color header:       isDark ? "#1e252e" : "#ffffff"
    readonly property color sidebar:      isDark ? "#181e25" : "#f0f2f5"

    // Text
    readonly property color text:         isDark ? "#e6edf3" : "#1f2328"
    readonly property color textSub:      isDark ? "#8b949e" : "#656d76"
    readonly property color textMuted:    isDark ? "#6e7681" : "#8c959f"

    // Borders
    readonly property color border:       isDark ? "#313840" : "#d0d7de"
    readonly property color borderSub:    isDark ? "#282f38" : "#e1e4e8"

    // Accent (KDE Breeze Blue)
    readonly property color primary:      isDark ? "#3daee9" : "#2980b9"
    readonly property color primaryBg:    isDark ? "#1a3a52" : "#deeffe"

    // Status
    readonly property color success:      isDark ? "#3fb950" : "#1a7f37"
    readonly property color successBg:    isDark ? "#162d1f" : "#dafbe1"
    readonly property color warning:      isDark ? "#d29922" : "#bf8700"
    readonly property color warningBg:    isDark ? "#2d2310" : "#fff8c5"
    readonly property color error:        isDark ? "#f85149" : "#cf222e"
    readonly property color errorBg:      isDark ? "#3d1418" : "#ffebe9"

    // Dimensions
    readonly property int radius:   10
    readonly property int radiusSm: 6
    readonly property int radiusLg: 14

    function alpha(c, a) {
        return Qt.rgba(c.r, c.g, c.b, a);
    }
}
