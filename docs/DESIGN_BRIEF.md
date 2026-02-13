# ro-Control — Figma Design Brief

## What is this document?

This is the design specification for the ro-Control application UI.
Use this as a reference when designing the interface in Figma.

---

## 1. Application Identity

**Name:** ro-Control
**Type:** NVIDIA GPU Driver Manager (system utility)
**Platform:** Fedora-based Linux distro, KDE Plasma 6 desktop
**Toolkit:** Qt6 + QML + Qt Quick Controls 2 (NOT Kirigami)
**Language:** Rust (backend), QML (frontend)

### What it does (in one sentence):

> Downloads, validates, installs, and manages NVIDIA proprietary drivers
> with a single click — safely, with version compatibility checks.

### What it does NOT do:

- NOT a general "settings" app (it has ONE job)
- NOT a package manager
- NOT a hardware monitoring dashboard (perf view is secondary)
- Does NOT run in the background as a service

---

## 2. Target Performance Profile

| Metric      | Target           | Why                                          |
| ----------- | ---------------- | -------------------------------------------- |
| Cold start  | < 500ms          | System tool, must feel instant               |
| Idle RAM    | < 25 MB          | May stay open during driver install          |
| Active RAM  | < 40 MB          | During download + install                    |
| CPU idle    | 0%               | No background work when idle                 |
| CPU active  | < 5% single core | Only during download/install                 |
| Binary size | < 5 MB           | Lean Rust binary                             |
| Animations  | 60fps or none    | No choppy animations — either smooth or skip |

### Design Implications:

- **NO heavy blur/glassmorphism** — GPU compositing cost on integrated GPUs
- **NO constant animations** — CPU wake-ups drain battery on laptops
- **NO embedded web views** — memory hog
- **Minimal PNG/raster assets** — use SVG icons + system theme colors
- **Solid colors with subtle borders** preferred over transparency effects

---

## 3. UI Architecture (4 Screens)

```
┌─────────────────────────────────────────────────────────┐
│  Header Bar (always visible)                            │
│  [ro-Control]            [Theme ☀/🌙]  [About ℹ]       │
├─────────────────────────────────────────────────────────┤
│  Status Bar (contextual)                                │
│  Driver: nvidia-560.xx | Secure Boot: OFF | GPU: RTX   │
├──────────┬──────────────────────────────────────────────┤
│ Sidebar  │  Content Area                                │
│          │                                              │
│ Install  │  ┌──────────────────────────────────────┐    │
│ --------►│  │  Currently shown page                │    │
│ Expert   │  │                                      │    │
│          │  │  (Install / Expert / Perf / Progress) │    │
│ Monitor  │  │                                      │    │
│          │  └──────────────────────────────────────┘    │
│          │                                              │
│          │                                              │
│ ──────── │                                              │
│ Version  │                                              │
│ v1.0.0   │                                              │
└──────────┴──────────────────────────────────────────────┘
```

### Screen 1: Install Page (Default / Landing)

**Purpose:** Let the user install or update NVIDIA drivers in ONE click.
**Mental model:** "App Store install button" — dead simple.

```
┌──────────────────────────────────────────┐
│                                          │
│         [GPU Icon - 48px SVG]            │
│                                          │
│     Select Installation Type             │
│     Optimized for your hardware          │
│                                          │
│  ┌────────────────────────────────────┐  │
│  │ ✅  Express Install (Recommended) │  │
│  │     Installs nvidia-560.35.03     │  │
│  │     Compatible: ✓ Verified        │──►  Click → Progress Page
│  └────────────────────────────────────┘  │
│                                          │
│  ┌────────────────────────────────────┐  │
│  │ ⚙️  Custom Install (Expert)       │  │
│  │     Choose version, kernel module │──►  Click → Expert Page
│  └────────────────────────────────────┘  │
│                                          │
│  ⚠️  Secure Boot Warning (if active)    │
│                                          │
└──────────────────────────────────────────┘
```

**Key behaviors:**

- Express card pre-fills with the BEST compatible driver version
- Shows "Compatible: ✓ Verified" or "⚠️ Not recommended for your GPU"
- If no internet → shows offline warning instead of cards
- If driver already installed → shows "✓ Up to date" state

### Screen 2: Expert Page

**Purpose:** Manual control for power users.
**Who uses this:** People who know what `akmod-nvidia` vs `nvidia-open` means.

