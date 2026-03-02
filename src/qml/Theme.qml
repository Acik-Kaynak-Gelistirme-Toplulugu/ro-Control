pragma Singleton
import QtQuick

QtObject {
    id: theme

    property bool isDark: false

    // Light mode colors
    readonly property color lightBackground: "#f5f7fa"
    readonly property color lightForeground: "#1a1d23"
    readonly property color lightCard: "#fcfcfc"
    readonly property color lightCardGlass: Qt.rgba(1, 1, 1, 0.9)
    readonly property color lightPrimary: "#3b82f6"
    readonly property color lightAccent: "#8b5cf6"
    readonly property color lightSuccess: "#10b981"
    readonly property color lightWarning: "#f59e0b"
    readonly property color lightError: "#ef4444"
    readonly property color lightBorder: "#e5e7eb"
    readonly property color lightMuted: "#f1f5f9"
    readonly property color lightMutedForeground: "#64748b"

    // Dark mode colors
    readonly property color darkBackground: "#0f1419"
    readonly property color darkForeground: "#e2e8f0"
    readonly property color darkCard: "#1e293b"
    readonly property color darkCardGlass: Qt.rgba(0.117, 0.16, 0.23, 0.8)
    readonly property color darkPrimary: "#60a5fa"
    readonly property color darkAccent: "#a78bfa"
    readonly property color darkSuccess: "#34d399"
    readonly property color darkWarning: "#fbbf24"
    readonly property color darkError: "#f87171"
    readonly property color darkBorder: "#334155"
    readonly property color darkMuted: "#1e293b"
    readonly property color darkMutedForeground: "#94a3b8"

    // Dynamic colors
    readonly property color background: isDark ? darkBackground : lightBackground
    readonly property color foreground: isDark ? darkForeground : lightForeground
    readonly property color card: isDark ? darkCard : lightCard
    readonly property color cardGlass: isDark ? darkCardGlass : lightCardGlass
    readonly property color primary: isDark ? darkPrimary : lightPrimary
    readonly property color accent: isDark ? darkAccent : lightAccent
    readonly property color success: isDark ? darkSuccess : lightSuccess
    readonly property color warning: isDark ? darkWarning : lightWarning
    readonly property color error: isDark ? darkError : lightError
    readonly property color border: isDark ? darkBorder : lightBorder
    readonly property color muted: isDark ? darkMuted : lightMuted
    readonly property color mutedForeground: isDark ? darkMutedForeground : lightMutedForeground

    // Text on primary/accent backgrounds (always white for both themes)
    readonly property color primaryForeground: "#ffffff"

    // Spacing
    readonly property int paddingXs: 8
    readonly property int paddingSm: 12
    readonly property int paddingMd: 16
    readonly property int paddingLg: 20
    readonly property int paddingXl: 24
    readonly property int padding2xl: 32

    // Border radius
    readonly property int radiusSm: 6
    readonly property int radiusMd: 8
    readonly property int radiusLg: 12
    readonly property int radiusXl: 16
    readonly property int radius2xl: 20

    // Font sizes
    readonly property int fontSizeXs: 12
    readonly property int fontSizeSm: 14
    readonly property int fontSizeMd: 16
    readonly property int fontSizeLg: 18
    readonly property int fontSizeXl: 20
    readonly property int fontSize2xl: 24
    readonly property int fontSize3xl: 30

    // Font weights
    readonly property int fontWeightNormal: Font.Normal
    readonly property int fontWeightMedium: Font.Medium
    readonly property int fontWeightBold: Font.Bold

    // Animation durations
    readonly property int animationFast: 150
    readonly property int animationNormal: 300
    readonly property int animationSlow: 500

    // Easing curves
    readonly property int easingStandard: Easing.OutCubic
    readonly property int easingDecelerate: Easing.OutQuad
    readonly property int easingAccelerate: Easing.InQuad

    // Icon sizes
    readonly property int iconSizeSm: 16
    readonly property int iconSizeMd: 20
    readonly property int iconSizeLg: 24
    readonly property int iconSizeXl: 32

    function alpha(c, a) {
        return Qt.rgba(c.r, c.g, c.b, a);
    }
}
