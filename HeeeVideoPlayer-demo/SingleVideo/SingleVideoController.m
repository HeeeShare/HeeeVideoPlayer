//
//  SingleVideoController.m
//  HeeeVideoPlayer-demo
//
//  Created by Heee on 2020/3/6.
//  Copyright © 2020 Heee. All rights reserved.
//

#define topGap ([UIApplication sharedApplication].statusBarFrame.size.height + self.navigationController.navigationBar.bounds.size.height)

#import "SingleVideoController.h"
#import "HeeeVideoPlayer.h"

@interface SingleVideoController ()<HeeeVideoPlayerDelegate>
@property (nonatomic,assign) CGRect originalFrame;
@property (nonatomic,assign) BOOL fullFlag;

@end

@implementation SingleVideoController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"singleVideo";
    self.view.backgroundColor = [UIColor whiteColor];
    self.originalFrame = CGRectMake(0, topGap, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.width*9/16.0);
    
    HeeeVideoPlayer *videoPlayer = [[HeeeVideoPlayer alloc] initWithFrame:self.originalFrame];
    videoPlayer.videoDuration = 272;
    videoPlayer.thumbnailImage = [UIImage imageNamed:@"VideoThumbnail.png"];
    videoPlayer.delegate = self;
    videoPlayer.videoUrl = @"http://aliuwmp3.changba.com/userdata/video/45F6BD5E445E4C029C33DC5901307461.mp4";
    [self.view addSubview:videoPlayer];
}

#pragma mark - HeeeVideoPlayerDelegate
- (void)videoPlayerClickFullScreenBtn:(HeeeVideoPlayer *)player {
    [self handlePlayer:player rotateStatusBar:NO];
}

/*说明：
    1. 这里把视频旋转、frame改变、进度条边距设置等操作留给开发者，
        给了个简单例子，给你更多的操作空间。
    2. 工具里面的所有动画时间都是0.3s，因此你旋转的动画也应该是这个时间。
        当然，你可以到里面修改成你想要的时间。
    3. 下面的例子rotate参数表示你是否想要旋转状态栏，或者仅仅是旋转视频本身。
 */
- (void)handlePlayer:(HeeeVideoPlayer *)player rotateStatusBar:(BOOL)rotate {
    if (rotate) {
        if ([UIDevice currentDevice].orientation == UIInterfaceOrientationPortrait) {
            [self p_changeOrientation:UIInterfaceOrientationLandscapeLeft];
            [UIView animateWithDuration:0.3 animations:^{
                player.progressBottomGap = 34;
                player.progressSideGap = 34;
                player.frame = CGRectMake(0, 32, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height - 32);
            }];
        }else{
            [self p_changeOrientation:UIInterfaceOrientationPortrait];
            [UIView animateWithDuration:0.3 animations:^{
                player.progressBottomGap = 0;
                player.progressSideGap = 0;
                player.frame = self.originalFrame;
            }];
        }
    }else{
        self.fullFlag = !self.fullFlag;
        
        if (self.fullFlag) {
            [[UIApplication sharedApplication].keyWindow addSubview:player];
            [UIView animateWithDuration:0.3 animations:^{
                player.progressBottomGap = 20;
                player.progressSideGap = 34;
                player.transform = CGAffineTransformMakeRotation(-M_PI_2);
                player.frame = [UIScreen mainScreen].bounds;
            }];
        }else{
            [self.view addSubview:player];
            [UIView animateWithDuration:0.3 animations:^{
                player.progressBottomGap = 0;
                player.progressSideGap = 0;
                player.transform = CGAffineTransformIdentity;
                player.frame = self.originalFrame;
            }];
        }
    }
}

//旋转屏幕
- (void)p_changeOrientation:(UIInterfaceOrientation)toOrientation {
    if ([[UIDevice currentDevice] respondsToSelector:@selector(setOrientation:)]) {
        SEL selector = NSSelectorFromString(@"setOrientation:");
        NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:[UIDevice instanceMethodSignatureForSelector:selector]];
        [invocation setSelector:selector];
        [invocation setTarget:[UIDevice currentDevice]];
        [invocation setArgument:&toOrientation atIndex:2];
        [invocation invoke];
    }
}

@end
