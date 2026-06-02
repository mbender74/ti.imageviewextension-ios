# ti.imageviewextension Module

## Description

A Titanium iOS module that extends `Ti.UI.ImageView` with advanced image processing capabilities. The module works as a **transparent extension** — simply install it and all ImageView instances gain the new features automatically. No `require()` needed.

### Key Features

- **Animated fade-in** — Smooth fade-in animation for scrollable containers
- **Auto-scaling** — Constrain images to max dimensions while maintaining aspect ratio
- **Gaussian blur** — Apply blur effects using Core Image
- **Average color detection** — Extract dominant color for UI theming
- **Performance optimization** — Remove transparency, rasterize layers, tint colors
- **Hi-res loading** — Support for @2x/@3x retina images
- **Auto-rotate** — Correct image orientation from EXIF data

---

## Installation

Add to your `tiapp.xml`:

```xml
<modules>
    <module version="1.3.7">ti.imageviewextension</module>
</modules>
```

Place the module zip in `modules/iphone/` directory. That's it — all ImageView instances automatically gain extended features.

---

## Accessing the Module

This module operates as a **transparent extension** via Objective-C categories on `TiUIImageView`. You do **not** need to `require()` it:

```javascript
// No require needed!
var imageView = Ti.UI.createImageView({
    image: '/myimage.jpg',
    animated: true,
    calcMinMax: true,
    maxWidth: 300
});
```

---

## API Reference

### Properties

#### Animation

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `animated` | `Boolean` | `false` | Smooth fade-in (0.5s) when imageView becomes visible. Re-triggers on re-visibility unless `animateOnce: true` |
| `animateOnce` | `Boolean` | `false` | Animation plays only on first appearance |

#### Sizing

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `calcMinMax` | `Boolean` | `false` | Scale image to fit within `maxWidth`/`maxHeight` while maintaining aspect ratio |
| `maxWidth` | `Number` | Image width | Maximum width for `calcMinMax` scaling |
| `maxHeight` | `Number` | Image height | Maximum height for `calcMinMax` scaling |

#### Image Processing

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `blurredImage` | `Boolean` | `false` | Apply Gaussian blur using Core Image `CIGaussianBlur` |
| `blurRadius` | `Number` | `15.0` | Blur intensity in pixels (higher = more blur) |
| `noTransparency` | `Boolean` | `false` | Remove alpha channel, fill with `backgroundColor` |
| `hires` | `Boolean` | `false` | Load @2x/@3x resolution version of image |
| `autorotate` | `Boolean` | `true` | Auto-correct orientation from EXIF data |

#### Rendering

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `shouldRasterize` | `Boolean` | `false` | Rasterize layer for improved scrolling performance |
| `tintColor` | `String` | `null` | Apply tint color (image becomes template/silhouette) |
| `backgroundColor` | `String` | `null` | Background color (required for `noTransparency`) |

#### Placeholder

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `defaultImage` | `String` | Built-in placeholder | Path to placeholder during remote image load |
| `preventDefaultImage` | `Boolean` | `false` | Hide built-in Titanium placeholder |

#### Internal Flags

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `averageColorDone` | `Boolean` | `false` | Tracks if average color calculated. Set `false` to recalculate |
| `calcMinMaxDone` | `Boolean` | `false` | Tracks if calcMinMax applied |
| `averageColor` | `String` | `null` | Hex color string (e.g., `#39ADE1`) after calculation |

---

### Events

#### `averageColor`

Fired **once** when average color is calculated.

**Event Object:**
- `color` (`Array`): `[red, green, blue]` (0-255)
- `averageColor` (`String`): Hex color (e.g., `#39ADE1`)

```javascript
imageView.addEventListener('averageColor', function(e) {
    console.log('RGB:', e.color);        // [57, 173, 225]
    console.log('Hex:', e.averageColor);  // '#39ADE1'
    
    win.backgroundColor = e.averageColor;
});
```

**Notes:**
- Fires only once per imageView lifecycle
- Set `averageColorDone: false` to force recalculation
- Listener must be attached before image is set

#### `imageMinMax`

Fired after `calcMinMax` scaling completes.

**Event Object:**
- `width` (`Number`): Scaled width
- `height` (`Number`): Scaled height

```javascript
imageView.addEventListener('imageMinMax', function(e) {
    console.log('Scaled to:', e.width + 'x' + e.height);
    
    imageView.width = e.width;
    imageView.height = e.height;
});
```

---

## Usage Examples

### Fade-In Animation in TableView

```javascript
var imageView = Ti.UI.createImageView({
    image: '/assets/photo.jpg',
    animated: true,
    animateOnce: false  // Re-animate on scroll back into view
});
```

### Constrained Sizing

```javascript
var imageView = Ti.UI.createImageView({
    image: '/assets/landscape.jpg',
    calcMinMax: true,
    maxWidth: 320,
    maxHeight: 240
});
```

### Blurred Background

```javascript
var imageView = Ti.UI.createImageView({
    image: '/assets/background.jpg',
    blurredImage: true,
    blurRadius: 25,
    width: Ti.UI.FILL,
    height: Ti.UI.FILL
});
```

### Average Color Detection

