# Fedora 43 Packaging Contract

This note captures the packaging requirements for publishing `ro-control` into
the Ro-ASD repository for direct ISO installation.

## Target environment

- Fedora 43 KDE
- Install path must work with:

```bash
dnf -y --refresh --setopt=install_weak_deps=False install ro-control
rpm -q ro-control
command -v ro-control
```

## Required package shape

- `ro-control.<arch>` must provide `/usr/bin/ro-control`
- `ro-control-common.noarch` must contain shared assets only
- `ro-control.<arch>` may depend on `ro-control-common = %{version}-%{release}`

## Forbidden ABI dependencies

These must not appear in `rpm -qpR ro-control-*.rpm`:

- `Qt_6.10`
- `Qt_6.10_PRIVATE_API`
- any `PRIVATE_API` symbol requirement

## Build rules

- Build in Fedora 43, not `fedora:latest`, Fedora 44, or Rawhide
- Do not add Qt private module link targets
- Do not include `#include <private/...>` headers
- Do not require `qt6-qtbase-private-devel` unless the code proves it is needed

## Acceptance checks

```bash
dnf clean all
dnf -y --refresh --setopt=install_weak_deps=False install ro-control
rpm -q ro-control
command -v ro-control
ldd -r /usr/bin/ro-control
rpm -q --whatprovides /usr/bin/ro-control
rpm -qpR ro-control-*.rpm
rpm -qpl ro-control-*.rpm | grep /usr/bin/ro-control
```

Expected provider for `/usr/bin/ro-control`:

```text
ro-control
```
