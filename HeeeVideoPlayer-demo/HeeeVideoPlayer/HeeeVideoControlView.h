//
//  HeeeVideoControlView.h
//  HeeeVideoPlayer
//
//  Created by Heee on 2020/1/20.
//  Copyright © 2020 Heee. All rights reserved.
//

#import <UIKit/UIKit.h>
@class HeeeVideoControlView;

NS_ASSUME_NONNULL_BEGIN

@protocol HeeeVideoControlViewDelegate <NSObject>
- (void)videoControlViewPlayVideo:(HeeeVideoControlView *)progressBar;
- (void)videoControlViewPauseVideo:(HeeeVideoControlView *)progressBar;
- (void)videoControlView:(HeeeVideoControlView *)progressBar seekToTime:(CGFloat)time;
- (void)videoControlViewClickFullScreen:(HeeeVideoControlView *)progressBar;
- (void)videoControlViewWillShow:(HeeeVideoControlView *)progressBar;
- (void)videoControlViewWillHide:(HeeeVideoControlView *)progressBar;

@end

@interface HVCustomButton : UIButton

@end

@interface HeeeVideoControlView : UIView
@property (nonatomic,strong) HVCustomButton *playBtn;//播放暂停按钮
@property (nonatomic,strong) UIColor *playedPartColor;//已经播放部分的颜色
@property (nonatomic,strong) UIColor *indicatorColor;//小圆点的颜色
@property (nonatomic,strong,readonly) UIPanGestureRecognizer *indicatorPanGes;
@property (nonatomic,assign) CGFloat duration;//总时长
@property (nonatomic,assign) CGFloat currentPlayTime;//当前播放的时间
@property (nonatomic,assign) CGFloat videoBufferTime;//当前视频缓冲时间
@property (nonatomic,assign) CGFloat progressBottomGap;//进度条控件底部间隙
@property (nonatomic,assign) CGFloat progressSideGap;//进度条控件左右边距
@property (nonatomic,assign) BOOL panFlag;//正在拖动进度条标志
@property (nonatomic,assign) BOOL canHideItemFlag;//可以自动隐藏控件的标志
@property (nonatomic,assign) BOOL brightnessVolumeControl;
@property (nonatomic,assign) BOOL showLittleProgress;
@property (nonatomic,assign) BOOL closeHideItems;
@property (nonatomic,weak) id <HeeeVideoControlViewDelegate> delegate;
- (void)showItems;
- (void)hideItemsDelay:(BOOL)delay;//delay是否需要延迟3秒后自动隐藏
- (void)fullScreen;

@end

NS_ASSUME_NONNULL_END
