# Contributing to ro-Control

## Workflow

- branch from `main`
- keep changes focused
- open a pull request back to `main`
- avoid direct pushes to `main`

Recommended branch prefixes:

- `feat/`
- `fix/`
- `docs/`
- `chore/`

## Before Opening a PR

- build the project successfully
- run tests
- update translations if user-facing strings changed
- include screenshots for visible UI changes when relevant

Suggested commands:

```bash
cmake -S . -B build -DCMAKE_BUILD_TYPE=Release -DBUILD_TESTS=ON
cmake --build build --parallel
ctest --test-dir build --output-on-failure
```

## Style

- keep English as the source language in code
- use `qsTr(...)` in QML and `tr(...)` in C++
- prefer small, reviewable pull requests

## Issues

- use bug reports for defects
- use feature requests for product changes
- keep reproduction steps concrete
