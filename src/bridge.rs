// cxx-qt bridge — exposes Rust backend to QML as QObjects
//
// GpuController: GPU detection, driver install/remove actions
// PerfMonitor:   Live GPU/CPU/RAM stats (called by QML timer)

use cxx_qt::Threading;
use std::pin::Pin;
use std::sync::atomic::{AtomicBool, Ordering};

#[cxx_qt::bridge]
pub mod ffi {
    unsafe extern "C++" {
        include!("cxx-qt-lib/qstring.h");
        type QString = cxx_qt_lib::QString;
    }

    // ─── GpuController ─────────────────────────────────────────

    extern "RustQt" {
        #[qobject]
        #[qml_element]
        #[qproperty(QString, gpu_vendor)]
        #[qproperty(QString, gpu_model)]
        #[qproperty(QString, driver_in_use)]
        #[qproperty(QString, driver_version)]
        #[qproperty(bool, secure_boot)]
        #[qproperty(bool, is_installing)]
        #[qproperty(bool, has_internet)]
        #[qproperty(bool, is_up_to_date)]
        #[qproperty(QString, best_version)]
        #[qproperty(QString, current_status)]
        #[qproperty(i32, install_progress)]
        #[qproperty(QString, install_log)]
        #[qproperty(bool, is_detecting)]
        #[qproperty(QString, available_versions)]
        #[qproperty(QString, official_versions_json)]
        #[qproperty(QString, app_version)]
        #[qproperty(bool, app_update_available)]
        #[qproperty(QString, app_latest_version)]
        #[qproperty(QString, app_download_url)]
        #[qproperty(QString, app_release_notes)]
        type GpuController = super::GpuControllerRust;

        /// Detect GPU and populate properties (async — runs in background thread)
        #[qinvokable]
        fn detect_gpu(self: Pin<&mut GpuController>);

        /// Get list of available NVIDIA driver versions (returns comma-separated)
        #[qinvokable]
        fn get_available_versions(self: Pin<&mut GpuController>) -> QString;

        /// Get official version list with short changelog notes as JSON array (returns cached)
        #[qinvokable]
        fn get_official_versions_with_changes(self: Pin<&mut GpuController>) -> QString;

        /// Load official version list with changelog (async, populates official_versions_json property)
        #[qinvokable]
        fn load_official_versions(self: Pin<&mut GpuController>);

        /// Check if a specific version is compatible with the current kernel
        #[qinvokable]
        fn is_version_compatible(self: Pin<&mut GpuController>, version: &QString) -> bool;

        /// Express install (best compatible version)
        #[qinvokable]
        fn install_express(self: Pin<&mut GpuController>, use_open_kernel: bool);

        /// Custom install (specific version + kernel module type)
        #[qinvokable]
        fn install_custom(self: Pin<&mut GpuController>, version: &QString, use_open_kernel: bool);

        /// Remove all NVIDIA drivers and reset
        #[qinvokable]
        fn remove_drivers(self: Pin<&mut GpuController>, deep_clean: bool);

        /// Check network connectivity
        #[qinvokable]
        fn check_network(self: Pin<&mut GpuController>);

        /// Reboot the system
        #[qinvokable]
        fn reboot_system(self: Pin<&mut GpuController>);

        /// Check for application updates on GitHub
        #[qinvokable]
        fn check_app_update(self: Pin<&mut GpuController>);

        /// Download and install the application update
        #[qinvokable]
        fn install_app_update(self: Pin<&mut GpuController>);
    }

    impl cxx_qt::Threading for GpuController {}
    impl cxx_qt::Threading for PerfMonitor {}

    // ─── PerfMonitor ────────────────────────────────────────────

