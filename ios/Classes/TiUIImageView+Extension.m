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

@interface TiUIImageView (Extension)

@end

@class TiUIImageView;
@class TiUIImageViewProxy;

@implementation TiUIImageView (Extension)
- (void)cancelPendingImageLoads
{
  // cancel a pending request if we have one pending
  [(TiUIImageViewProxy *)[self proxy] cancelPendingImageLoads];
  placeholderLoading = NO;
}

- (void)fireLoadEventWithState:(NSString *)stateString
{
  TiUIImageViewProxy *ourProxy = (TiUIImageViewProxy *)self.proxy;
  [ourProxy propagateLoadEvent:stateString];
}


- (UIImage *)imageWithImage:(UIImage *)image convertToSize:(CGSize)size {
    UIGraphicsBeginImageContext(size);
    [image drawInRect:CGRectMake(0, 0, size.width, size.height)];
    UIImage *destImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return destImage;
}


- (UIImage *)calcMinMax:(UIImage *)image
{

   
       id maxHeight = [self.proxy valueForUndefinedKey:@"maxHeight"];
       id maxWidth = [self.proxy valueForUndefinedKey:@"maxWidth"];
       if (maxHeight == nil || maxHeight == [NSNull null]){
           maxHeight = [NSNumber numberWithFloat:image.size.height];
       }
       if (maxWidth == nil || maxWidth == [NSNull null]){
           maxWidth = [NSNumber numberWithFloat:image.size.width];
       }

       CGFloat ratio = ceilf(MIN([maxWidth floatValue] / image.size.width, [maxHeight floatValue] / image.size.height));

       
    CGSize size = CGSizeMake( ceilf(image.size.width*ratio), ceilf(image.size.height*ratio));
       
       UIGraphicsBeginImageContext(size);
       [image drawInRect:CGRectMake(0, 0, size.width, size.height)];
       UIImage *destImage = UIGraphicsGetImageFromCurrentImageContext();
       UIGraphicsEndImageContext();
    
    [[self proxy] replaceValue:NUMBOOL(NO) forKey:@"calcMinMax" notification:NO];

    NSMutableDictionary *eventObject = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                           [NSNumber numberWithFloat:image.size.width*ratio], @"width",
                                           [NSNumber numberWithFloat:image.size.height*ratio], @"height",
                                                                   nil];
           [self.proxy fireEvent:@"imageMinMax" withObject:eventObject propagate:NO];

    
    
       return destImage;
}



- (UIImage *)rotatedImage:(UIImage *)originalImage
{
  //If autorotate is set to false and the image orientation is not UIImageOrientationUp create new image
  if (![TiUtils boolValue:[[self proxy] valueForUndefinedKey:@"autorotate"] def:YES] && (originalImage.imageOrientation != UIImageOrientationUp)) {
    UIImage *theImage = [UIImage imageWithCGImage:[originalImage CGImage] scale:[originalImage scale] orientation:UIImageOrientationUp];
    return theImage;
  } else {
    return originalImage;
  }
}


- (void)loadDefaultImage:(CGSize)imageSize
{
 // use a placeholder image - which the dev can specify with the
 // defaultImage property or we'll provide the Lookpoint stock one
 // if not specified
 NSURL *defURL = [TiUtils toURL:[self.proxy valueForKey:@"defaultImage"] proxy:self.proxy];

 if ((defURL == nil) && ![TiUtils boolValue:[self.proxy valueForKey:@"preventDefaultImage"] def:NO]) { //This is a special case, because it IS built into the bundle despite being in the simulator.
   NSString *filePath = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"modules/ui/images/photoDefault.png"];
   defURL = [NSURL fileURLWithPath:filePath];
 }

 if (defURL != nil) {
   UIImage *poster = [[ImageLoader sharedLoader] loadImmediateImage:defURL withSize:imageSize];

   UIImage *imageToUse = [self rotatedImage:poster];

   // TODO: Use the full image size here?  Auto width/height is going to be changed once the image is loaded.
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

   // NOTE: Loading from URL means we can't pre-determine any % value.
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

     
     
   if (image != nil) {
       if ([TiUtils boolValue:[[self proxy] valueForUndefinedKey:@"blurredImage"] def:NO]) {
           image = [self blurredImageWithImage:image];
       }
     if ([TiUtils boolValue:[[self proxy] valueForKey:@"calcMinMax"] def:NO]) {
           image = [self calcMinMax:image];
     }
     UIImage *imageToUse = [self rotatedImage:image];
     [(TiUIImageViewProxy *)[self proxy] setImageURL:img];

     autoWidth = ceilf(imageToUse.size.width);
     autoHeight = ceilf(imageToUse.size.height);
     if ([TiUtils boolValue:[[self proxy] valueForKey:@"hires"]]) {
       autoWidth = ceilf(autoWidth / 2);
       autoHeight = ceilf(autoHeight / 2);
     }
    
     [self setTintedImage:imageToUse];
     [self fireLoadEventWithState:@"image"];
   }
 }
}


