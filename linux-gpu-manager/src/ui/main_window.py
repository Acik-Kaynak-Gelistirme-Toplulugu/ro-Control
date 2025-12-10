import gi
import logging
import os
import threading
import subprocess
import datetime
import socket
import sys
import shutil

# GTK4 / GTK3 Uyumluluk
try:
    gi.require_version('Gtk', '4.0')
    from gi.repository import Gtk, Gdk, Gio, GLib, GObject
    try:
        gi.require_version('Adw', '1') 
        from gi.repository import Adw
        BaseApp = Adw.Application
        IsAdwaita = True
    except ValueError:
        BaseApp = Gtk.Application
        IsAdwaita = False
        logging.info("Adwaita bulunamadı, GTK4 Standart modunda çalışıyor.")
except ValueError:
    try:
        gi.require_version('Gtk', '3.0')
        from gi.repository import Gtk, Gdk, Gio, GLib, GObject
        Adw = None 
        BaseApp = Gtk.Application
        IsAdwaita = False
        logging.warning("GTK4 bulunamadı, GTK3 fallback.")
    except ValueError:
        raise ImportError("GTK bulunamadı.")

from src.core.installer import DriverInstaller
from src.core.detector import SystemDetector
from src.core.repo_manager import RepoManager
from src.utils.reporter import ErrorReporter
from src.config import AppConfig
from src.ui.performance_view import PerformanceView

