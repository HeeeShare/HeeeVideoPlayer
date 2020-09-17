//
//  HeeeVideoPlayer.m
//  HeeeVideoPlayer
//
//  Created by Heee on 2020/1/20.
//  Copyright © 2020 Heee. All rights reserved.
//

#import "HeeeVideoPlayer.h"
#import "HeeeVideoControlView.h"
#import "HeeeLoadingView.h"
#import <AVFoundation/AVFoundation.h>
#import <AVKit/AVKit.h>

@interface HeeeVideoPlayer ()<HeeeVideoControlViewDelegate>
@property (nonatomic,strong) id timeObserver;
@property (nonatomic,strong) AVPlayer *player;
@property (nonatomic,strong) AVPlayerItem *playerItem;
@property (nonatomic,assign) HeeePlayerState playerState;
@property (nonatomic,strong) HeeeLoadingView *loadingView;//加载动画
@property (nonatomic,strong) UIImageView *placeholderImgV;//第一贞展位图
@property (nonatomic,assign) CGFloat currentPlayTime;//播放到的时长
@property (nonatomic,strong) HeeeVideoControlView *videoControlView;
@property (nonatomic,assign) CGFloat lastPlayTime;//上次播放时间
@property (nonatomic,strong) NSTimer *indicatiorTimer;//缓冲视频动画计时器
@property (nonatomic,assign) CGRect originalFrame;
@property (nonatomic,assign) BOOL videoPauseByEvents;//播放被事件打断的
@property (nonatomic,assign) BOOL isLocalVideo;//是否是本地视频
@property (nonatomic,strong) dispatch_queue_t getDurationQueue;
@property (nonatomic,assign) CGFloat seekRate;//首次播放需要开始的进度比例

@end

@implementation HeeeVideoPlayer
+ (Class)layerClass {
    return [AVPlayerLayer class];
}
- (AVPlayer*)player {
    return [(AVPlayerLayer *)[self layer] player];
}
- (void)setPlayer:(AVPlayer *)player {
    [(AVPlayerLayer *)[self layer] setPlayer:player];
}

- (void)dealloc {
    [self notifyOthersOnDeactivation];
    [self p_removeObserver];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    self.playerItem = nil;
    NSLog(@"HeeeVideoPlayer -> dealloc");
}

- (instancetype)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    if (self) {
        [self p_init];
    }
    return self;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        [self p_init];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self p_init];
    }
    return self;
}

- (void)setFrame:(CGRect)frame {
    [super setFrame:frame];
    
    self.placeholderImgV.frame = self.bounds;
    if (frame.size.width>0 && [UIDevice currentDevice].orientation==UIInterfaceOrientationPortrait) {
        self.originalFrame = frame;
    }
}

- (void)didMoveToSuperview {
    [super didMoveToSuperview];
    
    self.videoControlView.duration = self.videoDuration;
    [self p_handleIndicatiorTimer];
    if (_autoGetVideoDuration) {
        [self p_getVideoDuration];
    }
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    [UIView animateWithDuration:0.3 animations:^{
        self.loadingView.center = CGPointMake(self.bounds.size.width/2, self.bounds.size.height/2);
        self.videoControlView.frame = self.bounds;
    }];
}

- (void)setVideoUrl:(NSString *)videoUrl {
    _videoUrl = videoUrl;
    
    //网络视频与本地视频的判断条件
    if (![videoUrl containsString:@"http"]) {
        self.isLocalVideo = YES;
    }
    
    [self pause];
    [self p_removeObserver];
    self.player = nil;
    self.playerItem = nil;
    self.currentPlayTime = 0;
    self.videoControlView.currentPlayTime = self.currentPlayTime;
    self.videoControlView.videoBufferTime = 0;
    [self p_addObserver];
}

- (void)setPlayerState:(HeeePlayerState)playerState {
    _playerState = playerState;
    self.videoControlView.canHideItemFlag = playerState==HeeePlayerStatePlaying;
}

- (void)setPlayedPartColor:(UIColor *)playedPartColor {
    _playedPartColor = playedPartColor;
    self.videoControlView.playedPartColor = playedPartColor;
}

- (void)setIndicatorColor:(UIColor *)indicatorColor {
    _indicatorColor = indicatorColor;
    self.videoControlView.indicatorColor = indicatorColor;
}

