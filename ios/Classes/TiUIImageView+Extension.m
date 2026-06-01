/**
* Appcelerator Titanium Mobile
* Copyright (c) 2009-2021 by Appcelerator, Inc. All Rights Reserved.
* Licensed under the terms of the Apache Public License
* Please see the LICENSE included with this distribution for details.
 *
 * WARNING: This is generated code. Modify at your own risk and without support.
*
* WARNING: This is generated code. Modify at your own risk and without support.
*/
#define USE_TI_UIIMAGEVIEW
#import "TiUIImageView+Extension.h"
#import <CommonCrypto/CommonDigest.h>
#import <TitaniumKit/ImageLoader.h>
#import <TitaniumKit/OperationQueue.h>
#import <TitaniumKit/TiBase.h>
#import <TitaniumKit/TiBlob.h>
#import <TitaniumKit/TiFile.h>
#import <TitaniumKit/TiProxy.h>
#import <TitaniumKit/TiUtils.h>
#import <TitaniumKit/TiViewProxy.h>
#import <TitaniumKit/UIImage+Resize.h>
#import <objc/runtime.h>

// Magic Numbers als Konstanten
static const CGFloat kFadeAnimationDuration = 0.5;
static const CGFloat kDefaultBlurRadius = 15.0;

// Shared CIContext für Blur (thread-safe, einmalig)
static CIContext *sharedCIContext(void) {
    static CIContext *ctx = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        ctx = [CIContext contextWithOptions:nil];
    });
    return ctx;
}

// Shared ColorSpace für Image Manipulation (thread-safe, einmalig)
static CGColorSpaceRef sharedRGBColorSpace(void) {
    static CGColorSpaceRef space = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        space = CGColorSpaceCreateDeviceRGB();
    });
    return space;
}

// Helper: ColorSpace releasing in dealloc oder app shutdown
__attribute__((destructor))
static void releaseSharedColorSpace(void) {
    // Wird beim App-Shutdown aufgerufen
}

@implementation TiUIImageView (Extension)

// Pro-Instanz Flags für Event-Duplikate innerhalb desselben Image-Lade-Zyklus
static const char *kAverageColorFiredKey = "kAverageColorFired";
static const char *kImageMinMaxFiredKey = "kImageMinMaxFired";

- (BOOL)averageColorFired
{
    NSNumber *value = objc_getAssociatedObject(self, kAverageColorFiredKey);
    return value ? value.boolValue : NO;
}

- (void)setAverageColorFired:(BOOL)value
{
    objc_setAssociatedObject(self, kAverageColorFiredKey, @(value), OBJC_ASSOCIATION_COPY);
}

- (BOOL)imageMinMaxFired
{
    NSNumber *value = objc_getAssociatedObject(self, kImageMinMaxFiredKey);
    return value ? value.boolValue : NO;
}

- (void)setImageMinMaxFired:(BOOL)value
{
    objc_setAssociatedObject(self, kImageMinMaxFiredKey, @(value), OBJC_ASSOCIATION_COPY);
}

- (UIViewContentMode)contentModeForImageView
{
  int contentMode = [TiUtils intValue:[self.proxy valueForKey:@"scalingMode"] def:-1];
  if (contentMode < 0) {
    if (TiDimensionIsAuto(width) || TiDimensionIsAutoSize(width) || TiDimensionIsUndefined(width) || TiDimensionIsAuto(height) || TiDimensionIsAutoSize(height) || TiDimensionIsUndefined(height)) {
      contentMode = UIViewContentModeScaleAspectFit;
    } else {
      contentMode = UIViewContentModeScaleToFill;
    }
  }
  return contentMode;
}

- (UIImageView *)imageView
{
 if (imageView == nil) {
    id backgroundColor = [self.proxy valueForUndefinedKey:@"backgroundColor"];
     UIColor * backgroundColorValue = nil;
     if (backgroundColor != nil) {
         backgroundColorValue = [[TiUtils colorValue:backgroundColor] _color];
     }
   imageView = [[UIImageView alloc] initWithFrame:[self bounds]];
   [imageView setAutoresizingMask:UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight];
   [imageView setContentMode:[self contentModeForImageView]];
   if (backgroundColorValue != nil) {
        imageView.backgroundColor = backgroundColorValue;
   }
   imageView.opaque = YES;
   imageView.layer.masksToBounds = true;
   [self addSubview:imageView];
 }
 return imageView;
}

- (void)cancelPendingImageLoads
{
  [(TiUIImageViewProxy *)[self proxy] cancelPendingImageLoads];
  placeholderLoading = NO;
}

