//
//  HeeeVideoPlayer.h
//  HeeeVideoPlayer
//
//  Created by Heee on 2020/1/20.
//  Copyright © 2020 Heee. All rights reserved.
//

#import <UIKit/UIKit.h>
@class HeeeVideoPlayer;

NS_ASSUME_NONNULL_BEGIN

typedef enum : NSUInteger {
    HeeePlayerStateDefault,
    HeeePlayerStatePlaying,
    HeeePlayerStatePause,
    HeeePlayerStatePlayFinished,
    HeeePlayerStateError,
} HeeePlayerState;

@protocol HeeeVideoPlayerDelegate <NSObject>
@optional
- (void)videoPlayerPlay:(HeeeVideoPlayer *)player;
- (void)videoPlayerPause:(HeeeVideoPlayer *)player;
- (void)videoPlayerFinished:(HeeeVideoPlayer *)player;
- (void)videoPlayerError:(HeeeVideoPlayer *)player;
- (void)videoPlayerClickFullScreenBtn:(HeeeVideoPlayer *)player;
- (void)videoPlayer:(HeeeVideoPlayer *)player playingAtTime:(CGFloat)time;
- (void)videoPlayerWillShowControlView:(HeeeVideoPlayer *)player;
- (void)videoPlayerWillHideControlView:(HeeeVideoPlayer *)player;

@end

@interface HeeeVideoPlayer : UIView
@property (nonatomic,copy) NSString *videoUrl;//视频地址(网络或本地)
@property (nonatomic,assign) CGFloat videoDuration;//视频的时长，可以不设置。视频播放中会获取校准时长。
@property (nonatomic,assign) BOOL autoGetVideoDuration;//是否主动获取视频时长，yes表示即使没播放视频也会获取视频
@property (nonatomic,strong) UIColor *playedPartColor;//已播放进度条颜色
@property (nonatomic,strong) UIColor *indicatorColor;//小圆点的颜色
@property (nonatomic,copy) NSArray <UIView *>*itemArray;//需要添加到控制层上的自定义组件
@property (nonatomic,assign) BOOL mutePlay;//是否要静音播放，默认NO
@property (nonatomic,assign) BOOL brightnessVolumeControl;//是否需要亮度与音量的手势控制，默认YES
@property (nonatomic,assign) BOOL showLittleProgress;//当隐藏其他控件时，是否显示底部的小进度条，默认NO
@property (nonatomic,assign) UIEdgeInsets progressBarInsets;//进度条部分的位置偏移
@property (nonatomic,strong) UIImage *thumbnailImage;//设置视频占位图
@property (nonatomic,assign) UIViewContentMode thumbnailImageContentMode;//占位图的填充模式，默认UIViewContentModeScaleAspectFit
///是否需要主动通知其他app播放完成，默认是。(注意：如果同时开启了多个播放器，主动通知会将所有的视频暂停，因此可以将此属性设置成NO，然后自己控制通知时机)。
@property (nonatomic,assign) BOOL needNotifyOthersOnDeactivation;
@property (nonatomic,assign) BOOL hiddenControlView;//是否隐藏控制层
@property (nonatomic,assign,readonly) HeeePlayerState playerState;//播放器状态
@property (nonatomic,weak) id<HeeeVideoPlayerDelegate> delegate;

- (void)play;
- (void)pause;
- (void)stop;//停止播放，并回到初始状态
- (void)seekToTime:(NSTimeInterval)time;
- (void)fullScreen;
- (void)hideControlView:(BOOL)delay;//delay:是否需要延迟3秒后自动隐藏
- (void)notifyOthersOnDeactivation;//主动通知其他app完成音频占用

@end

NS_ASSUME_NONNULL_END
