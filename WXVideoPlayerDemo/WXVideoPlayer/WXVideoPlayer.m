//
//  WXVideoPlayer.m
//  WXVideoPlayerDemo
//
//  Created by Liuwx on 2017/2/15.
//  Copyright © 2017年 Liuwx. All rights reserved.
//

#import "WXVideoPlayer.h"
#import <AVFoundation/AVFoundation.h>
#import <MediaPlayer/MediaPlayer.h>
#import "Masonry.h"
#import "WXVideoLayerView.h"
#import "WXVideoOpertationTip.h"
#import "WXVideoTopBar.h"
#import "WXVideoBottomBar.h"
#define WXVideoPlayerImageName(fileName) fileName

static NSString * const WXVideoPlayerItemStatusKeyPath              = @"status";
static NSString * const WXVideoPlayerItemLoadedTimeRangesKeyPath    = @"loadedTimeRanges";
static NSString * const WXVideoPlayerItemPlaybackBufferEmptyKeyPath = @"playbackBufferEmpty";

typedef NS_ENUM(NSUInteger, WXControlType) {
    WXControlTypeProgress,
    WXControlTypeVoice,
    WXControlTypeLight,
    WXControlTypeNone = 999
};


@interface WXVideoPlayer()<UIGestureRecognizerDelegate, WXVideoTopBarBarDelegate, WXVideoBottomBarDelegate>


@property (nonatomic, strong) NSURL *videoURL;

@property (nonatomic, assign, readwrite) WXVideoPlayerState playerState;
@property (nonatomic, assign) UIInterfaceOrientation currentOrientation;

@property (nonatomic, assign) BOOL moved;
@property (nonatomic, assign) BOOL controlHasJudged;
@property (nonatomic, assign) WXControlType controlType;

@property (nonatomic, assign) CGPoint touchBeginPoint;
@property (nonatomic, assign) CGFloat touchBeginVideoValue;
@property (nonatomic, assign) CGFloat touchBeginVoiceValue;

@property (nonatomic, assign) CGFloat videoDuration;
@property (nonatomic, assign) CGFloat videoCurrent;

@property (nonatomic, strong) AVPlayer     *player;
@property (nonatomic, strong) AVPlayerItem *playerItem;
@property (nonatomic, strong) NSObject     *playbackTimeObserver;

@property (nonatomic, weak  ) UIView           *playerView;
@property (nonatomic, weak  ) UIView           *playerSuperView;
@property (nonatomic, assign) CGRect            playerViewOriginalRect;
@property (nonatomic, strong) WXVideoLayerView *videoLayerView;

@property (nonatomic, strong) WXVideoTopBar *topBar;
@property (nonatomic, strong) WXVideoBottomBar *bottomBar;
@property (nonatomic, strong) WXVideoOpertationTip *videoOperationTip;

@property (nonatomic, assign) BOOL isFullScreen;
@property (nonatomic, assign) BOOL isDragingSlider;
@property (nonatomic, assign) BOOL isManualPaused;

@property (nonatomic, strong) UIActivityIndicatorView *loadingIndicatorView;
@property (nonatomic, strong) UISlider                *volumeSlider;
@property (nonatomic, strong) UIView                  *touchView;
@property (nonatomic, strong) UIButton                *replayBtn;


@end





@implementation WXVideoPlayer
- (void)dealloc {
    
    [self destroyPlayer];
    
    NSLog(@"%s", __func__);
}

#pragma mark - Lazy Load

- (WXVideoLayerView *)videoLayerView {
    
    if (!_videoLayerView) {
        _videoLayerView = [[WXVideoLayerView alloc] init];
    }
    return _videoLayerView;
}

- (WXVideoTopBar *)topBar {
    
    if (!_topBar) {
        _topBar = [WXVideoTopBar videoTopBar];
        _topBar.delegate = self;
    }
    
    return _topBar;
}