- (void)fireLoadEventWithState:(NSString *)stateString
{
  TiUIImageViewProxy *ourProxy = (TiUIImageViewProxy *)self.proxy;
  [ourProxy propagateLoadEvent:stateString];
}

// Zentrale Scaling-Methode (ersetzt imageWithImage:convertToSize:, scaleToSize:withImage:)
- (UIImage *)imageWithImage:(UIImage *)image scaledToSize:(CGSize)size {
    if (!image || size.width <= 0 || size.height <= 0) {
        return image;
    }
    UIGraphicsBeginImageContextWithOptions(size, NO, 0.0);
    [image drawInRect:CGRectMake(0, 0, size.width, size.height)];
    UIImage *scaledImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return scaledImage;
}

// Backward-compat alias für imageWithImage:convertToSize:
- (UIImage *)imageWithImage:(UIImage *)image convertToSize:(CGSize)size {
    return [self imageWithImage:image scaledToSize:size];
}

- (UIImage *)calcMinMax:(UIImage *)image originalSize:(CGSize)originalSize
{
    if (!image) {
        return image;
    }

    // Double-event prevention: calcMinMaxDone vom Proxy prüfen (pro Cell/Instanz)
    BOOL calcMinMaxDone = [TiUtils boolValue:[self.proxy valueForKey:@"calcMinMaxDone"] def:NO];
    if (calcMinMaxDone || [self imageMinMaxFired]) {
        return image;
    }
    [self setImageMinMaxFired:YES];

    // Properties cachern
    id maxHeight = [self.proxy valueForKey:@"maxHeight"];
    id maxWidth = [self.proxy valueForKey:@"maxWidth"];
    if (maxHeight == nil || maxHeight == [NSNull null]){
        maxHeight = @(originalSize.height);
    }
    if (maxWidth == nil || maxWidth == [NSNull null]){
        maxWidth = @(originalSize.width);
    }

    CGFloat ratio = MIN([maxWidth floatValue] / originalSize.width, [maxHeight floatValue] / originalSize.height);

    CGSize size = CGSizeMake(ceilf(originalSize.width * ratio), ceilf(originalSize.height * ratio));

    // Zentrale Scaling-Methode verwenden
    UIImage *destImage = [self imageWithImage:image scaledToSize:size];

    // calcMinMax und calcMinMaxDone auf dem Proxy setzen (pro Cell/Instanz)
    [[self proxy] replaceValue:NUMBOOL(NO) forKey:@"calcMinMax" notification:NO];
    [[self proxy] replaceValue:NUMBOOL(YES) forKey:@"calcMinMaxDone" notification:NO];

    // Event feuern mit den Ziel-Dimensionen
    NSLog(@"[TiUIImageView+Extension] calcMinMax: firing imageMinMax event width=%.1f height=%.1f (original=%.0fx%.0f, ratio=%.2f)",
          destImage.size.width, destImage.size.height, originalSize.width, originalSize.height, ratio);
    NSMutableDictionary *eventObject = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                        @(destImage.size.width), @"width",
                                        @(destImage.size.height), @"height",
                                        nil];
    [self.proxy fireEvent:@"imageMinMax" withObject:eventObject propagate:NO];

    return destImage;
}

// Backward compat für Aufrufe ohne originalSize
- (UIImage *)calcMinMax:(UIImage *)image
{
    return [self calcMinMax:image originalSize:image.size];
}

- (UIImage *)rotatedImage:(UIImage *)originalImage
{
  if (!originalImage) {
      return originalImage;
  }

  if (![TiUtils boolValue:[[self proxy] valueForUndefinedKey:@"autorotate"] def:YES] && (originalImage.imageOrientation != UIImageOrientationUp)) {
    UIImage *theImage = [UIImage imageWithCGImage:[originalImage CGImage] scale:[originalImage scale] orientation:UIImageOrientationUp];
    return theImage;
  } else {
    return originalImage;
  }
}

- (void)loadDefaultImage:(CGSize)imageSize
{
 NSURL *defURL = [TiUtils toURL:[self.proxy valueForKey:@"defaultImage"] proxy:self.proxy];

 if ((defURL == nil) && ![TiUtils boolValue:[self.proxy valueForKey:@"preventDefaultImage"] def:NO]) {
   NSString *filePath = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"modules/ui/images/photoDefault.png"];
   defURL = [NSURL fileURLWithPath:filePath];
 }

 if (defURL != nil) {
   UIImage *poster = [[ImageLoader sharedLoader] loadImmediateImage:defURL withSize:imageSize];

   UIImage *imageToUse = [self rotatedImage:poster];

   autoWidth = imageToUse.size.width;
   autoHeight = imageToUse.size.height;
   [self setTintedImage:imageToUse];
 }
}

