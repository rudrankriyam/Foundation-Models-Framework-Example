# FoundationLabsKit

A shared Swift Package containing common UI components and utilities for Foundation Labs apps.

## Package Structure

### Extensions
- **Color+Extensions.swift**: Common color utilities and platform-specific background colors
- **View+Extensions.swift**: Common view modifiers including conditional modifiers
- **View+AnimationEffects.swift**: Reusable animation effects (breathing, pulse, shimmer)

### Components (To Be Added)
- Chat components (ChatInputView, MessageBubbleView)
- Common button styles
- Card layouts
- Loading indicators

## Integration Status

### ✅ Completed
1. Created package structure with iOS 26, macOS 26, visionOS 26 support
2. Moved Color extensions with:
   - Common background colors
   - HealthColors namespace for health-related colors
   - AppColorScheme protocol for app-specific color schemes
3. Moved View extensions with:
   - Conditional modifiers (`if`, `ifLet`)
   - Common effects (softShadow, glow)
   - Animation effects (breathing, pulse, shimmer)
4. Created compatibility files:
   - Foundation Lab: `Color+AppColors.swift` (defines `.main` as mint)
   - Body Buddy: `HealthColors+App.swift` (maps legacy names to new namespace)

### ⏳ Next Steps
1. **Add Package to Xcode Project**:
   - Open FoundationLab.xcodeproj in Xcode
   - File → Add Package Dependencies
   - Add Local Package → Select `Packages/FoundationLabsKit`
   
2. **Update Imports**:
   - Add `import FoundationLabsKit` to files using the extensions
   - Remove `.backup` files once confirmed working

3. **Move Chat Components**:
   - Extract common chat functionality to package
   - Create protocols for customization points
   - Update both apps to use shared components

## Usage

### Color Extensions
```swift
import FoundationLabsKit

// Use common colors
view.background(Color.secondaryBackgroundColor)

// Use health colors
Text("Heart Rate")
    .foregroundColor(HealthColors.heart)
```

### View Extensions
```swift
import FoundationLabsKit

// Conditional modifiers
Text("Hello")
    .if(isLarge) { $0.font(.largeTitle) }

// Animation effects
Image(systemName: "heart.fill")
    .pulse(color: HealthColors.heart)
```

## Migration Guide

### Foundation Lab
- Replace `Color+Extensions.swift` imports with `import FoundationLabsKit`
- App-specific `Color.main` remains in `Color+AppColors.swift`

### Body Buddy
- Replace `HealthColors.swift` imports with `import FoundationLabsKit`
- Legacy color names work via `HealthColors+App.swift` mappings
- Consider updating to use `HealthColors.primary` instead of `.healthPrimary`