- (WXVideoBottomBar *)bottomBar {
    
    if (!_bottomBar) {
        _bottomBar = [WXVideoBottomBar videoBottomBar];
        _bottomBar.delegate = self;
        _bottomBar.userInteractionEnabled = NO;
    }
    return _bottomBar;
}

- (UIActivityIndicatorView *)loadingIndicatorView {
    
    if (!_loadingIndicatorView) {
        _loadingIndicatorView = [[UIActivityIndicatorView alloc] init];
    }
    return _loadingIndicatorView;
}

- (UIView *)touchView {
    
    if (!_touchView) {
        _touchView = [[UIView alloc] init];
        _touchView.backgroundColor = [UIColor clearColor];
        
        {
            UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(touchViewTapAction:)];
            tap.delegate = self;
            [_touchView addGestureRecognizer:tap];
        }
        
        {
            UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(touchViewPanAction:)];
            pan.delegate = self;
            [_touchView addGestureRecognizer:pan];
        }
        
        _touchView.userInteractionEnabled = NO;
    }
    return _touchView;
}

- (UISlider *)volumeSlider {
    
    if (!_volumeSlider) {
        MPVolumeView *volumeView = [[MPVolumeView alloc] init];
        volumeView.showsRouteButton = NO;
        volumeView.showsVolumeSlider = NO;
        for (UIView *view in volumeView.subviews) {
            if ([NSStringFromClass(view.class) isEqualToString:@"MPVolumeSlider"]) {
                _volumeSlider = (UISlider *)view;
                break;
            }
        }
    }
    return _volumeSlider;
}

- (WXVideoOpertationTip *)videoOperationTip {
    
    if (!_videoOperationTip) {
        _videoOperationTip = [[WXVideoOpertationTip alloc] init];
        _videoOperationTip.hidden = YES;
        _videoOperationTip.layer.cornerRadius = 10.0;
    }
    return _videoOperationTip;
}

- (UIButton *)replayBtn {
    
    if (!_replayBtn) {
        _replayBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [_replayBtn setImage:[UIImage imageNamed:WXVideoPlayerImageName(@"replay")] forState:UIControlStateNormal];
        [_replayBtn addTarget:self action:@selector(replayAction) forControlEvents:UIControlEventTouchUpInside];
        _replayBtn.hidden = YES;
    }
    return _replayBtn;
}

#pragma mark - Init Methods

+ (instancetype)playerWithVideoURL:(NSURL *)videoURL playerView:(UIView *)playerView playerSuperView:(UIView *)playerSuperView {
    
    return [[WXVideoPlayer alloc] initWithVideoURL:videoURL playerView:playerView playerSuperView:playerSuperView];
}

- (instancetype)initWithVideoURL:(NSURL *)videoURL playerView:(UIView *)playerView playerSuperView:(UIView *)playerSuperView {
    
    if (self = [super init]) {
        _videoURL = videoURL;
        _playerState = WXVideoPlayerStateBuffering;
        _playerEndAction = WXVideoPlayerEndActionStop;
        
        _playerView = playerView;
        _playerView.backgroundColor = [UIColor blackColor];
        _playerView.userInteractionEnabled = YES;
        _playerViewOriginalRect = playerView.frame;
        _playerSuperView = playerSuperView;
        
        [self setupUIConstraints];
        
        [self setupCurrentOrientation];
    }
    return self;
}

- (void)setupCurrentOrientation {
    
    switch ([UIDevice currentDevice].orientation) {
        case UIDeviceOrientationPortrait:
            _currentOrientation = UIInterfaceOrientationPortrait;
            break;
        case UIDeviceOrientationLandscapeLeft:
            _currentOrientation = UIInterfaceOrientationLandscapeLeft;
            break;
        case UIDeviceOrientationLandscapeRight:
            _currentOrientation = UIInterfaceOrientationLandscapeRight;
            break;
        case UIDeviceOrientationPortraitUpsideDown:
            _currentOrientation = UIInterfaceOrientationPortraitUpsideDown;
            break;
        default:
            break;
    }
    
    // Need setting the app only support portrait orientation?
    [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(orientationDidChange) name:UIDeviceOrientationDidChangeNotification object:nil];
}

