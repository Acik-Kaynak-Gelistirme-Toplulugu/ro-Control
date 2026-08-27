#!/usr/bin/env bash
# dev-watch.sh — Kaynak degisikliklerini izler, otomatik build alir ve uygulamayi yeniden baslatir.
# Kullanim: ./scripts/dev-watch.sh
# Gereksinim: Ro-ASD gelistirme ortaminda inotify-tools

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_DIR="${BUILD_DIR:-$ROOT_DIR/build}"
BINARY="$BUILD_DIR/ro-control"
APP_PID=""

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
RESET='\033[0m'

log()  { echo -e "${CYAN}[dev-watch]${RESET} $*"; }
ok()   { echo -e "${GREEN}[dev-watch]${RESET} $*"; }
warn() { echo -e "${YELLOW}[dev-watch]${RESET} $*"; }
err()  { echo -e "${RED}[dev-watch]${RESET} $*"; }

setup_qt_env() {
    if [[ -n "${QSG_RHI_BACKEND:-}" || -n "${QT_XCB_GL_INTEGRATION:-}" ]]; then
        return
    fi

    if command -v glxinfo &>/dev/null && glxinfo 2>/dev/null | grep -q "direct rendering: Yes"; then
        log "OpenGL hardware acceleration detected; using the default Qt renderer."
    else
        warn "No GPU/EGL acceleration detected; falling back to the software-friendly Qt path."
        export QT_XCB_GL_INTEGRATION=none
        export LIBGL_ALWAYS_SOFTWARE=0
        export QSG_RENDERER_DEBUG=""
    fi
}

if ! command -v inotifywait &>/dev/null; then
    err "inotify-tools bulunamadi. Kurmak icin:"
    err "  Ro-ASD paket yoneticisi ile inotify-tools kur"
    exit 1
fi

if [[ ! -d "$BUILD_DIR" || ! -f "$BUILD_DIR/CMakeCache.txt" ]]; then
    warn "Build directory is missing or not configured with CMake."
    warn "Run ./scripts/fedora-bootstrap.sh first."
    exit 1
fi

if [[ ! -f "$BINARY" ]]; then
    warn "Binary not found: $BINARY"
    warn "Run ./scripts/fedora-bootstrap.sh first."
    exit 1
fi

stop_app() {
    if [[ -n "$APP_PID" ]] && kill -0 "$APP_PID" 2>/dev/null; then
        log "Stopping ro-control (PID: $APP_PID)..."
        kill "$APP_PID" 2>/dev/null || true
        wait "$APP_PID" 2>/dev/null || true
        APP_PID=""
    fi
}

build_and_run() {
    echo ""
    log "Starting incremental build..."
    if cmake --build "$BUILD_DIR" -j"$(nproc)" 2>&1; then
        ok "Build completed successfully."
        stop_app
        log "Launching ro-control..."
        "$BINARY" 2>/dev/null &
        APP_PID=$!
        ok "ro-control is running (PID: $APP_PID)."
    else
        err "Build failed. Review the changes above."
    fi
    echo ""
}

cleanup() {
    echo ""
    warn "Exit signal received."
    stop_app
    exit 0
}
trap cleanup SIGINT SIGTERM

setup_qt_env

echo ""
log "ro-Control dev-watch mode"
log "Project root : $ROOT_DIR"
log "Build dir    : $BUILD_DIR"
log "Watching     : $ROOT_DIR/src"
log "Exit         : Ctrl+C"
echo ""

build_and_run

inotifywait -m -r \
    --include '\.(cpp|h|qml|js|ts)$' \
    -e modify,create,delete,moved_to \
    --format "%w%f  [%e]" \
    "$ROOT_DIR/src" "$ROOT_DIR/i18n" 2>/dev/null \
| while IFS= read -r line; do
    log "Change detected: $line"
    sleep 0.8

    while IFS= read -t 0.1 -r _extra; do :; done <&0 2>/dev/null || true

    build_and_run
done
