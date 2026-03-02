"""
ro-Control — macOS Native Qt6 Simulation
Tamamen PySide6 widget'larıyla yazılmıştır. HTML/WebEngine kullanılmaz.
Çalıştırma: python3 ro_control_qt.py
"""
import sys
import random
import math
from datetime import datetime
from PySide6.QtWidgets import (
    QApplication, QMainWindow, QWidget, QVBoxLayout, QHBoxLayout,
    QLabel, QPushButton, QStackedWidget, QFrame, QScrollArea,
    QRadioButton, QButtonGroup, QCheckBox, QProgressBar, QTextEdit,
    QDialog, QDialogButtonBox, QGroupBox, QGridLayout, QSizePolicy,
    QListWidget, QListWidgetItem, QSplitter,
)
from PySide6.QtCore import (
    Qt, QTimer, QPropertyAnimation, QEasingCurve, QSize, Signal, QThread,
    QRect, QPoint,
)
from PySide6.QtGui import (
    QFont, QColor, QPalette, QLinearGradient, QGradient, QPainter,
    QBrush, QPen, QPixmap, QIcon, QPainterPath, QFontDatabase,
)

# ── Renk Paleti ───────────────────────────────────────────────────────────────
PRIMARY   = "#3B82F6"   # mavi
ACCENT    = "#8B5CF6"   # mor
SUCCESS   = "#10B981"   # yeşil
WARNING   = "#F59E0B"   # sarı
DANGER    = "#EF4444"   # kırmızı
BG        = "#F8FAFC"   # açık arka plan
SIDEBAR   = "#F1F5F9"   # kenar çubuğu
CARD      = "#FFFFFF"   # kart
BORDER    = "#E2E8F0"   # sınır
TEXT      = "#1E293B"   # ana metin
SUBTEXT   = "#64748B"   # alt metin

DRIVER_VERSIONS = [
    {"ver": "560.35.03", "src": "RPM Fusion", "note": "Latest stable", "latest": True},
    {"ver": "555.58.02", "src": "RPM Fusion", "note": "Production branch", "latest": False},
    {"ver": "550.120",   "src": "RPM Fusion", "note": "LTS / Enterprise",  "latest": False},
    {"ver": "545.29.06", "src": "RPM Fusion", "note": "Legacy",            "latest": False},
    {"ver": "535.183.01","src": "RPM Fusion", "note": "Legacy LTS",        "latest": False},
]
LATEST_VER = DRIVER_VERSIONS[0]["ver"]

# ── Yardımcı Widget'lar ───────────────────────────────────────────────────────

def label(text, bold=False, size=13, color=TEXT):
    l = QLabel(text)
    f = QFont("SF Pro Display" if sys.platform == "darwin" else "Segoe UI", size)
    f.setBold(bold)
    l.setFont(f)
    l.setStyleSheet(f"color: {color};")
    return l

def make_card(radius=12):
    f = QFrame()
    f.setStyleSheet(
        f"QFrame {{ background:{CARD}; border:1px solid {BORDER}; "
        f"border-radius:{radius}px; }}"
    )
    return f

class GradientBar(QWidget):
    """Renkli gradient progress bar."""
    def __init__(self, color_from="#3B82F6", color_to="#8B5CF6", parent=None):
        super().__init__(parent)
        self.setFixedHeight(8)
        self._value = 0
        self.c_from = QColor(color_from)
        self.c_to   = QColor(color_to)

    def setValue(self, v):
        self._value = max(0, min(100, v))
        self.update()

    def paintEvent(self, event):
        p = QPainter(self)
        p.setRenderHint(QPainter.Antialiasing)
        r = self.rect()
        # track
        p.setBrush(QColor(BORDER))
        p.setPen(Qt.NoPen)
        p.drawRoundedRect(r, 4, 4)
        # fill
        if self._value > 0:
            fill_w = int(r.width() * self._value / 100)
            g = QLinearGradient(0, 0, fill_w, 0)
            g.setColorAt(0, self.c_from)
            g.setColorAt(1, self.c_to)
            p.setBrush(g)
            fill_rect = QRect(r.x(), r.y(), fill_w, r.height())
            p.drawRoundedRect(fill_rect, 4, 4)

class NavButton(QPushButton):
    def __init__(self, icon_txt, label_txt):
        super().__init__()
        self.setCheckable(True)
        self.setFixedHeight(64)
        self.setFixedWidth(72)
        self._icon_txt  = icon_txt
        self._label_txt = label_txt
        self._update()
        self.toggled.connect(self._update)

    def _update(self):
        active = self.isChecked()
        bg = f"background:{PRIMARY}; border-radius:10px;" if active else "background:transparent;"
        txt_color = "white" if active else SUBTEXT
        self.setStyleSheet(
            f"QPushButton {{ {bg} border:none; padding:4px; }}"
        )
        self.setText(f"{self._icon_txt}\n{self._label_txt}")
        f = QFont("SF Pro Display" if sys.platform == "darwin" else "Segoe UI", 9)
        self.setFont(f)

class PillLabel(QLabel):
    def __init__(self, txt, color=SUCCESS):
        super().__init__(f"  {txt}  ")
        self.setStyleSheet(
            f"background:{color}22; color:{color}; border:1px solid {color}44;"
            f"border-radius:10px; padding:2px 6px; font-size:11px;"
        )

# ── Sayfalar ─────────────────────────────────────────────────────────────────

