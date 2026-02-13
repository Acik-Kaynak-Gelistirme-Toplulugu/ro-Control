// Internationalization — multi-language dictionary-based translation
//
// Supported languages (same as po/LINGUAS):
//   ar, de, es, fr, it, ja, ko, nl, pl, pt, pt_BR, ru, tr, uk, zh_CN, zh_TW
//
// English (en) is the default / fallback language.

use std::collections::HashMap;
use std::sync::OnceLock;

static LANG: OnceLock<Lang> = OnceLock::new();

#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash)]
pub enum Lang {
    Ar,
    De,
    En,
    Es,
    Fr,
    It,
    Ja,
    Ko,
    Nl,
    Pl,
    Pt,
    PtBr,
    Ru,
    Tr,
    Uk,
    ZhCn,
    ZhTw,
}

/// Detect system language and initialize.
pub fn init() {
    let lang = detect_language();
    let _ = LANG.set(lang);
    log::info!("Language set to: {:?}", lang);
}

fn detect_language() -> Lang {
    let raw = std::env::var("LANG")
        .or_else(|_| std::env::var("LC_ALL"))
        .or_else(|_| std::env::var("LC_MESSAGES"))
        .unwrap_or_default()
        .to_lowercase();

    if raw.starts_with("tr") { return Lang::Tr; }
    if raw.starts_with("de") { return Lang::De; }
    if raw.starts_with("es") { return Lang::Es; }
    if raw.starts_with("fr") { return Lang::Fr; }
    if raw.starts_with("it") { return Lang::It; }
    if raw.starts_with("ar") { return Lang::Ar; }
    if raw.starts_with("ja") { return Lang::Ja; }
    if raw.starts_with("ko") { return Lang::Ko; }
    if raw.starts_with("nl") { return Lang::Nl; }
    if raw.starts_with("pl") { return Lang::Pl; }
    if raw.starts_with("pt_br") { return Lang::PtBr; }
    if raw.starts_with("pt") { return Lang::Pt; }
    if raw.starts_with("ru") { return Lang::Ru; }
    if raw.starts_with("uk") { return Lang::Uk; }
    if raw.starts_with("zh_tw") || raw.starts_with("zh_hant") { return Lang::ZhTw; }
    if raw.starts_with("zh") { return Lang::ZhCn; }

    Lang::En
}

fn current_lang() -> Lang {
    *LANG.get().unwrap_or(&Lang::En)
}

/// Translate a key. Returns English fallback if key not found.
pub fn tr(key: &str) -> &'static str {
    let dict = get_dictionary();
    let lang = current_lang();

    // Try the user's language first
    if let Some(lang_map) = dict.langs.get(&lang) {
        if let Some(&val) = lang_map.get(key) {
            return val;
        }
    }

    // Fallback to English
    dict.en.get(key).copied().unwrap_or("???")
}

struct Dictionary {
    en: HashMap<&'static str, &'static str>,
    langs: HashMap<Lang, HashMap<&'static str, &'static str>>,
}

static DICT: OnceLock<Dictionary> = OnceLock::new();

// Helper macro to reduce repetition
macro_rules! t {
    ($map:expr, $key:expr, $val:expr) => {
        $map.insert($key, $val);
    };
}