```javascript
var imageView = Ti.UI.createImageView({
    image: '/assets/hero.jpg',
    averageColorDone: false
});

imageView.addEventListener('averageColor', function(e) {
    win.backgroundColor = e.averageColor;
});
```

### No Transparency (Performance)

```javascript
var imageView = Ti.UI.createImageView({
    image: '/assets/logo.png',
    noTransparency: true,
    backgroundColor: '#ffffff'
});
```

### Tint Color

```javascript
var imageView = Ti.UI.createImageView({
    image: '/assets/icon.png',
    tintColor: '#365b85'
});
```

### Complete TableView Example

```javascript
var tableView = Ti.UI.createTableView();

for (var i = 0; i < 50; i++) {
    var row = Ti.UI.createTableViewRow({ height: Ti.UI.SIZE });
    
    var imageView = Ti.UI.createImageView({
        image: '/assets/photos/photo_' + i + '.jpg',
        left: 10, top: 10, bottom: 10,
        width: 80, height: 80,
        
        animated: true,
        animateOnce: false,
        calcMinMax: true,
        maxWidth: 80,
        maxHeight: 80,
        shouldRasterize: true
    });
    
    imageView.addEventListener('averageColor', function(e) {
        this.backgroundColor = e.averageColor;
    });
    
    row.add(imageView);
    tableView.appendRow(row);
}

win.add(tableView);
```

---

## Performance Tips

### For Scrolling Containers

```javascript
var imageView = Ti.UI.createImageView({
    image: '/assets/photo.jpg',
    animated: true,
    animateOnce: false,
    shouldRasterize: true,    // Layer caching
    noTransparency: true,     // No compositing
    backgroundColor: '#fff'   // Required for noTransparency
});
```

### General Guidelines

1. **`shouldRasterize: true`** — For imageView in TableView/ListView/ScrollView
2. **`noTransparency: true`** — When alpha channel isn't needed
3. **`animateOnce: true`** — For static images (avoid re-animation)
4. **`calcMinMax`** — Reduces memory footprint of large images

### Architecture

- All processing runs on **background threads**
- Shared `CIContext` for blur operations
- Early-exit detection skips duplicate loads
- Property caching reduces proxy lookups

---

## Troubleshooting

### Events Fire Twice

**Cause:** TableViewExtension height caching or cell reuse.

**Solution:** Module has built-in early-exit. Ensure properties set only once:

```javascript
var imageView = Ti.UI.createImageView({
    image: '/assets/photo.jpg',
    calcMinMax: true,
    maxWidth: 120,
    maxHeight: 69,
    calcMinMaxDone: false,
    averageColorDone: false
});
```

### Average Color Not Calculated

**Solution:** Attach listener before setting image:

```javascript
var imageView = Ti.UI.createImageView({
    averageColorDone: false
});

imageView.addEventListener('averageColor', function(e) {
    console.log('Color:', e.averageColor);
});

imageView.image = '/assets/photo.jpg';  // Set after listener
```

### Animation Not Working in TableView

**Solution:** Use `animateOnce: false`:

```javascript
var imageView = Ti.UI.createImageView({
    image: '/assets/photo.jpg',
    animated: true,
    animateOnce: false  // Re-animate on visibility
});
```

---

## Compatibility

| Platform | Minimum |
|----------|---------|
| Titanium SDK | 13.2.0+ |
| iOS | 13.0+ |
| Architecture | arm64, x86_64 |

---

## Changelog

### v1.3.8 (2026-06-02)
- ✅ Fixed Cell-Reuse cache: property comparison now uses numeric values instead of object references
- ✅ Race condition fix: properties cached once before background dispatch — no inconsistent processing
- ✅ Fixed tintColor double application in `noTransparency` path — template/silhouette mode only
- ✅ `imageMinMax` event fires on main thread — safe for layout code in handlers
- ✅ Average color uses transparent context — no black tint on images with transparency
- ✅ Fixed invisible images with `blurredImage` + `calcMinMax`: imageView now created in `loadUrl` path
- ✅ Optimized imageView creation: lazy instantiation only when needed
- ✅ All `NSLog` replaced with `DebugLog` — no console spam in production
- ✅ Removed unused `tintOpacity` variable

### v1.3.7 (2026-06-02)
- ✅ Fixed duplicate event firing with TableViewExtension height caching
- ✅ Flag reset now occurs after early-exit checks
- ✅ Improved cell reuse compatibility
- ✅ noTransparency works in both direct image and loadUrl paths
- ✅ tintColor uses silhouette/template mode (solid color)
- ✅ noTransparency removes alpha channel, fills with backgroundColor (no blended layers)
- ✅ Comprehensive documentation update (all properties, events, examples)
- ✅ Added troubleshooting section
- ✅ Updated manifest (author, license, minsdk: 13.2.0)
- ✅ Example app with 10 feature demonstrations

### v1.3.6 - v1.3.2 (2026-01-20)
- Early-exit cache, property comparison, cell reuse fixes

### v1.1.0 (2026-06-01)
- Average color fix, background thread processing, shared CIContext
- Early-exit for duplicates, property caching, modern Obj-C syntax

### v1.0.3 (2026-05-31)
- Initial release

---

## License

Apache 2.0 — See [LICENSE](../LICENSE)

## Author

Created by **Marc Bender** — Copyright © 2022-2026