```
┌──────────────────────────────────────────┐
│  Expert Driver Management                │
│                                          │
│  Current: nvidia-555.42 (proprietary)    │
│  Kernel:  6.8.12-300.fc40.x86_64        │
│                                          │
│  ┌────────────────────────────────────┐  │
│  │ Available Versions:               │  │
│  │                                   │  │
│  │  ● 560.35.03  (Latest Stable) ✓   │  │
│  │  ○ 555.42.06  (Installed)         │  │
│  │  ○ 550.120    (LTS Branch)        │  │
│  │  ○ 545.29.06  (Legacy)           │  │
│  └────────────────────────────────────┘  │
│                                          │
│  Kernel Module:  ○ Proprietary  ○ Open   │
│  Deep Clean:     [  ] Remove old configs │
│                                          │
│  [Install Selected]  [Remove All & Reset]│
│                                          │
└──────────────────────────────────────────┘
```

**Key behaviors:**

- Radio button for version selection
- Shows which version is currently installed
- Version compatibility badge (green ✓, yellow ⚠, red ✗)
- "Remove All" requires double confirmation (dialog)

### Screen 3: Performance Monitor

**Purpose:** Quick system/GPU health check AFTER driver installation.
**NOT a dedicated monitoring app** — just enough info to verify the driver works.

```
┌──────────────────────────────────────────┐
│  System Information                      │
│                                          │
│  OS:         Fedora 40 (KDE Plasma)      │
│  Kernel:     6.8.12-300.fc40             │
│  CPU:        AMD Ryzen 7 5800X           │
│  RAM:        32 GB DDR4                  │
│  GPU:        NVIDIA RTX 4070            │
│  Driver:     nvidia-560.35.03            │
│  Display:    Wayland                     │
│                                          │
│  ┌─ GPU Status ────────────────────────┐ │
│  │ Temp    42°C    ████░░░░░░  42%     │ │
│  │ Load     8%     █░░░░░░░░░   8%     │ │
│  │ VRAM   1.2/8 GB ██░░░░░░░░  15%     │ │
│  └─────────────────────────────────────┘ │
│                                          │
│  ┌─ System ────────────────────────────┐ │
│  │ CPU     12%     ██░░░░░░░░  12%     │ │
│  │ RAM    8.2/32   ███░░░░░░░  25%     │ │
│  └─────────────────────────────────────┘ │
│                                          │
└──────────────────────────────────────────┘
```

**Key behaviors:**

- Refreshes every 2 seconds (only when this page is VISIBLE)
- Progress bars change color: green < 60%, yellow < 85%, red ≥ 85%
- No charts, no graphs — just bars (lightweight)
- Values read from `/sys/`, `nvidia-smi`, `/proc/` (no daemon)

### Screen 4: Progress Page

**Purpose:** Shows real-time progress during driver installation.

```
┌──────────────────────────────────────────┐
│                                          │
│         Installing nvidia-560.35.03      │
│                                          │
│  ████████████████████░░░░░░  67%         │
│                                          │
│  ┌─ Log ──────────────────────────────┐  │
│  │ > Checking compatibility...  ✓     │  │
│  │ > Downloading packages...    ✓     │  │
│  │ > Installing akmod-nvidia... ⏳    │  │
│  │ > Building kernel module...        │  │
│  │ > Running dracut...                │  │
│  └────────────────────────────────────┘  │
│                                          │
│  ⚠️ Do not turn off your computer       │
│                                          │
│  [Cancel]                                │
│                                          │
└──────────────────────────────────────────┘
```

**Key behaviors:**

- Sequential steps with status icons (✓ done, ⏳ running, ○ pending)
- Real-time log output in a scrollable monospace area
- Cancel button with confirmation dialog
- On completion → shows success/error result + "Reboot Required" button

---

## 4. Design Language

### DO:

- **Flat design** with solid background colors from the Breeze theme
- **Subtle 1px borders** to define card boundaries
- **System accent color** for primary actions (KDE users can customize this)
- **Standard Qt icons** from the Breeze icon theme (no custom icon assets)
- **Clear typography hierarchy** — title, subtitle, body, caption
- **Generous whitespace** — the app has little content, let it breathe
- **High contrast** — this may run on cheap monitors with poor color accuracy
- **Responsive layout** — should work from 800×600 to 2560×1440

### DON'T:

