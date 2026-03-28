# Add "Git panel open by default" setting

## Context

The git tree panel (`showGitTree`) is currently hardcoded to `true` at init in `AppModel`. The user wants a General setting to control this default.

## Changes

### 1. `ClaudeHub/Shared/AppModel.swift`
- Read `@AppStorage("gitPanelOpenByDefault")` (default `true`) to initialize `showGitTree`

Since `AppModel` is `@Observable` (not a View), we can't use `@AppStorage` directly. Instead, read `UserDefaults.standard.object(forKey:)` in an initializer:

```swift
var showGitTree: Bool

init() {
    let defaults = UserDefaults.standard
    // nil means never set → default true
    showGitTree = defaults.object(forKey: "gitPanelOpenByDefault") as? Bool ?? true
}
```

### 2. `ClaudeHub/Features/Settings/organisms/GeneralSettingsSection.swift`
- Add `@Binding var gitPanelOpenByDefault: Bool` property
- Add a toggle section (same pattern as `permissionsSection`):
  - Title: "Git Panel Open by Default"
  - Description: "Show the git tree panel when opening a project."
- Place it between `ideSection` and `permissionsSection`
- Update preview

### 3. `ClaudeHub/Features/Settings/pages/SettingsPage.swift`
- Add `@AppStorage("gitPanelOpenByDefault") private var gitPanelOpenByDefault = true`
- Pass `$gitPanelOpenByDefault` to `GeneralSettingsSection`

## Commits

1. `feat(settings): add git panel open by default toggle` — after build verification

## Verification

- `xcodebuild -scheme ClaudeHub -destination 'platform=macOS' build`
