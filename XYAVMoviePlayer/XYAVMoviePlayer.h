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
//以下两个文件是为了缓存已播放的文件而存在的 文件缓存需要文件名和文件后缀
//当cacheEnable = NO 不会触发这两个回调
- (NSString *)fileNameWhenPlayerCompleteCache:(XYAVMoviePlayer *)player;
- (NSString *)filePathExtensionWhenPlayerCompleteCache:(XYAVMoviePlayer *)player;

//当cacheEnable = YES时触发回调
//当播放器下载了文件到自身的文件系统中 这样在播放的时候就不用去缓存文件夹去查找缓存过的文件
//而是直接去 文件系统中返回路径 直接播放本地文件
//如果返回的是nil或者文件不存在 则走 原本逻辑 拿到filename之后去缓存文件夹查找,如果存在播放缓存文件夹的本地文件 如果不存在播放网络流
- (void)player:(XYAVMoviePlayer *)player didPlayerStateChanged:(BOOL)isPlaying;

- (void)player:(XYAVMoviePlayer *)player didPlayerTimePass:(double)pass timeTotal:(double)total;

- (void)player:(XYAVMoviePlayer *)player didPlayerCacheDownloadProgressChanged:(float)downloadProgress;

- (void)didPlayerMuteStateChanged:(XYAVMoviePlayer *)player;

@end

@interface XYAVMoviePlayer : UIView

@property (nonatomic, copy) NSString *playURL;

@property (nonatomic, strong) UIView *mediaPlayerView;

@property (nonatomic, weak) id<XYAVMoviePlayerDelegate> delegate;

@property (nonatomic ,strong) UIImageView *shortCutImageView;

@property (nonatomic, getter=isMute) BOOL mute;

@property (nonatomic, assign) float currentVolumn;

@property (nonatomic, readonly) BOOL isPlaying;

@property (nonatomic, copy) NSString *currentMIMEType;

@property (nonatomic, assign,getter=isCacheEnable) BOOL cacheEnable;

#pragma mark - control
// Plays items from the current queue, resuming paused playback if possible.
- (void)play;

// Pauses playback if playing.
- (void)pause;

// Ends playback. Calling -play again will start from the beginnning of the queue.
- (void)stop;

- (void)jumpToTime:(float)time;

//- (void)downloadWithFileIdentifier

@end


