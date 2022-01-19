# ti.imageviewextension

## Description

**TiUIImageView Extension for iOS (Titanium Module)**

Just add module in **tiapp.xml** no further steps needed!

Extends TiSDK TiUIImageView with the following features:
- animated (regardless if local or remote image)
- animateOnce (animates the appearing of the image only on the first time)
- calcMinMax (with properties maxHeight and maxWidth) this sizes the image to the given size
- noTransparency (will remove the alpha information of the image)
- averageColor (most used color of the image, usefull if you want to know if the image is a darker image or more lighten)

API is exactly as:
https://titaniumsdk.com/api/titanium/ui/imageview.html


## additional properties

* `animated ` - BOOL true/false (the image is faded in when true when the imageView appears, as example when tableView row / listView item / scrollView childview will be visible in scrolling! When the imageView is no longer visible and "animateOnce" is false, the imageView will fadein on reappering again!)
* `animateOnce ` - BOOL true/false (the image is faded in when animated is true, but only on the first appearing - as example when image is in a scrollable view)

* `calcMinMax ` - BOOL true/false (the will be resized to the max given dimensions)
* `maxHeight ` - INTEGER (the will be resized to the max given dimension when "calcMinMax" is true)
* `maxWidth ` - INTEGER (the will be resized to the max given dimension when "calcMinMax" is true)
* `noTransparency ` - BOOL true/false (the image will be rendered without transparency, transparency of image will be removed internally)

* `averageColorDone ` - BOOL true/false

## Events and Listeners
* `averageColor ` - when eventlistener "averageColor" is added to the imageView, an event "averageColor" will return the average color of the imageView, event returns hex color value '#123456' - the event will also set a property "averageColorDone:true" to the imageView, so the calculation of averageColor is only done once (or if you manually set averageColorDone:false after the event, it is done again on next appearing of the imageView)


```js
imageView.addEventListener('averageColor', function(e) {
 console.log("returned average image color: "+e.color);
});
```




## Example

```js
var imageView = Ti.UI.createImageView({
  image:YOUR_IMAGE,
  height:260,
  width:Ti.UI.SIZE,
  averageColorDone:false,
  animateOnce:false,
  noTransparency:false,
  maxHeight:260,
  maxWidth:280,
  calcMinMax:true,
});
```

