"""
ro-Control — macOS Native Qt6 Simulation  (v2 – HTML-faithful)
───────────────────────────────────────────────────────────────
Tamamen PySide6 widget'larıyla çalışır.  HTML/WebEngine kullanmaz.
HTML simülasyonundaki tasarımı birebir takip eder.

Çalıştırma:
    pip install PySide6
    python3 ro_control_native.py
"""

import sys, os, random, math
from datetime import datetime

from PySide6.QtWidgets import (
    QApplication, QMainWindow, QWidget, QVBoxLayout, QHBoxLayout,
    QLabel, QPushButton, QStackedWidget, QFrame, QScrollArea,
    QRadioButton, QButtonGroup, QCheckBox, QTextEdit, QDialog,
    QGridLayout, QSizePolicy, QGraphicsDropShadowEffect, QStyle,
    QStyleFactory,
)
from PySide6.QtCore import (
    Qt, QTimer, QPropertyAnimation, QEasingCurve, QSize, Signal,
    QRect, QPoint, QEvent,
)
from PySide6.QtGui import (
    QFont, QColor, QPalette, QLinearGradient, QPainter,
    QBrush, QPen, QPainterPath, QFontDatabase, QCursor,
)


# ╔═══════════════════════════════════════════╗
# ║  THEME (CSS variable karşılığı)           ║
# ╚═══════════════════════════════════════════╝

_DARK = False

def _d():
    return _DARK

# Light
_L = {
    "bg":       "#f5f7fa",  "fg":       "#1a1d23",
    "card":     "#fcfcfc",  "card-glass":"rgba(255,255,255,0.9)",
    "primary":  "#3b82f6",  "accent":   "#8b5cf6",
    "success":  "#10b981",  "warning":  "#f59e0b",
    "error":    "#ef4444",  "border":   "#e5e7eb",
    "muted":    "#f1f5f9",  "muted-fg": "#64748b",
}
# Dark
_DK = {
    "bg":       "#0f1419",  "fg":       "#e2e8f0",
    "card":     "#1e293b",  "card-glass":"rgba(30,41,59,0.8)",
    "primary":  "#60a5fa",  "accent":   "#a78bfa",
    "success":  "#34d399",  "warning":  "#fbbf24",
    "error":    "#f87171",  "border":   "#334155",
    "muted":    "#1e293b",  "muted-fg": "#94a3b8",
}

def C(key):
    """Tema rengi al."""
    return (_DK if _DARK else _L)[key]


# ╔═══════════════════════════════════════════╗
# ║  SABİTLER                                 ║
# ╚═══════════════════════════════════════════╝

APP_VERSION = "1.1.0"
VERSIONS = [
    {"ver":"560.35.03","src":"RPM Fusion","note":"Latest stable","latest":True},
    {"ver":"555.58.02","src":"RPM Fusion","note":"Production branch","latest":False},
    {"ver":"550.120",  "src":"RPM Fusion","note":"LTS / Enterprise","latest":False},
    {"ver":"545.29.06","src":"RPM Fusion","note":"Legacy","latest":False},
    {"ver":"535.183.01","src":"RPM Fusion","note":"Legacy LTS","latest":False},
]
LATEST = VERSIONS[0]["ver"]
VRAM_T = 12288
RAM_T  = 32768


# ╔═══════════════════════════════════════════╗
# ║  YARDIMCI                                 ║
# ╚═══════════════════════════════════════════╝

def _f(sz=13, bold=False, family=None):
    name = family or ("Inter" if QFontDatabase.hasFamily("Inter") else
                      (".AppleSystemUIFont" if sys.platform=="darwin" else "Segoe UI"))
    f = QFont(name, sz)
    f.setBold(bold)
    return f

def _lbl(txt, sz=13, bold=False, color=None, wrap=False):
    l = QLabel(txt)
    l.setFont(_f(sz, bold))
    l.setStyleSheet(f"color:{color or C('fg')};background:transparent;")
    if wrap:
        l.setWordWrap(True)
    return l

def _shadow(w, blur=24, dy=4, alpha=0.06):
    e = QGraphicsDropShadowEffect(w)
    e.setBlurRadius(blur)
    e.setOffset(0, dy)
    e.setColor(QColor(0,0,0,int(alpha*255)))
    w.setGraphicsEffect(e)


# ╔═══════════════════════════════════════════╗
# ║  GRADIENT BAR  (shimmer dahil)            ║
# ╚═══════════════════════════════════════════╝

class GradientBar(QWidget):
    def __init__(self, colors=None, h=10, parent=None):
        super().__init__(parent)
        self.setFixedHeight(h)
        self._h = h
        self._val = 0
        self._colors = colors or [QColor("#3b82f6"), QColor("#8b5cf6")]
        self._shimmer_x = 0.0
        t = QTimer(self); t.timeout.connect(self._tick); t.start(35)

    def setValue(self, v):
        self._val = max(0, min(100, v))
        self.update()

    def set_colors(self, cols):
        self._colors = [QColor(c) for c in cols]
        self.update()

    def _tick(self):
        self._shimmer_x += 0.025
        if self._shimmer_x > 1.5: self._shimmer_x = -0.5
        if self._val > 0: self.update()

    def paintEvent(self, _):
        p = QPainter(self); p.setRenderHint(QPainter.Antialiasing)
        r = self.rect(); rad = self._h / 2

        # track
        p.setPen(Qt.NoPen)
        p.setBrush(QColor(C("muted")))
        p.drawRoundedRect(r, rad, rad)

        if self._val <= 0: return

        fw = max(int(r.width() * self._val / 100), int(rad*2))
        fr = QRect(r.x(), r.y(), fw, r.height())

        # fill gradient
        g = QLinearGradient(0, 0, fw, 0)
        for i, c in enumerate(self._colors):
            g.setColorAt(i / max(len(self._colors)-1, 1), c)
        p.setBrush(g); p.drawRoundedRect(fr, rad, rad)

        # shimmer
        sw = fw * 0.4
        sx = self._shimmer_x * (fw + sw) - sw
        sg = QLinearGradient(sx, 0, sx+sw, 0)
        sg.setColorAt(0,   QColor(255,255,255,0))
        sg.setColorAt(0.5, QColor(255,255,255,70))
        sg.setColorAt(1,   QColor(255,255,255,0))
        p.save(); p.setClipRect(fr); p.setBrush(sg)
        p.drawRoundedRect(fr, rad, rad); p.restore()


# ╔═══════════════════════════════════════════╗
# ║  HOVER CARD  (translateY + shadow)        ║
# ╚═══════════════════════════════════════════╝

