# ArcPicker

A customizable **semi-circular picker** for SwiftUI that allows users to select integer values along an arc. Inspired by Apple’s human interface guidelines, `ArcPicker` provides a smooth, dial-like interaction for numeric input such as weight, speed, temperature, or distance.

> **Requires iOS 18.0 or later.**

---

## Features

* **Semi-circular dial interface**: Displays values along a horizontal arc.
* **Smooth scrolling**: Supports precise and natural selection using a `ScrollView`.
* **Customizable appearance**: Easily adjust colors, tick frequency, stroke styles, and height.
* **Active tick highlighting**: Shows a marker and label for the currently selected value.
* **Fully reusable**: Designed to integrate seamlessly into any SwiftUI project.

---

## Example Usage

```swift
import SwiftUI
import ArcPicker

struct ContentView: View {
    @State private var weight = 70
    
    var body: some View {
        ArcPicker(range: 5...150, selectedValue: $weight) { value in
            Text("\(value) kg")
                .font(.title2)
                .bold()
        }
        .frame(height: 200)
    }
}
```

---

## Configuration

You can customize `ArcPicker` using `ArcPickerConfig`:

```swift
let config = ArcPicker.ArcPickerConfig(
    activeTint: .blue,
    inactiveTint: .gray.opacity(0.5),
    largeTickFrequency: 5,
    strokeStyle: StrokeStyle(lineWidth: 40, lineCap: .round, lineJoin: .round),
    strokeColor: .black.opacity(0.1),
    height: 180,
    isCompleteInteractionEnabled: true
)

ArcPicker(range: 0...100, selectedValue: $value, config: config) { value in
    Text("\(value)")
}
```

### Configurable Properties

| Property                       | Description                        | Default                |
| ------------------------------ | ---------------------------------- | ---------------------- |
| `activeTint`                   | Color of the active tick and label | `.primary`             |
| `inactiveTint`                 | Color of inactive ticks            | `.gray`                |
| `largeTickFrequency`           | Frequency of larger tick marks     | `10`                   |
| `strokeStyle`                  | Stroke style for the arc           | Rounded line, width 50 |
| `strokeColor`                  | Arc color                          | `.black.opacity(0.1)`  |
| `height`                       | Overall picker height              | `200`                  |
| `isCompleteInteractionEnabled` | Enable full-area scrolling         | `true`                 |

---

## Implementation Notes

* Built using **SwiftUI** and **GeometryReader** for precise layout.
* Uses `ScrollView` and `LazyHStack` for high-performance scrolling with a large number of ticks.
* Designed to follow Apple’s **Human Interface Guidelines**:

  * Smooth, intuitive interactions.
  * Clear visual distinction between active and inactive elements.
  * Adaptive to different sizes and layouts.

---

## Requirements

* iOS 18.0+
* Swift 5.9+
* SwiftUI

---

## License

`ArcPicker` is open-source and can be freely integrated into personal or commercial projects.

---

✅ **Tip:** This picker works best for numeric ranges with moderate step counts (e.g., 0–150). For extremely large ranges, consider adjusting `largeTickFrequency` for optimal performance.