- (void)loadUrl:(NSURL *)img
{
 [self cancelPendingImageLoads];

 if (img != nil) {
   // Early-Exit: Wenn gleiche URL UND alle Berechnungen fertig – Cache verwenden (Cell Reuse)
   BOOL calcMinMaxDone = [TiUtils boolValue:[self.proxy valueForKey:@"calcMinMaxDone"] def:NO];
   BOOL averageColorDone = [TiUtils boolValue:[self.proxy valueForKey:@"averageColorDone"] def:YES];
   if (calcMinMaxDone && averageColorDone) {
       NSString *currentImage = [self.proxy valueForKey:@"image"];
       if ([currentImage isKindOfClass:[NSString class]] && [currentImage isEqualToString:[img path]]) {
           NSLog(@"[TiUIImageView+Extension] loadUrl: EARLY EXIT – Cache hit url=%@", [img path]);
           return;
       }
   }

   [self removeAllImagesFromContainer];

   // Properties cachern (KVC-overhead reduzieren)
   BOOL hires = [TiUtils boolValue:[self.proxy valueForKey:@"hires"] def:NO];
   BOOL hasBlur = [TiUtils boolValue:[self.proxy valueForKey:@"blurredImage"] def:NO];
   BOOL hasCalcMinMax = [TiUtils boolValue:[self.proxy valueForKey:@"calcMinMax"] def:NO];

   CGSize imageSize = CGSizeMake(TiDimensionCalculateValue(width, 0.0),
       TiDimensionCalculateValue(height, 0.0));

   if (hires) {
     imageSize.width *= 2;
     imageSize.height *= 2;
   }

   UIImage *image = [[ImageLoader sharedLoader] loadImmediateImage:img];
   if (image == nil) {
     [self loadDefaultImage:imageSize];
     placeholderLoading = YES;
     [(TiUIImageViewProxy *)[self proxy] startImageLoad:img];
     return;
   }

   if (hasBlur || hasCalcMinMax) {
       // Image Processing asynchron im Background
       dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
           UIImage *processedImage = image;
           CGSize originalImageSize = image.size;

           if (hasBlur) {
               processedImage = [self blurredImageWithImage:processedImage];
           }
           if (hasCalcMinMax) {
               processedImage = [self calcMinMax:processedImage originalSize:originalImageSize];
           }
           UIImage *imageToUse = [self rotatedImage:processedImage];
           [(TiUIImageViewProxy *)[self proxy] setImageURL:img];

           dispatch_async(dispatch_get_main_queue(), ^{
               self->autoWidth = ceilf(imageToUse.size.width);
               self->autoHeight = ceilf(imageToUse.size.height);
               if (hires) {
                   self->autoWidth = ceilf(self->autoWidth / 2);
                   self->autoHeight = ceilf(self->autoHeight / 2);
               }

               [self setTintedImage:imageToUse];
               [self fireLoadEventWithState:@"image"];
           });
       });
   }
   else {
       // Kein Processing - direkt anwenden (wie Original)
       UIImage *imageToUse = [self rotatedImage:image];
       [(TiUIImageViewProxy *)[self proxy] setImageURL:img];

       self->autoWidth = ceilf(imageToUse.size.width);
       self->autoHeight = ceilf(imageToUse.size.height);
       if (hires) {
           self->autoWidth = ceilf(self->autoWidth / 2);
           self->autoHeight = ceilf(self->autoHeight / 2);
       }

       [self setTintedImage:imageToUse];
       [self fireLoadEventWithState:@"image"];
   }
 }
}

- (UIImage* )setBackgroundImageByColor:(UIColor *)backgroundColor withFrame:(CGRect )rect{

   UIView *tcv = [[UIView alloc] initWithFrame:rect];
   [tcv setBackgroundColor:backgroundColor];

   CGSize gcSize = tcv.frame.size;
   UIGraphicsBeginImageContextWithOptions(gcSize, NO, 0.0);
   [tcv.layer renderInContext:UIGraphicsGetCurrentContext()];
   UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    return image;
}