class HoverCard(QFrame):
    """Hover'da yukarı zıplayan kart."""
    clicked = Signal()

    def __init__(self, primary_tint=False, parent=None):
        super().__init__(parent)
        self._primary = primary_tint
        self.setCursor(QCursor(Qt.PointingHandCursor))
        self.setMouseTracking(True)
        self._hovered = False
        self._apply()

    def _apply(self):
        base = (f"background:qlineargradient(x1:0,y1:0,x2:1,y2:1,"
                f"stop:0 {C('primary')}14, stop:1 {C('accent')}0a);"
                if self._primary else f"background:{C('card')};")
        border_col = f"{C('primary')}4d" if self._primary else C("border")
        self.setStyleSheet(
            f"HoverCard {{ {base} border:1px solid {border_col}; border-radius:16px; }}"
        )
        _shadow(self, 24 if self._hovered else 6, 8 if self._hovered else 4,
                0.10 if self._hovered else 0.06)

    def enterEvent(self, e):
        self._hovered = True; self._apply(); super().enterEvent(e)
    def leaveEvent(self, e):
        self._hovered = False; self._apply(); super().leaveEvent(e)
    def mousePressEvent(self, e):
        self.clicked.emit(); super().mousePressEvent(e)
    def refresh(self):
        self._apply()


# ╔═══════════════════════════════════════════╗
# ║  NAV BUTTON  (70px sidebar)               ║
# ╚═══════════════════════════════════════════╝

class NavBtn(QPushButton):
    def __init__(self, icon, label, parent=None):
        super().__init__(parent)
        self.setCheckable(True)
        self.setFixedSize(56, 52)
        self._icon = icon; self._label = label
        self.setCursor(QCursor(Qt.PointingHandCursor))
        self.toggled.connect(lambda: self._paint())
        self._paint()

    def _paint(self):
        a = self.isChecked()
        if a:
            bg = (f"background:qlineargradient(x1:0,y1:0,x2:1,y2:1,"
                  f"stop:0 {C('primary')}26, stop:1 {C('accent')}26);")
            fg = C("primary")
        else:
            bg = "background:transparent;"
            fg = C("muted-fg")
        self.setStyleSheet(
            f"QPushButton {{ {bg} border:none; border-radius:10px; color:{fg}; }}"
            f"QPushButton:hover {{ background:{C('muted')}; }}"
        )
        self.setText(f"{self._icon}\n{self._label}")
        self.setFont(_f(10, a))


# ╔═══════════════════════════════════════════╗
# ║  STATUS PILL                               ║
# ╚═══════════════════════════════════════════╝

class Pill(QFrame):
    def __init__(self, icon_txt, label_txt, border_color=None, parent=None):
        super().__init__(parent)
        lo = QHBoxLayout(self); lo.setContentsMargins(10,4,10,4); lo.setSpacing(6)
        self._icon = _lbl(icon_txt, 14)
        self._text = _lbl(label_txt, 12, bold=True)
        lo.addWidget(self._icon); lo.addWidget(self._text)
        self._bc = border_color
        self._apply()

    def set_text(self, txt): self._text.setText(txt); self._text.setStyleSheet(f"color:{C('fg')};background:transparent;")
    def set_icon(self, txt): self._icon.setText(txt)
    def set_border(self, c): self._bc = c; self._apply()

    def _apply(self):
        bc = self._bc or C("border")
        self.setStyleSheet(
            f"Pill {{ background:{C('card')}; border:1px solid {bc}; "
            f"border-radius:20px; }}"
        )
        self._text.setStyleSheet(f"color:{C('fg')};background:transparent;")
        self._icon.setStyleSheet(f"background:transparent;")

    def refresh(self):
        self._apply()


# ╔═══════════════════════════════════════════╗
# ║  SECURE BOOT BANNER                       ║
# ╚═══════════════════════════════════════════╝

class SecureBootBanner(QFrame):
    def __init__(self, parent=None):
        super().__init__(parent)
        self.setVisible(False)
        lo = QVBoxLayout(self); lo.setContentsMargins(14,10,14,10); lo.setSpacing(4)
        self._header = QHBoxLayout(); self._header.setSpacing(8)
        self._icon = _lbl("", 16); self._title = _lbl("", 13, True)
        self._header.addWidget(self._icon); self._header.addWidget(self._title); self._header.addStretch()
        lo.addLayout(self._header)
        self._desc = _lbl("", 12, color=C("muted-fg"), wrap=True)
        lo.addWidget(self._desc)

    def set_status(self, on):
        if on:
            col = C("warning")
            self._icon.setText("⚠️"); self._title.setText("Secure Boot is Enabled")
            self._desc.setText(
                "Your system has Secure Boot enabled in UEFI/BIOS. "
                "Third-party kernel modules (including NVIDIA proprietary drivers) may fail to load "
                "unless they are signed with a Machine Owner Key (MOK). You may need to enroll a key "
                "after installation, or disable Secure Boot in BIOS to use unsigned drivers.")
        else:
            col = C("success")
            self._icon.setText("✅"); self._title.setText("Secure Boot is Disabled")
            self._desc.setText(
                "Third-party kernel modules (NVIDIA drivers) can load freely "
                "without MOK signing. No additional steps are required for driver installation.")
        self.setStyleSheet(
            f"SecureBootBanner {{ background:{col}14; border:1px solid {col}40; border-radius:10px; }}")
        self._title.setStyleSheet(f"color:{C('fg')};font-weight:bold;background:transparent;")
        self._desc.setStyleSheet(f"color:{C('muted-fg')};background:transparent;")
        self.setVisible(True)


# ╔═══════════════════════════════════════════╗
# ║  GRADIENT BUTTON                           ║
# ╚═══════════════════════════════════════════╝

def _gbtn(text, variant="primary"):
    b = QPushButton(text)
    b.setCursor(QCursor(Qt.PointingHandCursor))
    b.setFont(_f(14, True))
    b.setFixedHeight(40)
    styles = {
        "primary": (f"background:qlineargradient(x1:0,y1:0,x2:1,y2:1,"
                     f"stop:0 {C('primary')},stop:1 {C('accent')});color:white;"),
        "secondary": f"background:{C('muted')};color:{C('fg')};border:1px solid {C('border')};",
        "danger": (f"background:qlineargradient(x1:0,y1:0,x2:1,y2:1,"
                    f"stop:0 {C('error')},stop:1 #dc2626);color:white;"),
        "warning": (f"background:qlineargradient(x1:0,y1:0,x2:1,y2:1,"
                     f"stop:0 {C('warning')},stop:1 #d97706);color:#1a1d23;"),
        "success": f"background:{C('success')};color:white;",
        "outline": f"background:transparent;color:{C('primary')};border:1px solid {C('border')};",
    }
    base = styles.get(variant, styles["primary"])
    b.setStyleSheet(
        f"QPushButton {{ {base} border-radius:10px; padding:0 20px; font-size:14px; font-weight:600; }}"
        f"QPushButton:hover {{ padding:0 20px; }}"
    )
    return b


# ╔═══════════════════════════════════════════╗
# ║  INSTALL PAGE                              ║
# ╚═══════════════════════════════════════════╝

