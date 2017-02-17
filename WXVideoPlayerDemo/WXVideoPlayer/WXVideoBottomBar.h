//
//  WXVideoBottomBar.h
//  WXVideoPlayerDemo
//
//  Created by Liuwx on 2017/2/15.
//  Copyright © 2017年 Liuwx. All rights reserved.
//

#import <UIKit/UIKit.h>
@protocol WXVideoBottomBarDelegate <NSObject>

- (void)videoBottomBarDidClickPlayPauseBtn;
- (void)videoBottomBarDidClickChangeScreenBtn;
- (void)videoBottomBarDidTapSlider:(UISlider *)slider withTap:(UITapGestureRecognizer *)tap;
- (void)videoBottomBarChangingSlider:(UISlider *)slider;
- (void)videoBottomBarDidEndChangeSlider:(UISlider *)slider;

@end
@interface WXVideoBottomBar : UIView
@property (nonatomic, weak) id<WXVideoBottomBarDelegate> delegate;

@property (nonatomic, strong) UIButton       *playPauseBtn;
@property (nonatomic, strong) UIButton       *changeScreenBtn;

@property (nonatomic, strong) UILabel        *currentTimeLabel;
@property (nonatomic, strong) UILabel        *totalTimeLabel;

@property (nonatomic, strong) UISlider       *videoProgressSlider;
@property (nonatomic, strong) UIProgressView *videoCacheProgress;

+ (instancetype)videoBottomBar;


@end
