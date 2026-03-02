# ─── Stage 1: Build ──────────────────────────────────────────────
FROM fedora:42 AS builder

# Install build dependencies (Rust via rustup, Qt6/QML headers)
RUN dnf install -y \
    curl gcc gcc-c++ cmake pkgconf-pkg-config \
    qt6-qtbase-devel qt6-qtdeclarative-devel qt6-qtwayland-devel \
    kf6-qqc2-desktop-style \
    && dnf clean all

# Install Rust via rustup (matches CI toolchain)
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | \
    sh -s -- -y --default-toolchain 1.88.0 --profile minimal
ENV PATH="/root/.cargo/bin:${PATH}"

WORKDIR /app
COPY . .

RUN cargo build --release && \
    strip target/release/ro-control

# ─── Stage 2: Runtime ────────────────────────────────────────────
FROM fedora:42

RUN dnf install -y \
    qt6-qtbase qt6-qtdeclarative qt6-qtwayland \
    kf6-qqc2-desktop-style \
    && dnf clean all

COPY --from=builder /app/target/release/ro-control /usr/bin/ro-control
COPY --from=builder /app/scripts/ro-control-root-task /usr/bin/ro-control-root-task
COPY --from=builder /app/data/io.github.AcikKaynakGelistirmeToplulugu.ro-control.desktop /usr/share/applications/io.github.AcikKaynakGelistirmeToplulugu.ro-control.desktop
COPY --from=builder /app/data/io.github.AcikKaynakGelistirmeToplulugu.ro-control.metainfo.xml /usr/share/metainfo/io.github.AcikKaynakGelistirmeToplulugu.ro-control.metainfo.xml
COPY --from=builder /app/data/polkit/io.github.AcikKaynakGelistirmeToplulugu.ro-control.policy /usr/share/polkit-1/actions/io.github.AcikKaynakGelistirmeToplulugu.ro-control.policy
COPY --from=builder /app/data/io.github.AcikKaynakGelistirmeToplulugu.ro-control.gschema.xml /usr/share/glib-2.0/schemas/io.github.AcikKaynakGelistirmeToplulugu.ro-control.gschema.xml
COPY --from=builder /app/data/icons/ /usr/share/icons/

ENTRYPOINT ["ro-control"]