    extern "RustQt" {
        #[qobject]
        #[qml_element]
        #[qproperty(u32, gpu_temp)]
        #[qproperty(u32, gpu_load)]
        #[qproperty(u32, gpu_mem_used)]
        #[qproperty(u32, gpu_mem_total)]
        #[qproperty(u32, cpu_load)]
        #[qproperty(u32, cpu_temp)]
        #[qproperty(u32, ram_used)]
        #[qproperty(u32, ram_total)]
        #[qproperty(u32, ram_percent)]
        #[qproperty(QString, distro)]
        #[qproperty(QString, kernel)]
        #[qproperty(QString, cpu_name)]
        #[qproperty(QString, ram_info)]
        #[qproperty(QString, gpu_full_name)]
        #[qproperty(QString, display_server)]
        type PerfMonitor = super::PerfMonitorRust;

        /// Refresh live stats (called by QML Timer every 2s)
        #[qinvokable]
        fn refresh(self: Pin<&mut PerfMonitor>);

        /// Load static system info (called once on page load)
        #[qinvokable]
        fn load_system_info(self: Pin<&mut PerfMonitor>);
    }
}

// ─── GpuController Implementation ──────────────────────────────

use cxx_qt_lib::QString;

/// Rust-side data for GpuController QObject
#[derive(Default)]
pub struct GpuControllerRust {
    gpu_vendor: QString,
    gpu_model: QString,
    driver_in_use: QString,
    driver_version: QString,
    secure_boot: bool,
    is_installing: bool,
    has_internet: bool,
    is_up_to_date: bool,
    is_detecting: bool,
    best_version: QString,
    current_status: QString,
    install_progress: i32,
    install_log: QString,
    available_versions: QString,
    official_versions_json: QString,
    app_version: QString,
    app_update_available: bool,
    app_latest_version: QString,
    app_download_url: QString,
    app_release_notes: QString,
}

impl ffi::GpuController {
    fn detect_gpu(mut self: Pin<&mut Self>) {
        if *self.is_detecting() {
            return;
        }
        self.as_mut().set_is_detecting(true);
        self.as_mut().set_current_status(QString::from("detecting"));
        // Set app version from Cargo.toml on first run
        if self.as_ref().app_version().is_empty() {
            self.as_mut()
                .set_app_version(QString::from(crate::config::VERSION));
        }

        let qt_thread = self.as_ref().qt_thread();

        std::thread::spawn(move || {
            use crate::core::detector;

            let info = detector::detect_gpu();
            let versions = detector::get_available_nvidia_versions();
            let best = versions.first().cloned().unwrap_or_default();

            // Get installed NVIDIA driver version (from modinfo or nvidia-smi)
            let installed_version = crate::utils::command::run("modinfo -F version nvidia")
                .or_else(|| {
                    crate::utils::command::run(
                        "nvidia-smi --query-gpu=driver_version --format=csv,noheader",
                    )
                })
                .unwrap_or_default()
                .trim()
                .to_string();

            let up_to_date =
                !best.is_empty() && !installed_version.is_empty() && installed_version == best;
            let versions_str = versions.join(",");

            log::info!(
                "GPU detected: {} {} (driver: {}, version: {})",
                info.vendor,
                info.model,
                info.driver_in_use,
                if installed_version.is_empty() {
                    "N/A"
                } else {
                    &installed_version
                }
            );

            let _ = qt_thread.queue(move |mut qobject: Pin<&mut ffi::GpuController>| {
                qobject.as_mut().set_gpu_vendor(QString::from(&info.vendor));
                qobject.as_mut().set_gpu_model(QString::from(&info.model));
                qobject
                    .as_mut()
                    .set_driver_in_use(QString::from(&info.driver_in_use));
                qobject
                    .as_mut()
                    .set_driver_version(QString::from(&installed_version));
                qobject.as_mut().set_secure_boot(info.secure_boot);
                qobject.as_mut().set_best_version(QString::from(&best));
                qobject.as_mut().set_is_up_to_date(up_to_date);
                qobject
                    .as_mut()
                    .set_available_versions(QString::from(&versions_str));
                qobject.as_mut().set_current_status(QString::from("ready"));
                qobject.as_mut().set_is_detecting(false);
            });
        });
    }

