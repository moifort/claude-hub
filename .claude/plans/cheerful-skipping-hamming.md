# Replace SidebarTaskRow status icon with small pulsing dot

## Context

The `SidebarTaskRow` currently uses a large SF Symbol icon (20pt font, 24px frame) for status display (`play.circle.fill`, `clock`, `checkmark.circle.fill`, etc.). This takes significant horizontal space in the narrow sidebar (220-360px). The user wants the same compact approach as `ProjectRow`'s running indicator: a small colored dot that pulses when running, freeing space for a 3-line title.

## Changes

### File: `ClaudeHub/Features/Sidebar/molecules/SidebarTaskRow.swift`

**Replace the status icon** (lines 11-14):
```swift
// Before:
Image(systemName: status.iconName)
    .font(.system(size: 20))
    .foregroundStyle(status.tintColor)
    .frame(width: 24)

// After:
Image(systemName: "circle.fill")
    .font(.system(size: 6))
    .foregroundStyle(status.tintColor)
    .symbolEffect(.pulse, isActive: status == .running)
    .frame(width: 12)
```

- Icon: `circle.fill` (6pt) — same as `ProjectRow`'s running dot
- Color: `status.tintColor` — preserves per-status color (blue/orange/green/secondary)
- Pulse: `.symbolEffect(.pulse, isActive: status == .running)` — shimmers only when running
- Frame: reduced from 24px to 12px — frees ~12px for text

**Increase text line limit** (line 19):
```swift
// Before:
.lineLimit(2)

// After:
.lineLimit(3)
```

**Adjust alignment** (line 10): Change from `.top` to `.center` since the dot is now much smaller and looks better centered.

## Verification

1. `xcodebuild -scheme ClaudeHub -destination 'platform=macOS' build`
2. Visual check: sidebar task rows show small colored dot, pulsing for running tasks, text wraps to 3 lines

## Commits

1. `refactor(sidebar): replace task status icon with compact pulsing dot`
