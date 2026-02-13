// cxx-qt bridge — exposes Rust backend to QML as QObjects
//
// GpuController: GPU detection, driver install/remove actions
// PerfMonitor:   Live GPU/CPU/RAM stats (called by QML timer)

use cxx_qt::Threading;
use std::pin::Pin;

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
        type GpuController = super::GpuControllerRust;

        /// Detect GPU and populate properties
        #[qinvokable]
        fn detect_gpu(self: Pin<&mut GpuController>);

        /// Get list of available NVIDIA driver versions (returns comma-separated)
        #[qinvokable]
        fn get_available_versions(self: Pin<&mut GpuController>) -> QString;

        /// Check if a specific version is compatible with the current kernel
        #[qinvokable]
        fn is_version_compatible(self: Pin<&mut GpuController>, version: &QString) -> bool;

        /// Express install (best compatible version)
        #[qinvokable]
        fn install_express(self: Pin<&mut GpuController>);

        /// Custom install (specific version + kernel module type)
        #[qinvokable]
        fn install_custom(self: Pin<&mut GpuController>, version: &QString, use_open_kernel: bool);

        /// Remove all NVIDIA drivers and reset
        #[qinvokable]
        fn remove_drivers(self: Pin<&mut GpuController>, deep_clean: bool);

        /// Check network connectivity
        #[qinvokable]
        fn check_network(self: Pin<&mut GpuController>);
    }

    impl cxx_qt::Threading for GpuController {}

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
    best_version: QString,
    current_status: QString,
    install_progress: i32,
    install_log: QString,
}

impl ffi::GpuController {
    fn detect_gpu(mut self: Pin<&mut Self>) {
        use crate::core::detector;
        let info = detector::detect_gpu();

        self.as_mut().set_gpu_vendor(QString::from(&info.vendor));
        self.as_mut().set_gpu_model(QString::from(&info.model));
        self.as_mut()
            .set_driver_in_use(QString::from(&info.driver_in_use));
        self.as_mut().set_secure_boot(info.secure_boot);

        let versions = detector::get_available_nvidia_versions();
        let best = versions.first().cloned().unwrap_or_default();
        self.as_mut().set_best_version(QString::from(&best));

        let current_installed = &info.driver_in_use;
        let up_to_date = !best.is_empty() && current_installed.contains(&best);
        self.as_mut().set_is_up_to_date(up_to_date);

        self.as_mut().set_current_status(QString::from("ready"));
        log::info!(
            "GPU detected: {} {} (driver: {})",
            info.vendor,
            info.model,
            info.driver_in_use
        );
    }

    fn get_available_versions(self: Pin<&mut Self>) -> QString {
        use crate::core::detector;
        let versions = detector::get_available_nvidia_versions();
        QString::from(&versions.join(","))
    }

    fn is_version_compatible(self: Pin<&mut Self>, version: &QString) -> bool {
        let _ver = version.to_string();
        // TODO: Implement kernel compatibility check
        true
    }

    fn install_express(mut self: Pin<&mut Self>) {
        if *self.is_installing() {
            return;
        }

        self.as_mut().set_is_installing(true);
        self.as_mut().set_install_progress(0);
        self.as_mut()
            .set_install_log(QString::from("Starting express installation...\n"));
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

            let success = installer.install_nvidia_closed();

            // Final UI update
            let _ = qt_thread.queue(move |mut qobject: Pin<&mut ffi::GpuController>| {
                qobject.as_mut().set_is_installing(false);
                qobject
                    .as_mut()
                    .set_install_progress(if success { 100 } else { 0 });
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

            // Logic: if use_open_kernel -> install_nvidia_open, else -> install_nvidia_closed
            // Ideally core::installer handles version pinning. For now using available methods.
            let success = if use_open_kernel {
                installer.install_nvidia_open()
            } else {
                installer.install_nvidia_closed()
            };

            let _ = qt_thread.queue(move |mut qobject: Pin<&mut ffi::GpuController>| {
                qobject.as_mut().set_is_installing(false);
                qobject
                    .as_mut()
                    .set_install_progress(if success { 100 } else { 0 });

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

    fn check_network(mut self: Pin<&mut Self>) {
        use std::net::TcpStream;
        use std::time::Duration;

        let connected =
            TcpStream::connect_timeout(&"8.8.8.8:53".parse().unwrap(), Duration::from_secs(3))
                .is_ok();

        self.as_mut().set_has_internet(connected);
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

impl ffi::PerfMonitor {
    fn refresh(mut self: Pin<&mut Self>) {
        use crate::core::tweaks;

        let gpu = tweaks::get_gpu_stats();
        self.as_mut().set_gpu_temp(gpu.temp);
        self.as_mut().set_gpu_load(gpu.load);
        self.as_mut().set_gpu_mem_used(gpu.mem_used);
        self.as_mut().set_gpu_mem_total(gpu.mem_total);

        let sys = tweaks::get_system_stats();
        self.as_mut().set_cpu_load(sys.cpu_load);
        self.as_mut().set_cpu_temp(sys.cpu_temp);
        self.as_mut().set_ram_used(sys.ram_used);
        self.as_mut().set_ram_total(sys.ram_total);
        self.as_mut().set_ram_percent(sys.ram_percent);
    }

    fn load_system_info(mut self: Pin<&mut Self>) {
        use crate::core::detector;

        let info = detector::get_full_system_info();
        self.as_mut().set_distro(QString::from(&info.distro));
        self.as_mut().set_kernel(QString::from(&info.kernel));
        self.as_mut().set_cpu_name(QString::from(&info.cpu));
        self.as_mut().set_ram_info(QString::from(&info.ram));
        self.as_mut().set_gpu_full_name(QString::from(&format!(
            "{} {}",
            info.gpu.vendor, info.gpu.model
        )));
        self.as_mut()
            .set_display_server(QString::from(&info.display_server));
    }
}
