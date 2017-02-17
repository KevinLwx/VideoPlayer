//
//  ViewController.m
//  WXVideoPlayerDemo
//
//  Created by Liuwx on 2017/2/15.
//  Copyright © 2017年 Liuwx. All rights reserved.
//

#import "ViewController.h"
#import "VideoViewController.h"
@interface ViewController ()
@property (nonatomic, strong) UIButton *locationBtn;
@property (nonatomic, strong) UIButton *netBtn;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    [self initLoctionBtn];
    [self initNetBtn];
    
    
}

- (void)initLoctionBtn {
    self.locationBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.locationBtn setTitle:@"videoLoaction" forState:UIControlStateNormal];
    self.locationBtn.center = self.view.center;
    [self.locationBtn setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
    [self.locationBtn addTarget:self action:@selector(locationBtnAction:) forControlEvents:UIControlEventTouchUpInside];
    [self.locationBtn sizeToFit];
    [self.view addSubview:self.locationBtn];
}

- (void)initNetBtn{
    self.netBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.netBtn setTitle:@"videoNet" forState:UIControlStateNormal];
    self.netBtn.center = CGPointMake(self.view.center.x, self.view.center.y - 100);
    [self.netBtn setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
    [self.netBtn addTarget:self action:@selector(netBtnAction:) forControlEvents:UIControlEventTouchUpInside];
    [self.netBtn sizeToFit];
    [self.view addSubview:self.netBtn];
}
//播放本地视频
- (void)locationBtnAction:(UIButton *)sender {
    
    
    
    VideoViewController *videoVC = [[VideoViewController alloc] init];
    videoVC.videoURL = [[NSBundle mainBundle] URLForResource:@"赵雷 - 成都" withExtension:@"mp4"];
       
    
    [self.navigationController pushViewController:videoVC animated:NO];
}
//播放网络视频
- (void)netBtnAction:(UIButton *)sender {
        
    VideoViewController *videoVC = [[VideoViewController alloc] init];
    
    videoVC.videoURL = [NSURL URLWithString:@"http://baobab.wdjcdn.com/1442142801331138639111.mp4"];

    [self.navigationController pushViewController:videoVC animated:NO];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
