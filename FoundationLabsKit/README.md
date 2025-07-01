# FoundationLabsKit

A shared Swift Package containing common UI components and utilities for Foundation Labs apps.

## Installation

### Swift Package Manager

Add this package to your project using Swift Package Manager:

```swift
dependencies: [
    .package(url: "https://github.com/rudrankriyam/Foundation-Models-Framework-Example.git", from: "1.0.0")
]
```

Then add `FoundationLabsKit` to your target dependencies:

```swift
.target(
    name: "YourApp",
    dependencies: ["FoundationLabsKit"]
)
```

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

### Health Colors
```swift
// Primary health colors
HealthColors.primary    // Bright cyan
HealthColors.secondary  // Fresh green
HealthColors.accent     // Warm coral

// Metric-specific colors
HealthColors.heart      // Heart red
HealthColors.steps      // Activity blue
HealthColors.sleep      // Sleep purple
HealthColors.calories   // Energy orange
HealthColors.mindfulness // Calm teal

// Status colors
HealthColors.success    // Success green
HealthColors.warning    // Warning yellow
HealthColors.alert      // Alert red
```

## Requirements

- iOS 26.0+
- macOS 26.0+
- visionOS 26.0+
- Swift 6.0+

## License

This package is part of the Foundation Models Framework Example project.