-(UIImage*) imageByReplacingColor:(UIColor*)sourceColor withImage:(UIImage*)image withMinTolerance:(CGFloat)minTolerance withMaxTolerance:(CGFloat)maxTolerance withColor:(UIColor*)destinationColor {
    if (!image || !sourceColor || !destinationColor) {
        return image;
    }

   const CGFloat* sourceComponents = CGColorGetComponents(sourceColor.CGColor);
   UInt8 source255Components[4];
   for (int i = 0; i < 4; i++) source255Components[i] = (UInt8)round(sourceComponents[i]*255.0);

   const CGFloat* destinationComponents = CGColorGetComponents(destinationColor.CGColor);
   UInt8 destination255Components[4];
   for (int i = 0; i < 4; i++) destination255Components[i] = (UInt8)round(destinationComponents[i]*255.0);

   CGImageRef rawImage = image.CGImage;
   size_t width = CGImageGetWidth(rawImage);
   size_t height = CGImageGetHeight(rawImage);
   CGRect rect = {CGPointZero, {width, height}};

   size_t bitsPerComponent = 8;
   size_t bytesPerRow = width*4;
   CGBitmapInfo bitmapInfo = kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big;
   UInt8* data = calloc(bytesPerRow, height);
   CGColorSpaceRef colorSpace = sharedRGBColorSpace();

   CGContextRef ctx = CGBitmapContextCreate(data, width, height, bitsPerComponent, bytesPerRow, colorSpace, bitmapInfo);
   CGContextDrawImage(ctx, rect, rawImage);

   for (int byte = 0; byte < bytesPerRow*height; byte += 4) {
       UInt8 r = data[byte];
       UInt8 g = data[byte+1];
       UInt8 b = data[byte+2];

       UInt8 dr = abs(r-source255Components[0]);
       UInt8 dg = abs(g-source255Components[1]);
       UInt8 db = abs(b-source255Components[2]);

       CGFloat ratio = (dr+dg+db)/(255.0*3.0);
       if (ratio > maxTolerance) ratio = 1;
       if (ratio < minTolerance) ratio = 0;

       data[byte] = (UInt8)round(ratio*r)+(UInt8)round((1.0-ratio)*destination255Components[0]);
       data[byte+1] = (UInt8)round(ratio*g)+(UInt8)round((1.0-ratio)*destination255Components[1]);
       data[byte+2] = (UInt8)round(ratio*b)+(UInt8)round((1.0-ratio)*destination255Components[2]);
   }

   CGImageRef img = CGBitmapContextCreateImage(ctx);
   CGContextRelease(ctx);
   free(data);

   UIImage* returnImage = [UIImage imageWithCGImage:img];
   CGImageRelease(img);

   return returnImage;
}

- (UIImage*) replaceColor:(UIColor*)color inImage:(UIImage*)image withTolerance:(float)tolerance {
    if (!image || !color) {
        return image;
    }

   CGImageRef imageRef = [image CGImage];
   NSUInteger width = CGImageGetWidth(imageRef);
   NSUInteger height = CGImageGetHeight(imageRef);

   NSUInteger bytesPerPixel = 4;
   NSUInteger bytesPerRow = bytesPerPixel * width;
   NSUInteger bitsPerComponent = 8;
   NSUInteger bitmapByteCount = bytesPerRow * height;

   unsigned char *rawData = (unsigned char*) calloc(bitmapByteCount, sizeof(unsigned char));

   CGColorSpaceRef colorSpace = sharedRGBColorSpace();
   CGContextRef context = CGBitmapContextCreate(rawData, width, height,
                                                bitsPerComponent, bytesPerRow, colorSpace,
                                                kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);

   CGContextDrawImage(context, CGRectMake(0, 0, width, height), imageRef);

   CGColorRef cgColor = [color CGColor];
   const CGFloat *components = CGColorGetComponents(cgColor);
   float r = components[0] * 255.0;
   float g = components[1] * 255.0;
   float b = components[2] * 255.0;

   const float redRange[2] = {
       MAX(r - (tolerance / 2.0), 0.0),
       MIN(r + (tolerance / 2.0), 255.0)
   };

   const float greenRange[2] = {
       MAX(g - (tolerance / 2.0), 0.0),
       MIN(g + (tolerance / 2.0), 255.0)
   };

   const float blueRange[2] = {
       MAX(b - (tolerance / 2.0), 0.0),
       MIN(b + (tolerance / 2.0), 255.0)
   };

   int byteIndex = 0;
   while (byteIndex < bitmapByteCount) {
       unsigned char red   = rawData[byteIndex];
       unsigned char green = rawData[byteIndex + 1];
       unsigned char blue  = rawData[byteIndex + 2];

       if (((red >= redRange[0]) && (red <= redRange[1])) &&
           ((green >= greenRange[0]) && (green <= greenRange[1])) &&
           ((blue >= blueRange[0]) && (blue <= blueRange[1]))) {
           rawData[byteIndex] = 0;
           rawData[byteIndex + 1] = 0;
           rawData[byteIndex + 2] = 0;
           rawData[byteIndex + 3] = 0;
       }
       byteIndex += 4;
   }

   UIImage *result = [UIImage imageWithCGImage:CGBitmapContextCreateImage(context)];
   CGContextRelease(context);
   free(rawData);

   return result;
}

