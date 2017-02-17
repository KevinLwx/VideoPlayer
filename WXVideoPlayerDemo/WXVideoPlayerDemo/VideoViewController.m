//
//  VedioViewController.m
//  WXVideoPlayerDemo
//
//  Created by Liuwx on 2017/2/15.
//  Copyright © 2017年 Liuwx. All rights reserved.
//

#import "VideoViewController.h"
#import "WXVideoPlayer.h"
@interface VideoViewController ()
@property (nonatomic, strong) WXVideoPlayer *videoPlayer;
@end

@implementation VideoViewController

- (void)viewDidLoad {
    
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor whiteColor];
    
    [self showVideoPlayer];
}

- (void)showVideoPlayer {
    
    UIView *playerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.width)];
    playerView.center = self.view.center;
    [self.view addSubview:playerView];
    _videoPlayer = [WXVideoPlayer playerWithVideoURL:_videoURL playerView:playerView playerSuperView:playerView.superview];
    _videoPlayer.videoName = @"视频名字";
    _videoPlayer.playerEndAction = WXVideoPlayerEndActionStop;
    [_videoPlayer play];
}

- (void)viewDidDisappear:(BOOL)animated {
    
    [super viewWillDisappear:animated];
    
    [_videoPlayer destroyPlayer];
}


@end
