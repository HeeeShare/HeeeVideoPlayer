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
@property (nonatomic,strong) HeeeVideoPlayer *videoPlayView;
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
    self.videoPlayView.videoUrl = videoUrl;
}

- (void)setThumbnailImage:(UIImage *)thumbnailImage {
    _thumbnailImage = thumbnailImage;
    self.videoPlayView.thumbnailImage = thumbnailImage;
}

- (void)setVideoDuration:(CGFloat)videoDuration {
    _videoDuration = videoDuration;
    self.videoPlayView.videoDuration = videoDuration;
}

- (void)playVideoOnContainerView:(UIView *)view videoFrame:(CGRect)frame {
    [view addSubview:self.backView];
    [self.backView addSubview:self.videoPlayView];
    self.backView.frame = frame;
    self.videoPlayView.frame = self.backView.bounds;
    self.originalFrame = frame;
}

- (void)playVideo {
    [self.videoPlayView play];
    self.pauseVideoByUser = NO;
    self.isPlayFinished = NO;
}

- (void)pauseVideo {
    [self.videoPlayView pause];
}

- (void)destroyVideoPlayer {
    if (_videoPlayView) {
        [self pauseVideo];
        [self.videoPlayView removeFromSuperview];
        self.videoPlayView = nil;
    }
}

- (void)p_close {
    [self.videoPlayView fullScreen];
}

- (BOOL)isPlaying {
    return self.videoPlayView.playerState==HeeePlayerStatePlaying;
}

#pragma mark - HeeeVideoPlayerDelegate
- (void)videoPlayerClickFullScreenBtn:(HeeeVideoPlayer *)player {
    self.fullScreenFlag = !self.fullScreenFlag;
    
    UIWindow *window = [UIApplication sharedApplication].keyWindow;
    CGRect frame = [self.backView.superview convertRect:self.backView.frame toView:window];
    if (self.fullScreenFlag) {
        [window addSubview:self.videoPlayView];
        self.videoPlayView.frame = frame;
        
        [UIView animateWithDuration:0.3 animations:^{
            if (self.videoPlayView.thumbnailImage.size.width >= self.videoPlayView.thumbnailImage.size.height) {
                self.videoPlayView.transform = CGAffineTransformMakeRotation(-M_PI_2);
                self.videoPlayView.frame = CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height);
                player.progressBarInsets = UIEdgeInsetsMake(0, self.bottomSafeSize + 20, self.bottomSafeSize/2, self.bottomSafeSize + 20);
            }else{
                player.progressBarInsets = UIEdgeInsetsMake(0, 0, self.bottomSafeSize, 0);
                self.videoPlayView.frame = [UIScreen mainScreen].bounds;
            }
        } completion:^(BOOL finished) {
            [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationNone];
        }];
    }else{
        [UIView animateWithDuration:0.3 animations:^{
            player.progressBarInsets = UIEdgeInsetsZero;
            self.videoPlayView.transform = CGAffineTransformIdentity;
            self.videoPlayView.frame = frame;
        } completion:^(BOOL finished) {
            self.videoPlayView.frame = self.backView.bounds;
            [self.backView addSubview:self.videoPlayView];
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
- (HeeeVideoPlayer *)videoPlayView {
    if (!_videoPlayView) {
        _videoPlayView = [[HeeeVideoPlayer alloc] init];
        _videoPlayView.brightnessVolumeControl = NO;
        _videoPlayView.delegate = self;
    }
    
    return _videoPlayView;
}

-(UIView *)backView {
    if (!_backView) {
        _backView = [[UIView alloc] init];
        _backView.backgroundColor = [UIColor whiteColor];
    }
    
    return _backView;
}

@end
