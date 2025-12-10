from gi.repository import Gtk, GLib, Gdk
from src.core.tweaks import SystemTweaks
import threading
import time

class PerformanceView(Gtk.Box):
    def __init__(self):
        super().__init__(orientation=Gtk.Orientation.VERTICAL, spacing=20)
        self.set_margin_top(20)
        self.set_margin_bottom(20)
        self.set_margin_start(20)
        self.set_margin_end(20)
        
        self.tweaks = SystemTweaks()
        
        self._build_dashboard()
        self._build_controls()
        self._build_tools()
        
        # Dashboard güncelleme zamanlayıcısı (Her 2 saniyede bir)
        GLib.timeout_add(2000, self._update_stats)

    def _build_dashboard(self):
        frame = Gtk.Frame(label="Canlı GPU Durumu")
        box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=20)
        box.set_margin_top(15); box.set_margin_bottom(15); box.set_margin_start(15); box.set_margin_end(15)
        
        # Temp
        vbox1 = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=5)
        self.lbl_temp = Gtk.Label(label="Sıcaklık: --°C")
        self.bar_temp = Gtk.ProgressBar()
        vbox1.append(self.lbl_temp); vbox1.append(self.bar_temp)
        
        # Load
        vbox2 = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=5)
        self.lbl_load = Gtk.Label(label="Yük: --%")
        self.bar_load = Gtk.ProgressBar()
        vbox2.append(self.lbl_load); vbox2.append(self.bar_load)
        
        # VRAM
        vbox3 = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=5)
        self.lbl_mem = Gtk.Label(label="Bellek: -- / -- MB")
        self.bar_mem = Gtk.ProgressBar()
        vbox3.append(self.lbl_mem); vbox3.append(self.bar_mem)
        
        # Eşit dağılım
        vbox1.set_hexpand(True); vbox2.set_hexpand(True); vbox3.set_hexpand(True)
        box.append(vbox1); box.append(vbox2); box.append(vbox3)
        frame.set_child(box)
        self.append(frame)

    def _build_controls(self):
        frame = Gtk.Frame(label="Grafik Modu (Laptop)")
        box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=10)
        box.set_margin_top(15); box.set_margin_bottom(15)
        box.set_margin_start(15); box.set_margin_end(15)
        
        lbl = Gtk.Label(label="Mod Seçin:")
        
        # Combo
        self.combo_prime = Gtk.ComboBoxText()
        self.combo_prime.append("nvidia", "Performans (NVIDIA)")
        self.combo_prime.append("intel", "Güç Tasarrufu (Intel)")
        self.combo_prime.append("on-demand", "Dengeli (On-Demand)")
        # Mevcut modu seçmeye çalış
        current = self.tweaks.get_prime_profile()
        if current in ["nvidia", "intel", "on-demand"]:
            self.combo_prime.set_active_id(current)
        else:
            self.combo_prime.set_active_id("on-demand") # Varsayılan
            
        btn_apply = Gtk.Button(label="Uygula (Reboot Gerekir)")
        btn_apply.add_css_class("suggested-action")
        btn_apply.connect("clicked", self._on_prime_apply)
        
        box.append(lbl)
        box.append(self.combo_prime)
        box.append(btn_apply)
        frame.set_child(box)
        self.append(frame)

    def _build_tools(self):
        frame = Gtk.Frame(label="Araçlar ve Optimizasyon")
        grid = Gtk.Grid()
        grid.set_column_spacing(20)
        grid.set_row_spacing(15)
        grid.set_margin_top(15); grid.set_margin_bottom(15)
        grid.set_margin_start(15); grid.set_margin_end(15)
        
        # GameMode
        lbl_game = Gtk.Label(label="Oyun Modu (Feral GameMode):")
        lbl_game.set_halign(Gtk.Align.START)
        
        self.switch_game = Gtk.Switch()
        self.switch_game.set_active(self.tweaks.is_gamemode_active())
        self.switch_game.connect("state-set", self._on_gamemode_toggle)
        
        # Flatpak Fix
        lbl_flat = Gtk.Label(label="Flatpak/Steam İzin Onarıcı:")
        lbl_flat.set_halign(Gtk.Align.START)
        
        btn_flat = Gtk.Button(label="Onar")
        btn_flat.connect("clicked", self._on_flatpak_fix)
        
        grid.attach(lbl_game, 0, 0, 1, 1)
        grid.attach(self.switch_game, 1, 0, 1, 1)
        
        grid.attach(lbl_flat, 0, 1, 1, 1)
        grid.attach(btn_flat, 1, 1, 1, 1)
        
        frame.set_child(grid)
        self.append(frame)

    def _update_stats(self):
        # UI Thread'i dondurmamak için veriyi arka planda çek
        if not self.get_root(): return False

        def fetch_data():
            stats = self.tweaks.get_gpu_stats()
            GLib.idle_add(self._apply_stats, stats)

        threading.Thread(target=fetch_data, daemon=True).start()
        return True # Timer devam etsin

    def _apply_stats(self, stats):
        # Bu metod UI thread içinde çalışır (Güvenli)
        if not self.get_root(): return # Pencere kapanmış olabilir

        # Helper
        def set_color(bar, val):
            # Önce temizle
            bar.remove_css_class("p-green"); bar.remove_css_class("p-yellow"); bar.remove_css_class("p-red")
            if val < 60: bar.add_css_class("p-green")
            elif val < 85: bar.add_css_class("p-yellow")
            else: bar.add_css_class("p-red")

        # Temp
        t = stats.get('temp', 0)
        self.lbl_temp.set_text(f"Sıcaklık: {t}°C")
        self.bar_temp.set_fraction(min(t / 100.0, 1.0))
        set_color(self.bar_temp, t)
        
        # Load
        l = stats.get('load', 0)
        self.lbl_load.set_text(f"Yük: {l}%")
        self.bar_load.set_fraction(min(l / 100.0, 1.0))
        set_color(self.bar_load, l)
        
        # Mem
        u = stats.get('mem_used', 0)
        tot = stats.get('mem_total', 1) 
        if tot == 0: tot = 1
        
        ratio = (u / tot) * 100
        self.lbl_mem.set_text(f"Bellek (VRAM/RAM): {u} / {tot} MB")
        self.bar_mem.set_fraction(min(u / tot, 1.0))
        set_color(self.bar_mem, ratio)

    def _on_prime_apply(self, btn):
        mode = self.combo_prime.get_active_id()
        if mode:
            print(f"DEBUG: Prime profil uygulanıyor: {mode}")
            # Thread içinde çalıştır
            def run():
                btn.set_sensitive(False)
                btn.set_label("Uygulanıyor...")
                self.tweaks.set_prime_profile(mode)
                GLib.idle_add(lambda: btn.set_label("Uygula (Reboot Gerekir)"))
                GLib.idle_add(lambda: btn.set_sensitive(True))
            threading.Thread(target=run, daemon=True).start()

    def _on_gamemode_toggle(self, switch, state):
        if state and not self.tweaks.is_gamemode_active():
             # Kurulum gerekli
             print("DEBUG: GameMode kuruluyor...")
             def run():
                 # Switch'i geçici olarak disable et
                 GLib.idle_add(lambda: switch.set_sensitive(False))
                 success = self.tweaks.install_gamemode()
                 GLib.idle_add(lambda: switch.set_sensitive(True))
                 if not success:
                     # Geri al
                     GLib.idle_add(lambda: switch.set_active(False))
                     print("DEBUG: GameMode kurulumu başarısız")
                 else:
                     print("DEBUG: GameMode kuruldu")
             threading.Thread(target=run, daemon=True).start()
        return True

    def _on_flatpak_fix(self, btn):
        print("DEBUG: Flatpak onarılıyor...")
        def run():
            btn.set_sensitive(False)
            btn.set_label("Onarılıyor...")
            success = self.tweaks.repair_flatpak_permissions()
            GLib.idle_add(lambda: btn.set_sensitive(True))
            if success:
                GLib.idle_add(lambda: btn.set_label("Tamamlandı"))
                # Bir süre sonra eski haline dön
                GLib.timeout_add(3000, lambda: btn.set_label("Onar"))
            else:
                GLib.idle_add(lambda: btn.set_label("Hata!"))
                GLib.timeout_add(3000, lambda: btn.set_label("Onar"))
                
        threading.Thread(target=run, daemon=True).start()