    fn get_available_versions(self: Pin<&mut Self>) -> QString {
        self.available_versions().clone()
    }

    fn get_official_versions_with_changes(self: Pin<&mut Self>) -> QString {
        self.official_versions_json().clone()
    }

    fn load_official_versions(self: Pin<&mut Self>) {
        let qt_thread = self.as_ref().qt_thread();

        std::thread::spawn(move || {
            use crate::core::detector;

            // Fetch merged versions: internet (latest official) + local repo (installable)
            let merged = detector::get_merged_nvidia_versions();

            let payload: Vec<serde_json::Value> = merged
                .into_iter()
                .map(|dv| {
                    serde_json::json!({
                        "version": dv.version,
                        "changes": dv.release_notes,
                        "is_latest": dv.is_latest,
                        "source": dv.source,
                        "installable": dv.installable
                    })
                })
                .collect();

            let json = serde_json::to_string(&payload).unwrap_or_else(|_| "[]".to_string());

            let _ = qt_thread.queue(move |mut qobject: Pin<&mut ffi::GpuController>| {
                qobject
                    .as_mut()
                    .set_official_versions_json(QString::from(&json));
            });
        });
    }

    fn is_version_compatible(self: Pin<&mut Self>, version: &QString) -> bool {
        let ver = version.to_string();
        // NVIDIA 545+ requires kernel ≥ 6.0
        // NVIDIA 525+ requires kernel ≥ 5.10
        // Older versions are broadly compatible
        let kernel_str = std::fs::read_to_string("/proc/version")
            .ok()
            .or_else(|| crate::utils::command::run("uname -r"));
        if let Some(kernel_str) = kernel_str {
            let kernel_parts: Vec<u32> = kernel_str
                .split(|c: char| !c.is_ascii_digit())
                .filter_map(|s| s.parse().ok())
                .take(2)
                .collect();
            let (kmajor, kminor) = (
                kernel_parts.first().copied().unwrap_or(0),
                kernel_parts.get(1).copied().unwrap_or(0),
            );
            let driver_major: u32 = ver
                .split('.')
                .next()
                .and_then(|s| s.parse().ok())
                .unwrap_or(0);

            if driver_major >= 545 && (kmajor < 6) {
                log::warn!(
                    "Driver {} requires kernel ≥ 6.0, current: {}.{}",
                    ver,
                    kmajor,
                    kminor
                );
                return false;
            }
            if driver_major >= 525 && (kmajor < 5 || (kmajor == 5 && kminor < 10)) {
                log::warn!(
                    "Driver {} requires kernel ≥ 5.10, current: {}.{}",
                    ver,
                    kmajor,
                    kminor
                );
                return false;
            }
        }
        true
    }