- (UIImage* )setBackgroundImageByColor:(UIColor *)backgroundColor withFrame:(CGRect )rect{

   // tcv - temporary colored view
   UIView *tcv = [[UIView alloc] initWithFrame:rect];
   [tcv setBackgroundColor:backgroundColor];


   // set up a graphics context of button's size
   CGSize gcSize = tcv.frame.size;
   UIGraphicsBeginImageContext(gcSize);
   // add tcv's layer to context
   [tcv.layer renderInContext:UIGraphicsGetCurrentContext()];
   // create background image now
   UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    return image;
}


-(UIImage*) imageByReplacingColor:(UIColor*)sourceColor withImage:(UIImage*)image withMinTolerance:(CGFloat)minTolerance withMaxTolerance:(CGFloat)maxTolerance withColor:(UIColor*)destinationColor {

   // components of the source color
   const CGFloat* sourceComponents = CGColorGetComponents(sourceColor.CGColor);
   UInt8* source255Components = malloc(sizeof(UInt8)*4);
   for (int i = 0; i < 4; i++) source255Components[i] = (UInt8)round(sourceComponents[i]*255.0);

   // components of the destination color
   const CGFloat* destinationComponents = CGColorGetComponents(destinationColor.CGColor);
   UInt8* destination255Components = malloc(sizeof(UInt8)*4);
   for (int i = 0; i < 4; i++) destination255Components[i] = (UInt8)round(destinationComponents[i]*255.0);

   // raw image reference
   CGImageRef rawImage = image.CGImage;

   // image attributes
   size_t width = CGImageGetWidth(rawImage);
   size_t height = CGImageGetHeight(rawImage);
   CGRect rect = {CGPointZero, {width, height}};

   // bitmap format
   size_t bitsPerComponent = 8;
   size_t bytesPerRow = width*4;
   CGBitmapInfo bitmapInfo = kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big;

   // data pointer
   UInt8* data = calloc(bytesPerRow, height);

   CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();

   // create bitmap context
   CGContextRef ctx = CGBitmapContextCreate(data, width, height, bitsPerComponent, bytesPerRow, colorSpace, bitmapInfo);
   CGContextDrawImage(ctx, rect, rawImage);

   // loop through each pixel's components
   for (int byte = 0; byte < bytesPerRow*height; byte += 4) {

       UInt8 r = data[byte];
       UInt8 g = data[byte+1];
       UInt8 b = data[byte+2];

       // delta components
       UInt8 dr = abs(r-source255Components[0]);
       UInt8 dg = abs(g-source255Components[1]);
       UInt8 db = abs(b-source255Components[2]);

       // ratio of 'how far away' each component is from the source color
       CGFloat ratio = (dr+dg+db)/(255.0*3.0);
       if (ratio > maxTolerance) ratio = 1; // if ratio is too far away, set it to max.
       if (ratio < minTolerance) ratio = 0; // if ratio isn't far enough away, set it to min.

       // blend color components
       data[byte] = (UInt8)round(ratio*r)+(UInt8)round((1.0-ratio)*destination255Components[0]);
       data[byte+1] = (UInt8)round(ratio*g)+(UInt8)round((1.0-ratio)*destination255Components[1]);
       data[byte+2] = (UInt8)round(ratio*b)+(UInt8)round((1.0-ratio)*destination255Components[2]);

   }

   // get image from context
   CGImageRef img = CGBitmapContextCreateImage(ctx);

   // clean up
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
   float r = components[0];
   float g = components[1];
   float b = components[2];
   //float a = components[3]; // not needed

   r = r * 255.0;
   g = g * 255.0;
   b = b * 255.0;

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
           // make the pixel transparent
           //
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
   //UIGraphicsBeginImageContext(newSize);
   UIGraphicsBeginImageContextWithOptions(newSize, NO, 0.0);
   [image drawInRect:CGRectMake(0, 0, newSize.width, newSize.height)];
   UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
   UIGraphicsEndImageContext();
   return newImage;
}





