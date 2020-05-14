//
//  HeeeLoadingView.h
//  HeeeVideoPlayer
//
//  Created by Heee on 2020/2/3.
//  Copyright © 2020 Heee. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface HeeeLoadingView : UIView
@property (nonatomic,assign) NSTimeInterval timeout;//超时时间，默认5秒
@property (nonatomic,assign) CGFloat lineWidth;//线宽，默认1
@property (nonatomic,copy) void (^timeoutBlock) (void);

@end

NS_ASSUME_NONNULL_END