class InstallPage(QWidget):
    go_express = Signal()
    go_expert  = Signal()

    def __init__(self, get_sb, parent=None):
        super().__init__(parent)
        self._get_sb = get_sb
        self.setStyleSheet(f"background:{C('bg')};")

        lo = QVBoxLayout(self); lo.setContentsMargins(20,16,20,16); lo.setSpacing(12)

        # Status bar
        self._status = QHBoxLayout(); self._status.setSpacing(8)
        self._p_driver = Pill("🟢", f"nvidia ({LATEST})")
        self._p_gpu    = Pill("🎮", "NVIDIA GeForce RTX 4070 (Simülasyon)")
        self._p_sb     = Pill("🔍", "Scanning...")
        self._status.addWidget(self._p_driver)
        self._status.addWidget(self._p_gpu)
        self._status.addWidget(self._p_sb)
        self._status.addStretch()
        lo.addLayout(self._status)

        # Secure Boot Banner
        self.banner = SecureBootBanner()
        lo.addWidget(self.banner)

        # Title
        lo.addWidget(_lbl("Select Installation Type", 20, True))
        lo.addWidget(_lbl("Optimized options for your hardware.", 14, color=C("muted-fg")))
        lo.addSpacing(4)

        # Cards
        cards = QHBoxLayout(); cards.setSpacing(16)

        # Express card
        exp = HoverCard(primary_tint=True)
        elo = QVBoxLayout(exp); elo.setContentsMargins(20,20,20,20); elo.setSpacing(8)
        eh = QHBoxLayout(); eh.setSpacing(8)
        eh.addWidget(_lbl("🚀", 24))
        eh.addWidget(_lbl("Express Install", 15, True))
        badge = QLabel("Recommended")
        badge.setFont(_f(10, True))
        badge.setStyleSheet(
            f"background:{C('success')};color:white;border-radius:12px;padding:2px 8px;")
        eh.addWidget(badge); eh.addStretch()
        elo.addLayout(eh)
        elo.addWidget(_lbl(
            f"Automatically installs the latest stable NVIDIA driver (v{LATEST}).",
            13, color=C("muted-fg"), wrap=True))
        elo.addStretch()
        exp_btn = _gbtn("Express Install  →", "primary")
        exp_btn.clicked.connect(self.go_express)
        elo.addWidget(exp_btn)
        cards.addWidget(exp, 1)

        # Custom card
        cus = HoverCard()
        clo = QVBoxLayout(cus); clo.setContentsMargins(20,20,20,20); clo.setSpacing(8)
        ch = QHBoxLayout(); ch.setSpacing(8)
        ch.addWidget(_lbl("🔧", 24))
        ch.addWidget(_lbl("Custom Install (Expert)", 15, True))
        ch.addStretch()
        clo.addLayout(ch)
        clo.addWidget(_lbl(
            "Manually configure version, kernel type, and cleanup settings.",
            13, color=C("muted-fg"), wrap=True))
        clo.addStretch()
        cus_btn = _gbtn("Open Expert  →", "outline")
        cus_btn.clicked.connect(self.go_expert)
        clo.addWidget(cus_btn)
        cards.addWidget(cus, 1)

        lo.addLayout(cards)
        lo.addStretch()

    def showEvent(self, e):
        super().showEvent(e)
        sb = self._get_sb()
        self.banner.set_status(sb)
        if sb:
            self._p_sb.set_icon("⚠️"); self._p_sb.set_text("Secure Boot ON")
            self._p_sb.set_border(f"{C('warning')}66")
        else:
            self._p_sb.set_icon("🔓"); self._p_sb.set_text("Secure Boot OFF")
            self._p_sb.set_border(f"{C('success')}50")


# ╔═══════════════════════════════════════════╗
# ║  EXPRESS CONFIRM PAGE                      ║
# ╚═══════════════════════════════════════════╝

class ExpressConfirmPage(QWidget):
    confirmed = Signal(bool)
    cancelled = Signal()

    def __init__(self, get_sb, parent=None):
        super().__init__(parent)
        self._get_sb = get_sb
        lo = QVBoxLayout(self); lo.setContentsMargins(20,16,20,16); lo.setSpacing(12)

        # Header
        top = QHBoxLayout()
        back = _gbtn("← Back", "outline"); back.setFixedWidth(90)
        back.clicked.connect(self.cancelled)
        top.addWidget(back); top.addSpacing(8)
        top.addWidget(_lbl("Express Install — Confirm Options", 18, True)); top.addStretch()
        lo.addLayout(top)

        # Confirm card
        card = QFrame()
        card.setStyleSheet(
            f"QFrame#confirmCard {{ background:{C('card')}; border:1px solid {C('border')}; "
            f"border-radius:16px; }}")
        card.setObjectName("confirmCard")
        _shadow(card, 24, 4, 0.06)
        clo = QVBoxLayout(card); clo.setContentsMargins(20,20,20,20); clo.setSpacing(0)

        def _row(k, v, color=None):
            r = QHBoxLayout()
            r.addWidget(_lbl(k, 13, color=C("muted-fg"))); r.addStretch()
            vl = _lbl(v, 13, True, color=color)
            r.addWidget(vl)
            return r, vl

        r1, _ = _row("Driver Version:", f"v{LATEST} (Latest Stable)")
        r2, _ = _row("GPU:", "NVIDIA GeForce RTX 4070 (Simülasyon)")
        r3, self._sb_val = _row("Secure Boot:", "—")
        for r in (r1, r2, r3):
            w = QWidget(); w.setLayout(r)
            w.setStyleSheet(f"border-bottom:1px solid {C('border')};padding:8px 0;background:transparent;")
            clo.addWidget(w)

        # Divider
        clo.addSpacing(12)
        clo.addWidget(_lbl("Kernel Module Type", 14, True))
        clo.addSpacing(6)

        self._bg = QButtonGroup(self)
        for val, title, desc, checked in [
            ("proprietary", "Proprietary (Closed Source)",
             "Official NVIDIA binary driver. Best compatibility and performance.", True),
            ("open", "Open Kernel Module",
             "NVIDIA open source kernel module. Requires Turing+ GPU (RTX 20xx/30xx/40xx). Experimental.", False),
        ]:
            row = QFrame()
            row.setStyleSheet(
                f"QFrame {{ border:1px solid {C('border')}; border-radius:10px; "
                f"padding:10px; background:transparent; }}"
                f"QFrame:hover {{ background:{C('muted')}; }}")
            rlo = QHBoxLayout(row); rlo.setSpacing(10)
            rb = QRadioButton()
            rb.setChecked(checked); rb.setProperty("val", val)
            rb.setStyleSheet(f"QRadioButton {{ color:{C('fg')}; }}")
            self._bg.addButton(rb)
            rlo.addWidget(rb)
            tcol = QVBoxLayout(); tcol.setSpacing(2)
            tcol.addWidget(_lbl(title, 13, True))
            tcol.addWidget(_lbl(desc, 12, color=C("muted-fg")))
            rlo.addLayout(tcol, 1)
            clo.addWidget(row)
            clo.addSpacing(4)

        # EULA
        self._eula = QFrame()
        self._eula.setStyleSheet(
            f"QFrame {{ background:{C('warning')}14; border:1px solid {C('warning')}33; "
            f"border-radius:8px; padding:8px 12px; }}")
        eulo = QHBoxLayout(self._eula); eulo.setSpacing(8)
        eulo.addWidget(_lbl("⚠️", 14))
        eulo.addWidget(_lbl("By installing the NVIDIA Proprietary driver, you agree to the NVIDIA EULA.", 12))
        clo.addWidget(self._eula)

        lo.addWidget(card)

        # Buttons
        btns = QHBoxLayout()
        ok = _gbtn("Accept and Install", "primary"); ok.clicked.connect(self._confirm)
        cancel = _gbtn("Cancel", "secondary"); cancel.clicked.connect(self.cancelled)
        btns.addStretch(); btns.addWidget(ok); btns.addSpacing(8); btns.addWidget(cancel)
        lo.addLayout(btns)
        lo.addStretch()

        self._bg.buttonToggled.connect(self._upd_eula)

    def showEvent(self, e):
        super().showEvent(e)
        sb = self._get_sb()
        t = "ON — MOK signing may be required" if sb else "OFF — No restrictions"
        c = C("warning") if sb else C("success")
        self._sb_val.setText(t)
        self._sb_val.setStyleSheet(f"color:{c};font-weight:bold;background:transparent;")

    def _upd_eula(self):
        cur = next((b for b in self._bg.buttons() if b.isChecked()), None)
        self._eula.setVisible(cur and cur.property("val") == "proprietary")

    def _confirm(self):
        cur = next((b for b in self._bg.buttons() if b.isChecked()), None)
        self.confirmed.emit(cur and cur.property("val") == "open")


