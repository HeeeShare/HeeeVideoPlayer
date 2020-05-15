//
//  HeeeVideoControlView.m
//  HeeeVideoPlayer
//
//  Created by Heee on 2020/1/20.
//  Copyright © 2020 Heee. All rights reserved.
//

#define lineViewHeight 2
#define indicatorGap 8

#import "HeeeVideoControlView.h"
#import "HeeeBrightnessVolumeView.h"

@implementation HVCustomButton
- (void)setSelected:(BOOL)selected {
    [super setSelected:selected];
    
    if (selected) {
        [self setImage:[UIImage imageNamed:@"Heee_pause_btn"] forState:UIControlStateNormal];
        [self setImageEdgeInsets:UIEdgeInsetsMake(12, 12, 12, 12)];
    }else{
        [self setImage:[UIImage imageNamed:@"Heee_play_btn"] forState:UIControlStateNormal];
        [self setImageEdgeInsets:UIEdgeInsetsMake(12, 14, 12, 10)];
    }
}

@end

@interface HeeeVideoControlView()
@property (nonatomic,strong) UIView *progressBackView;//底部放进度条的view
@property (nonatomic,strong) UIView *playedLineView;//已播放的进度条
@property (nonatomic,strong) UIView *toPlayLineView;//未播放的进度条
@property (nonatomic,strong) UIView *bufferLineView;//缓冲进度条
@property (nonatomic,strong) UIView *indicatorBackView;
@property (nonatomic,strong) UIView *indicatorView;
@property (nonatomic,strong) UIPanGestureRecognizer *indicatorPanGes;
@property (nonatomic,strong) UIButton *fullScreenBtn;
@property (nonatomic,strong) UILabel *totalTimeLabel;//视频总时长
@property (nonatomic,strong) UILabel *playedTimeLabel;//视频已播放时长
@property (nonatomic,strong) HeeeBrightnessVolumeView *brightnessVolumeView;
@property (nonatomic,assign) CGFloat playRate;//播放时间比例
@property (nonatomic,assign) CGFloat panLocation;
@property (nonatomic,assign) CGFloat totalIndicatorWidth;
@property (nonatomic,strong) NSTimer *hideItemsTimer;//隐藏各个控件的计时器
@property (nonatomic,assign) BOOL firstLayoutFlag;
@property (nonatomic,strong) UIImageView *shadowImgV;
@property (nonatomic,strong) UIPanGestureRecognizer *volumeBrightGes;
@property (nonatomic,assign) CGFloat originalBrightnessValue;
@property (nonatomic,assign) CGPoint startPanPoint;

//隐藏控制控件后的底部小的进度显示
@property (nonatomic,strong) UIView *littleProgressBackView;
@property (nonatomic,strong) UIView *littlePlayedLineView;
@property (nonatomic,strong) UIView *littleToPlayLineView;
@property (nonatomic,strong) UIView *littleBufferLineView;

@end

@implementation HeeeVideoControlView
- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    if (!self.closeHideItems) {
        if (self.playBtn.alpha == 1.0) {
            [self p_hideTimerAction];
        }else{
            [self p_showItems];
            [self p_hideItems];
        }
    }
}

- (instancetype)init {
    self = [super init];
    if (self) {
        [self p_setupUI];
    }
    
    return self;
}

- (void)removeFromSuperview {
    [super removeFromSuperview];
    [self p_clearTimer];
    if (_hideItemsTimer) {
        [_hideItemsTimer invalidate];
        _hideItemsTimer = nil;
    }
    
    [self.brightnessVolumeView removeFromSuperview];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    [self p_setupFrame];
    
    if (self.frame.size.width > 0) {
        self.firstLayoutFlag = NO;
    }
}

- (void)setDuration:(CGFloat)duration {
    _duration = duration;
    self.totalTimeLabel.text = [self p_getTimeStr:duration];
}

- (void)setCurrentPlayTime:(CGFloat)currentPlayTime {
    _currentPlayTime = currentPlayTime;
    
    if (self.duration > 0 && currentPlayTime >=0 &&  currentPlayTime <= self.duration) {
        self.playRate = (float)currentPlayTime/self.duration;
        self.playedTimeLabel.text = [self p_getTimeStr:currentPlayTime];
        [self p_updatePlayRate];
    }
}