- (void)setMutePlay:(BOOL)mutePlay {
    _mutePlay = mutePlay;
    
    if (mutePlay) {
        //混响，静音不中断其他app声音
        [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryAmbient error:nil];
    }else{
        //静音有声音
        [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:nil];
    }
}

- (void)setItemArray:(NSArray<UIView *> *)itemArray {
    _itemArray = itemArray;
    for (UIView *view in itemArray) {
        [self.videoControlView addSubview:view];
    }
}

- (void)setBrightnessVolumeControl:(BOOL)brightnessVolumeControl {
    _brightnessVolumeControl = brightnessVolumeControl;
    self.videoControlView.brightnessVolumeControl = brightnessVolumeControl;
}

- (void)setShowLittleProgress:(BOOL)showLittleProgress {
    _showLittleProgress = showLittleProgress;
    self.videoControlView.showLittleProgress = showLittleProgress;
}

- (void)setThumbnailImage:(UIImage *)thumbnailImage {
    _thumbnailImage = thumbnailImage;
    self.placeholderImgV.alpha = 1.0;
    self.placeholderImgV.image = thumbnailImage;
}

- (void)setProgressBarInsets:(UIEdgeInsets)progressBarInsets {
    _progressBarInsets = progressBarInsets;
    self.videoControlView.progressBarInsets = progressBarInsets;
}

- (void)setThumbnailImageContentMode:(UIViewContentMode)thumbnailImageContentMode {
    _thumbnailImageContentMode = thumbnailImageContentMode;
    self.placeholderImgV.contentMode = thumbnailImageContentMode;
}

- (void)setHiddenControlView:(BOOL)hiddenControlView {
    _hiddenControlView = hiddenControlView;
    self.videoControlView.hidden = hiddenControlView;
    self.loadingView.hidden = hiddenControlView;
}

- (void)play {
    if (self.playerState!=HeeePlayerStatePlaying) [self p_play];
}

- (void)pause {
    if (self.playerState!=HeeePlayerStatePause) [self p_pause];
}

- (void)seekToTime:(NSTimeInterval)time {
    if (self.playerState!=HeeePlayerStatePlaying) {
        self.currentPlayTime = time;
        self.videoControlView.currentPlayTime = time;
        [self.player seekToTime:CMTimeMakeWithSeconds(time,30) toleranceBefore:CMTimeMake(1, 30) toleranceAfter:CMTimeMake(1, 30)];
    }
}

- (void)hideControlView:(BOOL)delay {
    [self.videoControlView hideItemsDelay:delay];
}

- (void)fullScreen {
    [self.videoControlView fullScreen];
}

- (void)notifyOthersOnDeactivation {
    if (self.needNotifyOthersOnDeactivation) {
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            [[AVAudioSession sharedInstance] setActive:NO withOptions:AVAudioSessionSetActiveOptionNotifyOthersOnDeactivation error:nil];
        });
    }
}

#pragma mark - observer&notify
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context {
    if ([keyPath isEqualToString:@"status"]) {
        if (self.playerState==HeeePlayerStatePlaying && self.playerItem.status==AVPlayerItemStatusReadyToPlay) {
            [self play];
        }else if (self.playerItem.status==AVPlayerItemStatusFailed){
            self.playerState = HeeePlayerStateError;
            if (self.delegate && [self.delegate respondsToSelector:@selector(videoPlayerError:)]) {
                [self.delegate videoPlayerError:self];
            }
        }
    }else if ([keyPath isEqualToString:@"loadedTimeRanges"]) {
        CGFloat sec = CMTimeGetSeconds(self.playerItem.duration);
        if (!isnan(sec) && self.videoDuration != sec) {
            self.videoDuration = sec;
            self.videoControlView.duration = self.videoDuration;
            [self.player seekToTime:CMTimeMakeWithSeconds(self.videoControlView.duration*self.seekRate,30) toleranceBefore:CMTimeMake(1, 30) toleranceAfter:CMTimeMake(1, 30)];
        }
        
        NSArray *array = self.player.currentItem.loadedTimeRanges;
        // 本次缓冲的时间范围
        CMTimeRange timeRange = [array.firstObject CMTimeRangeValue];
        // 缓冲总长度
        NSTimeInterval totalBuffer = CMTimeGetSeconds(timeRange.start) + CMTimeGetSeconds(timeRange.duration);
        self.videoControlView.videoBufferTime = totalBuffer;
        
        // 计算缓冲百分比例
        NSTimeInterval scale = 0.0;
        if (self.videoDuration > 0.0) {
            scale = totalBuffer/self.videoDuration;
        }
        NSLog(@"视频总时长:%f, 已缓冲时间:%f, 已缓冲进度:%f", self.videoDuration, totalBuffer, scale);
    }
}