# ╔═══════════════════════════════════════════╗
# ║  EXPERT PAGE                               ║
# ╚═══════════════════════════════════════════╝

class ExpertPage(QWidget):
    start_install = Signal(str, bool, bool)
    back          = Signal()

    def __init__(self, parent=None):
        super().__init__(parent)
        lo = QVBoxLayout(self); lo.setContentsMargins(20,16,20,16); lo.setSpacing(12)

        top = QHBoxLayout()
        bb = _gbtn("← Back", "outline"); bb.setFixedWidth(90); bb.clicked.connect(self.back)
        top.addWidget(bb); top.addSpacing(8)
        top.addWidget(_lbl("Expert Driver Management", 18, True)); top.addStretch()
        lo.addLayout(top)

        # Version selector card
        vcard = QFrame()
        vcard.setStyleSheet(
            f"QFrame#vcard {{ background:{C('card')}; border:1px solid {C('border')}; border-radius:12px; }}")
        vcard.setObjectName("vcard")
        vclo = QVBoxLayout(vcard); vclo.setContentsMargins(16,16,16,16); vclo.setSpacing(6)
        vclo.addWidget(_lbl("Select Driver Version", 14, True))
        vclo.addSpacing(4)

        self._ver_btns = []
        self._ver_group = QButtonGroup(self)
        for i, d in enumerate(VERSIONS):
            row = QFrame()
            row.setObjectName(f"vrow_{i}")
            rlo = QHBoxLayout(row); rlo.setContentsMargins(12,8,12,8); rlo.setSpacing(10)
            rb = QRadioButton()
            rb.setChecked(i == 0)
            rb.setStyleSheet(f"color:{C('fg')};")
            self._ver_group.addButton(rb, i)
            rlo.addWidget(rb)
            rlo.addWidget(_lbl(d["ver"], 14, True))
            src = QLabel(d["src"])
            src.setFont(_f(11))
            src.setStyleSheet(
                f"background:{C('muted')};color:{C('muted-fg')};border-radius:8px;padding:2px 6px;")
            rlo.addWidget(src)
            if d["latest"]:
                lt = QLabel("Latest")
                lt.setFont(_f(11, True))
                lt.setStyleSheet(f"background:{C('success')};color:white;border-radius:8px;padding:2px 6px;")
                rlo.addWidget(lt)
            rlo.addStretch()
            rlo.addWidget(_lbl(d["note"], 12, color=C("muted-fg")))
            row.setStyleSheet(
                f"QFrame#vrow_{i} {{ border:1px solid transparent; border-radius:8px; }}"
                f"QFrame#vrow_{i}:hover {{ background:{C('muted')}; }}")
            vclo.addWidget(row)
            self._ver_btns.append((rb, row))
        lo.addWidget(vcard)

        # Options
        opts = QHBoxLayout(); opts.setSpacing(20)
        self._open = QCheckBox("Use Open Kernel Module")
        self._deep = QCheckBox("Deep Clean (Remove previous configs)")
        for cb in (self._open, self._deep):
            cb.setFont(_f(13)); cb.setStyleSheet(f"color:{C('fg')};")
            opts.addWidget(cb)
        opts.addStretch()
        lo.addLayout(opts)

        # Buttons
        btns = QHBoxLayout()
        ins = _gbtn("Install Selected", "primary"); ins.clicked.connect(self._do_install)
        rem = _gbtn("Remove All Drivers", "danger")
        btns.addStretch(); btns.addWidget(ins); btns.addSpacing(10); btns.addWidget(rem)
        lo.addLayout(btns)
        lo.addStretch()

    def _do_install(self):
        idx = self._ver_group.checkedId()
        if idx < 0: idx = 0
        v = VERSIONS[idx]["ver"]
        self.start_install.emit(v, self._open.isChecked(), self._deep.isChecked())


# ╔═══════════════════════════════════════════╗
# ║  PROGRESS PAGE                             ║
# ╚═══════════════════════════════════════════╝

class StepRow(QFrame):
    """Progress step satırı — pending / active / complete."""
    def __init__(self, icon, text, parent=None):
        super().__init__(parent)
        self._state = "pending"
        lo = QHBoxLayout(self); lo.setContentsMargins(14,8,14,8); lo.setSpacing(10)
        self._ico = _lbl("⏳", 18); self._ico.setFixedWidth(26)
        self._txt = _lbl(text, 13)
        lo.addWidget(self._ico); lo.addWidget(self._txt, 1)
        self._apply()

    def set_state(self, s):
        self._state = s
        if s == "active":
            self._ico.setText("⏳")
        elif s == "complete":
            self._ico.setText("✅")
        elif s == "error":
            self._ico.setText("❌")
        self._apply()

    def _apply(self):
        bc = C("border")
        bg = C("card")
        op = "1.0"
        if self._state == "active":
            bc = C("primary"); bg = f"{C('primary')}0d"
        elif self._state == "complete":
            bc = C("success")
        elif self._state == "pending":
            op = "0.5"
        self.setStyleSheet(
            f"StepRow {{ background:{bg}; border:1px solid {bc}; border-radius:8px; }}")
        self._ico.setStyleSheet("background:transparent;")
        self._txt.setStyleSheet(f"color:{C('fg')};background:transparent;")
        if self._state == "pending":
            self._ico.setStyleSheet("background:transparent; color:rgba(0,0,0,0.3);")
            self._txt.setStyleSheet(f"color:{C('muted-fg')};background:transparent;")