- (void)setIndicatorColor:(UIColor *)indicatorColor {
    _indicatorColor = indicatorColor;
    self.indicatorView.backgroundColor = indicatorColor;
}

- (void)setPlayedPartColor:(UIColor *)playedPartColor {
    _playedPartColor = playedPartColor;
    self.playedLineView.backgroundColor = playedPartColor;
    self.littlePlayedLineView.backgroundColor = playedPartColor;
}

- (void)setVideoBufferTime:(CGFloat)videoBufferTime {
    _videoBufferTime = videoBufferTime;
    if (self.duration <= 0) return;
    
    self.bufferLineView.frame = CGRectMake(self.playedLineView.frame.origin.x, self.playedLineView.frame.origin.y, self.totalIndicatorWidth*videoBufferTime/self.duration, self.playedLineView.frame.size.height);
    self.littleBufferLineView.frame = CGRectMake(0, 0, self.littleProgressBackView.bounds.size.width*videoBufferTime/self.duration, lineViewHeight);
}

- (void)setBrightnessVolumeControl:(BOOL)brightnessVolumeControl {
    _brightnessVolumeControl = brightnessVolumeControl;
    
    if (brightnessVolumeControl) {
        [self addGestureRecognizer:self.volumeBrightGes];
    }else{
        [self removeGestureRecognizer:self.volumeBrightGes];
    }
}

- (void)setShowLittleProgress:(BOOL)showLittleProgress {
    _showLittleProgress = showLittleProgress;
    self.littleProgressBackView.hidden = !showLittleProgress;
}

- (void)showItems {
    [self p_clearTimer];
    [self p_showItems];
}

- (void)hideItemsDelay:(BOOL)delay {
    if (delay) {
        [self p_hideItems];
    }else{
        [self p_hideTimerAction];
    }
}

- (void)fullScreen {
    [self p_fullScreenBtnClick];
}

#pragma mark - private action
- (void)p_setupUI {
    self.brightnessVolumeControl = YES;
    self.playedPartColor = [UIColor colorWithRed:0 green:200/255.0 blue:70/255.0 alpha:1.0];
    self.indicatorColor = [UIColor whiteColor];
    
    self.originalBrightnessValue = -1.0;
    self.firstLayoutFlag = YES;
    [self addSubview:self.littleProgressBackView];
    [self.littleProgressBackView addSubview:self.littleToPlayLineView];
    [self.littleProgressBackView addSubview:self.littleBufferLineView];
    [self.littleProgressBackView addSubview:self.littlePlayedLineView];
    [self addSubview:self.shadowImgV];
    [self addSubview:self.progressBackView];
    [self.progressBackView addSubview:self.totalTimeLabel];
    [self.progressBackView addSubview:self.playedTimeLabel];
    [self.progressBackView addSubview:self.toPlayLineView];
    [self.progressBackView addSubview:self.bufferLineView];
    [self.progressBackView addSubview:self.playedLineView];
    [self.progressBackView addSubview:self.indicatorBackView];
    [self.indicatorBackView addSubview:self.indicatorView];
    [self.progressBackView addSubview:self.fullScreenBtn];
    [self addSubview:self.playBtn];
    [self addSubview:self.brightnessVolumeView];
}

