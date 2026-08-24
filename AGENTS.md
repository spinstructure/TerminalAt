# AGENTS.md — Codex instructions for TerminalAt

This repository contains **TerminalAt**, a small native macOS utility written in Swift/SwiftUI.
These instructions are intended for Codex and other coding agents working in this repository.

## Project goals

TerminalAt should remain:

- small and fast;
- native to macOS;
- dependency-free unless a dependency is clearly justified;
- usable without Homebrew or a full Xcode project;
- buildable with Apple's Command Line Tools;
- easy to install locally with `./install.sh`.

## Supported platform

- macOS 13 Ventura or later.
- Apple Terminal is the target terminal application unless the user explicitly requests another terminal.

## Repository layout

- `Sources/` — Swift source code.
- `Info.plist` — application bundle metadata.
- `build.sh` — compiles a local `.app` into `build/` without installing it.
- `install.sh` — builds, ad-hoc signs, installs to `~/Applications/TerminalAt.app`, and opens the app.
- `uninstall.sh` — removes the installed app while preserving preferences by default.
- `README.md` — user-facing documentation.
- `CHANGELOG.md` — user-visible changes.
- `VERSION` — current release version.
- `.github/workflows/build.yml` — macOS CI compile check.

## Required validation after code changes

On macOS, run:

```zsh
./build.sh
```

A successful change must leave:

```text
build/TerminalAt.app
```

The build script also validates `Info.plist` and ad-hoc signs the local application bundle.

If a change affects installation behavior, also test:

```zsh
./install.sh
```

Then launch TerminalAt and verify the relevant workflow manually.

## Behavioral invariants

Unless the task explicitly changes them, preserve these behaviors:

1. Clicking the Dock icon or pressing `⌥⌘T` reveals the chooser.
2. Closing the chooser hides it instead of terminating the process.
3. `⌘Q` actually quits TerminalAt.
4. Selecting a folder opens Apple Terminal at that folder and hides TerminalAt.
5. Recent folders and favorites persist through `UserDefaults`.
6. Spotlight searches folders under the user's home directory and suppresses hidden and `~/Library` noise.
7. `⌘O` opens the standard macOS directory chooser.
8. Direct paths beginning with `/` or `~` can be opened without Spotlight.
9. No shell command should be constructed from an unquoted user path when a safer URL/file API is available.

## Editing guidelines

- Prefer Apple frameworks (`SwiftUI`, `AppKit`, `Foundation`) over third-party packages.
- Keep source files focused; add a new file rather than making one file excessively large.
- Do not commit generated `.app` bundles or build products.
- Do not change `CFBundleIdentifier` (`com.terminalat.app`) casually because that would split the app's preferences/history.
- If user-visible behavior changes, update `README.md` and `CHANGELOG.md` in the same change.
- `VERSION` is the source of truth for the user-facing app version; `build.sh` stamps it into the built `Info.plist`. If the release version changes, update `VERSION` and the corresponding changelog heading.
- Keep installation commands copy-pasteable in zsh.

## CI limitations

GitHub Actions verifies compilation on macOS but does not exercise the interactive GUI. Changes involving window behavior, keyboard focus, drag-and-drop, Spotlight result quality, or Terminal launching still require a manual macOS smoke test.