class ProgressPage(QWidget):
    done = Signal()

    def __init__(self, parent=None):
        super().__init__(parent)
        lo = QVBoxLayout(self); lo.setContentsMargins(20,16,20,16); lo.setSpacing(12)

        self._title = _lbl("Installation Progress", 20, True)
        lo.addWidget(self._title)

        # Progress bar (large — 20px like HTML)
        pbar = QHBoxLayout(); pbar.setSpacing(12)
        self._bar = GradientBar([C("primary"), C("accent"), C("success")], h=20)
        self._pct = _lbl("0%", 16, True)
        self._pct.setFixedWidth(50); self._pct.setAlignment(Qt.AlignRight|Qt.AlignVCenter)
        pbar.addWidget(self._bar, 1); pbar.addWidget(self._pct)
        lo.addLayout(pbar)

        # Steps
        self._steps_w = QWidget()
        self._steps_lo = QVBoxLayout(self._steps_w); self._steps_lo.setSpacing(8)
        self._steps_lo.setContentsMargins(0,0,0,0)
        scroll = QScrollArea()
        scroll.setWidget(self._steps_w); scroll.setWidgetResizable(True)
        scroll.setFixedHeight(200)
        scroll.setStyleSheet(
            f"QScrollArea {{ border:none; background:transparent; }}"
            f"QScrollBar:vertical {{ width:6px; background:transparent; }}"
            f"QScrollBar::handle:vertical {{ background:{C('border')}; border-radius:3px; }}")
        lo.addWidget(scroll)

        # Log
        self._log = QTextEdit()
        self._log.setReadOnly(True)
        self._log.setFixedHeight(150)
        self._log.setStyleSheet(
            "QTextEdit { background:#0d1117; color:#c9d1d9; "
            "font-family:'SF Mono','JetBrains Mono','Menlo','Courier New',monospace; "
            "font-size:12px; border-radius:10px; padding:12px; "
            "border:1px solid #30363d; line-height:1.6; }")
        lo.addWidget(self._log)

        # Buttons
        self._btns = QWidget()
        blo = QHBoxLayout(self._btns); blo.setContentsMargins(0,0,0,0)
        blo.addStretch()
        db = _gbtn("Done", "primary"); db.clicked.connect(self.done)
        rb = _gbtn("Reboot Now", "warning")
        blo.addWidget(db); blo.addSpacing(10); blo.addWidget(rb)
        self._btns.setVisible(False)
        lo.addWidget(self._btns)

        self._timer = QTimer(self); self._timer.timeout.connect(self._tick)
        self._steps = []; self._step_widgets = []; self._cur = 0; self._phase = "start"

    def start(self, version, open_kernel, deep_clean):
        ktype = "Open Kernel" if open_kernel else "Proprietary"
        self._title.setText(f"Installing NVIDIA {ktype} Driver")
        self._bar.setValue(0); self._pct.setText("0%")
        self._log.clear(); self._btns.setVisible(False)

        for i in reversed(range(self._steps_lo.count())):
            w = self._steps_lo.itemAt(i).widget()
            if w: w.deleteLater()
        self._step_widgets.clear()

        steps = [("📋","Backing up Xorg configuration")]
        if deep_clean:
            steps += [("🧹","Deep cleaning previous driver configs"),("🗑️","Removing old NVIDIA packages")]
        steps += [("🚫","Blacklisting nouveau driver"),("⚙️","Installing kernel headers (kernel-devel)"),
                  ("📦","Enabling RPM Fusion repository")]
        steps.append(("🔓","Installing NVIDIA Open Kernel Module (nvidia-open)") if open_kernel
                     else ("🎮","Installing NVIDIA Proprietary driver (akmod-nvidia)"))
        steps += [("🔄","Regenerating initramfs (dracut --force)"),("✅","Verifying installation")]
        self._steps = steps

        for ico, txt in steps:
            sw = StepRow(ico, txt)
            self._steps_lo.addWidget(sw)
            self._step_widgets.append(sw)

        op = "Open Kernel Module" if open_kernel else "Proprietary (Closed Source)"
        self._alog(f"--- OPERATION STARTING: NVIDIA {op} ---")
        self._alog(f"Version: {version}")
        self._alog(f"Package Manager: dnf")
        self._alog(f"Kernel: 6.8.11-300.fc40.x86_64")
        self._alog(f"GPU: NVIDIA GeForce RTX 4070 (Simülasyon)")
        self._alog(f"Open Kernel: {'YES' if open_kernel else 'NO'}")
        self._alog(f"Deep Clean: {'YES' if deep_clean else 'NO'}")
        self._alog("")
        self._alog("Waiting for authorization (Root/Admin)...")
        self._alog("Please enter your password in the dialog.")
        self._alog("")

        self._cur = 0; self._ok = open_kernel; self._dc = deep_clean
        self._total = len(steps); self._phase = "start"
        self._timer.start(1200)

    def _alog(self, t):
        ts = datetime.now().strftime("%H:%M:%S")
        self._log.append(f"[{ts}] {t}")

    def _tick(self):
        if self._cur >= self._total:
            self._timer.stop()
            self._alog("")
            if self._dc:
                self._alog("[Deep Clean] Removed: /etc/X11/xorg.conf.d/nvidia*")
                self._alog("[Deep Clean] Removed: /etc/modprobe.d/nvidia*")
                self._alog("[Deep Clean] Purged old DKMS modules")
            if self._ok:
                self._alog("[Open Kernel] nvidia-open module loaded successfully")
                self._alog("[Open Kernel] Module verification: PASS")
            else:
                self._alog("[Proprietary] akmod-nvidia built successfully")
                self._alog("[Proprietary] Module verification: PASS")
            self._alog("")
            k = "Open Kernel" if self._ok else "Proprietary"
            self._alog(f"SUCCESS: NVIDIA {k} Installation completed.")
            self._alog("Reboot the system for changes to take effect.")
            self._bar.setValue(100); self._pct.setText("100%")
            self._btns.setVisible(True)
            return

        sw = self._step_widgets[self._cur]
        _, txt = self._steps[self._cur]

        if self._phase == "start":
            sw.set_state("active")
            self._alog(f"→ {txt}...")
            p = int((self._cur + 0.5) / self._total * 100)
            self._bar.setValue(p); self._pct.setText(f"{p}%")
            self._phase = "done"
            self._timer.start(600 + random.randint(0, 1000))
        else:
            sw.set_state("complete")
            self._alog(f"  ✓ {txt} — done")
            p = int((self._cur + 1) / self._total * 100)
            self._bar.setValue(p); self._pct.setText(f"{p}%")
            self._cur += 1; self._phase = "start"
            self._timer.start(300)


