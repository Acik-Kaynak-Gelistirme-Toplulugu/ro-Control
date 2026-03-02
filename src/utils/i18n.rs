#![allow(dead_code)]

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
        .unwrap_or_default();

    parse_locale(&raw)
}

/// Parse a locale string (e.g. "tr_TR.UTF-8") into a Lang variant.
fn parse_locale(raw: &str) -> Lang {
    let raw = raw.to_lowercase();

    if raw.starts_with("tr") {
        return Lang::Tr;
    }
    if raw.starts_with("de") {
        return Lang::De;
    }
    if raw.starts_with("es") {
        return Lang::Es;
    }
    if raw.starts_with("fr") {
        return Lang::Fr;
    }
    if raw.starts_with("it") {
        return Lang::It;
    }
    if raw.starts_with("ar") {
        return Lang::Ar;
    }
    if raw.starts_with("ja") {
        return Lang::Ja;
    }
    if raw.starts_with("ko") {
        return Lang::Ko;
    }
    if raw.starts_with("nl") {
        return Lang::Nl;
    }
    if raw.starts_with("pl") {
        return Lang::Pl;
    }
    if raw.starts_with("pt_br") {
        return Lang::PtBr;
    }
    if raw.starts_with("pt") {
        return Lang::Pt;
    }
    if raw.starts_with("ru") {
        return Lang::Ru;
    }
    if raw.starts_with("uk") {
        return Lang::Uk;
    }
    if raw.starts_with("zh_tw") || raw.starts_with("zh_hant") {
        return Lang::ZhTw;
    }
    if raw.starts_with("zh") {
        return Lang::ZhCn;
    }

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
        t!(it, "desc_main", "Opzioni ottimizzate per il tuo hardware.");
        t!(ar, "desc_main", "خيارات محسّنة لعتادك.");
        t!(ja, "desc_main", "お使いのハードウェアに最適化されたオプション。");
        t!(ko, "desc_main", "하드웨어에 최적화된 옵션.");
        t!(nl, "desc_main", "Geoptimaliseerde opties voor uw hardware.");
        t!(pl, "desc_main", "Zoptymalizowane opcje dla Twojego sprzętu.");
        t!(pt, "desc_main", "Opções otimizadas para o seu hardware.");
        t!(pt_br, "desc_main", "Opções otimizadas para o seu hardware.");
        t!(ru, "desc_main", "Оптимизированные параметры для вашего оборудования.");
        t!(uk, "desc_main", "Оптимізовані параметри для вашого обладнання.");
        t!(zh_cn, "desc_main", "为您的硬件优化的选项。");
        t!(zh_tw, "desc_main", "為您的硬體最佳化的選項。");

        t!(en, "express_title", "Express Install (Recommended)");
        t!(tr, "express_title", "Hızlı Kurulum (Önerilen)");
        t!(de, "express_title", "Express-Installation (Empfohlen)");
        t!(es, "express_title", "Instalación rápida (Recomendado)");
        t!(fr, "express_title", "Installation rapide (Recommandé)");
        t!(it, "express_title", "Installazione rapida (Consigliata)");
        t!(ar, "express_title", "تثبيت سريع (موصى به)");
        t!(ja, "express_title", "高速インストール（推奨）");
        t!(ko, "express_title", "빠른 설치 (권장)");
        t!(nl, "express_title", "Snelle installatie (Aanbevolen)");
        t!(pl, "express_title", "Szybka instalacja (Zalecana)");
        t!(pt, "express_title", "Instalação rápida (Recomendado)");
        t!(pt_br, "express_title", "Instalação rápida (Recomendado)");
        t!(ru, "express_title", "Экспресс-установка (Рекомендуется)");
        t!(uk, "express_title", "Швидке встановлення (Рекомендовано)");
        t!(zh_cn, "express_title", "快速安装（推荐）");
        t!(zh_tw, "express_title", "快速安裝（推薦）");

        t!(en, "express_desc_nvidia", "Automatically installs the latest stable NVIDIA driver.");
        t!(tr, "express_desc_nvidia", "En güncel kararlı NVIDIA sürücüsünü otomatik kurar.");
        t!(de, "express_desc_nvidia", "Installiert automatisch den neuesten stabilen NVIDIA-Treiber.");
        t!(es, "express_desc_nvidia", "Instala automáticamente el controlador NVIDIA estable más reciente.");
        t!(fr, "express_desc_nvidia", "Installe automatiquement le dernier pilote NVIDIA stable.");
        t!(it, "express_desc_nvidia", "Installa automaticamente il driver NVIDIA stabile più recente.");
        t!(ar, "express_desc_nvidia", "يثبّت تلقائياً أحدث تعريف NVIDIA المستقر.");
        t!(ja, "express_desc_nvidia", "最新の安定版NVIDIAドライバーを自動インストールします。");
        t!(ko, "express_desc_nvidia", "최신 안정 NVIDIA 드라이버를 자동으로 설치합니다.");
        t!(nl, "express_desc_nvidia", "Installeert automatisch het nieuwste stabiele NVIDIA-stuurprogramma.");
        t!(pl, "express_desc_nvidia", "Automatycznie instaluje najnowszy stabilny sterownik NVIDIA.");
        t!(pt, "express_desc_nvidia", "Instala automaticamente o driver NVIDIA estável mais recente.");
        t!(pt_br, "express_desc_nvidia", "Instala automaticamente o driver NVIDIA estável mais recente.");
        t!(ru, "express_desc_nvidia", "Автоматически устанавливает последний стабильный драйвер NVIDIA.");
        t!(uk, "express_desc_nvidia", "Автоматично встановлює найновіший стабільний драйвер NVIDIA.");
        t!(zh_cn, "express_desc_nvidia", "自动安装最新稳定版 NVIDIA 驱动。");
        t!(zh_tw, "express_desc_nvidia", "自動安裝最新穩定版 NVIDIA 驅動程式。");

        t!(en, "express_desc_amd", "Automatically installs the latest AMD Mesa drivers.");
        t!(tr, "express_desc_amd", "En güncel AMD Mesa sürücülerini otomatik kurar.");
        t!(de, "express_desc_amd", "Installiert automatisch die neuesten AMD-Mesa-Treiber.");
        t!(es, "express_desc_amd", "Instala automáticamente los controladores AMD Mesa más recientes.");
        t!(fr, "express_desc_amd", "Installe automatiquement les derniers pilotes AMD Mesa.");
        t!(it, "express_desc_amd", "Installa automaticamente i driver AMD Mesa più recenti.");
        t!(ar, "express_desc_amd", "يثبّت تلقائياً أحدث تعريفات AMD Mesa.");
        t!(ja, "express_desc_amd", "最新のAMD Mesaドライバーを自動インストールします。");
        t!(ko, "express_desc_amd", "최신 AMD Mesa 드라이버를 자동으로 설치합니다.");
        t!(nl, "express_desc_amd", "Installeert automatisch de nieuwste AMD Mesa-stuurprogramma's.");
        t!(pl, "express_desc_amd", "Automatycznie instaluje najnowsze sterowniki AMD Mesa.");
        t!(pt, "express_desc_amd", "Instala automaticamente os drivers AMD Mesa mais recentes.");
        t!(pt_br, "express_desc_amd", "Instala automaticamente os drivers AMD Mesa mais recentes.");
        t!(ru, "express_desc_amd", "Автоматически устанавливает последние драйверы AMD Mesa.");
        t!(uk, "express_desc_amd", "Автоматично встановлює найновіші драйвери AMD Mesa.");
        t!(zh_cn, "express_desc_amd", "自动安装最新的 AMD Mesa 驱动。");
        t!(zh_tw, "express_desc_amd", "自動安裝最新的 AMD Mesa 驅動程式。");

        t!(en, "custom_title", "Custom Install (Expert)");
        t!(tr, "custom_title", "Özel Kurulum (Uzman)");
        t!(de, "custom_title", "Benutzerdefinierte Installation (Experte)");
        t!(es, "custom_title", "Instalación personalizada (Experto)");
        t!(fr, "custom_title", "Installation personnalisée (Expert)");
        t!(it, "custom_title", "Installazione personalizzata (Esperto)");
        t!(ar, "custom_title", "تثبيت مخصص (خبير)");
        t!(ja, "custom_title", "カスタムインストール（上級者向け）");
        t!(ko, "custom_title", "사용자 정의 설치 (전문가)");
        t!(nl, "custom_title", "Aangepaste installatie (Expert)");
        t!(pl, "custom_title", "Instalacja niestandardowa (Ekspert)");
        t!(pt, "custom_title", "Instalação personalizada (Especialista)");
        t!(pt_br, "custom_title", "Instalação personalizada (Especialista)");
        t!(ru, "custom_title", "Выборочная установка (Эксперт)");
        t!(uk, "custom_title", "Вибіркове встановлення (Експерт)");
        t!(zh_cn, "custom_title", "自定义安装（专家）");
        t!(zh_tw, "custom_title", "自訂安裝（專家）");

        t!(en, "custom_desc", "Manually configure version, kernel type, and cleanup settings.");
        t!(tr, "custom_desc", "Sürüm, kernel tipi ve temizlik ayarlarını manuel yapılandırın.");
        t!(de, "custom_desc", "Version, Kernel-Typ und Bereinigungsoptionen manuell konfigurieren.");
        t!(es, "custom_desc", "Configurar manualmente versión, tipo de kernel y opciones de limpieza.");
        t!(fr, "custom_desc", "Configurer manuellement la version, le type de noyau et les options de nettoyage.");
        t!(it, "custom_desc", "Configura manualmente versione, tipo di kernel e impostazioni di pulizia.");
        t!(ar, "custom_desc", "تهيئة الإصدار ونوع النواة وإعدادات التنظيف يدوياً.");
        t!(ja, "custom_desc", "バージョン、カーネルタイプ、クリーンアップ設定を手動で構成します。");
        t!(ko, "custom_desc", "버전, 커널 유형 및 정리 설정을 수동으로 구성합니다.");
        t!(nl, "custom_desc", "Versie, kerneltype en opschoningsopties handmatig configureren.");
        t!(pl, "custom_desc", "Ręczna konfiguracja wersji, typu jądra i ustawień czyszczenia.");
        t!(pt, "custom_desc", "Configurar manualmente versão, tipo de kernel e opções de limpeza.");
        t!(pt_br, "custom_desc", "Configurar manualmente versão, tipo de kernel e opções de limpeza.");
        t!(ru, "custom_desc", "Вручную настроить версию, тип ядра и параметры очистки.");
        t!(uk, "custom_desc", "Вручну налаштувати версію, тип ядра та параметри очищення.");
        t!(zh_cn, "custom_desc", "手动配置版本、内核类型和清理设置。");
        t!(zh_tw, "custom_desc", "手動設定版本、核心類型和清理設定。");

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
        t!(ar, "tab_perf", "الأداء");
        t!(ja, "tab_perf", "パフォーマンス");
        t!(ko, "tab_perf", "성능");
        t!(nl, "tab_perf", "Prestaties");
        t!(pl, "tab_perf", "Wydajność");
        t!(pt, "tab_perf", "Desempenho");
        t!(pt_br, "tab_perf", "Desempenho");
        t!(ru, "tab_perf", "Производительность");
        t!(uk, "tab_perf", "Продуктивність");
        t!(zh_cn, "tab_perf", "性能");
        t!(zh_tw, "tab_perf", "效能");

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
        t!(it, "btn_apply", "Applica (Riavvio richiesto)");
        t!(ar, "btn_apply", "تطبيق (يتطلب إعادة التشغيل)");
        t!(ja, "btn_apply", "適用（再起動が必要）");
        t!(ko, "btn_apply", "적용 (재부팅 필요)");
        t!(nl, "btn_apply", "Toepassen (Herstart vereist)");
        t!(pl, "btn_apply", "Zastosuj (Wymagany restart)");
        t!(pt, "btn_apply", "Aplicar (Reinício necessário)");
        t!(pt_br, "btn_apply", "Aplicar (Reinicialização necessária)");
        t!(ru, "btn_apply", "Применить (Требуется перезагрузка)");
        t!(uk, "btn_apply", "Застосувати (Потрібне перезавантаження)");
        t!(zh_cn, "btn_apply", "应用（需要重启）");
        t!(zh_tw, "btn_apply", "套用（需要重新啟動）");

        t!(en, "btn_report", "Send Report");
        t!(tr, "btn_report", "Rapor Gönder");
        t!(de, "btn_report", "Bericht senden");
        t!(es, "btn_report", "Enviar informe");
        t!(fr, "btn_report", "Envoyer un rapport");
        t!(it, "btn_report", "Invia rapporto");
        t!(ar, "btn_report", "إرسال تقرير");
        t!(ja, "btn_report", "レポートを送信");
        t!(ko, "btn_report", "보고서 전송");
        t!(nl, "btn_report", "Rapport verzenden");
        t!(pl, "btn_report", "Wyślij raport");
        t!(pt, "btn_report", "Enviar relatório");
        t!(pt_br, "btn_report", "Enviar relatório");
        t!(ru, "btn_report", "Отправить отчёт");
        t!(uk, "btn_report", "Надіслати звіт");
        t!(zh_cn, "btn_report", "发送报告");
        t!(zh_tw, "btn_report", "傳送報告");

        t!(en, "btn_repair", "Repair");
        t!(tr, "btn_repair", "Onar");
        t!(de, "btn_repair", "Reparieren");
        t!(es, "btn_repair", "Reparar");
        t!(fr, "btn_repair", "Réparer");
        t!(it, "btn_repair", "Ripara");
        t!(ar, "btn_repair", "إصلاح");
        t!(ja, "btn_repair", "修復");
        t!(ko, "btn_repair", "복구");
        t!(nl, "btn_repair", "Repareren");
        t!(pl, "btn_repair", "Napraw");
        t!(pt, "btn_repair", "Reparar");
        t!(pt_br, "btn_repair", "Reparar");
        t!(ru, "btn_repair", "Восстановить");
        t!(uk, "btn_repair", "Відновити");
        t!(zh_cn, "btn_repair", "修复");
        t!(zh_tw, "btn_repair", "修復");

        t!(en, "btn_accept", "Accept and Install");
        t!(tr, "btn_accept", "Kabul Et ve Kur");
        t!(de, "btn_accept", "Akzeptieren und installieren");
        t!(es, "btn_accept", "Aceptar e instalar");
        t!(fr, "btn_accept", "Accepter et installer");
        t!(it, "btn_accept", "Accetta e installa");
        t!(ar, "btn_accept", "قبول وتثبيت");
        t!(ja, "btn_accept", "同意してインストール");
        t!(ko, "btn_accept", "동의 및 설치");
        t!(nl, "btn_accept", "Accepteren en installeren");
        t!(pl, "btn_accept", "Akceptuj i zainstaluj");
        t!(pt, "btn_accept", "Aceitar e instalar");
        t!(pt_br, "btn_accept", "Aceitar e instalar");
        t!(ru, "btn_accept", "Принять и установить");
        t!(uk, "btn_accept", "Прийняти та встановити");
        t!(zh_cn, "btn_accept", "接受并安装");
        t!(zh_tw, "btn_accept", "接受並安裝");

        t!(en, "btn_decline", "Cancel");
        t!(tr, "btn_decline", "Vazgeç");
        t!(de, "btn_decline", "Abbrechen");
        t!(es, "btn_decline", "Cancelar");
        t!(fr, "btn_decline", "Annuler");
        t!(it, "btn_decline", "Annulla");
        t!(ar, "btn_decline", "إلغاء");
        t!(ja, "btn_decline", "キャンセル");
        t!(ko, "btn_decline", "취소");
        t!(nl, "btn_decline", "Annuleren");
        t!(pl, "btn_decline", "Anuluj");
        t!(pt, "btn_decline", "Cancelar");
        t!(pt_br, "btn_decline", "Cancelar");
        t!(ru, "btn_decline", "Отмена");
        t!(uk, "btn_decline", "Скасувати");
        t!(zh_cn, "btn_decline", "取消");
        t!(zh_tw, "btn_decline", "取消");

        // =====================================================================
        // Status / Messages
        // =====================================================================
        t!(en, "sb_warning", "⚠️ Secure Boot is ON! Unsigned drivers may not work.");
        t!(tr, "sb_warning", "⚠️ Secure Boot Açık! İmzasız sürücüler çalışmayabilir.");
        t!(de, "sb_warning", "⚠️ Secure Boot ist aktiviert! Unsignierte Treiber funktionieren möglicherweise nicht.");
        t!(es, "sb_warning", "⚠️ ¡Secure Boot activado! Los controladores sin firmar pueden no funcionar.");
        t!(fr, "sb_warning", "⚠️ Secure Boot activé ! Les pilotes non signés pourraient ne pas fonctionner.");
        t!(it, "sb_warning", "⚠️ Secure Boot attivo! I driver non firmati potrebbero non funzionare.");
        t!(ar, "sb_warning", "⚠️ التمهيد الآمن مفعّل! قد لا تعمل التعريفات غير الموقّعة.");
        t!(ja, "sb_warning", "⚠️ セキュアブートが有効です！署名されていないドライバーは動作しない場合があります。");
        t!(ko, "sb_warning", "⚠️ 보안 부팅이 켜져 있습니다! 서명되지 않은 드라이버가 작동하지 않을 수 있습니다.");
        t!(nl, "sb_warning", "⚠️ Secure Boot is ingeschakeld! Niet-ondertekende stuurprogramma's werken mogelijk niet.");
        t!(pl, "sb_warning", "⚠️ Secure Boot jest włączony! Niepodpisane sterowniki mogą nie działać.");
        t!(pt, "sb_warning", "⚠️ Secure Boot ativado! Drivers não assinados podem não funcionar.");
        t!(pt_br, "sb_warning", "⚠️ Secure Boot ativado! Drivers não assinados podem não funcionar.");
        t!(ru, "sb_warning", "⚠️ Secure Boot включён! Неподписанные драйверы могут не работать.");
        t!(uk, "sb_warning", "⚠️ Secure Boot увімкнено! Непідписані драйвери можуть не працювати.");
        t!(zh_cn, "sb_warning", "⚠️ 安全启动已开启！未签名的驱动可能无法工作。");
        t!(zh_tw, "sb_warning", "⚠️ 安全開機已啟用！未簽署的驅動程式可能無法運作。");

        t!(en, "msg_processing", "Please wait, configuring system...");
        t!(tr, "msg_processing", "Lütfen bekleyin, sistem yapılandırılıyor...");
        t!(de, "msg_processing", "Bitte warten, System wird konfiguriert...");
        t!(es, "msg_processing", "Por favor espere, configurando el sistema...");
        t!(fr, "msg_processing", "Veuillez patienter, configuration du système...");
        t!(it, "msg_processing", "Attendere, configurazione del sistema in corso...");
        t!(ar, "msg_processing", "يرجى الانتظار، جارٍ تهيئة النظام...");
        t!(ja, "msg_processing", "お待ちください、システムを構成中です...");
        t!(ko, "msg_processing", "잠시 기다려 주세요, 시스템 구성 중...");
        t!(nl, "msg_processing", "Even geduld, systeem wordt geconfigureerd...");
        t!(pl, "msg_processing", "Proszę czekać, konfigurowanie systemu...");
        t!(pt, "msg_processing", "Aguarde, a configurar o sistema...");
        t!(pt_br, "msg_processing", "Aguarde, configurando o sistema...");
        t!(ru, "msg_processing", "Пожалуйста, подождите, настройка системы...");
        t!(uk, "msg_processing", "Будь ласка, зачекайте, налаштування системи...");
        t!(zh_cn, "msg_processing", "请稍候，正在配置系统...");
        t!(zh_tw, "msg_processing", "請稍候，正在設定系統...");

        t!(en, "msg_success_title", "Operation Completed Successfully");
        t!(tr, "msg_success_title", "İşlem Başarıyla Tamamlandı");
        t!(de, "msg_success_title", "Vorgang erfolgreich abgeschlossen");
        t!(es, "msg_success_title", "Operación completada exitosamente");
        t!(fr, "msg_success_title", "Opération terminée avec succès");
        t!(it, "msg_success_title", "Operazione completata con successo");
        t!(ar, "msg_success_title", "اكتملت العملية بنجاح");
        t!(ja, "msg_success_title", "操作が正常に完了しました");
        t!(ko, "msg_success_title", "작업이 성공적으로 완료되었습니다");
        t!(nl, "msg_success_title", "Bewerking succesvol voltooid");
        t!(pl, "msg_success_title", "Operacja zakończona pomyślnie");
        t!(pt, "msg_success_title", "Operação concluída com sucesso");
        t!(pt_br, "msg_success_title", "Operação concluída com sucesso");
        t!(ru, "msg_success_title", "Операция успешно завершена");
        t!(uk, "msg_success_title", "Операцію успішно завершено");
        t!(zh_cn, "msg_success_title", "操作成功完成");
        t!(zh_tw, "msg_success_title", "操作已成功完成");

        t!(en, "msg_error_title", "An Error Occurred");
        t!(tr, "msg_error_title", "İşlem Sırasında Hata Oluştu");
        t!(de, "msg_error_title", "Ein Fehler ist aufgetreten");
        t!(es, "msg_error_title", "Se produjo un error");
        t!(fr, "msg_error_title", "Une erreur s'est produite");
        t!(it, "msg_error_title", "Si è verificato un errore");
        t!(ar, "msg_error_title", "حدث خطأ");
        t!(ja, "msg_error_title", "エラーが発生しました");
        t!(ko, "msg_error_title", "오류가 발생했습니다");
        t!(nl, "msg_error_title", "Er is een fout opgetreden");
        t!(pl, "msg_error_title", "Wystąpił błąd");
        t!(pt, "msg_error_title", "Ocorreu um erro");
        t!(pt_br, "msg_error_title", "Ocorreu um erro");
        t!(ru, "msg_error_title", "Произошла ошибка");
        t!(uk, "msg_error_title", "Сталася помилка");
        t!(zh_cn, "msg_error_title", "发生错误");
        t!(zh_tw, "msg_error_title", "發生錯誤");

        t!(en, "no_internet", "Internet connection required.");
        t!(tr, "no_internet", "İnternet bağlantısı gerekli.");
        t!(de, "no_internet", "Internetverbindung erforderlich.");
        t!(es, "no_internet", "Se requiere conexión a Internet.");
        t!(fr, "no_internet", "Connexion Internet requise.");
        t!(it, "no_internet", "Connessione a Internet necessaria.");
        t!(ar, "no_internet", "يتطلب اتصالاً بالإنترنت.");
        t!(ja, "no_internet", "インターネット接続が必要です。");
        t!(ko, "no_internet", "인터넷 연결이 필요합니다.");
        t!(nl, "no_internet", "Internetverbinding vereist.");
        t!(pl, "no_internet", "Wymagane połączenie z Internetem.");
        t!(pt, "no_internet", "Ligação à Internet necessária.");
        t!(pt_br, "no_internet", "Conexão com a Internet necessária.");
        t!(ru, "no_internet", "Требуется подключение к интернету.");
        t!(uk, "no_internet", "Потрібне підключення до Інтернету.");
        t!(zh_cn, "no_internet", "需要互联网连接。");
        t!(zh_tw, "no_internet", "需要網際網路連線。");

        t!(en, "scan_complete", "Scan Complete");
        t!(tr, "scan_complete", "Tarama Tamamlandı");
        t!(de, "scan_complete", "Scan abgeschlossen");
        t!(es, "scan_complete", "Escaneo completado");
        t!(fr, "scan_complete", "Analyse terminée");
        t!(it, "scan_complete", "Scansione completata");
        t!(ar, "scan_complete", "اكتمل الفحص");
        t!(ja, "scan_complete", "スキャン完了");
        t!(ko, "scan_complete", "검사 완료");
        t!(nl, "scan_complete", "Scan voltooid");
        t!(pl, "scan_complete", "Skanowanie zakończone");
        t!(pt, "scan_complete", "Análise concluída");
        t!(pt_br, "scan_complete", "Verificação concluída");
        t!(ru, "scan_complete", "Сканирование завершено");
        t!(uk, "scan_complete", "Сканування завершено");
        t!(zh_cn, "scan_complete", "扫描完成");
        t!(zh_tw, "scan_complete", "掃描完成");

        // =====================================================================
        // Expert View
        // =====================================================================
        t!(en, "expert_header", "Expert Driver Management");
        t!(tr, "expert_header", "Uzman Sürücü Yönetimi");
        t!(de, "expert_header", "Erweiterte Treiberverwaltung");
        t!(es, "expert_header", "Gestión avanzada de controladores");
        t!(fr, "expert_header", "Gestion avancée des pilotes");
        t!(it, "expert_header", "Gestione avanzata dei driver");
        t!(ar, "expert_header", "إدارة التعريفات المتقدمة");
        t!(ja, "expert_header", "上級ドライバー管理");
        t!(ko, "expert_header", "고급 드라이버 관리");
        t!(nl, "expert_header", "Geavanceerd stuurprogrammabeheer");
        t!(pl, "expert_header", "Zaawansowane zarządzanie sterownikami");
        t!(pt, "expert_header", "Gestão avançada de drivers");
        t!(pt_br, "expert_header", "Gerenciamento avançado de drivers");
        t!(ru, "expert_header", "Расширенное управление драйверами");
        t!(uk, "expert_header", "Розширене керування драйверами");
        t!(zh_cn, "expert_header", "高级驱动管理");
        t!(zh_tw, "expert_header", "進階驅動程式管理");

        t!(en, "expert_btn_proprietary", "Install Proprietary Driver");
        t!(tr, "expert_btn_proprietary", "Kapalı Kaynak Sürücüyü Kur");
        t!(de, "expert_btn_proprietary", "Proprietären Treiber installieren");
        t!(es, "expert_btn_proprietary", "Instalar controlador propietario");
        t!(fr, "expert_btn_proprietary", "Installer le pilote propriétaire");
        t!(it, "expert_btn_proprietary", "Installa driver proprietario");
        t!(ar, "expert_btn_proprietary", "تثبيت التعريف المملوك");
        t!(ja, "expert_btn_proprietary", "プロプライエタリドライバーをインストール");
        t!(ko, "expert_btn_proprietary", "독점 드라이버 설치");
        t!(nl, "expert_btn_proprietary", "Propriëtair stuurprogramma installeren");
        t!(pl, "expert_btn_proprietary", "Zainstaluj sterownik własnościowy");
        t!(pt, "expert_btn_proprietary", "Instalar driver proprietário");
        t!(pt_br, "expert_btn_proprietary", "Instalar driver proprietário");
        t!(ru, "expert_btn_proprietary", "Установить проприетарный драйвер");
        t!(uk, "expert_btn_proprietary", "Встановити пропрієтарний драйвер");
        t!(zh_cn, "expert_btn_proprietary", "安装专有驱动");
        t!(zh_tw, "expert_btn_proprietary", "安裝專有驅動程式");

        t!(en, "expert_btn_open", "Install Open Kernel Driver");
        t!(tr, "expert_btn_open", "Açık Çekirdek Sürücüsünü Kur");
        t!(de, "expert_btn_open", "Open-Kernel-Treiber installieren");
        t!(es, "expert_btn_open", "Instalar controlador de kernel abierto");
        t!(fr, "expert_btn_open", "Installer le pilote noyau ouvert");
        t!(it, "expert_btn_open", "Installa driver open kernel");
        t!(ar, "expert_btn_open", "تثبيت تعريف النواة المفتوح");
        t!(ja, "expert_btn_open", "オープンカーネルドライバーをインストール");
        t!(ko, "expert_btn_open", "오픈 커널 드라이버 설치");
        t!(nl, "expert_btn_open", "Open kernel-stuurprogramma installeren");
        t!(pl, "expert_btn_open", "Zainstaluj otwarty sterownik jądra");
        t!(pt, "expert_btn_open", "Instalar driver de kernel aberto");
        t!(pt_br, "expert_btn_open", "Instalar driver de kernel aberto");
        t!(ru, "expert_btn_open", "Установить открытый драйвер ядра");
        t!(uk, "expert_btn_open", "Встановити відкритий драйвер ядра");
        t!(zh_cn, "expert_btn_open", "安装开源内核驱动");
        t!(zh_tw, "expert_btn_open", "安裝開源核心驅動程式");

        t!(en, "expert_btn_reset", "Remove Drivers & Reset");
        t!(tr, "expert_btn_reset", "Sürücüleri Kaldır ve Sıfırla");
        t!(de, "expert_btn_reset", "Treiber entfernen & zurücksetzen");
        t!(es, "expert_btn_reset", "Eliminar controladores y restablecer");
        t!(fr, "expert_btn_reset", "Supprimer les pilotes et réinitialiser");
        t!(it, "expert_btn_reset", "Rimuovi driver e ripristina");
        t!(ar, "expert_btn_reset", "إزالة التعريفات وإعادة التعيين");
        t!(ja, "expert_btn_reset", "ドライバーを削除してリセット");
        t!(ko, "expert_btn_reset", "드라이버 제거 및 초기화");
        t!(nl, "expert_btn_reset", "Stuurprogramma's verwijderen en resetten");
        t!(pl, "expert_btn_reset", "Usuń sterowniki i zresetuj");
        t!(pt, "expert_btn_reset", "Remover drivers e repor");
        t!(pt_br, "expert_btn_reset", "Remover drivers e redefinir");
        t!(ru, "expert_btn_reset", "Удалить драйверы и сбросить");
        t!(uk, "expert_btn_reset", "Видалити драйвери та скинути");
        t!(zh_cn, "expert_btn_reset", "卸载驱动并重置");
        t!(zh_tw, "expert_btn_reset", "移除驅動程式並重設");

        t!(en, "expert_deep_clean", "Deep Clean (Remove previous configs)");
        t!(tr, "expert_deep_clean", "Derin Temizlik (Önceki yapılandırmaları sil)");
        t!(de, "expert_deep_clean", "Tiefenreinigung (Vorherige Konfigurationen entfernen)");
        t!(es, "expert_deep_clean", "Limpieza profunda (Eliminar configuraciones anteriores)");
        t!(fr, "expert_deep_clean", "Nettoyage en profondeur (Supprimer les configurations précédentes)");
        t!(it, "expert_deep_clean", "Pulizia profonda (Rimuovi configurazioni precedenti)");
        t!(ar, "expert_deep_clean", "تنظيف شامل (إزالة الإعدادات السابقة)");
        t!(ja, "expert_deep_clean", "ディープクリーン（以前の設定を削除）");
        t!(ko, "expert_deep_clean", "정밀 정리 (이전 설정 제거)");
        t!(nl, "expert_deep_clean", "Dieptereiniging (Vorige configuraties verwijderen)");
        t!(pl, "expert_deep_clean", "Głębokie czyszczenie (Usuń poprzednie konfiguracje)");
        t!(pt, "expert_deep_clean", "Limpeza profunda (Remover configurações anteriores)");
        t!(pt_br, "expert_deep_clean", "Limpeza profunda (Remover configurações anteriores)");
        t!(ru, "expert_deep_clean", "Глубокая очистка (Удалить предыдущие конфигурации)");
        t!(uk, "expert_deep_clean", "Глибоке очищення (Видалити попередні конфігурації)");
        t!(zh_cn, "expert_deep_clean", "深度清理（移除先前配置）");
        t!(zh_tw, "expert_deep_clean", "深度清理（移除先前設定）");

        // =====================================================================
        // Performance View
        // =====================================================================
        t!(en, "sys_info_title", "System Specs");
        t!(tr, "sys_info_title", "Sistem Özellikleri");
        t!(de, "sys_info_title", "Systeminformationen");
        t!(es, "sys_info_title", "Especificaciones del sistema");
        t!(fr, "sys_info_title", "Spécifications du système");
        t!(it, "sys_info_title", "Specifiche di sistema");
        t!(ar, "sys_info_title", "مواصفات النظام");
        t!(ja, "sys_info_title", "システム仕様");
        t!(ko, "sys_info_title", "시스템 사양");
        t!(nl, "sys_info_title", "Systeemspecificaties");
        t!(pl, "sys_info_title", "Specyfikacja systemu");
        t!(pt, "sys_info_title", "Especificações do sistema");
        t!(pt_br, "sys_info_title", "Especificações do sistema");
        t!(ru, "sys_info_title", "Характеристики системы");
        t!(uk, "sys_info_title", "Характеристики системи");
        t!(zh_cn, "sys_info_title", "系统规格");
        t!(zh_tw, "sys_info_title", "系統規格");

        t!(en, "lbl_os", "OS:");
        t!(tr, "lbl_os", "İşletim Sistemi:");
        t!(de, "lbl_os", "Betriebssystem:");
        t!(es, "lbl_os", "Sistema operativo:");
        t!(fr, "lbl_os", "Système d'exploitation :");
        t!(it, "lbl_os", "Sistema operativo:");
        t!(ar, "lbl_os", "نظام التشغيل:");
        t!(ja, "lbl_os", "OS:");
        t!(ko, "lbl_os", "운영체제:");
        t!(nl, "lbl_os", "Besturingssysteem:");
        t!(pl, "lbl_os", "System operacyjny:");
        t!(pt, "lbl_os", "Sistema operativo:");
        t!(pt_br, "lbl_os", "Sistema operacional:");
        t!(ru, "lbl_os", "ОС:");
        t!(uk, "lbl_os", "ОС:");
        t!(zh_cn, "lbl_os", "操作系统：");
        t!(zh_tw, "lbl_os", "作業系統：");

        t!(en, "lbl_kernel", "Kernel:");
        t!(tr, "lbl_kernel", "Çekirdek:");
        t!(de, "lbl_kernel", "Kernel:");
        t!(es, "lbl_kernel", "Kernel:");
        t!(fr, "lbl_kernel", "Noyau :");
        t!(it, "lbl_kernel", "Kernel:");
        t!(ar, "lbl_kernel", "النواة:");
        t!(ja, "lbl_kernel", "カーネル:");
        t!(ko, "lbl_kernel", "커널:");
        t!(nl, "lbl_kernel", "Kernel:");
        t!(pl, "lbl_kernel", "Jądro:");
        t!(pt, "lbl_kernel", "Kernel:");
        t!(pt_br, "lbl_kernel", "Kernel:");
        t!(ru, "lbl_kernel", "Ядро:");
        t!(uk, "lbl_kernel", "Ядро:");
        t!(zh_cn, "lbl_kernel", "内核：");
        t!(zh_tw, "lbl_kernel", "核心：");

        t!(en, "lbl_cpu", "Processor (CPU):");
        t!(tr, "lbl_cpu", "İşlemci (CPU):");
        t!(de, "lbl_cpu", "Prozessor (CPU):");
        t!(es, "lbl_cpu", "Procesador (CPU):");
        t!(fr, "lbl_cpu", "Processeur (CPU) :");
        t!(it, "lbl_cpu", "Processore (CPU):");
        t!(ar, "lbl_cpu", "المعالج (CPU):");
        t!(ja, "lbl_cpu", "プロセッサ (CPU):");
        t!(ko, "lbl_cpu", "프로세서 (CPU):");
        t!(nl, "lbl_cpu", "Processor (CPU):");
        t!(pl, "lbl_cpu", "Procesor (CPU):");
        t!(pt, "lbl_cpu", "Processador (CPU):");
        t!(pt_br, "lbl_cpu", "Processador (CPU):");
        t!(ru, "lbl_cpu", "Процессор (CPU):");
        t!(uk, "lbl_cpu", "Процесор (CPU):");
        t!(zh_cn, "lbl_cpu", "处理器 (CPU)：");
        t!(zh_tw, "lbl_cpu", "處理器 (CPU)：");

        t!(en, "lbl_ram", "Memory (RAM):");
        t!(tr, "lbl_ram", "Bellek (RAM):");
        t!(de, "lbl_ram", "Arbeitsspeicher (RAM):");
        t!(es, "lbl_ram", "Memoria (RAM):");
        t!(fr, "lbl_ram", "Mémoire (RAM) :");
        t!(it, "lbl_ram", "Memoria (RAM):");
        t!(ar, "lbl_ram", "الذاكرة (RAM):");
        t!(ja, "lbl_ram", "メモリ (RAM):");
        t!(ko, "lbl_ram", "메모리 (RAM):");
        t!(nl, "lbl_ram", "Geheugen (RAM):");
        t!(pl, "lbl_ram", "Pamięć (RAM):");
        t!(pt, "lbl_ram", "Memória (RAM):");
        t!(pt_br, "lbl_ram", "Memória (RAM):");
        t!(ru, "lbl_ram", "Память (ОЗУ):");
        t!(uk, "lbl_ram", "Пам'ять (ОЗП):");
        t!(zh_cn, "lbl_ram", "内存 (RAM)：");
        t!(zh_tw, "lbl_ram", "記憶體 (RAM)：");

        t!(en, "lbl_gpu", "Graphics Card:");
        t!(tr, "lbl_gpu", "Ekran Kartı:");
        t!(de, "lbl_gpu", "Grafikkarte:");
        t!(es, "lbl_gpu", "Tarjeta gráfica:");
        t!(fr, "lbl_gpu", "Carte graphique :");
        t!(it, "lbl_gpu", "Scheda grafica:");
        t!(ar, "lbl_gpu", "بطاقة الرسوميات:");
        t!(ja, "lbl_gpu", "グラフィックカード:");
        t!(ko, "lbl_gpu", "그래픽 카드:");
        t!(nl, "lbl_gpu", "Grafische kaart:");
        t!(pl, "lbl_gpu", "Karta graficzna:");
        t!(pt, "lbl_gpu", "Placa gráfica:");
        t!(pt_br, "lbl_gpu", "Placa de vídeo:");
        t!(ru, "lbl_gpu", "Видеокарта:");
        t!(uk, "lbl_gpu", "Відеокарта:");
        t!(zh_cn, "lbl_gpu", "显卡：");
        t!(zh_tw, "lbl_gpu", "顯示卡：");

        t!(en, "lbl_display", "Display Server:");
        t!(tr, "lbl_display", "Görüntü Sunucusu:");
        t!(de, "lbl_display", "Anzeigeserver:");
        t!(es, "lbl_display", "Servidor de pantalla:");
        t!(fr, "lbl_display", "Serveur d'affichage :");
        t!(it, "lbl_display", "Server di visualizzazione:");
        t!(ar, "lbl_display", "خادم العرض:");
        t!(ja, "lbl_display", "ディスプレイサーバー:");
        t!(ko, "lbl_display", "디스플레이 서버:");
        t!(nl, "lbl_display", "Weergaveserver:");
        t!(pl, "lbl_display", "Serwer wyświetlania:");
        t!(pt, "lbl_display", "Servidor de ecrã:");
        t!(pt_br, "lbl_display", "Servidor de exibição:");
        t!(ru, "lbl_display", "Сервер отображения:");
        t!(uk, "lbl_display", "Сервер відображення:");
        t!(zh_cn, "lbl_display", "显示服务器：");
        t!(zh_tw, "lbl_display", "顯示伺服器：");

        t!(en, "lbl_temp", "Temp");
        t!(tr, "lbl_temp", "Sıcaklık");
        t!(de, "lbl_temp", "Temp.");
        t!(es, "lbl_temp", "Temp.");
        t!(fr, "lbl_temp", "Temp.");
        t!(it, "lbl_temp", "Temp.");
        t!(ar, "lbl_temp", "الحرارة");
        t!(ja, "lbl_temp", "温度");
        t!(ko, "lbl_temp", "온도");
        t!(nl, "lbl_temp", "Temp.");
        t!(pl, "lbl_temp", "Temp.");
        t!(pt, "lbl_temp", "Temp.");
        t!(pt_br, "lbl_temp", "Temp.");
        t!(ru, "lbl_temp", "Темп.");
        t!(uk, "lbl_temp", "Темп.");
        t!(zh_cn, "lbl_temp", "温度");
        t!(zh_tw, "lbl_temp", "溫度");

        t!(en, "lbl_load", "Load");
        t!(tr, "lbl_load", "Yük");
        t!(de, "lbl_load", "Auslastung");
        t!(es, "lbl_load", "Carga");
        t!(fr, "lbl_load", "Charge");
        t!(it, "lbl_load", "Carico");
        t!(ar, "lbl_load", "الحمل");
        t!(ja, "lbl_load", "負荷");
        t!(ko, "lbl_load", "부하");
        t!(nl, "lbl_load", "Belasting");
        t!(pl, "lbl_load", "Obciążenie");
        t!(pt, "lbl_load", "Carga");
        t!(pt_br, "lbl_load", "Carga");
        t!(ru, "lbl_load", "Нагрузка");
        t!(uk, "lbl_load", "Навантаження");
        t!(zh_cn, "lbl_load", "负载");
        t!(zh_tw, "lbl_load", "負載");

        t!(en, "lbl_mem", "VRAM");
        t!(tr, "lbl_mem", "VRAM");
        t!(de, "lbl_mem", "VRAM");
        t!(es, "lbl_mem", "VRAM");
        t!(fr, "lbl_mem", "VRAM");
        t!(it, "lbl_mem", "VRAM");
        t!(ar, "lbl_mem", "VRAM");
        t!(ja, "lbl_mem", "VRAM");
        t!(ko, "lbl_mem", "VRAM");
        t!(nl, "lbl_mem", "VRAM");
        t!(pl, "lbl_mem", "VRAM");
        t!(pt, "lbl_mem", "VRAM");
        t!(pt_br, "lbl_mem", "VRAM");
        t!(ru, "lbl_mem", "VRAM");
        t!(uk, "lbl_mem", "VRAM");
        t!(zh_cn, "lbl_mem", "显存");
        t!(zh_tw, "lbl_mem", "顯示記憶體");

        t!(en, "lbl_cpu_temp", "CPU Temp");
        t!(tr, "lbl_cpu_temp", "CPU Isısı");
        t!(de, "lbl_cpu_temp", "CPU-Temp.");
        t!(es, "lbl_cpu_temp", "Temp. CPU");
        t!(fr, "lbl_cpu_temp", "Temp. CPU");
        t!(it, "lbl_cpu_temp", "Temp. CPU");
        t!(ar, "lbl_cpu_temp", "حرارة المعالج");
        t!(ja, "lbl_cpu_temp", "CPU温度");
        t!(ko, "lbl_cpu_temp", "CPU 온도");
        t!(nl, "lbl_cpu_temp", "CPU-temp.");
        t!(pl, "lbl_cpu_temp", "Temp. CPU");
        t!(pt, "lbl_cpu_temp", "Temp. CPU");
        t!(pt_br, "lbl_cpu_temp", "Temp. CPU");
        t!(ru, "lbl_cpu_temp", "Темп. CPU");
        t!(uk, "lbl_cpu_temp", "Темп. CPU");
        t!(zh_cn, "lbl_cpu_temp", "CPU 温度");
        t!(zh_tw, "lbl_cpu_temp", "CPU 溫度");

        t!(en, "lbl_cpu_load", "CPU Load");
        t!(tr, "lbl_cpu_load", "CPU Yükü");
        t!(de, "lbl_cpu_load", "CPU-Auslastung");
        t!(es, "lbl_cpu_load", "Carga CPU");
        t!(fr, "lbl_cpu_load", "Charge CPU");
        t!(it, "lbl_cpu_load", "Carico CPU");
        t!(ar, "lbl_cpu_load", "حمل المعالج");
        t!(ja, "lbl_cpu_load", "CPU負荷");
        t!(ko, "lbl_cpu_load", "CPU 부하");
        t!(nl, "lbl_cpu_load", "CPU-belasting");
        t!(pl, "lbl_cpu_load", "Obciążenie CPU");
        t!(pt, "lbl_cpu_load", "Carga CPU");
        t!(pt_br, "lbl_cpu_load", "Carga CPU");
        t!(ru, "lbl_cpu_load", "Нагрузка CPU");
        t!(uk, "lbl_cpu_load", "Навантаження CPU");
        t!(zh_cn, "lbl_cpu_load", "CPU 负载");
        t!(zh_tw, "lbl_cpu_load", "CPU 負載");

        t!(en, "dash_gpu_title", "Live GPU Status");
        t!(tr, "dash_gpu_title", "Canlı GPU Durumu");
        t!(de, "dash_gpu_title", "Live-GPU-Status");
        t!(es, "dash_gpu_title", "Estado de GPU en vivo");
        t!(fr, "dash_gpu_title", "État du GPU en direct");
        t!(it, "dash_gpu_title", "Stato GPU in tempo reale");
        t!(ar, "dash_gpu_title", "حالة GPU مباشرة");
        t!(ja, "dash_gpu_title", "GPUリアルタイム状態");
        t!(ko, "dash_gpu_title", "GPU 실시간 상태");
        t!(nl, "dash_gpu_title", "Live GPU-status");
        t!(pl, "dash_gpu_title", "Status GPU na żywo");
        t!(pt, "dash_gpu_title", "Estado da GPU em tempo real");
        t!(pt_br, "dash_gpu_title", "Status da GPU em tempo real");
        t!(ru, "dash_gpu_title", "Статус GPU в реальном времени");
        t!(uk, "dash_gpu_title", "Стан GPU в реальному часі");
        t!(zh_cn, "dash_gpu_title", "GPU 实时状态");
        t!(zh_tw, "dash_gpu_title", "GPU 即時狀態");

        t!(en, "dash_sys_title", "Live System Usage");
        t!(tr, "dash_sys_title", "Canlı Sistem Kullanımı");
        t!(de, "dash_sys_title", "Live-Systemauslastung");
        t!(es, "dash_sys_title", "Uso del sistema en vivo");
        t!(fr, "dash_sys_title", "Utilisation du système en direct");
        t!(it, "dash_sys_title", "Utilizzo del sistema in tempo reale");
        t!(ar, "dash_sys_title", "استخدام النظام مباشرة");
        t!(ja, "dash_sys_title", "システムリアルタイム使用状況");
        t!(ko, "dash_sys_title", "시스템 실시간 사용량");
        t!(nl, "dash_sys_title", "Live systeemgebruik");
        t!(pl, "dash_sys_title", "Wykorzystanie systemu na żywo");
        t!(pt, "dash_sys_title", "Uso do sistema em tempo real");
        t!(pt_br, "dash_sys_title", "Uso do sistema em tempo real");
        t!(ru, "dash_sys_title", "Использование системы в реальном времени");
        t!(uk, "dash_sys_title", "Використання системи в реальному часі");
        t!(zh_cn, "dash_sys_title", "系统实时使用情况");
        t!(zh_tw, "dash_sys_title", "系統即時使用情況");

        // =====================================================================
        // Tools & Optimization
        // =====================================================================
        t!(en, "tools_title", "Tools & Optimization");
        t!(tr, "tools_title", "Araçlar ve Optimizasyon");
        t!(de, "tools_title", "Werkzeuge & Optimierung");
        t!(es, "tools_title", "Herramientas y optimización");
        t!(fr, "tools_title", "Outils et optimisation");
        t!(it, "tools_title", "Strumenti e ottimizzazione");
        t!(ar, "tools_title", "أدوات وتحسين");
        t!(ja, "tools_title", "ツールと最適化");
        t!(ko, "tools_title", "도구 및 최적화");
        t!(nl, "tools_title", "Hulpmiddelen en optimalisatie");
        t!(pl, "tools_title", "Narzędzia i optymalizacja");
        t!(pt, "tools_title", "Ferramentas e otimização");
        t!(pt_br, "tools_title", "Ferramentas e otimização");
        t!(ru, "tools_title", "Инструменты и оптимизация");
        t!(uk, "tools_title", "Інструменти та оптимізація");
        t!(zh_cn, "tools_title", "工具与优化");
        t!(zh_tw, "tools_title", "工具與最佳化");

        t!(en, "tool_gamemode", "Game Mode (Feral GameMode):");
        t!(tr, "tool_gamemode", "Oyun Modu (Feral GameMode):");
        t!(de, "tool_gamemode", "Spielmodus (Feral GameMode):");
        t!(es, "tool_gamemode", "Modo juego (Feral GameMode):");
        t!(fr, "tool_gamemode", "Mode jeu (Feral GameMode) :");
        t!(it, "tool_gamemode", "Modalità gioco (Feral GameMode):");
        t!(ar, "tool_gamemode", "وضع اللعبة (Feral GameMode):");
        t!(ja, "tool_gamemode", "ゲームモード (Feral GameMode):");
        t!(ko, "tool_gamemode", "게임 모드 (Feral GameMode):");
        t!(nl, "tool_gamemode", "Spelmodus (Feral GameMode):");
        t!(pl, "tool_gamemode", "Tryb gry (Feral GameMode):");
        t!(pt, "tool_gamemode", "Modo jogo (Feral GameMode):");
        t!(pt_br, "tool_gamemode", "Modo jogo (Feral GameMode):");
        t!(ru, "tool_gamemode", "Игровой режим (Feral GameMode):");
        t!(uk, "tool_gamemode", "Ігровий режим (Feral GameMode):");
        t!(zh_cn, "tool_gamemode", "游戏模式 (Feral GameMode)：");
        t!(zh_tw, "tool_gamemode", "遊戲模式 (Feral GameMode)：");

        t!(en, "tool_flatpak", "Flatpak/Steam Permission Fixer:");
        t!(tr, "tool_flatpak", "Flatpak/Steam İzin Onarıcı:");
        t!(de, "tool_flatpak", "Flatpak/Steam-Berechtigungsfix:");
        t!(es, "tool_flatpak", "Corrector de permisos Flatpak/Steam:");
        t!(fr, "tool_flatpak", "Réparateur de permissions Flatpak/Steam :");
        t!(it, "tool_flatpak", "Correttore permessi Flatpak/Steam:");
        t!(ar, "tool_flatpak", "مصلح أذونات Flatpak/Steam:");
        t!(ja, "tool_flatpak", "Flatpak/Steam 権限修復:");
        t!(ko, "tool_flatpak", "Flatpak/Steam 권한 수정:");
        t!(nl, "tool_flatpak", "Flatpak/Steam-machtigingsfixer:");
        t!(pl, "tool_flatpak", "Naprawa uprawnień Flatpak/Steam:");
        t!(pt, "tool_flatpak", "Corretor de permissões Flatpak/Steam:");
        t!(pt_br, "tool_flatpak", "Corretor de permissões Flatpak/Steam:");
        t!(ru, "tool_flatpak", "Исправление разрешений Flatpak/Steam:");
        t!(uk, "tool_flatpak", "Виправлення дозволів Flatpak/Steam:");
        t!(zh_cn, "tool_flatpak", "Flatpak/Steam 权限修复：");
        t!(zh_tw, "tool_flatpak", "Flatpak/Steam 權限修復：");

        // =====================================================================
        // Hybrid / Graphics Mode
        // =====================================================================
        t!(en, "ctrl_title", "Graphics Mode (Hybrid / Mux)");
        t!(tr, "ctrl_title", "Grafik Modu (Hybrid / Mux)");
        t!(de, "ctrl_title", "Grafikmodus (Hybrid / Mux)");
        t!(es, "ctrl_title", "Modo gráfico (Hybrid / Mux)");
        t!(fr, "ctrl_title", "Mode graphique (Hybride / Mux)");
        t!(it, "ctrl_title", "Modalità grafica (Hybrid / Mux)");
        t!(ar, "ctrl_title", "وضع الرسوميات (Hybrid / Mux)");
        t!(ja, "ctrl_title", "グラフィックモード (Hybrid / Mux)");
        t!(ko, "ctrl_title", "그래픽 모드 (Hybrid / Mux)");
        t!(nl, "ctrl_title", "Grafische modus (Hybrid / Mux)");
        t!(pl, "ctrl_title", "Tryb grafiki (Hybrid / Mux)");
        t!(pt, "ctrl_title", "Modo gráfico (Hybrid / Mux)");
        t!(pt_br, "ctrl_title", "Modo gráfico (Hybrid / Mux)");
        t!(ru, "ctrl_title", "Режим графики (Гибрид / Мультиплексор)");
        t!(uk, "ctrl_title", "Режим графіки (Гібрид / Мультиплексор)");
        t!(zh_cn, "ctrl_title", "图形模式 (Hybrid / Mux)");
        t!(zh_tw, "ctrl_title", "圖形模式 (Hybrid / Mux)");

        t!(en, "mode_perf", "Performance (NVIDIA)");
        t!(tr, "mode_perf", "Performans (NVIDIA)");
        t!(de, "mode_perf", "Leistung (NVIDIA)");
        t!(es, "mode_perf", "Rendimiento (NVIDIA)");
        t!(fr, "mode_perf", "Performance (NVIDIA)");
        t!(it, "mode_perf", "Prestazioni (NVIDIA)");
        t!(ar, "mode_perf", "الأداء (NVIDIA)");
        t!(ja, "mode_perf", "パフォーマンス (NVIDIA)");
        t!(ko, "mode_perf", "성능 (NVIDIA)");
        t!(nl, "mode_perf", "Prestaties (NVIDIA)");
        t!(pl, "mode_perf", "Wydajność (NVIDIA)");
        t!(pt, "mode_perf", "Desempenho (NVIDIA)");
        t!(pt_br, "mode_perf", "Desempenho (NVIDIA)");
        t!(ru, "mode_perf", "Производительность (NVIDIA)");
        t!(uk, "mode_perf", "Продуктивність (NVIDIA)");
        t!(zh_cn, "mode_perf", "性能模式 (NVIDIA)");
        t!(zh_tw, "mode_perf", "效能模式 (NVIDIA)");

        t!(en, "mode_save", "Power Saving (Intel)");
        t!(tr, "mode_save", "Güç Tasarrufu (Intel)");
        t!(de, "mode_save", "Energiesparmodus (Intel)");
        t!(es, "mode_save", "Ahorro de energía (Intel)");
        t!(fr, "mode_save", "Économie d'énergie (Intel)");
        t!(it, "mode_save", "Risparmio energetico (Intel)");
        t!(ar, "mode_save", "توفير الطاقة (Intel)");
        t!(ja, "mode_save", "省電力 (Intel)");
        t!(ko, "mode_save", "절전 (Intel)");
        t!(nl, "mode_save", "Energiebesparing (Intel)");
        t!(pl, "mode_save", "Oszczędzanie energii (Intel)");
        t!(pt, "mode_save", "Poupança de energia (Intel)");
        t!(pt_br, "mode_save", "Economia de energia (Intel)");
        t!(ru, "mode_save", "Энергосбережение (Intel)");
        t!(uk, "mode_save", "Енергозбереження (Intel)");
        t!(zh_cn, "mode_save", "省电模式 (Intel)");
        t!(zh_tw, "mode_save", "省電模式 (Intel)");

        t!(en, "mode_balanced", "Balanced (On-Demand)");
        t!(tr, "mode_balanced", "Dengeli (İsteğe Bağlı)");
        t!(de, "mode_balanced", "Ausgewogen (Bei Bedarf)");
        t!(es, "mode_balanced", "Equilibrado (Bajo demanda)");
        t!(fr, "mode_balanced", "Équilibré (À la demande)");
        t!(it, "mode_balanced", "Bilanciato (Su richiesta)");
        t!(ar, "mode_balanced", "متوازن (عند الطلب)");
        t!(ja, "mode_balanced", "バランス (オンデマンド)");
        t!(ko, "mode_balanced", "균형 (온디맨드)");
        t!(nl, "mode_balanced", "Gebalanceerd (Op aanvraag)");
        t!(pl, "mode_balanced", "Zrównoważony (Na żądanie)");
        t!(pt, "mode_balanced", "Equilibrado (Sob demanda)");
        t!(pt_br, "mode_balanced", "Equilibrado (Sob demanda)");
        t!(ru, "mode_balanced", "Сбалансированный (По запросу)");
        t!(uk, "mode_balanced", "Збалансований (За запитом)");
        t!(zh_cn, "mode_balanced", "平衡模式 (按需)");
        t!(zh_tw, "mode_balanced", "平衡模式 (按需)");

        // =====================================================================
        // Theme
        // =====================================================================
        t!(en, "tooltip_theme_system", "Theme: System");
        t!(tr, "tooltip_theme_system", "Tema: Sistem");
        t!(de, "tooltip_theme_system", "Thema: System");
        t!(es, "tooltip_theme_system", "Tema: Sistema");
        t!(fr, "tooltip_theme_system", "Thème : Système");
        t!(it, "tooltip_theme_system", "Tema: Sistema");
        t!(ar, "tooltip_theme_system", "السمة: النظام");
        t!(ja, "tooltip_theme_system", "テーマ：システム");
        t!(ko, "tooltip_theme_system", "테마: 시스템");
        t!(nl, "tooltip_theme_system", "Thema: Systeem");
        t!(pl, "tooltip_theme_system", "Motyw: Systemowy");
        t!(pt, "tooltip_theme_system", "Tema: Sistema");
        t!(pt_br, "tooltip_theme_system", "Tema: Sistema");
        t!(ru, "tooltip_theme_system", "Тема: Системная");
        t!(uk, "tooltip_theme_system", "Тема: Системна");
        t!(zh_cn, "tooltip_theme_system", "主题：跟随系统");
        t!(zh_tw, "tooltip_theme_system", "主題：跟隨系統");

        t!(en, "tooltip_theme_dark", "Theme: Dark");
        t!(tr, "tooltip_theme_dark", "Tema: Koyu");
        t!(de, "tooltip_theme_dark", "Thema: Dunkel");
        t!(es, "tooltip_theme_dark", "Tema: Oscuro");
        t!(fr, "tooltip_theme_dark", "Thème : Sombre");
        t!(it, "tooltip_theme_dark", "Tema: Scuro");
        t!(ar, "tooltip_theme_dark", "السمة: داكنة");
        t!(ja, "tooltip_theme_dark", "テーマ：ダーク");
        t!(ko, "tooltip_theme_dark", "테마: 다크");
        t!(nl, "tooltip_theme_dark", "Thema: Donker");
        t!(pl, "tooltip_theme_dark", "Motyw: Ciemny");
        t!(pt, "tooltip_theme_dark", "Tema: Escuro");
        t!(pt_br, "tooltip_theme_dark", "Tema: Escuro");
        t!(ru, "tooltip_theme_dark", "Тема: Тёмная");
        t!(uk, "tooltip_theme_dark", "Тема: Темна");
        t!(zh_cn, "tooltip_theme_dark", "主题：深色");
        t!(zh_tw, "tooltip_theme_dark", "主題：深色");

        t!(en, "tooltip_theme_light", "Theme: Light");
        t!(tr, "tooltip_theme_light", "Tema: Açık");
        t!(de, "tooltip_theme_light", "Thema: Hell");
        t!(es, "tooltip_theme_light", "Tema: Claro");
        t!(fr, "tooltip_theme_light", "Thème : Clair");
        t!(it, "tooltip_theme_light", "Tema: Chiaro");
        t!(ar, "tooltip_theme_light", "السمة: فاتحة");
        t!(ja, "tooltip_theme_light", "テーマ：ライト");
        t!(ko, "tooltip_theme_light", "테마: 라이트");
        t!(nl, "tooltip_theme_light", "Thema: Licht");
        t!(pl, "tooltip_theme_light", "Motyw: Jasny");
        t!(pt, "tooltip_theme_light", "Tema: Claro");
        t!(pt_br, "tooltip_theme_light", "Tema: Claro");
        t!(ru, "tooltip_theme_light", "Тема: Светлая");
        t!(uk, "tooltip_theme_light", "Тема: Світла");
        t!(zh_cn, "tooltip_theme_light", "主题：浅色");
        t!(zh_tw, "tooltip_theme_light", "主題：淺色");

        // =====================================================================
        // EULA
        // =====================================================================
        t!(en, "eula_title", "License Agreement (EULA)");
        t!(tr, "eula_title", "Lisans Sözleşmesi (EULA)");
        t!(de, "eula_title", "Lizenzvereinbarung (EULA)");
        t!(es, "eula_title", "Acuerdo de licencia (EULA)");
        t!(fr, "eula_title", "Contrat de licence (EULA)");
        t!(it, "eula_title", "Contratto di licenza (EULA)");
        t!(ar, "eula_title", "اتفاقية الترخيص (EULA)");
        t!(ja, "eula_title", "使用許諾契約 (EULA)");
        t!(ko, "eula_title", "라이선스 계약 (EULA)");
        t!(nl, "eula_title", "Licentieovereenkomst (EULA)");
        t!(pl, "eula_title", "Umowa licencyjna (EULA)");
        t!(pt, "eula_title", "Acordo de licença (EULA)");
        t!(pt_br, "eula_title", "Acordo de licença (EULA)");
        t!(ru, "eula_title", "Лицензионное соглашение (EULA)");
        t!(uk, "eula_title", "Ліцензійна угода (EULA)");
        t!(zh_cn, "eula_title", "许可协议 (EULA)");
        t!(zh_tw, "eula_title", "授權合約 (EULA)");

        t!(en, "eula_desc", "By installing the NVIDIA Proprietary driver, you agree to the NVIDIA EULA.");
        t!(tr, "eula_desc", "NVIDIA Kapalı Kaynak sürücüsünü kurarak NVIDIA EULA'yı kabul etmiş olursunuz.");
        t!(de, "eula_desc", "Durch die Installation des proprietären NVIDIA-Treibers stimmen Sie der NVIDIA-EULA zu.");
        t!(es, "eula_desc", "Al instalar el controlador propietario de NVIDIA, acepta el EULA de NVIDIA.");
        t!(fr, "eula_desc", "En installant le pilote propriétaire NVIDIA, vous acceptez le CLUF NVIDIA.");
        t!(it, "eula_desc", "Installando il driver proprietario NVIDIA, accetti l'EULA di NVIDIA.");
        t!(ar, "eula_desc", "بتثبيت برنامج تشغيل NVIDIA الاحتكاري، فإنك توافق على اتفاقية EULA الخاصة بـ NVIDIA.");
        t!(ja, "eula_desc", "NVIDIAプロプライエタリドライバーをインストールすると、NVIDIA EULAに同意したことになります。");
        t!(ko, "eula_desc", "NVIDIA 독점 드라이버를 설치하면 NVIDIA EULA에 동의하는 것입니다.");
        t!(nl, "eula_desc", "Door de NVIDIA-proprietaire driver te installeren, gaat u akkoord met de NVIDIA EULA.");
        t!(pl, "eula_desc", "Instalując sterownik własnościowy NVIDIA, zgadzasz się z umową EULA NVIDIA.");
        t!(pt, "eula_desc", "Ao instalar o driver proprietário da NVIDIA, concorda com o EULA da NVIDIA.");
        t!(pt_br, "eula_desc", "Ao instalar o driver proprietário da NVIDIA, você concorda com o EULA da NVIDIA.");
        t!(ru, "eula_desc", "Устанавливая проприетарный драйвер NVIDIA, вы соглашаетесь с EULA NVIDIA.");
        t!(uk, "eula_desc", "Встановлюючи пропрієтарний драйвер NVIDIA, ви погоджуєтесь з EULA NVIDIA.");
        t!(zh_cn, "eula_desc", "安装 NVIDIA 专有驱动程序即表示您同意 NVIDIA EULA。");
        t!(zh_tw, "eula_desc", "安裝 NVIDIA 專有驅動程式即表示您同意 NVIDIA EULA。");

        // =====================================================================
        // About
        // =====================================================================
        t!(en, "about_title", "About");
        t!(tr, "about_title", "Hakkında");
        t!(de, "about_title", "Über");
        t!(es, "about_title", "Acerca de");
        t!(fr, "about_title", "À propos");
        t!(it, "about_title", "Informazioni");
        t!(ar, "about_title", "حول");
        t!(ja, "about_title", "このアプリについて");
        t!(ko, "about_title", "정보");
        t!(nl, "about_title", "Over");
        t!(pl, "about_title", "O programie");
        t!(pt, "about_title", "Sobre");
        t!(pt_br, "about_title", "Sobre");
        t!(ru, "about_title", "О программе");
        t!(uk, "about_title", "Про програму");
        t!(zh_cn, "about_title", "关于");
        t!(zh_tw, "about_title", "關於");

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

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn parse_turkish() {
        assert_eq!(parse_locale("tr_TR.UTF-8"), Lang::Tr);
        assert_eq!(parse_locale("TR_TR"), Lang::Tr);
    }

    #[test]
    fn parse_english_fallback() {
        assert_eq!(parse_locale("en_US.UTF-8"), Lang::En);
        assert_eq!(parse_locale(""), Lang::En);
    }

    #[test]
    fn parse_unknown_falls_back_to_english() {
        assert_eq!(parse_locale("xx_XX.UTF-8"), Lang::En);
    }

    #[test]
    fn parse_portuguese_brazil() {
        assert_eq!(parse_locale("pt_BR.UTF-8"), Lang::PtBr);
    }

    #[test]
    fn parse_chinese_variants() {
        assert_eq!(parse_locale("zh_CN.UTF-8"), Lang::ZhCn);
        assert_eq!(parse_locale("zh_TW.UTF-8"), Lang::ZhTw);
        assert_eq!(parse_locale("zh_Hant"), Lang::ZhTw);
    }

    #[test]
    fn dictionary_has_english_keys() {
        let dict = get_dictionary();
        assert!(dict.en.contains_key("title_main"));
        assert!(dict.en.contains_key("desc_main"));
    }

    #[test]
    fn dictionary_has_turkish_translations() {
        let dict = get_dictionary();
        let tr_map = dict
            .langs
            .get(&Lang::Tr)
            .expect("Turkish translations missing");
        assert!(tr_map.contains_key("title_main"));
    }

    #[test]
    fn unknown_key_returns_fallback() {
        // Ensure dictionary is initialized with English
        let _ = LANG.set(Lang::En);
        let result = tr("this_key_does_not_exist_xyz");
        assert_eq!(result, "???");
    }
}
