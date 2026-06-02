# ti.imageviewextension

## TiUIImageView Extension for iOS (Titanium Module)

Extends the standard Titanium `Ti.UI.ImageView` with powerful features for smooth image loading, processing, and rendering optimization. Simply add the module to your **tiapp.xml** — no further setup required!

All `Ti.UI.ImageView` instances automatically gain the extended features — **no `require()` needed**.

---

## Features

| Feature | Property | Description |
|---------|----------|-------------|
| **Fade-In Animation** | `animated` | Smooth fade-in when imageView becomes visible (TableView, ListView, ScrollView) |
| **Single Animation** | `animateOnce` | Animation plays only on first appearance |
| **Auto-Scaling** | `calcMinMax` | Scale images to `maxWidth`/`maxHeight` while maintaining aspect ratio |
| **Blur Effect** | `blurredImage` | Apply Gaussian blur with configurable radius using Core Image |
| **Average Color** | `averageColor` event | Calculate dominant color for background matching |
| **No Transparency** | `noTransparency` | Remove alpha channel for better rendering performance |
| **Tint Color** | `tintColor` | Apply tint color to template images |
| **Hi-Res Loading** | `hires` | Load @2x/@3x resolution images |
| **Auto-Rotate** | `autorotate` | Auto-correct image orientation from EXIF data |
| **Layer Rasterization** | `shouldRasterize` | Rasterize layer for improved scrolling performance |
| **Default Image** | `defaultImage` | Placeholder image while loading |

---

## Installation

1. Build or download the module zip (`ti.imageviewextension-iphone-x.x.x.zip`)
2. Place in your project's `modules/iphone/` directory
3. Add to `tiapp.xml`:

```xml
<modules>
    <module version="1.3.7">ti.imageviewextension</module>
</modules>
```

**That's it!** All `Ti.UI.ImageView` instances automatically gain the extended features.

---

## API Reference

### Properties

#### Animation

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `animated` | `Boolean` | `false` | Enables smooth fade-in animation (0.5s duration) when imageView becomes visible. In scrollable containers, re-triggers on re-visibility unless `animateOnce: true` |
| `animateOnce` | `Boolean` | `false` | When `true`, animation only plays on first appearance. Subsequent visibility changes show image immediately |

#### Sizing

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `calcMinMax` | `Boolean` | `false` | Automatically scales image to fit within `maxWidth`/`maxHeight` bounds while maintaining aspect ratio. Uses `MIN(maxWidth/originalWidth, maxHeight/originalHeight)` ratio |
| `maxWidth` | `Number` | Original image width | Maximum width for `calcMinMax` scaling. Ignored if `calcMinMax: false` |
| `maxHeight` | `Number` | Original image height | Maximum height for `calcMinMax` scaling. Ignored if `calcMinMax: false` |

#### Image Processing

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `blurredImage` | `Boolean` | `false` | Applies Gaussian blur filter using Core Image `CIGaussianBlur`. Processed on background thread to avoid UI blocking |
| `blurRadius` | `Number` | `15.0` | Blur intensity in pixels. Higher values = more blur. Only active when `blurredImage: true` |
| `noTransparency` | `Boolean` | `false` | Removes alpha channel and fills with `backgroundColor`. Improves rendering performance in scrolling lists by eliminating compositing |
| `hires` | `Boolean` | `false` | Loads high-resolution (@2x/@3x) version of image. Auto-scales displayed dimensions back to original size |
| `autorotate` | `Boolean` | `true` | Automatically corrects image orientation based on EXIF data. Set to `false` to preserve original orientation |

#### Rendering Optimization

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `shouldRasterize` | `Boolean` | `false` | Enables layer rasterization for improved scrolling performance. Useful for complex imageView hierarchies or when combined with blur effects |
| `tintColor` | `String` | `null` | Applies tint color to image using `UIImageRenderingModeAlwaysTemplate`. Image becomes single-color silhouette |
| `backgroundColor` | `String` | `null` | Background color for imageView. Required when using `noTransparency: true` |

#### Placeholder Images

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `defaultImage` | `String` | Built-in placeholder | Path to placeholder image shown while loading remote images. Set to `null` with `preventDefaultImage: true` to show nothing |
| `preventDefaultImage` | `Boolean` | `false` | Prevents showing the built-in Titanium placeholder image during load |

