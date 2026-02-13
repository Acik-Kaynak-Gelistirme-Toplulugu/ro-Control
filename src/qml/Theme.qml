pragma Singleton
import QtQuick
import QtQuick.Controls

QtObject {
    id: theme

    // Detect system theme (Dark/Light) using SystemPalette
    // We instantiate a SystemPalette object to query system colors
    property SystemPalette palette: SystemPalette {
        colorGroup: SystemPalette.Active
    }

    // Determine dark mode based on window background brightness
    // If lightness is low (< 0.5), it's dark mode.
    property bool isDark: theme.palette.window.hslLightness < 0.5

    // ─── Font Settings ───
    property int fontSize: 16
    property int fontWeightNormal: 400
    property int fontWeightMedium: 500

    property font fontH1: Qt.font({ pixelSize: 24, weight: fontWeightMedium }) // text-2xl
    property font fontH2: Qt.font({ pixelSize: 20, weight: fontWeightMedium }) // text-xl
    property font fontH3: Qt.font({ pixelSize: 18, weight: fontWeightMedium }) // text-lg
    property font fontBody: Qt.font({ pixelSize: fontSize, weight: fontWeightNormal })

    // ─── Colors (Dynamic based on differs) ───

    // Backgrounds
    property color background: isDark ? "#1b1e20" : "#eff0f1"
    property color card:       isDark ? "#2a2e32" : "#fcfcfc"
    property color popover:    isDark ? "#2a2e32" : "#fcfcfc"
    property color sidebar:    isDark ? "#1b1e20" : "#eff0f1"
    property color overlay:    isDark ? "#000000" : "#ffffff"  // Custom extra

    // Foregrounds (Text)
    property color foreground:           isDark ? "#eff0f1" : "#232629"
    property color cardForeground:       isDark ? "#eff0f1" : "#232629"
    property color popoverForeground:    isDark ? "#eff0f1" : "#232629"
    property color sidebarForeground:    isDark ? "#eff0f1" : "#232629"
    property color mutedForeground:      "#7f8c8d"

    // Brand / Primary
    property color primary:           isDark ? "#3daee9" : "#2980b9"
    property color primaryForeground: isDark ? "#1b1e20" : "#ffffff"

    property color accent:            isDark ? "#3daee9" : "#2980b9"
    property color accentForeground:  isDark ? "#1b1e20" : "#ffffff"

    // Functional
    property color destructive:       isDark ? "#ed1515" : "#da4453"
    property color destructiveForeground: "#ffffff"
    
    property color success:           "#27ae60"
    property color warning:           isDark ? "#f67400" : "#f39c12"
    property color error:             isDark ? "#ed1515" : "#da4453"

    // UI Elements
    property color border:            isDark ? "#3e4349" : "#bdc3c7"
    property color input:             isDark ? "#2a2e32" : "transparent"
    property color inputBackground:   isDark ? "#2a2e32" : "#fcfcfc"
    property color ring:              isDark ? "#3daee9" : "#2980b9"

    // ─── Dimensions ───
    property int radius: 8 // 0.5rem approx
    property int radiusSm: 4
    property int radiusLg: 12

    // ─── Helper Functions ───
    function alpha(colorVal, alphaVal) {
        return Qt.rgba(colorVal.r, colorVal.g, colorVal.b, alphaVal)
    }
}