- (void)p_setupFrame {
    [UIView animateWithDuration:self.firstLayoutFlag?0:0.3 animations:^{
        self.littleProgressBackView.frame = CGRectMake(self.progressBarInsets.left, self.bounds.size.height - lineViewHeight, self.bounds.size.width - self.progressBarInsets.left - self.progressBarInsets.right, lineViewHeight);
        self.littleToPlayLineView.frame = self.littleProgressBackView.bounds;
        self.progressBackView.frame = CGRectMake(self.progressBarInsets.left, self.bounds.size.height - 40 - self.progressBarInsets.bottom, self.bounds.size.width - self.progressBarInsets.left - self.progressBarInsets.right, 40);
        self.playBtn.frame = CGRectMake((self.bounds.size.width - 60)/2, (self.bounds.size.height - 60)/2, 60, 60);
        self.fullScreenBtn.frame = CGRectMake(self.progressBackView.bounds.size.width - 40, 0, 40, 40);
        self.playedTimeLabel.frame = CGRectMake(8, 0, 50, 40);
        self.totalTimeLabel.frame = CGRectMake(self.fullScreenBtn.frame.origin.x - 50, 0, 50, 40);
        self.indicatorView.center = CGPointMake(self.indicatorBackView.bounds.size.width/2, self.indicatorBackView.bounds.size.height/2);
        [self p_updatePlayRate];
        self.toPlayLineView.frame = CGRectMake(self.playedLineView.frame.origin.x, self.playedLineView.frame.origin.y, self.totalIndicatorWidth, self.playedLineView.frame.size.height);
        [self setVideoBufferTime:self.videoBufferTime];
        self.shadowImgV.frame = CGRectMake(0, self.progressBackView.frame.origin.y - 20, self.bounds.size.width, self.bounds.size.height - (self.progressBackView.frame.origin.y - 20));
        self.brightnessVolumeView.center = CGPointMake(self.frame.size.width/2, self.brightnessVolumeView.frame.origin.y + self.brightnessVolumeView.frame.size.height/2);
    }];
}

- (void)p_updatePlayRate {
    self.totalIndicatorWidth = self.totalTimeLabel.frame.origin.x - CGRectGetMaxX(self.playedTimeLabel.frame) - 2*indicatorGap;
    self.playedLineView.frame = CGRectMake(CGRectGetMaxX(self.playedTimeLabel.frame) + indicatorGap, CGRectGetMidY(self.fullScreenBtn.frame) - lineViewHeight, self.totalIndicatorWidth*self.playRate, lineViewHeight);
    self.indicatorBackView.center = CGPointMake(CGRectGetMaxX(self.playedLineView.frame), CGRectGetMidY(self.playedLineView.frame));
    self.littlePlayedLineView.frame = CGRectMake(0, 0, self.littleProgressBackView.bounds.size.width*self.playRate, lineViewHeight);
}

- (void)p_playBtnClick {
    self.playBtn.selected = !self.playBtn.selected;
    
    if (self.playBtn.selected) {
        if (self.delegate || [self.delegate respondsToSelector:@selector(videoControlViewPlayVideo:)]) {
            [self.delegate videoControlViewPlayVideo:self];
        }
        [self p_hideItems];
    }else{
        [self p_clearTimer];
        if (self.delegate || [self.delegate respondsToSelector:@selector(videoControlViewPauseVideo:)]) {
            [self.delegate videoControlViewPauseVideo:self];
        }
    }
}

- (void)p_fullScreenBtnClick {
    if (self.delegate && [self.delegate respondsToSelector:@selector(videoControlViewClickFullScreen:)]) {
        [self.delegate videoControlViewClickFullScreen:self];
    }
    
    [self p_hideItems];
}

- (void)p_clearTimer {
    if (_hideItemsTimer) {
        [_hideItemsTimer invalidate];
        _hideItemsTimer = nil;
    }
}

- (void)p_handleIndicatorGes:(UIPanGestureRecognizer *)panGes {
    if (self.duration<=0) return;
    
    if (panGes.state == UIGestureRecognizerStateBegan) {
        self.panLocation = self.indicatorBackView.center.x;
        self.panFlag = YES;
    }
    
    CGPoint translatedPoint = [panGes translationInView:self.indicatorBackView];
    self.panLocation+=translatedPoint.x;
    self.playRate = (self.panLocation - self.playedLineView.frame.origin.x)/self.totalIndicatorWidth;
    if (self.playRate<=0) {
        self.playRate = 0;
    }else if (self.playRate>=1.0) {
        self.playRate = 1.0;
    }
    self.currentPlayTime = self.playRate*self.duration;
    
    if (self.delegate || [self.delegate respondsToSelector:@selector(videoControlView:seekToTime:)]) {
        [self.delegate videoControlView:self seekToTime:self.currentPlayTime];
    }
    
    [self p_clearTimer];
    [self p_showItems];
    if (panGes.state == UIGestureRecognizerStateEnded) {
        self.panFlag = NO;
        [self p_hideItems];
    }
    
    [panGes setTranslation:CGPointMake(0, 0) inView:self.indicatorBackView];
}

