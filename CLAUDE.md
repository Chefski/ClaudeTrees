# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

ClaudeTrees is a macOS menu bar app (SwiftUI) for managing MCP servers and git worktrees. It lives in the system menu bar using `MenuBarExtra` with a windowed popover style. The app has no main window — `LSUIElement` is set to `YES`, making it an agent app (no Dock icon).

## Build & Test

Open `ClaudeTrees.xcodeproj` in Xcode. Do not run Xcode builds from CLI unless explicitly asked.

```
# Build from CLI (only when asked)
xcodebuild -scheme ClaudeTrees -configuration Debug build

# Run unit tests
xcodebuild -scheme ClaudeTrees -configuration Debug test

# Run a single test
xcodebuild -scheme ClaudeTrees -configuration Debug -only-testing:ClaudeTreesTests/ClaudeTreesTests/testExample test
```

## Architecture

- **ClaudeTreesApp.swift** — App entry point. Sets up `MenuBarExtra` with a branch icon (`arrow.triangle.branch`) and renders `PopoverView` in a `.window` style popover.
- **PopoverView.swift** — Main UI. Segmented picker switching between "MCPs" and "Worktrees" tabs (currently placeholder content).

## Swift Settings

- Swift 5 with `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor` and `SWIFT_APPROACHABLE_CONCURRENCY = YES`
- Deployment target: macOS 26.2
- App Sandbox and Hardened Runtime enabled
- Tests use Swift Testing framework (`import Testing`, `@Test`, `#expect`)
- UI tests use XCTest

## Conventions

- Credit "Patryk Radziszewski" in new Swift file headers with format `Created by Patryk Radziszewski on dd/mm/yyyy.`
- Bundle ID: `com.chefski.ClaudeTrees`
