//
//  HeeeBrightnessVolumeView.m
//  HeeeVideoPlayer
//
//  Created by Heee on 2020/2/7.
//  Copyright © 2020 Heee. All rights reserved.
//

#define totalHeight 20
#define imageSize 26
#define imageGap 6
#define progressHeight 8
#define progressWidth 140

#import "HeeeBrightnessVolumeView.h"
#import <MediaPlayer/MediaPlayer.h>

@interface HeeeBrightnessVolumeView ()
@property (nonatomic,strong) UIImageView *imgv;
@property (nonatomic,strong) UIView *progressBackView;
@property (nonatomic,strong) UIVisualEffectView *whiteProgressView;
@property (nonatomic,strong) UIVisualEffectView *grayProgressView;
@property (nonatomic,assign) CGFloat brightnessValue;
@property (nonatomic,assign) CGFloat volumeValue;
@property (nonatomic,strong) NSTimer *hideTimer;
@property (nonatomic,strong) UISlider *volumeSlider;

@end

@implementation HeeeBrightnessVolumeView
- (instancetype)init {
    self = [super init];
    if (self) {
        [self p_setupInterface];
        [self p_setupFrame];
    }
    return self;
}

- (void)removeFromSuperview {
    [super removeFromSuperview];
    [_hideTimer invalidate];
    _hideTimer = nil;
}

- (void)setValue:(CGFloat)value {
    _value = value;
    
    if (self.controlMode) {
        _volumeValue = value;
        [self.volumeSlider setValue:value animated:NO];
        [self.volumeSlider sendActionsForControlEvents:UIControlEventTouchUpInside];
    }else{
        if (value < 0) value = 0;
        if (value > 1) value = 1;
        _brightnessValue = value;
        [self p_show];
        [[UIScreen mainScreen] setBrightness:value];
        [UIView animateWithDuration:0.3 animations:^{
            self.whiteProgressView.frame = CGRectMake(0, 0, progressWidth*value, progressHeight);
            self.grayProgressView.frame = CGRectMake(CGRectGetMaxX(self.whiteProgressView.frame), 0, progressWidth*(1-value), progressHeight);
        }];
    }
}

- (void)setControlMode:(BOOL)controlMode {
    _controlMode = controlMode;
    
    if (controlMode) {
        _value = self.volumeSlider.value;
    }else{
        _value = [UIScreen mainScreen].brightness;
        self.whiteProgressView.frame = CGRectMake(0, 0, progressWidth*_value, progressHeight);
        self.grayProgressView.frame = CGRectMake(CGRectGetMaxX(self.whiteProgressView.frame), 0, progressWidth*(1-_value), progressHeight);
    }
}

- (void)p_show {
    if (_hideTimer) {
        [_hideTimer invalidate];
        _hideTimer = nil;
    }
    _hideTimer = [[NSTimer alloc] initWithFireDate:[NSDate dateWithTimeIntervalSinceNow:1.0] interval:0.5 target:self selector:@selector(p_hide) userInfo:nil repeats:NO];
    [[NSRunLoop currentRunLoop] addTimer:_hideTimer forMode:NSRunLoopCommonModes];
    
    if (self.frame.origin.y != 12) {
        [self.superview bringSubviewToFront:self];
        [UIView animateWithDuration:0.3 animations:^{
            self.frame = CGRectMake(self.frame.origin.x, 12, self.frame.size.width, self.frame.size.height);
            self.alpha = 1.0;
        }];
    }
}

- (void)p_hide {
    [UIView animateWithDuration:0.3 animations:^{
        self.frame = CGRectMake(self.frame.origin.x, 0, progressWidth + imageGap + imageSize, totalHeight);
        self.alpha = 0;
    }];
}

- (void)p_setupInterface {
    self.alpha = 0;
    self.layer.cornerRadius = totalHeight/2;
    self.layer.shadowColor = [UIColor blackColor].CGColor;
    self.layer.shadowRadius = 6;
    self.layer.shadowOpacity = 0.3;
    self.layer.shadowOffset = CGSizeZero;
    [self p_getVolumeSlider];
    [self addSubview:self.imgv];
    [self addSubview:self.progressBackView];
    [self.progressBackView addSubview:self.whiteProgressView];
    [self.progressBackView addSubview:self.grayProgressView];
}

- (void)p_setupFrame {
    self.frame = CGRectMake(0, 0, progressWidth + imageSize + imageGap, totalHeight);
    self.imgv.frame = CGRectMake(0, (totalHeight - imageSize)/2, imageSize, imageSize);
    self.progressBackView.frame = CGRectMake(CGRectGetMaxX(self.imgv.frame) + imageGap, (totalHeight - progressHeight)/2, progressWidth, progressHeight);
    _brightnessValue = [UIScreen mainScreen].brightness;
    self.whiteProgressView.frame = CGRectMake(0, 0, progressWidth*_brightnessValue, progressHeight);
    self.grayProgressView.frame = CGRectMake(CGRectGetMaxX(self.whiteProgressView.frame), 0, progressWidth*(1-_brightnessValue), progressHeight);
        
    
}

- (void)p_getVolumeSlider {
    MPVolumeView *volumeView = [[MPVolumeView alloc] init];
    for(UIView*view in[volumeView subviews]) {
        if ([view.class.description isEqualToString:@"MPVolumeSlider"]){
            self.volumeSlider = (UISlider*)view;
            break;
        }
    }
}

#pragma mark - lazy
- (UIImageView *)imgv {
    if (!_imgv) {
        _imgv = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"Heee_brightness"]];
    }
    
    return _imgv;
}

- (UIView *)progressBackView {
    if (!_progressBackView) {
        _progressBackView = [[UIView alloc] init];
        _progressBackView.layer.cornerRadius = progressHeight/2;
        _progressBackView.layer.masksToBounds = YES;
    }
    
    return _progressBackView;
}

- (UIVisualEffectView *)whiteProgressView {
    if (!_whiteProgressView) {
        _whiteProgressView = [[UIVisualEffectView alloc] initWithEffect:[UIBlurEffect effectWithStyle:UIBlurEffectStyleExtraLight]];
    }
    
    return _whiteProgressView;
}

- (UIVisualEffectView *)grayProgressView {
    if (!_grayProgressView) {
        _grayProgressView = [[UIVisualEffectView alloc] initWithEffect:[UIBlurEffect effectWithStyle:UIBlurEffectStyleDark]];
    }
    
    return _grayProgressView;
}

@end
