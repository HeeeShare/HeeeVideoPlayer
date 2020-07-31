//
//  VideoPlayManager.m
//  HeeeVideoPlayer-demo
//
//  Created by Heee on 2020/3/5.
//  Copyright © 2020 Heee. All rights reserved.
//

#import "VideoPlayManager.h"
#import "HeeeVideoPlayer.h"

@interface VideoPlayManager ()<HeeeVideoPlayerDelegate>
@property (nonatomic,strong) HeeeVideoPlayer *videoPlayer;
@property (nonatomic,strong) UIView *backView;
@property (nonatomic,assign) CGRect originalFrame;
@property (nonatomic,assign) BOOL fullScreenFlag;
@property (nonatomic,assign) CGFloat bottomSafeSize;

@end

@implementation VideoPlayManager
+ (instancetype)shareInstance {
    static VideoPlayManager *manager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[VideoPlayManager alloc] init];
        if (@available(iOS 11.0, *)) {
            manager.bottomSafeSize = [UIApplication sharedApplication].keyWindow.safeAreaInsets.bottom;
        }
    });
    
    return manager;
}

- (void)setVideoUrl:(NSString *)videoUrl {
    _videoUrl = videoUrl;
    self.videoPlayer.videoUrl = videoUrl;
}

- (void)setThumbnailImage:(UIImage *)thumbnailImage {
    _thumbnailImage = thumbnailImage;
    self.videoPlayer.thumbnailImage = thumbnailImage;
}

- (void)setVideoDuration:(CGFloat)videoDuration {
    _videoDuration = videoDuration;
    self.videoPlayer.videoDuration = videoDuration;
}

- (void)playVideoOnContainerView:(UIView *)view videoFrame:(CGRect)frame {
    [view addSubview:self.backView];
    [self.backView addSubview:self.videoPlayer];
    self.backView.frame = frame;
    self.videoPlayer.frame = self.backView.bounds;
    self.originalFrame = frame;
}

- (void)playVideo {
    [self.videoPlayer play];
    self.pauseVideoByUser = NO;
    self.isPlayFinished = NO;
}

- (void)pauseVideo {
    [self.videoPlayer pause];
}

- (void)hideControlView {
    [self.videoPlayer hideControlView:NO];
}

- (void)destroyVideoPlayer {
    if (_videoPlayer) {
        [self pauseVideo];
        [self.videoPlayer removeFromSuperview];
        self.videoPlayer = nil;
    }
}

- (void)p_close {
    [self.videoPlayer fullScreen];
}

- (BOOL)isPlaying {
    return self.videoPlayer.playerState==HeeePlayerStatePlaying;
}

#pragma mark - HeeeVideoPlayerDelegate
- (void)videoPlayerClickFullScreenBtn:(HeeeVideoPlayer *)player {
    self.fullScreenFlag = !self.fullScreenFlag;
    
    UIWindow *window = [UIApplication sharedApplication].keyWindow;
    CGRect frame = [self.backView.superview convertRect:self.backView.frame toView:window];
    if (self.fullScreenFlag) {
        [window addSubview:self.videoPlayer];
        self.videoPlayer.frame = frame;
        
        [UIView animateWithDuration:0.3 animations:^{
            if (self.videoPlayer.thumbnailImage.size.width >= self.videoPlayer.thumbnailImage.size.height) {
                self.videoPlayer.transform = CGAffineTransformMakeRotation(-M_PI_2);
                self.videoPlayer.frame = CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height);
                player.progressBarInsets = UIEdgeInsetsMake(0, self.bottomSafeSize + 20, self.bottomSafeSize/2, self.bottomSafeSize + 20);
            }else{
                player.progressBarInsets = UIEdgeInsetsMake(0, 0, self.bottomSafeSize, 0);
                self.videoPlayer.frame = [UIScreen mainScreen].bounds;
            }
        } completion:^(BOOL finished) {
            [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationNone];
        }];
    }else{
        [UIView animateWithDuration:0.3 animations:^{
            player.progressBarInsets = UIEdgeInsetsZero;
            self.videoPlayer.transform = CGAffineTransformIdentity;
            self.videoPlayer.frame = frame;
        } completion:^(BOOL finished) {
            self.videoPlayer.frame = self.backView.bounds;
            [self.backView addSubview:self.videoPlayer];
            [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationNone];
        }];
    }
}

- (void)videoPlayerPause:(HeeeVideoPlayer *)player {
    self.pauseVideoByUser = YES;
}

- (void)videoPlayerPlay:(HeeeVideoPlayer *)player {
    self.pauseVideoByUser = NO;
    self.isPlayFinished = NO;
}

- (void)videoPlayerFinished:(HeeeVideoPlayer *)player {
    self.isPlayFinished = YES;
}

#pragma mark - lazy
- (HeeeVideoPlayer *)videoPlayer {
    if (!_videoPlayer) {
        _videoPlayer = [[HeeeVideoPlayer alloc] init];
        _videoPlayer.autoGetVideoDuration = YES;
        _videoPlayer.brightnessVolumeControl = NO;
        _videoPlayer.delegate = self;
    }
    
    return _videoPlayer;
}

-(UIView *)backView {
    if (!_backView) {
        _backView = [[UIView alloc] init];
        _backView.backgroundColor = [UIColor whiteColor];
    }
    
    return _backView;
}

@end