#### Internal Flags (Read-Only / Advanced)

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `averageColorDone` | `Boolean` | `false` | Tracks if average color has been calculated. Set to `false` to force recalculation on next image load |
| `calcMinMaxDone` | `Boolean` | `false` | Tracks if calcMinMax scaling has been applied |
| `averageColor` | `String` | `null` | Hex color string (e.g., `#39ADE1`) of calculated average color. Set after `averageColor` event fires |

---

### Events

#### `averageColor`

Fired **once** when the image's average color is calculated. The event provides RGB values and sets the `averageColor` property on the imageView.

**Event Object:**
- `color` (`Array`): `[red, green, blue]` values (0-255)
- `averageColor` (`String`): Hex color string (e.g., `#39ADE1`)

**Example:**
```javascript
var imageView = Ti.UI.createImageView({
    image: '/assets/hero.jpg',
    averageColorDone: false  // Ensure calculation runs
});

imageView.addEventListener('averageColor', function(e) {
    console.log('RGB:', e.color);           // [57, 173, 225]
    console.log('Hex:', e.averageColor);     // '#39ADE1'
    console.log('Prop:', imageView.averageColor); // '#39ADE1'
    
    // Use for dynamic background matching
    win.backgroundColor = e.averageColor;
});
```

**Important Notes:**
- Event fires only **once per imageView lifecycle**
- To recalculate after image change: `imageView.averageColorDone = false` then set new image
- Requires listener to be attached **before** image is set (Titanium event system)
- Calculation runs on background thread, event fires on main thread

#### `imageMinMax`

Fired after image is scaled via `calcMinMax`. Provides the resulting dimensions.

**Event Object:**
- `width` (`Number`): Scaled width in points
- `height` (`Number`): Scaled height in points

**Example:**
```javascript
var imageView = Ti.UI.createImageView({
    image: '/assets/landscape.jpg',
    calcMinMax: true,
    maxWidth: 300,
    maxHeight: 200
});

imageView.addEventListener('imageMinMax', function(e) {
    console.log('Image scaled to:', e.width + 'x' + e.height);
    
    // Adjust layout based on actual dimensions
    imageView.width = e.width;
    imageView.height = e.height;
});
```

---

## Usage Examples

### 1. Basic Fade-In Animation

Smooth fade-in when image scrolls into view:

```javascript
var imageView = Ti.UI.createImageView({
    image: '/assets/photo.jpg',
    animated: true,
    animateOnce: false  // Re-animate on every visibility change
});

win.add(imageView);
```

### 2. Constrained Image Sizing

Auto-scale large images to fit within bounds:

```javascript
var imageView = Ti.UI.createImageView({
    image: '/assets/landscape.jpg',
    calcMinMax: true,
    maxWidth: 320,
    maxHeight: 240
});

imageView.addEventListener('imageMinMax', function(e) {
    console.log('Final size:', e.width + 'x' + e.height);
});
```

### 3. Blurred Background Effect

Create frosted glass or background blur effects:

```javascript
var imageView = Ti.UI.createImageView({
    image: '/assets/background.jpg',
    blurredImage: true,
    blurRadius: 25,
    width: Ti.UI.FILL,
    height: Ti.UI.FILL
});

win.add(imageView);
```

### 4. Average Color Detection

Match UI elements to image tone:

```javascript
var imageView = Ti.UI.createImageView({
    image: '/assets/hero.jpg',
    averageColorDone: false
});

imageView.addEventListener('averageColor', function(e) {
    // Match window background
    win.backgroundColor = e.averageColor;
    
    // Create complementary label
    var label = Ti.UI.createLabel({
        color: e.averageColor,
        font: { fontSize: 24, fontWeight: 'bold' },
        text: 'Hero Section'
    });
    win.add(label);
});

win.add(imageView);
```

### 5. No Transparency (Performance)

Remove alpha channel for better scrolling performance:

```javascript
var imageView = Ti.UI.createImageView({
    image: '/assets/logo.png',
    noTransparency: true,
    backgroundColor: '#ffffff'
});
```

### 6. Tint Color

Create monochrome icon effects:

