// ro-Control macOS Simulation — JavaScript v2
// Full feature simulation with real-time monitoring, express confirm flow, and expert options

(function () {
    'use strict';

    // ─── State ──────────────────────────────
    let currentPage = 'install';
    let isDark = false;
    let selectedVersion = '';
    let installRunning = false;
    let useOpenKernel = false;
    let deepClean = false;
    let secureBootOn = false;
    let latestVersion = '';
    let perfAnimationId = null;
    let lastPerfTime = 0;

    // Simulated smooth sensor values (using exponential moving average)
    const sensors = {
        gpuTemp: { current: 40, target: 40 },
        gpuLoad: { current: 10, target: 10 },
        vramUsed: { current: 1400, target: 1400 },
        cpuLoad: { current: 15, target: 15 },
        cpuTemp: { current: 45, target: 45 },
        ramUsed: { current: 8200, target: 8200 },
    };
    const VRAM_TOTAL = 12288;
    const RAM_TOTAL = 32768;
    const PERF_UPDATE_INTERVAL = 1000;  // ms between target changes
    const SMOOTHING = 0.08;             // EMA factor per frame

    const VERSIONS = [
        { version: '560.35.03', source: 'RPM Fusion', notes: 'Latest stable', latest: true },
        { version: '555.58.02', source: 'RPM Fusion', notes: 'Production branch' },
        { version: '550.120', source: 'RPM Fusion', notes: 'LTS / Enterprise' },
        { version: '545.29.06', source: 'RPM Fusion', notes: 'Legacy' },
        { version: '535.183.01', source: 'RPM Fusion', notes: 'Legacy LTS' },
    ];

    // ─── DOM Helpers ────────────────────────
    const $ = (sel) => document.querySelector(sel);
    const $$ = (sel) => document.querySelectorAll(sel);

    // ─── Navigation ─────────────────────────
    function showPage(pageId) {
        $$('.page').forEach(p => p.classList.remove('active'));
        $$('.nav-btn').forEach(b => b.classList.remove('active'));

        const page = $(`#page-${pageId}`);
        if (page) { page.classList.add('active'); currentPage = pageId; }

        const navMap = { 'install': 'install', 'express-confirm': 'install', 'expert': 'expert', 'perf': 'perf', 'progress': 'install' };
        const navKey = navMap[pageId] || pageId;
        const btn = $(`.nav-btn[data-page="${navKey}"]`);
        if (btn) btn.classList.add('active');

        // Start/stop performance monitor
        if (pageId === 'perf') startPerfMonitor();
        else stopPerfMonitor();
    }

    // ─── Theme ──────────────────────────────
    function toggleTheme() {
        isDark = !isDark;
        document.documentElement.setAttribute('data-theme', isDark ? 'dark' : 'light');
        $('#themeToggle').textContent = isDark ? '☀️' : '🌙';
    }

    // ─── Fetch Latest Version (Simulated) ───
    function fetchLatestVersion() {
        // Simulate API call with slight delay
        setTimeout(() => {
            latestVersion = VERSIONS[0].version;
            selectedVersion = latestVersion;
            $('#expressVersion').textContent = `v${latestVersion}`;
            $('#statusDriverVer').textContent = latestVersion;
        }, 800);
    }

    // ─── Secure Boot Detection ──────────────
    function detectSecureBoot() {
        setTimeout(() => {
            // Randomly simulate for demo purposes
            secureBootOn = Math.random() > 0.6;

            const pill = $('#secbootPill');
            const icon = $('#secbootIcon');
            const label = $('#secbootLabel');
            const banner = $('#secbootBanner');
            const bannerIcon = $('#secbootBannerIcon');
            const bannerTitle = $('#secbootBannerTitle');
            const bannerDesc = $('#secbootBannerDesc');

            if (secureBootOn) {
                icon.textContent = '⚠️';
                label.textContent = 'Secure Boot ON';
                pill.style.borderColor = 'rgba(245,158,11,0.4)';

                banner.className = 'secboot-banner on';
                banner.style.display = 'block';
                bannerIcon.textContent = '⚠️';
                bannerTitle.textContent = 'Secure Boot is Enabled';
                bannerDesc.textContent = 'Your system has Secure Boot enabled in UEFI/BIOS. ' +
                    'Third-party kernel modules (including NVIDIA proprietary drivers) may fail to load ' +
                    'unless they are signed with a Machine Owner Key (MOK). You may need to enroll a key ' +
                    'after installation, or disable Secure Boot in BIOS to use unsigned drivers.';
            } else {
                icon.textContent = '🔓';
                label.textContent = 'Secure Boot OFF';
                pill.style.borderColor = 'rgba(16,185,129,0.3)';

                banner.className = 'secboot-banner off';
                banner.style.display = 'block';
                bannerIcon.textContent = '✅';
                bannerTitle.textContent = 'Secure Boot is Disabled';
                bannerDesc.textContent = 'Third-party kernel modules (NVIDIA drivers) can load freely ' +
                    'without MOK signing. No additional steps are required for driver installation.';
            }

            // Update confirm page too
            $('#confirmSecboot').textContent = secureBootOn ? 'ON — MOK signing may be required' : 'OFF — No restrictions';
        }, 600);
    }

    // ─── Version List ───────────────────────
    function renderVersionList() {
        const list = $('#versionList');
        list.innerHTML = '';
        VERSIONS.forEach(v => {
            const item = document.createElement('div');
            item.className = `version-item${v.version === selectedVersion ? ' selected' : ''}`;
            item.innerHTML = `
                <input type="radio" name="driverVer" ${v.version === selectedVersion ? 'checked' : ''}>
                <span class="version-name">${v.version}</span>
                <span class="version-source">${v.source}</span>
                ${v.latest ? '<span class="version-source" style="background:var(--success);color:white;">Latest</span>' : ''}
                <span class="version-notes">${v.notes}</span>`;
            item.addEventListener('click', () => { selectedVersion = v.version; renderVersionList(); });
            list.appendChild(item);
        });
    }

    // ─── Build Install Steps ────────────────
    function buildInstallSteps(opts) {
        const steps = [];
        steps.push({ text: 'Backing up Xorg configuration', icon: '📋' });

        if (opts.deepClean) {
            steps.push({ text: 'Deep cleaning previous driver configs', icon: '🧹' });
            steps.push({ text: 'Removing old NVIDIA packages', icon: '🗑️' });
        }

        steps.push({ text: 'Blacklisting nouveau driver', icon: '🚫' });
        steps.push({ text: 'Installing kernel headers (kernel-devel)', icon: '⚙️' });
        steps.push({ text: 'Enabling RPM Fusion repository', icon: '📦' });

        if (opts.openKernel) {
            steps.push({ text: 'Installing NVIDIA Open Kernel Module (nvidia-open)', icon: '🔓' });
        } else {
            steps.push({ text: 'Installing NVIDIA Proprietary driver (akmod-nvidia)', icon: '🎮' });
        }

        steps.push({ text: 'Regenerating initramfs (dracut --force)', icon: '🔄' });
        steps.push({ text: 'Verifying installation', icon: '✅' });
        return steps;
    }

    // ─── Build Install Log Lines ────────────
    function buildLogLines(opts, steps) {
        const lines = [];
        const ver = opts.version;
        const kernelType = opts.openKernel ? 'Open Kernel Module' : 'Proprietary (Closed Source)';

        lines.push(`--- OPERATION STARTING: NVIDIA ${kernelType} ---`);
        lines.push(`Version: ${ver}`);
        lines.push(`Package Manager: dnf`);
        lines.push(`Kernel: 6.8.11-300.fc40.x86_64`);
        lines.push(`GPU: NVIDIA GeForce RTX 4070 (Simülasyon)`);
        lines.push(`Open Kernel: ${opts.openKernel ? 'YES' : 'NO'}`);
        lines.push(`Deep Clean: ${opts.deepClean ? 'YES' : 'NO'}`);
        lines.push(`Secure Boot: ${secureBootOn ? 'ON' : 'OFF'}`);
        lines.push(``);
        lines.push(`Waiting for authorization (Root/Admin)...`);
        lines.push(`Please enter your password in the dialog.`);
        lines.push(``);

        steps.forEach((step, i) => {
            lines.push(`Step ${i + 1}: ${step.text}...`);
        });

        return lines;
    }

    // ─── Installation Simulation ────────────
    function simulateInstall(opts) {
        if (installRunning) return;
        installRunning = true;
        showPage('progress');

        const steps = buildInstallSteps(opts);
        const stepsContainer = $('#stepsContainer');
        const logOutput = $('#logOutput');
        const progressBar = $('#installProgress');
        const progressPercent = $('#installPercent');
        const progressActions = $('#progressActions');

        stepsContainer.innerHTML = '';
        logOutput.textContent = '';
        progressActions.style.display = 'none';

        // Title
        const titleSuffix = opts.openKernel ? 'Open Kernel' : 'Proprietary';
        $('#progressTitle').textContent = `Installing NVIDIA ${titleSuffix} Driver`;

        // Create step elements
        steps.forEach((step, i) => {
            const el = document.createElement('div');
            el.className = 'step-item pending';
            el.id = `step-${i}`;
            el.innerHTML = `<span class="step-icon">⏳</span><span>${step.text}</span>`;
            stepsContainer.appendChild(el);
        });

        // Initial log output
        const logLines = buildLogLines(opts, steps);
        logLines.slice(0, 12).forEach(l => appendLog(l));

        let stepIndex = 0;
        const totalSteps = steps.length;

        function processStep() {
            if (stepIndex >= totalSteps) {
                appendLog(``);
                if (opts.deepClean) {
                    appendLog(`[Deep Clean] Removed: /etc/X11/xorg.conf.d/nvidia*`);
                    appendLog(`[Deep Clean] Removed: /etc/modprobe.d/nvidia*`);
                    appendLog(`[Deep Clean] Purged old DKMS modules`);
                }
                if (opts.openKernel) {
                    appendLog(`[Open Kernel] nvidia-open module loaded successfully`);
                    appendLog(`[Open Kernel] Module verification: PASS`);
                } else {
                    appendLog(`[Proprietary] akmod-nvidia built successfully`);
                    appendLog(`[Proprietary] Module verification: PASS`);
                }
                appendLog(``);
                appendLog(`SUCCESS: NVIDIA ${opts.openKernel ? 'Open Kernel' : 'Proprietary'} Installation completed.`);
                appendLog(`Reboot the system for changes to take effect.`);
                progressBar.style.width = '100%';
                progressPercent.textContent = '100%';
                progressActions.style.display = 'flex';
                installRunning = false;
                return;
            }

            const step = steps[stepIndex];
            const stepEl = $(`#step-${stepIndex}`);
            stepEl.className = 'step-item active';
            stepEl.querySelector('.step-icon').textContent = '⏳';

            const progress = Math.round(((stepIndex + 0.5) / totalSteps) * 100);
            progressBar.style.width = `${progress}%`;
            progressPercent.textContent = `${progress}%`;

            appendLog(`→ ${step.text}...`);

            const delay = 600 + Math.random() * 1000;
            setTimeout(() => {
                stepEl.className = 'step-item complete';
                stepEl.querySelector('.step-icon').textContent = '✅';
                appendLog(`  ✓ ${step.text} — done`);

                const finalProgress = Math.round(((stepIndex + 1) / totalSteps) * 100);
                progressBar.style.width = `${finalProgress}%`;
                progressPercent.textContent = `${finalProgress}%`;

                stepIndex++;
                processStep();
            }, delay);
        }

        setTimeout(processStep, 1200);
    }

    function appendLog(text) {
        const logOutput = $('#logOutput');
        const now = new Date();
        const ts = `${String(now.getHours()).padStart(2, '0')}:${String(now.getMinutes()).padStart(2, '0')}:${String(now.getSeconds()).padStart(2, '0')}`;
        logOutput.textContent += `[${ts}] ${text}\n`;
        $('#logPanel').scrollTop = $('#logPanel').scrollHeight;
    }

    // ─── Performance Monitor (requestAnimationFrame) ────
    function startPerfMonitor() {
        if (perfAnimationId) return;
        lastPerfTime = performance.now();
        updateTargets(); // Set initial targets
        perfAnimationId = requestAnimationFrame(perfLoop);
        updateMonitorFooter();
    }

    function stopPerfMonitor() {
        if (perfAnimationId) {
            cancelAnimationFrame(perfAnimationId);
            perfAnimationId = null;
        }
    }

    function updateTargets() {
        // Generate new random targets (simulating real sensor values)
        sensors.gpuTemp.target = 35 + Math.floor(Math.random() * 35);
        sensors.gpuLoad.target = Math.floor(Math.random() * 70);
        sensors.vramUsed.target = 800 + Math.floor(Math.random() * 4000);
        sensors.cpuLoad.target = 5 + Math.floor(Math.random() * 50);
        sensors.cpuTemp.target = 38 + Math.floor(Math.random() * 30);
        sensors.ramUsed.target = 5000 + Math.floor(Math.random() * 12000);
    }

    function perfLoop(timestamp) {
        // Smooth interpolation toward targets
        for (const key in sensors) {
            const s = sensors[key];
            s.current += (s.target - s.current) * SMOOTHING;
        }

        // Update DOM
        const gt = Math.round(sensors.gpuTemp.current);
        const gl = Math.round(sensors.gpuLoad.current);
        const vu = Math.round(sensors.vramUsed.current);
        const cl = Math.round(sensors.cpuLoad.current);
        const ct = Math.round(sensors.cpuTemp.current);
        const ru = Math.round(sensors.ramUsed.current);

        setBar('gpuTemp', gt, 100, `${gt}°C`);
        setBar('gpuLoad', gl, 100, `${gl}%`);
        setBar('vramBar', vu, VRAM_TOTAL, `${vu} / ${VRAM_TOTAL} MB`);
        setBar('cpuLoad', cl, 100, `${cl}%`);
        setBar('cpuTemp', ct, 100, `${ct}°C`);
        setBar('ramBar', ru, RAM_TOTAL, `${ru} / ${RAM_TOTAL} MB`);

        // Generate new targets periodically
        if (timestamp - lastPerfTime > PERF_UPDATE_INTERVAL) {
            lastPerfTime = timestamp;
            updateTargets();
            updateMonitorFooter();
        }

        perfAnimationId = requestAnimationFrame(perfLoop);
    }

    function setBar(id, value, max, label) {
        const bar = $(`#${id}`);
        const val = $(`#${id}Val`);
        if (bar) bar.style.width = `${(value / max) * 100}%`;
        if (val) val.textContent = label;
    }

    function updateMonitorFooter() {
        const now = new Date();
        const ts = `${String(now.getHours()).padStart(2, '0')}:${String(now.getMinutes()).padStart(2, '0')}:${String(now.getSeconds()).padStart(2, '0')}`;
        const text = `Live data • Updated at ${ts} • Refresh: ${PERF_UPDATE_INTERVAL}ms • Using requestAnimationFrame for smooth interpolation`;
        $('#monitorStatusText').textContent = text;
    }

    // ─── About Dialog — Changelog Tabs ──────
    function initChangelogTabs() {
        $$('.changelog-tab').forEach(tab => {
            tab.addEventListener('click', () => {
                $$('.changelog-tab').forEach(t => t.classList.remove('active'));
                tab.classList.add('active');
                $$('.changelog-content').forEach(c => c.style.display = 'none');
                $(`#changelog-${tab.dataset.ver}`).style.display = 'block';
            });
        });
    }

    // ─── Event Listeners ────────────────────
    function init() {
        // Navigation
        $$('.nav-btn').forEach(btn => {
            btn.addEventListener('click', () => showPage(btn.dataset.page));
        });

        // Theme
        $('#themeToggle').addEventListener('click', toggleTheme);

        // Express install → show confirm page
        $('#btnExpress').addEventListener('click', () => {
            $('#confirmVersion').textContent = `v${latestVersion} (Latest Stable)`;
            showPage('express-confirm');
        });

        // Express confirm actions
        $('#btnConfirmExpress').addEventListener('click', () => {
            const kernelType = document.querySelector('input[name="expressKernel"]:checked').value;
            simulateInstall({
                version: latestVersion,
                openKernel: kernelType === 'open',
                deepClean: false,
            });
        });
        $('#btnCancelExpress').addEventListener('click', () => showPage('install'));
        $('#btnBackFromExpress').addEventListener('click', () => showPage('install'));

        // Custom install → expert page
        $('#btnCustom').addEventListener('click', () => {
            renderVersionList();
            showPage('expert');
        });

        // Expert page
        $('#btnBack').addEventListener('click', () => showPage('install'));
        $('#openKernel').addEventListener('change', (e) => { useOpenKernel = e.target.checked; });
        $('#deepClean').addEventListener('change', (e) => { deepClean = e.target.checked; });

        $('#btnInstallSelected').addEventListener('click', () => {
            simulateInstall({
                version: selectedVersion,
                openKernel: useOpenKernel,
                deepClean: deepClean,
            });
        });

        $('#btnRemoveAll').addEventListener('click', () => {
            if (confirm('Remove all NVIDIA drivers and revert to nouveau?')) {
                simulateInstall({
                    version: selectedVersion,
                    openKernel: false,
                    deepClean: true,
                });
            }
        });

        // Progress actions
        $('#btnDone').addEventListener('click', () => showPage('install'));
        $('#btnReboot').addEventListener('click', () => {
            alert('System would reboot now.\n(macOS simulation — no actual reboot)');
        });

        // About dialog
        $('#aboutBtn').addEventListener('click', () => { $('#aboutDialog').style.display = 'flex'; });
        $('#closeAbout').addEventListener('click', () => { $('#aboutDialog').style.display = 'none'; });

        // Changelog tabs
        initChangelogTabs();

        // Detect system dark mode
        if (window.matchMedia && window.matchMedia('(prefers-color-scheme: dark)').matches) {
            toggleTheme();
        }

        // Initial data fetch
        fetchLatestVersion();
        detectSecureBoot();
    }

    document.addEventListener('DOMContentLoaded', init);
})();