class SecureBootBanner(QFrame):
    def __init__(self, parent=None):
        super().__init__(parent)
        self.setVisible(False)
        self._layout = QHBoxLayout(self)
        self._icon  = label("", bold=True, size=15)
        self._title = label("", bold=True, size=12)
        self._desc  = label("", size=11)
        self._desc.setWordWrap(True)
        self._layout.addWidget(self._icon)
        v = QVBoxLayout()
        v.addWidget(self._title)
        v.addWidget(self._desc)
        self._layout.addLayout(v)

    def set_status(self, secure_boot_on: bool):
        if secure_boot_on:
            self.setStyleSheet(
                f"background:{WARNING}15; border:1px solid {WARNING}55;"
                f"border-radius:10px; padding:8px;"
            )
            self._icon.setText("⚠️")
            self._title.setText("Secure Boot is Enabled")
            self._title.setStyleSheet(f"color:{WARNING};font-weight:bold;")
            self._desc.setText(
                "Your system has Secure Boot enabled. NVIDIA proprietary drivers may "
                "fail to load unless signed with a Machine Owner Key (MOK). You may "
                "need to enroll a key after installation, or disable Secure Boot in BIOS."
            )
        else:
            self.setStyleSheet(
                f"background:{SUCCESS}15; border:1px solid {SUCCESS}55;"
                f"border-radius:10px; padding:8px;"
            )
            self._icon.setText("✅")
            self._title.setText("Secure Boot is Disabled")
            self._title.setStyleSheet(f"color:{SUCCESS};font-weight:bold;")
            self._desc.setText(
                "Third-party kernel modules (NVIDIA drivers) can load freely without "
                "MOK signing. No additional steps are required for driver installation."
            )
        self.setVisible(True)


class InstallPage(QWidget):
    go_express_confirm = Signal(bool)  # secure_boot_on
    go_expert          = Signal()

    def __init__(self, get_secure_boot, parent=None):
        super().__init__(parent)
        self._get_sb = get_secure_boot
        lo = QVBoxLayout(self)
        lo.setSpacing(12)
        lo.setContentsMargins(24, 20, 24, 20)

        # Secure Boot Banner
        self.banner = SecureBootBanner()
        lo.addWidget(self.banner)

        # Başlık
        lo.addWidget(label("Select Installation Type", bold=True, size=18))
        lo.addWidget(label("Optimized options for your hardware.", size=12, color=SUBTEXT))
        lo.addSpacing(8)

        # Kartlar
        cards = QHBoxLayout()
        cards.setSpacing(16)

        # Express kart
        exp_card = make_card()
        exp_lo = QVBoxLayout(exp_card)
        exp_head = QHBoxLayout()
        exp_head.addWidget(label("🚀", size=22))
        exp_head.addWidget(label("Express Install", bold=True, size=14))
        exp_head.addWidget(PillLabel("Recommended", SUCCESS))
        exp_head.addStretch()
        exp_lo.addLayout(exp_head)
        exp_lo.addWidget(label(
            f"Automatically installs the latest stable NVIDIA\ndriver (v{LATEST_VER}).",
            size=11, color=SUBTEXT
        ))
        btn_exp = QPushButton("Express Install →")
        btn_exp.setStyleSheet(
            f"QPushButton {{ background:{PRIMARY}; color:white; border:none; "
            f"border-radius:8px; padding:8px 16px; font-size:13px; font-weight:bold; }}"
            f"QPushButton:hover {{ background:{ACCENT}; }}"
        )
        btn_exp.clicked.connect(self._on_express)
        exp_lo.addWidget(btn_exp)
        cards.addWidget(exp_card, 1)

        # Custom kart
        cus_card = make_card()
        cus_lo = QVBoxLayout(cus_card)
        cus_head = QHBoxLayout()
        cus_head.addWidget(label("🔧", size=22))
        cus_head.addWidget(label("Custom Install (Expert)", bold=True, size=14))
        cus_head.addStretch()
        cus_lo.addLayout(cus_head)
        cus_lo.addWidget(label(
            "Manually configure version, kernel type,\nand cleanup settings.",
            size=11, color=SUBTEXT
        ))
        btn_cus = QPushButton("Open Expert →")
        btn_cus.setStyleSheet(
            f"QPushButton {{ background:transparent; color:{PRIMARY}; border:2px solid {PRIMARY}; "
            f"border-radius:8px; padding:8px 16px; font-size:13px; font-weight:bold; }}"
            f"QPushButton:hover {{ background:{PRIMARY}15; }}"
        )
        btn_cus.clicked.connect(self.go_expert)
        cus_lo.addWidget(btn_cus)
        cards.addWidget(cus_card, 1)

        lo.addLayout(cards)
        lo.addStretch()

    def showEvent(self, e):
        super().showEvent(e)
        self.banner.set_status(self._get_sb())


    def _on_express(self):
        self.go_express_confirm.emit(self._get_sb())


