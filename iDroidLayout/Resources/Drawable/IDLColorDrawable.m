//
//  IDLColorDrawable.m
//  iDroidLayout
//
//  Created by Tom Quist on 17.12.12.
//  Copyright (c) 2012 Tom Quist. All rights reserved.
//

#import "IDLColorDrawable.h"
#import "IDLDrawable+IDL_Internal.h"
#import "TBXML+IDL.h"
#import "IDLResourceManager.h"
#import "UIColor+IDL_ColorParser.h"

@interface IDLColorDrawableConstantState ()

@property (nonatomic, strong) UIColor *color;

- (id)initWithState:(IDLColorDrawableConstantState *)state;

@end

@interface IDLColorDrawable ()

@property (nonatomic, strong) IDLColorDrawableConstantState *internalConstantState;

@end

@implementation IDLColorDrawableConstantState


- (id)initWithState:(IDLColorDrawableConstantState *)state {
    self = [super init];
    if (self) {
        if (state != nil) {
            self.color = state.color;
        } else {
            self.color = [UIColor clearColor];
        }
    }
    return self;
}

@end

@implementation IDLColorDrawable


- (id)initWithState:(IDLColorDrawableConstantState *)state {
    self = [super init];
    if (self) {
        IDLColorDrawableConstantState *s = [[IDLColorDrawableConstantState alloc] initWithState:state];
        self.internalConstantState = s;
    }
    return self;
}

- (id)initWithColor:(UIColor *)color {
    self = [super init];
    if (self) {
        IDLColorDrawableConstantState *state = [[IDLColorDrawableConstantState alloc] init];
        self.internalConstantState = state;
        self.internalConstantState.color = color;
    }
    return self;
}

- (id)init {
    return [self initWithState:nil];
}

- (void)drawInContext:(CGContextRef)context {
    UIGraphicsPushContext(context);
    [self.internalConstantState.color set];
    CGContextFillRect(context, self.bounds);
    UIGraphicsPopContext();
    OUTLINE_RECT(context, self.bounds);
}

- (void)inflateWithElement:(TBXMLElement *)element {
    [super inflateWithElement:element];
    NSMutableDictionary *attrs = [TBXML attributesFromXMLElement:element reuseDictionary:nil];
    NSString *colorString = [attrs objectForKey:@"color"];
    if (colorString != nil) {
        UIColor *color = [[IDLResourceManager currentResourceManager] colorForIdentifier:colorString];
        if (color == nil) {
            color = [UIColor colorFromIDLColorString:colorString];
        }
        self.internalConstantState.color = color;
    }
}

- (IDLDrawableConstantState *)constantState {
    return self.internalConstantState;
}

- (UIColor *)color {
    return self.internalConstantState.color;
}

@end