- (void)audioSessionWasInterrupted:(NSNotification *)notification {
    if (AVAudioSessionInterruptionTypeBegan == [notification.userInfo[AVAudioSessionInterruptionTypeKey] intValue]) {
        [self p_pauseByEventsStart];
        NSLog(@"视频被打断");
    }else if (AVAudioSessionInterruptionTypeEnded == [notification.userInfo[AVAudioSessionInterruptionTypeKey] intValue]) {
        [self p_playByEventsEnd];
        NSLog(@"视频打断结束");
    }
}

- (void)appDidEnterBackground {
    [self p_pauseByEventsStart];
    [self notifyOthersOnDeactivation];
}

- (void)appDidBecomeActive {
    [self p_playByEventsEnd];
}

- (void)routeChange:(NSNotification *)notification{
    NSDictionary *dic = notification.userInfo;
    int changeReason= [dic [AVAudioSessionRouteChangeReasonKey] intValue];
    //等于AVAudioSessionRouteChangeReasonOldDeviceUnavailable表示旧输出不可用
    if (changeReason == AVAudioSessionRouteChangeReasonOldDeviceUnavailable) {
        AVAudioSessionRouteDescription *routeDescription=dic[AVAudioSessionRouteChangePreviousRouteKey];
        AVAudioSessionPortDescription *portDescription= [routeDescription.outputs firstObject];
        //原设备为耳机则暂停
        if ([portDescription.portType isEqualToString:@"Headphones"]) {
            [self pause];
        }
    }
}

#pragma mark - private
- (void)p_init {
    self.backgroundColor = [UIColor blackColor];
    [self addSubview:self.placeholderImgV];
    [self addSubview:self.loadingView];
    [self addSubview:self.videoControlView];
    
    self.loadingView.frame = CGRectMake(30, 30, 60, 60);
    [self addSubview:self.loadingView];
    self.thumbnailImageContentMode = UIViewContentModeScaleAspectFit;
    self.brightnessVolumeControl = YES;
    self.showLittleProgress = NO;
    self.needNotifyOthersOnDeactivation = YES;
}

- (void)p_play {
    [self p_removeObserver];
    if (!self.player.currentItem) {
        if (self.isLocalVideo) {
            self.playerItem = [AVPlayerItem playerItemWithURL:[NSURL fileURLWithPath:self.videoUrl]];
        }else{
            self.playerItem = [AVPlayerItem playerItemWithURL:[NSURL URLWithString:self.videoUrl]];
        }
        
        self.player = [AVPlayer playerWithPlayerItem:self.playerItem];
    }
    
    [self p_addObserver];
    self.loadingView.alpha = 0;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        self.loadingView.alpha = 1.0;
    });
    
    if (self.playerState == HeeePlayerStateError) {
        [self p_reloadPlayerToPlay];
    }else{
        [self p_playAction];
    }
}

- (void)p_pause {
    [self p_removeObserver];
    [self.player pause];
    self.videoControlView.playBtn.selected = NO;
    [self.videoControlView showItems];
    if (self.playerState == HeeePlayerStatePlaying) {
        self.playerState = HeeePlayerStatePause;
    }
}

- (void)stop {
    [self pause];
    [self seekToTime:0];
    self.videoControlView.videoBufferTime = 0;
    [self p_handlePlayFinished];
}

- (void)p_playAction {
    if (self.playerState==HeeePlayerStatePlayFinished) {
        [self.player seekToTime:CMTimeMakeWithSeconds(self.videoControlView.currentPlayTime,30) toleranceBefore:CMTimeMake(1, 30) toleranceAfter:CMTimeMake(1, 30)];
    }
    
    if (self.playerState==HeeePlayerStateDefault && self.videoControlView.duration) {
        self.seekRate = self.videoControlView.currentPlayTime/self.videoControlView.duration;
    }
    
    self.player.volume = !self.mutePlay;
    [self setMutePlay:self.mutePlay];
    [self.player play];
    self.playerState = HeeePlayerStatePlaying;
    self.videoControlView.playBtn.selected = YES;
    [self.videoControlView hideItemsDelay:YES];
}