class ExpressConfirmPage(QWidget):
    confirmed = Signal(bool)   # use_open_kernel
    cancelled = Signal()

    def __init__(self, get_secure_boot, parent=None):
        super().__init__(parent)
        self._get_sb = get_secure_boot
        lo = QVBoxLayout(self)
        lo.setSpacing(12)
        lo.setContentsMargins(24, 20, 24, 20)

        # Geri butonu + başlık
        top = QHBoxLayout()
        back = QPushButton("← Back")
        back.setStyleSheet(
            f"QPushButton {{ background:transparent; color:{PRIMARY}; border:none; "
            f"font-size:13px; font-weight:bold; }}"
        )
        back.clicked.connect(self.cancelled)
        top.addWidget(back)
        top.addWidget(label("Express Install — Confirm Options", bold=True, size=16))
        top.addStretch()
        lo.addLayout(top)

        # Bilgi kartı
        card = make_card()
        card_lo = QVBoxLayout(card)
        card_lo.setSpacing(10)

        def info_row(k, v):
            h = QHBoxLayout()
            h.addWidget(label(k, size=12, color=SUBTEXT))
            h.addStretch()
            lv = label(v, bold=True, size=12)
            h.addWidget(lv)
            return h, lv

        row_ver, _ = info_row("Driver Version:", f"v{LATEST_VER} (Latest Stable)")
        row_gpu, _ = info_row("GPU:", "NVIDIA GeForce RTX 4070 (Simulation)")
        row_sb_h, self._sb_val = info_row("Secure Boot:", "—")
        card_lo.addLayout(row_ver)
        card_lo.addLayout(row_gpu)
        card_lo.addLayout(row_sb_h)

        sep = QFrame(); sep.setFrameShape(QFrame.HLine)
        sep.setStyleSheet(f"color:{BORDER};")
        card_lo.addWidget(sep)

        card_lo.addWidget(label("Kernel Module Type", bold=True, size=13))

        self._bg = QButtonGroup()
        for val, title, desc, checked in [
            ("proprietary", "Proprietary (Closed Source)",
             "Official NVIDIA binary driver. Best compatibility and performance.", True),
            ("open", "Open Kernel Module",
             "NVIDIA open source kernel module. Requires Turing+ GPU (RTX 20xx/30xx/40xx).", False),
        ]:
            rb = QRadioButton(title)
            rb.setChecked(checked)
            rb.setProperty("val", val)
            self._bg.addButton(rb)
            card_lo.addWidget(rb)
            card_lo.addWidget(label(f"  {desc}", size=11, color=SUBTEXT))

        # EULA uyarısı
        self._eula = QFrame()
        self._eula.setStyleSheet(
            f"background:{WARNING}15; border:1px solid {WARNING}44; border-radius:8px; padding:6px;"
        )
        eula_lo = QHBoxLayout(self._eula)
        eula_lo.addWidget(label("⚠️  By installing the NVIDIA Proprietary driver, you agree to the NVIDIA EULA.",
                                 size=11))
        card_lo.addWidget(self._eula)

        lo.addWidget(card)

        # Butonlar
        btns = QHBoxLayout()
        ok = QPushButton("Accept and Install")
        ok.setStyleSheet(
            f"QPushButton {{ background:{PRIMARY}; color:white; border:none; "
            f"border-radius:8px; padding:10px 24px; font-size:13px; font-weight:bold; }}"
            f"QPushButton:hover {{ background:{ACCENT}; }}"
        )
        ok.clicked.connect(self._confirm)
        cancel = QPushButton("Cancel")
        cancel.setStyleSheet(
            f"QPushButton {{ background:transparent; color:{SUBTEXT}; border:1px solid {BORDER}; "
            f"border-radius:8px; padding:10px 24px; font-size:13px; }}"
        )
        cancel.clicked.connect(self.cancelled)
        btns.addStretch()
        btns.addWidget(ok)
        btns.addWidget(cancel)
        lo.addLayout(btns)
        lo.addStretch()

        # Propagate EULA visibility on selection change
        self._bg.buttonToggled.connect(self._update_eula)

    def showEvent(self, e):
        super().showEvent(e)
        sb = self._get_sb()
        self._sb_val.setText("ON — MOK signing may be required" if sb else "OFF — No restrictions")
        self._sb_val.setStyleSheet(f"color:{WARNING};font-weight:bold;" if sb else f"color:{SUCCESS};font-weight:bold;")

    def _update_eula(self):
        checked = next((b for b in self._bg.buttons() if b.isChecked()), None)
        self._eula.setVisible(checked and checked.property("val") == "proprietary")

    def _confirm(self):
        checked = next((b for b in self._bg.buttons() if b.isChecked()), None)
        self.confirmed.emit(checked and checked.property("val") == "open")


