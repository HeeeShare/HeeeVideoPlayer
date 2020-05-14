//
//  HeeeBrightnessVolumeView.h
//  HeeeVideoPlayer
//
//  Created by Heee on 2020/2/7.
//  Copyright © 2020 Heee. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface HeeeBrightnessVolumeView : UIView
@property (nonatomic,assign) CGFloat value;
@property (nonatomic,assign) BOOL controlMode;//0：亮度控制，1：音量控制

@end

NS_ASSUME_NONNULL_END
