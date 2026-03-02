cmake_minimum_required(VERSION 3.28)
project(ro-control VERSION 1.2.0)

# --- KDE Extra CMake Modules ---
find_package(ECM 6.0 REQUIRED NO_MODULE)
set(CMAKE_MODULE_PATH ${ECM_MODULE_PATH})

include(KDEInstallDirs)
include(KDECMakeSettings)
include(ECMUninstallTarget)

# Qt Quick Controls 2 with Breeze style (no Kirigami needed)
find_package(KF6 REQUIRED COMPONENTS QQC2DesktopStyle)

set(APP_ID "io.github.AcikKaynakGelistirmeToplulugu.ro-control")

# --- Build via Cargo ---
set(CARGO_BUILD_TYPE "$<IF:$<CONFIG:Debug>,debug,release>")
set(CARGO_FLAG "$<IF:$<CONFIG:Debug>,,--release>")

add_custom_target(ro-control-bin ALL
    COMMAND cargo build ${CARGO_FLAG} --target-dir ${CMAKE_CURRENT_BINARY_DIR}/cargo
    WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
    COMMENT "Building ro-control with Cargo..."
)

# --- Install ---

# Binary
install(
    PROGRAMS ${CMAKE_CURRENT_BINARY_DIR}/cargo/${CARGO_BUILD_TYPE}/ro-control
    DESTINATION ${KDE_INSTALL_BINDIR}
)

# Helper script
install(
    PROGRAMS scripts/ro-control-root-task
    DESTINATION ${KDE_INSTALL_BINDIR}
)

# Desktop entry
install(FILES data/${APP_ID}.desktop
    DESTINATION ${KDE_INSTALL_APPDIR})

# AppStream metainfo
install(FILES data/${APP_ID}.metainfo.xml
    DESTINATION ${KDE_INSTALL_METAINFODIR})

# Scalable icon
install(FILES data/icons/hicolor/scalable/apps/${APP_ID}.svg
    DESTINATION ${KDE_INSTALL_ICONS}/hicolor/scalable/apps/)

# Symbolic icon
if(EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/data/icons/hicolor/symbolic/apps/${APP_ID}-symbolic.svg")
    install(FILES data/icons/hicolor/symbolic/apps/${APP_ID}-symbolic.svg
        DESTINATION ${KDE_INSTALL_ICONS}/hicolor/symbolic/apps/)
endif()

# PolicyKit policy
install(FILES data/polkit/${APP_ID}.policy
    DESTINATION ${CMAKE_INSTALL_PREFIX}/share/polkit-1/actions/)

# GSettings schema (for settings persistence)
install(FILES data/${APP_ID}.gschema.xml
    DESTINATION ${CMAKE_INSTALL_PREFIX}/share/glib-2.0/schemas/)