class ExpertPage(QWidget):
    start_install = Signal(str, bool, bool)  # version, open_kernel, deep_clean
    back          = Signal()

    def __init__(self, parent=None):
        super().__init__(parent)
        lo = QVBoxLayout(self)
        lo.setSpacing(12)
        lo.setContentsMargins(24, 20, 24, 20)

        top = QHBoxLayout()
        back_btn = QPushButton("← Back")
        back_btn.setStyleSheet(
            f"QPushButton {{ background:transparent; color:{PRIMARY}; border:none; "
            f"font-size:13px; font-weight:bold; }}"
        )
        back_btn.clicked.connect(self.back)
        top.addWidget(back_btn)
        top.addWidget(label("Expert Driver Management", bold=True, size=16))
        top.addStretch()
        lo.addLayout(top)

        # Versiyon listesi
        lo.addWidget(label("Select Driver Version", bold=True, size=13))
        self._list = QListWidget()
        self._list.setStyleSheet(
            f"QListWidget {{ background:{CARD}; border:1px solid {BORDER}; border-radius:10px; }}"
            f"QListWidget::item {{ padding:10px; border-bottom:1px solid {BORDER}; }}"
            f"QListWidget::item:selected {{ background:{PRIMARY}22; color:{PRIMARY}; }}"
        )
        self._list.setFixedHeight(200)
        for d in DRIVER_VERSIONS:
            badge = " ★ Latest" if d["latest"] else ""
            self._list.addItem(f"  {d['ver']}   [{d['src']}]   {d['note']}{badge}")
        self._list.setCurrentRow(0)
        lo.addWidget(self._list)

        # Seçenekler
        opts = make_card()
        opts_lo = QVBoxLayout(opts)
        self._open_kernel = QCheckBox("Use Open Kernel Module (nvidia-open)  — Requires Turing+ GPU")
        self._deep_clean  = QCheckBox("Deep Clean — Remove previous driver configs & DKMS modules")
        for cb in (self._open_kernel, self._deep_clean):
            cb.setStyleSheet(f"font-size:12px; color:{TEXT};")
            opts_lo.addWidget(cb)
        lo.addWidget(opts)

        # Butonlar
        btns = QHBoxLayout()
        install_btn = QPushButton("Install Selected")
        install_btn.setStyleSheet(
            f"QPushButton {{ background:{PRIMARY}; color:white; border:none; "
            f"border-radius:8px; padding:10px 28px; font-size:13px; font-weight:bold; }}"
            f"QPushButton:hover {{ background:{ACCENT}; }}"
        )
        install_btn.clicked.connect(self._install)
        remove_btn = QPushButton("Remove All Drivers")
        remove_btn.setStyleSheet(
            f"QPushButton {{ background:{DANGER}; color:white; border:none; "
            f"border-radius:8px; padding:10px 20px; font-size:13px; font-weight:bold; }}"
            f"QPushButton:hover {{ background:#b91c1c; }}"
        )
        btns.addStretch()
        btns.addWidget(install_btn)
        btns.addWidget(remove_btn)
        lo.addLayout(btns)
        lo.addStretch()

    def _install(self):
        row  = self._list.currentRow()
        ver  = DRIVER_VERSIONS[row]["ver"]
        self.start_install.emit(ver, self._open_kernel.isChecked(), self._deep_clean.isChecked())


