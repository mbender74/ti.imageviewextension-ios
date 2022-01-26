/**
 * Appcelerator Titanium Mobile
 * Copyright (c) 2009-2010 by Appcelerator, Inc. All Rights Reserved.
 * Licensed under the terms of the Apache Public License
 * Please see the LICENSE included with this distribution for details.
 */
#define USE_TI_UIIMAGEVIEW

#import "TiUIImageView.h"
#import "TiUIImageViewProxy.h"
#import <TitaniumKit/TiViewProxy.h>

//
// this is a re-implementation (sort of) of the UIImageView object used for
// displaying animated images.  The UIImageView object sucks and is very
// problemmatic and we try and solve it here.
//
@interface TiUIImageView (Extension)
@end