- (void)setupUIConstraints {
    
    __weak typeof(self) weakSelf = self;
    
    [_playerView addSubview:self.videoLayerView];
    [self.videoLayerView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(0);
        make.right.mas_equalTo(0);
        make.bottom.mas_equalTo(0);
        make.left.mas_equalTo(0);
    }];
    
    [_playerView addSubview:self.topBar];
    [self.topBar mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(0);
        make.left.mas_equalTo(0);
        make.right.mas_equalTo(0);
        make.height.mas_equalTo(44);
    }];
    
    [_playerView addSubview:self.bottomBar];
    [self.bottomBar mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(0);
        make.bottom.equalTo(weakSelf.playerView);
        make.right.mas_equalTo(0);
        make.height.mas_equalTo(44);
    }];
    
    [_playerView addSubview:self.loadingIndicatorView];
    [self.loadingIndicatorView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(weakSelf.videoLayerView);
        make.centerY.equalTo(weakSelf.videoLayerView);
        make.width.mas_equalTo(44);
        make.height.mas_equalTo(44);
    }];
    
    [_playerView addSubview:self.touchView];
    [self.touchView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(weakSelf.videoLayerView).offset(44);
        make.left.equalTo(weakSelf.videoLayerView);
        make.right.equalTo(weakSelf.videoLayerView);
        make.bottom.equalTo(weakSelf.videoLayerView).offset(-44);
    }];
    
    [_playerView addSubview:self.videoOperationTip];
    [self.videoOperationTip mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(weakSelf.playerView);
        make.width.equalTo(@(120));
        make.height.equalTo(@60);
    }];
    
    [_playerView addSubview:self.replayBtn];
    [self.replayBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(weakSelf.playerView);
    }];
}

#pragma mark - Notification Observers

- (void)appWillResignActive {
    
    if (!_playerItem) {
        return;
    }
    
    [self.bottomBar.playPauseBtn setImage:[UIImage imageNamed:WXVideoPlayerImageName(@"start")] forState:UIControlStateNormal];
    
    [self.player pause];
    _playerState = WXVideoPlayerStatePaused;
}

- (void)appDidBecomeActive {
    
    if (!_playerItem) {
        return;
    }
    
    if (!_isManualPaused) {
        [self.bottomBar.playPauseBtn setImage:[UIImage imageNamed:WXVideoPlayerImageName(@"pause")] forState:UIControlStateNormal];
        
        [self.player play];
        _playerState = WXVideoPlayerStatePlaying;
    }
}

