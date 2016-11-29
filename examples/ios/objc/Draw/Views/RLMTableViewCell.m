//
//  RLMTableViewCell.m
//  RealmExamples
//
//  Created by Tim Oliver on 11/28/16.
//  Copyright © 2016 Realm. All rights reserved.
//

#import "RLMTableViewCell.h"

@implementation RLMTableViewCell

- (void)setFrame:(CGRect)frame {
    CGFloat width = 550.0f;
    frame.size.width = width;
    frame.origin.x = (self.superview.frame.size.width - width) * 0.5f;
    [super setFrame:frame];
    
    self.textLabel.frame =  CGRectMake(30, 0, 150.0f, 54.0f);
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    self.textLabel.frame =  CGRectMake(30, 0, 150.0f, 54.0f);
}

@end