fn get_dictionary() -> &'static Dictionary {
    DICT.get_or_init(|| {
        let mut en = HashMap::new();
        let mut tr = HashMap::new();
        let mut de = HashMap::new();
        let mut es = HashMap::new();
        let mut fr = HashMap::new();
        let mut it = HashMap::new();
        let mut ar = HashMap::new();
        let mut ja = HashMap::new();
        let mut ko = HashMap::new();
        let mut nl = HashMap::new();
        let mut pl = HashMap::new();
        let mut pt = HashMap::new();
        let mut pt_br = HashMap::new();
        let mut ru = HashMap::new();
        let mut uk = HashMap::new();
        let mut zh_cn = HashMap::new();
        let mut zh_tw = HashMap::new();

        // =====================================================================
        // Installation View
        // =====================================================================
        t!(en, "title_main", "Select Installation Type");
        t!(tr, "title_main", "Kurulum Tipini Seçin");
        t!(de, "title_main", "Installationstyp auswählen");
        t!(es, "title_main", "Seleccionar tipo de instalación");
        t!(fr, "title_main", "Sélectionner le type d'installation");
        t!(it, "title_main", "Seleziona il tipo di installazione");
        t!(ar, "title_main", "اختر نوع التثبيت");
        t!(ja, "title_main", "インストールタイプを選択");
        t!(ko, "title_main", "설치 유형 선택");
        t!(nl, "title_main", "Installatietype selecteren");
        t!(pl, "title_main", "Wybierz typ instalacji");
        t!(pt, "title_main", "Selecionar tipo de instalação");
        t!(pt_br, "title_main", "Selecionar tipo de instalação");
        t!(ru, "title_main", "Выберите тип установки");
        t!(uk, "title_main", "Виберіть тип встановлення");
        t!(zh_cn, "title_main", "选择安装类型");
        t!(zh_tw, "title_main", "選擇安裝類型");

        t!(en, "desc_main", "Optimized options for your hardware.");
        t!(tr, "desc_main", "Donanımınız için optimize edilmiş seçenekler.");
        t!(de, "desc_main", "Optimierte Optionen für Ihre Hardware.");
        t!(es, "desc_main", "Opciones optimizadas para su hardware.");
        t!(fr, "desc_main", "Options optimisées pour votre matériel.");
        t!(ru, "desc_main", "Оптимизированные параметры для вашего оборудования.");

        t!(en, "express_title", "Express Install (Recommended)");
        t!(tr, "express_title", "Hızlı Kurulum (Önerilen)");
        t!(de, "express_title", "Express-Installation (Empfohlen)");
        t!(es, "express_title", "Instalación rápida (Recomendado)");
        t!(fr, "express_title", "Installation rapide (Recommandé)");
        t!(it, "express_title", "Installazione rapida (Consigliata)");
        t!(ja, "express_title", "高速インストール（推奨）");
        t!(ko, "express_title", "빠른 설치 (권장)");
        t!(ru, "express_title", "Экспресс-установка (Рекомендуется)");
        t!(zh_cn, "express_title", "快速安装（推荐）");

        t!(en, "express_desc_nvidia", "Automatically installs the latest stable NVIDIA driver.");
        t!(tr, "express_desc_nvidia", "En güncel kararlı NVIDIA sürücüsünü otomatik kurar.");
        t!(de, "express_desc_nvidia", "Installiert automatisch den neuesten stabilen NVIDIA-Treiber.");
        t!(es, "express_desc_nvidia", "Instala automáticamente el controlador NVIDIA estable más reciente.");
        t!(fr, "express_desc_nvidia", "Installe automatiquement le dernier pilote NVIDIA stable.");
        t!(ru, "express_desc_nvidia", "Автоматически устанавливает последний стабильный драйвер NVIDIA.");

        t!(en, "express_desc_amd", "Automatically installs the latest AMD Mesa drivers.");
        t!(tr, "express_desc_amd", "En güncel AMD Mesa sürücülerini otomatik kurar.");

        t!(en, "custom_title", "Custom Install (Expert)");
        t!(tr, "custom_title", "Özel Kurulum (Uzman)");
        t!(de, "custom_title", "Benutzerdefinierte Installation (Experte)");
        t!(es, "custom_title", "Instalación personalizada (Experto)");
        t!(fr, "custom_title", "Installation personnalisée (Expert)");
        t!(ru, "custom_title", "Выборочная установка (Эксперт)");

        t!(en, "custom_desc", "Manually configure version, kernel type, and cleanup settings.");
        t!(tr, "custom_desc", "Sürüm, kernel tipi ve temizlik ayarlarını manuel yapılandırın.");
        t!(de, "custom_desc", "Version, Kernel-Typ und Bereinigungsoptionen manuell konfigurieren.");
        t!(fr, "custom_desc", "Configurer manuellement la version, le type de noyau et les options de nettoyage.");
        t!(ru, "custom_desc", "Вручную настроить версию, тип ядра и параметры очистки.");

        // =====================================================================
        // Tab Labels
        // =====================================================================
        t!(en, "tab_install", "Install");
        t!(tr, "tab_install", "Kurulum");
        t!(de, "tab_install", "Installation");
        t!(es, "tab_install", "Instalación");
        t!(fr, "tab_install", "Installation");
        t!(it, "tab_install", "Installazione");
        t!(ja, "tab_install", "インストール");
        t!(ko, "tab_install", "설치");
        t!(nl, "tab_install", "Installatie");
        t!(pl, "tab_install", "Instalacja");
        t!(pt, "tab_install", "Instalação");
        t!(pt_br, "tab_install", "Instalação");
        t!(ru, "tab_install", "Установка");
        t!(uk, "tab_install", "Встановлення");
        t!(zh_cn, "tab_install", "安装");
        t!(zh_tw, "tab_install", "安裝");
        t!(ar, "tab_install", "التثبيت");

        t!(en, "tab_perf", "Performance");
        t!(tr, "tab_perf", "Performans");
        t!(de, "tab_perf", "Leistung");
        t!(es, "tab_perf", "Rendimiento");
        t!(fr, "tab_perf", "Performance");
        t!(it, "tab_perf", "Prestazioni");
        t!(ja, "tab_perf", "パフォーマンス");
        t!(ko, "tab_perf", "성능");
        t!(ru, "tab_perf", "Производительность");
        t!(zh_cn, "tab_perf", "性能");

        // =====================================================================
        // Buttons
        // =====================================================================
        t!(en, "btn_close", "Close");
        t!(tr, "btn_close", "Kapat");
        t!(de, "btn_close", "Schließen");
        t!(es, "btn_close", "Cerrar");
        t!(fr, "btn_close", "Fermer");
        t!(it, "btn_close", "Chiudi");
        t!(ja, "btn_close", "閉じる");
        t!(ko, "btn_close", "닫기");
        t!(nl, "btn_close", "Sluiten");
        t!(pl, "btn_close", "Zamknij");
        t!(pt, "btn_close", "Fechar");
        t!(pt_br, "btn_close", "Fechar");
        t!(ru, "btn_close", "Закрыть");
        t!(uk, "btn_close", "Закрити");
        t!(zh_cn, "btn_close", "关闭");
        t!(zh_tw, "btn_close", "關閉");
        t!(ar, "btn_close", "إغلاق");

        t!(en, "btn_apply", "Apply (Reboot Required)");
        t!(tr, "btn_apply", "Uygula (Yeniden Başlatma Gerekli)");
        t!(de, "btn_apply", "Anwenden (Neustart erforderlich)");
        t!(es, "btn_apply", "Aplicar (Reinicio necesario)");
        t!(fr, "btn_apply", "Appliquer (Redémarrage requis)");
        t!(ru, "btn_apply", "Применить (Требуется перезагрузка)");

        t!(en, "btn_report", "Send Report");
        t!(tr, "btn_report", "Rapor Gönder");
        t!(de, "btn_report", "Bericht senden");
        t!(fr, "btn_report", "Envoyer un rapport");
        t!(ru, "btn_report", "Отправить отчёт");

        t!(en, "btn_repair", "Repair");
        t!(tr, "btn_repair", "Onar");
        t!(de, "btn_repair", "Reparieren");
        t!(es, "btn_repair", "Reparar");
        t!(fr, "btn_repair", "Réparer");
        t!(ru, "btn_repair", "Восстановить");

        t!(en, "btn_accept", "Accept and Install");
        t!(tr, "btn_accept", "Kabul Et ve Kur");
        t!(de, "btn_accept", "Akzeptieren und installieren");
        t!(fr, "btn_accept", "Accepter et installer");
        t!(ru, "btn_accept", "Принять и установить");

        t!(en, "btn_decline", "Cancel");
        t!(tr, "btn_decline", "Vazgeç");
        t!(de, "btn_decline", "Abbrechen");
        t!(es, "btn_decline", "Cancelar");
        t!(fr, "btn_decline", "Annuler");
        t!(ru, "btn_decline", "Отмена");

        // =====================================================================
        // Status / Messages
        // =====================================================================
        t!(en, "sb_warning", "⚠️ Secure Boot is ON! Unsigned drivers may not work.");
        t!(tr, "sb_warning", "⚠️ Secure Boot Açık! İmzasız sürücüler çalışmayabilir.");
        t!(de, "sb_warning", "⚠️ Secure Boot ist aktiviert! Unsignierte Treiber funktionieren möglicherweise nicht.");
        t!(es, "sb_warning", "⚠️ ¡Secure Boot activado! Los controladores sin firmar pueden no funcionar.");
        t!(fr, "sb_warning", "⚠️ Secure Boot activé ! Les pilotes non signés pourraient ne pas fonctionner.");
        t!(ru, "sb_warning", "⚠️ Secure Boot включён! Неподписанные драйверы могут не работать.");
        t!(ja, "sb_warning", "⚠️ セキュアブートが有効です！署名されていないドライバーは動作しない場合があります。");

        t!(en, "msg_processing", "Please wait, configuring system...");
        t!(tr, "msg_processing", "Lütfen bekleyin, sistem yapılandırılıyor...");
        t!(de, "msg_processing", "Bitte warten, System wird konfiguriert...");
        t!(es, "msg_processing", "Por favor espere, configurando el sistema...");
        t!(fr, "msg_processing", "Veuillez patienter, configuration du système...");
        t!(it, "msg_processing", "Attendere, configurazione del sistema in corso...");
        t!(ja, "msg_processing", "お待ちください、システムを構成中です...");
        t!(ko, "msg_processing", "잠시 기다려 주세요, 시스템 구성 중...");
        t!(ru, "msg_processing", "Пожалуйста, подождите, настройка системы...");
        t!(zh_cn, "msg_processing", "请稍候，正在配置系统...");

        t!(en, "msg_success_title", "Operation Completed Successfully");
        t!(tr, "msg_success_title", "İşlem Başarıyla Tamamlandı");
        t!(de, "msg_success_title", "Vorgang erfolgreich abgeschlossen");
        t!(es, "msg_success_title", "Operación completada exitosamente");
        t!(fr, "msg_success_title", "Opération terminée avec succès");
        t!(ru, "msg_success_title", "Операция успешно завершена");

        t!(en, "msg_error_title", "An Error Occurred");
        t!(tr, "msg_error_title", "İşlem Sırasında Hata Oluştu");
        t!(de, "msg_error_title", "Ein Fehler ist aufgetreten");
        t!(es, "msg_error_title", "Se produjo un error");
        t!(fr, "msg_error_title", "Une erreur s'est produite");
        t!(ru, "msg_error_title", "Произошла ошибка");

        t!(en, "no_internet", "Internet connection required.");
        t!(tr, "no_internet", "İnternet bağlantısı gerekli.");
        t!(de, "no_internet", "Internetverbindung erforderlich.");
        t!(ru, "no_internet", "Требуется подключение к интернету.");

        t!(en, "scan_complete", "Scan Complete");
        t!(tr, "scan_complete", "Tarama Tamamlandı");
        t!(de, "scan_complete", "Scan abgeschlossen");
        t!(ru, "scan_complete", "Сканирование завершено");

        // =====================================================================
        // Expert View
        // =====================================================================
        t!(en, "expert_header", "Expert Driver Management");
        t!(tr, "expert_header", "Uzman Sürücü Yönetimi");
        t!(de, "expert_header", "Erweiterte Treiberverwaltung");
        t!(es, "expert_header", "Gestión avanzada de controladores");
        t!(fr, "expert_header", "Gestion avancée des pilotes");
        t!(it, "expert_header", "Gestione avanzata dei driver");
        t!(ja, "expert_header", "上級ドライバー管理");
        t!(ko, "expert_header", "고급 드라이버 관리");
        t!(ru, "expert_header", "Расширенное управление драйверами");
        t!(zh_cn, "expert_header", "高级驱动管理");

        t!(en, "expert_btn_proprietary", "Install Proprietary Driver");
        t!(tr, "expert_btn_proprietary", "Kapalı Kaynak Sürücüyü Kur");
        t!(de, "expert_btn_proprietary", "Proprietären Treiber installieren");
        t!(es, "expert_btn_proprietary", "Instalar controlador propietario");
        t!(fr, "expert_btn_proprietary", "Installer le pilote propriétaire");
        t!(ru, "expert_btn_proprietary", "Установить проприетарный драйвер");

        t!(en, "expert_btn_open", "Install Open Kernel Driver");
        t!(tr, "expert_btn_open", "Açık Çekirdek Sürücüsünü Kur");
        t!(de, "expert_btn_open", "Open-Kernel-Treiber installieren");
        t!(fr, "expert_btn_open", "Installer le pilote noyau ouvert");
        t!(ru, "expert_btn_open", "Установить открытый драйвер ядра");

        t!(en, "expert_btn_reset", "Remove Drivers & Reset");
        t!(tr, "expert_btn_reset", "Sürücüleri Kaldır ve Sıfırla");
        t!(de, "expert_btn_reset", "Treiber entfernen & zurücksetzen");
        t!(fr, "expert_btn_reset", "Supprimer les pilotes et réinitialiser");
        t!(ru, "expert_btn_reset", "Удалить драйверы и сбросить");

        t!(en, "expert_deep_clean", "Deep Clean (Remove previous configs)");
        t!(tr, "expert_deep_clean", "Derin Temizlik (Önceki yapılandırmaları sil)");
        t!(de, "expert_deep_clean", "Tiefenreinigung (Vorherige Konfigurationen entfernen)");
        t!(ru, "expert_deep_clean", "Глубокая очистка (Удалить предыдущие конфигурации)");

        // =====================================================================
        // Performance View
        // =====================================================================
        t!(en, "sys_info_title", "System Specs");
        t!(tr, "sys_info_title", "Sistem Özellikleri");
        t!(de, "sys_info_title", "Systeminformationen");
        t!(es, "sys_info_title", "Especificaciones del sistema");
        t!(fr, "sys_info_title", "Spécifications du système");
        t!(ru, "sys_info_title", "Характеристики системы");
        t!(ja, "sys_info_title", "システム仕様");

        t!(en, "lbl_os", "OS:");
        t!(tr, "lbl_os", "İşletim Sistemi:");
        t!(de, "lbl_os", "Betriebssystem:");
        t!(es, "lbl_os", "Sistema operativo:");
        t!(fr, "lbl_os", "Système d'exploitation :");
        t!(ru, "lbl_os", "ОС:");
        t!(ja, "lbl_os", "OS:");

        t!(en, "lbl_kernel", "Kernel:");
        t!(tr, "lbl_kernel", "Çekirdek:");
        t!(de, "lbl_kernel", "Kernel:");
        t!(ru, "lbl_kernel", "Ядро:");

        t!(en, "lbl_cpu", "Processor (CPU):");
        t!(tr, "lbl_cpu", "İşlemci (CPU):");
        t!(de, "lbl_cpu", "Prozessor (CPU):");
        t!(es, "lbl_cpu", "Procesador (CPU):");
        t!(fr, "lbl_cpu", "Processeur (CPU) :");
        t!(ru, "lbl_cpu", "Процессор (CPU):");
        t!(ja, "lbl_cpu", "プロセッサ (CPU):");

        t!(en, "lbl_ram", "Memory (RAM):");
        t!(tr, "lbl_ram", "Bellek (RAM):");
        t!(de, "lbl_ram", "Arbeitsspeicher (RAM):");
        t!(es, "lbl_ram", "Memoria (RAM):");
        t!(fr, "lbl_ram", "Mémoire (RAM) :");
        t!(ru, "lbl_ram", "Память (ОЗУ):");

        t!(en, "lbl_gpu", "Graphics Card:");
        t!(tr, "lbl_gpu", "Ekran Kartı:");
        t!(de, "lbl_gpu", "Grafikkarte:");
        t!(es, "lbl_gpu", "Tarjeta gráfica:");
        t!(fr, "lbl_gpu", "Carte graphique :");
        t!(ru, "lbl_gpu", "Видеокарта:");
        t!(ja, "lbl_gpu", "グラフィックカード:");

        t!(en, "lbl_display", "Display Server:");
        t!(tr, "lbl_display", "Görüntü Sunucusu:");
        t!(de, "lbl_display", "Anzeigeserver:");
        t!(fr, "lbl_display", "Serveur d'affichage :");
        t!(ru, "lbl_display", "Сервер отображения:");

        t!(en, "lbl_temp", "Temp");
        t!(tr, "lbl_temp", "Sıcaklık");
        t!(de, "lbl_temp", "Temp.");
        t!(ru, "lbl_temp", "Темп.");
        t!(ja, "lbl_temp", "温度");

        t!(en, "lbl_load", "Load");
        t!(tr, "lbl_load", "Yük");
        t!(de, "lbl_load", "Auslastung");
        t!(ru, "lbl_load", "Нагрузка");

        t!(en, "lbl_mem", "VRAM");
        t!(tr, "lbl_mem", "VRAM");

        t!(en, "lbl_cpu_temp", "CPU Temp");
        t!(tr, "lbl_cpu_temp", "CPU Isısı");
        t!(de, "lbl_cpu_temp", "CPU-Temp.");
        t!(ru, "lbl_cpu_temp", "Темп. CPU");

        t!(en, "lbl_cpu_load", "CPU Load");
        t!(tr, "lbl_cpu_load", "CPU Yükü");
        t!(de, "lbl_cpu_load", "CPU-Auslastung");
        t!(ru, "lbl_cpu_load", "Нагрузка CPU");

        t!(en, "dash_gpu_title", "Live GPU Status");
        t!(tr, "dash_gpu_title", "Canlı GPU Durumu");
        t!(de, "dash_gpu_title", "Live-GPU-Status");
        t!(es, "dash_gpu_title", "Estado de GPU en vivo");
        t!(fr, "dash_gpu_title", "État du GPU en direct");
        t!(ru, "dash_gpu_title", "Статус GPU в реальном времени");
        t!(ja, "dash_gpu_title", "GPUリアルタイム状態");

        t!(en, "dash_sys_title", "Live System Usage");
        t!(tr, "dash_sys_title", "Canlı Sistem Kullanımı");
        t!(de, "dash_sys_title", "Live-Systemauslastung");
        t!(ru, "dash_sys_title", "Использование системы в реальном времени");

        // =====================================================================
        // Tools & Optimization
        // =====================================================================
        t!(en, "tools_title", "Tools & Optimization");
        t!(tr, "tools_title", "Araçlar ve Optimizasyon");
        t!(de, "tools_title", "Werkzeuge & Optimierung");
        t!(es, "tools_title", "Herramientas y optimización");
        t!(fr, "tools_title", "Outils et optimisation");
        t!(ru, "tools_title", "Инструменты и оптимизация");

        t!(en, "tool_gamemode", "Game Mode (Feral GameMode):");
        t!(tr, "tool_gamemode", "Oyun Modu (Feral GameMode):");
        t!(de, "tool_gamemode", "Spielmodus (Feral GameMode):");
        t!(ru, "tool_gamemode", "Игровой режим (Feral GameMode):");

        t!(en, "tool_flatpak", "Flatpak/Steam Permission Fixer:");
        t!(tr, "tool_flatpak", "Flatpak/Steam İzin Onarıcı:");
        t!(de, "tool_flatpak", "Flatpak/Steam-Berechtigungsfix:");
        t!(ru, "tool_flatpak", "Исправление разрешений Flatpak/Steam:");

        // =====================================================================
        // Hybrid / Graphics Mode
        // =====================================================================
        t!(en, "ctrl_title", "Graphics Mode (Hybrid / Mux)");
        t!(tr, "ctrl_title", "Grafik Modu (Hybrid / Mux)");
        t!(de, "ctrl_title", "Grafikmodus (Hybrid / Mux)");
        t!(ru, "ctrl_title", "Режим графики (Гибрид / Мультиплексор)");

        t!(en, "mode_perf", "Performance (NVIDIA)");
        t!(tr, "mode_perf", "Performans (NVIDIA)");
        t!(de, "mode_perf", "Leistung (NVIDIA)");
        t!(ru, "mode_perf", "Производительность (NVIDIA)");

        t!(en, "mode_save", "Power Saving (Intel)");
        t!(tr, "mode_save", "Güç Tasarrufu (Intel)");
        t!(de, "mode_save", "Energiesparmodus (Intel)");
        t!(ru, "mode_save", "Энергосбережение (Intel)");

        t!(en, "mode_balanced", "Balanced (On-Demand)");
        t!(tr, "mode_balanced", "Dengeli (İsteğe Bağlı)");
        t!(de, "mode_balanced", "Ausgewogen (Bei Bedarf)");
        t!(ru, "mode_balanced", "Сбалансированный (По запросу)");

        // =====================================================================
        // Theme
        // =====================================================================
        t!(en, "tooltip_theme_system", "Theme: System");
        t!(tr, "tooltip_theme_system", "Tema: Sistem");
        t!(de, "tooltip_theme_system", "Thema: System");
        t!(ru, "tooltip_theme_system", "Тема: Системная");

        t!(en, "tooltip_theme_dark", "Theme: Dark");
        t!(tr, "tooltip_theme_dark", "Tema: Koyu");
        t!(de, "tooltip_theme_dark", "Thema: Dunkel");
        t!(ru, "tooltip_theme_dark", "Тема: Тёмная");

        t!(en, "tooltip_theme_light", "Theme: Light");
        t!(tr, "tooltip_theme_light", "Tema: Açık");
        t!(de, "tooltip_theme_light", "Thema: Hell");
        t!(ru, "tooltip_theme_light", "Тема: Светлая");

        // =====================================================================
        // EULA
        // =====================================================================
        t!(en, "eula_title", "License Agreement (EULA)");
        t!(tr, "eula_title", "Lisans Sözleşmesi (EULA)");
        t!(de, "eula_title", "Lizenzvereinbarung (EULA)");
        t!(ru, "eula_title", "Лицензионное соглашение (EULA)");

        t!(en, "eula_desc", "By installing the NVIDIA Proprietary driver, you agree to the NVIDIA EULA.");
        t!(tr, "eula_desc", "NVIDIA Kapalı Kaynak sürücüsünü kurarak NVIDIA EULA'yı kabul etmiş olursunuz.");
        t!(de, "eula_desc", "Durch die Installation des proprietären NVIDIA-Treibers stimmen Sie der NVIDIA-EULA zu.");
        t!(ru, "eula_desc", "Устанавливая проприетарный драйвер NVIDIA, вы соглашаетесь с EULA NVIDIA.");

        // =====================================================================
        // About
        // =====================================================================
        t!(en, "about_title", "About");
        t!(tr, "about_title", "Hakkında");
        t!(de, "about_title", "Über");
        t!(es, "about_title", "Acerca de");
        t!(fr, "about_title", "À propos");
        t!(it, "about_title", "Informazioni");
        t!(ja, "about_title", "このアプリについて");
        t!(ko, "about_title", "정보");
        t!(ru, "about_title", "О программе");
        t!(zh_cn, "about_title", "关于");

        // =====================================================================
        // Build the dictionary
        // =====================================================================
        let mut langs: HashMap<Lang, HashMap<&'static str, &'static str>> = HashMap::new();
        langs.insert(Lang::Tr, tr);
        langs.insert(Lang::De, de);
        langs.insert(Lang::Es, es);
        langs.insert(Lang::Fr, fr);
        langs.insert(Lang::It, it);
        langs.insert(Lang::Ar, ar);
        langs.insert(Lang::Ja, ja);
        langs.insert(Lang::Ko, ko);
        langs.insert(Lang::Nl, nl);
        langs.insert(Lang::Pl, pl);
        langs.insert(Lang::Pt, pt);
        langs.insert(Lang::PtBr, pt_br);
        langs.insert(Lang::Ru, ru);
        langs.insert(Lang::Uk, uk);
        langs.insert(Lang::ZhCn, zh_cn);
        langs.insert(Lang::ZhTw, zh_tw);

        Dictionary { en, langs }
    })
}