- (UIImage *)optimizedImageFromImage:(UIImage *)image
{
   CGSize imageSize = image.size;
   UIGraphicsBeginImageContextWithOptions( imageSize, YES, 0.0f );
   [image drawInRect: CGRectMake( 0, 0, imageSize.width, imageSize.height )];
   UIImage *optimizedImage = UIGraphicsGetImageFromCurrentImageContext();
   UIGraphicsEndImageContext();
   return optimizedImage;
}



- (UIImage *)imageWithTint:(UIColor *)tintColor withImage:(UIImage *)image
{
   // Begin drawing
   CGRect aRect = CGRectMake(0.f, 0.f, image.size.width, image.size.height);
   CGImageRef alphaMask;

   //
   // Compute mask flipping image
   //
   {
       UIGraphicsBeginImageContext(aRect.size);
       CGContextRef c = UIGraphicsGetCurrentContext();

       // draw image
       CGContextTranslateCTM(c, 0, aRect.size.height);
       CGContextScaleCTM(c, 1.0, -1.0);
       [image drawInRect: aRect];

       alphaMask = CGBitmapContextCreateImage(c);

       UIGraphicsEndImageContext();
   }

   //
   UIGraphicsBeginImageContext(aRect.size);

   // Get the graphic context
   CGContextRef c = UIGraphicsGetCurrentContext();

   // Draw the image
   [image drawInRect:aRect];

   // Mask
   CGContextClipToMask(c, aRect, alphaMask);

   // Set the fill color space
   CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
   CGContextSetFillColorSpace(c, colorSpace);

   // Set the fill color
   CGContextSetFillColorWithColor(c, tintColor.CGColor);

   UIRectFillUsingBlendMode(aRect, kCGBlendModeNormal);

   UIImage *img = UIGraphicsGetImageFromCurrentImageContext();
      
   UIGraphicsEndImageContext();

   // Release memory
   CGColorSpaceRelease(colorSpace);
   CGImageRelease(alphaMask);

   return img;
}


-(UIImage*)scaleToSize:(CGSize)size withImage:image
{
   // Create a bitmap graphics context
   // This will also set it as the current context
   UIGraphicsBeginImageContext(size);

   // Draw the scaled image in the current context
   [image drawInRect:CGRectMake(0, 0, size.width, size.height)];

   // Create a new image from current context
   UIImage* scaledImage = image;

   // Pop the current context from the stack
   UIGraphicsEndImageContext();

   // Return our new scaled image
   return scaledImage;
}



- (UIImage *)blurredImageWithImage:(UIImage *)sourceImage{

    //  Create our blurred image
    CIContext *context = [CIContext contextWithOptions:nil];
    CIImage *inputImage = [CIImage imageWithCGImage:sourceImage.CGImage];

    //  Setting up Gaussian Blur
    CIFilter *filter = [CIFilter filterWithName:@"CIGaussianBlur"];
      
    [filter setValue:inputImage forKey:kCIInputImageKey];
    [filter setValue:[NSNumber numberWithFloat:[TiUtils floatValue:[self.proxy valueForUndefinedKey:@"blurRadius"] def:15.0]] forKey:@"inputRadius"];
    CIImage *result = [filter valueForKey:kCIOutputImageKey];

    /*  CIGaussianBlur has a tendency to shrink the image a little, this ensures it matches
     *  up exactly to the bounds of our original image */
    CGImageRef cgImage = [context createCGImage:result fromRect:[inputImage extent]];

    UIImage *retVal = [UIImage imageWithCGImage:cgImage];

    if (cgImage) {
        CGImageRelease(cgImage);
    }

    return retVal;
}




