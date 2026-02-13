FROM fedora:40

# Install Rust and Qt6/QML build dependencies
RUN dnf install -y \
    rust cargo clippy rustfmt \
    cmake gcc-c++ pkgconf-pkg-config \
    qt6-qtbase-devel qt6-qtdeclarative-devel qt6-qtwayland-devel \
    kf6-qqc2-desktop-style \
    rpm-build \
    && dnf clean all

WORKDIR /app
COPY . .

# Build release binary
RUN cargo build --release

# Verify binary exists
RUN test -f target/release/ro-control && echo "Build successful"
