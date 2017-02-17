//
//  WXVideoPlayer.h
//  WXVideoPlayerDemo
//
//  Created by Liuwx on 2017/2/15.
//  Copyright © 2017年 Liuwx. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
typedef NS_ENUM(NSInteger, WXVideoPlayerState) {
    
    WXVedioPlayerStateFailed,
    WXVideoPlayerStateBuffering,
    WXVideoPlayerStatePlaying,
    WXVideoPlayerStatePaused,
    WXVideoPlayerStateFinished,
    WXVideoPlayerStateStopped
    
};

typedef NS_ENUM(NSInteger, WXVideoPlayerEndAction) {
    WXVideoPlayerEndActionStop,
    WXVideoPlayerEndActionLoop,
    WXVideoPlayerEndActionDestroy
};

@interface WXVideoPlayer : NSObject
@property (nonatomic, assign, readonly) WXVideoPlayerState playerState;

/**
视频播放结束时,默认是WXVideoPlayerEndActionStop。
 */
@property (nonatomic, assign) WXVideoPlayerEndAction playerEndAction;

/**
将要播放的视频的名字
 */
@property (nonatomic, copy) NSString *videoName;

/**
 创建一个WXVideoPlayer对象
 
 @param videoURL        视频网址
 @param playerView      显示视频的视图.
 @param playerSuperView 显示视频的视图的父视图.
 @return                返回一个WXVideoPlayer对象
 */
+ (instancetype)playerWithVideoURL:(NSURL *)videoURL playerView:(UIView *)playerView playerSuperView:(UIView *)playerSuperView;

- (void)play;

- (void)pause;

- (void)resume;

- (void)destroyPlayer;
@end
