// Command runner — executes shell commands and returns output
use std::process::Command;

/// Run a command and return stdout as String, or None on failure.
pub fn run(command: &str) -> Option<String> {
    log::debug!("Running command: {}", command);
    match Command::new("sh").arg("-c").arg(command).output() {
        Ok(output) => {
            if output.status.success() {
                let stdout = String::from_utf8_lossy(&output.stdout).trim().to_string();
                if !output.stderr.is_empty() {
                    let stderr = String::from_utf8_lossy(&output.stderr).trim().to_string();
                    if !stderr.is_empty() {
                        log::warn!("Command warning ({}): {}", command, stderr);
                    }
                }
                Some(stdout)
            } else {
                let stderr = String::from_utf8_lossy(&output.stderr).trim().to_string();
                log::debug!("Command failed ({}): {}", command, stderr);
                None
            }
        }
        Err(e) => {
            log::error!("Failed to execute command ({}): {}", command, e);
            None
        }
    }
}

/// Run a command returning (exit_code, stdout, stderr).
pub fn run_full(command: &str) -> (i32, String, String) {
    log::debug!("Running full command: {}", command);
    match Command::new("sh").arg("-c").arg(command).output() {
        Ok(output) => {
            let code = output.status.code().unwrap_or(-1);
            let stdout = String::from_utf8_lossy(&output.stdout).trim().to_string();
            let stderr = String::from_utf8_lossy(&output.stderr).trim().to_string();
            (code, stdout, stderr)
        }
        Err(e) => (-1, String::new(), e.to_string()),
    }
}

/// Check if a binary exists in PATH.
pub fn which(name: &str) -> bool {
    Command::new("which")
        .arg(name)
        .output()
        .map(|o| o.status.success())
        .unwrap_or(false)
}