- (void)playerItemDidPlayToEnd:(NSNotification *)notification {
    
    _playerState = WXVideoPlayerStateFinished;
    
    switch (_playerEndAction) {
        case WXVideoPlayerEndActionStop:
            self.topBar.hidden    = YES;
            self.bottomBar.hidden = YES;
            self.replayBtn.hidden = NO;
            break;
        case WXVideoPlayerEndActionLoop:
            [self replayAction];
            break;
        case WXVideoPlayerEndActionDestroy:
            [self destroyPlayer];
            break;
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    
    AVPlayerItem *playerItem = (AVPlayerItem *)object;
    if ([keyPath isEqualToString:WXVideoPlayerItemStatusKeyPath]) {
        NSLog(@"WXVideoPlayerItemStatusKeyPath");
        switch (playerItem.status) {
            case AVPlayerStatusReadyToPlay:
            {
                NSLog(@"AVPlayerStatuWXeadyToPlay");
                self.bottomBar.userInteractionEnabled = YES;
                self.touchView.userInteractionEnabled = YES; // Prevents the crash that caused by draging before the video has not successfully load.
                
                [self.loadingIndicatorView stopAnimating];
                
                [self.player play];
                _playerState = WXVideoPlayerStatePlaying;
                
                _videoDuration = playerItem.duration.value / playerItem.duration.timescale; // The total time of the video.
                self.bottomBar.totalTimeLabel.text = [self formatTimeWith:(long)ceil(_videoDuration)];
                self.bottomBar.videoProgressSlider.minimumValue = 0.0;
                self.bottomBar.videoProgressSlider.maximumValue = _videoDuration;
                
                __weak __typeof(self)weakSelf = self;
                _playbackTimeObserver = [_player addPeriodicTimeObserverForInterval:CMTimeMake(1, 1) queue:NULL usingBlock:^(CMTime time) {
                    __strong __typeof(weakSelf) strongSelf = weakSelf;
                    if (weakSelf.isDragingSlider) {
                        return;
                    }
                    
                    if (strongSelf.loadingIndicatorView.isAnimating) {
                        [strongSelf.loadingIndicatorView stopAnimating];
                    }
                    
                    if (!strongSelf.isManualPaused) {
                        strongSelf.playerState = WXVideoPlayerStatePlaying;
                    }
                    
                    CGFloat current = playerItem.currentTime.value / playerItem.currentTime.timescale;
                    strongSelf.bottomBar.currentTimeLabel.text = [strongSelf formatTimeWith:(long)ceil(current)];
                    
                    [strongSelf.bottomBar.videoProgressSlider setValue:current animated:YES];
                    
                    strongSelf.videoCurrent = current;
                    if (strongSelf.videoCurrent > strongSelf.videoDuration) {
                        strongSelf.videoCurrent = strongSelf.videoDuration;
                    }
                }];
                break;
            }
                
            case AVPlayerStatusFailed:
            {
                // Loading video error which usually a resource issue.
                NSLog(@"AVPlayerStatusFailed player: %@", _player.error);
                NSLog(@"AVPlayerStatusFailed playerItem: %@", _playerItem.error);
                [self.loadingIndicatorView stopAnimating];
                _playerState = WXVedioPlayerStateFailed;
                [self destroyPlayer];
                break;
            }
            case AVPlayerStatusUnknown:
            {
                NSLog(@"AVPlayerStatusUnknown");
                break;
            }
        }
    }
    
    if ([keyPath isEqualToString:WXVideoPlayerItemLoadedTimeRangesKeyPath]) {
        NSLog(@"WXVideoPlayerItemLoadedTimeRangesKeyPath");
        NSArray *loadedTimeRanges = [playerItem loadedTimeRanges];
        CMTimeRange timeRange = [loadedTimeRanges.firstObject CMTimeRangeValue]; // Buffer area
        float bufferStart = CMTimeGetSeconds(timeRange.start);
        float bufferDuration = CMTimeGetSeconds(timeRange.duration);
        NSTimeInterval bufferProgress = bufferStart + bufferDuration; // Buffer progress
        CMTime duration = playerItem.duration;
        CGFloat totalDuration = CMTimeGetSeconds(duration);
        [self.bottomBar.videoCacheProgress setProgress:bufferProgress / totalDuration animated:YES];
    }
    
    if ([keyPath isEqualToString:WXVideoPlayerItemPlaybackBufferEmptyKeyPath]) {
        NSLog(@"WXVideoPlayerItemPlaybackBufferEmptyKeyPath");
    }
}

- (void)orientationDidChange {
    
    UIDeviceOrientation orientation = [UIDevice currentDevice].orientation;
    switch (orientation) {
        case UIDeviceOrientationPortrait:
            [self changeToOrientation:UIInterfaceOrientationPortrait];
            break;
        case UIDeviceOrientationLandscapeLeft:
            [self changeToOrientation:UIInterfaceOrientationLandscapeRight];
            break;
        case UIDeviceOrientationLandscapeRight:
            [self changeToOrientation:UIInterfaceOrientationLandscapeLeft];
            break;
        case UIDeviceOrientationPortraitUpsideDown:
            [self changeToOrientation:UIInterfaceOrientationPortraitUpsideDown];
            break;
        default:
            break;
    }
}

#pragma mark - Monitor Methods

- (void)replayAction {
    
    //[self.player seekToTime:kCMTimeZero];
    [self seekToTimeWithSeconds:0];
    
    self.topBar.hidden    = NO;
    self.bottomBar.hidden = NO;
    self.replayBtn.hidden = YES;
    
    [self timingHideBottomBarTime];
}

#pragma mark - Player Methods

- (void)play {
    
    if (!_videoURL) {
        return;
    }
    
    _playerItem = [AVPlayerItem playerItemWithURL:_videoURL];
    _player = [AVPlayer playerWithPlayerItem:_playerItem];
    [(AVPlayerLayer *)self.videoLayerView.layer setPlayer:_player];
    
    [_playerItem addObserver:self forKeyPath:WXVideoPlayerItemStatusKeyPath options:NSKeyValueObservingOptionNew context:nil];
    [_playerItem addObserver:self forKeyPath:WXVideoPlayerItemLoadedTimeRangesKeyPath options:NSKeyValueObservingOptionNew context:nil];
    [_playerItem addObserver:self forKeyPath:WXVideoPlayerItemPlaybackBufferEmptyKeyPath options:NSKeyValueObservingOptionNew context:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appWillResignActive) name:UIApplicationWillResignActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appDidBecomeActive) name:UIApplicationDidBecomeActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playerItemDidPlayToEnd:) name:AVPlayerItemDidPlayToEndTimeNotification object:_playerItem];
    
    [self.loadingIndicatorView startAnimating];
}