class ProgressPage(QWidget):
    done = Signal()

    def __init__(self, parent=None):
        super().__init__(parent)
        lo = QVBoxLayout(self)
        lo.setSpacing(10)
        lo.setContentsMargins(24, 20, 24, 20)

        self._title = label("Installation Progress", bold=True, size=18)
        lo.addWidget(self._title)

        # Büyük progress bar
        self._bar = GradientBar(PRIMARY, ACCENT)
        self._bar.setFixedHeight(14)
        lo.addWidget(self._bar)
        self._pct = label("0%", bold=True, size=13, color=PRIMARY)
        self._pct.setAlignment(Qt.AlignRight)
        lo.addWidget(self._pct)

        # Adım listesi (scrollable)
        self._steps_widget = QWidget()
        self._steps_lo = QVBoxLayout(self._steps_widget)
        self._steps_lo.setSpacing(6)
        scroll = QScrollArea()
        scroll.setWidget(self._steps_widget)
        scroll.setWidgetResizable(True)
        scroll.setFixedHeight(200)
        scroll.setStyleSheet(
            f"QScrollArea {{ border:1px solid {BORDER}; border-radius:10px; background:{CARD}; }}"
        )
        lo.addWidget(scroll)

        # Log alanı
        self._log = QTextEdit()
        self._log.setReadOnly(True)
        self._log.setFixedHeight(160)
        self._log.setStyleSheet(
            "QTextEdit { background:#111827; color:#4ade80; font-family:'Courier New',monospace; "
            "font-size:11px; border-radius:8px; padding:8px; }"
        )
        lo.addWidget(self._log)

        # Butonlar (sadece bitince görünür)
        self._btn_area = QWidget()
        btn_lo = QHBoxLayout(self._btn_area)
        btn_lo.addStretch()
        done_btn = QPushButton("Done")
        done_btn.setStyleSheet(
            f"QPushButton {{ background:{SUCCESS}; color:white; border:none; "
            f"border-radius:8px; padding:10px 28px; font-size:13px; font-weight:bold; }}"
        )
        done_btn.clicked.connect(self.done)
        reboot_btn = QPushButton("Reboot Now")
        reboot_btn.setStyleSheet(
            f"QPushButton {{ background:{WARNING}; color:white; border:none; "
            f"border-radius:8px; padding:10px 28px; font-size:13px; font-weight:bold; }}"
        )
        btn_lo.addWidget(done_btn)
        btn_lo.addWidget(reboot_btn)
        self._btn_area.setVisible(False)
        lo.addWidget(self._btn_area)

        self._timer = QTimer()
        self._timer.timeout.connect(self._tick)
        self._steps = []
        self._step_labels = []
        self._cur = 0

    def start(self, version, open_kernel, deep_clean):
        # Title
        ktype = "Open Kernel" if open_kernel else "Proprietary"
        self._title.setText(f"Installing NVIDIA {ktype} Driver v{version}")
        self._bar.setValue(0)
        self._pct.setText("0%")
        self._log.clear()
        self._btn_area.setVisible(False)
        for i in reversed(range(self._steps_lo.count())):
            w = self._steps_lo.itemAt(i).widget()
            if w: w.deleteLater()
        self._step_labels.clear()

        # Build steps
        steps = [("📋", "Backing up Xorg configuration")]
        if deep_clean:
            steps += [
                ("🧹", "Deep cleaning previous driver configs"),
                ("🗑️", "Removing old NVIDIA packages"),
            ]
        steps += [
            ("🚫", "Blacklisting nouveau driver"),
            ("⚙️", "Installing kernel headers (kernel-devel)"),
            ("📦", "Enabling RPM Fusion repository"),
        ]
        if open_kernel:
            steps.append(("🔓", "Installing NVIDIA Open Kernel Module (nvidia-open)"))
        else:
            steps.append(("🎮", "Installing NVIDIA Proprietary driver (akmod-nvidia)"))
        steps += [
            ("🔄", "Regenerating initramfs (dracut --force)"),
            ("✅", "Verifying installation"),
        ]
        self._steps = steps

        # Create step widgets
        for ico, txt in steps:
            row = QHBoxLayout()
            st  = label("⏳", size=14)
            tx  = label(f"  {txt}", size=12)
            row.addWidget(st)
            row.addWidget(tx)
            row.addStretch()
            w = QWidget()
            w.setLayout(row)
            self._steps_lo.addWidget(w)
            self._step_labels.append(st)

        # Log header
        now = datetime.now().strftime("%H:%M:%S")
        op  = "Open Kernel Module" if open_kernel else "Proprietary"
        self._appendlog(f"--- OPERATION STARTING: NVIDIA {op} ---")
        self._appendlog(f"Version: {version}")
        self._appendlog(f"Package Manager: dnf")
        self._appendlog(f"Open Kernel: {'YES' if open_kernel else 'NO'}")
        self._appendlog(f"Deep Clean: {'YES' if deep_clean else 'NO'}")
        self._appendlog(f"Waiting for authorization (Root/Admin)...")
        self._appendlog("")

        self._cur      = 0
        self._ok       = open_kernel
        self._dc       = deep_clean
        self._total    = len(steps)
        self._delay    = 0
        self._phase    = "start"
        self._timer.start(800)

    def _appendlog(self, txt):
        ts = datetime.now().strftime("%H:%M:%S")
        self._log.append(f"[{ts}] {txt}")

    def _tick(self):
        if self._cur >= self._total:
            self._timer.stop()
            # Final log
            if self._dc:
                self._appendlog("[Deep Clean] Removed: /etc/X11/xorg.conf.d/nvidia*")
                self._appendlog("[Deep Clean] Purged old DKMS modules")
            if self._ok:
                self._appendlog("[Open Kernel] nvidia-open module loaded successfully")
                self._appendlog("[Open Kernel] Module verification: PASS")
            else:
                self._appendlog("[Proprietary] akmod-nvidia built successfully")
                self._appendlog("[Proprietary] Module verification: PASS")
            self._appendlog("")
            ktype = "Open Kernel" if self._ok else "Proprietary"
            self._appendlog(f"SUCCESS: NVIDIA {ktype} Installation completed.")
            self._appendlog("Reboot the system for changes to take effect.")
            self._bar.setValue(100)
            self._pct.setText("100%")
            self._btn_area.setVisible(True)
            return

        lbl = self._step_labels[self._cur]
        ico, txt = self._steps[self._cur]

        if self._phase == "start":
            lbl.setText("⏳")
            self._appendlog(f"→ {txt}...")
            prog = int((self._cur + 0.5) / self._total * 100)
            self._bar.setValue(prog)
            self._pct.setText(f"{prog}%")
            self._phase = "done"
            self._timer.start(600 + random.randint(0, 800))
        else:
            lbl.setText("✅")
            self._appendlog(f"  ✓ {txt} — done")
            prog = int((self._cur + 1) / self._total * 100)
            self._bar.setValue(prog)
            self._pct.setText(f"{prog}%")
            self._cur  += 1
            self._phase = "start"
            self._timer.start(400)


