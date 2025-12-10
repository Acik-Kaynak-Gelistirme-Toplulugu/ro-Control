from gi.repository import Gtk, GLib, Gdk
from src.core.tweaks import SystemTweaks
from src.core.detector import SystemDetector
from src.utils.translator import Translator
import threading
import time
import logging

class PerformanceView(Gtk.Box):
    def __init__(self):
        super().__init__(orientation=Gtk.Orientation.VERTICAL, spacing=20)
        self.logger = logging.getLogger("PerformanceView")
        self.set_margin_top(20)
        self.set_margin_bottom(20)
        self.set_margin_start(20)
        self.set_margin_end(20)
        
        self.tweaks = SystemTweaks()
        self.detector = SystemDetector()
        
        self._build_sys_info()
        self._build_dashboard()
        self._build_controls()
        self._build_tools()
        
        # Dashboard güncelleme zamanlayıcısı (Her 2 saniyede bir)
        GLib.timeout_add(2000, self._update_stats)

    def _build_sys_info(self):
        frame = Gtk.Frame(label=Translator.tr("sys_info_title"))
        grid = Gtk.Grid()
        grid.set_column_spacing(20); grid.set_row_spacing(10)
        grid.set_margin_top(15); grid.set_margin_bottom(15); grid.set_margin_start(15); grid.set_margin_end(15)

        info = self.detector.get_full_system_info()
        
        # Labels
        self.lbl_val_os = Gtk.Label(label=info.get("distro", "Linux"), xalign=0)
        self.lbl_val_kernel = Gtk.Label(label=info.get("kernel", "Unknown"), xalign=0)
        self.lbl_val_cpu = Gtk.Label(label=info.get("cpu", "Unknown"), xalign=0)
        self.lbl_val_ram = Gtk.Label(label=info.get("ram", "Unknown"), xalign=0)
        self.lbl_val_gpu = Gtk.Label(label=f"{info.get('vendor')} {info.get('model')}", xalign=0)

        # Helper to add rows
        def add_row(idx, label, val_widget, icon):
            img = Gtk.Image.new_from_icon_name(icon)
            lbl_t = Gtk.Label(label=label, xalign=0); lbl_t.add_css_class("heading")
            grid.attach(img, 0, idx, 1, 1)
            grid.attach(lbl_t, 1, idx, 1, 1)
            grid.attach(val_widget, 2, idx, 1, 1)

        add_row(0, Translator.tr("lbl_os"), self.lbl_val_os, "applications-system-symbolic")
        add_row(1, Translator.tr("lbl_kernel"), self.lbl_val_kernel, "preferences-system-symbolic")
        add_row(2, Translator.tr("lbl_cpu"), self.lbl_val_cpu, "computer-chip-symbolic")
        add_row(3, Translator.tr("lbl_ram"), self.lbl_val_ram, "media-flash-symbolic")
        add_row(4, Translator.tr("lbl_gpu"), self.lbl_val_gpu, "video-display-symbolic")
        
        # Display Server
        self.lbl_val_ds = Gtk.Label(label=info.get("display_server", "Unknown"), xalign=0)
        add_row(5, Translator.tr("lbl_display"), self.lbl_val_ds, "preferences-desktop-display-symbolic")

        frame.set_child(grid)
        self.append(frame)

    def _refresh_full_info(self):
        """Tüm bilgileri (Statik + Dinamik) yeniler."""
        # 1. Statik Sistem Bilgisi (RAM, vb.)
        # Dedektör önbelleğini temizle (varsa) ve yeniden oku
        self.detector.detect(force_refresh=True) 
        info = self.detector.get_full_system_info()
        
        self.lbl_val_os.set_text(info.get("distro", "Linux"))
        self.lbl_val_kernel.set_text(info.get("kernel", "Unknown"))
        self.lbl_val_cpu.set_text(info.get("cpu", "Unknown"))
        self.lbl_val_ram.set_text(info.get("ram", "Unknown"))
        self.lbl_val_gpu.set_text(f"{info.get('vendor')} {info.get('model')}")
        self.lbl_val_ds.set_text(info.get("display_server", "Unknown"))
        
        # 2. Canlı İstatistikler
        self._update_stats()

    def _build_dashboard(self):
        # Container Box
        container = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=20)
        container.set_margin_top(15); container.set_margin_bottom(15); container.set_margin_start(15); container.set_margin_end(15)

        # Header with Refresh
        header_box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL)
        header_box.set_halign(Gtk.Align.END)
        btn_refresh = Gtk.Button()
        btn_refresh.set_icon_name("view-refresh-symbolic")
        btn_refresh.set_tooltip_text("Şimdi Yenile")
        btn_refresh.connect("clicked", lambda x: self._refresh_full_info())
        header_box.append(btn_refresh)
        container.append(header_box)

        # --- 1. GPU Paneli ---
        frame_gpu = Gtk.Frame(label=Translator.tr("dash_gpu_title"))
        gpu_box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=20)
        gpu_box.set_margin_top(15); gpu_box.set_margin_bottom(15); gpu_box.set_margin_start(10); gpu_box.set_margin_end(10)

        # GPU Temp
        vbox_gt = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=5)
        self.lbl_temp = Gtk.Label(label=f"{Translator.tr('lbl_temp')}: --°C")
        self.bar_temp = Gtk.ProgressBar()
        vbox_gt.append(self.lbl_temp); vbox_gt.append(self.bar_temp)
        
        # GPU Load
        vbox_gl = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=5)
        self.lbl_load = Gtk.Label(label=f"{Translator.tr('lbl_load')}: --%")
        self.bar_load = Gtk.ProgressBar()
        vbox_gl.append(self.lbl_load); vbox_gl.append(self.bar_load)
        
        # VRAM
        vbox_gm = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=5)
        self.lbl_mem = Gtk.Label(label=f"{Translator.tr('lbl_mem')}: -- / -- MB")
        self.bar_mem = Gtk.ProgressBar()
        vbox_gm.append(self.lbl_mem); vbox_gm.append(self.bar_mem)
        
        vbox_gt.set_hexpand(True); vbox_gl.set_hexpand(True); vbox_gm.set_hexpand(True)
        gpu_box.append(vbox_gt); gpu_box.append(vbox_gl); gpu_box.append(vbox_gm)
        frame_gpu.set_child(gpu_box)
        container.append(frame_gpu)

        # --- 2. Sistem Paneli (CPU/RAM) ---
        frame_sys = Gtk.Frame(label=Translator.tr("dash_sys_title"))
        sys_box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=20)
        sys_box.set_margin_top(15); sys_box.set_margin_bottom(15); sys_box.set_margin_start(10); sys_box.set_margin_end(10)

        # CPU Temp
        vbox_ct = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=5)
        self.lbl_cpu_temp = Gtk.Label(label=f"{Translator.tr('lbl_cpu_temp')}: --°C")
        self.bar_cpu_temp = Gtk.ProgressBar()
        vbox_ct.append(self.lbl_cpu_temp); vbox_ct.append(self.bar_cpu_temp)

        # CPU Load
        vbox_cl = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=5)
        self.lbl_cpu_load = Gtk.Label(label=f"{Translator.tr('lbl_cpu_load')}: --%")
        self.bar_cpu_load = Gtk.ProgressBar()
        vbox_cl.append(self.lbl_cpu_load); vbox_cl.append(self.bar_cpu_load)

        # RAM Usage
        vbox_rm = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=5)
        self.lbl_ram = Gtk.Label(label=f"{Translator.tr('lbl_ram')}: -- / -- MB")
        self.bar_ram = Gtk.ProgressBar()
        vbox_rm.append(self.lbl_ram); vbox_rm.append(self.bar_ram)

        vbox_ct.set_hexpand(True); vbox_cl.set_hexpand(True); vbox_rm.set_hexpand(True)
        sys_box.append(vbox_ct); sys_box.append(vbox_cl); sys_box.append(vbox_rm)
        frame_sys.set_child(sys_box)
        container.append(frame_sys)

        self.append(container)

    def _build_controls(self):
        frame = Gtk.Frame(label=Translator.tr("ctrl_title"))
        
        # Ana kutu (Dikey: Üstte kontroller, altta uyarı)
        main_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=10)
        main_box.set_margin_top(15); main_box.set_margin_bottom(15)
        main_box.set_margin_start(15); main_box.set_margin_end(15)
        
        # Kontrol Satırı (Yatay)
        ctrl_box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=10)
        
        lbl = Gtk.Label(label=Translator.tr("ctrl_mode_select"))
        
        # Combo
        self.combo_prime = Gtk.ComboBoxText()
        self.combo_prime.append("nvidia", Translator.tr("mode_perf"))
        self.combo_prime.append("intel", Translator.tr("mode_save"))
        self.combo_prime.append("on-demand", Translator.tr("mode_balanced"))
        
        # Mevcut modu seçmeye çalış (ve sakla)
        self.active_mode = self.tweaks.get_prime_profile()
        if self.active_mode in ["nvidia", "intel", "on-demand"]:
            self.combo_prime.set_active_id(self.active_mode)
        else:
            self.combo_prime.set_active_id("on-demand")
            
        btn_apply = Gtk.Button(label=Translator.tr("btn_apply"))
        btn_apply.add_css_class("suggested-action")
        btn_apply.connect("clicked", self._on_prime_apply)
        
        # Yeniden Başlatma Uyarısı (İkon + Tooltip)
        self.restart_icon = Gtk.Image.new_from_icon_name("system-reboot-symbolic")
        self.restart_icon.set_tooltip_text("Değişikliklerin uygulanması için yeniden başlatma gerekli!")
        self.restart_icon.add_css_class("warning") # Veya custom style
        self.restart_icon.set_visible(False) # Başlangıçta gizli

        # Combo değiştikçe kontrol et
        self.combo_prime.connect("changed", self._check_restart_needed)
        
        ctrl_box.append(lbl)
        ctrl_box.append(self.combo_prime)
        ctrl_box.append(self.restart_icon) # Combo ile Buton arasına ekle
        ctrl_box.append(btn_apply)
        
        main_box.append(ctrl_box)

        # Destek Kontrolü
        if not self.tweaks.is_prime_supported():
            # Devre dışı bırak
            self.combo_prime.set_sensitive(False)
            btn_apply.set_sensitive(False)
            
            # Uyarı Ekle
            warn_box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=10)
            warn_icon = Gtk.Image.new_from_icon_name("dialog-warning-symbolic")
            warn_lbl = Gtk.Label(label=Translator.tr("msg_prime_unsupported"))
            warn_lbl.add_css_class("dim-label") # Silik yazı stili
            
            warn_box.append(warn_icon)
            warn_box.append(warn_lbl)
            main_box.append(warn_box)
        
        frame.set_child(main_box)
        self.append(frame)

    def _build_tools(self):
        frame = Gtk.Frame(label=Translator.tr("tools_title"))
        grid = Gtk.Grid()
        grid.set_column_spacing(20)
        grid.set_row_spacing(15)
        grid.set_margin_top(15); grid.set_margin_bottom(15)
        grid.set_margin_start(15); grid.set_margin_end(15)
        
        # --- GameMode ---
        # Label Box
        box_gm = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=5)
        lbl_game = Gtk.Label(label=Translator.tr("tool_gamemode"))
        lbl_game.set_halign(Gtk.Align.START)
        btn_info_gm = Gtk.Button(icon_name="dialog-information-symbolic")
        btn_info_gm.add_css_class("flat") # Buton çerçevesini gizle
        btn_info_gm.set_tooltip_text("GameMode Nedir?")
        btn_info_gm.connect("clicked", lambda x: self._show_info("gamemode"))
        box_gm.append(lbl_game)
        box_gm.append(btn_info_gm)
        box_gm.set_halign(Gtk.Align.START) # Kutuyu sola yasla
        
        self.switch_game = Gtk.Switch()
        self.switch_game.set_active(self.tweaks.is_gamemode_active())
        self.switch_game.set_halign(Gtk.Align.END) # Switch sağa yaslansın
        self.switch_game.connect("state-set", self._on_gamemode_toggle)
        
        # --- Flatpak Fix ---
        box_fp = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=5)
        lbl_flat = Gtk.Label(label=Translator.tr("tool_flatpak"))
        lbl_flat.set_halign(Gtk.Align.START)
        btn_info_fp = Gtk.Button(icon_name="dialog-information-symbolic")
        btn_info_fp.add_css_class("flat")
        btn_info_fp.set_tooltip_text("Ne İşe Yarar?")
        btn_info_fp.connect("clicked", lambda x: self._show_info("flatpak"))
        box_fp.append(lbl_flat)
        box_fp.append(btn_info_fp)
        box_fp.set_halign(Gtk.Align.START)
        
        btn_flat = Gtk.Button(label=Translator.tr("btn_repair"))
        btn_flat.set_halign(Gtk.Align.END) # Buton sağa yaslansın
        btn_flat.connect("clicked", self._on_flatpak_fix)
        
        grid.attach(box_gm, 0, 0, 1, 1)
        grid.attach(self.switch_game, 1, 0, 1, 1)
        
        grid.attach(box_fp, 0, 1, 1, 1)
        grid.attach(btn_flat, 1, 1, 1, 1)

        # 3. NVIDIA Wayland Fix (Eğer NVIDIA ise)
        if self.tweaks.is_nvidia or True:
            # Sol taraf (Label + Info)
            box_nv_label = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=5)
            lbl_nv = Gtk.Label(label="NVIDIA Wayland Fix")
            btn_nv_info = Gtk.Button(icon_name="dialog-information-symbolic")
            btn_nv_info.add_css_class("flat")
            btn_nv_info.connect("clicked", lambda x: self._show_info("nv_fix"))
            
            box_nv_label.append(lbl_nv)
            box_nv_label.append(btn_nv_info)
            box_nv_label.set_halign(Gtk.Align.START)

            # Sağ taraf (Buton)
            btn_nv = Gtk.Button(label="Uygula")
            btn_nv.add_css_class("suggested-action")
            btn_nv.set_halign(Gtk.Align.END)
            btn_nv.connect("clicked", self._on_nv_fix)
            
            grid.attach(box_nv_label, 0, 2, 1, 1)
            grid.attach(btn_nv, 1, 2, 1, 1)
            
        # Grid'in ikinci sütununu (Butonların olduğu sütun) genişletelim ki sağa yaslansınlar
        grid.set_column_homogeneous(False)
        # 1. sütun (widgets) genişlesin (hexpand)
        # Ama GtkGrid'de bu biraz trick gerektirir. Basitçe widgetlara hexpand verelim.
        box_gm.set_hexpand(True)
        box_fp.set_hexpand(True)
        if 'box_nv_label' in locals(): box_nv_label.set_hexpand(True)
        
        frame.set_child(grid)
        self.append(frame)

    def _show_info(self, key):
        title = ""
        text = ""
        
        if key == "gamemode":
            title = "GameMode Hakkında"
            text = ("Feral GameMode, Linux'ta oyun performansını artırmak için geliştirilmiş bir araçtır.\n\n"
                    "- İşlemciyi (CPU) 'Performans' moduna alır.\n"
                    "- Arka plan işlemlerinin önceliğini düşürür.\n"
                    "- Oyunların daha akıcı (yüksek FPS) çalışmasını sağlar.\n\n"
                    "Bu anahtarı açtığınızda sisteminize otomatik olarak kurulur ve yapılandırılır.")
        elif key == "flatpak":
            title = "Flatpak Onarımı"
            text = ("Eğer Steam veya oyunları Flatpak üzerinden kurduysanız, bazen sürücüye erişim sorunları yaşanabilir.\n\n"
                    "Bu araç şunları yapar:\n"
                    "1. Bozuk izinleri (permission) sıfırlar.\n"
                    "2. Eksik NVIDIA Runtime kütüphanelerini tamamlar.\n"
                    "3. Oyunların açılmama sorununu çözer.\n\n"
                    "Sisteminizde bir sorun yoksa çalıştırmanıza gerek yoktur.")
        elif key == "nv_fix":
            title = "NVIDIA Wayland Düzeltmesi"
            text = ("NVIDIA kartların Wayland masaüstü ortamında (GNOME/KDE) daha akıcı çalışması için Kernel parametresi ekler.\n\n"
                    "Yapılan işlem:\n"
                    "- /etc/default/grub dosyasına 'nvidia-drm.modeset=1' ekler.\n"
                    "- GRUB önyükleyicisini günceller.\n\n"
                    "Eğer masaüstünde takılmalar veya senkronizasyon sorunu yaşıyorsanız bunu uygulayın.")

        dialog = Gtk.MessageDialog(transient_for=self.get_root(), modal=True, message_type=Gtk.MessageType.INFO, buttons=Gtk.ButtonsType.OK, text=title)
        dialog.props.secondary_text = text
        dialog.connect("response", lambda d, r: d.destroy())
        dialog.present()

    def _update_stats(self):
        # UI Thread'i dondurmamak için veriyi arka planda çek
        if not self.get_root(): return False

        def fetch_data():
            gpu = self.tweaks.get_gpu_stats()
            sys = self.tweaks.get_system_stats()
            GLib.idle_add(self._apply_stats, gpu, sys)

        threading.Thread(target=fetch_data, daemon=True).start()
        return True # Timer devam etsin

    def _apply_stats(self, gpu_stats, sys_stats):
        # Bu metod UI thread içinde çalışır (Güvenli)
        if not self.get_root(): return # Pencere kapanmış olabilir

        # Helper
        def set_color(bar, val):
            # Önce temizle
            bar.remove_css_class("p-green"); bar.remove_css_class("p-yellow"); bar.remove_css_class("p-red")
            if val < 60: bar.add_css_class("p-green")
            elif val < 85: bar.add_css_class("p-yellow")
            else: bar.add_css_class("p-red")

        # --- GPU ---
        t = gpu_stats.get('temp', 0)
        self.lbl_temp.set_text(f"{Translator.tr('lbl_temp')}: {t}°C")
        self.bar_temp.set_fraction(min(t / 100.0, 1.0)); set_color(self.bar_temp, t)
        
        l = gpu_stats.get('load', 0)
        self.lbl_load.set_text(f"{Translator.tr('lbl_load')}: {l}%")
        self.bar_load.set_fraction(min(l / 100.0, 1.0)); set_color(self.bar_load, l)
        
        u = gpu_stats.get('mem_used', 0)
        tot = gpu_stats.get('mem_total', 1) 
        if tot == 0: tot = 1
        ratio = (u / tot) * 100
        self.lbl_mem.set_text(f"{Translator.tr('lbl_mem')}: {u} / {tot} MB")
        self.bar_mem.set_fraction(min(u / tot, 1.0)); set_color(self.bar_mem, ratio)

        # --- System ---
        ct = sys_stats.get('cpu_temp', 0)
        text_ct = f"{Translator.tr('lbl_cpu_temp')}: {ct}°C" if ct > 0 else f"{Translator.tr('lbl_cpu_temp')}: --"
        self.lbl_cpu_temp.set_text(text_ct)
        self.bar_cpu_temp.set_fraction(min(ct / 100.0, 1.0)); set_color(self.bar_cpu_temp, ct)

        cl = sys_stats.get('cpu_load', 0)
        self.lbl_cpu_load.set_text(f"{Translator.tr('lbl_cpu_load')}: {cl}%")
        self.bar_cpu_load.set_fraction(min(cl / 100.0, 1.0)); set_color(self.bar_cpu_load, cl)

        ru = sys_stats.get('ram_used', 0)
        rt = sys_stats.get('ram_total', 1)
        rp = sys_stats.get('ram_percent', 0)
        self.lbl_ram.set_text(f"{Translator.tr('lbl_ram')}: {ru} / {rt} MB")
        self.bar_ram.set_fraction(min(rp / 100.0, 1.0)); set_color(self.bar_ram, rp)

    def _on_prime_apply(self, btn):
        mode = self.combo_prime.get_active_id()
        if mode:
            self.logger.info(f"Prime profil uygulanıyor: {mode}")
            # Thread içinde çalıştır
            def run():
                btn.set_sensitive(False)
                btn.set_label("Uygulanıyor...")
                self.tweaks.set_prime_profile(mode)
                GLib.idle_add(lambda: btn.set_label("Uygula (Reboot Gerekir)"))
                GLib.idle_add(lambda: btn.set_sensitive(True))
            threading.Thread(target=run, daemon=True).start()

    def _check_restart_needed(self, combo):
        """Seçilen mod aktif moddan farklıysa uyarı ikonunu göster."""
        selected = combo.get_active_id()
        if selected != self.active_mode:
            self.restart_icon.set_visible(True)
        else:
            self.restart_icon.set_visible(False)


    def _on_gamemode_toggle(self, switch, state):
        if state and not self.tweaks.is_gamemode_active():
             # Kurulum gerekli
             self.logger.info("GameMode kuruluyor...")
             def run():
                 # Switch'i geçici olarak disable et
                 GLib.idle_add(lambda: switch.set_sensitive(False))
                 success, msg = self.tweaks.install_gamemode()
                 GLib.idle_add(lambda: switch.set_sensitive(True))
                 
                 if not success:
                     # Geri al
                     GLib.idle_add(lambda: switch.set_active(False))
                     GLib.idle_add(lambda: self._show_dialog("Hata", msg, Gtk.MessageType.ERROR))
                 else:
                     self.logger.info("GameMode kuruldu")
                     GLib.idle_add(lambda: self._show_dialog("Başarılı", msg, Gtk.MessageType.INFO))
                     
             threading.Thread(target=run, daemon=True).start()
        return True

    def _on_flatpak_fix(self, btn):
        self.logger.info("Flatpak onarılıyor...")
        def run():
            GLib.idle_add(lambda: btn.set_sensitive(False))
            GLib.idle_add(lambda: btn.set_label("Onarılıyor..."))
            
            success, msg = self.tweaks.repair_flatpak_permissions()
            
            GLib.idle_add(lambda: btn.set_sensitive(True))
            GLib.idle_add(lambda: btn.set_label("Onar"))
            
            if success:
                 GLib.idle_add(lambda: self._show_dialog("Onarım Tamamlandı", msg, Gtk.MessageType.INFO))
            else:
                 GLib.idle_add(lambda: self._show_dialog("Onarım Hatası", msg, Gtk.MessageType.ERROR))
                
        threading.Thread(target=run, daemon=True).start()

    def _on_nv_fix(self, btn):
        self.logger.info("NVIDIA Wayland Fix başlatılıyor...")
        def run():
            GLib.idle_add(lambda: btn.set_sensitive(False))
            GLib.idle_add(lambda: btn.set_label("Uygulanıyor..."))
            
            success, msg = self.tweaks.enable_nvidia_wayland_fix()
            
            GLib.idle_add(lambda: btn.set_sensitive(True))
            GLib.idle_add(lambda: btn.set_label("Uygula"))
            
            if success:
                 GLib.idle_add(lambda: self._show_dialog("Başarılı", msg, Gtk.MessageType.INFO))
            else:
                 GLib.idle_add(lambda: self._show_dialog("Hata", msg, Gtk.MessageType.ERROR))
                
        threading.Thread(target=run, daemon=True).start()

    def _show_dialog(self, title, text, msg_type):
        """Yardımcı metod: Thread içinden güvenli dialog gösterir."""
        if not self.get_root(): return
        d = Gtk.MessageDialog(transient_for=self.get_root(), modal=True, message_type=msg_type, buttons=Gtk.ButtonsType.OK, text=title)
        d.props.secondary_text = text
        d.connect("response", lambda w,r: w.destroy())
        d.present()
