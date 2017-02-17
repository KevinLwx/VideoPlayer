//
//  WXVideoTopBar.h
//  WXVideoPlayerDemo
//
//  Created by Liuwx on 2017/2/15.
//  Copyright © 2017年 Liuwx. All rights reserved.
//

#import <UIKit/UIKit.h>
@protocol WXVideoTopBarBarDelegate <NSObject>

- (void)videoTopBarDidClickCloseBtn;

@end
@interface WXVideoTopBar : UIView

@property (nonatomic, weak) id<WXVideoTopBarBarDelegate> delegate;

@property (nonatomic, strong) UIButton *closeBtn;
@property (nonatomic, strong) UILabel  *titleLabel;

+ (instancetype)videoTopBar;

@end
