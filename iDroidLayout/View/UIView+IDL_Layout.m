//
//  UIView+IDL.m
//  iDroidLayout
//
//  Created by Tom Quist on 22.07.12.
//  Copyright (c) 2012 Tom Quist. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "UIView+IDL_Layout.h"
#import "UIColor+IDL_ColorParser.h"
#import "UIView+IDL_ViewGroup.h"
#import "NSDictionary+IDL_ResourceManager.h"
#import "UIView+IDLDrawable.h"
#import "IDLResourceManager.h"

#pragma mark - import libs
#include <objc/runtime.h>

#pragma mark -

IDLLayoutMeasureSpec IDLLayoutMeasureSpecMake(CGFloat size, IDLLayoutMeasureSpecMode mode) {
    IDLLayoutMeasureSpec measureSpec;
    measureSpec.size = size;
    measureSpec.mode = mode;
    return measureSpec;
}

IDLViewVisibility IDLViewVisibilityFromString(NSString *visibilityString) {
    IDLViewVisibility visibility = IDLViewVisibilityVisible;
    if ([visibilityString isEqualToString:@"visible"]) {
        visibility = IDLViewVisibilityVisible;
    } else if ([visibilityString isEqualToString:@"invisible"]) {
        visibility = IDLViewVisibilityInvisible;
    } else if ([visibilityString isEqualToString:@"gone"]) {
        visibility = IDLViewVisibilityGone;
    }
    return visibility;
}

BOOL BOOLFromString(NSString *boolString) {
    return [boolString isEqualToString:@"true"] || [boolString isEqualToString:@"TRUE"] || [boolString isEqualToString:@"yes"] || [boolString isEqualToString:@"YES"] || [boolString boolValue];
}

@implementation UIView (IDL_Layout)

static char identifierKey;
static char minWidthKey;
static char minHeightKey;
static char measuredWidthSizeKey;
static char measuredWidthStateKey;
static char measuredHeightSizeKey;
static char measuredHeightStateKey;
static char paddingKey;
static char layoutParamsKey;
static char isLayoutRequestedKey;
static char visibilityKey;

- (void)setupFromAttributes:(NSDictionary *)attrs {
    
    // visibility
    NSString *visibilityString = [attrs objectForKey:@"visibility"];
    self.visibility = IDLViewVisibilityFromString(visibilityString);
    
    // background
    /*UIColor *background = [attrs colorFromIDLValueForKey:@"background"];
    if (background != nil) {
        self.backgroundColor = background;
    }*/
    NSString *backgroundString = [attrs objectForKey:@"background"];
    if (backgroundString != nil) {
        self.backgroundDrawable = [[IDLResourceManager currentResourceManager] drawableForIdentifier:backgroundString];
    }
    
    // padding
    NSString *paddingString = [attrs objectForKey:@"padding"];
    if (paddingString != nil) {
        CGFloat padding = [paddingString floatValue];
        self.padding = UIEdgeInsetsMake(padding, padding, padding, padding);
    } else {
        UIEdgeInsets padding = self.padding;
        UIEdgeInsets initialPadding = padding;
        NSString *paddingTopString = [attrs objectForKey:@"paddingTop"];
        NSString *paddingLeftString = [attrs objectForKey:@"paddingLeft"];
        NSString *paddingBottomString = [attrs objectForKey:@"paddingBottom"];
        NSString *paddingRightString = [attrs objectForKey:@"paddingRight"];
        if ([paddingTopString length] > 0) padding.top = [paddingTopString floatValue];
        if ([paddingLeftString length] > 0) padding.left = [paddingLeftString floatValue];
        if ([paddingBottomString length] > 0) padding.bottom = [paddingBottomString floatValue];
        if ([paddingRightString length] > 0) padding.right = [paddingRightString floatValue];
        if (!UIEdgeInsetsEqualToEdgeInsets(padding, initialPadding)) {
            self.padding = padding;
        }
    }
    
    // alpha
    NSString *alphaString = [attrs objectForKey:@"alpha"];
    if (alphaString != nil) {
        CGFloat alpha = MIN(1.0, MAX(0.0, [alphaString floatValue]));
        self.alpha = alpha;
    }
    
    // minWidth/minHeight
    CGFloat minWidth = [[attrs objectForKey:@"minWidth"] floatValue];
    CGFloat minHeight = [[attrs objectForKey:@"minHeight"] floatValue];
    self.minWidth = minWidth;
    self.minHeight = minHeight;
    
    // identifier
    NSString *identifier = [attrs objectForKey:@"id"];
    if (identifier != nil) {
        NSRange range = [identifier rangeOfString:@"@id/"];
        if (range.location == NSNotFound) {
            range = [identifier rangeOfString:@"@+id/"];    
        }
        if (range.location == 0) {
            identifier = [NSString stringWithFormat:@"%@", [identifier substringFromIndex:range.location + range.length]];
        }
        self.identifier = identifier;
    }
    
    // border
    NSString *borderWidth = [attrs objectForKey:@"borderWidth"];
    if (borderWidth != nil) {
        self.layer.borderWidth = [borderWidth floatValue];
    }
    UIColor *borderColor = [attrs colorFromIDLValueForKey:@"borderColor"];
    if (borderColor != nil) {
        self.layer.borderColor = borderColor.CGColor;
    }
    NSString *cornerRadius = [attrs objectForKey:@"cornerRadius"];
    if (cornerRadius != nil) {
        self.layer.cornerRadius = [cornerRadius floatValue];
    }
}