- (void)pause {
    
    if (!_playerItem) {
        return;
    }
    
    [self.bottomBar.playPauseBtn setImage:[UIImage imageNamed:WXVideoPlayerImageName(@"start")] forState:UIControlStateNormal];
    
    [_player pause];
    _playerState = WXVideoPlayerStatePaused;
    
    _isManualPaused = YES;
}

- (void)resume {
    
    if (!_playerItem) {
        return;
    }
    
    [self.bottomBar.playPauseBtn setImage:[UIImage imageNamed:WXVideoPlayerImageName(@"pause")] forState:UIControlStateNormal];
    
    [_player play];
    _playerState = WXVideoPlayerStatePlaying;
    
    _isManualPaused = NO;
}

- (void)destroyPlayer {
    
    if (!_playerItem) {
        return;
    }
    
    if (_player && _playerState == WXVideoPlayerStatePlaying) {
        [_player pause];
    }
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [_player removeTimeObserver:_playbackTimeObserver];
    
    [_playerItem removeObserver:self forKeyPath:WXVideoPlayerItemStatusKeyPath];
    [_playerItem removeObserver:self forKeyPath:WXVideoPlayerItemLoadedTimeRangesKeyPath];
    [_playerItem removeObserver:self forKeyPath:WXVideoPlayerItemPlaybackBufferEmptyKeyPath];
    
    _player = nil;
    _playerItem = nil;
    _playbackTimeObserver = nil;
    
    [_playerView removeFromSuperview];
    
    [[UIApplication sharedApplication] setStatusBarHidden:NO];
}

#pragma mark - Assist Methods

- (NSString *)formatTimeWith:(long)time {
    
    NSString *formatTime = nil;
    if (time < 3600) {
        formatTime = [NSString stringWithFormat:@"%02li:%02li", lround(floor(time / 60.0)), lround(floor(time / 1.0)) % 60];
    } else {
        formatTime = [NSString stringWithFormat:@"%02li:%02li:%02li", lround(floor(time / 3600.0)), lround(floor(time % 3600) / 60.0), lround(floor(time / 1.0)) % 60];
    }
    return formatTime;
}