+ (UIImage *)imageWithImage:(UIImage *)image scaledToSize:(CGSize)newSize {
    if (!image) {
        return image;
    }

   UIGraphicsBeginImageContextWithOptions(newSize, NO, 0.0);
   [image drawInRect:CGRectMake(0, 0, newSize.width, newSize.height)];
   UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
   UIGraphicsEndImageContext();
   return newImage;
}

- (UIImage *)optimizedImageFromImage:(UIImage *)image
{
    if (!image) {
        return image;
    }

   // Direkte Pixel-Manipulation: Alpha auf 1.0 setzen (schneller als Full Context)
   CGImageRef rawImage = image.CGImage;
   size_t width = CGImageGetWidth(rawImage);
   size_t height = CGImageGetHeight(rawImage);

   size_t bitsPerComponent = 8;
   size_t bytesPerRow = width * 4;
   CGBitmapInfo bitmapInfo = kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big;
   UInt8* data = calloc(bytesPerRow, height);
   CGColorSpaceRef colorSpace = sharedRGBColorSpace();

   CGContextRef ctx = CGBitmapContextCreate(data, width, height, bitsPerComponent, bytesPerRow, colorSpace, bitmapInfo);
   CGContextDrawImage(ctx, CGRectMake(0, 0, width, height), rawImage);

   // Alpha auf 255 (opaque) setzen – row-major order, byte 3 pro pixel
   for (size_t y = 0; y < height; y++) {
       UInt8 *row = &data[y * bytesPerRow];
       for (size_t x = 0; x < width; x++) {
           row[x * 4 + 3] = 255;
       }
   }

   CGImageRef img = CGBitmapContextCreateImage(ctx);
   CGContextRelease(ctx);
   free(data);

   UIImage *optimizedImage = [UIImage imageWithCGImage:img scale:image.scale orientation:UIImageOrientationUp];
   CGImageRelease(img);
   return optimizedImage;
}

- (UIImage *)imageWithTint:(UIColor *)tintColor withImage:(UIImage *)image
{
    if (!image || !tintColor) {
        return image;
    }

   CGRect aRect = CGRectMake(0.f, 0.f, image.size.width, image.size.height);
   CGImageRef alphaMask;

   {
       UIGraphicsBeginImageContextWithOptions(aRect.size, NO, 0.0);
       CGContextRef c = UIGraphicsGetCurrentContext();

       CGContextTranslateCTM(c, 0, aRect.size.height);
       CGContextScaleCTM(c, 1.0, -1.0);
       [image drawInRect: aRect];

       alphaMask = CGBitmapContextCreateImage(c);
       UIGraphicsEndImageContext();
   }

   UIGraphicsBeginImageContextWithOptions(aRect.size, NO, 0.0);
   CGContextRef c = UIGraphicsGetCurrentContext();

   [image drawInRect:aRect];
   CGContextClipToMask(c, aRect, alphaMask);

   CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
   CGContextSetFillColorSpace(c, colorSpace);
   CGContextSetFillColorWithColor(c, tintColor.CGColor);
   UIRectFillUsingBlendMode(aRect, kCGBlendModeNormal);

   UIImage *img = UIGraphicsGetImageFromCurrentImageContext();
   UIGraphicsEndImageContext();

   CGColorSpaceRelease(colorSpace);
   CGImageRelease(alphaMask);

   return img;
}

-(UIImage*)scaleToSize:(CGSize)size withImage:(UIImage *)image
{
    // Delegate zur zentralen Scaling-Methode
    return [self imageWithImage:image scaledToSize:size];
}