class MonitorPage(QWidget):
    VRAM_TOTAL = 12288
    RAM_TOTAL  = 32768

    def __init__(self, parent=None):
        super().__init__(parent)
        lo = QVBoxLayout(self)
        lo.setSpacing(12)
        lo.setContentsMargins(24, 20, 24, 20)
        lo.addWidget(label("Performance Monitor", bold=True, size=18))

        # Sistem info kartları
        info_grid = QGridLayout()
        infos = [
            ("💻", "OS",      "Fedora 40 Workstation"),
            ("🔧", "Kernel",  "6.8.11-300.fc40"),
            ("⚙️", "CPU",     "AMD Ryzen 7 5800X"),
            ("🧠", "RAM",     "32 GB"),
            ("🎮", "GPU",     "NVIDIA RTX 4070 (Simulation)"),
            ("📊", "Display", "Wayland"),
        ]
        for i, (ico, k, v) in enumerate(infos):
            c = make_card(8)
            cl = QVBoxLayout(c)
            cl.addWidget(label(ico, size=14))
            cl.addWidget(label(k, size=10, color=SUBTEXT))
            cl.addWidget(label(v, bold=True, size=12))
            info_grid.addWidget(c, i//3, i%3)
        lo.addLayout(info_grid)

        # Live stats
        stats = QHBoxLayout()
        stats.setSpacing(12)

        gpu_card = make_card()
        gc_lo = QVBoxLayout(gpu_card)
        gc_lo.addWidget(label("🎮 Live GPU Status", bold=True, size=13))
        self._gpu_bars = {}
        for k, label_txt in [("gpuTemp","🌡 Temp"),("gpuLoad","⚡ Load"),("vram","💾 VRAM")]:
            row = QHBoxLayout()
            l = label(label_txt, size=11, color=SUBTEXT); l.setFixedWidth(65)
            bar= GradientBar(PRIMARY, ACCENT)
            bar.setFixedHeight(10)
            val= label("—", size=11, color=TEXT); val.setFixedWidth(110); val.setAlignment(Qt.AlignRight)
            row.addWidget(l); row.addWidget(bar,1); row.addWidget(val)
            gc_lo.addLayout(row)
            self._gpu_bars[k] = (bar, val)
        stats.addWidget(gpu_card,1)

        sys_card = make_card()
        sc_lo = QVBoxLayout(sys_card)
        sc_lo.addWidget(label("🖥 Live System Usage", bold=True, size=13))
        self._sys_bars = {}
        for k, label_txt in [("cpuLoad","⚡ CPU"),("cpuTemp","🌡 CPU Temp"),("ram","🧠 RAM")]:
            row = QHBoxLayout()
            l = label(label_txt, size=11, color=SUBTEXT); l.setFixedWidth(80)
            bar= GradientBar(SUCCESS, PRIMARY)
            bar.setFixedHeight(10)
            val= label("—", size=11, color=TEXT); val.setFixedWidth(110); val.setAlignment(Qt.AlignRight)
            row.addWidget(l); row.addWidget(bar,1); row.addWidget(val)
            sc_lo.addLayout(row)
            self._sys_bars[k] = (bar, val)
        stats.addWidget(sys_card,1)
        lo.addLayout(stats)

        # Footer
        self._footer = label("Live data • Refresh: 1000ms • Using QTimer + EMA interpolation",
                              size=10, color=SUBTEXT)
        lo.addWidget(self._footer)
        lo.addStretch()

        # State
        self._sensors = {
            "gpuTemp": {"c": 40.0, "t": 40},
            "gpuLoad": {"c": 10.0, "t": 10},
            "vram":    {"c": 1400.0,"t":1400},
            "cpuLoad": {"c": 15.0, "t": 15},
            "cpuTemp": {"c": 45.0, "t": 45},
            "ram":     {"c": 8200.0,"t":8200},
        }
        self._target_timer= QTimer()
        self._target_timer.timeout.connect(self._update_targets)
        self._smooth_timer = QTimer()
        self._smooth_timer.timeout.connect(self._smooth_tick)

    def start(self):
        self._update_targets()
        self._target_timer.start(1000)
        self._smooth_timer.start(30)

    def stop(self):
        self._target_timer.stop()
        self._smooth_timer.stop()

    def _update_targets(self):
        self._sensors["gpuTemp"]["t"] = random.randint(35,70)
        self._sensors["gpuLoad"]["t"] = random.randint(0,80)
        self._sensors["vram"]["t"]    = random.randint(800,5000)
        self._sensors["cpuLoad"]["t"] = random.randint(5,60)
        self._sensors["cpuTemp"]["t"] = random.randint(38,70)
        self._sensors["ram"]["t"]     = random.randint(5000,18000)
        now = datetime.now().strftime("%H:%M:%S")
        self._footer.setText(f"Live data • Updated at {now} • Refresh: 1000ms • EMA smooth")

    def _smooth_tick(self):
        a = 0.06
        for k, s in self._sensors.items():
            s["c"] += (s["t"] - s["c"]) * a

        def upd(bars, k, val, max_val, txt):
            bar, lbl = bars[k]
            bar.setValue(int(val/max_val*100))
            lbl.setText(txt)

        s = self._sensors
        upd(self._gpu_bars,"gpuTemp", s["gpuTemp"]["c"], 100, f"{s['gpuTemp']['c']:.0f}°C")
        upd(self._gpu_bars,"gpuLoad", s["gpuLoad"]["c"], 100, f"{s['gpuLoad']['c']:.0f}%")
        upd(self._gpu_bars,"vram",    s["vram"]["c"],    self.VRAM_TOTAL, f"{s['vram']['c']:.0f} / {self.VRAM_TOTAL} MB")
        upd(self._sys_bars,"cpuLoad", s["cpuLoad"]["c"],100, f"{s['cpuLoad']['c']:.0f}%")
        upd(self._sys_bars,"cpuTemp", s["cpuTemp"]["c"],100, f"{s['cpuTemp']['c']:.0f}°C")
        upd(self._sys_bars,"ram",     s["ram"]["c"],     self.RAM_TOTAL,  f"{s['ram']['c']:.0f} / {self.RAM_TOTAL} MB")


# ── Ana Pencere ───────────────────────────────────────────────────────────────

class MainWindow(QMainWindow):
    def __init__(self):
        super().__init__()
        self.setWindowTitle("ro-Control  —  macOS Native Qt Simulation")
        self.resize(1060, 720)
        self.setMinimumSize(900, 620)
        self.setStyleSheet(f"QMainWindow {{ background:{BG}; }}")

        # Simulated state
        self._secure_boot = random.random() > 0.5  # rastgele başlat

        # ── Root container ──
        central = QWidget()
        self.setCentralWidget(central)
        root = QVBoxLayout(central)
        root.setContentsMargins(0,0,0,0)
        root.setSpacing(0)

        # ── Header ──
        header = QFrame()
        header.setFixedHeight(52)
        header.setStyleSheet(
            f"background:{CARD}; border-bottom:1px solid {BORDER};"
        )
        h_lo = QHBoxLayout(header)
        h_lo.setContentsMargins(16,0,16,0)

        # Logo  (gradient rectangle + shield text)
        logo_box = QFrame()
        logo_box.setFixedSize(32,32)
        logo_box.setStyleSheet(
            f"background:qlineargradient(x1:0,y1:0,x2:1,y2:1,"
            f"stop:0 {PRIMARY},stop:1 {ACCENT}); border-radius:8px;"
        )
        logo_lbl = QLabel("🛡", logo_box)
        logo_lbl.setAlignment(Qt.AlignCenter)
        logo_lbl.setFixedSize(32,32)
        logo_lbl.setStyleSheet("background:transparent; font-size:16px;")

        h_lo.addWidget(logo_box)
        h_lo.addSpacing(8)
        h_lo.addWidget(label("ro-Control", bold=True, size=14))
        badge = QLabel("Rust Edition")
        badge.setStyleSheet(
            f"background:{PRIMARY}; color:white; font-size:10px; font-weight:bold; "
            f"border-radius:6px; padding:2px 7px;"
        )
        h_lo.addWidget(badge)
        h_lo.addStretch()

        # Secure boot pill
        sb_txt = "⚠ Secure Boot ON" if self._secure_boot else "🔓 Secure Boot OFF"
        sb_col = WARNING if self._secure_boot else SUCCESS
        self._sb_pill = PillLabel(sb_txt, sb_col)
        h_lo.addWidget(self._sb_pill)
        h_lo.addSpacing(8)

        # Hakkında butonu
        about_btn = QPushButton("About")
        about_btn.setStyleSheet(
            f"QPushButton {{ background:transparent; color:{PRIMARY}; border:1px solid {PRIMARY}; "
            f"border-radius:6px; padding:4px 12px; font-size:12px; }}"
        )
        about_btn.clicked.connect(self._show_about)
        h_lo.addWidget(about_btn)

        root.addWidget(header)

        # ── Body (sidebar + content) ──
        body = QHBoxLayout()
        body.setSpacing(0)
        body.setContentsMargins(0,0,0,0)

        # Sidebar
        sidebar = QFrame()
        sidebar.setFixedWidth(80)
        sidebar.setStyleSheet(f"background:{SIDEBAR}; border-right:1px solid {BORDER};")
        sb_lo = QVBoxLayout(sidebar)
        sb_lo.setContentsMargins(4,16,4,16)
        sb_lo.setSpacing(4)
        sb_lo.setAlignment(Qt.AlignTop)

        self._nav_group = QButtonGroup()
        self._nav_btns  = {}
        for page_id, ico, txt in [
            ("install","📦","Install"),
            ("expert", "⚙️","Expert"),
            ("monitor","📊","Monitor"),
        ]:
            btn = NavButton(ico, txt)
            self._nav_group.addButton(btn)
            self._nav_btns[page_id] = btn
            btn.clicked.connect(lambda _, p=page_id: self._go(p))
            sb_lo.addWidget(btn, alignment=Qt.AlignHCenter)

        sb_lo.addStretch()
        ver_lbl = label("v1.1.0", size=10, color=SUBTEXT)
        ver_lbl.setAlignment(Qt.AlignHCenter)
        sb_lo.addWidget(ver_lbl)

        body.addWidget(sidebar)

        # Stacked pages
        self._stack = QStackedWidget()
        self._stack.setStyleSheet(f"background:{BG};")

        self._pg_install= InstallPage(lambda: self._secure_boot)
        self._pg_express= ExpressConfirmPage(lambda: self._secure_boot)
        self._pg_expert = ExpertPage()
        self._pg_progress=ProgressPage()
        self._pg_monitor= MonitorPage()

        for pg in (self._pg_install, self._pg_express, self._pg_expert,
                   self._pg_progress, self._pg_monitor):
            self._stack.addWidget(pg)

        # Sinyaller
        self._pg_install.go_express_confirm.connect(self._pg_express.showEvent)  # showEvent refresh
        self._pg_install.go_express_confirm.connect(lambda _: self._go("express"))
        self._pg_install.go_expert.connect(lambda: self._go("expert"))
        self._pg_express.confirmed.connect(self._start_express)
        self._pg_express.cancelled.connect(lambda: self._go("install"))
        self._pg_expert.start_install.connect(self._start_install)
        self._pg_expert.back.connect(lambda: self._go("install"))
        self._pg_progress.done.connect(lambda: self._go("install"))

        body.addWidget(self._stack, 1)
        root.addLayout(body)

        # İlk sayfa
        self._go("install")
        self._nav_btns["install"].setChecked(True)

    def _go(self, page_id):
        # Monitor page: start/stop timers
        if page_id == "monitor":
            self._pg_monitor.start()
        else:
            self._pg_monitor.stop()

        mapping = {
            "install":  self._pg_install,
            "express":  self._pg_express,
            "expert":   self._pg_expert,
            "progress": self._pg_progress,
            "monitor":  self._pg_monitor,
        }
        if page_id in mapping:
            self._stack.setCurrentWidget(mapping[page_id])

        # Nav butonlarını güncelle
        nav_map = {"install":"install","express":"install",
                   "progress":"install","expert":"expert","monitor":"monitor"}
        active = nav_map.get(page_id,"install")
        for k, btn in self._nav_btns.items():
            btn.setChecked(k == active)

    def _start_express(self, open_kernel):
        self._go("progress")
        self._pg_progress.start(LATEST_VER, open_kernel, False)

    def _start_install(self, ver, open_kernel, deep_clean):
        self._go("progress")
        self._pg_progress.start(ver, open_kernel, deep_clean)

    def _show_about(self):
        d = AboutDialog(self)
        d.exec()


class AboutDialog(QDialog):
    def __init__(self, parent=None):
        super().__init__(parent)
        self.setWindowTitle("About ro-Control")
        self.setMinimumWidth(520)
        self.setModal(True)
        lo = QVBoxLayout(self)
        lo.setSpacing(12)

        # Logo
        logo = label("🛡", size=42)
        logo.setAlignment(Qt.AlignCenter)
        lo.addWidget(logo)

        lo.addWidget(label("ro-Control", bold=True, size=20).__class__.__new__(
            label("ro-Control", bold=True, size=20).__class__
        ))
        # simple version
        title = QLabel("ro-Control")
        title.setAlignment(Qt.AlignCenter)
        title.setStyleSheet(f"font-size:20px; font-weight:bold; color:{TEXT};")
        lo.addWidget(title)

        ver = QLabel("v1.1.0 — Rust Edition")
        ver.setAlignment(Qt.AlignCenter)
        ver.setStyleSheet(f"font-size:13px; color:{PRIMARY}; font-weight:bold;")
        lo.addWidget(ver)

        desc = QLabel("Smart GPU driver manager for Linux.\nBuilt with Rust + Qt6/QML (CXX-Qt)")
        desc.setAlignment(Qt.AlignCenter)
        desc.setStyleSheet(f"font-size:12px; color:{SUBTEXT};")
        lo.addWidget(desc)

        org = QLabel("ro-ASD")
        org.setAlignment(Qt.AlignCenter)
        org.setStyleSheet(f"font-size:12px; color:{PRIMARY}; font-weight:bold;")
        lo.addWidget(org)

        # Changelog sekmeleri
        lo.addWidget(label("Changelog", bold=True, size=13))
        tab_row = QHBoxLayout()
        self._tabs = {}
        self._tab_contents = {}
        for ver_id, txt in [("1.1.0","v1.1.0"),("1.0.0","v1.0.0")]:
            btn = QPushButton(txt)
            btn.setCheckable(True)
            btn.setProperty("ver", ver_id)
            btn.clicked.connect(self._switch_tab)
            tab_row.addWidget(btn)
            self._tabs[ver_id] = btn
        tab_row.addStretch()
        lo.addLayout(tab_row)

        # 1.1.0 içeriği
        c110 = QLabel(
            "• Premium Rust Edition visual identity\n"
            "• Modern color palette (blue / purple / emerald)\n"
            "• Express Install confirmation with kernel type selection\n"
            "• Secure Boot status banner with explanations\n"
            "• Security: root-task script hardened against command injection\n"
            "• 49 unit tests (+113% increase)\n"
            "• Shared version parsing module\n"
            "• All log messages standardized to English"
        )
        c110.setStyleSheet(
            f"background:{SIDEBAR}; border-radius:8px; padding:10px; font-size:12px; color:{TEXT};"
        )
        self._tab_contents["1.1.0"] = c110
        lo.addWidget(c110)

        c100 = QLabel(
            "• NVIDIA proprietary driver install via RPM Fusion (akmod-nvidia)\n"
            "• NVIDIA Open Kernel module install\n"
            "• Live GPU/CPU/RAM performance dashboard\n"
            "• Feral GameMode integration\n"
            "• Flatpak/Steam permission repair\n"
            "• NVIDIA Wayland fix (nvidia-drm.modeset=1)\n"
            "• Hybrid graphics switching\n"
            "• Auto-update via GitHub Releases\n"
            "• Turkish / English bilingual UI"
        )
        c100.setStyleSheet(
            f"background:{SIDEBAR}; border-radius:8px; padding:10px; font-size:12px; color:{TEXT};"
        )
        c100.setVisible(False)
        self._tab_contents["1.0.0"] = c100
        lo.addWidget(c100)

        # Close
        close_btn = QPushButton("Close")
        close_btn.setStyleSheet(
            f"QPushButton {{ background:{PRIMARY}; color:white; border:none; "
            f"border-radius:8px; padding:8px 28px; font-size:13px; font-weight:bold; }}"
        )
        close_btn.clicked.connect(self.accept)
        lo.addWidget(close_btn, alignment=Qt.AlignHCenter)

        self._switch_tab_id("1.1.0")

    def _switch_tab(self):
        btn = self.sender()
        self._switch_tab_id(btn.property("ver"))

    def _switch_tab_id(self, ver_id):
        for k, btn in self._tabs.items():
            act = k == ver_id
            btn.setChecked(act)
            btn.setStyleSheet(
                f"QPushButton {{ background:{PRIMARY if act else 'transparent'}; "
                f"color:{'white' if act else PRIMARY}; border:{'none' if act else f'1px solid {PRIMARY}'}; "
                f"border-radius:6px; padding:4px 14px; font-size:12px; }}"
            )
        for k, w in self._tab_contents.items():
            w.setVisible(k == ver_id)


# ── Giriş Noktası ────────────────────────────────────────────────────────────
if __name__ == "__main__":
    app = QApplication(sys.argv)
    app.setApplicationName("ro-Control")
    app.setApplicationVersion("1.1.0")
    app.setOrganizationName("ro-ASD")

    # macOS native görünüm
    if sys.platform == "darwin":
        app.setStyle("macOS")

    win = MainWindow()
    win.show()
    sys.exit(app.exec())
