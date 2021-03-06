//
//  IDLResourceManager.h
//  iDroidLayout
//
//  Created by Tom Quist on 01.12.12.
//  Copyright (c) 2012 Tom Quist. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "IDLColorStateList.h"
#import "IDLDrawableStateList.h"
#import "IDLStyle.h"
#import "IDLDrawable.h"

@interface IDLResourceManager : NSObject

+ (IDLResourceManager *)currentResourceManager;

- (BOOL)isValidIdentifier:(NSString *)identifier;
- (BOOL)invalidateCacheForBundle:(NSBundle *)bundle;

- (NSString *)stringForIdentifier:(NSString *)identifierString;
- (NSURL *)layoutURLForIdentifier:(NSString *)identifierString;
- (UIImage *)imageForIdentifier:(NSString *)identifierString withCaching:(BOOL)withCaching;
- (UIImage *)imageForIdentifier:(NSString *)identifierString;
- (IDLDrawableStateList *)drawableStateListForIdentifier:(NSString *)identifierString;
- (IDLDrawable *)drawableForIdentifier:(NSString *)identifier;
- (UIColor *)colorForIdentifier:(NSString *)identifierString;
- (IDLColorStateList *)colorStateListForIdentifier:(NSString *)identifierString;
- (IDLStyle *)styleForIdentifier:(NSString *)identifierString;
- (NSArray *)stringArrayForIdentifier:(NSString *)identifierString;

/**
 * Changes the currently used resource manager. This can be used to change
 * the behaviour of resource resolution.
 */
+ (void)setCurrentResourceManager:(IDLResourceManager *)resourceManager;
+ (void)resetCurrentResourceManager;

@end