# ╔═══════════════════════════════════════════╗
# ║  MONITOR PAGE                              ║
# ╚═══════════════════════════════════════════╝

class MonitorPage(QWidget):
    def __init__(self, parent=None):
        super().__init__(parent)
        lo = QVBoxLayout(self); lo.setContentsMargins(20,16,20,16); lo.setSpacing(12)
        lo.addWidget(_lbl("Performance Monitor", 20, True))

        # Info grid (3 col)
        grid = QGridLayout(); grid.setSpacing(10)
        infos = [
            ("💻","OS","Fedora 40 Workstation"),
            ("🔧","Kernel","6.8.11-300.fc40"),
            ("⚙️","CPU","AMD Ryzen 7 5800X"),
            ("🧠","RAM","32 GB"),
            ("🎮","GPU","NVIDIA RTX 4070 (Simülasyon)"),
            ("📊","Display","Wayland"),
        ]
        for i, (ico, k, v) in enumerate(infos):
            c = QFrame(); c.setObjectName(f"icard_{i}")
            c.setStyleSheet(
                f"QFrame#icard_{i} {{ background:{C('card')}; border:1px solid {C('border')}; "
                f"border-radius:12px; }}"
                f"QFrame#icard_{i}:hover {{ border-color:{C('primary')}; }}")
            cl = QHBoxLayout(c); cl.setContentsMargins(12,10,12,10); cl.setSpacing(10)
            cl.addWidget(_lbl(ico, 22))
            vc = QVBoxLayout(); vc.setSpacing(1)
            vc.addWidget(_lbl(k, 11, color=C("muted-fg")))
            vc.addWidget(_lbl(v, 13, True))
            cl.addLayout(vc, 1)
            grid.addWidget(c, i//3, i%3)
        lo.addLayout(grid)

        # Monitor grid (2 col)
        mg = QHBoxLayout(); mg.setSpacing(16)

        self._gpu_bars = {}
        gpu_card = QFrame(); gpu_card.setObjectName("gpuCard")
        gpu_card.setStyleSheet(
            f"QFrame#gpuCard {{ background:{C('card')}; border:1px solid {C('border')}; border-radius:12px; }}")
        gcl = QVBoxLayout(gpu_card); gcl.setContentsMargins(16,14,16,14); gcl.setSpacing(10)
        gcl.addWidget(_lbl("🎮  Live GPU Status", 14, True))
        bar_defs_gpu = [
            ("gpuTemp","🌡 Temp",[C("success"), C("warning")]),
            ("gpuLoad","⚡ Load",[C("primary"), C("accent")]),
            ("vram",   "💾 VRAM",[C("accent"), C("error")]),
        ]
        for key, label, cols in bar_defs_gpu:
            r = QHBoxLayout(); r.setSpacing(10)
            ll = _lbl(label, 12, color=C("muted-fg")); ll.setFixedWidth(80)
            bar = GradientBar(cols, 10)
            val = _lbl("—", 12, True); val.setFixedWidth(110); val.setAlignment(Qt.AlignRight)
            r.addWidget(ll); r.addWidget(bar, 1); r.addWidget(val)
            gcl.addLayout(r)
            self._gpu_bars[key] = (bar, val)
        mg.addWidget(gpu_card, 1)

        self._sys_bars = {}
        sys_card = QFrame(); sys_card.setObjectName("sysCard")
        sys_card.setStyleSheet(
            f"QFrame#sysCard {{ background:{C('card')}; border:1px solid {C('border')}; border-radius:12px; }}")
        scl = QVBoxLayout(sys_card); scl.setContentsMargins(16,14,16,14); scl.setSpacing(10)
        scl.addWidget(_lbl("🖥  Live System Usage", 14, True))
        bar_defs_sys = [
            ("cpuLoad","⚡ CPU",    [C("success"), C("primary")]),
            ("cpuTemp","🌡 CPU Temp",[C("success"), C("error")]),
            ("ram",    "🧠 RAM",    [C("primary"), C("warning")]),
        ]
        for key, label, cols in bar_defs_sys:
            r = QHBoxLayout(); r.setSpacing(10)
            ll = _lbl(label, 12, color=C("muted-fg")); ll.setFixedWidth(90)
            bar = GradientBar(cols, 10)
            val = _lbl("—", 12, True); val.setFixedWidth(110); val.setAlignment(Qt.AlignRight)
            r.addWidget(ll); r.addWidget(bar, 1); r.addWidget(val)
            scl.addLayout(r)
            self._sys_bars[key] = (bar, val)
        mg.addWidget(sys_card, 1)
        lo.addLayout(mg)

        # Footer
        foot = QFrame(); foot.setObjectName("mfoot")
        foot.setStyleSheet(
            f"QFrame#mfoot {{ background:{C('card')}; border:1px solid {C('border')}; border-radius:8px; }}")
        flo = QHBoxLayout(foot); flo.setContentsMargins(14,6,14,6); flo.setSpacing(8)
        self._dot = _lbl("●", 10, color=C("success"))
        self._ftxt = _lbl("Waiting for data...", 11, color=C("muted-fg"))
        flo.addWidget(self._dot); flo.addWidget(self._ftxt, 1)
        lo.addWidget(foot)
        lo.addStretch()

        # Sensors
        self._s = {
            "gpuTemp":{"c":40.0,"t":40},"gpuLoad":{"c":10.0,"t":10},"vram":{"c":1400.0,"t":1400},
            "cpuLoad":{"c":15.0,"t":15},"cpuTemp":{"c":45.0,"t":45},"ram":{"c":8200.0,"t":8200},
        }
        self._tt = QTimer(self); self._tt.timeout.connect(self._new_targets)
        self._st = QTimer(self); self._st.timeout.connect(self._smooth)
        # Dot pulse
        self._pulse = QTimer(self); self._pulse.timeout.connect(self._blink)
        self._dot_on = True

    def start(self):
        self._new_targets(); self._tt.start(1000); self._st.start(33); self._pulse.start(1000)
    def stop(self):
        self._tt.stop(); self._st.stop(); self._pulse.stop()

    def _blink(self):
        self._dot_on = not self._dot_on
        self._dot.setStyleSheet(f"color:{C('success') if self._dot_on else 'transparent'};background:transparent;")

    def _new_targets(self):
        self._s["gpuTemp"]["t"] = random.randint(35,70)
        self._s["gpuLoad"]["t"] = random.randint(0,70)
        self._s["vram"]["t"]    = random.randint(800,5000)
        self._s["cpuLoad"]["t"] = random.randint(5,55)
        self._s["cpuTemp"]["t"] = random.randint(38,68)
        self._s["ram"]["t"]     = random.randint(5000,17000)
        now = datetime.now().strftime("%H:%M:%S")
        self._ftxt.setText(f"Live data • Updated at {now} • Refresh: 1000ms • Using QTimer + EMA smooth interpolation")

    def _smooth(self):
        a = 0.08
        for s in self._s.values():
            s["c"] += (s["t"] - s["c"]) * a

        def u(bars, k, v, mx, txt):
            bar, lbl = bars[k]
            bar.setValue(int(v/mx*100))
            lbl.setText(txt)
            lbl.setStyleSheet(f"color:{C('fg')};background:transparent;")

        s = self._s
        u(self._gpu_bars,"gpuTemp",s["gpuTemp"]["c"],100,f"{s['gpuTemp']['c']:.0f}°C")
        u(self._gpu_bars,"gpuLoad",s["gpuLoad"]["c"],100,f"{s['gpuLoad']['c']:.0f}%")
        u(self._gpu_bars,"vram",   s["vram"]["c"],   VRAM_T,f"{s['vram']['c']:.0f} / {VRAM_T} MB")
        u(self._sys_bars,"cpuLoad",s["cpuLoad"]["c"],100,f"{s['cpuLoad']['c']:.0f}%")
        u(self._sys_bars,"cpuTemp",s["cpuTemp"]["c"],100,f"{s['cpuTemp']['c']:.0f}°C")
        u(self._sys_bars,"ram",    s["ram"]["c"],    RAM_T, f"{s['ram']['c']:.0f} / {RAM_T} MB")


# ╔═══════════════════════════════════════════╗
# ║  ABOUT DIALOG                              ║
# ╚═══════════════════════════════════════════╝

class AboutDialog(QDialog):
    def __init__(self, parent=None):
        super().__init__(parent)
        self.setWindowTitle("About ro-Control")
        self.setMinimumWidth(420); self.setMaximumWidth(440)
        self.setModal(True)
        self.setStyleSheet(
            f"QDialog {{ background:{C('card')}; border:1px solid {C('border')}; border-radius:16px; }}")

        lo = QVBoxLayout(self); lo.setSpacing(8); lo.setContentsMargins(28,24,28,24)
        lo.setAlignment(Qt.AlignHCenter)

        logo = _lbl("🛡️", 44); logo.setAlignment(Qt.AlignCenter); lo.addWidget(logo)
        t = _lbl("ro-Control", 22, True); t.setAlignment(Qt.AlignCenter); lo.addWidget(t)
        v = _lbl(f"v{APP_VERSION} — Rust Edition", 14, True, C("primary"))
        v.setAlignment(Qt.AlignCenter); lo.addWidget(v)
        d = _lbl("Smart GPU driver manager for Linux.\nBuilt with Rust + Qt6/QML (CXX-Qt)", 13, color=C("muted-fg"))
        d.setAlignment(Qt.AlignCenter); lo.addWidget(d)
        o = _lbl("ro-ASD", 13, True, C("accent"))
        o.setAlignment(Qt.AlignCenter); lo.addWidget(o)
        lo.addSpacing(8)

        # Changelog tabs + content
        self._tabs = {}; self._contents = {}
        tr = QHBoxLayout(); tr.setSpacing(8)
        for vid, txt in [("1.1.0","v1.1.0"),("1.0.0","v1.0.0")]:
            b = QPushButton(txt); b.setCheckable(True); b.setCursor(QCursor(Qt.PointingHandCursor))
            b.setProperty("ver", vid); b.clicked.connect(self._sw)
            tr.addWidget(b); self._tabs[vid] = b
        tr.addStretch(); lo.addLayout(tr)

        c110 = QLabel(
            "<b>v1.1.0 — Rust Edition UI Redesign</b><br>"
            "• Premium Rust Edition visual identity<br>"
            "• Modern color palette (blue / purple / emerald)<br>"
            "• Express Install confirmation with kernel type selection<br>"
            "• Secure Boot status banner with explanations<br>"
            "• Security: root-task script hardened against command injection<br>"
            "• 49 unit tests (+113% increase)<br>"
            "• Shared version parsing module<br>"
            "• All log messages standardized to English")
        c110.setWordWrap(True); c110.setFont(_f(12))
        c110.setStyleSheet(
            f"background:{C('muted')};border-radius:8px;padding:12px;color:{C('fg')};")
        self._contents["1.1.0"] = c110; lo.addWidget(c110)

        c100 = QLabel(
            "<b>v1.0.0 — Initial Rust Release</b><br>"
            "• NVIDIA proprietary driver install via RPM Fusion<br>"
            "• NVIDIA Open Kernel module install<br>"
            "• Live GPU/CPU/RAM performance dashboard<br>"
            "• Feral GameMode integration<br>"
            "• Flatpak/Steam permission repair<br>"
            "• NVIDIA Wayland fix (nvidia-drm.modeset=1)<br>"
            "• Auto-update via GitHub Releases<br>"
            "• PolicyKit integration for secure privilege escalation")
        c100.setWordWrap(True); c100.setFont(_f(12))
        c100.setStyleSheet(
            f"background:{C('muted')};border-radius:8px;padding:12px;color:{C('fg')};")
        c100.setVisible(False)
        self._contents["1.0.0"] = c100; lo.addWidget(c100)

        cb = _gbtn("Close", "primary"); cb.clicked.connect(self.accept)
        lo.addSpacing(8); lo.addWidget(cb, alignment=Qt.AlignCenter)
        self._set_tab("1.1.0")

    def _sw(self):
        self._set_tab(self.sender().property("ver"))

    def _set_tab(self, vid):
        for k, b in self._tabs.items():
            a = k == vid; b.setChecked(a)
            b.setStyleSheet(
                f"QPushButton {{ background:{C('primary') if a else C('muted')}; "
                f"color:{'white' if a else C('muted-fg')}; "
                f"border:{'none' if a else '1px solid ' + C('border')}; "
                f"border-radius:8px; padding:6px 12px; font-size:12px; font-weight:600; }}")
        for k, w in self._contents.items():
            w.setVisible(k == vid)


# ╔═══════════════════════════════════════════╗
# ║  ANA PENCERE                               ║
# ╚═══════════════════════════════════════════╝

class MainWindow(QMainWindow):
    def __init__(self):
        super().__init__()
        self.setWindowTitle("ro-Control — NVIDIA Driver Manager (Rust Edition)")
        self.resize(960, 680)
        self.setMinimumSize(860, 600)

        self._secure_boot = random.random() > 0.6
        self._dark = False
        self._build()

    def _build(self):
        global _DARK
        _DARK = self._dark

        central = QWidget()
        self.setCentralWidget(central)
        central.setStyleSheet(f"background:{C('bg')};")
        root = QVBoxLayout(central); root.setContentsMargins(0,0,0,0); root.setSpacing(0)

        # ═══ HEADER ═══
        header = QFrame(); header.setObjectName("header")
        header.setFixedHeight(52)
        header.setStyleSheet(
            f"QFrame#header {{ background:{C('card-glass')}; border-bottom:1px solid {C('border')}; }}")
        hlo = QHBoxLayout(header); hlo.setContentsMargins(20,0,20,0); hlo.setSpacing(10)

        # Logo gradient box
        logo_f = QFrame(); logo_f.setFixedSize(28,28)
        logo_f.setStyleSheet(
            f"QFrame {{ background:qlineargradient(x1:0,y1:0,x2:1,y2:1,"
            f"stop:0 {C('primary')},stop:1 {C('accent')}); border-radius:6px; }}")
        logo_l = QLabel("🛡", logo_f); logo_l.setAlignment(Qt.AlignCenter)
        logo_l.setFixedSize(28,28); logo_l.setStyleSheet("background:transparent;font-size:14px;")
        hlo.addWidget(logo_f)

        hlo.addWidget(_lbl("ro-Control", 18, True))
        badge = QLabel("Rust Edition"); badge.setFont(_f(11, True))
        badge.setStyleSheet(
            f"background:qlineargradient(x1:0,y1:0,x2:1,y2:0,"
            f"stop:0 {C('primary')},stop:1 {C('accent')});"
            f"color:white;border-radius:20px;padding:3px 8px;")
        hlo.addWidget(badge)
        hlo.addStretch()

        theme_btn = QPushButton("☀️" if self._dark else "🌙")
        theme_btn.setFixedSize(36,36); theme_btn.setCursor(QCursor(Qt.PointingHandCursor))
        theme_btn.setStyleSheet(
            f"QPushButton {{ background:none; border:1px solid {C('border')}; "
            f"border-radius:8px; font-size:18px; }}"
            f"QPushButton:hover {{ background:{C('muted')}; }}")
        theme_btn.clicked.connect(self._toggle_theme)
        hlo.addWidget(theme_btn)
        root.addWidget(header)

        # ═══ BODY ═══
        body = QHBoxLayout(); body.setSpacing(0); body.setContentsMargins(0,0,0,0)

        # ── Sidebar (70px like HTML) ──
        sidebar = QFrame(); sidebar.setObjectName("sidebar")
        sidebar.setFixedWidth(70)
        sidebar.setStyleSheet(
            f"QFrame#sidebar {{ background:{C('card')}; border-right:1px solid {C('border')}; }}")
        slo = QVBoxLayout(sidebar); slo.setContentsMargins(7,12,7,12); slo.setSpacing(4)
        slo.setAlignment(Qt.AlignTop | Qt.AlignHCenter)

        self._nav = QButtonGroup(self); self._nav.setExclusive(True)
        self._nav_btns = {}
        for pid, ico, txt in [("install","📦","Install"),("expert","⚙️","Expert"),("monitor","📊","Monitor")]:
            b = NavBtn(ico, txt)
            self._nav.addButton(b)
            self._nav_btns[pid] = b
            b.clicked.connect(lambda _, p=pid: self._go(p))
            slo.addWidget(b, alignment=Qt.AlignHCenter)

        slo.addStretch()

        # Version label at bottom
        ver_w = QWidget()
        ver_w.setCursor(QCursor(Qt.PointingHandCursor))
        vvlo = QVBoxLayout(ver_w); vvlo.setAlignment(Qt.AlignCenter); vvlo.setSpacing(4)
        vvlo.setContentsMargins(0,0,0,0)
        vlogo = QFrame(); vlogo.setFixedSize(22,22)
        vlogo.setStyleSheet(
            f"QFrame {{ background:qlineargradient(x1:0,y1:0,x2:1,y2:1,"
            f"stop:0 {C('primary')},stop:1 {C('accent')}); border-radius:4px; }}")
        vvlo.addWidget(vlogo, alignment=Qt.AlignCenter)
        vvlo.addWidget(_lbl(f"v{APP_VERSION}", 10, color=C("muted-fg")), alignment=Qt.AlignCenter)
        ver_w.mousePressEvent = lambda _: self._about()
        slo.addWidget(ver_w)
        body.addWidget(sidebar)

        # ── Content stack ──
        content = QFrame(); content.setObjectName("content")
        content.setStyleSheet(f"QFrame#content {{ background:{C('bg')}; }}")
        clo = QVBoxLayout(content); clo.setContentsMargins(0,0,0,0)

        self._stack = QStackedWidget()
        self._pg_install  = InstallPage(lambda: self._secure_boot)
        self._pg_express  = ExpressConfirmPage(lambda: self._secure_boot)
        self._pg_expert   = ExpertPage()
        self._pg_progress = ProgressPage()
        self._pg_monitor  = MonitorPage()

        for pg in (self._pg_install, self._pg_express, self._pg_expert,
                   self._pg_progress, self._pg_monitor):
            self._stack.addWidget(pg)

        # Signals
        self._pg_install.go_express.connect(lambda: self._go("express"))
        self._pg_install.go_expert.connect(lambda: self._go("expert"))
        self._pg_express.confirmed.connect(self._express_go)
        self._pg_express.cancelled.connect(lambda: self._go("install"))
        self._pg_expert.start_install.connect(self._expert_go)
        self._pg_expert.back.connect(lambda: self._go("install"))
        self._pg_progress.done.connect(lambda: self._go("install"))

        clo.addWidget(self._stack)
        body.addWidget(content, 1)
        root.addLayout(body, 1)

        self._go("install")
        self._nav_btns["install"].setChecked(True)

    def _go(self, pid):
        if pid == "monitor": self._pg_monitor.start()
        else: self._pg_monitor.stop()

        m = {"install":self._pg_install,"express":self._pg_express,"expert":self._pg_expert,
             "progress":self._pg_progress,"monitor":self._pg_monitor}
        if pid in m: self._stack.setCurrentWidget(m[pid])

        nm = {"install":"install","express":"install","progress":"install",
              "expert":"expert","monitor":"monitor"}
        a = nm.get(pid, "install")
        for k,b in self._nav_btns.items(): b.setChecked(k == a)

    def _express_go(self, ok):
        self._go("progress"); self._pg_progress.start(LATEST, ok, False)

    def _expert_go(self, v, ok, dc):
        self._go("progress"); self._pg_progress.start(v, ok, dc)

    def _toggle_theme(self):
        self._dark = not self._dark
        old = self.centralWidget()
        if old: old.deleteLater()
        self._build()

    def _about(self):
        AboutDialog(self).exec()


# ╔═══════════════════════════════════════════╗
# ║  GİRİŞ NOKTASI                            ║
# ╚═══════════════════════════════════════════╝

def main():
    os.environ["QT_MAC_WANTS_LAYER"] = "1"
    app = QApplication(sys.argv)
    app.setApplicationName("ro-Control")
    app.setApplicationVersion(APP_VERSION)
    app.setOrganizationName("ro-ASD")
    app.setStyle("Fusion")

    # Inter font yoksa sistem fontuna düş
    if sys.platform == "darwin":
        app.setFont(QFont(".AppleSystemUIFont", 13))
    else:
        app.setFont(QFont("Segoe UI", 13))

    win = MainWindow()
    win.show()
    sys.exit(app.exec())


if __name__ == "__main__":
    main()
