//
//  IDLTextArea.h
//  iDroidLayout
//
//  Created by Tom Quist on 03.01.13.
//  Copyright (c) 2013 Tom Quist. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface IDLTextArea : UITextView {
    UIControlContentVerticalAlignment _contentVerticalAlignment;
}

@property (nonatomic, assign) UIControlContentVerticalAlignment contentVerticalAlignment;

@end
