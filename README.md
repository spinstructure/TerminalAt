# TerminalAt

**TerminalAt** is a small native macOS utility for opening Apple Terminal directly in a folder without first navigating through Finder.

It is intentionally lightweight: Swift/SwiftUI, Apple frameworks only, no Homebrew dependencies, and no Xcode project required.

## Features

- Spotlight-backed folder search within your home directory
- Recent Terminal folders
- Pinned Favorites
- Direct path entry such as `~/Documents/Research`
- Standard macOS folder chooser with `⌘O`
- Drag-and-drop folder opening
- Keyboard navigation with `↑`, `↓`, `Return`, and `Esc`
- Global `⌥⌘T` shortcut while TerminalAt is running
- Opens the selected directory in Apple Terminal
- Hides its chooser after opening Terminal while remaining available for the global shortcut

## Requirements

- macOS 13 Ventura or later
- Apple Terminal
- Apple's developer Command Line Tools

You do **not** need Homebrew, third-party Swift packages, or the full Xcode application.

## Install

Clone the repository or download it as a ZIP, then open Terminal in the repository directory and run:

```zsh
./install.sh
```

If the Command Line Tools are not installed, macOS will need them first:

```zsh
xcode-select --install
```

Then rerun:

```zsh
./install.sh
```

The installer:

1. builds TerminalAt locally;
2. validates and ad-hoc signs the application bundle;
3. installs it at `~/Applications/TerminalAt.app`;
4. opens the app.

### Put TerminalAt in the Dock

After installation, open:

```zsh
open ~/Applications
```

Drag **TerminalAt.app** to the application side of the Dock.

Leave TerminalAt running if you want the global `⌥⌘T` shortcut to remain available.

## Use

### Search for a folder

Click TerminalAt in the Dock or press:

```text
⌥⌘T
```

Start typing part of a folder name, for example:

```text
macset
```

TerminalAt searches folder metadata through macOS Spotlight.

Keyboard controls:

- `↑` / `↓` — move through results
- `Return` — open the selected folder in Terminal
- `Esc` — hide TerminalAt
- `⌘O` — choose a folder using the standard macOS folder picker
- `⌘Q` — quit TerminalAt completely

### Enter a path directly

You can enter an existing directory such as:

```text
~/Documents/Research
```

or:

```text
/Users/yourname/Documents/Research
```

### Favorites

Click the star beside a folder to pin it. Favorites appear above Recents.

### Recents

Each folder opened through TerminalAt is recorded in TerminalAt's own recent history. It stores only:

- the folder path;
- the last-used time;
- whether the folder is a Favorite.

### Drag and drop

Drag a folder onto the TerminalAt window to open Terminal there immediately.

## Why TerminalAt stays running

The global `⌥⌘T` shortcut requires TerminalAt to have a running process.

Therefore:

- opening a folder hides the TerminalAt window;
- closing the chooser hides it rather than terminating the app;
- `⌥⌘T` brings it back;
- `⌘Q` actually quits it.

## Spotlight behavior

TerminalAt uses Apple's `NSMetadataQuery` Spotlight metadata interface.

By default it:

- searches under your home directory;
- matches folder names and paths;
- suppresses hidden directories;
- suppresses `~/Library` results to reduce noise.

If Spotlight has not indexed a directory, use `⌘O` or enter its exact path instead.

## Build without installing

For development or verification, run:

```zsh
./build.sh
```

A successful build creates:

```text
build/TerminalAt.app
```

This does **not** modify the installed copy in `~/Applications`.

That separation is useful for automated edits and Codex work.

## Working with Codex

This repository includes [`AGENTS.md`](AGENTS.md), which gives Codex repository-specific instructions, including:

- project architecture;
- behavioral invariants to preserve;
- required build validation;
- documentation/versioning expectations;
- constraints against unnecessary dependencies.

For future changes, a useful Codex request is:

```text
Implement <change> in TerminalAt. Follow AGENTS.md, run ./build.sh on macOS,
and update README.md and CHANGELOG.md if user-visible behavior changes.
```

Generated `.app` bundles and build products are excluded by `.gitignore`, so Codex should edit source rather than commit binaries.

## Continuous integration

The repository includes a GitHub Actions workflow at:

```text
.github/workflows/build.yml
```

On pushes to `main` and on pull requests, GitHub runs a macOS build of TerminalAt. A successful workflow also uploads the built application as a workflow artifact.

This catches compiler/build regressions, although interactive UI behavior still requires a manual macOS test.

## Repository layout

```text
TerminalAt/
├── .github/
│   └── workflows/
│       └── build.yml
├── Sources/
│   ├── AppModel.swift
│   ├── ContentView.swift
│   ├── FolderRecord.swift
│   ├── HotKeyManager.swift
│   ├── KeyboardSearchField.swift
│   ├── SpotlightSearcher.swift
│   ├── TerminalAtMain.swift
│   └── TerminalLauncher.swift
├── .editorconfig
├── .gitattributes
├── .gitignore
├── AGENTS.md
├── CHANGELOG.md
├── Info.plist
├── README.md
├── VERSION
├── build.sh
├── install.sh
└── uninstall.sh
```

## Uninstall

From the repository directory:

```zsh
./uninstall.sh
```

This removes:

```text
~/Applications/TerminalAt.app
```

but preserves Favorites and recent-folder history.

To remove those preferences too:

```zsh
defaults delete com.terminalat.app
```

## Updating an existing installation after a code change

After pulling or applying changes, run:

```zsh
./install.sh
```

The script rebuilds TerminalAt and replaces the installed copy in `~/Applications`.

## License

No open-source license is included yet. Choose and add a license before treating the repository as an open-source project or inviting third-party reuse/contributions.