    fn install_express(mut self: Pin<&mut Self>, use_open_kernel: bool) {
        if *self.is_installing() {
            return;
        }

        let kernel_type = if use_open_kernel {
            "Open Kernel"
        } else {
            "Proprietary"
        };
        self.as_mut().set_is_installing(true);
        self.as_mut().set_install_progress(0);
        self.as_mut().set_install_log(QString::from(&format!(
            "Starting express installation ({})...\n",
            kernel_type
        )));
        self.as_mut()
            .set_current_status(QString::from("installing"));

        // Capture Qt thread handle to update UI from background thread
        let qt_thread = self.as_ref().qt_thread();

        std::thread::spawn(move || {
            use crate::core::installer::DriverInstaller;

            let mut installer = DriverInstaller::new();

            // Setup callback to update UI log
            let qt_thread_cb = qt_thread.clone();
            installer.set_log_callback(Box::new(move |msg| {
                let msg = String::from(msg);
                let _ = qt_thread_cb.queue(move |mut qobject: Pin<&mut ffi::GpuController>| {
                    let old_log = qobject.as_ref().install_log().to_string();
                    let new_log = format!("{}{}\n", old_log, msg);
                    qobject.as_mut().set_install_log(QString::from(&new_log));

                    // Fake progress increment for visual feedback
                    let current = *qobject.install_progress();
                    if current < 90 {
                        qobject.as_mut().set_install_progress(current + 5);
                    }
                });
            }));

            let success = if use_open_kernel {
                installer.install_nvidia_open()
            } else {
                installer.install_nvidia_closed()
            };

            // Final UI update
            let _ = qt_thread.queue(move |mut qobject: Pin<&mut ffi::GpuController>| {
                qobject.as_mut().set_is_installing(false);
                qobject
                    .as_mut()
                    .set_install_progress(if success { 100 } else { 0 });
                qobject
                    .as_mut()
                    .set_current_status(QString::from(if success { "complete" } else { "failed" }));
                let status_msg = if success {
                    "Installation completed successfully.\nPlease REBOOT your system."
                } else {
                    "Installation FAILED.\nCheck logs for details."
                };
                let old_log = qobject.as_ref().install_log().to_string();
                qobject
                    .as_mut()
                    .set_install_log(QString::from(&format!("{}\n\n{}", old_log, status_msg)));
            });
        });

        log::info!("Express install thread started");
    }

    fn install_custom(mut self: Pin<&mut Self>, version: &QString, use_open_kernel: bool) {
        if *self.is_installing() {
            return;
        }

        let version_str = version.to_string();
        let version_for_log = version_str.clone();
        self.as_mut().set_is_installing(true);
        self.as_mut().set_install_progress(0);
        let msg = format!(
            "Starting custom installation (v{}, OpenKernel: {})...\n",
            version_str, use_open_kernel
        );
        self.as_mut().set_install_log(QString::from(&msg));
        self.as_mut()
            .set_current_status(QString::from("installing"));

        let qt_thread = self.as_ref().qt_thread();

        std::thread::spawn(move || {
            use crate::core::installer::DriverInstaller;
            let mut installer = DriverInstaller::new();

            let qt_thread_cb = qt_thread.clone();
            installer.set_log_callback(Box::new(move |msg| {
                let msg = String::from(msg);
                let _ = qt_thread_cb.queue(move |mut qobject: Pin<&mut ffi::GpuController>| {
                    let old_log = qobject.as_ref().install_log().to_string();
                    qobject
                        .as_mut()
                        .set_install_log(QString::from(&format!("{}{}\n", old_log, msg)));

                    let current = *qobject.install_progress();
                    if current < 90 {
                        qobject.as_mut().set_install_progress(current + 2);
                    }
                });
            }));

            // Pin to selected version via versioned installer methods
            let ver = if version_str.is_empty() {
                None
            } else {
                Some(version_str.as_str())
            };
            let success = if use_open_kernel {
                installer.install_nvidia_open_versioned(ver)
            } else {
                installer.install_nvidia_closed_versioned(ver)
            };

            let _ = qt_thread.queue(move |mut qobject: Pin<&mut ffi::GpuController>| {
                qobject.as_mut().set_is_installing(false);
                qobject
                    .as_mut()
                    .set_install_progress(if success { 100 } else { 0 });
                qobject
                    .as_mut()
                    .set_current_status(QString::from(if success { "complete" } else { "failed" }));

                let result_msg = if success {
                    format!("v{} installation complete. REBOOT required.", version_str)
                } else {
                    "Installation failed.".to_string()
                };

                let old_log = qobject.as_ref().install_log().to_string();
                qobject
                    .as_mut()
                    .set_install_log(QString::from(&format!("{}\n\n{}", old_log, result_msg)));
            });
        });

        log::info!("Custom install thread started: {}", version_for_log);
    }