- (void)p_handleIndicatiorTimer {
    if (self.superview) {
        [self p_clearTimer];
        _indicatiorTimer = [NSTimer timerWithTimeInterval:0.2 target:self selector:@selector(p_indicatiorTimerAction) userInfo:nil repeats:YES];
        [[NSRunLoop currentRunLoop] addTimer:_indicatiorTimer forMode:NSRunLoopCommonModes];
    }else{
        [self p_clearTimer];
    }
}

- (void)p_clearTimer {
    if (_indicatiorTimer) {
        [_indicatiorTimer invalidate];
        _indicatiorTimer = nil;
    }
}

//处理加载中动画的timer事件
- (void)p_indicatiorTimerAction {
    if (self.playerState==HeeePlayerStatePlaying || self.playerState==HeeePlayerStateError) {
        [self p_updateLoadingViewHidden:fabs(self.currentPlayTime-self.lastPlayTime)>2/30.0];
        self.lastPlayTime = self.currentPlayTime;
    }else{
        [self p_updateLoadingViewHidden:YES];
    }
}

- (void)p_updateLoadingViewHidden:(BOOL)hidden {
    if (!self.hiddenControlView) {
        self.loadingView.hidden = hidden;
        if (!self.videoControlView.playBtn.selected || self.videoControlView.panFlag) {
            self.loadingView.hidden = YES;
        }
    }
}

//重新加载item并播放视频
- (void)p_reloadPlayerToPlay {
    if (self.playerState==HeeePlayerStatePlaying || self.playerState==HeeePlayerStateError) {
        [self.player pause];
        [self p_removeObserver];
        
        self.playerItem = [AVPlayerItem playerItemWithURL:[NSURL URLWithString:_videoUrl]];
        [self.player replaceCurrentItemWithPlayerItem:self.playerItem];
        [self.player seekToTime:CMTimeMakeWithSeconds(self.currentPlayTime, 30) toleranceBefore:CMTimeMake(1, 30) toleranceAfter:CMTimeMake(1, 30)];
        [self p_addObserver];
        [self.player play];
        self.playerState = HeeePlayerStatePlaying;
    }
}

- (void)p_addObserver {
    __weak __typeof(self) weakSelf = self;
    self.timeObserver = [self.player addPeriodicTimeObserverForInterval:CMTimeMake(1.0, 30) queue:dispatch_get_main_queue() usingBlock:^(CMTime time) {
        [weakSelf p_updateLoadingViewHidden:YES];
        
        if (CMTimeGetSeconds(time) <= weakSelf.seekRate*weakSelf.videoDuration) {
            return;
        }
        
        weakSelf.seekRate = 0;
        weakSelf.currentPlayTime = CMTimeGetSeconds(time);
        if (weakSelf.currentPlayTime>=0.1) {
            [UIView animateWithDuration:0.3 animations:^{
                weakSelf.placeholderImgV.alpha = 0;
            }];
        }
        
        if (weakSelf.delegate && [weakSelf.delegate respondsToSelector:@selector(videoPlayer:playingAtTime:)]) {
            [weakSelf.delegate videoPlayer:weakSelf playingAtTime:weakSelf.currentPlayTime];
        }
        
        //播放完毕
        if (weakSelf.videoDuration > 0 &&weakSelf.currentPlayTime >= weakSelf.videoDuration) {
            [weakSelf p_handlePlayFinished];
            if (weakSelf.delegate && [weakSelf.delegate respondsToSelector:@selector(videoPlayerFinished:)]) {
                [weakSelf.delegate videoPlayerFinished:weakSelf];
            }
        }
        
        if (weakSelf.playerState == HeeePlayerStatePlaying && !weakSelf.videoControlView.panFlag) {
            weakSelf.videoControlView.currentPlayTime = weakSelf.currentPlayTime;
        }
    }];
    
    [self.player.currentItem addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:nil];
    [self.player.currentItem addObserver:self forKeyPath:@"loadedTimeRanges" options:NSKeyValueObservingOptionNew context:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appDidEnterBackground) name:UIApplicationDidEnterBackgroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appDidBecomeActive) name:UIApplicationDidBecomeActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(audioSessionWasInterrupted:) name:AVAudioSessionInterruptionNotification object:[AVAudioSession sharedInstance]];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(routeChange:) name:AVAudioSessionRouteChangeNotification object:nil];
}