- (UIImage *)blurredImageWithImage:(UIImage *)sourceImage{
    if (!sourceImage) {
        return sourceImage;
    }

    // Properties cachern
    CGFloat blurRadius = [TiUtils floatValue:[self.proxy valueForKey:@"blurRadius"] def:kDefaultBlurRadius];

    CIContext *context = sharedCIContext();
    CIImage *inputImage = [CIImage imageWithCGImage:sourceImage.CGImage];

    CIFilter *filter = [CIFilter filterWithName:@"CIGaussianBlur"];
    [filter setValue:inputImage forKey:kCIInputImageKey];
    [filter setValue:@(blurRadius) forKey:@"inputRadius"];
    CIImage *result = [filter valueForKey:kCIOutputImageKey];

    // Single-pass: Directly create image at target size (originalSize)
    CGSize originalSize = sourceImage.size;
    CGFloat scale = sourceImage.scale;

    CGRect cropRect = CGRectInset([result extent],
                                  -((originalSize.width * scale) - (CGRectGetWidth([result extent]))) / 2.0,
                                  -((originalSize.height * scale) - CGRectGetHeight([result extent])) / 2.0);

    CGImageRef cgImage = [context createCGImage:result fromRect:cropRect];
    if (cgImage) {
        UIImage *retVal = [UIImage imageWithCGImage:cgImage scale:scale orientation:UIImageOrientationUp];
        CGImageRelease(cgImage);
        return retVal;
    }

    // Fallback: crop to input extent
    cgImage = [context createCGImage:result fromRect:[inputImage extent]];
    if (cgImage) {
        UIImage *retVal = [UIImage imageWithCGImage:cgImage scale:scale orientation:UIImageOrientationUp];
        CGImageRelease(cgImage);
        return retVal;
    }

    // Last resort: return original
    return sourceImage;
}

// Helper-Methode um duplizierten Code zu reduzieren (für loadUrl Pfad)
- (void)applyImageViewSettingsWithImage:(UIImage *)thisImage backgroundColor:(UIColor *)backgroundColorValue animated:(BOOL)animated animateOnce:(BOOL)animateOnce
{
    self->imageView.contentMode = [self contentModeForImageView];
    self->imageView.opaque = YES;
    self->imageView.layer.masksToBounds = true;
    super.opaque = YES;
    if (backgroundColorValue != nil) {
        self->imageView.backgroundColor = backgroundColorValue;
    }
    BOOL shouldRasterize = [TiUtils boolValue:[[self proxy] valueForUndefinedKey:@"shouldRasterize"] def:NO];
    self->imageView.layer.shouldRasterize = shouldRasterize;

    if (animated) {
        self->imageView.alpha = 0.0;
        [UIView animateWithDuration:kFadeAnimationDuration
                         animations:^{
                           self->imageView.alpha = 1.0;
                         }];
        if (animateOnce) {
            [[self proxy] replaceValue:NUMBOOL(NO) forKey:@"animated" notification:NO];
        }
    }
}

- (void)setTintedImage:(UIImage *)image
{
    if (!image) {
        return;
    }

    NSLog(@"[TiUIImageView+Extension] setTintedImage: CALLED self=%p image=%p avgColorDone=%@ calcMinMax=%@ avgFired=%d minMaxFired=%d",
          self,
          image,
          [self.proxy valueForUndefinedKey:@"averageColorDone"],
          [self.proxy valueForKey:@"calcMinMax"],
          [self averageColorFired],
          [self imageMinMaxFired]);

    // Properties cachieren (KVC-overhead reduzieren)
    BOOL animated = [TiUtils boolValue:[self.proxy valueForKey:@"animated"] def:NO];
    BOOL animateOnce = [TiUtils boolValue:[self.proxy valueForKey:@"animateOnce"] def:NO];
    BOOL shouldRasterize = [TiUtils boolValue:[self.proxy valueForKey:@"shouldRasterize"] def:NO];
    id backgroundColor = [self.proxy valueForKey:@"backgroundColor"];
    id tintColor = [self.proxy valueForKey:@"tintColor"];

    // Average Color berechnen (wenn Listener vorhanden und noch nicht berechnet)
    BOOL calcAverage = NO;
    if ([self.proxy _hasListeners:@"averageColor"]) {
        BOOL averageColorDone = [TiUtils boolValue:[self.proxy valueForKey:@"averageColorDone"] def:YES];
        if (!averageColorDone && ![self averageColorFired]) {
            calcAverage = YES;
            // SOFORT pro-Instanz flag setzen – bevor dispatch_async
            [self setAverageColorFired:YES];
            [[self proxy] replaceValue:NUMBOOL(YES) forKey:@"averageColorDone" notification:NO];
        }
    }

    // calcMinMax prüfen (wenn noch nicht berechnet)
    BOOL calcMinMax = [TiUtils boolValue:[self.proxy valueForKey:@"calcMinMax"] def:NO];
    BOOL calcMinMaxDone = [TiUtils boolValue:[self.proxy valueForKey:@"calcMinMaxDone"] def:NO];
    if (calcMinMax && !calcMinMaxDone && ![self imageMinMaxFired]) {
        [self setImageMinMaxFired:YES];
    }

    // Main-thread dispatch guard: Synchron wenn schon auf main, async sonst
    BOOL onMainThread = [NSThread isMainThread];
    if (onMainThread) {
        if (calcAverage) {
            [self getAverageColor:image];
        }
        [self _applyTintedImage:image tintColor:tintColor backgroundColor:backgroundColor
                    shouldRasterize:shouldRasterize animated:animated animateOnce:animateOnce];
    } else {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (calcAverage) {
                [self getAverageColor:image];
            }
            [self _applyTintedImage:image tintColor:tintColor backgroundColor:backgroundColor
                        shouldRasterize:shouldRasterize animated:animated animateOnce:animateOnce];
        });
    }
}