- (id)initWithAttributes:(NSDictionary *)attrs {
    self = [self init];
    if (self) {
        [self setupFromAttributes:attrs];         
    }
    return self;
}

- (IDLLayoutMeasuredDimension)defaultSizeForSize:(CGFloat)size measureSpec:(IDLLayoutMeasureSpec)measureSpec {
    CGFloat result = size;
    IDLLayoutMeasureSpecMode specMode = measureSpec.mode;
    CGFloat specSize = measureSpec.size;
    
    switch (specMode) {
        case IDLLayoutMeasureSpecModeUnspecified:
            result = size;
            break;
        case IDLLayoutMeasureSpecModeAtMost:
        case IDLLayoutMeasureSpecModeExactly:
            result = specSize;
            break;
    }
    IDLLayoutMeasuredDimension ret = {result, IDLLayoutMeasuredStateNone};
    return ret;
}

+ (IDLLayoutMeasuredWidthHeightState)combineMeasuredStatesCurrentState:(IDLLayoutMeasuredWidthHeightState)curState newState:(IDLLayoutMeasuredWidthHeightState)newState {
    curState.widthState |= newState.widthState;
    curState.heightState |= newState.heightState;
    return curState;
}

/**
 * Utility to reconcile a desired size and state, with constraints imposed
 * by a MeasureSpec.  Will take the desired size, unless a different size
 * is imposed by the constraints.  The returned value is a compound integer,
 * with the resolved size in the {@link #MEASURED_SIZE_MASK} bits and
 * optionally the bit {@link #MEASURED_STATE_TOO_SMALL} set if the resulting
 * size is smaller than the size the view wants to be.
 *
 * @param size How big the view wants to be
 * @param measureSpec Constraints imposed by the parent
 * @return Size information bit mask as defined by
 * {@link #MEASURED_SIZE_MASK} and {@link #MEASURED_STATE_TOO_SMALL}.
 */
+ (IDLLayoutMeasuredDimension)resolveSizeAndStateForSize:(CGFloat)size measureSpec:(IDLLayoutMeasureSpec)measureSpec childMeasureState:(IDLLayoutMeasuredState)childMeasuredState {
    IDLLayoutMeasuredDimension result = {size, IDLLayoutMeasuredStateNone};
    switch (measureSpec.mode) {
        case IDLLayoutMeasureSpecModeUnspecified:
            result.size = size;
            break;
        case IDLLayoutMeasureSpecModeAtMost:
            if (measureSpec.size < size) {
                result.size = measureSpec.size;
                result.state = IDLLayoutMeasuredStateTooSmall;
            } else {
                result.size = size;
            }
            break;
        case IDLLayoutMeasureSpecModeExactly:
            result.size = measureSpec.size;
            break;
    }
    result.state |= childMeasuredState;
    return result;
}