- (void)seekToTimeWithSeconds:(CGFloat)seconds {
    
    if (_playerState == WXVideoPlayerStateStopped) {
        return;
    }
    
    seconds = MAX(0, seconds);
    seconds = MIN(seconds, _videoDuration);
    
    [self.player pause];
    [self.player seekToTime:CMTimeMakeWithSeconds(seconds, NSEC_PER_SEC) completionHandler:^(BOOL finished) {
        [self.player play];
        _isManualPaused = NO;
        _playerState = WXVideoPlayerStatePlaying;
        if (!_playerItem.isPlaybackLikelyToKeepUp) {
            _playerState = WXVideoPlayerStateBuffering;
            [self.loadingIndicatorView startAnimating];
        }
    }];
}

- (float)videoCurrentTimeWithTouchPoint:(CGPoint)touchPoint {
    
    float videoCurrentTime = _touchBeginVideoValue + 100 * ((touchPoint.x - _touchBeginPoint.x) / [UIScreen mainScreen].bounds.size.width);
    
    if (videoCurrentTime > _videoDuration) {
        videoCurrentTime = _videoDuration;
    }
    if (videoCurrentTime < 0) {
        videoCurrentTime = 0;
    }
    
    return videoCurrentTime;
}

- (void)showTopBottomBar {
    
    if (_playerState == WXVideoPlayerStatePlaying) {
        self.topBar.hidden = NO;
        self.bottomBar.hidden = NO;
        [self timingHideBottomBarTime];
    }
}

- (void)hideTopBottomBar {
    
    if (_playerState == WXVideoPlayerStatePlaying) {
        self.topBar.hidden = YES;
        self.bottomBar.hidden = YES;
    }
}

- (void)timingHideBottomBarTime {
    
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(hideTopBottomBar) object:nil];
    [self performSelector:@selector(hideTopBottomBar) withObject:nil afterDelay:5.0];
}

#pragma mark - Orientation Methods

- (void)changeToOrientation:(UIInterfaceOrientation)orientation {
    
    if (_currentOrientation == orientation) {
        return;
    }
    _currentOrientation = orientation;
    
    if (orientation == UIInterfaceOrientationPortrait || orientation == UIInterfaceOrientationPortraitUpsideDown) {
        [_playerView removeFromSuperview];
        [_playerSuperView addSubview:_playerView];
        __weak typeof(self) weakSelf = self;
        [_playerView mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.top.mas_equalTo(CGRectGetMinY(weakSelf.playerViewOriginalRect));
            make.left.mas_equalTo(CGRectGetMinX(weakSelf.playerViewOriginalRect));
            make.width.mas_equalTo(CGRectGetWidth(weakSelf.playerViewOriginalRect));
            make.height.mas_equalTo(CGRectGetHeight(weakSelf.playerViewOriginalRect));
        }];
        
        [_bottomBar.changeScreenBtn setImage:[UIImage imageNamed:WXVideoPlayerImageName(@"full_screen")] forState:UIControlStateNormal];
    }
    
    if (orientation == UIInterfaceOrientationLandscapeLeft || orientation == UIInterfaceOrientationLandscapeRight) {
        [_playerView removeFromSuperview];
        [[UIApplication sharedApplication].keyWindow addSubview:_playerView];
        [_playerView mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.width.equalTo(@([UIScreen mainScreen].bounds.size.height));
            make.height.equalTo(@([UIScreen mainScreen].bounds.size.width));
            make.center.equalTo([UIApplication sharedApplication].keyWindow);
        }];
        
        [_bottomBar.changeScreenBtn setImage:[UIImage imageNamed:WXVideoPlayerImageName(@"small_screen")] forState:UIControlStateNormal];
    }
    
    [UIView animateWithDuration:0.5 animations:^{
        _playerView.transform = [self getTransformWithOrientation:orientation];
    }];
}