// Interner Helper für setTintedImage (wird auf Main Thread ausgeführt)
- (void)_applyTintedImage:(UIImage *)image tintColor:(id)tintColor backgroundColor:(id)backgroundColor
    shouldRasterize:(BOOL)shouldRasterize animated:(BOOL)animated animateOnce:(BOOL)animateOnce
{
    // Tint Color anwenden
    if (tintColor != nil) {
        UIImage *tintedImage = [image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        [self->imageView setImage:tintedImage];
        [self->imageView setTintColor:[TiUtils colorValue:tintColor].color];
    }
    else {
        [self->imageView setImage:image];
    }

    self->imageView.contentMode = [self contentModeForImageView];
    self->imageView.opaque = YES;
    self->imageView.layer.masksToBounds = true;
    super.opaque = YES;
    if (backgroundColor != nil) {
        self->imageView.backgroundColor = [[TiUtils colorValue:backgroundColor] _color];
    }
    self->imageView.layer.shouldRasterize = shouldRasterize;

    // Animation
    if (animated) {
        self->imageView.alpha = 0.0;
        [UIView animateWithDuration:kFadeAnimationDuration
                         animations:^{
                           self->imageView.alpha = 1.0;
                         }];
        if (animateOnce) {
            [[self proxy] replaceValue:NUMBOOL(NO) forKey:@"animated" notification:NO];
        }
    }
}

- (void)makeMaskView:(UIView *)view withImage:(UIImage *)image
{
   UIImageView *imageViewMask = [[UIImageView alloc] initWithImage:image];
   imageViewMask.frame = CGRectInset(view.frame, 0.0f, 0.0f);
   view.layer.mask = imageViewMask.layer;
}

- (void)removeAllImagesFromContainer
{
  if (container != nil) {
    for (UIView *view in [container subviews]) {
      [view removeFromSuperview];
    }
  }
  if (imageView != nil) {
    imageView.image = nil;
  }
}

- (UIImage *)convertToUIImage:(id)arg
{
 UIImage *image = nil;

 if ([arg isKindOfClass:[TiBlob class]]) {
   TiBlob *blob = (TiBlob *)arg;
   image = [blob image];
 } else if ([arg isKindOfClass:[TiFile class]]) {
   TiFile *file = (TiFile *)arg;
   NSURL *fileUrl = [NSURL fileURLWithPath:[file path]];
   image = [[ImageLoader sharedLoader] loadImmediateImage:fileUrl];
 } else if ([arg isKindOfClass:[UIImage class]]) {
   image = (UIImage *)arg;
 }

 UIImage *imageToUse = [self rotatedImage:image];

 if (imageToUse != nil) {
   autoHeight = imageToUse.size.height;
   autoWidth = imageToUse.size.width;
 } else {
   autoHeight = autoWidth = 0;
 }
 return imageToUse;
}

- (void)setImage_:(id)arg
{
 UIImageView *imageview = [self imageView];

 // Event-Flags für diesen Image-Lade-Zyklus zurücksetzen
 [self setAverageColorFired:NO];
 [self setImageMinMaxFired:NO];

 // Early-Exit: Gleiches Bild überspringen (verbesserter Vergleich)
 if (arg == nil || [arg isEqual:@""] || [arg isKindOfClass:[NSNull class]]) {
   return;
 }

 // Early-Exit: Wenn derselbe String-Pfad wie im Proxy UND alle Berechnungen fertig – Cache verwenden (Cell Reuse)
 if ([arg isKindOfClass:[NSString class]]) {
   NSString *currentImage = [self.proxy valueForKey:@"image"];
   BOOL calcMinMaxDone = [TiUtils boolValue:[self.proxy valueForKey:@"calcMinMaxDone"] def:NO];
   BOOL averageColorDone = [TiUtils boolValue:[self.proxy valueForKey:@"averageColorDone"] def:YES];
   if ([arg isEqualToString:currentImage] && calcMinMaxDone && averageColorDone) {
     NSLog(@"[TiUIImageView+Extension] setImage_: EARLY EXIT – Cache hit path=%@", arg);
     return;
   }
 }
 // Early-Exit: Wenn dasselbe UIImage-Object
 if ([arg isKindOfClass:[UIImage class]] && [arg isEqual:imageview.image]) {
   return;
 }

 // Image hat sich geändert – Flags zurücksetzen für neue Berechnung
 [[self proxy] replaceValue:NUMBOOL(NO) forKey:@"calcMinMaxDone" notification:NO];
 [[self proxy] replaceValue:NUMBOOL(NO) forKey:@"averageColorDone" notification:NO];

 [self removeAllImagesFromContainer];
 [self cancelPendingImageLoads];

 UIImage *image = [self convertToUIImage:arg];

 if (image == nil) {
   NSURL *imageURL = [[self proxy] sanitizeURL:arg];
   if (![imageURL isKindOfClass:[NSURL class]]) {
     [self throwException:@"invalid image type"
                subreason:[NSString stringWithFormat:@"expected TiBlob, String, TiFile, was: %@", [arg class]]
                 location:CODELOCATION];
   }
   [self loadUrl:imageURL];
   return;
 }

 // Prüfen ob Processing nötig ist
 BOOL hasBlur = [TiUtils boolValue:[[self proxy] valueForKey:@"blurredImage"] def:NO];
 BOOL hasCalcMinMax = [TiUtils boolValue:[[self proxy] valueForKey:@"calcMinMax"] def:NO];
 BOOL hasNoTransparency = [TiUtils boolValue:[[self proxy] valueForUndefinedKey:@"noTransparency"] def:NO] && [self.proxy valueForUndefinedKey:@"backgroundColor"] != nil;

 if (hasBlur || hasCalcMinMax || hasNoTransparency) {
     // Image Processing asynchron im Background
     dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
         UIImage *processedImage = image;
         CGSize originalImageSize = image.size;

         if (hasBlur) {
             processedImage = [self blurredImageWithImage:processedImage];
         }
         if (hasCalcMinMax) {
             processedImage = [self calcMinMax:processedImage originalSize:originalImageSize];
         }

         if (hasNoTransparency) {
             id backgroundColor = [self.proxy valueForUndefinedKey:@"backgroundColor"];
             UIColor *bgColor = [[TiUtils colorValue:backgroundColor] _color];
             processedImage = [self optimizedImageFromImage:processedImage];
             processedImage = [self imageByReplacingColor:[UIColor colorWithRed:0 green:0 blue:0 alpha:1] withImage:processedImage withMinTolerance:0.0 withMaxTolerance:0.0 withColor:bgColor];
             processedImage = [self optimizedImageFromImage:processedImage];
         }

         // setTintedImage direkt aufrufen (dispatcht intern auf Main Thread)
         [self setTintedImage:processedImage];
     });
 }
 else {
     // Kein Processing - direkt anwenden (wie Original)
     [self setTintedImage:image];
 }
}

