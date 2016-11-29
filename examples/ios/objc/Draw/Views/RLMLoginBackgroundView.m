//
//  RLMLoginBackgroundView.m
//  RealmExamples
//
//  Created by Tim Oliver on 11/28/16.
//  Copyright © 2016 Realm. All rights reserved.
//

#import "RLMLoginBackgroundView.h"
#import "RLMRealmLogoView.h"

@interface RLMLoginBackgroundView ()

@property (nonatomic, strong) RLMRealmLogoView *logoView;
@property (nonatomic, strong) UIVisualEffectView *visualEffectView;

@end

@implementation RLMLoginBackgroundView

- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        _logoView = [[RLMRealmLogoView alloc] init];
        _logoView.backgroundColor = [UIColor whiteColor];
        _visualEffectView = [[UIVisualEffectView alloc] initWithEffect:[UIBlurEffect effectWithStyle:UIBlurEffectStyleLight]];
    }

    return self;
}

- (void)didMoveToSuperview
{
    [super didMoveToSuperview];
    
    self.backgroundColor = [UIColor whiteColor];
    [self addSubview:self.logoView];
    [self addSubview:self.visualEffectView];
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    CGRect bounds = self.bounds;
    
    // Logo view
    CGFloat minimumSize = MIN(bounds.size.width, bounds.size.height);
    minimumSize -= 100.0f;
    CGRect frame = CGRectMake(0, 0, minimumSize, minimumSize);
    self.logoView.frame = frame;
    self.logoView.center = self.center;
    [self.logoView setNeedsDisplay];
    
    // Blue View
    self.visualEffectView.frame = bounds;
}

@end