```javascript
var imageView = Ti.UI.createImageView({
    image: '/assets/icon.png',
    tintColor: '#365b85'
});
```

### 7. TableView with All Features

Complete example for list items:

```javascript
var tableView = Ti.UI.createTableView();

for (var i = 0; i < 50; i++) {
    var row = Ti.UI.createTableViewRow({
        height: Ti.UI.SIZE,
        className: 'item'
    });
    
    var imageView = Ti.UI.createImageView({
        image: '/assets/photos/photo_' + i + '.jpg',
        left: 10,
        top: 10,
        bottom: 10,
        width: 80,
        height: 80,
        
        // Animation
        animated: true,
        animateOnce: false,
        
        // Sizing
        calcMinMax: true,
        maxWidth: 80,
        maxHeight: 80,
        
        // Rendering
        shouldRasterize: true,  // Better scroll performance
        noTransparency: false
    });
    
    imageView.addEventListener('averageColor', function(e) {
        this.backgroundColor = e.averageColor;
    });
    
    row.add(imageView);
    
    var label = Ti.UI.createLabel({
        text: 'Item ' + i,
        left: 100,
        top: 20,
        right: 10,
        font: { fontSize: 16 }
    });
    row.add(label);
    
    tableView.appendRow(row);
}

win.add(tableView);
```

### 8. Combined Features (Advanced)

Multiple features working together:

```javascript
var imageView = Ti.UI.createImageView({
    image: '/assets/photo.jpg',
    height: 300,
    width: Ti.UI.FILL,
    
    // Fade in on first load only
    animated: true,
    animateOnce: true,
    
    // Constrain to screen width
    calcMinMax: true,
    maxWidth: Ti.Platform.displayCaps.platformWidth - 20,
    maxHeight: 400,
    
    // Apply subtle blur
    blurredImage: true,
    blurRadius: 5,
    
    // Optimize for scrolling
    shouldRasterize: true,
    noTransparency: true,
    backgroundColor: '#f0f0f0'
});

imageView.addEventListener('averageColor', function(e) {
    console.log('Dominant color:', e.averageColor);
});

imageView.addEventListener('imageMinMax', function(e) {
    console.log('Scaled to:', e.width + 'x' + e.height);
});

win.add(imageView);
```

### 9. Placeholder Image During Load

Show placeholder while remote image loads:

```javascript
var imageView = Ti.UI.createImageView({
    image: 'https://example.com/large-photo.jpg',
    defaultImage: '/assets/placeholder.png',
    animated: true
});
```

### 10. Hi-Res Image Loading

Load retina-quality images:

```javascript
var imageView = Ti.UI.createImageView({
    image: '/assets/icon.png',
    hires: true,  // Loads @2x/@3x version
    width: 50,
    height: 50
});
```

---

## Performance Tips

### General Guidelines

1. **Use `shouldRasterize: true`** for imageView in scrolling containers (TableView, ListView, ScrollView)
2. **Enable `noTransparency: true`** with `backgroundColor` when alpha channel isn't needed
3. **Set `animateOnce: true`** for static images to avoid re-animation overhead
4. **Use `calcMinMax`** instead of fixed dimensions for responsive layouts

### For TableView/ListView

```javascript
var imageView = Ti.UI.createImageView({
    image: '/assets/photo.jpg',
    animated: true,
    animateOnce: false,      // Re-animate on scroll back into view
    shouldRasterize: true,   // Layer caching for smooth scrolling
    noTransparency: true,    // Eliminate compositing overhead
    backgroundColor: '#fff'  // Required for noTransparency
});
```

### Memory Management

- All image processing (blur, resize, color extraction) runs on **background threads**
- Shared `CIContext` for blur operations reduces memory overhead
- Duplicate image loads are automatically skipped via early-exit detection
- Use `calcMinMax` to reduce memory footprint of large images

### Avoiding Duplicate Events

When using with TableViewExtension or similar modules that cache row heights:

```javascript
// Set properties once, don't re-set on cell reuse
var imageView = Ti.UI.createImageView({
    image: '/assets/photo.jpg',
    calcMinMax: true,
    maxWidth: 120,
    maxHeight: 69,
    blurredImage: true,
    blurRadius: 20,
    
    // Initial flags (don't change these)
    calcMinMaxDone: false,
    averageColorDone: false
});
```

