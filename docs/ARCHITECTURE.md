# System Architecture & IPC Specification

**ro-Control** is architected as an integrated OS hardware subsystem for **Ro-ASD**, providing separation between unprivileged user interfaces, headless background daemons, and privileged hardware management.

---

## 1. Subsystem Architecture

```
┌────────────────────────────────────────────────────────┐
│               User Interaction Layer                   │
├──────────────────────────┬─────────────────────────────┤
│  KDE Plasma Desktop GUI  │        Headless CLI         │
│     (Qt6 / QML / KF6)    │   (JSON & Human Output)     │
└────────────┬─────────────┴──────────────┬──────────────┘
             │                            │
             ▼                            ▼
┌────────────────────────────────────────────────────────┐
│           ro-Control Backend & IPC Engine              │
├────────────────────────────────────────────────────────┤
│ • GpuMonitor       • FanController    • PowerController│
│ • CpuMonitor       • HealthGuard      • SystemInfo     │
│ • RamMonitor       • DBusService      • UiPreferences  │
└────────────┬────────────────────────────┬──────────────┘
             │                            │
             ▼                            ▼
┌────────────────────────────┐ ┌─────────────────────────┐
│     Linux Kernel & Sysfs   │ │     Polkit Helper       │
│ • /sys/class/hwmon         │ │ • /usr/libexec/         │
│ • /sys/class/thermal       │ │   ro-control-helper     │
│ • NVIDIA NVML & NV-CONTROL │ │ • dnf, akmods, dracut   │
└────────────────────────────┘ └─────────────────────────┘
```

---

## 2. Core Backend Modules

- **`GpuMonitor`:** Communicates with NVIDIA NVML / NV-CONTROL and Linux sysfs. Gathers clock frequencies, VRAM allocation, temperature hotspots, and per-process memory maps with non-blocking async timers.
- **`FanController`:** Hardware-aware PWM tachometer discovery across GPU, CPU, and chassis fans. Implements 6 cooling modes, dynamic multi-point curve interpolation, directional hysteresis smoothing, and 0dB idle detection.
- **`PowerController`:** Manages GPU TDP power limits, clock offsets, and driver persistence state.
- **`HealthGuard`:** Evaluates thermal safety thresholds (warning at 78°C, critical at 85°C). Dispatches system desktop notifications and triggers emergency 100% cooling overrides.
- **`SystemInfoProvider`:** Collects kernel version, display server (Wayland / X11), CPU model, motherboard, and secure boot status.
- **`DBusService`:** Exposes hardware telemetry and control endpoints on the session bus.

---

## 3. D-Bus IPC Specification

- **Service Name:** `io.github.ProjectRoASD.rocontrol`
- **Object Path:** `/io/github/ProjectRoASD/rocontrol`
- **Interface:** `io.github.ProjectRoASD.rocontrol`

### Methods

| Method | Signature | Description |
| :--- | :--- | :--- |
| `GetTelemetry` | `() -> (s: json)` | Returns complete live system, GPU, CPU, and fan telemetry |
| `GetGpuDevices` | `() -> (s: json)` | Enumerates detected graphics cards |
| `GetGpuProcesses` | `() -> (s: json)` | Lists running applications using GPU VRAM |
| `GetThermalStatus` | `() -> (s: json)` | Returns active thermal zones and temperatures |
| `SelectGpu` | `(i: index) -> (b: success)` | Switches active target GPU for monitoring and tuning |
| `SetFanMode` | `(s: mode) -> (b: success)` | Sets cooling profile (`auto`, `silent`, `balanced`, `performance`, `manual`, `custom`) |
| `SetFanSpeed` | `(i: percent) -> (b: success)` | Applies fixed manual fan speed (0–100%) |
| `ApplyFanCurvePreset`| `(s: preset) -> (b: success)` | Applies curve template (`zero-db`, `aggressive`, `stepped`) |
| `SetPowerLimit` | `(d: watts) -> (b: success)` | Sets maximum GPU TDP power limit |
| `SetPersistenceMode`| `(b: enabled) -> (b: success)` | Toggles NVIDIA driver persistence daemon |

### Signals

| Signal | Signature | Description |
| :--- | :--- | :--- |
| `TelemetryUpdated` | `(s: jsonPayload)` | Emitted periodically (1 Hz) when telemetry registers update |
| `ThermalAlert` | `(s: severity, s: message)` | Emitted when hardware temperatures exceed safety thresholds |
