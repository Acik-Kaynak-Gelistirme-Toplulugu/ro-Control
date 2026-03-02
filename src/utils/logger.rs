// Logging setup
use crate::config;
use simplelog::*;
use std::fs;

pub fn init() {
    let mut loggers: Vec<Box<dyn SharedLogger>> = vec![];

    // Terminal logger (Info level by default, or RUST_LOG env)
    let logger = TermLogger::new(
        LevelFilter::Info,
        Config::default(),
        TerminalMode::Mixed,
        ColorChoice::Auto,
    );
    loggers.push(logger);

    // File logger (Debug level - captures everything, appends across sessions)
    if let Some(data_dir) = dirs::data_local_dir() {
        let log_dir = data_dir.join(config::APP_NAME);
        if !log_dir.exists() {
            let _ = fs::create_dir_all(&log_dir);
        }

        let log_file_path = log_dir.join("ro-control.log");

        // Rotate log if it exceeds 5 MB
        if let Ok(meta) = fs::metadata(&log_file_path) {
            if meta.len() > 5 * 1024 * 1024 {
                let backup = log_dir.join("ro-control.log.old");
                let _ = fs::rename(&log_file_path, &backup);
            }
        }

        if let Ok(file) = fs::OpenOptions::new()
            .create(true)
            .append(true)
            .open(&log_file_path)
        {
            loggers.push(WriteLogger::new(
                LevelFilter::Debug,
                Config::default(),
                file,
            ));
        }
    }

    // Initialize combined logger
    let _ = CombinedLogger::init(loggers);

    log::info!("========================================");
    log::info!("ro-Control v{} Started", config::VERSION);
    if let Some(data_dir) = dirs::data_local_dir() {
        let log_dir = data_dir.join(config::APP_NAME);
        log::info!("Log directory: {:?}", log_dir);
    }
    log::info!("========================================");
}
