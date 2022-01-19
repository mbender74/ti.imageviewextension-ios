/**
 * ti.imageviewextension
 *
 * Created by Your Name
 * Copyright (c) 2022 Your Company. All rights reserved.
 */

#import "TiImageviewextensionModule.h"
#import "TiBase.h"
#import "TiHost.h"
#import "TiUtils.h"

@implementation TiImageviewextensionModule

#pragma mark Internal

// This is generated for your module, please do not change it
- (id)moduleGUID
{
  return @"a89abb68-61e6-46e9-b0fa-215cb5f54a52";
}

// This is generated for your module, please do not change it
- (NSString *)moduleId
{
  return @"ti.imageviewextension";
}

#pragma mark Lifecycle

- (void)startup
{
  // This method is called when the module is first loaded
  // You *must* call the superclass
  [super startup];
  DebugLog(@"[DEBUG] %@ loaded", self);
}

#pragma Public APIs

- (NSString *)example:(id)args
{
  // Example method. 
  // Call with "MyModule.example(args)"
  return @"hello world";
}

- (NSString *)exampleProp
{
  // Example property getter. 
  // Call with "MyModule.exampleProp" or "MyModule.getExampleProp()"
  return @"Titanium rocks!";
}

- (void)setExampleProp:(id)value
{
  // Example property setter. 
  // Call with "MyModule.exampleProp = 'newValue'" or "MyModule.setExampleProp('newValue')"
}

@end