    fn remove_drivers(mut self: Pin<&mut Self>, deep_clean: bool) {
        if *self.is_installing() {
            return;
        }

        self.as_mut().set_is_installing(true);
        self.as_mut().set_install_progress(0);
        let msg = if deep_clean {
            "Removing drivers with deep clean...\n"
        } else {
            "Removing drivers...\n"
        };
        self.as_mut().set_install_log(QString::from(msg));
        self.as_mut().set_current_status(QString::from("removing"));

        let qt_thread = self.as_ref().qt_thread();

        std::thread::spawn(move || {
            use crate::core::installer::DriverInstaller;
            let mut installer = DriverInstaller::new();

            let qt_thread_cb = qt_thread.clone();
            installer.set_log_callback(Box::new(move |msg| {
                let msg = String::from(msg);
                let _ = qt_thread_cb.queue(move |mut qobject: Pin<&mut ffi::GpuController>| {
                    let old_log = qobject.as_ref().install_log().to_string();
                    qobject
                        .as_mut()
                        .set_install_log(QString::from(&format!("{}{}\n", old_log, msg)));

                    let current = *qobject.install_progress();
                    if current < 90 {
                        qobject.as_mut().set_install_progress(current + 10);
                    }
                });
            }));

            let success = installer.remove_nvidia(deep_clean);

            let _ = qt_thread.queue(move |mut qobject: Pin<&mut ffi::GpuController>| {
                qobject.as_mut().set_is_installing(false);
                qobject
                    .as_mut()
                    .set_install_progress(if success { 100 } else { 0 });
                qobject
                    .as_mut()
                    .set_current_status(QString::from(if success { "complete" } else { "failed" }));
                let status_msg = if success {
                    "Removal complete. Reboot to nouveau."
                } else {
                    "Removal failed."
                };
                let old_log = qobject.as_ref().install_log().to_string();
                qobject
                    .as_mut()
                    .set_install_log(QString::from(&format!("{}\n\n{}", old_log, status_msg)));
            });
        });

        log::info!("Remove drivers thread started (deep_clean: {})", deep_clean);
    }

    fn check_network(self: Pin<&mut Self>) {
        let qt_thread = self.as_ref().qt_thread();

        std::thread::spawn(move || {
            use std::net::{IpAddr, Ipv4Addr, SocketAddr, TcpStream};
            use std::time::Duration;

            let dns_addr = SocketAddr::new(IpAddr::V4(Ipv4Addr::new(8, 8, 8, 8)), 53);
            let connected = TcpStream::connect_timeout(&dns_addr, Duration::from_secs(3)).is_ok();

            let _ = qt_thread.queue(move |mut qobject: Pin<&mut ffi::GpuController>| {
                qobject.as_mut().set_has_internet(connected);
            });
        });
    }

    fn reboot_system(self: Pin<&mut Self>) {
        log::info!("Reboot requested by user");
        std::thread::spawn(move || {
            // systemctl reboot does not need pkexec; it uses logind
            let _ = std::process::Command::new("systemctl")
                .arg("reboot")
                .spawn();
        });
    }

    fn check_app_update(self: Pin<&mut Self>) {
        let qt_thread = self.as_ref().qt_thread();

        std::thread::spawn(move || {
            use crate::core::updater;

            log::info!("Checking for application updates...");
            let info = updater::check_for_updates();

            let _ = qt_thread.queue(move |mut qobject: Pin<&mut ffi::GpuController>| {
                qobject.as_mut().set_app_update_available(info.has_update);
                qobject
                    .as_mut()
                    .set_app_latest_version(QString::from(&info.version));
                qobject
                    .as_mut()
                    .set_app_download_url(QString::from(&info.download_url.unwrap_or_default()));
                qobject
                    .as_mut()
                    .set_app_release_notes(QString::from(&info.release_notes));
                if info.has_update {
                    log::info!("Update available: v{}", info.version);
                } else {
                    log::info!("Application is up to date.");
                }
            });
        });
    }