+ (CGFloat)resolveSizeForSize:(CGFloat)size measureSpec:(IDLLayoutMeasureSpec)measureSpec {
    return [self resolveSizeAndStateForSize:size measureSpec:measureSpec childMeasureState:IDLLayoutMeasuredStateNone].size;
}

- (void)setIdentifier:(NSString *)identifier {
    objc_setAssociatedObject(self,
                             &identifierKey,
                             identifier,
                             OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSString *)identifier {
    return objc_getAssociatedObject(self, &identifierKey);
}

- (void)setLayoutParams:(IDLLayoutParams *)layoutParams {
    objc_setAssociatedObject(self,
                             &layoutParamsKey,
                             layoutParams,
                             OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    [self requestLayout];
}

- (IDLLayoutParams *)layoutParams {
    return objc_getAssociatedObject(self, &layoutParamsKey);
}

- (void)setVisibility:(IDLViewVisibility)visibility {
    IDLViewVisibility curVisibility = self.visibility;
    [self setHidden:(visibility != IDLViewVisibilityVisible)];
    objc_setAssociatedObject(self,
                             &visibilityKey,
                             @(visibility),
                             OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    if ((curVisibility != visibility) && (curVisibility == IDLViewVisibilityGone || visibility == IDLViewVisibilityGone)) {
        [self requestLayout];
    }
}

- (IDLViewVisibility)visibility {
    NSNumber *value = objc_getAssociatedObject(self, &visibilityKey);
    IDLViewVisibility visibility = [value intValue];
    if (visibility == IDLViewVisibilityVisible && self.isHidden) {
        // Visibility has been set independently
        visibility = IDLViewVisibilityInvisible;
    }
    return visibility;
}

- (CGFloat)minWidth {
    NSNumber *value = objc_getAssociatedObject(self, &minWidthKey);
    return [value floatValue];
}

- (CGFloat)minHeight {
    NSNumber *value = objc_getAssociatedObject(self, &minHeightKey);
    return [value floatValue];
}

- (void)setMinWidth:(CGFloat)minWidth {
    objc_setAssociatedObject(self,
                             &minWidthKey,
                             @(minWidth),
                             OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void)setMinHeight:(CGFloat)minHeight {
    objc_setAssociatedObject(self,
                             &minHeightKey,
                             @(minHeight),
                             OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (CGFloat)suggestedMinimumWidth {
    CGFloat suggestedMinWidth = [self minWidth];
    return suggestedMinWidth;
}

- (CGFloat)suggestedMinimumHeight {
    CGFloat suggestedMinHeight = [self minHeight];
    return suggestedMinHeight;
}

- (void)setMeasuredDimensionWidth:(IDLLayoutMeasuredDimension)width height:(IDLLayoutMeasuredDimension)height {
    objc_setAssociatedObject(self,
                             &measuredWidthSizeKey,
                             @(width.size),
                             OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    objc_setAssociatedObject(self,
                             &measuredWidthStateKey,
                             @(width.state),
                             OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    objc_setAssociatedObject(self,
                             &measuredHeightSizeKey,
                             @(height.size),
                             OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    objc_setAssociatedObject(self,
                             &measuredHeightStateKey,
                             @(height.state),
                             OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (BOOL)isLayoutRequested {
    NSNumber *value = objc_getAssociatedObject(self, &isLayoutRequestedKey);
    return [value boolValue];
}

- (void)setIsLayoutRequested:(BOOL)isRequested {
    objc_setAssociatedObject(self,
                             &isLayoutRequestedKey,
                             @(isRequested),
                             OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (IDLLayoutMeasuredDimension)measuredWidth {
    NSNumber *sizeValue = objc_getAssociatedObject(self, &measuredWidthSizeKey);
    NSNumber *stateValue = objc_getAssociatedObject(self, &measuredWidthStateKey);
    IDLLayoutMeasuredDimension ret = {[sizeValue floatValue], [stateValue intValue]};
    return ret;
}

- (IDLLayoutMeasuredDimension)measuredHeight {
    NSNumber *sizeValue = objc_getAssociatedObject(self, &measuredHeightSizeKey);
    NSNumber *stateValue = objc_getAssociatedObject(self, &measuredHeightStateKey);
    IDLLayoutMeasuredDimension ret = {[sizeValue floatValue], [stateValue intValue]};
    return ret;
}

- (CGSize)measuredSize {
    return CGSizeMake([self measuredWidth].size, [self measuredHeight].size);
}

- (void)onMeasureWithWidthMeasureSpec:(IDLLayoutMeasureSpec)widthMeasureSpec heightMeasureSpec:(IDLLayoutMeasureSpec)heightMeasureSpec {
    IDLLayoutMeasuredDimension width = [self defaultSizeForSize:[self suggestedMinimumWidth] measureSpec:widthMeasureSpec];
    IDLLayoutMeasuredDimension height = [self defaultSizeForSize:[self suggestedMinimumHeight] measureSpec:heightMeasureSpec];
    [self setMeasuredDimensionWidth:width height:height];
}

- (void)measureWithWidthMeasureSpec:(IDLLayoutMeasureSpec)widthMeasureSpec heightMeasureSpec:(IDLLayoutMeasureSpec)heightMeasureSpec {
    [self onMeasureWithWidthMeasureSpec:widthMeasureSpec heightMeasureSpec:heightMeasureSpec];
}

- (void)onLayoutWithFrame:(CGRect)frame didFrameChange:(BOOL)changed {
    
}

- (CGRect)roundFrame:(CGRect)frame {
    frame.origin.x = ceilf(frame.origin.x);
    frame.origin.y = ceilf(frame.origin.y);
    frame.size.width = ceilf(frame.size.width);
    frame.size.height = ceilf(frame.size.height);
    return frame;
}

- (void)layoutWithFrame:(CGRect)frame {
    [self setIsLayoutRequested:FALSE];
    CGRect oldFrame = self.frame;
    CGRect newFrame = [self roundFrame:frame];
    BOOL changed = !CGRectEqualToRect(oldFrame, newFrame);
    if (changed) self.frame = newFrame;
    
    //if (changed) {
    [self onLayoutWithFrame:frame didFrameChange:changed];
    //}
    if (changed) {
        NSString *identifier = self.identifier;
        if (identifier != nil) {
            NSLog(@"%@ (%@) changed size: ", NSStringFromClass([self class]), identifier);
        } else {
            NSLog(@"%@ changed size: ", NSStringFromClass([self class]));            
        }
        NSLog(@"OldRect: %@", NSStringFromCGRect(oldFrame));
        NSLog(@"NewRect: %@", NSStringFromCGRect(newFrame));
    }
}

- (UIEdgeInsets)padding {
    NSValue *value = objc_getAssociatedObject(self, &paddingKey);
    return [value UIEdgeInsetsValue];
}

- (void)setPadding:(UIEdgeInsets)padding {
    UIEdgeInsets prevPadding = self.padding;
    if (!UIEdgeInsetsEqualToEdgeInsets(prevPadding, padding)) {
        objc_setAssociatedObject(self,
                                 &paddingKey,
                                 [NSValue valueWithUIEdgeInsets:padding],
                                 OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        [self requestLayout];
    }
}

/**
 * <p>Return the offset of the widget's text baseline from the widget's top
 * boundary. If this widget does not support baseline alignment, this
 * method returns -1. </p>
 *
 * @return the offset of the baseline within the widget's bounds or -1
 *         if baseline alignment is not supported
 */
- (CGFloat)baseline {
    return -1;
}

- (IDLLayoutMeasuredWidthHeightState)measuredState {
    IDLLayoutMeasuredWidthHeightState ret;
    ret.widthState = [self measuredWidth].state;
    ret.heightState = [self measuredHeight].state;
    return ret;
}

- (void)requestLayout {
    [self setNeedsLayout];
    [self setIsLayoutRequested:TRUE];
    if (self.superview != nil) {
        if (!self.superview.isLayoutRequested) {
            [self.superview requestLayout];
        }
    }
}

- (void)onFinishInflate {
    
}

- (UIView *)findViewById:(NSString *)identifier {
    UIView *ret = nil;
    if (self.isViewGroup) {
        ret = [self findViewTraversal:identifier];
    } else if ([self.identifier isEqualToString:identifier]) {
        ret = self;
    }
    return ret;
}

@end
