# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Prism is a macOS 14.0+ menu bar application for switching Claude Code API providers with one click. It modifies `~/.claude/settings.json` to switch between different API endpoints (e.g., Anthropic Official, 智谱AI) while preserving all other configuration.

## Build Commands

```bash
# Build the project
xcodebuild -project Prism.xcodeproj -scheme Prism -configuration Debug build

# Check for build errors only
xcodebuild -project Prism.xcodeproj -scheme Prism -configuration Debug build 2>&1 | grep -E "(error:|warning:|Build succeeded)"
```

## Architecture

### Core Responsibility: Only Modify `env` Key

**Critical**: ConfigManager must ONLY modify the `env` key in `~/.claude/settings.json`. All other keys in the settings file must remain untouched. The `ClaudeConfig` struct intentionally only includes the `env` field.

### Data Flow

1. **App Launch** → `AppDelegate.applicationDidFinishLaunching`
   - `StatusBarController.shared.setup()` creates menu bar icon and NSPopover
   - `ConfigImportService.shared.importExistingConfigurationIfNeeded()` detects existing Claude Code config and auto-imports matching providers

2. **User Interaction** → `ContentView`
   - Shows "默认" (Default) row + user-added providers
   - User clicks "Activate" on a provider → `ProviderStore.activateProvider()` → `ConfigManager.updateEnvVariables()`
   - User adds/edits provider → `AddEditProviderView` → `ProviderStore.addProvider()/updateProvider()`

3. **Data Persistence**
   - User providers: `ProviderStore` → UserDefaults (key: "saved_providers")
   - Claude Code config: `ConfigManager` → `~/.claude/settings.json` (only `env` key)

### State Management with @Observable

**Critical Pattern**: `ProviderStore` uses macOS 14.0+ `@Observable` macro with proper UserDefaults integration:

```swift
var providers: [Provider] {
    get {
        access(keyPath: \.providers)  // Required for @Observable
        // ... load from UserDefaults
    }
    set {
        withMutation(keyPath: \.providers) {  // Required for @Observable
            // ... save to UserDefaults
        }
    }
}
```

**Do NOT use**: Traditional `didSet` pattern - it won't trigger SwiftUI updates with @Observable.

### Provider Identity

`Provider.id` must be encoded/decoded in Codable implementation. Each Provider has:
- `id: UUID` - Must persist across app launches (explicitly encoded/decoded)
- `name: String`
- `envVariables: [String: String]` - Contains 5 keys: ANTHROPIC_BASE_URL, ANTHROPIC_AUTH_TOKEN, ANTHROPIC_DEFAULT_HAIKU_MODEL, ANTHROPIC_DEFAULT_SONNET_MODEL, ANTHROPIC_DEFAULT_OPUS_MODEL
- `isActive: Bool` - Only one provider can be active at a time

### Sheet Data Passing Pattern

For editing providers, use the `item` variant of `.sheet()`:

```swift
.sheet(item: $editingProvider) { provider in
    AddEditProviderView(provider: provider, onSave: { ... })
}
```

**Do NOT use** `.sheet(isPresented:)` with conditional logic inside - it causes timing issues where the provider data becomes nil.

### Default Provider Logic

The "默认" (Default) row is always shown at the top of the provider list. It's considered active when:
- Claude Code config has no `ANTHROPIC_BASE_URL` OR
- Claude Code config has no `ANTHROPIC_AUTH_TOKEN`

This is checked via `isDefaultActive` computed property in ContentView.

### Custom NSPopover Implementation

The app uses a custom `StatusBarController` with `NSPopover` (not `MenuBarExtra`) for better focus control. This prevents the popup from closing when users interact with text fields or menus.

Key adaptations:
- macOS 14+ uses automatic rounded corners
- Window styling with `.floating` level and transparent titlebar
- `NSHostingController` wraps SwiftUI ContentView

## JSON Encoding Requirements

When writing to `~/.claude/settings.json`, use:

```swift
encoder.outputFormatting = [.prettyPrinted, .withoutEscapingSlashes]
```

This prevents unwanted `\/` escaping in URLs.

## Configuration Import Logic

At app launch, `ConfigImportService` checks existing Claude Code config:
1. If `ANTHROPIC_BASE_URL` matches a template (e.g., 智谱AI's `https://open.bigmodel.cn/api/anthropic`), auto-import with template name
2. If URL doesn't match any template, auto-import as "其它" (Other)
3. If provider already exists (matching both URL and token), activate it instead of duplicating

Template matching includes validation beyond URL matching (e.g., token format checks for 智谱AI).

## File Authorship

When creating new files, use author signature: `okooo5km(十里)`

## Adding New Provider Templates

To add a new provider template:

1. Add to `ProviderTemplate.allTemplates` in Models.swift:
```swift
static let newProvider = ProviderTemplate(
    name: "Provider Name",
    envVariables: [
        "ANTHROPIC_BASE_URL": "https://...",
        "ANTHROPIC_AUTH_TOKEN": "",
        "ANTHROPIC_DEFAULT_HAIKU_MODEL": "model-name",
        "ANTHROPIC_DEFAULT_SONNET_MODEL": "model-name",
        "ANTHROPIC_DEFAULT_OPUS_MODEL": "model-name"
    ]
)
```

2. Add validation logic in `ConfigImportService.isValidProviderForTemplate()` if the provider requires special token format or URL pattern validation.