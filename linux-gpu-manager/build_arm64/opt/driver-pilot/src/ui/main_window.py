import gi
import logging
import os
import threading
import subprocess
import datetime
import socket

# GTK4 / GTK3 Uyumluluk
try:
    gi.require_version('Gtk', '4.0')
    gi.require_version('Adw', '1') 
    from gi.repository import Gtk, Gdk, Adw, Gio, GLib, GObject
    BaseApp = Adw.Application
    IsAdwaita = True
except ValueError:
    try:
        gi.require_version('Gtk', '3.0')
        from gi.repository import Gtk, Gdk, Gio, GLib, GObject
        Adw = None 
        BaseApp = Gtk.Application
        IsAdwaita = False
        logging.warning("GTK4/Adwaita bulunamadı, GTK3 fallback.")
    except ValueError:
        raise ImportError("GTK bulunamadı.")

from src.core.installer import DriverInstaller
from src.core.detector import SystemDetector
from src.utils.reporter import ErrorReporter
from src.config import AppConfig

class MainWindow(Gtk.ApplicationWindow):
    def __init__(self, app):
        super().__init__(application=app)
        self.set_title("Display Driver App")
        self.set_default_size(1000, 750)
        self.load_css()

        self.installer = DriverInstaller()
        self.detector = SystemDetector()
        self.available_versions = self.installer.get_available_versions() 
        self.target_action = None
        self.selected_version = None 
        self.is_processing = False

        # --- Header ---
        header_bar = Gtk.HeaderBar()
        self.set_titlebar(header_bar)

        switch_box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=10)
        switch_label = Gtk.Label(label="Uzman Modu")
        self.mode_switch = Gtk.Switch()
        self.mode_switch.connect("state-set", self.on_mode_switch)
        switch_box.append(switch_label)
        switch_box.append(self.mode_switch)
        header_bar.pack_start(switch_box)

        menu_button = Gtk.Button(icon_name="open-menu-symbolic")
        menu_button.connect("clicked", self.show_about_dialog)
        header_bar.pack_end(menu_button)
        
        # --- Main Layout ---
        self.stack = Gtk.Stack()
        self.stack.set_transition_type(Gtk.StackTransitionType.SLIDE_LEFT_RIGHT)
        self.stack.add_named(self.create_simple_view(), "simple")
        self.stack.add_named(self.create_pro_view(), "pro")
        
        main_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=0)
        
        # Secure Boot Banner
        self.sb_banner = Gtk.InfoBar()
        self.sb_banner.set_message_type(Gtk.MessageType.WARNING)
        self.sb_banner.set_show_close_button(True)
        self.sb_banner.set_revealed(False)
        self.sb_banner.connect("response", lambda w, r: self.sb_banner.set_revealed(False))
        content = self.sb_banner.get_content_area() if hasattr(self.sb_banner, "get_content_area") else self.sb_banner
        sb_label = Gtk.Label(label="⚠️ Secure Boot Açık! İmzasız sürücüler çalışmayabilir. BIOS'tan kapatmanız önerilir.")
        if hasattr(content, "append"): content.append(sb_label)
        else: content.add(sb_label); sb_label.show()

        main_box.append(self.sb_banner)
        main_box.append(self.stack)
        main_box.append(self.create_log_area())
        self.set_child(main_box)

        GLib.timeout_add(500, self.run_initial_scan)

    def load_css(self):
        p = Gtk.CssProvider()
        path = os.path.join(os.path.dirname(__file__), "assets", "style.css")
        if os.path.exists(path):
            p.load_from_path(path)
            if IsAdwaita or Gtk.get_major_version() == 4:
                Gtk.StyleContext.add_provider_for_display(Gdk.Display.get_default(), p, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION)
            else:
                Gtk.StyleContext.add_provider_for_screen(Gdk.Screen.get_default(), p, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION)

    def create_simple_view(self):
        vbox = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=20)
        vbox.set_margin_top(40)
        vbox.set_margin_bottom(40)
        vbox.set_margin_start(40)
        vbox.set_margin_end(40)
        vbox.set_valign(Gtk.Align.CENTER)

        # Logo
        title_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=10)
        icon = self.get_logo_image()
        icon.set_pixel_size(96)
        title_box.append(icon)
        self.simple_status_label = Gtk.Label(label="Sistem Taranıyor...")
        self.simple_status_label.set_css_classes(["title-1"])
        title_box.append(self.simple_status_label)
        vbox.append(title_box)

        # Kartlar
        cards = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=30)
        cards.set_homogeneous(True)
        
        self.btn_simple_closed = self.create_card("speedometer-symbolic", "Yüksek Performans\n(Kapalı Kaynak)", 
            "Oyun/3D için en iyisi.\n⚠️ Siyah ekran riski olabilir.", self.on_simple_closed_clicked)
        cards.append(self.btn_simple_closed)

        self.btn_simple_open = self.create_card("security-high-symbolic", "Maksimum Uyum\n(Açık Kaynak)", 
            "Stabil ve güvenli.\nℹ️ Düşük 3D performansı.", self.on_simple_open_clicked)
        cards.append(self.btn_simple_open)
        
        self.btn_simple_reset = self.create_card("system-reboot-symbolic", "Fabrika Ayarları\n(Varsayılan)", 
            "Sürücüleri kaldırır.\nNouveau sürücüsüne döner.", self.on_nouveau_clicked)
        cards.append(self.btn_simple_reset)
        
        vbox.append(cards)
        return vbox

    def create_card(self, icon_name, title, desc, callback):
        btn = Gtk.Button()
        btn.set_css_classes(["card-button"])
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

    def create_pro_view(self):
        box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=20)
        box.set_margin_top(20); box.set_margin_bottom(20); box.set_margin_start(40); box.set_margin_end(40)

        box.append(Gtk.Label(label="Uzman Sürücü Yönetimi", css_classes=["title-1"]))
        self.pro_status_label = Gtk.Label(label="...")
        box.append(self.pro_status_label)

        # Versiyon
        ver_box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=10)
        ver_box.set_halign(Gtk.Align.CENTER)
        ver_box.append(Gtk.Label(label="Versiyon:"))
        self.ver_combo = Gtk.ComboBoxText()
        for v in self.available_versions: self.ver_combo.append(v, f"v{v}")
        self.ver_combo.set_active(0)
        self.ver_combo.connect("changed", self.on_version_changed)
        ver_box.append(self.ver_combo)
        box.append(ver_box)

        # Butonlar
        opts = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=15)
        opts.set_homogeneous(True)
        self.btn_nouveau = Gtk.Button(label="Nouveau (Topluluk)"); self.btn_nouveau.connect("clicked", self.on_nouveau_clicked); opts.append(self.btn_nouveau)
        self.btn_open = Gtk.Button(label="Open Kernel"); self.btn_open.connect("clicked", self.on_open_clicked); opts.append(self.btn_open)
        self.btn_closed = Gtk.Button(label="Proprietary"); self.btn_closed.connect("clicked", self.on_closed_clicked); opts.append(self.btn_closed)
        box.append(opts)

        # Araçlar
        tools = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=10)
        tools.set_halign(Gtk.Align.CENTER)
        btn_scan = Gtk.Button(label="Yeniden Tara"); btn_scan.connect("clicked", self.on_scan_clicked); tools.append(btn_scan)
        btn_test = Gtk.Button(label="Test (Glxgears)"); btn_test.connect("clicked", self.on_test_clicked); tools.append(btn_test)
        box.append(tools)
        return box

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
        box.set_margin_start(20); box.set_margin_end(20); box.set_margin_bottom(20)
        box.append(self.log_expander)
        return box

    # --- Helpers ---
    def get_logo_image(self):
        # 1. Geliştirme Ortamı (Proje kökünde data/)
        dev_path = os.path.join(os.path.dirname(os.path.dirname(os.path.dirname(__file__))), "data", "logo.png")
        # 2. Yüklü Ortam (Opt dizini)
        prod_path = "/opt/display-driver-app/data/logo.png"

        if os.path.exists(dev_path): return Gtk.Image.new_from_file(dev_path)
        if os.path.exists(prod_path): return Gtk.Image.new_from_file(prod_path)
        
        return Gtk.Image.new_from_icon_name("video-display")

    def check_network(self):
        try:
            socket.create_connection(("8.8.8.8", 53), timeout=3)
            return True
        except OSError:
            return False

    def show_error_dialog(self, title, message):
        dialog = Gtk.MessageDialog(transient_for=self, modal=True, message_type=Gtk.MessageType.ERROR, buttons=Gtk.ButtonsType.OK, text=title)
        dialog.format_secondary_text(message)
        dialog.connect("response", lambda d, r: d.destroy())
        dialog.show()

    def show_reboot_dialog(self):
        dialog = Gtk.MessageDialog(transient_for=self, modal=True, message_type=Gtk.MessageType.QUESTION, buttons=Gtk.ButtonsType.YES_NO, text="İşlem Tamamlandı")
        dialog.format_secondary_text("Sürücülerin aktif olması için yeniden başlatmanız gerekiyor.\nŞimdi başlatılsın mı?")
        def on_resp(d, r):
            d.destroy()
            if r == Gtk.ResponseType.YES:
                self.append_log("Yeniden başlatılıyor...")
                subprocess.Popen(["pkexec", "reboot"])
        dialog.connect("response", on_resp)
        dialog.show()

    # --- Handlers ---
    def on_mode_switch(self, s, state):
        self.stack.set_visible_child_name("pro" if state else "simple")

    def on_version_changed(self, c): self.selected_version = c.get_active_id()

    def run_initial_scan(self): self.on_scan_clicked(None); return False

    def on_scan_clicked(self, w):
        info = self.detector.detect()
        ven, mod, drv, sb = info.get("vendor"), info.get("model"), info.get("driver_in_use"), info.get("secure_boot")
        self.current_vendor = ven

        
        self.sb_banner.set_revealed(sb)
        self.simple_status_label.set_label(f"{ven} {mod}")
        self.pro_status_label.set_label(f"{ven} {mod} | {drv} | SB: {sb}")
        
        is_prop = "nvidia" in str(drv) and "open" not in str(drv)
        is_open = "open" in str(drv) or "nouveau" in str(drv)
        
        self.btn_simple_closed.set_sensitive(not is_prop)
        self.btn_simple_open.set_sensitive(not is_open)
        self.btn_simple_reset.set_sensitive(is_prop or is_open) # Sadece özel sürücü varsa aktif olsun
        
        # AMD Kontrolü
        if self.current_vendor == "AMD":
            self.btn_simple_closed.set_sensitive(False)
            self.btn_simple_closed.set_tooltip_text("AMD için kapalı kaynak sürücü kurulumu şu an desteklenmemektedir.")
            self.btn_simple_reset.set_sensitive(True) # AMD için de reset mantıklı olabilir (mesa reinstall)
            
        if is_prop: self.btn_simple_closed.add_css_class("suggested-action")
        else: self.btn_simple_closed.remove_css_class("suggested-action")

    def validate_and_start(self, action, desc):
        if not self.check_network() and action != "remove":
            self.show_error_dialog("İnternet Yok", "Sürücü indirmek için internet bağlantısı gereklidir.")
            return
        self.target_action = action
        self.start_transaction(desc)

    def on_simple_closed_clicked(self, w): 
        if getattr(self, "current_vendor", "NVIDIA") == "AMD":
            self.show_error_dialog("Desteklenmiyor", "AMD Pro sürücüleri henüz bu araçla kurulamamaktadır.")
            return
        self.selected_version = None; self.validate_and_start("install_nvidia_closed", "Kapalı Kaynak Kurulumu...")

    def on_simple_open_clicked(self, w): 
        if getattr(self, "current_vendor", "NVIDIA") == "AMD":
             self.validate_and_start("install_amd_open", "AMD Open (Mesa) Kurulumu...")
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
                with open(dlg.get_file().get_path(), "w") as f:
                    f.write(self.log_buffer.get_text(self.log_buffer.get_start_iter(), self.log_buffer.get_end_iter(), True))
            dlg.destroy()
        d.connect("response", resp); d.show()

    def show_about_dialog(self, w):
        about = Gtk.AboutDialog(program_name=AppConfig.PRETTY_NAME, version=AppConfig.VERSION, authors=["Sopwith"], license_type=Gtk.License.GPL_3_0)
        about.set_transient_for(self); about.present()

    # --- Threading & UI Updates ---
    def start_transaction(self, msg):
        self.log_expander.set_expanded(True)
        self.log_buffer.set_text("")
        self.append_log(msg)
        self.is_processing = True
        self.progress_bar.set_text("İşleniyor...")
        
        for b in [self.btn_simple_closed, self.btn_simple_open, self.btn_simple_reset, self.btn_nouveau, self.btn_open, self.btn_closed]:
            b.set_sensitive(False)
            
        threading.Thread(target=self._worker, daemon=True).start()
        GLib.timeout_add(100, self._update_progress)

    def _worker(self):
        self.append_log("Ortam hazırlanıyor (Yedekleme, Build Tools)...")
        if self.target_action == "remove": success = self.installer.remove_nvidia()
        elif self.target_action == "install_nvidia_open": success = self.installer.install_nvidia_open(self.selected_version)
        elif self.target_action == "install_nvidia_closed": success = self.installer.install_nvidia_closed(self.selected_version)
        elif self.target_action == "install_amd_open": success = self.installer.install_amd_open()
        GLib.idle_add(self._on_finished, success)

    def _update_progress(self):
        if self.is_processing:
            self.progress_bar.pulse()
            return True
        return False

    def _on_finished(self, success):
        self.is_processing = False
        self.on_scan_clicked(None) 
        self.progress_bar.set_fraction(1.0)
        
        if success:
            self.progress_bar.set_text("Tamamlandı")
            self.append_log("✅ İŞLEM BAŞARILI!")
            self.show_reboot_dialog()
        else:
            self.progress_bar.set_text("Hata")
            self.append_log("❌ HATA OLUŞTU.")
            # Hata raporlama diyalogunu göster
            self.show_report_dialog("İşlem sırasında bir hata oluştu.")

    def show_report_dialog(self, message):
        """Kullanıcıya hatayı raporlaması için seçenek sunar."""
        dialog = Gtk.MessageDialog(
            transient_for=self,
            modal=True,
            message_type=Gtk.MessageType.ERROR,
            buttons=Gtk.ButtonsType.NONE, # Özel butonlar ekleyeceğiz
            text="İşlem Başarısız"
        )
        dialog.format_secondary_text(f"{message}\n\nBu hatayı geliştiriciye bildirerek sorunun çözümüne yardımcı olmak ister misiniz? (Sistem bilgileri ve loglar gönderilecektir.)")
        
        dialog.add_button("Kapat", Gtk.ResponseType.CLOSE)
        dialog.add_button("Rapor Gönder", Gtk.ResponseType.YES)
        
        def on_response(d, response_id):
            d.destroy()
            if response_id == Gtk.ResponseType.YES:
                self.send_error_report(message)
        
        dialog.connect("response", on_response)
        dialog.show()

    def send_error_report(self, error_msg):
        """Logları kopyalar ve mail uygulamasını başlatır."""
        self.append_log("Rapor süreci başlatılıyor...")
        
        # 1. Log içeriğini al
        log_content = self.log_buffer.get_text(self.log_buffer.get_start_iter(), self.log_buffer.get_end_iter(), True)
        
        # 2. Panoya (Clipboard) Kopyala
        try:
            clipboard = Gdk.Display.get_default().get_clipboard()
            clipboard.set(log_content)
            self.append_log("📋 Loglar panoya kopyalandı!")
        except Exception as e:
            logging.error(f"Pano hatası: {e}")
            self.append_log("⚠️ Pano kopyalama başarısız oldu.")

        # 3. Mail İstemcisini Aç (Ayrı thread gerekmez, webbrowser hızlıdır)
        success = ErrorReporter.send_report(error_msg, log_content)
        
        if success:
            self.append_log("📧 Mail uygulamanız açıldı.")
            
            # Bilgilendirme Diyaloğu
            info_dialog = Gtk.MessageDialog(
                transient_for=self, modal=True, message_type=Gtk.MessageType.INFO,
                buttons=Gtk.ButtonsType.OK, text="Loglar Kopyalandı"
            )
            info_dialog.format_secondary_text(
                "İşlem logları panoya kopyalandı.\n\n"
                "Lütfen açılan e-posta penceresine sağ tıklayıp 'Yapıştır' (veya CTRL+V) diyerek logları ekleyin ve gönderin."
            )
            info_dialog.connect("response", lambda d, r: d.destroy())
            info_dialog.show()
        else:
            self.append_log("❌ Mail uygulaması açılamadı.")

    def append_log(self, msg):
        GLib.idle_add(lambda: self.log_buffer.insert(self.log_buffer.get_end_iter(), f"\n> {msg}"))

class GPUManagerApp(BaseApp):
    def __init__(self):
        super().__init__(application_id="com.sopwith.DisplayDriverApp", flags=Gio.ApplicationFlags.FLAGS_NONE)
    def do_activate(self):
        MainWindow(self).present()

def start_gui(): GPUManagerApp().run(None)