#!/usr/bin/env bash
# dev-watch.sh — Kaynak değişikliklerini izler, otomatik build alır ve uygulamayı yeniden başlatır.
# Kullanım: ./scripts/dev-watch.sh
# Gereksinim: sudo dnf install inotify-tools

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}"]/.." && pwd)"
BUILD_DIR="${BUILD_DIR:-$ROOT_DIR/build}"
BINARY="$BUILD_DIR/ro-control"
APP_PID=""

# ─── Renk tanımları ──────────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
RESET='\033[0m'

log()  { echo -e "${CYAN}[dev-watch]${RESET} $*"; }
ok()   { echo -e "${GREEN}[dev-watch]${RESET} $*"; }
warn() { echo -e "${YELLOW}[dev-watch]${RESET} $*"; }
err()  { echo -e "${RED}[dev-watch]${RESET} $*"; }

# ─── Bağımlılık kontrolü ─────────────────────────────────────────────────────
if ! command -v inotifywait &>/dev/null; then
    err "inotify-tools bulunamadı. Kurmak için:"
    err "  sudo dnf install inotify-tools"
    exit 1
fi

if [[ ! -d "$BUILD_DIR" || ! -f "$BUILD_DIR/CMakeCache.txt" ]]; then
    warn "Build dizini yok veya cmake yapılandırılmamış."
    warn "Önce şunu çalıştır: ./scripts/fedora-bootstrap.sh"
    exit 1
fi

# ─── Uygulama durdurma ───────────────────────────────────────────────────────
stop_app() {
    if [[ -n "$APP_PID" ]] && kill -0 "$APP_PID" 2>/dev/null; then
        log "Uygulama durduruluyor (PID: $APP_PID)..."
        kill "$APP_PID" 2>/dev/null || true
        wait "$APP_PID" 2>/dev/null || true
        APP_PID=""
    fi
}

# ─── Build + başlat ──────────────────────────────────────────────────────────
build_and_run() {
    echo ""
    log "${BOLD}Incremental build başlıyor...${RESET}"
    if cmake --build "$BUILD_DIR" -j"$(nproc)" 2>&1; then
        ok "✓ Build başarılı"
        stop_app
        log "Uygulama başlatılıyor: $BINARY"
        "$BINARY" &
        APP_PID=$!
        ok "✓ ro-control çalışıyor (PID: $APP_PID)"
    else
        err "✗ Build hatası — bekleniyor..."
    fi
    echo ""
}

# ─── Temiz çıkış ─────────────────────────────────────────────────────────────
cleanup() {
    echo ""
    warn "Çıkış sinyali alındı."
    stop_app
    exit 0
}
trap cleanup SIGINT SIGTERM

# ─── İlk build ve başlangıç ──────────────────────────────────────────────────
echo -e "${BOLD}${CYAN}"
echo "╔══════════════════════════════════════════╗"
echo "║       ro-Control  dev-watch modu         ║"
echo "╚══════════════════════════════════════════╝"
echo -e "${RESET}"
log "İzlenen dizin: $ROOT_DIR/src"
log "Build dizini:  $BUILD_DIR"
log "Çıkmak için:   Ctrl+C"
echo ""

build_and_run

# ─── Değişiklik izleme döngüsü ───────────────────────────────────────────────
inotifywait -m -r \
    --include '\.(cpp|h|qml|js|ts)$' \
    -e modify,create,delete,moved_to \
    --format "%w%f  [%e]" \
    "$ROOT_DIR/src" "$ROOT_DIR/i18n" 2>/dev/null \
| while IFS= read -r line; do
    # Birden fazla hızlı değişikliği birleştir (debounce 800ms)
    log "Değişiklik algılandı: $line"
    sleep 0.8

    # Kuyruktaki diğer olayları boşalt
    while IFS= read -t 0.1 -r _extra; do :; done <&0 2>/dev/null || true

    build_and_run
done
