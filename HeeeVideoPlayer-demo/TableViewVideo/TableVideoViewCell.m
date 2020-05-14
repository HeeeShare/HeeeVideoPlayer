//
//  TableVideoViewCell.m
//  HeeeVideoPlayer-demo
//
//  Created by Heee on 2020/3/6.
//  Copyright © 2020 Heee. All rights reserved.
//

#import "TableVideoViewCell.h"

@implementation TableVideoViewCell
- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        self.textLabel.textColor = [UIColor orangeColor];
        self.textLabel.font = [UIFont systemFontOfSize:20 weight:UIFontWeightBold];
        self.textLabel.text = @"点击播放视频";
        self.textLabel.textAlignment = NSTextAlignmentCenter;
    }
    
    return self;
}

@end
