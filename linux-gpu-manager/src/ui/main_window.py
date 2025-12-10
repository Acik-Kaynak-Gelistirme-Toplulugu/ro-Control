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
from src.utils.translator import Translator
from src.config import AppConfig
from src.ui.performance_view import PerformanceView
from src.ui.progress_controller import ProgressController

class MainWindow(Gtk.ApplicationWindow):
    def __init__(self, app):
        super().__init__(application=app)
        self.set_title(AppConfig.PRETTY_NAME)
        
        # Dinamik Çözünürlük Ayarı
        self.set_resizable(True) # Kullanıcı boyutlandırabilsin
        
        default_w, default_h = 950, 680
        try:
            display = Gdk.Display.get_default()
            monitors = display.get_monitors()
            if monitors and monitors.get_n_items() > 0:
                monitor = monitors.get_item(0) # Birinci monitör
                
                # Full geometry yerine Workarea (Dock vs hariç) bulmaya çalışalım
                # Gtk4'te workarea doğrudan yok, bu yüzden biraz daha korumacı davranıyoruz.
                geometry = monitor.get_geometry()
                
                # Ekranın %50 genişliği, %60 yüksekliği (Daha kompakt)
                scale_w = int(geometry.width * 0.5)
                scale_h = int(geometry.height * 0.6)
                
                # Minimum limitleri düşürdüm
                default_w = max(800, min(scale_w, 1200)) # Min 800px genişlik
                default_h = max(550, min(scale_h, 900))  # Min 550px yükseklik (Dock taşmasını önler)
        except:
            pass # Gdk hatası olursa varsayılan kullanılır
            
        self.set_default_size(default_w, default_h) 
        self.load_css()

        self.target_action = None
        self.selected_version = None 
        self.is_processing = False
        self.theme_mode = "system" # system, dark, light

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
        self.theme_btn.set_icon_name("computer-symbolic")
        self.theme_btn.set_tooltip_text(Translator.tr("tooltip_theme_system"))
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
        from src.core.updater import AppUpdater
        self.updater = AppUpdater()
        
        # Log Callback Bağla
        self.installer.set_logger_callback(lambda msg: self.append_log(msg))
        self.repo_manager.set_logger_callback(lambda msg: self.append_log(msg))
        
        self.available_versions = self.installer.get_available_versions()
        self.gpu_info = self.detector.detect()

        
        main_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL)
        # İçeriği dikey ve yatayda esneyecek şekilde ayarla
        main_box.set_vexpand(True)
        main_box.set_hexpand(True)
        
        # Header Info (Banner)
        self.status_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL)
        self.create_info_bars() 
        self._update_ui_state() 

        main_box.append(self.status_box)
        main_box.append(self.stack) # Stack'i ekle
        
        self.set_child(main_box)

        self.connect("notify::default-width", self._on_window_resize)
        
        # --- Sayfaları Oluştur ve Ekle ---
        self.simple_view = self.create_simple_view()
        self.expert_view = self.create_pro_view()
        self.perf_view = PerformanceView()
        
        # Progress Controller'ı başlat
        self.progress_controller = ProgressController(self, self.stack, self.installer, self.repo_manager, self.updater)
        self.progress_view = self.progress_controller.get_view()

        self.stack.add_titled(self.simple_view, "simple", Translator.tr("tab_install"))
        self.stack.add_named(self.expert_view, "expert") 
        self.stack.add_titled(self.perf_view, "performance", Translator.tr("tab_perf"))
        self.stack.add_named(self.progress_view, "progress") 
        
        # İlk tarama
        GLib.timeout_add(500, self.run_initial_scan)
        
        # Auto Update Check (1 saniye sonra)
        GLib.timeout_add(1000, self._auto_check_updates)
    
    def _auto_check_updates(self):
        """Uygulama ve sürücü güncellemelerini kontrol eder."""
        def run():
            # 1. Uygulama Güncellemesi
            has_up, ver, url, notes = self.updater.check_for_updates()
            if has_up:
                GLib.idle_add(self._show_app_update_notification, ver, url, notes)
            
            # 2. Sürücü Güncellemesi (Sadece NVIDIA ise)
            if "NVIDIA" in self.gpu_info.get("vendor", ""):
                 # Basit bir kontrol: `apt list --upgradable` içinde nvidia-driver kelimesi geçiyor mu?
                 # Bunu yapmak için thread güvenliği ve command runner lazım.
                 # Hızlı bir check için installer'a soralım (şimdilik mock/basit)
                 pass 
                 
        threading.Thread(target=run, daemon=True).start()
        return False # Tek sefer çalışır

    def _show_app_update_notification(self, ver, url, notes):
        """Güncelleme varsa üstte bilgi çubuğu gösterir."""
        info_bar = Gtk.InfoBar()
        info_bar.set_message_type(Gtk.MessageType.INFO)
        info_bar.set_show_close_button(True)
        info_bar.connect("response", lambda w, r: w.hide())
        
        box = info_bar.get_content_area()
        lbl = Gtk.Label(label=f"Yeni Güncelleme Mevcut: v{ver}")
        box.append(lbl)
        
        btn_up = Gtk.Button(label="Şimdi Güncelle")
        btn_up.add_css_class("suggested-action")
        
        def on_update_click(btn):
            info_bar.set_revealed(False)
            self.progress_controller.start_transaction(
                action="self_update",
                desc=f"Uygulama Güncelleniyor (v{ver})...",
                update_url=url
            )
            
        btn_up.connect("clicked", on_update_click)
        info_bar.add_action_widget(btn_up, Gtk.ResponseType.OK)
        
        self.status_box.prepend(info_bar)
        info_bar.set_revealed(True)

        
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
        
        sb_label = Gtk.Label(label=Translator.tr("sb_warning"))
        self.sb_banner.add_child(sb_label)
        
        self.status_box.append(self.sb_banner)

    def create_simple_view(self):
        vbox = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=30)
        vbox.set_margin_top(50); vbox.set_margin_bottom(50)
        vbox.set_margin_start(100); vbox.set_margin_end(100) # Odaklanmış görünüm
        vbox.set_valign(Gtk.Align.CENTER)

        # Başlık ve Logo
        title_box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=20)
        title_box.set_halign(Gtk.Align.CENTER)
        
        icon = self.get_logo_image()
        icon.set_pixel_size(64)
        
        text_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=5)
        text_box.set_valign(Gtk.Align.CENTER)
        lbl_title = Gtk.Label(label="Kurulum Tipini Seçin"); lbl_title.add_css_class("title-1"); lbl_title.set_xalign(0)
        lbl_desc = Gtk.Label(label="Donanımınız için optimize edilmiş seçenekler."); lbl_desc.add_css_class("dim-label"); lbl_desc.set_xalign(0)
        text_box.append(lbl_title); text_box.append(lbl_desc)
        
        title_box.append(icon); title_box.append(text_box)
        vbox.append(title_box)

        # Seçenekler Listesi
        opts_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=15)
        
        # En iyi sürümü belirle
        best_ver = self.available_versions[0] if self.available_versions else "Auto"
        is_amd = "AMD" in self.gpu_info.get("vendor", "")
        
        # Açıklama metni
        # Açıklama metni
        express_title = Translator.tr("express_title")
        if is_amd:
            express_desc = Translator.tr("express_desc_amd")
        else:
            express_desc = Translator.tr("express_desc_nvidia", best_ver)

        # 1. Hızlı Kurulum Butonu
        btn_express = self.create_option_row(
            express_title, express_desc, "emblem-default-symbolic", self.on_express_install_clicked
        )
        opts_box.append(btn_express)
        
        # 2. Özel Kurulum Butonu
        btn_custom = self.create_option_row(
            Translator.tr("custom_title"), 
            Translator.tr("custom_desc"), 
            "preferences-system-symbolic", self.on_custom_install_clicked
        )
        opts_box.append(btn_custom)
        
        vbox.append(opts_box)
        return vbox

    def create_option_row(self, title, desc, icon_name, callback):
        btn = Gtk.Button()
        # CSS ile özelleştirilebilir, şimdilik native buton
        
        row = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=20)
        row.set_margin_top(15); row.set_margin_bottom(15); row.set_margin_start(20); row.set_margin_end(20)
        
        icon = Gtk.Image.new_from_icon_name(icon_name)
        icon.set_pixel_size(48)
        
        text_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=5)
        text_box.set_valign(Gtk.Align.CENTER)
        text_box.set_hexpand(True) 
        
        lbl_t = Gtk.Label(label=title, xalign=0); lbl_t.add_css_class("heading")
        lbl_d = Gtk.Label(label=desc, xalign=0); lbl_d.add_css_class("dim-label"); lbl_d.set_wrap(True); lbl_d.set_max_width_chars(60)
        
        text_box.append(lbl_t); text_box.append(lbl_d)
        
        arrow = Gtk.Image.new_from_icon_name("go-next-symbolic")
        
        row.append(icon); row.append(text_box); row.append(arrow)
        
        btn.set_child(row)
        btn.connect("clicked", callback)
        return btn

    def create_pro_view(self):
        # Modern, Gruplandırılmış Uzman Görünümü
        scroll = Gtk.ScrolledWindow()
        scroll.set_policy(Gtk.PolicyType.NEVER, Gtk.PolicyType.AUTOMATIC)
        
        box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=20)
        box.set_margin_top(40); box.set_margin_bottom(40); box.set_margin_start(100); box.set_margin_end(100)
        
        # Başlık
        header = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=15)
        back_btn = Gtk.Button(icon_name="go-previous-symbolic")
        back_btn.connect("clicked", lambda x: self.stack.set_visible_child_name("simple"))
        header.append(back_btn)

        # Refresh Butonu
        refresh_btn = Gtk.Button(icon_name="view-refresh-symbolic")
        refresh_btn.set_tooltip_text("Donanımı Yeniden Tara")
        refresh_btn.add_css_class("flat") # Şeffaf/Sade görünüm
        refresh_btn.connect("clicked", self.on_scan_clicked)
        header.append(refresh_btn)
        
        lbl = Gtk.Label(label=Translator.tr("expert_header")); lbl.add_css_class("title-1")
        header.append(lbl)
        box.append(header)

        # 1. Konfigürasyon Kartı
        conf_group = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=10)
        conf_lbl = Gtk.Label(label=Translator.tr("expert_conf_title"), xalign=0); conf_lbl.add_css_class("heading")
        conf_group.append(conf_lbl)
        
        conf_card = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=10)
        conf_card.add_css_class("card") # Varsa CSS, yoksa default
        
        # Versiyon Seçimi Satırı
        ver_row = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=10)
        ver_row.set_margin_top(10); ver_row.set_margin_bottom(10); ver_row.set_margin_start(10); ver_row.set_margin_end(10)
        ver_label = Gtk.Label(label=Translator.tr("expert_target_ver"))
        self.ver_combo = Gtk.ComboBoxText()
        for v in self.available_versions: self.ver_combo.append(v, f"NVIDIA v{v}")
        if self.available_versions: self.ver_combo.set_active_id(self.available_versions[0])
        else: self.ver_combo.append("auto", "Otomatik"); self.ver_combo.set_active(0)
        self.ver_combo.connect("changed", self.on_version_changed)
        
        ver_row.append(ver_label)
        ver_row.append(Gtk.Label(label="   ")) # Spacer
        ver_row.append(self.ver_combo)
        conf_card.append(ver_row)
        
        # Checkboxlar
        chk_box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=10)
        chk_box.set_margin_bottom(10); chk_box.set_margin_start(10)
        self.chk_deep_clean = Gtk.CheckButton(label=Translator.tr("expert_deep_clean"))
        self.chk_deep_clean.set_active(True)
        chk_box.append(self.chk_deep_clean)
        conf_card.append(chk_box)
        
        conf_group.append(conf_card)
        box.append(conf_group)

        # 2. İşlemler Listesi
        act_group = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=10)
        act_lbl = Gtk.Label(label=Translator.tr("expert_actions_title"), xalign=0); act_lbl.add_css_class("heading")
        act_group.append(act_lbl)
        
        # Liste Oluşturucu Helper
        def add_action_row(icon, title, desc, callback, action_style=""):
            row = Gtk.Button()
            row.add_css_class("list-button") # Yeni şık stil
            
            row_box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=15)
            row_box.set_margin_top(10); row_box.set_margin_bottom(10); row_box.set_margin_start(15); row_box.set_margin_end(15)
            
            img = Gtk.Image.new_from_icon_name(icon); img.set_pixel_size(28)
            
            txt = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=2)
            txt.set_hexpand(True)
            l1 = Gtk.Label(label=title, xalign=0); l1.add_css_class("heading")
            l2 = Gtk.Label(label=desc, xalign=0); l2.add_css_class("dim-label")
            txt.append(l1); txt.append(l2)
            
            arr = Gtk.Image.new_from_icon_name("go-next-symbolic")
            
            row_box.append(img); row_box.append(txt); row_box.append(arr)
            row.set_child(row_box)
            row.connect("clicked", callback)
            
            # Sadece kritik olanlara renk ver (Destructive gibi)
            if action_style == "destructive-action":
                row.add_css_class("destructive-action")
                row.remove_css_class("list-button") # Kırmızı olacağı için list stilini kaldır
            elif action_style == "suggested-action":
                # Mavi vurgu
                 l1.add_css_class("accent") # Veya custom bir stil
                 # Row'un kendisine suggested-action verirsek çok cırtlak mavi buton olur
                 # Bunun yerine ikon rengiyle vs. oynayabiliriz ama şimdilik list-button kalsın.

            return row
            
        self.btn_closed = add_action_row("speedometer-symbolic", Translator.tr("expert_btn_proprietary"), 
                                         Translator.tr("expert_desc_proprietary"), self.on_closed_clicked, "suggested-action")
        self.btn_open = add_action_row("security-high-symbolic", Translator.tr("expert_btn_open"), 
                                         Translator.tr("expert_desc_open"), self.on_open_clicked)
        self.btn_nouveau = add_action_row("edit-undo-symbolic", Translator.tr("expert_btn_reset"), 
                                          Translator.tr("expert_desc_reset"), self.on_nouveau_clicked, "destructive-action")
                                          
        act_group.append(self.btn_closed)
        act_group.append(self.btn_open)
        act_group.append(self.btn_nouveau)
        
        box.append(act_group)
        
        # Araçlar
        # Header + Info
        tool_header = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=10)
        tool_lbl = Gtk.Label(label=Translator.tr("expert_tools_title"), xalign=0); tool_lbl.add_css_class("heading")
        tool_header.append(tool_lbl)
        
        btn_info_tool = Gtk.Button(icon_name="dialog-information-symbolic")
        btn_info_tool.add_css_class("flat")
        btn_info_tool.connect("clicked", self._show_expert_info)
        tool_header.append(btn_info_tool)
        
        box.append(tool_header)
        
        tools = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=10)
        tools.set_homogeneous(True)
        
        
        btn_repo = Gtk.Button(label="Repo Fix"); btn_repo.connect("clicked", self.on_optimize_clicked)
        # btn_scan artık yukarıda (header) ikon olarak var
        btn_test = Gtk.Button(label="Test (glxgears)"); btn_test.connect("clicked", self.on_test_clicked)
        
        tools.append(btn_repo); tools.append(btn_test)
        box.append(tools)
        
        scroll.set_child(box)
        return scroll

    def _show_expert_info(self, btn):
        title = "Gelişmiş Araçlar Hakkında"
        text = ("Bu menüdeki araçlar sistem bakımını sağlar:\n\n"
                "• Repo Fix (Optimizasyon): İndirme hızını artırmak için 'sources.list' dosyanızı konumunuza en yakın sunucuya yönlendirir ve eksik Ubuntu depolarını (universe/restricted) açar.\n\n"
                "• Yeniden Tara: Donanım değişikliklerini algılamak için sistem taramasını tekrarlar.\n\n"
                "• Test: Ekran kartınızın çalışıp çalışmadığını anlamak için basit bir 3D çark animasyonu (glxgears) açar.")
        
        d = Gtk.MessageDialog(transient_for=self, modal=True, message_type=Gtk.MessageType.INFO, buttons=Gtk.ButtonsType.OK, text=title)
        d.props.secondary_text = text
        d.connect("response", lambda w, r: w.destroy())
        d.present()

    def on_custom_install_clicked(self, btn):
        self.stack.set_visible_child_name("expert")

    def create_progress_view(self):
        """İşlem sırasında gösterilecek odaklanmış ekran."""
        vbox = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=20)
        vbox.set_valign(Gtk.Align.CENTER); vbox.set_halign(Gtk.Align.CENTER)
        vbox.set_margin_top(50); vbox.set_margin_bottom(50)
        vbox.set_margin_start(100); vbox.set_margin_end(100)

        # Animasyon / İkon
        self.spinner = Gtk.Spinner()
        self.spinner.set_size_request(64, 64)
        self.spinner.start()
        vbox.append(self.spinner)
        
        # Durum Metni
        self.lbl_progress_title = Gtk.Label(label=Translator.tr("msg_trans_start")); self.lbl_progress_title.add_css_class("title-1")
        self.lbl_progress_desc = Gtk.Label(label=Translator.tr("msg_processing")); self.lbl_progress_desc.add_css_class("dim-label")
        vbox.append(self.lbl_progress_title)
        vbox.append(self.lbl_progress_desc)
        
        # Log Görüntüleyici (Expander içinde)
        expander = Gtk.Expander(label="Ayrıntıları Göster")
        log_scroll = Gtk.ScrolledWindow()
        log_scroll.set_min_content_height(150)
        log_scroll.set_min_content_width(500)
        
        log_view = Gtk.TextView()
        log_view.set_editable(False)
        log_view.set_monospace(True)
        log_view.set_wrap_mode(Gtk.WrapMode.WORD)
        
        self.log_buffer = log_view.get_buffer()
        log_scroll.set_child(log_view)
        expander.set_child(log_scroll)
        vbox.append(expander)
        
        # Progress Bar
        self.progress_bar = Gtk.ProgressBar()
        self.progress_bar.set_show_text(True)
        self.progress_bar.set_size_request(300, 20) # Added from original
        self.progress_bar.set_pulse_step(0.05) # Added from original
        vbox.append(self.progress_bar)
        
        # Actions Box
        action_box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=10)
        action_box.set_halign(Gtk.Align.CENTER)
        
        self.btn_done = Gtk.Button(label=Translator.tr("btn_close")) # Changed label to original
        self.btn_done.add_css_class("suggested-action")
        self.btn_done.set_visible(False)
        self.btn_done.connect("clicked", lambda x: self.stack.set_visible_child_name("simple")) # Reverted to original lambda
        
        # İptal Butonu (Yeni)
        self.btn_cancel_op = Gtk.Button(label="İşlemi Durdur")
        self.btn_cancel_op.add_css_class("destructive-action") # Kırmızı/Uyarı tonu
        self.btn_cancel_op.connect("clicked", self.on_cancel_op_clicked)
        
        action_box.append(self.btn_done)
        action_box.append(self.btn_cancel_op)
        
        vbox.append(action_box)
        
        return vbox

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

        # Aktif Sürücüye Göre Buton Durumları
        driver = gpu.get('driver_in_use', '').lower()
        is_amd = "amd" in gpu.get('vendor', '').lower()

        # Helper
        def set_btn_state(btn, is_active_for_this_mode):
            if is_active_for_this_mode:
                btn.set_sensitive(False)
                # Label bulup değiştir (Biraz hacky ama çalışır)
                child = btn.get_child() 
                if child and isinstance(child, Gtk.Box):
                    # Box içindeki 2. eleman title
                    lbl = child.get_first_child().get_next_sibling()
                    if isinstance(lbl, Gtk.Label):
                        text = lbl.get_text()
                        if "Kurulu" not in text:
                            lbl.set_text(text + " (Kurulu)")
            else:
                btn.set_sensitive(True)
                # Orijinal metni döndürmek zor, o yüzden reset'te UI yeniden çiziliyor zaten

        if hasattr(self, "btn_simple_closed"):
             is_nvidia_closed = "nvidia" in driver and "nouveau" not in driver
             set_btn_state(self.btn_simple_closed, is_nvidia_closed)

        if hasattr(self, "btn_simple_open"):
             if is_amd:
                 is_amd_open = "amdgpu" in driver or "radeonsi" in driver
                 set_btn_state(self.btn_simple_open, is_amd_open)
             else:
                 # Nvidia Open Kernel
                 is_nvidia_open = "nvidia" in driver and "open" in driver # Basit tespit
                 set_btn_state(self.btn_simple_open, is_nvidia_open)

        # Uzman Modu Butonları
        if hasattr(self, "btn_closed"):
            self.btn_closed.set_sensitive(not ("nvidia" in driver and "nouveau" not in driver))
        if hasattr(self, "btn_open"):
            self.btn_open.set_sensitive(not ("nvidia" in driver and "open" in driver))
        if hasattr(self, "btn_nouveau"):
            self.btn_nouveau.set_sensitive("nouveau" not in driver)

    def on_version_changed(self, combo):
        self.selected_version = combo.get_active_id()

    def on_optimize_clicked(self, w):
        self.progress_controller.start_transaction("optimize_repos", "Repo Optimizasyonu (Konum + PPA)...")

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
        d.connect("response", resp); d.present()


    def ask_eula_confirmation(self):
        """Kullanıcıdan modla EULA onayı alır (Synchronous/Blocking mantığıyla çalışır)."""
        dialog = Gtk.MessageDialog(transient_for=self, modal=True, message_type=Gtk.MessageType.WARNING, buttons=Gtk.ButtonsType.NONE, text=Translator.tr("eula_title"))
        dialog.props.secondary_text = Translator.tr("eula_desc")
        
        btn_ok = dialog.add_button(Translator.tr("btn_accept"), Gtk.ResponseType.OK)
        btn_ok.add_css_class("suggested-action")
        dialog.add_button(Translator.tr("btn_decline"), Gtk.ResponseType.CANCEL)
        
        response = None
        def on_response(d, r):
            nonlocal response
            response = r
            d.destroy()
            
        dialog.connect("response", on_response)
        dialog.present()
        
        # Basit bir event loop ile bekle
        while response is None:
            GLib.MainContext.default().iteration(True)
            
        return response == Gtk.ResponseType.OK

    def validate_and_start(self, action, desc):
        if not self.check_network() and action != "remove":
            self.show_error_dialog("İnternet Yok", "Sürücü indirmek için internet bağlantısı gereklidir.")
            return

        if action == "install_nvidia_closed":
             if not self.ask_eula_confirmation(): return

        if "install" in action or action == "remove":
            if shutil.which("timeshift"):
                self.ask_for_snapshot(action, desc)
                return

        self.progress_controller.start_transaction(action, desc, version=self.selected_version)

    def ask_for_snapshot(self, action, desc):
        dialog = Gtk.MessageDialog(transient_for=self, modal=True, message_type=Gtk.MessageType.QUESTION, buttons=Gtk.ButtonsType.YES_NO, text="Sistem Yedeği")
        dialog.props.secondary_text = "İşleme başlamadan önce Timeshift ile sistem yedeği (snapshot) alınsın mı?\n\n(Önerilir)"
        dialog.add_button("Yedeksiz Devam Et", Gtk.ResponseType.NO)
        
        def on_resp(d, r):
            d.destroy()
            should_snapshot = (r == Gtk.ResponseType.YES)
            self.progress_controller.start_transaction(action, desc, version=self.selected_version, snapshot=should_snapshot)
        dialog.connect("response", on_resp)
        dialog.present()

    def append_log(self, msg):
        self.progress_controller.append_log(msg)

    # --- Theme & Style ---
    def toggle_theme(self, widget):
        # Döngü: System -> Dark -> Light -> System
        if self.theme_mode == "system":
            self.theme_mode = "dark"
        elif self.theme_mode == "dark":
            self.theme_mode = "light"
        else:
            self.theme_mode = "system"
        self.apply_theme()

    def apply_theme(self):
        # İkon ve Tooltip
        icon_name = "computer-symbolic"
        tooltip = Translator.tr("tooltip_theme_system")
        
        if self.theme_mode == "dark":
            icon_name = "weather-clear-night-symbolic"
            tooltip = Translator.tr("tooltip_theme_dark")
        elif self.theme_mode == "light":
            icon_name = "weather-clear-symbolic"
            tooltip = Translator.tr("tooltip_theme_light")

        if hasattr(self, "theme_btn"): 
            self.theme_btn.set_icon_name(icon_name)
            self.theme_btn.set_tooltip_text(tooltip)

        # Temayı Uygula
        if IsAdwaita:
            style_manager = Adw.StyleManager.get_default()
            if self.theme_mode == "system":
                style_manager.set_color_scheme(Adw.ColorScheme.DEFAULT)
            elif self.theme_mode == "dark":
                style_manager.set_color_scheme(Adw.ColorScheme.FORCE_DARK)
            else:
                style_manager.set_color_scheme(Adw.ColorScheme.FORCE_LIGHT)
        else:
            settings = Gtk.Settings.get_default()
            if settings: 
                # Standart GTK'da 'system' demek aslında tercihi 0 yapmaktır
                if self.theme_mode == "dark":
                    settings.props.gtk_application_prefer_dark_theme = True
                elif self.theme_mode == "light":
                    settings.props.gtk_application_prefer_dark_theme = False
                else:
                    settings.props.gtk_application_prefer_dark_theme = False # Varsayılan davranış

    def load_css(self):
        p = Gtk.CssProvider()
        path = os.path.join(os.path.dirname(__file__), "assets", "style.css")
        if not os.path.exists(path): path = "/opt/ro-control/src/ui/assets/style.css"
        if os.path.exists(path):
            p.load_from_path(path)
            if IsAdwaita or Gtk.get_major_version() == 4:
                Gtk.StyleContext.add_provider_for_display(Gdk.Display.get_default(), p, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION)
            else:
                Gtk.StyleContext.add_provider_for_screen(Gdk.Screen.get_default(), p, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION)

    # --- Helpers ---
    def get_logo_image(self):
        dev_path = os.path.join(os.path.dirname(os.path.dirname(os.path.dirname(__file__))), "data", "logo.png") 
        prod_path = "/opt/ro-control/data/logo.png"
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
        
        # Version Box (Label + Update Check)
        ver_box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=5)
        lbl_ver = Gtk.Label(label=f"v{AppConfig.VERSION}"); lbl_ver.add_css_class("heading")
        ver_box.append(lbl_ver)
        
        # Küçük güncelleme butonu (Eğer repo varsa)
        if hasattr(AppConfig, "GITHUB_REPO") and AppConfig.GITHUB_REPO:
             btn_upd = Gtk.Button(icon_name="system-software-update-symbolic")
             btn_upd.add_css_class("flat"); btn_upd.set_tooltip_text("Güncellemeleri Kontrol Et")
             btn_upd.connect("clicked", lambda x: self.on_check_update_clicked(x, lbl_ver))
             ver_box.append(btn_upd)
             
        center_box.append(ver_box)
        main_vbox.append(center_box)
        scroll = Gtk.ScrolledWindow(); scroll.set_min_content_height(250); scroll.set_vexpand(True); changelog_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=10); changelog_box.set_margin_start(10)
        
        # Basit Changelog (Hatamı önlemek için burada yeniden yazıyorum)
        # Basit Changelog (Hatamı önlemek için burada yeniden yazıyorum)
        import re
        # Regex: vX.X.X (veya vX.X.X Alpha/Beta) Yenilikleri:
        # Gruplama parantezi önemli ()
        parts = re.split(r'(v\d+\.\d+\.\d+(?: \(.*\))? Yenilikleri:)', AppConfig.CHANGELOG.strip())
        
        current_header = None
        for part in parts:
             part = part.strip()
             if not part: continue
             
             # Başlık mı?
             if "Yenilikleri:" in part: 
                 current_header = part.replace(" Yenilikleri:", "")
             elif current_header:
                  e = Gtk.Expander(label=current_header)
                  # Label padding
                  l = Gtk.Label(label=part)
                  l.set_wrap(True)
                  l.set_xalign(0)
                  l.set_margin_start(10); l.set_margin_bottom(10)
                  e.set_child(l)
                  
                  changelog_box.append(e)
                  
                  # En son sürümü varsayılan olarak açık yap
                  # (Basit kontrol: Versiyon numarasını içeriyorsa)
                  if AppConfig.VERSION in current_header:
                       e.set_expanded(True)
                  
                  current_header = None
        scroll.set_child(changelog_box); main_vbox.append(scroll)
        
        # Contact Button
        btn_contain = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL)
        btn_contain.set_halign(Gtk.Align.CENTER)
        
        btn_contact = Gtk.Button(label="Geliştirici İle İletişime Geç")
        btn_contact.set_icon_name("mail-message-new-symbolic")
        btn_contact.add_css_class("suggested-action")
        btn_contact.connect("clicked", lambda x: ErrorReporter.send_feedback())
        
        btn_contain.append(btn_contact)
        main_vbox.append(btn_contain)
        
        win.set_child(main_vbox); win.present()

    def on_check_update_clicked(self, btn, lbl_ver):
        btn.set_sensitive(False)
        lbl_ver.set_text(f"v{AppConfig.VERSION} (Kontrol ediliyor...)")
        
        def check_thread():
            has_update, new_ver, url, notes = self.updater.check_for_updates()
            GLib.idle_add(self._on_update_checked, btn, lbl_ver, has_update, new_ver, url, notes)
            
        threading.Thread(target=check_thread, daemon=True).start()
        
    def _on_update_checked(self, btn, lbl_ver, has_update, new_ver, url, notes):
        btn.set_sensitive(True)
        if not has_update:
            lbl_ver.set_text(f"v{AppConfig.VERSION} (Güncel)")
            # Basit bir bilgi mesajı
            d = Gtk.MessageDialog(transient_for=self.get_root(), modal=True, message_type=Gtk.MessageType.INFO, buttons=Gtk.ButtonsType.OK, text="Sistem Güncel")
            d.props.secondary_text = f"Mevcut sürüm (v{AppConfig.VERSION}) en son sürüm."
            d.connect("response", lambda w, r: w.destroy())
            d.present()
        else:
            lbl_ver.set_text(f"v{AppConfig.VERSION} -> v{new_ver}")
            # Güncelleme Onay Diyaloğu
            self._show_update_dialog(new_ver, notes, url)

    def _auto_check_updates(self):
        """Uygulama açılışında otomatik güncelleme kontrolü."""
        def check_thread():
             has_update, new_ver, url, notes = self.updater.check_for_updates()
             GLib.idle_add(self._on_auto_update_checked, has_update, new_ver, url, notes)
        threading.Thread(target=check_thread, daemon=True).start()
        return False # One-time
    
    def _on_auto_update_checked(self, has_update, new_ver, url, notes):
        if not has_update:
            # Güncel ise sessizce loga yaz veya banner'a yaz
            self.append_log(f"Sürüm kontrolü: Sistem güncel (v{AppConfig.VERSION})")
            
            # Status Bar'a küçük bir ikon/text eklenebilir
            # self.status_box içine... (İsteğe bağlı, şimdilik log yeterli)
        else:
            self.append_log(f"YENİ GÜNCELLEME TESPİT EDİLDİ: v{new_ver}")
            # Banner göster
            self._show_update_banner(new_ver, url, notes)

    def _show_update_banner(self, new_ver, url, notes):
        """Header'da görünür bir güncelleme uyarısı oluşturur."""
        infobar = Gtk.InfoBar(message_type=Gtk.MessageType.WARNING)
        infobar.set_show_close_button(True)
        
        # İçerik
        content = infobar.get_child() 
        box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=10)
        
        lbl = Gtk.Label(label=f"<b>Yeni Güncelleme Mevcut: v{new_ver}</b>", use_markup=True)
        btn = Gtk.Button(label="İncele ve Yükle")
        btn.connect("clicked", lambda x: self._show_update_dialog(new_ver, notes, url))
        
        box.append(lbl)
        box.append(btn)
        content.append(box)
        
        infobar.connect("response", lambda w, r: w.set_revealed(False))
        infobar.set_revealed(True)
        
        # En sora değil en başa ekle (Status Box'ın başına)
        self.status_box.prepend(infobar)

    def _show_update_dialog(self, new_ver, notes, url):
        d = Gtk.MessageDialog(transient_for=self.get_root(), modal=True, message_type=Gtk.MessageType.QUESTION, buttons=Gtk.ButtonsType.OK_CANCEL, text="Güncelleme Mevcut")
        d.props.secondary_text = f"Yeni sürüm (v{new_ver}) indirilebilir.\n\nDeğişiklikler:\n{notes}\n\nŞimdi yüklemek ister misiniz?"
        
        # OK = Yükle
        d.set_response_appearance(Gtk.ResponseType.OK, "suggested-action")
        
        def on_resp(w, r):
            w.destroy()
            if r == Gtk.ResponseType.OK:
                self._start_update_process(url, new_ver)
                
        d.connect("response", on_resp)
        d.present()

    def _start_update_process(self, url, new_ver):
        # UI Progress Moduna Geçsin
        self.start_transaction("Uygulama Güncelleniyor...")
        
        def run_update():
            success = self.updater.download_and_install(url, lambda msg: self.append_log(msg))
            GLib.idle_add(self._on_finished, success)
            if success:
                 GLib.idle_add(self.append_log, "Güncelleme tamamlandı! Lütfen uygulamayı yeniden başlatın.")
                 
        threading.Thread(target=run_update, daemon=True).start()

    def on_express_install_clicked(self, btn):
        # 1. Sürücü Tipi Seçimi (Open vs Closed)
        # Kullanıcıya sor: Açık Kaynak mı Kapalı Kaynak mı?
        
        # Dialog Creation
        dialog = Gtk.Dialog(title=Translator.tr("express_title"), transient_for=self, modal=True)
        dialog.add_button(Translator.tr("btn_close"), Gtk.ResponseType.CANCEL)
        
        # Content Area
        content_area = dialog.get_content_area()
        content_area.set_spacing(20); content_area.set_margin_top(20); content_area.set_margin_bottom(20); content_area.set_margin_start(20); content_area.set_margin_end(20)
        
        lbl = Gtk.Label(label=Translator.tr("dialog_type_desc")); lbl.add_css_class("title-2")
        content_area.append(lbl)
        
        # Buttons Box
        btn_box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=20)
        btn_box.set_halign(Gtk.Align.CENTER)
        
        # Open Source Button
        btn_open = Gtk.Button()
        b_box_o = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=5)
        b_box_o.set_margin_top(10); b_box_o.set_margin_bottom(10); b_box_o.set_margin_start(10); b_box_o.set_margin_end(10)
        l1 = Gtk.Label(label=Translator.tr("type_open"), xalign=0.5); l1.add_css_class("heading")
        l2 = Gtk.Label(label=Translator.tr("type_open_desc"), xalign=0.5); l2.add_css_class("dim-label")
        b_box_o.append(l1); b_box_o.append(l2)
        btn_open.set_child(b_box_o)
        
        # Closed Source Button
        btn_closed = Gtk.Button()
        b_box_c = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=5)
        b_box_c.set_margin_top(10); b_box_c.set_margin_bottom(10); b_box_c.set_margin_start(10); b_box_c.set_margin_end(10)
        l3 = Gtk.Label(label=Translator.tr("type_closed"), xalign=0.5); l3.add_css_class("heading")
        l4 = Gtk.Label(label=Translator.tr("type_closed_desc"), xalign=0.5); l4.add_css_class("dim-label")
        b_box_c.append(l3); b_box_c.append(l4)
        btn_closed.set_child(b_box_c)
        btn_closed.add_css_class("suggested-action")
        
        btn_box.append(btn_open)
        btn_box.append(btn_closed)
        content_area.append(btn_box)
        
        # Logic Helpers
        is_amd = "AMD" in self.gpu_info.get("vendor", "")
        best_ver = self.available_versions[0] if self.available_versions else "Auto"
        
        # Dialog Response (Kapat butonu için)
        dialog.connect("response", lambda d, r: d.destroy())

        def on_open_clicked(x):
            dialog.destroy()
            if is_amd:
                # AMD -> Open (Mesa)
                self.validate_and_start("install_amd_open", Translator.tr("msg_trans_start"))
            else:
                # NVIDIA -> Open
                self.selected_version = best_ver
                self.validate_and_start("install_nvidia_open", Translator.tr("msg_trans_start"))
                
        def on_closed_clicked(x):
            dialog.destroy()
            if is_amd:
                # AMD -> Closed (Pro) warning
                self.show_error_dialog(Translator.tr("err_amd_pro_title"), Translator.tr("err_amd_pro_desc"))
            else:
                # NVIDIA -> Closed
                self.selected_version = best_ver
                self.validate_and_start("install_nvidia_closed", Translator.tr("msg_trans_start"))

        btn_open.connect("clicked", on_open_clicked)
        btn_closed.connect("clicked", on_closed_clicked)
        
        dialog.present()

    def on_test_clicked(self, w):
        if shutil.which("glxgears"):
            # Varsa direkt çalıştır
            try:
                subprocess.Popen(["glxgears"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
                d = Gtk.MessageDialog(transient_for=self, modal=True, message_type=Gtk.MessageType.INFO, buttons=Gtk.ButtonsType.OK, text="Test Başlatıldı")
                d.props.secondary_text = "3D çarklar penceresi açıldıysa ekran kartınız çalışıyor demektir."
                d.connect("response", lambda w,r: w.destroy())
                d.present()
            except Exception as e:
                self.show_error_dialog("Hata", f"Test başlatılamadı: {e}")
        else:
            # Yoksa Kur (Manuel Dialog)
            dialog = Gtk.Dialog(title="Test Aracı Kuruluyor", transient_for=self, modal=True)
            dialog.set_deletable(False)
            box = dialog.get_content_area()
            box.set_spacing(15); box.set_margin_top(20); box.set_margin_bottom(20); box.set_margin_start(20); box.set_margin_end(20)
            
            hbox = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=10)
            hbox.set_halign(Gtk.Align.CENTER)
            spinner = Gtk.Spinner(); spinner.start()
            lbl = Gtk.Label(label="mesa-utils paketi yükleniyor...")
            hbox.append(spinner); hbox.append(lbl)
            box.append(hbox)
            
            def install_thread():
                cmd = 'pkexec ro-control-root-task "apt-get install -y mesa-utils"'
                from src.utils.command_runner import CommandRunner
                runner = CommandRunner()
                code, out, err = runner.run_full(cmd)
                GLib.idle_add(on_install_done, code, err)

            def on_install_done(code, err):
                dialog.destroy()
                if code == 0:
                   self.append_log("mesa-utils başarıyla kuruldu.")
                   # Tekrar tetikle
                   self.on_test_clicked(w)
                else:
                   self.show_error_dialog("Kurulum Hatası", f"Test aracı kurulamadı: {err}")

            dialog.present()
            threading.Thread(target=install_thread, daemon=True).start()

    def on_scan_clicked(self, w):
        self.gpu_info = self.detector.detect(force_refresh=True)
        self._update_ui_state()
        
        # Kullanıcıya başarı mesajı
        d = Gtk.MessageDialog(transient_for=self, modal=True, message_type=Gtk.MessageType.INFO, buttons=Gtk.ButtonsType.OK, text="Tarama Tamamlandı")
        d.props.secondary_text = f"Donanım değişiklikleri için sistem yeniden tarandı.\nTespit edilen: {self.gpu_info.get('vendor')} {self.gpu_info.get('model')}"
        d.connect("response", lambda w,r: w.destroy())
        d.present()

    def _on_window_resize(self, *args):
        """Pencere boyutuna göre responsive sınıfları uygular."""
        width = self.get_default_size().width
        # Eğer pencere maximize edilmişse veya manuel büyütülmüşse
        # get_width() daha doğru olabilir ama GTK4'te surface üzerinden alınır.
        
        # Basit yaklaşım: Varsayılan boyutu kontrol et, eğer küçükse compact yap.
        # Daha doğrusu: allocation width
        alloc_width = self.get_width()
        
        if alloc_width < 800:
            self.add_css_class("compact")
            self.remove_css_class("wide")
        elif alloc_width > 1200:
            self.add_css_class("wide")
            self.remove_css_class("compact")
        else:
            self.remove_css_class("compact")
            self.remove_css_class("wide")

    def show_error_dialog(self, title, message):
        dialog = Gtk.MessageDialog(transient_for=self, modal=True, message_type=Gtk.MessageType.ERROR, buttons=Gtk.ButtonsType.OK, text=title)
        dialog.props.secondary_text = message
        dialog.connect("response", lambda d, r: d.destroy())
        dialog.present()

    def show_reboot_dialog(self):
        dialog = Gtk.MessageDialog(transient_for=self, modal=True, message_type=Gtk.MessageType.QUESTION, buttons=Gtk.ButtonsType.YES_NO, text="İşlem Tamamlandı")
        dialog.props.secondary_text = "Yeniden başlatılsın mı?"
        def on_resp(d, r):
            d.destroy(); 
            if r == Gtk.ResponseType.YES: subprocess.Popen(["pkexec", "reboot"])
        dialog.connect("response", on_resp)
        dialog.present()

    def show_report_dialog(self, message):
        dialog = Gtk.MessageDialog(transient_for=self, modal=True, message_type=Gtk.MessageType.ERROR, buttons=Gtk.ButtonsType.NONE, text="İşlem Başarısız")
        dialog.props.secondary_text = f"{message}\nRapor gönderilsin mi?"
        dialog.add_button("Kapat", Gtk.ResponseType.CLOSE)
        dialog.add_button("Rapor Gönder", Gtk.ResponseType.YES)
        def on_response(d, rid):
            d.destroy()
            if rid == Gtk.ResponseType.YES: self.send_error_report(message)
        dialog.connect("response", on_response); dialog.present()

    def send_error_report(self, error_msg):
        self.append_log("Raporlanıyor...")
        log_content = self.log_buffer.get_text(self.log_buffer.get_start_iter(), self.log_buffer.get_end_iter(), True)
        try: Gdk.Display.get_default().get_clipboard().set(log_content)
        except: pass
        ErrorReporter.send_report(error_msg, log_content)

# Launcher
class GPUManagerApp(BaseApp):
    def __init__(self):
        super().__init__(application_id="com.sopwith.rocontrol", flags=Gio.ApplicationFlags.NON_UNIQUE)
        self.window = None

    def do_activate(self):
        if not self.window: self.window = MainWindow(self)
        self.window.present()

def start_gui():
    app = GPUManagerApp()
    return app.run(None)