class MainWindow(Gtk.ApplicationWindow):
    def __init__(self, app):
        super().__init__(application=app)
        self.set_title(AppConfig.PRETTY_NAME)
        self.set_default_size(950, 680) 
        self.load_css()

        self.target_action = None
        self.selected_version = None 
        self.is_processing = False
        self.dark_mode = True # Başlangıç teması

        # --- Managers ---
        self.repo_manager = RepoManager()

        # --- Header Setup ---
        header = Gtk.HeaderBar()
        self.set_titlebar(header)

        # Tab Switcher
        self.stack = Gtk.Stack()
        self.stack.set_transition_type(Gtk.StackTransitionType.SLIDE_LEFT_RIGHT)
        
        stack_switcher = Gtk.StackSwitcher()
        stack_switcher.set_stack(self.stack)
        header.set_title_widget(stack_switcher)
        
        # Tema Butonu
        self.theme_btn = Gtk.Button()
        self.theme_btn.set_icon_name("weather-clear-symbolic")
        self.theme_btn.connect("clicked", self.toggle_theme)
        header.pack_end(self.theme_btn)
        
        # Menu Butonu
        menu_button = Gtk.Button()
        menu_button.set_icon_name("open-menu-symbolic")
        menu_button.connect("clicked", self.show_about_dialog)
        header.pack_end(menu_button)

        self.apply_theme()

        # --- Logic Classes ---
        self.detector = SystemDetector()
        self.installer = DriverInstaller()
        self.available_versions = self.installer.get_available_versions()
        self.gpu_info = self.detector.detect()

        # --- Main Layout ---
        main_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL)
        
        # Header Info (Banner)
        self.status_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL)
        self.create_info_bars() 
        self._update_ui_state() # İlk metinleri ayarla

        main_box.append(self.status_box)
        main_box.append(self.stack) # Stack'i ekle
        main_box.append(self.create_log_area()) # Alt panel
        
        self.set_child(main_box)

        # --- Sayfaları Oluştur ve Ekle ---
        self.simple_view = self.create_simple_view()
        self.expert_view = self.create_pro_view()
        self.perf_view = PerformanceView()

        self.stack.add_titled(self.simple_view, "simple", "Kurulum")
        self.stack.add_titled(self.expert_view, "expert", "Uzman")
        self.stack.add_titled(self.perf_view, "performance", "Performans")
        
        # İlk tarama
        GLib.timeout_add(500, self.run_initial_scan)

    # --- UI Builders ---
    def create_info_bars(self):
        # Header Label (Info)
        self.header_label = Gtk.Label()
        self.header_label.add_css_class("title-2")
        self.header_label.set_margin_top(15)
        
        self.status_label = Gtk.Label()
        self.status_label.add_css_class("dim-label")
        self.status_label.set_margin_bottom(10)

        self.status_box.append(self.header_label)
        self.status_box.append(self.status_label)
        
        # Secure Boot Banner
        self.sb_banner = Gtk.InfoBar()
        self.sb_banner.set_message_type(Gtk.MessageType.WARNING)
        self.sb_banner.set_show_close_button(True)
        self.sb_banner.set_revealed(False)
        self.sb_banner.connect("response", lambda w, r: self.sb_banner.set_revealed(False))
        
        sb_label = Gtk.Label(label="⚠️ Secure Boot Açık! İmzasız sürücüler çalışmayabilir. BIOS'tan kapatmanız önerilir.")
        self.sb_banner.add_child(sb_label)
        
        self.status_box.append(self.sb_banner)

    def create_simple_view(self):
        vbox = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=20)
        vbox.set_margin_top(40); vbox.set_margin_bottom(40)
        vbox.set_margin_start(40); vbox.set_margin_end(40)
        vbox.set_valign(Gtk.Align.CENTER)

        # Logo ve Büyük Başlık
        title_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=10)
        icon = self.get_logo_image()
        icon.set_pixel_size(96)
        title_box.append(icon)
        
        gpu_vendor = self.gpu_info.get('vendor', 'Unknown')
        gpu_model = self.gpu_info.get('model', 'GPU')
        
        self.simple_gpu_label = Gtk.Label(label=f"{gpu_vendor} {gpu_model}")
        self.simple_gpu_label.set_css_classes(["title-1", "accent"])
        title_box.append(self.simple_gpu_label)
        
        vbox.append(title_box)

        # Kartlar
        cards = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=30)
        cards.set_homogeneous(True)
        
        # --- Dinamik Kart Mantığı ---
        is_amd = "AMD" in gpu_vendor or "Advanced Micro Devices" in gpu_vendor
        
        if is_amd:
            # AMD İçin Arayüz
            self.btn_simple_open = self.create_card("security-high-symbolic", "AMD Sürücüleri\n(Mesa/Open)", 
                "AMD kartlar için en iyi performans ve uyumluluk.\n(Önerilen)", self.on_simple_open_clicked)
            cards.append(self.btn_simple_open)
        else:
            # NVIDIA (veya Diğer) İçin Arayüz
            self.btn_simple_closed = self.create_card("speedometer-symbolic", "Yüksek Performans\n(NVIDIA Proprietary)", 
                "Oyun ve Maksimum FPS için.\nKapalı kaynak kodlu resmi sürücü.", self.on_simple_closed_clicked)
            cards.append(self.btn_simple_closed)

            self.btn_simple_open = self.create_card("security-high-symbolic", "NVIDIA Open Kernel\n(Resmi Açık Kaynak)", 
                "Modern kartlar (RTX 20+) için.\nÇekirdek modülü açık kaynaktır. (Nouveau DEĞİLDİR)", self.on_simple_open_clicked)
            cards.append(self.btn_simple_open)
        
        # Reset Butonu (Herkes İçin)
        self.btn_simple_reset = self.create_card("system-reboot-symbolic", "Sürücüleri Kaldır\n(Nouveau'ya Dön)", 
            "Tüm NVIDIA/AMD sürücülerini siler.\nSistemi varsayılan Nouveau sürücüsüne döndürür.", self.on_nouveau_clicked)
        cards.append(self.btn_simple_reset)
        
        vbox.append(cards)
        return vbox

    def create_pro_view(self):
        box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=20)
        box.set_margin_top(20); box.set_margin_bottom(20); box.set_margin_start(40); box.set_margin_end(40)

        box.append(Gtk.Label(label="Uzman Sürücü Yönetimi", css_classes=["title-1"]))
        
        # Versiyon Seçimi
        ver_box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=10)
        ver_box.set_halign(Gtk.Align.CENTER)
        ver_box.append(Gtk.Label(label="Versiyon Seç:"))
        self.ver_combo = Gtk.ComboBoxText()
        for v in self.available_versions: self.ver_combo.append(v, f"v{v}")
        if self.available_versions: self.ver_combo.set_active(0)
        self.ver_combo.connect("changed", self.on_version_changed)
        ver_box.append(self.ver_combo)
        box.append(ver_box)
        
        # Seçenekler (Checkboxlar)
        opts_chk = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=20)
        opts_chk.set_halign(Gtk.Align.CENTER)
        
        self.chk_deep_clean = Gtk.CheckButton(label="Derin Temizlik (Kalıntıları Sil)")
        self.chk_deep_clean.set_active(True)
        opts_chk.append(self.chk_deep_clean)
        
        box.append(opts_chk)

        # İşlem Butonları
        opts = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=15)
        opts.set_homogeneous(True)
        self.btn_nouveau = Gtk.Button(label="Sıfırla (Nouveau)"); self.btn_nouveau.connect("clicked", self.on_nouveau_clicked); opts.append(self.btn_nouveau)
        self.btn_open = Gtk.Button(label="Open Kernel"); self.btn_open.connect("clicked", self.on_open_clicked); opts.append(self.btn_open)
        self.btn_closed = Gtk.Button(label="Proprietary"); self.btn_closed.connect("clicked", self.on_closed_clicked); opts.append(self.btn_closed)
        box.append(opts)

        # Repo ve Araçlar
        tools = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=10)
        tools.set_halign(Gtk.Align.CENTER)
        
        btn_repo = Gtk.Button(label="Repoları İyileştir (Konum Bazlı)"); 
        btn_repo.set_icon_name("network-server-symbolic")
        btn_repo.connect("clicked", self.on_optimize_clicked)
        tools.append(btn_repo)
        
        btn_scan = Gtk.Button(label="Yeniden Tara"); btn_scan.connect("clicked", self.on_scan_clicked); tools.append(btn_scan)
        btn_test = Gtk.Button(label="Test (Glxgears)"); btn_test.connect("clicked", self.on_test_clicked); tools.append(btn_test)
        box.append(tools)
        return box

    def create_card(self, icon_name, title, desc, callback):
        btn = Gtk.Button()
        box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=15)
        box.set_margin_top(20); box.set_margin_bottom(20); box.set_margin_start(15); box.set_margin_end(15)
        
        icon = Gtk.Image.new_from_icon_name(icon_name)
        icon.set_pixel_size(64)
        lbl_t = Gtk.Label(label=title); lbl_t.set_css_classes(["heading"]); lbl_t.set_justify(Gtk.Justification.CENTER)
        lbl_d = Gtk.Label(label=desc); lbl_d.set_wrap(True); lbl_d.set_justify(Gtk.Justification.CENTER); lbl_d.set_max_width_chars(30)
        
        box.append(icon); box.append(lbl_t); box.append(lbl_d)
        btn.set_child(box)
        btn.connect("clicked", callback)
        return btn

    def create_log_area(self):
        self.log_expander = Gtk.Expander(label="İşlem Detayları")
        self.log_view = Gtk.TextView(editable=False, monospace=True)
        self.log_buffer = self.log_view.get_buffer()
        
        scroll = Gtk.ScrolledWindow()
        scroll.set_min_content_height(120)
        scroll.set_child(self.log_view)
        
        ctrl = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=5)
        
        # Progress Bar
        self.progress_bar = Gtk.ProgressBar()
        self.progress_bar.set_text("Hazır")
        self.progress_bar.set_show_text(True)
        ctrl.append(self.progress_bar)
        ctrl.append(scroll)
        
        btn_save = Gtk.Button(label="Log Kaydet", halign=Gtk.Align.END)
        btn_save.connect("clicked", self.on_save_log_clicked)
        ctrl.append(btn_save)
        
        self.log_expander.set_child(ctrl)
        
        box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL)
        box.set_margin_top(10)
        box.set_margin_start(20); box.set_margin_end(20); box.set_margin_bottom(20)
        box.append(self.log_expander)
        return box

    # --- Actions ---
    def check_network(self):
        try:
            socket.create_connection(("8.8.8.8", 53), timeout=3)
            return True
        except: return False

    def run_initial_scan(self):
        self._update_ui_state()
        return False

    def _update_ui_state(self):
        gpu = self.gpu_info
        sb_status = "Aktif" if gpu.get("secure_boot") else "Devre Dışı"
        self.status_label.set_text(f"Aktif Sürücü: {gpu.get('driver_in_use')} | Secure Boot: {sb_status}")

        if gpu.get("secure_boot") and "NVIDIA" in gpu.get("vendor", ""):
             self.sb_banner.set_revealed(True)
        else:
             self.sb_banner.set_revealed(False)
             
        # Basit Görünüm Başlığı Güncelle
        if hasattr(self, "simple_gpu_label"):
            self.simple_gpu_label.set_text(f"{gpu.get('vendor')} {gpu.get('model')}")

    def on_version_changed(self, combo):
        self.selected_version = combo.get_active_id()

    def on_scan_clicked(self, w):
        self.gpu_info = self.detector.detect(force_refresh=True)
        self._update_ui_state()

    def on_optimize_clicked(self, w):
        self.start_transaction("Repo Optimizasyonu (Konum + PPA)...")
        self.target_action = "optimize_repos"

    def on_simple_closed_clicked(self, w): 
        if "AMD" in self.gpu_info.get("vendor", ""): return
        self.selected_version = None; self.validate_and_start("install_nvidia_closed", "Kapalı Kaynak Kurulumu...")

    def on_simple_open_clicked(self, w): 
        if "AMD" in self.gpu_info.get("vendor", ""):
             self.validate_and_start("install_amd_open", "AMD Driver (Mesa) Kurulumu...")
             return
        self.selected_version = None; self.validate_and_start("install_nvidia_open", "Açık Kaynak Kurulumu...")

    def on_nouveau_clicked(self, w): self.validate_and_start("remove", "Nouveau Dönüşü (Reset)...")
    def on_open_clicked(self, w): self.validate_and_start("install_nvidia_open", f"Open Kernel v{self.selected_version}...")
    def on_closed_clicked(self, w): self.validate_and_start("install_nvidia_closed", f"Proprietary v{self.selected_version}...")
    def on_test_clicked(self, w): subprocess.Popen(["glxgears"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    
    def on_save_log_clicked(self, w):
        d = Gtk.FileChooserDialog(title="Log Kaydet", parent=self, action=Gtk.FileChooserAction.SAVE)
        d.add_buttons("İptal", Gtk.ResponseType.CANCEL, "Kaydet", Gtk.ResponseType.ACCEPT)
        d.set_current_name(f"gpu-log-{datetime.datetime.now().strftime('%H%M')}.txt")
        def resp(dlg, res):
            if res == Gtk.ResponseType.ACCEPT:
                try:
                    with open(dlg.get_file().get_path(), "w") as f:
                        f.write(self.log_buffer.get_text(self.log_buffer.get_start_iter(), self.log_buffer.get_end_iter(), True))
                except: passed
            dlg.destroy()
        d.connect("response", resp); d.show()

    def validate_and_start(self, action, desc):
        if not self.check_network() and action != "remove":
            self.show_error_dialog("İnternet Yok", "Sürücü indirmek için internet bağlantısı gereklidir.")
            return

        if "install" in action or action == "remove":
            if shutil.which("timeshift"):
                self.ask_for_snapshot(action, desc)
                return

        self.target_action = action
        self.start_transaction(desc)

    def ask_for_snapshot(self, action, desc):
        dialog = Gtk.MessageDialog(transient_for=self, modal=True, message_type=Gtk.MessageType.QUESTION, buttons=Gtk.ButtonsType.YES_NO, text="Sistem Yedeği")
        dialog.format_secondary_text(f"İşleme başlamadan önce Timeshift ile sistem yedeği (snapshot) alınsın mı?\n\n(Önerilir)")
        dialog.add_button("Yedeksiz Devam Et", Gtk.ResponseType.NO)
        
        def on_resp(d, r):
            d.destroy()
            should_snapshot = (r == Gtk.ResponseType.YES)
            self.target_action = action
            self.start_transaction(desc, snapshot=should_snapshot)
        dialog.connect("response", on_resp)
        dialog.show()

    # --- Threading ---
    def start_transaction(self, msg, snapshot=False):
        self.log_expander.set_expanded(True)
        self.log_buffer.set_text("")
        self.append_log(msg)
        self.is_processing = True
        self.progress_bar.set_text("İşleniyor...")
        threading.Thread(target=self._worker, args=(snapshot,), daemon=True).start()
        GLib.timeout_add(100, self._update_progress)

    def _worker(self, snapshot=False):
        if snapshot:
            self.append_log("Sistem yedeği alınıyor (timeshift)...")
            if self.installer.create_timeshift_snapshot():
                self.append_log("Yedek başarıyla alındı.")
            else:
                self.append_log("Yedek alınamadı veya iptal edildi.")

        if self.target_action == "optimize_repos":
            self.append_log("Konum algılanıyor ve sunucular optimize ediliyor...")
            self.repo_manager.optimize_sources()
            self.append_log("Resmi Ubuntu depoları (Restricted/Multiverse) açılıyor...")
            self.repo_manager.ensure_standard_repos()
            self.append_log("Paket listesi güncelleniyor (apt update)...")
            subprocess.run(["pkexec", "driver-pilot-root-task", "apt-get update"])
            GLib.idle_add(self._on_finished, True)
            return

        self.append_log("Asıl işlem başlatılıyor...")
        
        # Derin Temizlik Kontrolü
        is_deep = False
        if hasattr(self, "chk_deep_clean"):
            is_deep = self.chk_deep_clean.get_active()

        success = False
        if self.target_action == "remove": 
            success = self.installer.remove_nvidia(deep_clean=is_deep)
        elif self.target_action == "install_nvidia_open": 
            self.repo_manager.ensure_standard_repos() # Standart Repo
            success = self.installer.install_nvidia_open(self.selected_version)
        elif self.target_action == "install_nvidia_closed": 
            self.repo_manager.ensure_standard_repos() # Standart Repo
            success = self.installer.install_nvidia_closed(self.selected_version)
        elif self.target_action == "install_amd_open": 
            self.repo_manager.fix_gamemode_repo() # Update only
            success = self.installer.install_amd_open()
            
        GLib.idle_add(self._on_finished, success)

    def _update_progress(self):
        if self.is_processing: self.progress_bar.pulse(); return True
        return False

    def _on_finished(self, success):
        self.is_processing = False
        self.progress_bar.set_fraction(1.0)
        self.on_scan_clicked(None)
        if success:
             self.progress_bar.set_text("Tamamlandı"); self.append_log("BAŞARILI")
             if "optimize" in str(self.target_action): return # Reboot isteme
             self.show_reboot_dialog()
        else:
             self.progress_bar.set_text("Hata"); self.append_log("HATA")
             self.show_report_dialog("İşlem başarısız oldu.")

    def append_log(self, msg):
        GLib.idle_add(lambda: self.log_buffer.insert(self.log_buffer.get_end_iter(), f"\n> {msg}"))

    # --- Theme & Style ---
    def toggle_theme(self, widget):
        self.dark_mode = not self.dark_mode
        self.apply_theme()

    def apply_theme(self):
        if IsAdwaita:
            style_manager = Adw.StyleManager.get_default()
            if self.dark_mode: style_manager.set_color_scheme(Adw.ColorScheme.FORCE_DARK)
            else: style_manager.set_color_scheme(Adw.ColorScheme.FORCE_LIGHT)
        else:
            settings = Gtk.Settings.get_default()
            if settings: settings.props.gtk_application_prefer_dark_theme = self.dark_mode
        
        icon = "weather-clear-symbolic" if self.dark_mode else "weather-clear-night-symbolic"
        if hasattr(self, "theme_btn"): self.theme_btn.set_icon_name(icon)

    def load_css(self):
        p = Gtk.CssProvider()
        path = os.path.join(os.path.dirname(__file__), "assets", "style.css")
        if not os.path.exists(path): path = "/opt/driver-pilot/src/ui/assets/style.css"
        if os.path.exists(path):
            p.load_from_path(path)
            if IsAdwaita or Gtk.get_major_version() == 4:
                Gtk.StyleContext.add_provider_for_display(Gdk.Display.get_default(), p, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION)
            else:
                Gtk.StyleContext.add_provider_for_screen(Gdk.Screen.get_default(), p, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION)

    # --- Helpers ---
    def get_logo_image(self):
        dev_path = os.path.join(os.path.dirname(os.path.dirname(os.path.dirname(__file__))), "data", "logo.png") 
        prod_path = "/opt/driver-pilot/data/logo.png"
        if os.path.exists(dev_path): return Gtk.Image.new_from_file(dev_path)
        if os.path.exists(prod_path): return Gtk.Image.new_from_file(prod_path)
        return Gtk.Image.new_from_icon_name("video-display")

    # --- Dialogs ---
    def show_about_dialog(self, widget):
        # (Bu kod çok uzun olduğu için ve değişmediği için kısaltıyorum, önceki haliyle aynı)
        win = Gtk.Window(transient_for=self, modal=True); win.set_title("Hakkında"); win.set_default_size(500, 600); win.set_resizable(False)
        main_vbox = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=20); main_vbox.set_margin_top(30); main_vbox.set_margin_bottom(30); main_vbox.set_margin_start(30); main_vbox.set_margin_end(30)
        center_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=10); center_box.set_halign(Gtk.Align.CENTER)
        icon = self.get_logo_image(); icon.set_pixel_size(80); center_box.append(icon)
        lbl_title = Gtk.Label(label=AppConfig.PRETTY_NAME); lbl_title.add_css_class("title-1"); center_box.append(lbl_title)
        lbl_ver = Gtk.Label(label=f"v{AppConfig.VERSION}"); lbl_ver.add_css_class("heading"); center_box.append(lbl_ver)
        main_vbox.append(center_box)
        scroll = Gtk.ScrolledWindow(); scroll.set_min_content_height(250); scroll.set_vexpand(True); changelog_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=10); changelog_box.set_margin_start(10)
        
        # Basit Changelog (Hatamı önlemek için burada yeniden yazıyorum)
        import re
        parts = re.split(r'(v\d+\.\d+\.\d+ Yenilikleri:)', AppConfig.CHANGELOG.strip())
        current_header = None
        for part in parts:
             part = part.strip()
             if not part: continue
             if re.match(r'v\d+\.\d+\.\d+ Yenilikleri:', part): current_header = part.replace(" Yenilikleri:", "")
             elif current_header:
                  e = Gtk.Expander(label=current_header); l = Gtk.Label(label=part); l.set_wrap(True); l.set_xalign(0); e.set_child(l); changelog_box.append(e)
                  if current_header == f"v{AppConfig.VERSION}": e.set_expanded(True)
                  current_header = None
        scroll.set_child(changelog_box); main_vbox.append(scroll)
        win.set_child(main_vbox); win.present()

    def show_error_dialog(self, title, message):
        dialog = Gtk.MessageDialog(transient_for=self, modal=True, message_type=Gtk.MessageType.ERROR, buttons=Gtk.ButtonsType.OK, text=title)
        dialog.format_secondary_text(message)
        dialog.connect("response", lambda d, r: d.destroy())
        dialog.show()

    def show_reboot_dialog(self):
        dialog = Gtk.MessageDialog(transient_for=self, modal=True, message_type=Gtk.MessageType.QUESTION, buttons=Gtk.ButtonsType.YES_NO, text="İşlem Tamamlandı")
        dialog.format_secondary_text("Yeniden başlatılsın mı?")
        def on_resp(d, r):
            d.destroy(); 
            if r == Gtk.ResponseType.YES: subprocess.Popen(["pkexec", "reboot"])
        dialog.connect("response", on_resp)
        dialog.show()

    def show_report_dialog(self, message):
        dialog = Gtk.MessageDialog(transient_for=self, modal=True, message_type=Gtk.MessageType.ERROR, buttons=Gtk.ButtonsType.NONE, text="İşlem Başarısız")
        dialog.format_secondary_text(f"{message}\nRapor gönderilsin mi?")
        dialog.add_button("Kapat", Gtk.ResponseType.CLOSE)
        dialog.add_button("Rapor Gönder", Gtk.ResponseType.YES)
        def on_response(d, rid):
            d.destroy()
            if rid == Gtk.ResponseType.YES: self.send_error_report(message)
        dialog.connect("response", on_response); dialog.show()

    def send_error_report(self, error_msg):
        self.append_log("Raporlanıyor...")
        log_content = self.log_buffer.get_text(self.log_buffer.get_start_iter(), self.log_buffer.get_end_iter(), True)
        try: Gdk.Display.get_default().get_clipboard().set(log_content)
        except: pass
        ErrorReporter.send_report(error_msg, log_content)

# Launcher
class GPUManagerApp(BaseApp):
    def __init__(self):
        super().__init__(application_id="com.sopwith.driverpilot", flags=Gio.ApplicationFlags.NON_UNIQUE)
        self.window = None

    def do_activate(self):
        if not self.window: self.window = MainWindow(self)
        self.window.present()

def start_gui():
    app = GPUManagerApp()
    return app.run(None)