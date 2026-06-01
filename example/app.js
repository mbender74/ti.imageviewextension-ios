// Example app for ti.imageviewextension module
// Demonstrates all extended features

var win = Ti.UI.createWindow({
    backgroundColor: '#ffffff'
});

var scrollView = Ti.UI.createScrollView({
    top: 0,
    left: 0,
    right: 0,
    bottom: 0,
    showVerticalScrollIndicator: true
});

// Helper to create section headers
function createHeader(text) {
    return Ti.UI.createLabel({
        text: text,
        font: { fontSize: 18, fontWeight: 'bold' },
        top: 20,
        left: 10,
        right: 10,
        color: '#333333'
    });
}

// Helper to create description labels
function createDescription(text) {
    return Ti.UI.createLabel({
        text: text,
        font: { fontSize: 14 },
        top: 5,
        left: 10,
        right: 10,
        color: '#666666'
    });
}

var yOffset = 0;

// ============================================================
// Example 1: Animated Fade-In
// ============================================================
scrollView.add(createHeader('Animated Fade-In'));
scrollView.add(createDescription('animated: true, animateOnce: false'));

var imageView1 = Ti.UI.createImageView({
    image: '/assets/KITT.jpg',
    top: yOffset + 30,
    left: 10,
    right: 10,
    height: 200,
    animated: true,
    animateOnce: false
});
scrollView.add(imageView1);
yOffset += 240;

// ============================================================
// Example 2: Constrained Sizing with calcMinMax
// ============================================================
scrollView.add(createHeader('Constrained Sizing'));
scrollView.add(createDescription('calcMinMax: true, maxWidth: 300, maxHeight: 200'));

var imageView2 = Ti.UI.createImageView({
    image: '/assets/KITT.jpg',
    top: yOffset + 30,
    left: 10,
    width: Ti.UI.SIZE,
    height: Ti.UI.SIZE,
    calcMinMax: true,
    maxWidth: 300,
    maxHeight: 200
});
scrollView.add(imageView2);

imageView2.addEventListener('imageMinMax', function(e) {
    Ti.API.info('Scaled dimensions: ' + e.width + 'x' + e.height);
});

yOffset += 250;

// ============================================================
// Example 3: No Transparency
// ============================================================
scrollView.add(createHeader('No Transparency'));
scrollView.add(createDescription('noTransparency: true, backgroundColor: #e0e0e0'));

var imageView3 = Ti.UI.createImageView({
    image: '/assets/KITT.jpg',
    top: yOffset + 30,
    left: 10,
    right: 10,
    height: 200,
    noTransparency: true,
    backgroundColor: '#e0e0e0'
});
scrollView.add(imageView3);
yOffset += 240;

// ============================================================
// Example 4: Average Color Detection
// ============================================================
scrollView.add(createHeader('Average Color Detection'));
scrollView.add(createDescription('Listens for averageColor event'));

var colorLabel = Ti.UI.createLabel({
    top: yOffset + 25,
    left: 10,
    right: 10,
    height: 40,
    textAlign: 'center',
    font: { fontSize: 16, fontWeight: 'bold' },
    color: '#333333'
});
scrollView.add(colorLabel);

var imageView4 = Ti.UI.createImageView({
    image: '/assets/KITT.jpg',
    top: yOffset + 50,
    left: 10,
    right: 10,
    height: 200,
    averageColorDone: false
});
scrollView.add(imageView4);

imageView4.addEventListener('averageColor', function(e) {
    var hexColor = imageView4.averageColor;
    colorLabel.text = 'Dominant Color: ' + hexColor;
    colorLabel.color = hexColor;
    Ti.API.info('Average color detected: ' + hexColor);
});

yOffset += 280;

// ============================================================
// Example 5: Blurred Image
// ============================================================
scrollView.add(createHeader('Blurred Image'));
scrollView.add(createDescription('blurredImage: true, blurRadius: 20'));

var imageView5 = Ti.UI.createImageView({
    image: '/assets/KITT.jpg',
    top: yOffset + 30,
    left: 10,
    right: 10,
    height: 200,
    blurredImage: true,
    blurRadius: 20
});
scrollView.add(imageView5);
yOffset += 240;

// ============================================================
// Example 6: Combined Features
// ============================================================
scrollView.add(createHeader('Combined Features'));
scrollView.add(createDescription('animated + calcMinMax + averageColor'));

var combinedLabel = Ti.UI.createLabel({
    top: yOffset + 25,
    left: 10,
    right: 10,
    height: 40,
    textAlign: 'center',
    font: { fontSize: 16 },
    color: '#333333'
});
scrollView.add(combinedLabel);

var imageView6 = Ti.UI.createImageView({
    image: '/assets/KITT.jpg',
    top: yOffset + 50,
    left: 10,
    width: Ti.UI.SIZE,
    height: Ti.UI.SIZE,
    animated: true,
    animateOnce: true,
    calcMinMax: true,
    maxWidth: 320,
    maxHeight: 250,
    averageColorDone: false
});
scrollView.add(imageView6);

imageView6.addEventListener('averageColor', function(e) {
    combinedLabel.text = 'Color: ' + imageView6.averageColor;
});

imageView6.addEventListener('imageMinMax', function(e) {
    Ti.API.info('Combined example scaled to: ' + e.width + 'x' + e.height);
});

yOffset += 320;

// Footer
scrollView.add(Ti.UI.createLabel({
    top: yOffset + 20,
    left: 10,
    right: 10,
    textAlign: 'center',
    font: { fontSize: 12 },
    color: '#999999',
    text: 'ti.imageviewextension Module Example'
}));

scrollView.height = yOffset + 80;
win.add(scrollView);
win.open();