---

## Troubleshooting

### Events Fire Twice

**Problem:** `averageColor` or `imageMinMax` events fire multiple times.

**Cause:** Usually happens when using with TableViewExtension's height caching or cell reuse.

**Solution:** The module has built-in early-exit detection. Ensure:
1. Properties are set only once during imageView creation
2. Don't re-set `image` property to the same value
3. Use `className` on TableViewRows for proper cell reuse grouping

### Average Color Not Calculated

**Problem:** `averageColor` event never fires.

**Solutions:**
1. Ensure listener is attached **before** setting the image
2. Set `averageColorDone: false` explicitly
3. Check that image loads successfully (not nil)

```javascript
var imageView = Ti.UI.createImageView({
    averageColorDone: false  // Must be set before image
});

imageView.addEventListener('averageColor', function(e) {
    console.log('Color:', e.averageColor);
});

// Set image after listener
imageView.image = '/assets/photo.jpg';
```

### Blur Not Applying

**Problem:** Image appears unblurred.

**Solutions:**
1. Ensure `blurredImage: true` is set
2. Check `blurRadius` value (default 15, try 20-30 for visible effect)
3. Verify image loads successfully (not a remote URL that fails)

### Animation Not Working in TableView

**Problem:** Fade-in animation doesn't trigger when scrolling.

**Solution:** Set `animateOnce: false` to re-animate on each visibility change:

```javascript
var imageView = Ti.UI.createImageView({
    image: '/assets/photo.jpg',
    animated: true,
    animateOnce: false  // Key setting for TableView
});
```

### Image Appears Stretched

**Problem:** Image doesn't maintain aspect ratio.

**Solution:** Use `calcMinMax` with appropriate bounds:

```javascript
var imageView = Ti.UI.createImageView({
    image: '/assets/photo.jpg',
    calcMinMax: true,
    maxWidth: 300,
    maxHeight: 200,
    width: Ti.UI.SIZE,   // Let module set actual size
    height: Ti.UI.SIZE
});

imageView.addEventListener('imageMinMax', function(e) {
    // Update dimensions after scaling
    imageView.width = e.width;
    imageView.height = e.height;
});
```

---

## Compatibility

| Platform | Minimum Version |
|----------|----------------|
| **Titanium SDK** | 13.2.0+ |
| **iOS** | 13.0+ |
| **Architecture** | arm64, x86_64 (Simulator) |

---

## Changelog

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

### v1.3.6 (2026-01-20)
- ✅ Early-exit cache with property comparison
- ✅ Prevents redundant processing when image unchanged

### v1.3.5 (2026-01-20)
- ✅ Early-exit in `loadUrl` for remote/local images
- ✅ Prevents double-fire on URL-based image loads

### v1.3.4 (2026-01-20)
- ✅ Corrected flag reset order for cell reuse
- ✅ Flags reset after early-exit, not before

### v1.3.3 (2026-01-20)
- ✅ Fixed image disappearing on cell reuse
- ✅ Proper flag management for recycled cells

### v1.3.2 (2026-01-20)
- ✅ Cell reuse cache implementation
- ✅ Flags persist for same image across cell lifecycle

### v1.1.0 (2026-06-01)
- ✅ Fixed average color calculation (RGB order & hex formatting)
- ✅ Optimized image processing pipeline (non-blocking UI thread)
- ✅ Shared CIContext for blur operations
- ✅ Early-exit for duplicate image loads
- ✅ Property caching to reduce proxy lookups
- ✅ Modern Objective-C syntax
- ✅ Fixed blur extent handling & image scaling
- ✅ Updated SDK version (13.2.0.GA)

### v1.0.3 (2026-05-31)
- Initial release with extended TiUIImageView features

---

## License

Apache 2.0 — See [LICENSE](LICENSE)

## Author

Created by **Marc Bender** — Copyright © 2022-2026

---

## Related Modules

- **[de.marcbender.tableviewextension](https://github.com/mbender74/TableViewExtension)** — Smooth scrolling TableView optimizations
- **[ti.imageviewextension-android](https://github.com/mbender74/ti.imageviewextension-android)** — Android version of this module
