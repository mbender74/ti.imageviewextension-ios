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

@implementation TiUIImageView (Extension)

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

- (UIImage *)imageWithImage:(UIImage *)image convertToSize:(CGSize)size {
    if (!image) return image;
    UIGraphicsBeginImageContextWithOptions(size, NO, 0.0);
    [image drawInRect:CGRectMake(0, 0, size.width, size.height)];
    UIImage *destImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return destImage;
}

- (UIImage *)calcMinMax:(UIImage *)image
{
    if (!image) {
        return image;
    }

       id maxHeight = [self.proxy valueForUndefinedKey:@"maxHeight"];
       id maxWidth = [self.proxy valueForUndefinedKey:@"maxWidth"];
       if (maxHeight == nil || maxHeight == [NSNull null]){
           maxHeight = @(image.size.height);
       }
       if (maxWidth == nil || maxWidth == [NSNull null]){
           maxWidth = @(image.size.width);
       }

       CGFloat ratio = ceilf(MIN([maxWidth floatValue] / image.size.width, [maxHeight floatValue] / image.size.height));


    CGSize size = CGSizeMake( ceilf(image.size.width*ratio), ceilf(image.size.height*ratio));

       UIGraphicsBeginImageContextWithOptions(size, NO, 0.0);
       [image drawInRect:CGRectMake(0, 0, size.width, size.height)];
       UIImage *destImage = UIGraphicsGetImageFromCurrentImageContext();
       UIGraphicsEndImageContext();

    [[self proxy] replaceValue:NUMBOOL(NO) forKey:@"calcMinMax" notification:NO];

    NSMutableDictionary *eventObject = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                           @(image.size.width*ratio), @"width",
                                           @(image.size.height*ratio), @"height",
                                                                   nil];
           [self.proxy fireEvent:@"imageMinMax" withObject:eventObject propagate:NO];



       return destImage;
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
   [self removeAllImagesFromContainer];

   CGSize imageSize = CGSizeMake(TiDimensionCalculateValue(width, 0.0),
       TiDimensionCalculateValue(height, 0.0));

   if ([TiUtils boolValue:[[self proxy] valueForKey:@"hires"]]) {
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

   // Prüfen ob Processing nötig ist
   BOOL hasBlur = [TiUtils boolValue:[[self proxy] valueForUndefinedKey:@"blurredImage"] def:NO];
   BOOL hasCalcMinMax = [TiUtils boolValue:[[self proxy] valueForKey:@"calcMinMax"] def:NO];

   if (hasBlur || hasCalcMinMax) {
       // Image Processing asynchron im Background
       dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
           UIImage *processedImage = image;

           if (hasBlur) {
               processedImage = [self blurredImageWithImage:processedImage];
           }
           if (hasCalcMinMax) {
               processedImage = [self calcMinMax:processedImage];
           }
           UIImage *imageToUse = [self rotatedImage:processedImage];
           [(TiUIImageViewProxy *)[self proxy] setImageURL:img];

           dispatch_async(dispatch_get_main_queue(), ^{
               self->autoWidth = ceilf(imageToUse.size.width);
               self->autoHeight = ceilf(imageToUse.size.height);
               if ([TiUtils boolValue:[[self proxy] valueForKey:@"hires"]]) {
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
       if ([TiUtils boolValue:[[self proxy] valueForKey:@"hires"]]) {
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
   UInt8* source255Components = malloc(sizeof(UInt8)*4);
   for (int i = 0; i < 4; i++) source255Components[i] = (UInt8)round(sourceComponents[i]*255.0);

   const CGFloat* destinationComponents = CGColorGetComponents(destinationColor.CGColor);
   UInt8* destination255Components = malloc(sizeof(UInt8)*4);
   for (int i = 0; i < 4; i++) destination255Components[i] = (UInt8)round(destinationComponents[i]*255.0);

   CGImageRef rawImage = image.CGImage;
   size_t width = CGImageGetWidth(rawImage);
   size_t height = CGImageGetHeight(rawImage);
   CGRect rect = {CGPointZero, {width, height}};

   size_t bitsPerComponent = 8;
   size_t bytesPerRow = width*4;
   CGBitmapInfo bitmapInfo = kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big;
   UInt8* data = calloc(bytesPerRow, height);
   CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();

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
   CGColorSpaceRelease(colorSpace);
   free(data);
   free(source255Components);
   free(destination255Components);

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
   CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();

   NSUInteger bytesPerPixel = 4;
   NSUInteger bytesPerRow = bytesPerPixel * width;
   NSUInteger bitsPerComponent = 8;
   NSUInteger bitmapByteCount = bytesPerRow * height;

   unsigned char *rawData = (unsigned char*) calloc(bitmapByteCount, sizeof(unsigned char));

   CGContextRef context = CGBitmapContextCreate(rawData, width, height,
                                                bitsPerComponent, bytesPerRow, colorSpace,
                                                kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
   CGColorSpaceRelease(colorSpace);

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

   CGSize imageSize = image.size;
   UIGraphicsBeginImageContextWithOptions(imageSize, YES, 0.0f);
   [image drawInRect:CGRectMake(0, 0, imageSize.width, imageSize.height)];
   UIImage *optimizedImage = UIGraphicsGetImageFromCurrentImageContext();
   UIGraphicsEndImageContext();
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

-(UIImage*)scaleToSize:(CGSize)size withImage:image
{
    if (!image) {
        return image;
    }

   UIGraphicsBeginImageContextWithOptions(size, NO, 0.0);
   [image drawInRect:CGRectMake(0, 0, size.width, size.height)];
   UIImage* scaledImage = UIGraphicsGetImageFromCurrentImageContext();
   UIGraphicsEndImageContext();

   return scaledImage;
}

- (UIImage *)blurredImageWithImage:(UIImage *)sourceImage{
    if (!sourceImage) {
        return sourceImage;
    }

    CIContext *context = sharedCIContext();
    CIImage *inputImage = [CIImage imageWithCGImage:sourceImage.CGImage];

    CIFilter *filter = [CIFilter filterWithName:@"CIGaussianBlur"];
    [filter setValue:inputImage forKey:kCIInputImageKey];
    CGFloat blurRadius = [TiUtils floatValue:[self.proxy valueForUndefinedKey:@"blurRadius"] def:kDefaultBlurRadius];
    [filter setValue:@(blurRadius) forKey:@"inputRadius"];
    CIImage *result = [filter valueForKey:kCIOutputImageKey];

    // Use result's extent (the blurred image is larger due to blur spread)
    CGRect extent = [result extent];
    CGImageRef cgImage = [context createCGImage:result fromRect:extent];
    
    if (cgImage) {
        UIImage *blurredImage = [UIImage imageWithCGImage:cgImage scale:sourceImage.scale orientation:UIImageOrientationUp];
        CGImageRelease(cgImage);
        
        // Scale back to original size
        CGSize originalSize = CGSizeMake(CGRectGetWidth([inputImage extent]), CGRectGetHeight([inputImage extent]));
        UIGraphicsBeginImageContextWithOptions(originalSize, NO, sourceImage.scale);
        [blurredImage drawInRect:CGRectMake(0, 0, originalSize.width, originalSize.height)];
        UIImage *retVal = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        
        return retVal ? retVal : blurredImage;
    }
    
    // Fallback: try input extent
    cgImage = [context createCGImage:result fromRect:[inputImage extent]];
    if (cgImage) {
        UIImage *retVal = [UIImage imageWithCGImage:cgImage scale:sourceImage.scale orientation:UIImageOrientationUp];
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

    // Properties cachieren
    BOOL animated = [TiUtils boolValue:[self.proxy valueForKey:@"animated"] def:NO];
    BOOL animateOnce = [TiUtils boolValue:[self.proxy valueForKey:@"animateOnce"] def:NO];
    BOOL shouldRasterize = [TiUtils boolValue:[[self proxy] valueForUndefinedKey:@"shouldRasterize"] def:NO];
    id backgroundColor = [self.proxy valueForUndefinedKey:@"backgroundColor"];
    id tintColor = [self.proxy valueForUndefinedKey:@"tintColor"];

    // Average Color berechnen (wenn Listener vorhanden)
    if ([self.proxy _hasListeners:@"averageColor"]) {
        if (![TiUtils boolValue:[[self proxy] valueForKey:@"averageColorDone"] def:YES]) {
            [self getAverageColor:image];
        }
    }

    dispatch_async(dispatch_get_main_queue(), ^{
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
    });
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

 // Early-Exit: Gleiches Bild überspringen (verbesserter Vergleich)
 if (arg == nil || [arg isEqual:@""] || [arg isKindOfClass:[NSNull class]]) {
   return;
 }
 if ([arg isKindOfClass:[UIImage class]] && [arg isEqual:imageview.image]) {
   return;
 }
 if ([arg isKindOfClass:[NSString class]] && imageview.image) {
   id currentImage = [self.proxy valueForUndefinedKey:@"image"];
   if ([arg isEqual:currentImage]) {
     return;
   }
 }

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

         if (hasBlur) {
             processedImage = [self blurredImageWithImage:processedImage];
         }
         if (hasCalcMinMax) {
             processedImage = [self calcMinMax:processedImage];
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
    NSDictionary *evt = @{@"color": line_data};
    NSString *hexColor = [NSString stringWithFormat:@"#%02lx%02lx%02lx", (unsigned long)red_, (unsigned long)green_, (unsigned long)blue_];

   dispatch_async(dispatch_get_main_queue(), ^{
        [[self proxy] replaceValue:NUMBOOL(YES) forKey:@"averageColorDone" notification:NO];
        [[self proxy] replaceValue:hexColor forKey:@"averageColor" notification:NO];
        [self.proxy fireEvent:@"averageColor" withObject:evt];
   });
}

@end