- (CGAffineTransform)getTransformWithOrientation:(UIInterfaceOrientation)orientation{
    
    if (orientation == UIInterfaceOrientationPortrait) {
        [self updateToVerticalOrientation];
        return CGAffineTransformIdentity;
    } else if (orientation == UIInterfaceOrientationLandscapeLeft) {
        [self updateToHorizontalOrientation];
        return CGAffineTransformMakeRotation(-M_PI_2);
    } else if (orientation == UIInterfaceOrientationLandscapeRight) {
        [self updateToHorizontalOrientation];
        return CGAffineTransformMakeRotation(M_PI_2);
    } else if (orientation == UIInterfaceOrientationPortraitUpsideDown) {
        [self updateToVerticalOrientation];
        return CGAffineTransformMakeRotation(M_PI);
    }
    return CGAffineTransformIdentity;
}

- (void)updateToVerticalOrientation {
    
    _isFullScreen = NO;
    
    [[UIApplication sharedApplication] setStatusBarHidden:NO];
}

- (void)updateToHorizontalOrientation {
    
    _isFullScreen = YES;
    
    [[UIApplication sharedApplication] setStatusBarHidden:YES];
}

#pragma mark - UIGestureRecognizerDelegate

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
    
    if (_controlHasJudged) {
        return NO;
    } else {
        return YES;
    }
}

- (void)touchViewTapAction:(UITapGestureRecognizer *)tap {
    
    if (self.bottomBar.hidden) {
        [self showTopBottomBar];
    } else {
        [self hideTopBottomBar];
    }
}

- (void)touchViewPanAction:(UIPanGestureRecognizer *)pan {
    
    CGPoint touchPoint = [pan locationInView:pan.view];
    
    if (pan.state == UIGestureRecognizerStateBegan) {
        _moved = NO;
        _controlHasJudged = NO;
        _touchBeginVideoValue = self.bottomBar.videoProgressSlider.value;
        _touchBeginVoiceValue = _volumeSlider.value;
        _touchBeginPoint = touchPoint;
    }
    
    if (pan.state == UIGestureRecognizerStateChanged) {
        if (fabs(touchPoint.x - _touchBeginPoint.x) < 10 && fabs(touchPoint.y - _touchBeginPoint.y) < 10) {
            return;
        }
        
        _moved = YES;
        
        if (!_controlHasJudged) {
            float tan = fabs(touchPoint.y - _touchBeginPoint.y) / fabs(touchPoint.x - _touchBeginPoint.x);
            if (tan < 1 / sqrt(3)) { // Sliding angle is less than 30 degrees.
                _controlType = WXControlTypeProgress;
                _controlHasJudged = YES;
            } else if (tan > sqrt(3)) { // Sliding angle is greater than 60 degrees
                if (_touchBeginPoint.x < pan.view.frame.size.width / 2) { // The left side of the screen controls the brightness.
                    _controlType = WXControlTypeLight;
                } else { // The right side of the screen controls the volume.
                    _controlType = WXControlTypeVoice;
                }
                _controlHasJudged = YES;
            } else {
                _controlType = WXControlTypeNone;
                return;
            }
        }
        
        if (_controlType == WXControlTypeProgress) {
            float videoCurrentTime = [self videoCurrentTimeWithTouchPoint:touchPoint];
            if (videoCurrentTime > _touchBeginVideoValue) {
                self.videoOperationTip.tipImageView.image = [UIImage imageNamed:WXVideoPlayerImageName(@"progress_right")];
            } else if(videoCurrentTime < _touchBeginVideoValue) {
                self.videoOperationTip.tipImageView.image = [UIImage imageNamed:WXVideoPlayerImageName(@"progress_left")];
            }
            
            self.videoOperationTip.hidden = NO;
            self.videoOperationTip.tipLabel.text = [NSString stringWithFormat:@"%@/%@", [self formatTimeWith:(long)videoCurrentTime], self.bottomBar.totalTimeLabel.text];
            
        } else if (_controlType == WXControlTypeVoice) {
            float voiceValue = _touchBeginVoiceValue - ((touchPoint.y - _touchBeginPoint.y) / CGRectGetHeight(pan.view.frame));
            if (voiceValue < 0) {
                self.volumeSlider.value = 0;
            } else if (voiceValue > 1) {
                self.volumeSlider.value = 1;
            } else {
                self.volumeSlider.value = voiceValue;
            }
            
        } else if (_controlType == WXControlTypeLight) {
            [UIScreen mainScreen].brightness -= ((touchPoint.y - _touchBeginPoint.y) / 10000);
            
        } else if (_controlType == WXControlTypeNone) {
            if (self.bottomBar.hidden) {
                [self showTopBottomBar];
            } else {
                [self hideTopBottomBar];
            }
        }
    }
    
    if (pan.state == UIGestureRecognizerStateEnded || pan.state == UIGestureRecognizerStateCancelled) {
        _controlHasJudged = NO;
        if (_moved && _controlType == WXControlTypeProgress) {
            self.videoOperationTip.hidden = YES;
            [self seekToTimeWithSeconds:[self videoCurrentTimeWithTouchPoint:touchPoint]];
            [self.bottomBar.playPauseBtn setImage:[UIImage imageNamed:WXVideoPlayerImageName(@"pause")] forState:UIControlStateNormal];
        }
    }
    
    [self showTopBottomBar];
}

