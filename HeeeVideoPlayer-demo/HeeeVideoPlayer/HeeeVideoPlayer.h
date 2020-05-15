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
@property (nonatomic,copy) NSString *videoUrl;//视频地址
@property (nonatomic,assign) CGFloat videoDuration;//视频的时长，建议主动设置，否则自动获取。即使设置了也会在加载过程中获取，以校准时长。
@property (nonatomic,strong) UIColor *playedPartColor;//已播放进度条颜色
@property (nonatomic,strong) UIColor *indicatorColor;//小圆点的颜色
@property (nonatomic,copy) NSArray <UIView *>*itemArray;//需要添加到控制层上的自定义组件
@property (nonatomic,assign) BOOL mutePlay;//是否要静音播放，默认NO
@property (nonatomic,assign) BOOL brightnessVolumeControl;//是否需要亮度与音量的手势控制，默认YES
@property (nonatomic,assign) BOOL showLittleProgress;//当隐藏其他控件时，是否显示底部的小进度条，默认NO
@property (nonatomic,assign) UIEdgeInsets progressBarInsets;//进度条部分的位置偏移
@property (nonatomic,strong) UIImage *thumbnailImage;//设置视频占位图
@property (nonatomic,assign) UIViewContentMode thumbnailImageContentMode;//占位图的填充模式，默认UIViewContentModeScaleAspectFill
@property (nonatomic,assign,readonly) HeeePlayerState playerState;//播放器状态
@property (nonatomic,weak) id<HeeeVideoPlayerDelegate> delegate;
- (void)play;
- (void)pause;
- (void)seekToTime:(NSTimeInterval)time;
- (void)fullScreen;
- (void)hideControlView:(BOOL)delay;//delay:是否需要延迟3秒后自动隐藏
- (void)notifyOthersOnDeactivation;//主动通知其他app完成音频占用

@end

NS_ASSUME_NONNULL_END