- (void)p_handleVolumeBrightGes:(UIPanGestureRecognizer *)panGes {
    CGPoint translatedPoint = [panGes translationInView:self];
    CGPoint locationPoint = [panGes locationInView:self];
    if (panGes.state==UIGestureRecognizerStateBegan) {
        self.startPanPoint = locationPoint;
        self.originalBrightnessValue = -1.0;
    }
    
    CGFloat offsetX = fabs(self.startPanPoint.x - locationPoint.x);
    CGFloat offsetY = fabs(self.startPanPoint.y - locationPoint.y);
    //竖向有效移动10像素，且竖直夹角小于45度的才开始调节
    if (offsetY >= 10 && self.originalBrightnessValue==-1.0) {
        if (offsetY >= offsetX) {
            self.brightnessVolumeView.controlMode = self.startPanPoint.x>self.bounds.size.width/2;
            self.originalBrightnessValue = self.brightnessVolumeView.value;
        }else{
            panGes.enabled = NO;
            panGes.enabled = YES;
        }
    }
    
    if (self.originalBrightnessValue>=0) {
        self.brightnessVolumeView.value = self.originalBrightnessValue - translatedPoint.y/self.frame.size.height;
    }
}

- (void)p_showItems {
    if (self.delegate && [self.delegate respondsToSelector:@selector(videoControlViewWillShow:)]) {
        [self.delegate videoControlViewWillShow:self];
    }
    
    [UIView animateWithDuration:0.3 animations:^{
        for (UIView *subView in self.subviews) {
            if (subView==self.brightnessVolumeView) {
                continue;
            }else if (subView==self.littleProgressBackView) {
                subView.alpha = 0;
            }else{
                subView.alpha = 1.0;
            }
        }
    }];
}

- (void)p_hideItems {
    if (self.canHideItemFlag) {
        [self p_clearTimer];
        _hideItemsTimer = [NSTimer scheduledTimerWithTimeInterval:3 target:self selector:@selector(p_hideTimerAction) userInfo:nil repeats:NO];
        [[NSRunLoop currentRunLoop] addTimer:_hideItemsTimer forMode:NSRunLoopCommonModes];
    }
}

- (void)p_hideTimerAction {
    if (self.delegate && [self.delegate respondsToSelector:@selector(videoControlViewWillHide:)]) {
        [self.delegate videoControlViewWillHide:self];
    }
    
    [UIView animateWithDuration:0.3 animations:^{
        for (UIView *subView in self.subviews) {
            if (subView==self.brightnessVolumeView) {
                continue;
            }else if (subView==self.littleProgressBackView){
                subView.alpha = 1.0;
            }else{
                subView.alpha = 0;
            }
        }
    }];
}

- (NSString *)p_getTimeStr:(CGFloat)time {
    int min,sec;
    min = (int)ceil(time)/60;
    sec = (int)floor(time)%60;
    if (time - min*60 - sec >= 0.5) {
        sec+=1;
    }
    
    return [NSString stringWithFormat:@"%02d:%02d",min,sec];
}

#pragma mark - lazy
- (HVCustomButton *)playBtn {
    if (!_playBtn) {
        _playBtn = [[HVCustomButton alloc] init];
        _playBtn.backgroundColor = [UIColor colorWithWhite:0 alpha:0.2];
        _playBtn.layer.masksToBounds = YES;
        _playBtn.layer.cornerRadius = 30;
        _playBtn.selected = NO;
        _playBtn.adjustsImageWhenHighlighted = NO;
        [_playBtn addTarget:self action:@selector(p_playBtnClick) forControlEvents:UIControlEventTouchUpInside];
    }
    
    return _playBtn;
}

- (UIView *)progressBackView {
    if (!_progressBackView) {
        _progressBackView = [[UIView alloc] init];
    }
    
    return _progressBackView;
}

- (UIView *)playedLineView {
    if (!_playedLineView) {
        _playedLineView = [[UIView alloc] init];
    }
    
    return _playedLineView;
}

- (UIView *)toPlayLineView {
    if (!_toPlayLineView) {
        _toPlayLineView = [[UIView alloc] init];
        _toPlayLineView.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.3];
    }
    
    return _toPlayLineView;
}

