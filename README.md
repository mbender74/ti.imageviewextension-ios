# ti.imageviewextension

## TiUIImageView Extension for iOS (Titanium Module)

Extends the standard Titanium `Ti.UI.ImageView` with powerful features for smooth image loading and processing. Simply add the module to your **tiapp.xml** — no further setup required!

## Features

| Feature | Description |
|---------|-------------|
| **animated** | Smooth fade-in animation when imageView becomes visible (works in TableView, ListView, ScrollView) |
| **animateOnce** | Animation plays only on first appearance |
|**calcMinMax** | Auto-scale images to `maxWidth`/`maxHeight` while maintaining aspect ratio |
| **noTransparency** | Remove alpha channel for better rendering performance |
| **averageColor** | Calculate the dominant color of an image (useful for background matching) |
| **blurredImage** | Apply Gaussian blur with configurable radius |

## Installation

1. Build or download the module zip (`ti.imageviewextension-iphone-1.0.2.zip`)
2. Place in your project's `modules/iphone/` directory
3. Add to `tiapp.xml`:

```xml
<modules>
    <module version="1.0.2">ti.imageviewextension</module>
</modules>
```

**That's it!** All `Ti.UI.ImageView` instances automatically gain the extended features.

## API Reference

### Additional Properties

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `animated` | `Boolean` | `false` | Fade-in animation when imageView appears. Re-triggers on re-visibility unless `animateOnce` is true |
| `animateOnce` | `Boolean` | `false` | Limit animation to first appearance only |
| `calcMinMax` | `Boolean` | `false` | Scale image to fit within `maxWidth`/`maxHeight` bounds |
| `maxWidth` | `Number` | Image width | Maximum width for `calcMinMax` scaling |
| `maxHeight` | `Number` | Image height | Maximum height for `calcMinMax` scaling |
| `noTransparency` | `Boolean` | `false` | Render image without alpha channel (requires `backgroundColor`) |
| `blurredImage` | `Boolean` | `false` | Apply Gaussian blur filter using Core Image |
| `blurRadius` | `Number` | `15.0` | Blur intensity in pixels (requires `blurredImage: true`) |
| `averageColorDone` | `Boolean` | `false` | Flag to track if average color has been calculated |

### Events

#### `averageColor`

Fired when the image's average color is calculated. Returns RGB values and hex string.

```javascript
imageView.addEventListener('averageColor', function(e) {
    console.log('RGB:', e.color); // [R, G, B] array (0-255)
    console.log('Hex:', imageView.averageColor); // '#FF00AA'
});
```

**Note:** The event fires only once per imageView. Reset `averageColorDone = false` to recalculate.

### Additional Events

#### `imageMinMax`

Fired after image is scaled via `calcMinMax`. Returns the new dimensions.

```javascript
imageView.addEventListener('imageMinMax', function(e) {
    console.log('New width:', e.width);
    console.log('New height:', e.height);
});
```

## Usage Examples

### Basic Fade-In Animation

```javascript
var imageView = Ti.UI.createImageView({
    image: '/assets/photo.jpg',
    animated: true,
    animateOnce: false  // Re-animate on every visibility change
});

win.add(imageView);
```

### Constrained Image Sizing

```javascript
var imageView = Ti.UI.createImageView({
    image: '/assets/landscape.jpg',
    calcMinMax: true,
    maxWidth: 320,
    maxHeight: 240
});
```

### Background Color (No Transparency)

```javascript
var imageView = Ti.UI.createImageView({
    image: '/assets/logo.png',
    noTransparency: true,
    backgroundColor: '#ffffff'
});
```

### Average Color Detection

```javascript
var imageView = Ti.UI.createImageView({
    image: '/assets/hero.jpg',
    averageColorDone: false
});

imageView.addEventListener('averageColor', function(e) {
    var hexColor = imageView.averageColor; // '#AABBCC'
    win.backgroundColor = hexColor;  // Match page background
});
```

### Blurred Image

```javascript
var imageView = Ti.UI.createImageView({
    image: '/assets/background.jpg',
    blurredImage: true,
    blurRadius: 20
});
```

### Complete Example

```javascript
var imageView = Ti.UI.createImageView({
    image: '/assets/photo.jpg',
    height: 260,
    width: Ti.UI.SIZE,
    
    // Animation
    animated: true,
    animateOnce: false,
    
    // Sizing
    calcMinMax: true,
    maxWidth: 280,
    maxHeight: 260,
    
    // Rendering
    noTransparency: false,
    backgroundColor: '#f0f0f0'
});

imageView.addEventListener('averageColor', function(e) {
    console.log('Dominant color:', imageView.averageColor);
});

win.add(imageView);
```

## Performance Notes

- All image processing (blur, resize, color extraction) runs on **background threads** to keep UI at 60fps
- Shared CI context for blur operations reduces memory overhead
- Duplicate image loads are automatically skipped via early-exit detection
- Use `noTransparency: true` with `backgroundColor` for better scrolling performance in lists

## Compatibility

- **Titanium SDK:** 13.2.0+
- **iOS:** 13.0+
- **Architecture:** arm64, x86_64 (Simulator)

## Changelog

### v1.1.0 (2026-06-01)
- ✅ Fixed average color calculation (RGB order & hex formatting)
- ✅ Optimized image processing pipeline (non-blocking UI thread)
- ✅ Shared CIContext for blur operations (better performance)
- ✅ Early-exit for duplicate image loads
- ✅ Property caching to reduce proxy lookups
- ✅ Modern Objective-C syntax (`@()` literals, `UIGraphicsBeginImageContextWithOptions`)
- ✅ Fixed blur extent handling & image scaling
- ✅ Updated SDK version in titanium.xcconfig (13.2.0.GA)

### v1.0.3 (2026-05-31)
- Initial release with extended TiUIImageView features

## License

Apache 2.0 - See [LICENSE](LICENSE)

## Author

Created by Marc Bender - Copyright (c) 2022
