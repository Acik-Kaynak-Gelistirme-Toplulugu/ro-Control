# Makefile for ro-Control
# Follows FreeDesktop installation conventions
# Usage: sudo make install (after cargo build --release)

prefix ?= /usr/local
bindir = $(prefix)/bin
datadir = $(prefix)/share
iconsdir = $(datadir)/icons/hicolor
applicationsdir = $(datadir)/applications
metainfodir = $(datadir)/metainfo
polkitdir = $(datadir)/polkit-1/actions
gschemasdir = $(datadir)/glib-2.0/schemas

BINARY = target/release/ro-control
APP_ID = io.github.AcikKaynakGelistirmeToplulugu.ro-control

.PHONY: all build install uninstall clean test fmt clippy check lint dist

all: build

build:
	cargo build --release

check:
	cargo check --all-targets

test:
	cargo test --all-targets

fmt:
	cargo fmt --all

clippy:
	cargo clippy --all-targets -- -D warnings -A dead_code -A clippy::incompatible_msrv

lint: fmt clippy

install: build
	# Binary
	install -Dm755 $(BINARY) $(DESTDIR)$(bindir)/ro-control
	install -Dm755 scripts/ro-control-root-task $(DESTDIR)$(bindir)/ro-control-root-task

	# Desktop entry
	install -Dm644 data/$(APP_ID).desktop $(DESTDIR)$(applicationsdir)/$(APP_ID).desktop

	# AppStream metainfo
	install -Dm644 data/$(APP_ID).metainfo.xml $(DESTDIR)$(metainfodir)/$(APP_ID).metainfo.xml

	# Icons
	install -Dm644 data/icons/hicolor/scalable/apps/$(APP_ID).svg \
		$(DESTDIR)$(iconsdir)/scalable/apps/$(APP_ID).svg
	install -Dm644 data/icons/hicolor/symbolic/apps/$(APP_ID)-symbolic.svg \
		$(DESTDIR)$(iconsdir)/symbolic/apps/$(APP_ID)-symbolic.svg

	# PolicyKit
	install -Dm644 data/polkit/$(APP_ID).policy $(DESTDIR)$(polkitdir)/$(APP_ID).policy

	# GSettings schema
	install -Dm644 data/$(APP_ID).gschema.xml $(DESTDIR)$(gschemasdir)/$(APP_ID).gschema.xml

	# Post-install triggers
	if [ -z "$(DESTDIR)" ]; then \
		glib-compile-schemas $(gschemasdir) 2>/dev/null || true; \
		update-desktop-database $(applicationsdir) 2>/dev/null || true; \
	fi

uninstall:
	rm -f $(DESTDIR)$(bindir)/ro-control
	rm -f $(DESTDIR)$(bindir)/ro-control-root-task
	rm -f $(DESTDIR)$(applicationsdir)/$(APP_ID).desktop
	rm -f $(DESTDIR)$(metainfodir)/$(APP_ID).metainfo.xml
	rm -f $(DESTDIR)$(iconsdir)/scalable/apps/$(APP_ID).svg
	rm -f $(DESTDIR)$(iconsdir)/symbolic/apps/$(APP_ID)-symbolic.svg
	rm -f $(DESTDIR)$(polkitdir)/$(APP_ID).policy
	rm -f $(DESTDIR)$(gschemasdir)/$(APP_ID).gschema.xml

	if [ -z "$(DESTDIR)" ]; then \
		glib-compile-schemas $(gschemasdir) 2>/dev/null || true; \
	fi

clean:
	cargo clean

dist:
	@echo "packing source tarball..."
	git archive --format=tar.gz --prefix=ro-control-$(shell grep '^version' Cargo.toml | head -1 | sed 's/.*"\(.*\)"/\1/')/ \
		HEAD > ro-control-$(shell grep '^version' Cargo.toml | head -1 | sed 's/.*"\(.*\)"/\1/').tar.gz