- ❌ Blur / frosted glass / glassmorphism (GPU-intensive, inconsistent across compositors)
- ❌ Drop shadows heavier than 2-4px (performance cost)
- ❌ Animated backgrounds or particle effects
- ❌ Custom fonts (use system font — Noto Sans on KDE)
- ❌ Transparency levels below 80% opacity (readability issue)
- ❌ Rounded corners > 12px (doesn't match KDE Breeze aesthetic)
- ❌ Dark-only design (must support both Breeze Light and Breeze Dark)

### Breeze Color Reference:

**Light Mode:**
| Token | Color | Usage |
|--------------------|----------|--------------------------|
| Window Background | #eff0f1 | Main background |
| Card Background | #fcfcfc | Card/section background |
| Text Primary | #232629 | Main text |
| Text Secondary | #7f8c8d | Descriptions, captions |
| Accent | #2980b9 | Primary buttons, links |
| Success | #27ae60 | Verified, installed |
| Warning | #f39c12 | Secure Boot, caution |
| Error | #da4453 | Failed, incompatible |
| Border | #bdc3c7 | Card borders, dividers |

**Dark Mode:**
| Token | Color | Usage |
|--------------------|----------|--------------------------|
| Window Background | #1b1e20 | Main background |
| Card Background | #2a2e32 | Card/section background |
| Text Primary | #eff0f1 | Main text |
| Text Secondary | #7f8c8d | Descriptions, captions |
| Accent | #3daee9 | Primary buttons, links |
| Success | #27ae60 | Verified, installed |
| Warning | #f67400 | Secure Boot, caution |
| Error | #ed1515 | Failed, incompatible |
| Border | #3e4349 | Card borders, dividers |

---

## 5. Component Inventory

Design these reusable components in Figma:

| Component       | Variants                           | Used in         |
| --------------- | ---------------------------------- | --------------- |
| **ActionCard**  | default, hover, selected, disabled | Install, Expert |
| **StatusBar**   | normal, warning, error             | All pages       |
| **ProgressBar** | green, yellow, red                 | Perf, Progress  |
| **StepItem**    | pending, running, done, error      | Progress        |
| **VersionRow**  | available, installed, selected     | Expert          |
| **InfoRow**     | label + value (selectable)         | Perf            |
| **NavItem**     | default, active                    | Sidebar         |
| **Dialog**      | confirm, error, success            | All pages       |
| **Button**      | primary, secondary, destructive    | All pages       |
| **Header Bar**  | with title + action buttons        | All pages       |

---

## 6. User Flows

### Flow 1: First Launch (Express Install)

```
Open App → Install Page → Click "Express Install"
→ EULA Dialog (NVIDIA) → Accept
→ Progress Page (download → install → dracut → done)
→ Success Dialog → "Reboot Now" / "Later"
```

### Flow 2: Update Existing Driver

```
Open App → Install Page shows "Update Available: 560.35"
→ Click "Express Install"
→ Progress Page → Success → Reboot
```

### Flow 3: Expert Custom Install

```
Open App → Install Page → Click "Custom Install"
→ Expert Page → Select version → Select kernel module type
→ Click "Install Selected"
→ EULA Dialog → Progress Page → Success
```

### Flow 4: Remove Drivers

```
Open App → Expert Page → Click "Remove All & Reset"
→ Confirmation Dialog ("Are you sure?")
→ Deep Clean checkbox → Confirm
→ Progress Page → Success → Reboot
```

### Flow 5: Incompatible Driver Warning

```
Open App → Expert Page → Select old/incompatible version
→ Warning badge: "⚠️ Not compatible with kernel 6.8.x"
→ Install button disabled or shows warning dialog
```

---

## 7. Window Specification

| Property        | Value                                   |
| --------------- | --------------------------------------- |
| Default size    | 960 × 680 px                            |
| Minimum size    | 800 × 600 px                            |
| Maximum size    | Unrestricted                            |
| Sidebar width   | 200 px (fixed)                          |
| Content padding | 24 px                                   |
| Card padding    | 16-20 px                                |
| Card radius     | 8 px                                    |
| Card border     | 1px solid                               |
| Button radius   | 6 px                                    |
| Button height   | 36 px                                   |
| Font            | System (Noto Sans)                      |
| Icon size       | 16px (inline), 24px (card), 48px (hero) |

---

## 8. States to Design

For each screen, design these states:

### Install Page:

1. **Default** — No driver installed, cards for Express/Custom
2. **Up to date** — Driver installed, shows "✓ Up to date" with current version
3. **Update available** — Shows update badge on Express card
4. **No internet** — Shows offline warning, cards disabled
5. **Secure Boot ON** — Shows warning banner above cards

### Expert Page:

1. **Default** — Version list loaded, nothing selected
2. **Version selected** — One version highlighted, install button enabled
3. **Incompatible version** — Warning badge, install prevented
4. **Loading versions** — Spinner while fetching from repo

### Performance:

1. **Default** — All values populated
2. **No GPU detected** — GPU section shows "No NVIDIA GPU found"
3. **Driver not installed** — Shows "Install driver first" message

### Progress:

1. **In progress** — Steps advancing
2. **Completed** — All green, "Reboot Required" button
3. **Failed** — Error step red, error message, "Send Report" button
4. **Cancelled** — Rolled-back message