- (void)p_removeObserver {
    if (self.timeObserver) {
        [self.player removeTimeObserver:self.timeObserver];
        self.timeObserver = nil;
        [self.player.currentItem cancelPendingSeeks];
        [self.player.currentItem.asset cancelLoading];
        [self.player.currentItem removeObserver:self forKeyPath:@"status"];
        [self.player.currentItem removeObserver:self forKeyPath:@"loadedTimeRanges"];
    }
}

- (void)p_handlePlayFinished {
    self.playerState = HeeePlayerStatePlayFinished;
    self.videoControlView.playBtn.selected = NO;
    [self.videoControlView showItems];
    self.currentPlayTime = 0;
    self.placeholderImgV.alpha = 1.0;
    
    if (!self.videoControlView.panFlag) {
        self.videoControlView.currentPlayTime = self.currentPlayTime;
    }
}

//获取视频长度
- (void)p_getVideoDuration {
    self.getDurationQueue = dispatch_queue_create("com.Heee.getVideoDuration", DISPATCH_QUEUE_CONCURRENT);
    dispatch_async(self.getDurationQueue, ^{
        NSURL*videoUrl = [NSURL URLWithString:self.videoUrl];
        if (self.isLocalVideo) {
            videoUrl = [NSURL fileURLWithPath:self.videoUrl];
        }
        
        AVURLAsset *avUrlAsset = [AVURLAsset URLAssetWithURL:videoUrl options:nil];
        CMTime time = [avUrlAsset duration];
        self.videoDuration = CMTimeGetSeconds(time);
        if (isnan(self.videoDuration)) {
            self.videoDuration = 0;
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            self.videoControlView.duration = self.videoDuration;
        });
        
        NSLog(@"视频总时长:%f",self.videoDuration);
    });
}

- (void)p_pauseByEventsStart {
    if (self.playerState==HeeePlayerStatePlaying) {
        [self p_pause];
        self.videoPauseByEvents = YES;
    }
}

- (void)p_playByEventsEnd {
    if (self.videoPauseByEvents) {
        [self p_play];
        [self.videoControlView hideItemsDelay:YES];
    }
}

#pragma mark - HeeeVideoControlViewDelegate
- (void)videoControlViewPlayVideo:(HeeeVideoControlView *)progressBar {
    [self p_play];
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(videoPlayerPlay:)]) {
        [self.delegate videoPlayerPlay:self];
    }
}

- (void)videoControlViewPauseVideo:(HeeeVideoControlView *)progressBar {
    [self p_pause];
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(videoPlayerPause:)]) {
        [self.delegate videoPlayerPause:self];
    }
}

- (void)videoControlView:(HeeeVideoControlView *)progressBar seekToTime:(CGFloat)time {
    self.currentPlayTime = time;
    [self.player seekToTime:CMTimeMakeWithSeconds(time, 30) toleranceBefore:kCMTimeZero
             toleranceAfter:kCMTimeZero];
}

- (void)videoControlViewClickFullScreen:(HeeeVideoControlView *)progressBar {
    if (self.delegate && [self.delegate respondsToSelector:@selector(videoPlayerClickFullScreenBtn:)]) {
        [self.delegate videoPlayerClickFullScreenBtn:self];
    }
}

- (void)videoControlViewWillShow:(HeeeVideoControlView *)progressBar {
    if (self.delegate && [self.delegate respondsToSelector:@selector(videoPlayerWillShowControlView:)]) {
        [self.delegate videoPlayerWillShowControlView:self];
    }
}

- (void)videoControlViewWillHide:(HeeeVideoControlView *)progressBar {
    if (self.delegate && [self.delegate respondsToSelector:@selector(videoPlayerWillHideControlView:)]) {
        [self.delegate videoPlayerWillHideControlView:self];
    }
}

#pragma mark - lazy
- (HeeeLoadingView *)loadingView {
    if (!_loadingView) {
        _loadingView = [[HeeeLoadingView alloc] init];
        _loadingView.hidden = YES;
        _loadingView.alpha = 0.8;
    }
    
    return _loadingView;
}

- (HeeeVideoControlView *)videoControlView {
    if (!_videoControlView) {
        _videoControlView = [[HeeeVideoControlView alloc] init];
        _videoControlView.delegate = self;
    }
    
    return _videoControlView;
}

- (UIImageView *)placeholderImgV {
    if (!_placeholderImgV) {
        _placeholderImgV = [[UIImageView alloc] init];
        _placeholderImgV.clipsToBounds = YES;
    }
    
    return _placeholderImgV;
}

@end
