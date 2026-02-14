# Security Policy

## Supported Versions

| Version | Supported          |
| ------- | ------------------ |
| 1.0.x   | :white_check_mark: |
| < 1.0   | :x:                |

## Reporting a Vulnerability

If you discover a security vulnerability in ro-Control, please report it responsibly:

1. **Do NOT open a public GitHub issue.**
2. Send an email to **info@akgt.dev** with:
   - A description of the vulnerability
   - Steps to reproduce
   - Potential impact assessment
3. You will receive an acknowledgement within **48 hours**.
4. We will work with you to understand and address the issue before any public disclosure.

## Security Architecture

ro-Control uses PolicyKit (`pkexec`) for privilege escalation. The privileged helper script (`scripts/ro-control-root-task`) enforces a strict command allowlist — only pre-approved system commands (package managers, initramfs tools, etc.) are permitted to run as root.

### Key Security Design Decisions

- **No direct root execution** — all privileged operations go through PolicyKit authentication
- **Command allowlist** — the root helper script validates every command against a whitelist before execution
- **No network data in privileged context** — downloads happen as the unprivileged user
- **Minimal dependencies** — reduced attack surface through careful dependency selection

## Scope

The following are considered in scope:
- Privilege escalation bypasses in `ro-control-root-task`
- Command injection via QML ↔ Rust bridge
- Unsafe handling of user-supplied data (file paths, version strings)
- Dependencies with known CVEs (monitored via `cargo-audit` in CI)

Thank you for helping keep ro-Control secure.
