import gi
import threading
import datetime
import logging
import shutil

try:
    gi.require_version('Gtk', '4.0')
    from gi.repository import Gtk, GLib
except:
    from gi.repository import Gtk, GLib

from src.utils.translator import Translator

class ProgressController:
    def __init__(self, main_window, stack, installer, repo_manager, updater):
        self.main_window = main_window
        self.stack = stack
        self.installer = installer
        self.repo_manager = repo_manager
        self.updater = updater
        self.logger = logging.getLogger("ProgressController")
        
        # State
        self.is_processing = False
        self.cancel_requested = False
        self.start_time = None
        self.target_action = None
        self.selected_version = None
        self.update_url = None
        self.chk_deep_clean = None # Optional reference
        
        # UI Elements
        self.view_box = self._create_view()
        
    def _create_view(self):
        vbox = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=20)
        vbox.set_valign(Gtk.Align.CENTER); vbox.set_halign(Gtk.Align.CENTER)
        vbox.set_margin_top(50); vbox.set_margin_bottom(50)
        vbox.set_margin_start(100); vbox.set_margin_end(100)

        # Spinner
        self.spinner = Gtk.Spinner()
        self.spinner.set_size_request(64, 64)
        vbox.append(self.spinner)
        
        # Labels
        self.lbl_title = Gtk.Label(label="İşlem Başlıyor..."); self.lbl_title.add_css_class("title-2")
        self.lbl_desc = Gtk.Label(label="..."); self.lbl_desc.add_css_class("body")
        vbox.append(self.lbl_title)
        vbox.append(self.lbl_desc)
        
        # Log View
        expander = Gtk.Expander(label="Ayrıntıları Göster")
        log_scroll = Gtk.ScrolledWindow()
        log_scroll.set_min_content_height(150); log_scroll.set_min_content_width(500)
        
        log_view = Gtk.TextView(); log_view.set_editable(False); log_view.set_monospace(True); log_view.set_wrap_mode(Gtk.WrapMode.WORD)
        self.log_buffer = log_view.get_buffer()
        log_scroll.set_child(log_view)
        expander.set_child(log_scroll)
        self.log_expander = expander
        vbox.append(expander)
        
        # Progress Bar
        self.progress_bar = Gtk.ProgressBar()
        self.progress_bar.set_show_text(True)
        self.progress_bar.set_size_request(300, 20)
        vbox.append(self.progress_bar)
        
        # Actions
        action_box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=10)
        action_box.set_halign(Gtk.Align.CENTER)
        
        self.btn_done = Gtk.Button(label=Translator.tr("btn_close"))
        self.btn_done.add_css_class("suggested-action")
        self.btn_done.set_visible(False)
        self.btn_done.connect("clicked", self.on_done_clicked)
        
        self.btn_cancel = Gtk.Button(label="İşlemi Durdur")
        self.btn_cancel.add_css_class("destructive-action")
        self.btn_cancel.connect("clicked", self.on_cancel_clicked)
        
        action_box.append(self.btn_done)
        action_box.append(self.btn_cancel)
        vbox.append(action_box)
        
        return vbox

    def get_view(self):
        return self.view_box

    def start_transaction(self, action, desc, version=None, update_url=None, snapshot=False):
        self.target_action = action
        self.selected_version = version
        self.update_url = update_url
        
        # UI Reset
        self.stack.set_visible_child_name("progress")
        self.btn_done.set_visible(False)
        self.btn_cancel.set_visible(True)
        self.btn_cancel.set_sensitive(True)
        self.spinner.start()
        
        self.lbl_title.set_text("İşlem Başlatılıyor")
        self.lbl_desc.set_text(desc)
        self.log_buffer.set_text("")
        self.append_log(desc)
        
        self.is_processing = True
        self.cancel_requested = False
        self.start_time = datetime.datetime.now()
        
        self.progress_bar.set_text("İşleniyor... (00:00)")
        self.progress_bar.set_fraction(0.0)
        
        threading.Thread(target=self._worker, args=(snapshot,), daemon=True).start()
        GLib.timeout_add(100, self._update_progress)

    def _update_progress(self):
        if not self.is_processing: return False
        self.spinner.spin()
        
        elapsed = datetime.datetime.now() - self.start_time
        mins, secs = divmod(elapsed.seconds, 60)
        
        fraction = self.progress_bar.get_fraction()
        pct = int(fraction * 100)
        self.progress_bar.set_text(f"%{pct} Tamamlandı - Geçen Süre: {mins:02}:{secs:02}")
        return True

    def _check_cancel(self):
        if self.cancel_requested:
            self.append_log("\n!!! İPTAL EDİLDİ !!!")
            raise InterruptedError("Cancelled")

    def on_cancel_clicked(self, btn):
        # Onay Dialog
        d = Gtk.MessageDialog(transient_for=self.main_window, modal=True, message_type=Gtk.MessageType.WARNING, buttons=Gtk.ButtonsType.YES_NO, text="İşlemi İptal Et")
        d.props.secondary_text = "İşlemi durdurmak sistemi kararsız bırakabilir. Emin misiniz?"
        
        def resp(dlg, r):
            dlg.destroy()
            if r == Gtk.ResponseType.YES:
                self.cancel_requested = True
                self.append_log("İptal isteniyor...")
                btn.set_sensitive(False)
        d.connect("response", resp)
        d.present()

    def on_done_clicked(self, btn):
        # Ana ekrana dön
        self.stack.set_visible_child_name("simple")

    def append_log(self, msg):
        GLib.idle_add(lambda: self.log_buffer.insert(self.log_buffer.get_end_iter(), f"\n> {msg}"))

    def _worker(self, snapshot=False):
        success = False
        try:
            self._check_cancel()
            if snapshot:
                self.append_log("Snapshot alınıyor...")
                if self.installer.create_timeshift_snapshot(): self.append_log("Yedek alındı.")
                else: self.append_log("Yedek alınamadı/atlandı.")
            
            self._check_cancel()
            
            # --- ACTION DISPATCHER ---
            if self.target_action == "optimize_repos":
                self._do_optimize()
                success = True
            elif self.target_action == "self_update":
                success = self._do_self_update()
            elif self.target_action == "remove":
                # Deep clean check
                is_deep = False
                if self.chk_deep_clean and self.chk_deep_clean.get_active(): is_deep = True
                success = self.installer.remove_nvidia(deep_clean=is_deep)
            elif self.target_action == "install_nvidia_open":
                ver = self.selected_version if self.selected_version else 535
                success = self.installer.install_nvidia_open_kernel(ver)
            elif self.target_action == "install_nvidia_closed":
                ver = self.selected_version if self.selected_version else 535
                success = self.installer.install_nvidia_proprietary(ver)
            elif "amd" in self.target_action:
                success = self.installer.install_amd_open()
            
            self.progress_bar.set_fraction(1.0)
            
        except InterruptedError:
            success = False
            GLib.idle_add(lambda: self.lbl_desc.set_text("İptal Edildi"))
            self.append_log("\nİşlem iptal edildi.")
        except Exception as e:
            success = False
            self.logger.error(f"Worker Hata: {e}")
            self.append_log(f"HATA: {e}")
            
        finally:
            self.is_processing = False
            GLib.idle_add(self._on_finished, success)

    def _do_optimize(self):
        self.progress_bar.set_fraction(0.1)
        self.append_log("Konum algılanıyor...")
        self._check_cancel()
        if not self.repo_manager.optimize_sources(): self.append_log("Optimizasyon uyarısı.")
        self.progress_bar.set_fraction(0.5)
        self.append_log("Depolar güncelleniyor...")
        self.repo_manager.ensure_standard_repos()
        self.repo_manager.update_repos()
        self.append_log("Tamamlandı.")

    def _do_self_update(self):
        self.append_log("İndiriliyor...")
        def cb(msg): GLib.idle_add(lambda: self.append_log(msg))
        res = self.updater.download_and_install(self.update_url, progress_callback=cb)
        if res: self.append_log("Güncellendi."); return True
        else: self.append_log("Güncelleme hatası."); return False

    def _on_finished(self, success):
        self.spinner.stop()
        self.btn_done.set_visible(True)
        self.btn_cancel.set_visible(False)
        
        if success:
            self.lbl_title.set_text("Tamamlandı")
            self.progress_bar.set_text("Başarılı")
            
            # Reboot gerektirmeyenler
            if "optimize" in str(self.target_action) or "self" in str(self.target_action):
                return
                
            # Reboot Dialog
            self.main_window.show_reboot_dialog()
        else:
            self.lbl_title.set_text("Hata Oluştu")
            self.progress_bar.set_text("Başarısız")
            self.log_expander.set_expanded(True)

