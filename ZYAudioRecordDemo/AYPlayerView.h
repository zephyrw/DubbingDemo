//
//  AYPlayer.h
//  AYPlayer
//
//  Created by wpsd on 2016/11/22.
//  Copyright © 2016年 wpsd. All rights reserved.
//

#import <UIKit/UIKit.h>

@class AVPlayer;
@class AYPlayerView;

@protocol AYPlayerViewDelegate <NSObject>

@required
- (void)playerView:(AYPlayerView *)playerView fullScreenBtnDidClick:(UIButton *)sender;
@optional
- (void)playerView:(AYPlayerView *)playerView playDidFinished:(NSNotification *)noti;

@end

@interface AYPlayerView : UIView

@property (strong, nonatomic) AVPlayer *player;

- (void)startPlay;
- (void)setupAVPlayerWithURL:(NSURL *)url;
- (void)releasePlayerView;

@end