#pragma mark - WXVideoTopBarBarDelegate

- (void)videoTopBarDidClickCloseBtn {
    
    [self destroyPlayer];
}

#pragma mark - WXVideoBottomBarDelegate

- (void)videoBottomBarDidClickPlayPauseBtn {
    
    if (!_playerItem) {
        return;
    }
    
    switch (_playerState) {
        case WXVideoPlayerStatePlaying:
            [self pause];
            break;
        case WXVideoPlayerStatePaused:
            [self resume];
            break;
        default:
            break;
    }
    
    [self timingHideBottomBarTime];
}

- (void)videoBottomBarDidClickChangeScreenBtn {
    
    if (_isFullScreen) {
        [self changeToOrientation:UIInterfaceOrientationPortrait];
    } else {
        [self changeToOrientation:UIInterfaceOrientationLandscapeRight];
    }
    
    [self timingHideBottomBarTime];
}

- (void)videoBottomBarDidTapSlider:(UISlider *)slider withTap:(UITapGestureRecognizer *)tap {
    
    CGPoint touchPoint = [tap locationInView:self.bottomBar.videoProgressSlider];
    float value = (touchPoint.x / self.bottomBar.videoProgressSlider.frame.size.width) * self.bottomBar.videoProgressSlider.maximumValue;
    
    self.bottomBar.currentTimeLabel.text = [self formatTimeWith:(long)ceil(value)];
    [self seekToTimeWithSeconds:value];
    
    [self.bottomBar.playPauseBtn setImage:[UIImage imageNamed:WXVideoPlayerImageName(@"pause")] forState:UIControlStateNormal];
    
    [self timingHideBottomBarTime];
}

- (void)videoBottomBarChangingSlider:(UISlider *)slider {
    
    _isDragingSlider = YES;
    
    self.bottomBar.currentTimeLabel.text = [self formatTimeWith:(long)ceil(slider.value)];
    
    [self timingHideBottomBarTime];
}

- (void)videoBottomBarDidEndChangeSlider:(UISlider *)slider {
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        // The delay is to prevent the sliding point from jumping.
        _isDragingSlider = NO;
    });
    
    self.bottomBar.currentTimeLabel.text = [self formatTimeWith:(long)ceil(slider.value)];
    
    [self.bottomBar.playPauseBtn setImage:[UIImage imageNamed:WXVideoPlayerImageName(@"pause")] forState:UIControlStateNormal];
    
    [self seekToTimeWithSeconds:slider.value];
    
    [self timingHideBottomBarTime];
}

#pragma mark - Public Methods

- (void)setVideoName:(NSString *)videoName {
    
    videoName = videoName;
    
    _topBar.titleLabel.text = videoName;
}
@end
