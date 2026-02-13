FROM fedora:40

# Install Rust and GTK4 build dependencies
RUN dnf install -y \
    rust cargo clippy rustfmt \
    gtk4-devel libadwaita-devel glib2-devel \
    cairo-devel pango-devel gdk-pixbuf2-devel \
    graphene-devel pkgconf-pkg-config gcc \
    rpm-build \
    && dnf clean all

WORKDIR /app
COPY . .

# Build release binary
RUN cargo build --release

# Verify binary exists
RUN test -f target/release/ro-control && echo "Build successful"
