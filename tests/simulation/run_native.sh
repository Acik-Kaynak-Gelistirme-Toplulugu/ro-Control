#!/bin/bash
# ─────────────────────────────────────────────────────────────────────
# ro-Control — macOS Native Qt Simulation Launcher
# ─────────────────────────────────────────────────────────────────────
# Bu script PySide6 kurulu değilse otomatik kurar ve simülasyonu başlatır.
#
# Kullanım:
#   chmod +x run_native.sh
#   ./run_native.sh
# ─────────────────────────────────────────────────────────────────────

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

echo "╔═══════════════════════════════════════════════════════════╗"
echo "║  ro-Control — macOS Native Qt6 Simulation                ║"
echo "╚═══════════════════════════════════════════════════════════╝"
echo ""

# Python3 kontrolü
if ! command -v python3 &>/dev/null; then
    echo "❌  Python3 bulunamadı. Lütfen Python 3.9+ kurun."
    exit 1
fi

# PySide6 kontrolü
if ! python3 -c "import PySide6" 2>/dev/null; then
    echo "📦  PySide6 kurulu değil — kuruluyor..."
    pip3 install --user PySide6
    echo "✅  PySide6 kuruldu."
fi

echo "🚀  Simülasyon başlatılıyor..."
echo ""
python3 ro_control_native.py