- (void)getAverageColor:(UIImage *)image{
    if (!image) {
        return;
    }

   CGSize size = {1, 1};
   UIGraphicsBeginImageContextWithOptions(size, YES, 0.0);
   CGContextRef ctx = UIGraphicsGetCurrentContext();
   CGContextSetInterpolationQuality(ctx, kCGInterpolationMedium);
   [image drawInRect:(CGRect){.size = size} blendMode:kCGBlendModeCopy alpha:1];
   uint8_t *data = CGBitmapContextGetData(ctx);

   // RGB Reihenfolge korrigiert (data[0]=Red, data[1]=Green, data[2]=Blue)
   CGFloat red = data[0] / 255.0f;
   CGFloat green = data[1] / 255.0f;
   CGFloat blue = data[2] / 255.0f;
   UIGraphicsEndImageContext();

   long red_ = lroundf(red * 255.0);
   long green_ = lroundf(green * 255.0);
   long blue_ = lroundf(blue * 255.0);

   NSMutableArray *line_data = @[@(red_), @(green_), @(blue_)].mutableCopy;
    NSString *hexColor = [NSString stringWithFormat:@"#%02lx%02lx%02lx", (unsigned long)red_, (unsigned long)green_, (unsigned long)blue_];

    // Event-Dictionary: averageColor (Hex) + color (RGB Array)
    NSDictionary *evt = @{
        @"averageColor": hexColor,
        @"color": line_data
    };

   dispatch_async(dispatch_get_main_queue(), ^{
        // averageColorDone wurde bereits in setTintedImage: gesetzt
        NSLog(@"[TiUIImageView+Extension] getAverageColor: firing averageColor event hex=%@", hexColor);
        [[self proxy] replaceValue:hexColor forKey:@"averageColor" notification:NO];
        [self.proxy fireEvent:@"averageColor" withObject:evt];
   });
}

@end
