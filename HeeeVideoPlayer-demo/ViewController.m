//
//  ViewController.m
//  HeeeVideoPlayer-demo
//
//  Created by Heee on 2020/2/8.
//  Copyright © 2020 Heee. All rights reserved.
//

#import "ViewController.h"
#import "SingleVideoController.h"
#import "TableVideoController.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"demo";
    self.view.backgroundColor = [UIColor lightGrayColor];
    
    UIButton *singleVideoBtn = [[UIButton alloc] initWithFrame:CGRectMake(100, 120, 140, 50)];
    singleVideoBtn.backgroundColor = [UIColor orangeColor];
    [singleVideoBtn setTitle:@"singleVideo->" forState:UIControlStateNormal];
    [self.view addSubview:singleVideoBtn];
    [singleVideoBtn addTarget:self action:@selector(pushToSingleVideo) forControlEvents:UIControlEventTouchUpInside];
    
    UIButton *tableVideoBtn = [[UIButton alloc] initWithFrame:CGRectMake(100, 200, 140, 50)];
    tableVideoBtn.backgroundColor = [UIColor orangeColor];
    [tableVideoBtn setTitle:@"tableVideo->" forState:UIControlStateNormal];
    [self.view addSubview:tableVideoBtn];
    [tableVideoBtn addTarget:self action:@selector(pushToTableVideo) forControlEvents:UIControlEventTouchUpInside];
}

- (void)pushToSingleVideo {
    [self.navigationController pushViewController:[SingleVideoController new] animated:YES];
}

- (void)pushToTableVideo {
    [self.navigationController pushViewController:[TableVideoController new] animated:YES];
}

@end
