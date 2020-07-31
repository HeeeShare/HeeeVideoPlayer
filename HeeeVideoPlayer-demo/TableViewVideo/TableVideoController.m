//
//  TableVideoController.m
//  HeeeVideoPlayer-demo
//
//  Created by Heee on 2020/3/6.
//  Copyright © 2020 Heee. All rights reserved.
//
#define topGap ([UIApplication sharedApplication].statusBarFrame.size.height + self.navigationController.navigationBar.bounds.size.height)

#import "TableVideoController.h"
#import "TableVideoViewCell.h"
#import "VideoPlayManager.h"

@interface TableVideoController ()<UITableViewDelegate,UITableViewDataSource>
@property (nonatomic,strong) UITableView *tableView;
@property (nonatomic, assign) CGRect videoFrame;
@property (nonatomic, assign) BOOL autoPauseVideo;

@end

@implementation TableVideoController

- (void)dealloc {
    [[VideoPlayManager shareInstance] destroyVideoPlayer];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"tableVideo";
    self.view.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:self.tableView];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if ([VideoPlayManager shareInstance].pauseVideoByUser) return;
    
    CGFloat videoCenterY = self.videoFrame.origin.y + self.videoFrame.size.height/2;
    if (self.videoFrame.size.height && !(videoCenterY >= scrollView.contentOffset.y && videoCenterY < (scrollView.contentOffset.y + scrollView.bounds.size.height))) {
        if ([VideoPlayManager shareInstance].isPlaying) {
            [[VideoPlayManager shareInstance] pauseVideo];
            self.autoPauseVideo = YES;
        }
    }else if(![VideoPlayManager shareInstance].isPlayFinished) {
        if (self.autoPauseVideo) {
            [[VideoPlayManager shareInstance] playVideo];
            [[VideoPlayManager shareInstance] hideControlView];
        }
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 210;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 15;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    TableVideoViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
    if (!cell) {
        cell = [[TableVideoViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"cell"];
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    TableVideoViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    
    self.autoPauseVideo = NO;
    self.videoFrame = cell.frame;
    [VideoPlayManager shareInstance].thumbnailImage = [UIImage imageNamed:@"VideoThumbnail.png"];
    [VideoPlayManager shareInstance].videoDuration = 100;
    [VideoPlayManager shareInstance].videoUrl = @"http://aliuwmp3.changba.com/userdata/video/45F6BD5E445E4C029C33DC5901307461.mp4";
    [[VideoPlayManager shareInstance] playVideoOnContainerView:tableView videoFrame:self.videoFrame];
    [[VideoPlayManager shareInstance] playVideo];
}

- (UITableView *)tableView {
    if (!_tableView) {
        _tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, topGap, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height - topGap) style:UITableViewStylePlain];
        _tableView.delegate = self;
        _tableView.dataSource = self;
        _tableView.contentInsetAdjustmentBehavior = NO;
        _tableView.estimatedRowHeight = 0;
        _tableView.estimatedSectionFooterHeight = 0;
        _tableView.estimatedSectionHeaderHeight = 0;
    }
    
    return _tableView;
}

@end
