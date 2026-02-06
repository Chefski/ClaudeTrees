# ClaudeTrees

ClaudeTrees is a macOS menu bar app for two day-to-day workflows:

1. Enabling/disabling MCP servers from `~/.claude/settings.json`
2. Creating and opening Git worktrees from a lightweight popover UI

The app runs as a menu bar extra (`LSUIElement`), so it does not show a Dock icon or a main app window.

> Note: This project is still a work in progress

## Features

- Toggle MCP servers on/off by writing the `disabled` flag in `~/.claude/settings.json`
- Preserve unrelated keys in your Claude settings file while editing MCP entries
- Add and persist Git repositories for quick worktree access
- List existing worktrees per repo (`git worktree list --porcelain`)
- Create a new worktree with a new branch from a chosen base branch
- Open worktrees in Finder or directly in your preferred terminal app
- Optional launch-at-login setting

## Supported Terminals

ClaudeTrees detects installed terminals and lets you choose among:

- Ghostty
- Terminal.app
- iTerm2
- Warp
- Alacritty
- Kitty
- WezTerm
- Rio

## Requirements

- macOS (project deployment target is currently `26.2`)
- Xcode with SwiftUI support
- Git installed (`/usr/bin/git`)
- Optional: `~/.claude/settings.json` with an `mcpServers` object

## Getting Started

1. Clone this repository.
2. Open `ClaudeTrees.xcodeproj` in Xcode.
3. Select the `ClaudeTrees` scheme.
4. Build and run.
5. Click the branch icon in the macOS menu bar to open the app.

## Usage

### MCPs tab

- Reads `~/.claude/settings.json`
- Shows MCP servers from `mcpServers`
- Use toggles to enable/disable servers
- Changes are saved back to the same file

### Worktrees tab

1. Click `+` and pick a local Git repository.
2. Expand the repo section to view its worktrees.
3. Use `+` on a repo to create a new worktree:
   - Enter new branch name
   - Choose base branch
   - Click **Create & Open**
4. Use row actions to open a worktree in Finder or terminal.

### Settings

- Choose preferred terminal
- Toggle launch at login
- Configure Claude CLI path (stored in app settings)

## Tests

The project includes Swift Testing-based unit tests in `ClaudeTreesTests/` and UI tests in `ClaudeTreesUITests/`.

You can run tests in Xcode, or from CLI:

```bash
xcodebuild -scheme ClaudeTrees -configuration Debug test
```

## Project Layout

- `ClaudeTrees/` - app source
  - `Models/` - app data models
  - `Services/` - Git, settings, terminal launching, persistence
  - `Views/` - SwiftUI views for MCPs/worktrees/settings
- `ClaudeTreesTests/` - unit tests
- `ClaudeTreesUITests/` - UI tests
