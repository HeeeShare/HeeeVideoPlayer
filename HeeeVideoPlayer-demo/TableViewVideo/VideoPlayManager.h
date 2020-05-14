//
//  VideoPlayManager.h
//  HeeeVideoPlayer-demo
//
//  Created by Heee on 2020/3/5.
//  Copyright © 2020 Heee. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface VideoPlayManager : NSObject
+ (instancetype)shareInstance;

@property (nonatomic,copy) NSString *videoUrl;
@property (nonatomic,strong) UIImage *thumbnailImage;
@property (nonatomic,assign) CGFloat videoDuration;
@property (nonatomic,assign) BOOL isPlaying;
@property (nonatomic,assign) BOOL isPlayFinished;
@property (nonatomic,assign) BOOL pauseVideoByUser;
- (void)playVideoOnContainerView:(UIView *)view videoFrame:(CGRect)frame;
- (void)playVideo;
- (void)pauseVideo;
- (void)destroyVideoPlayer;

@end

NS_ASSUME_NONNULL_END
