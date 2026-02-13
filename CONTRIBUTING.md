# Contributing to ro-Control

Thank you for your interest in contributing to ro-Control! We welcome contributions from everyone.

## How to Contribute

### 🐛 Bug Reports

Found a bug? Please open an [issue](https://github.com/Acik-Kaynak-Gelistirme-Toplulugu/ro-Control/issues/new?template=bug_report.yml) with:

- Clear description of the problem
- Steps to reproduce
- Your system info (distro, GPU model, kernel version)
- Relevant log output from `~/.local/share/ro-control/app.log`

### 💡 Feature Requests

Have an idea? Open a [feature request](https://github.com/Acik-Kaynak-Gelistirme-Toplulugu/ro-Control/issues/new?template=feature_request.yml) and describe:

- The problem you're trying to solve
- Your proposed solution
- Any alternatives you've considered

### 🔧 Code Contributions

1. **Fork** the repository
2. **Clone** your fork and create a branch:
    ```bash
    git clone https://github.com/YOUR_USERNAME/ro-Control.git
    cd ro-Control
    git checkout -b feature/your-feature
    ```
3. **Set up** the development environment (see [docs/BUILDING.md](docs/BUILDING.md))
4. **Make** your changes
5. **Verify** quality:
    ```bash
    cargo fmt --all          # Format code
    cargo clippy --all-targets -- -D warnings -A dead_code -A clippy::incompatible_msrv  # Lint
    cargo test               # Run tests
    ```
6. **Commit** with a clear message:
    ```
    feat: add AMD driver detection via lspci
    fix: resolve crash when nvidia-smi is not installed
    docs: update build instructions for Arch Linux
    ```
7. **Push** and open a **Pull Request**

### 🌍 Translations

ro-Control supports multiple languages. To add or improve a translation:

1. Check `po/LINGUAS` for existing languages
2. Translation strings are in `src/utils/i18n.rs`
3. Add your language to the dictionary and submit a PR

### 📝 Documentation

Improvements to documentation are always welcome:

- `README.md` — Overview and quick start
- `docs/BUILDING.md` — Build instructions
- `docs/ARCHITECTURE.md` — Technical architecture
- Code comments and doc strings

## Development Guidelines

### Code Style

- Follow `rustfmt` configuration (see `rustfmt.toml`)
- All public functions should have doc comments
- Variable and function names in English
- UI strings go through the `i18n::tr()` system
- Keep modules focused: UI code in `ui/`, business logic in `core/`

### Commit Messages

We follow [Conventional Commits](https://www.conventionalcommits.org/):

| Prefix      | Use for                    |
| ----------- | -------------------------- |
| `feat:`     | New feature                |
| `fix:`      | Bug fix                    |
| `docs:`     | Documentation              |
| `style:`    | Formatting, no code change |
| `refactor:` | Code restructuring         |
| `test:`     | Adding/updating tests      |
| `ci:`       | CI/CD changes              |
| `chore:`    | Maintenance tasks          |

### Architecture

See [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) for an overview of the codebase structure, design decisions, and data flow.

## Code of Conduct

This project follows the [Contributor Covenant Code of Conduct](CODE_OF_CONDUCT.md). By participating, you agree to uphold this code.

## License

By contributing, you agree that your contributions will be licensed under the [GPL-3.0](LICENSE) license.

---

Thank you for helping make ro-Control better! 🚀
