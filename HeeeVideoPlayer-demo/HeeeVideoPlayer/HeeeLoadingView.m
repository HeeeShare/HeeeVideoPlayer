//
//  HeeeLoadingView.m
//  HeeeVideoPlayer
//
//  Created by Heee on 2020/2/3.
//  Copyright © 2020 Heee. All rights reserved.
//

#import "HeeeLoadingView.h"

@interface HeeeLoadingView ()
@property (nonatomic,strong) NSTimer *timeoutTimer;

@end

@implementation HeeeLoadingView
- (instancetype)init {
    self = [super init];
    if (self) {
        [self p_init];
    }
    return self;
}

- (void)removeFromSuperview {
    [super removeFromSuperview];
    [self p_clearTimer];
}

- (void)p_clearTimer {
    if (_timeoutTimer) {
        [_timeoutTimer invalidate];
        _timeoutTimer = nil;
    }
}

- (void)p_init {
    _timeout = 5;
    _lineWidth = 1.0;
    [self rotateAction];
    self.userInteractionEnabled = NO;
    self.backgroundColor = [UIColor clearColor];
}

- (void)setHidden:(BOOL)hidden {
    [super setHidden:hidden];
    
    if (hidden) {
        [self p_clearTimer];
    }else if(!_timeoutTimer){
        _timeoutTimer = [[NSTimer alloc] initWithFireDate:[NSDate dateWithTimeIntervalSinceNow:_timeout] interval:_timeout target:self selector:@selector(timeoutTimerAction) userInfo:nil repeats:YES];
        [[NSRunLoop currentRunLoop] addTimer:_timeoutTimer forMode:NSRunLoopCommonModes];
    }
}

- (void)timeoutTimerAction {
    if (_timeoutBlock) {
        _timeoutBlock();
    }
}

- (void)drawRect:(CGRect)rect {
    [[UIColor whiteColor] set];
    UIBezierPath *path = [UIBezierPath bezierPath];
    [path moveToPoint:CGPointMake(rect.size.width/2, _lineWidth)];
    [path addArcWithCenter:CGPointMake(rect.size.width/2, rect.size.width/2) radius:rect.size.width/2 - _lineWidth startAngle:M_PI_2*3 endAngle:M_PI_2*2.5 clockwise:YES];
    path.lineWidth = _lineWidth;
    [path stroke];
}

//旋转动画
- (void)rotateAction {
    CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"transform.rotation.z"];
    animation.fromValue = [NSNumber numberWithFloat:0.f];
    animation.toValue = [NSNumber numberWithFloat:M_PI];
    animation.duration = 1;
    animation.removedOnCompletion = NO;
    animation.fillMode = kCAFillModeForwards;
    animation.repeatCount = MAXFLOAT;
    animation.cumulative = YES;
    [self.layer addAnimation:animation forKey:@"rotationAnimate"];
}

@end