    fn install_app_update(mut self: Pin<&mut Self>) {
        let url = self.as_ref().app_download_url().to_string();
        if url.is_empty() {
            log::warn!("No download URL for app update");
            return;
        }

        self.as_mut()
            .set_current_status(QString::from("updating_app"));
        let qt_thread = self.as_ref().qt_thread();

        std::thread::spawn(move || {
            use crate::core::updater;

            log::info!("Installing application update from: {}", url);
            let success = updater::download_and_install(&url);

            let _ = qt_thread.queue(move |mut qobject: Pin<&mut ffi::GpuController>| {
                if success {
                    qobject
                        .as_mut()
                        .set_current_status(QString::from("update_installed"));
                    log::info!("App update installed. Restart required.");
                } else {
                    qobject
                        .as_mut()
                        .set_current_status(QString::from("update_failed"));
                    log::error!("App update failed.");
                }
            });
        });
    }
}

// ─── PerfMonitor Implementation ─────────────────────────────────

/// Rust-side data for PerfMonitor QObject
#[derive(Default)]
pub struct PerfMonitorRust {
    gpu_temp: u32,
    gpu_load: u32,
    gpu_mem_used: u32,
    gpu_mem_total: u32,
    cpu_load: u32,
    cpu_temp: u32,
    ram_used: u32,
    ram_total: u32,
    ram_percent: u32,
    distro: QString,
    kernel: QString,
    cpu_name: QString,
    ram_info: QString,
    gpu_full_name: QString,
    display_server: QString,
}

/// Guard to prevent overlapping refresh calls from piling up threads
static REFRESH_IN_PROGRESS: AtomicBool = AtomicBool::new(false);

impl ffi::PerfMonitor {
    fn refresh(self: Pin<&mut Self>) {
        // Skip if previous refresh is still in-flight
        if REFRESH_IN_PROGRESS.swap(true, Ordering::SeqCst) {
            return;
        }

        let qt_thread = self.as_ref().qt_thread();

        std::thread::spawn(move || {
            use crate::core::tweaks;

            let gpu = tweaks::get_gpu_stats();
            let sys = tweaks::get_system_stats();

            let _ = qt_thread.queue(move |mut qobject: Pin<&mut ffi::PerfMonitor>| {
                qobject.as_mut().set_gpu_temp(gpu.temp);
                qobject.as_mut().set_gpu_load(gpu.load);
                qobject.as_mut().set_gpu_mem_used(gpu.mem_used);
                qobject.as_mut().set_gpu_mem_total(gpu.mem_total);
                qobject.as_mut().set_cpu_load(sys.cpu_load);
                qobject.as_mut().set_cpu_temp(sys.cpu_temp);
                qobject.as_mut().set_ram_used(sys.ram_used);
                qobject.as_mut().set_ram_total(sys.ram_total);
                qobject.as_mut().set_ram_percent(sys.ram_percent);
                REFRESH_IN_PROGRESS.store(false, Ordering::SeqCst);
            });
        });
    }

    fn load_system_info(self: Pin<&mut Self>) {
        let qt_thread = self.as_ref().qt_thread();

        std::thread::spawn(move || {
            use crate::core::detector;

            let info = detector::get_full_system_info();
            let gpu_name = format!("{} {}", info.gpu.vendor, info.gpu.model);

            let _ = qt_thread.queue(move |mut qobject: Pin<&mut ffi::PerfMonitor>| {
                qobject.as_mut().set_distro(QString::from(&info.distro));
                qobject.as_mut().set_kernel(QString::from(&info.kernel));
                qobject.as_mut().set_cpu_name(QString::from(&info.cpu));
                qobject.as_mut().set_ram_info(QString::from(&info.ram));
                qobject.as_mut().set_gpu_full_name(QString::from(&gpu_name));
                qobject
                    .as_mut()
                    .set_display_server(QString::from(&info.display_server));
            });
        });
    }
}
