// Logging setup
use crate::config;
use std::fs;

pub fn init() {
    // Set up env_logger with default INFO level
    env_logger::Builder::from_env(env_logger::Env::default().default_filter_or("info"))
        .format_timestamp_secs()
        .init();

    // Ensure log directory exists
    if let Some(data_dir) = dirs::data_local_dir() {
        let log_dir = data_dir.join(config::APP_NAME);
        if !log_dir.exists() {
            let _ = fs::create_dir_all(&log_dir);
        }
        log::info!("========================================");
        log::info!("ro-Control v{} Started", config::VERSION);
        log::info!("Log directory: {:?}", log_dir);
        log::info!("========================================");
    }
}
