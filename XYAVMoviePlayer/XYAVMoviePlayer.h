//
//  XYAVMoviePlayer.h
//  XYAVMoviePlayerExample
//
//  Created by xiaoyu on 2016/10/14.
//  Copyright © 2016年 xiaoyu. All rights reserved.
//

#import <UIKit/UIKit.h>

@class XYAVMoviePlayer;
@protocol XYAVMoviePlayerDelegate <NSObject>
@optional
-(void)player:(XYAVMoviePlayer *)player didPlayerStateChanged:(BOOL)isPlaying;

-(void)player:(XYAVMoviePlayer *)player didPlayerTimePass:(double)pass timeTotal:(double)total;

-(void)player:(XYAVMoviePlayer *)player didPlayerDownloadProgressChanged:(float)downloadProgress;

-(void)didPlayerMuteStateChanged:(XYAVMoviePlayer *)player;

@end

@interface XYAVMoviePlayer : UIView

@property (nonatomic, copy) NSString *playURL;

@property (nonatomic, strong) UIView *mediaPlayerView;

@property (nonatomic, weak) id<XYAVMoviePlayerDelegate> delegate;

@property (nonatomic ,strong) UIImageView *shortCutImageView;

@property (nonatomic, getter=isMute) BOOL mute;

@property (nonatomic,assign) float currentVolumn;

@property (nonatomic,readonly) BOOL isPlaying;

#pragma mark - control
// Plays items from the current queue, resuming paused playback if possible.
- (void)play;

// Pauses playback if playing.
- (void)pause;

// Ends playback. Calling -play again will start from the beginnning of the queue.
- (void)stop;

-(void)jumpToTime:(float)time;

@end
