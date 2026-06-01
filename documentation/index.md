# ti.imageviewextension Module

## Description

A Titanium iOS module that extends `Ti.UI.ImageView` with advanced image processing capabilities including animated fade-in, automatic scaling, transparency removal, average color detection, and Gaussian blur. The module works as a transparent extension — simply install it and all ImageView instances gain the new features automatically.

## Installation

Add to your `tiapp.xml`:

```xml
<modules>
    <module version="1.0.2">ti.imageviewextension</module>
</modules>
```

No additional code required. The module hooks into the Titanium image loading pipeline via Objective-C categories.

## Accessing the Module

This module operates as a **transparent extension** to `Ti.UI.ImageView`. You do not need to `require()` it in your JavaScript code. Simply create ImageView instances and use the extended properties:

```javascript
var imageView = Ti.UI.createImageView({
    image: '/myimage.jpg',
    animated: true,
    calcMinMax: true,
    maxWidth: 300
});
```

## API Reference

### Extended Properties

All properties are optional and can be combined freely.

#### `animated` (Boolean)

**Default:** `false`

Enables a smooth fade-in animation when the imageView becomes visible on screen. Particularly useful in scrollable containers (TableView, ListView, ScrollView) where images appear/disappear during scrolling.

When `animateOnce` is `false`, the animation re-triggers every time the view scrolls back into view.

**Example:**
```javascript
var imageView = Ti.UI.createImageView({
    image: '/photo.jpg',
    animated: true,
    animateOnce: false  // Re-animate on every visibility change
});
```

#### `animateOnce` (Boolean)

**Default:** `false`

When `true`, the fade-in animation only plays on the very first appearance. Subsequent visibility changes will show the image immediately without animation.

#### `calcMinMax` (Boolean)

**Default:** `false`

Automatically scales the image to fit within the bounds defined by `maxWidth` and `maxHeight` while maintaining the original aspect ratio. If only one dimension is provided, the other scales proportionally.

**Example:**
```javascript
var imageView = Ti.UI.createImageView({
    image: '/landscape.jpg',
    calcMinMax: true,
    maxWidth: 320,
    maxHeight: 240
});
```

#### `maxWidth` (Number)

**Default:** Original image width

Maximum width for `calcMinMax` scaling. Ignored if `calcMinMax` is `false`.

#### `maxHeight` (Number)

**Default:** Original image height

Maximum height for `calcMinMax` scaling. Ignored if `calcMinMax` is `false`.

#### `noTransparency` (Boolean)

**Default:** `false`

Removes the alpha channel from the image and renders it with a solid background. Set `backgroundColor` to define the fill color. This improves rendering performance, especially in scrolling lists.

**Example:**
```javascript
var imageView = Ti.UI.createImageView({
    image: '/logo.png',
    noTransparency: true,
    backgroundColor: '#ffffff'
});
```

#### `blurredImage` (Boolean)

**Default:** `false`

Applies a Gaussian blur filter to the image using Core Image. Control intensity with `blurRadius`.

**Example:**
```javascript
var imageView = Ti.UI.createImageView({
    image: '/background.jpg',
    blurredImage: true,
    blurRadius: 25
});
```

#### `blurRadius` (Number)

**Default:** `15.0`

Controls the intensity of the Gaussian blur. Higher values produce more blur. Only active when `blurredImage: true`.

#### `averageColorDone` (Boolean)

**Default:** `false`

Internal flag that tracks whether the average color has already been calculated. Set to `false` manually to force recalculation on next image load.

### Events

#### `averageColor`

Fired once when the image's dominant color is calculated. The event provides RGB values and sets the `averageColor` property on the imageView.

**Event Object:**
- `color` (Array): `[red, green, blue]` values (0-255)

**Example:**
```javascript
var imageView = Ti.UI.createImageView({
    image: '/photo.jpg',
    averageColorDone: false
});

imageView.addEventListener('averageColor', function(e) {
    var rgb = e.color;  // [150, 200, 100]
    var hex = imageView.averageColor;  // '#96C864'
    
    // Use for dynamic backgrounds
    win.backgroundColor = hex;
});
```

**Important:** This event fires only once per imageView lifecycle. To recalculate, set `imageView.averageColorDone = false` before loading a new image.

#### `imageMinMax`

Fired after an image is scaled via `calcMinMax`. Provides the resulting dimensions.

**Event Object:**
- `width` (Number): Scaled width
- `height` (Number): Scaled height

**Example:**
```javascript
imageView.addEventListener('imageMinMax', function(e) {
    Ti.API.info('Image scaled to: ' + e.width + 'x' + e.height);
});
```

## Usage Examples

### Smooth Image Loading in TableView Rows

```javascript
var tableView = Ti.UI.createTableView();

for (var i = 0; i < 50; i++) {
    var row = Ti.UI.createTableViewRow({
        height: 100
    });
    
    var imageView = Ti.UI.createImageView({
        image: '/photos/photo_' + i + '.jpg',
        left: 10,
        top: 10,
        width: 80,
        height: 80,
        animated: true,
        animateOnce: false  // Re-animate when scrolling back into view
    });
    
    row.add(imageView);
    tableView.appendRow(row);
}

win.add(tableView);
```

### Responsive Image Sizing

```javascript
var imageView = Ti.UI.createImageView({
    image: '/large_photo.jpg',
    width: Ti.UI.FILL,
    height: Ti.UI.SIZE,
    calcMinMax: true,
    maxWidth: Ti.Platform.displayCaps.platformWidth,
    maxHeight: 500
});
```

### Background Matching with Average Color

```javascript
var imageView = Ti.UI.createImageView({
    image: '/hero.jpg',
    averageColorDone: false
});

imageView.addEventListener('averageColor', function(e) {
    // Dynamically match window background to image tone
    win.backgroundColor = imageView.averageColor;
    
    // Or create complementary UI elements
    var label = Ti.UI.createLabel({
        color: imageView.averageColor,
        text: 'Hero Image'
    });
    win.add(label);
});

win.add(imageView);
```

### Blurred Background Effect

```javascript
var imageView = Ti.UI.createImageView({
    image: '/background.jpg',
    blurredImage: true,
    blurRadius: 30,
    width: Ti.UI.FILL,
    height: Ti.UI.FILL
});

win.add(imageView);
```

## Performance Considerations

- **Non-blocking:** All image processing (blur, resize, color extraction) runs on background threads
- **Shared CI Context:** Blur operations use a shared Core Image context to reduce memory overhead
- **Duplicate Detection:** Identical image loads are automatically skipped via early-exit optimization
- **No Transparency:** Use `noTransparency: true` with `backgroundColor` for improved scrolling performance in lists
- **Animate Once:** Set `animateOnce: true` for static images to avoid re-animation overhead

## Compatibility

- **Titanium SDK:** 13.2.0+
- **iOS:** 13.0+
- **Architecture:** arm64, x86_64 (Simulator)

## Author

Created by Marc Bender - Copyright (c) 2022

## License

Apache 2.0 - See [LICENSE](../LICENSE)