- (void)setTintedImage:(UIImage *)image
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{

 

    
 UIImage *thisImage = image;
 id tintColor = [self.proxy valueForUndefinedKey:@"tintColor"];
 id backgroundColor = [self.proxy valueForUndefinedKey:@"backgroundColor"];

    
 UIColor * backgroundColorValue = nil;
    
   if ([TiUtils boolValue:[[self proxy] valueForUndefinedKey:@"noTransparency"] def:NO]) {
       
    if (backgroundColor != nil) {

      backgroundColorValue = [[TiUtils colorValue:backgroundColor] _color];
        
        thisImage = [self optimizedImageFromImage:thisImage];
        thisImage = [self imageByReplacingColor:[UIColor colorWithRed:0 green:0 blue:0 alpha:1] withImage:thisImage withMinTolerance:0.0 withMaxTolerance:0.0 withColor:backgroundColorValue];
        thisImage = [self optimizedImageFromImage:thisImage];
        
        if ([self.proxy _hasListeners:@"averageColor"]) {
              if (![TiUtils boolValue:[[self proxy] valueForKey:@"averageColorDone"] def:YES]) {
                    [self getAverageColor:thisImage];
              }
        }
                
        if ([TiUtils boolValue:[self.proxy valueForKey:@"animated"] def:NO]){
            dispatch_async(dispatch_get_main_queue(), ^{

            self->imageView.alpha = 0.0;
            [self->imageView setImage:thisImage];
                self->imageView.contentMode = self->imageView.contentMode;
                self->imageView.opaque = YES;
                self->imageView.layer.masksToBounds = true;
            super.opaque = YES;
            if (backgroundColorValue != nil) {
                self->imageView.backgroundColor = backgroundColorValue;
            }
                if ([TiUtils boolValue:[[self proxy] valueForUndefinedKey:@"shouldRasterize"] def:NO]) {
                    self->imageView.layer.shouldRasterize = YES;
                }
            [UIView animateWithDuration:0.5
                             animations:^{
                               self->imageView.alpha = 1.0;
                             }];
            });
            if ([TiUtils boolValue:[self.proxy valueForKey:@"animateOnce"] def:NO]){
                [[self proxy] replaceValue:NUMBOOL(NO) forKey:@"animated" notification:NO];
            }
        }
        else {
            dispatch_async(dispatch_get_main_queue(), ^{

            [self->imageView setImage:thisImage];
                self->imageView.contentMode = self->imageView.contentMode;
                
                self->imageView.opaque = YES;
                self->imageView.layer.masksToBounds = true;

            super.opaque = YES;
            if (backgroundColorValue != nil) {
                self->imageView.backgroundColor = backgroundColorValue;
            }
            if ([TiUtils boolValue:[[self proxy] valueForUndefinedKey:@"shouldRasterize"] def:NO]) {
                self->imageView.layer.shouldRasterize = YES;
            }

            });

        }
        
    }
   }
   else {
         if (tintColor != nil) {
             
             if ([TiUtils boolValue:[self.proxy valueForKey:@"animated"] def:NO]){
                 dispatch_async(dispatch_get_main_queue(), ^{

                     self->imageView.alpha = 0.0;
                 [self->imageView setImage:[thisImage imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]];
                 [self->imageView setTintColor:[TiUtils colorValue:tintColor].color];
                 self->imageView.contentMode = self->imageView.contentMode;
                  self->imageView.opaque = YES;
                  self->imageView.layer.masksToBounds = true;
                 super.opaque = YES;
                 if ([self.proxy _hasListeners:@"averageColor"]) {
                       if (![TiUtils boolValue:[[self proxy] valueForKey:@"averageColorDone"] def:YES]) {
                               [self getAverageColor:self->imageView.image];
                       }
                 }
                 if (backgroundColorValue != nil) {
                     self->imageView.backgroundColor = backgroundColorValue;
                 }
                     if ([TiUtils boolValue:[[self proxy] valueForUndefinedKey:@"shouldRasterize"] def:NO]) {
                         self->imageView.layer.shouldRasterize = YES;
                     }
                 [UIView animateWithDuration:0.5
                                  animations:^{
                                    self->imageView.alpha = 1.0;
                                  }];
                 });
                 if ([TiUtils boolValue:[self.proxy valueForKey:@"animateOnce"] def:NO]){
                     [[self proxy] replaceValue:NUMBOOL(NO) forKey:@"animated" notification:NO];
                 }

             }
             else {
                 dispatch_async(dispatch_get_main_queue(), ^{

                 [self->imageView setImage:[thisImage imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]];
                 [self->imageView setTintColor:[TiUtils colorValue:tintColor].color];
                     self->imageView.contentMode = self->imageView.contentMode;
                     self->imageView.opaque = YES;
                     self->imageView.layer.masksToBounds = true;
                 super.opaque = YES;
                 if ([self.proxy _hasListeners:@"averageColor"]) {
                       if (![TiUtils boolValue:[[self proxy] valueForKey:@"averageColorDone"] def:YES]) {
                               [self getAverageColor:self->imageView.image];
                       }
                 }
                 if (backgroundColorValue != nil) {
                     self->imageView.backgroundColor = backgroundColorValue;
                 }
                     if ([TiUtils boolValue:[[self proxy] valueForUndefinedKey:@"shouldRasterize"] def:NO]) {
                         self->imageView.layer.shouldRasterize = YES;
                     }
                 });
             }
             
             
         } else {
             if ([self.proxy _hasListeners:@"averageColor"]) {
                   if (![TiUtils boolValue:[[self proxy] valueForKey:@"averageColorDone"] def:YES]) {
                           [self getAverageColor:thisImage];
                   }
             }
             if ([TiUtils boolValue:[self.proxy valueForKey:@"animated"] def:NO]){
                 dispatch_async(dispatch_get_main_queue(), ^{

                     self->imageView.alpha = 0.0;
                 [self->imageView setImage:thisImage];
                     self->imageView.contentMode = self->imageView.contentMode;
                     self->imageView.opaque = YES;
                     self->imageView.layer.masksToBounds = true;
                 super.opaque = YES;
                 if (backgroundColorValue != nil) {
                     self->imageView.backgroundColor = backgroundColorValue;
                 }

                 [UIView animateWithDuration:0.5
                                  animations:^{
                                    self->imageView.alpha = 1.0;
                                  }];
                 });
                 if ([TiUtils boolValue:[self.proxy valueForKey:@"animateOnce"] def:NO]){
                     [[self proxy] replaceValue:NUMBOOL(NO) forKey:@"animated" notification:NO];
                 }

                 if ([TiUtils boolValue:[[self proxy] valueForUndefinedKey:@"shouldRasterize"] def:NO]) {
                     self->imageView.layer.shouldRasterize = YES;
                 }
             }
             else {
                 dispatch_async(dispatch_get_main_queue(), ^{

                 [self->imageView setImage:thisImage];
                     self->imageView.contentMode = self->imageView.contentMode;
                     self->imageView.opaque = YES;
                     self->imageView.layer.masksToBounds = true;

                 super.opaque = YES;
                 if (backgroundColorValue != nil) {
                     self->imageView.backgroundColor = backgroundColorValue;
                 }
                     if ([TiUtils boolValue:[[self proxy] valueForUndefinedKey:@"shouldRasterize"] def:NO]) {
                         self->imageView.layer.shouldRasterize = YES;
                     }
                 });

             }

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
  // remove any existing images
  if (container != nil) {
    for (UIView *view in [container subviews]) {
      [view removeFromSuperview];
    }
  }
  if (imageView != nil) {
    imageView.image = nil;
  }
}

- (void)getAverageColor:(UIImage *)image{
   
dispatch_async(dispatch_get_main_queue(), ^{
   CGSize size = {1, 1};
   UIGraphicsBeginImageContext(size);
   CGContextRef ctx = UIGraphicsGetCurrentContext();
   CGContextSetInterpolationQuality(ctx, kCGInterpolationMedium);
   [image drawInRect:(CGRect){.size = size} blendMode:kCGBlendModeCopy alpha:1];
   uint8_t *data = CGBitmapContextGetData(ctx);
   UIColor *color = [UIColor colorWithRed:data[2] / 255.0f
                                    green:data[1] / 255.0f
                                     blue:data[0] / 255.0f
                                    alpha:1];
   UIGraphicsEndImageContext();
   
   
   CGFloat red, green, blue, alpha;
   [color getRed: &red green: &green blue: &blue alpha: &alpha];
   int red_ = red * 255;
   int green_ = green * 255;
   int blue_ = blue * 255;

   NSInteger rgb[3];
   rgb[0] = red_;
   rgb[1] = green_;
   rgb[2] = blue_;
   NSMutableArray *line_data = [[NSMutableArray alloc] init];
   
   [line_data addObject:[NSNumber numberWithInt:red_]];
   [line_data addObject:[NSNumber numberWithInt:green_]];
   [line_data addObject:[NSNumber numberWithInt:blue_]];

    
    
    
    NSDictionary *evt = [NSDictionary dictionaryWithObject:line_data forKey:@"color"];
    [self.proxy fireEvent:@"averageColor" withObject:evt];
    [[self proxy] replaceValue:NUMBOOL(YES) forKey:@"averageColorDone" notification:NO];
    [[self proxy] replaceValue:[NSString stringWithFormat:@"#%02lX%02lX%02lX", lroundf(red_ * 255.0), lroundf(green_ * 255.0), lroundf(blue_ * 255.0)] forKey:@"averageColor" notification:NO];
   });
}

@end
