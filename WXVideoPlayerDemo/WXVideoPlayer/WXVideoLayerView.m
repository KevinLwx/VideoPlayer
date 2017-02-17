//
//  WXVideoLayerView.m
//  WXVideoPlayerDemo
//
//  Created by Liuwx on 2017/2/15.
//  Copyright © 2017年 Liuwx. All rights reserved.
//

#import "WXVideoLayerView.h"
#import <AVFoundation/AVFoundation.h>

@implementation WXVideoLayerView
+ (Class)layerClass {
    
    return [AVPlayerLayer class];
}
/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