- (UIView *)bufferLineView {
    if (!_bufferLineView) {
        _bufferLineView = [[UIView alloc] init];
        _bufferLineView.backgroundColor = [UIColor colorWithWhite:1.0 alpha:1.0];
    }
    
    return _bufferLineView;
}

- (UIView *)indicatorBackView {
    if (!_indicatorBackView) {
        _indicatorBackView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 40, 40)];
        [_indicatorBackView addGestureRecognizer:self.indicatorPanGes];
    }
    
    return _indicatorBackView;
}

- (UIPanGestureRecognizer *)indicatorPanGes {
    if (!_indicatorPanGes) {
        _indicatorPanGes = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(p_handleIndicatorGes:)];
        [_indicatorBackView addGestureRecognizer:_indicatorPanGes];
    }
    
    return _indicatorPanGes;
}

- (UIView *)indicatorView {
    if (!_indicatorView) {
        _indicatorView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 10, 10)];
        _indicatorView.layer.cornerRadius = 5;
    }
    
    return _indicatorView;
}

- (UIButton *)fullScreenBtn {
    if (!_fullScreenBtn) {
        _fullScreenBtn = [[UIButton alloc] init];
        _fullScreenBtn.adjustsImageWhenHighlighted = NO;
        [_fullScreenBtn setImage:[UIImage imageNamed:@"Heee_fullScreen"] forState:UIControlStateNormal];
        [_fullScreenBtn setImageEdgeInsets:UIEdgeInsetsMake(10, 10, 10, 10)];
        [_fullScreenBtn addTarget:self action:@selector(p_fullScreenBtnClick) forControlEvents:UIControlEventTouchUpInside];
    }
    
    return _fullScreenBtn;
}

- (UILabel *)totalTimeLabel {
    if (!_totalTimeLabel) {
        _totalTimeLabel = [[UILabel alloc] init];
        _totalTimeLabel.textAlignment = NSTextAlignmentCenter;
        _totalTimeLabel.text = @"00:00";
        _totalTimeLabel.textColor = [UIColor whiteColor];
        _totalTimeLabel.font = [UIFont fontWithName:@"Avenir Next" size:14];
    }
    
    return _totalTimeLabel;
}

- (UILabel *)playedTimeLabel {
    if (!_playedTimeLabel) {
        _playedTimeLabel = [[UILabel alloc] init];
        _playedTimeLabel.textAlignment = NSTextAlignmentCenter;
        _playedTimeLabel.text = @"00:00";
        _playedTimeLabel.textColor = [UIColor whiteColor];
        _playedTimeLabel.font = [UIFont fontWithName:@"Avenir Next" size:14];
    }
    
    return _playedTimeLabel;
}

- (UIImageView *)shadowImgV {
    if (!_shadowImgV) {
        _shadowImgV = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"Heee_bottom_shadow"]];
    }
    
    return _shadowImgV;
}

- (HeeeBrightnessVolumeView *)brightnessVolumeView {
    if (!_brightnessVolumeView) {
        _brightnessVolumeView = [[HeeeBrightnessVolumeView alloc] init];
    }
    
    return _brightnessVolumeView;
}

- (UIPanGestureRecognizer *)volumeBrightGes {
    if (!_volumeBrightGes) {
        _volumeBrightGes = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(p_handleVolumeBrightGes:)];
    }
    
    return _volumeBrightGes;
}

- (UIView *)littleProgressBackView {
    if (!_littleProgressBackView) {
        _littleProgressBackView = [[UIView alloc] init];
    }
    
    return _littleProgressBackView;
}

- (UIView *)littleToPlayLineView {
    if (!_littleToPlayLineView) {
        _littleToPlayLineView = [[UIView alloc] init];
        _littleToPlayLineView.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.3];
    }
    
    return _littleToPlayLineView;
}

- (UIView *)littlePlayedLineView {
    if (!_littlePlayedLineView) {
        _littlePlayedLineView = [[UIView alloc] init];
    }
    
    return _littlePlayedLineView;
}

- (UIView *)littleBufferLineView {
    if (!_littleBufferLineView) {
        _littleBufferLineView = [[UIView alloc] init];
        _littleBufferLineView.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.6];
    }
    
    return _littleBufferLineView;
}

@end
