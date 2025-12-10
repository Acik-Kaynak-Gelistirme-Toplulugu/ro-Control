import locale
import gettext
import os

class Translator:
    # Basit bir sözlük tabanlı çeviri (gettext kurulumu gerektirmez, taşınabilir)
    # Eğer sistem locale TR ise Türkçe, değilse İngilizce.
    
    DICTIONARY = {
        "tr": {
            # --- Main Window ---
            "title_main": "Kurulum Tipini Seçin",
            "desc_main": "Donanımınız için optimize edilmiş seçenekler.",
            "tab_install": "Kurulum",
            "tab_expert": "Uzman",
            "tab_perf": "Performans",
            
            "express_title": "Hızlı Kurulum (Önerilen)",
            "express_desc_nvidia": "En güncel kararlı NVIDIA v{} sürücüsünü otomatik kurar.",
            "express_desc_amd": "En güncel AMD Mesa sürücülerini otomatik kurar.",
            "custom_title": "Özel Kurulum (Uzman)",
            "custom_desc": "Sürüm, kernel tipi ve temizlik ayarlarını manuel yapılandırın.",
            
            "dialog_express_title": "Hızlı Kurulum Onayı",
            "dialog_express_desc_nvidia": "Sisteminiz için en uygun NVIDIA Proprietary (v{}) sürücüsü seçildi.\n\nBu işlem oyunlar ve profesyonel uygulamalar için en yüksek performansı sağlar.\nDevam etmek istiyor musunuz?",
            "dialog_express_desc_amd": "Sisteminiz için en uygun AMD (Mesa) açık kaynak sürücüleri kurulacak.\nDevam etmek istiyor musunuz?",
            
            "btn_dev_contact": "Geliştirici İle İletişime Geç",
            "btn_backup": "Yedeksiz Devam Et",
            "btn_close": "Kapat",
            "btn_report": "Rapor Gönder",
            
            "status_active_driver": "Aktif Sürücü: {} | Secure Boot: {}",
            "sb_warning": "⚠️ Secure Boot Açık! İmzasız sürücüler çalışmayabilir. BIOS'tan kapatmanız önerilir.",
            "err_no_internet": "İnternet Yok",
            "err_no_internet_desc": "Sürücü indirmek için internet bağlantısı gereklidir.",
            
            "msg_trans_start": "İşlem Başlatılıyor",
            "msg_processing": "Lütfen bekleyin, sistem yapılandırılıyor...",
            "msg_success_title": "İşlem Başarıyla Tamamlandı",
            "msg_success_desc": "Logları kontrol edebilir veya ana menüye dönebilirsiniz.",
            "msg_error_title": "İşlem Sırasında Hata Oluştu",
            "msg_error_desc": "Lütfen aşağıdaki detayları inceleyin.",
            
            "expert_header": "Uzman Sürücü Yönetimi",
            "expert_conf_title": "Kurulum Ayarları",
            "expert_target_ver": "Hedef Sürücü Sürümü:",
            "expert_deep_clean": "Derin Temizlik (Önceki yapılandırmaları sil)",
            "expert_actions_title": "İşlemler",
            "expert_btn_proprietary": "Proprietary Sürücüyü Kur",
            "expert_desc_proprietary": "Seçili versiyonu (Kapalı Kaynak) kurar.",
            "expert_btn_open": "Open Kernel Sürücüyü Kur",
            "expert_desc_open": "Seçili versiyonu (Açık Kaynak Modüllü) kurar.",
            "expert_btn_reset": "Sürücüleri Kaldır ve Sıfırla",
            "expert_desc_reset": "Sistemi varsayılan Nouveau sürücüsüne döndürür.",
            "expert_tools_title": "Ekstra Araçlar",
            "btn_scan": "Yeniden Tara",
            
            # --- Performance View ---
            "sys_info_title": "Sistem Özellikleri",
            "lbl_os": "İşletim Sistemi:",
            "lbl_kernel": "Kernel:",
            "lbl_cpu": "İşlemci (CPU):",
            "lbl_ram": "Bellek (RAM):",
            "lbl_gpu": "Ekran Kartı:",
            
            "dash_gpu_title": "Canlı GPU Durumu",
            "dash_sys_title": "Canlı Sistem Kullanımı",
            "lbl_temp": "Sıcaklık",
            "lbl_load": "Yük",
            "lbl_mem": "VRAM",
            "lbl_cpu_temp": "CPU Isısı",
            "lbl_cpu_load": "CPU Yükü",
            
            "ctrl_title": "Grafik Modu (Hybrid / Mux)",
            "ctrl_mode_select": "Mod Seçin:",
            "mode_perf": "Performans (NVIDIA)",
            "mode_save": "Güç Tasarrufu (Intel)",
            "mode_balanced": "Dengeli (On-Demand)",
            "mode_auto": "Otomatik",
            "btn_apply": "Uygula (Reboot Gerekir)",
            "msg_prime_unsupported": "Bu özellik cihazınız tarafından desteklenmiyor (NVIDIA Optimus/Prime bulunamadı).",
            
            "tools_title": "Araçlar ve Optimizasyon",
            "tool_gamemode": "Oyun Modu (Feral GameMode):",
            "tool_flatpak": "Flatpak/Steam İzin Onarıcı:",
            "btn_repair": "Onar",
            "btn_repaired": "Tamamlandı",
            
            # --- Type Selection Dialog ---
            "dialog_type_desc": "Hangi sürücü tipini kurmak istiyorsunuz?",
            "type_open": "Açık Kaynak (Open Source)",
            "type_open_desc": "Topluluk destekli, kararlı.",
            "type_closed": "Kapalı Kaynak (Proprietary)",
            "type_closed_desc": "Üretici resmi sürücüsü,\nyüksek oyun performansı.",
            "err_amd_pro_title": "AMD Proprietary",
            "err_amd_pro_desc": "AMD için en iyi deneyimi Açık Kaynak sunar. Açık Kaynak (Mesa) kurulacak.",
        },
        "en": {
            # --- Main Window ---
            "title_main": "Select Installation Type",
            "desc_main": "Optimized options for your hardware.",
            "tab_install": "Install",
            "tab_expert": "Expert",
            "tab_perf": "Performance",
            
            "express_title": "Express Install (Recommended)",
            "express_desc_nvidia": "Automatically installs the latest stable NVIDIA v{} driver.",
            "express_desc_amd": "Automatically installs the latest AMD Mesa drivers.",
            "custom_title": "Custom Install (Expert)",
            "custom_desc": "Manually configure version, kernel type, and cleanup settings.",
            
            "dialog_express_title": "Express Install Confirmation",
            "dialog_express_desc_nvidia": "The optimal NVIDIA Proprietary (v{}) driver has been selected for your system.\n\nThis ensures maximum performance for gaming and professional apps.\nDo you want to proceed?",
            "dialog_express_desc_amd": "The optimal AMD (Mesa) open-source drivers will be installed.\nDo you want to proceed?",
            
            "btn_dev_contact": "Contact Developer",
            "btn_backup": "Continue Without Backup",
            "btn_close": "Close",
            "btn_report": "Send Report",
            
            "status_active_driver": "Active Driver: {} | Secure Boot: {}",
            "sb_warning": "⚠️ Secure Boot is ON! Unsigned drivers may not work. It is recommended to disable it in BIOS.",
            "err_no_internet": "No Internet",
            "err_no_internet_desc": "Internet connection is required to download drivers.",
            
            "msg_trans_start": "Starting Process",
            "msg_processing": "Please wait, configuring system...",
            "msg_success_title": "Process Completed Successfully",
            "msg_success_desc": "You can check the logs or return to the main menu.",
            "msg_error_title": "An Error Occurred",
            "msg_error_desc": "Please review the details below.",
            
            "expert_header": "Expert Driver Management",
            "expert_conf_title": "Installation Settings",
            "expert_target_ver": "Target Driver Version:",
            "expert_deep_clean": "Deep Clean (Remove previous configs)",
            "expert_actions_title": "Actions",
            "expert_btn_proprietary": "Install Proprietary Driver",
            "expert_desc_proprietary": "Installs the selected version (Closed Source).",
            "expert_btn_open": "Install Open Kernel Driver",
            "expert_desc_open": "Installs the selected version (Open Source Modules).",
            "expert_btn_reset": "Remove Drivers & Reset",
            "expert_desc_reset": "Reverts system to the default Nouveau driver.",
            "expert_tools_title": "Extra Tools",
            "btn_scan": "Rescan",
            
            # --- Performance View ---
            "sys_info_title": "System Specs",
            "lbl_os": "OS:",
            "lbl_kernel": "Kernel:",
            "lbl_cpu": "Processor (CPU):",
            "lbl_ram": "Memory (RAM):",
            "lbl_gpu": "Graphics Card:",
            
            "dash_gpu_title": "Live GPU Status",
            "dash_sys_title": "Live System Usage",
            "lbl_temp": "Temp",
            "lbl_load": "Load",
            "lbl_mem": "VRAM",
            "lbl_cpu_temp": "CPU Temp",
            "lbl_cpu_load": "CPU Load",
            
            "ctrl_title": "Graphics Mode (Hybrid / Mux)",
            "ctrl_mode_select": "Select Mode:",
            "mode_perf": "Performance (NVIDIA)",
            "mode_save": "Power Saving (Intel)",
            "mode_balanced": "Balanced (On-Demand)",
            "mode_auto": "Auto",
            "btn_apply": "Apply (Reboot Required)",
            "msg_prime_unsupported": "This feature is not supported on your device (NVIDIA Optimus/Prime not found).",
            
            "tools_title": "Tools & Optimization",
            "tool_gamemode": "Game Mode (Feral GameMode):",
            "tool_flatpak": "Flatpak/Steam Permission Fixer:",
            "btn_repair": "Repair",
            "btn_repaired": "Done",
            
            # --- Type Selection Dialog ---
            "dialog_type_desc": "Which driver type do you want to install?",
            "type_open": "Open Source",
            "type_open_desc": "Community supported, stable.",
            "type_closed": "Proprietary",
            "type_closed_desc": "Manufacturer official driver,\nhigh gaming performance.",
            "err_amd_pro_title": "AMD Proprietary",
            "err_amd_pro_desc": "Open Source offers the best experience for AMD. Installing Open Source (Mesa).",
        }
    }
    
    _lang = "en" # Default

    @classmethod
    def init_lang(cls):
        """Sistem dilini algılar ve ayarlar."""
        try:
            # 1. Environment Variable
            sys_lang = os.environ.get("LANG", "").split(".")[0]
            if not sys_lang:
                 sys_lang = locale.getdefaultlocale()[0]
            
            if sys_lang and sys_lang.lower().startswith("tr"):
                cls._lang = "tr"
            else:
                cls._lang = "en" # Diğer hepsi için İngilizce
                
            print(f"DEBUG: Language set to '{cls._lang}' (detected from '{sys_lang}')")
        except:
            cls._lang = "en"

    @classmethod
    def tr(cls, key, *args):
        """Anahtar kelimeyi çevirir."""
        dic = cls.DICTIONARY.get(cls._lang, cls.DICTIONARY["en"])
        val = dic.get(key, key)
        if args:
            try:
                return val.format(*args)
            except:
                return val
        return val

# Modül yüklendiğinde otomatik algıla
Translator.init_lang()
