//
//  XYAVMoviePlayer.m
//  XYAVMoviePlayerExample
//
//  Created by xiaoyu on 2016/10/14.
//  Copyright © 2016年 xiaoyu. All rights reserved.
//

#import "XYAVMoviePlayer.h"

#import <AVKit/AVKit.h>
#import <AVFoundation/AVFoundation.h>

#import "XYAVAssetResourceLoader.h"
#import "XYAVFileTool.h"

//#import "SUResourceLoader.h"

@interface XYAVMoviePlayer () </*SULoaderDelegate*/ XYAVAssetResourceLoaderDelegate>

@property (nonatomic,strong) AVPlayerLayer *playerLayer;

@property (nonatomic,assign) BOOL shouldPlay;

@property (nonatomic,strong) XYAVAssetResourceLoader *resourceLoader;
//@property (nonatomic,strong) SUResourceLoader *resourceLoader;

@end

@implementation XYAVMoviePlayer {
    NSTimer *durationTimer;
}

#pragma mark - init
-(instancetype)init{
    return [self initWithFrame:CGRectZero];
}

-(instancetype)initWithImage:(UIImage *)image{
    return [self init];
}

-(instancetype)initWithImage:(UIImage *)image highlightedImage:(UIImage *)highlightedImage{
    return [self init];
}

-(instancetype)initWithFrame:(CGRect)frame{
    if (self = [super initWithFrame:frame]) {
        [self setupPlayer];
        [self setFrame:frame];
    }
    return self;
}

#pragma mark - setup
-(void)setupPlayer{
    if (self.playerLayer) {
        return;
    }
    
    self.mediaPlayerView = [[UIView alloc] init];
    self.mediaPlayerView.backgroundColor = [UIColor clearColor];
    [self addSubview:self.mediaPlayerView];
    
    self.shortCutImageView = [[UIImageView alloc] init];
    self.shortCutImageView.backgroundColor = [UIColor clearColor];
    [self.mediaPlayerView addSubview:self.shortCutImageView];
    
    self.playerLayer = [[AVPlayerLayer alloc] init];
    self.playerLayer.videoGravity = AVLayerVideoGravityResizeAspect;
    self.playerLayer.player.volume = 1;
    [self.mediaPlayerView.layer addSublayer:self.playerLayer];

}

- (void)startDurationTimer {
    [durationTimer invalidate];
    durationTimer = [NSTimer scheduledTimerWithTimeInterval:0.2 target:self selector:@selector(monitorVideoPlayback) userInfo:nil repeats:YES];
    [[NSRunLoop currentRunLoop] addTimer:durationTimer forMode:UITrackingRunLoopMode];
}

- (void)stopDurationTimer {
    [durationTimer invalidate];
}

-(void)monitorVideoPlayback{
    CMTime currentTimeCM = self.playerLayer.player.currentTime;
    CMTime durationTimeCM = self.playerLayer.player.currentItem.duration;
    if (currentTimeCM.timescale == 0 || durationTimeCM.timescale == 0) {
        return;
    }
    double currentTime = currentTimeCM.value*1000/currentTimeCM.timescale/1000.f;
    double totalTime = durationTimeCM.value*1000/durationTimeCM.timescale/1000.f;
    
    if (self.isPlaying) {
        if (self.delegate && [self.delegate respondsToSelector:@selector(player:didPlayerTimePass:timeTotal:)]) {
            [self.delegate player:self didPlayerTimePass:currentTime timeTotal:totalTime];
        }
        if (currentTime > totalTime || totalTime <= 0.1f) {
            [self pause];
        }
    }else{
        if (self.shouldPlay) {
            [self play];
        }
    }
    [self notifyPlayStateChanged:self.isPlaying];
    
    //计算缓存进度
    NSArray *loadedTimeRanges = [[self.playerLayer.player currentItem] loadedTimeRanges];
    float downloadProgress = 0.f;
    if (loadedTimeRanges && loadedTimeRanges.count > 0) {
        CMTimeRange timeRange = [loadedTimeRanges.firstObject CMTimeRangeValue];// 获取缓冲区域
        CMTime downloadStartCM = timeRange.start;
        CMTime downloadDurationCM = timeRange.duration;
        if (downloadStartCM.timescale == 0 || downloadDurationCM.timescale == 0) {
            downloadProgress = 0.f;
        }else{
            double downloadStartSecondD = downloadStartCM.value*1000/downloadStartCM.timescale/1000.f;
            double downloadDurationSecondD = downloadDurationCM.value*1000/downloadDurationCM.timescale/1000.f;
            double downloadSecond = downloadStartSecondD + downloadDurationSecondD;
            if (totalTime != 0) {
                downloadProgress = (float)(((int)(downloadSecond*100)/1.f) / ((int)(totalTime*100)/1.f));
                downloadProgress = MIN(downloadProgress, 1);
            }
        }
    }
    if (self.delegate && [self.delegate respondsToSelector:@selector(player:didPlayerDownloadProgressChanged:)]) {
        [self.delegate player:self didPlayerDownloadProgressChanged:downloadProgress];
    }
    NSLog(@"播放进度 %d%@ , 缓存进度 %d%@",(int)(currentTime*100/totalTime),@"%",(int)(downloadProgress*100),@"%");
    
}

- (BOOL)isPlaying {
    if([[UIDevice currentDevice] systemVersion].floatValue >= 10){
        return self.playerLayer.player.timeControlStatus == AVPlayerTimeControlStatusPlaying;
    }else{
        //timeControlStatus 该属性 可以判断出现在播放器的状态
        //iOS对avplayer做了一个改进 可以判断出现在正在缓存的视频的状态
        // 在获取HLS流的时候  avplayer会首先获取第一帧 用来首先显示在界面 再来进行缓存
        //这中间的状态就是 AVPlayerTimeControlStatusWaitingToPlayAtSpecifiedRate
        //在iOS10之前 没有timeControlStatus属性 也就没有了这个状态 这时候在界面上就会出现界面卡死的错觉 但是实际上播放器现在正在缓存
        //但是在实现相关的功能的时候 就需要判断现在播放的时间  这种方法不是非常准备 但是可以提升用户体验
        float rate = self.playerLayer.player.rate;
        if (rate != 0) {
            CMTime currentTimeCM = self.playerLayer.player.currentTime;
            return currentTimeCM.value/currentTimeCM.timescale > 0;
        }else{
            return NO;
        }
    }
}

static int lastPlayingState = -1;
-(void)notifyPlayStateChanged:(BOOL)nowPlayingState{
    if (lastPlayingState == nowPlayingState) {
        return;
    }
    lastPlayingState = nowPlayingState;
    if (self.delegate && [self.delegate respondsToSelector:@selector(player:didPlayerStateChanged:)]) {
        [self.delegate player:self didPlayerStateChanged:self.isPlaying];
    }
}

#pragma mark - control
// Plays items from the current queue, resuming paused playback if possible.
- (void)play {
    [self.playerLayer.player play];
    [self startDurationTimer];
    self.shouldPlay = YES;
    //play的时候不一定现在的状态就是 playing
    //有可能要进行一些网络请求的动作和渲染 正在播放的状态 需要通过 [self isPlaying]方法获取
    //所以这里不能断定现在播放的状态 故没有发送扩展
}

// Pauses playback if playing.
- (void)pause {
    [self.playerLayer.player pause];
    self.shouldPlay = NO;
//    [self stopDurationTimer];
    if (self.delegate && [self.delegate respondsToSelector:@selector(player:didPlayerStateChanged:)]) {
        [self.delegate player:self didPlayerStateChanged:NO];
    }
}

// Ends playback. Calling -play again will start from the beginnning of the queue.
- (void)stop {
    [self pause];
    self.shouldPlay = NO;
    [self stopDurationTimer];
}

-(void)jumpToTime:(float)progress {
    CMTime durationTimeCM = self.playerLayer.player.currentItem.duration;
    if (durationTimeCM.timescale == 0) {
        return;
    }
    long totalTime = durationTimeCM.value/durationTimeCM.timescale;
    self.resourceLoader.seekRequired = YES;
    [self.playerLayer.player seekToTime:CMTimeMakeWithSeconds(totalTime*progress, 1 *NSEC_PER_SEC) completionHandler:^(BOOL finished) {
        [self play];
    }];
}

-(void)changePlayingVolumn:(float)aVolumn{
    if (aVolumn == 0) {
        [self setMute:YES];
        return;
    }else{
        [self setMute:NO];
    }
    self.playerLayer.player.volume = aVolumn;
}

#pragma mark - setter & getter
-(void)setFrame:(CGRect)frame{
    [super setFrame:frame];
    self.mediaPlayerView.frame = self.bounds;
    self.playerLayer.frame = self.mediaPlayerView.bounds;
    self.shortCutImageView.frame = self.mediaPlayerView.bounds;
}

- (void)setMute:(BOOL)mute {
    [self.playerLayer.player setMuted:mute];
    if (self.delegate && [self.delegate respondsToSelector:@selector(didPlayerMuteStateChanged:)]) {
        [self.delegate didPlayerMuteStateChanged:self];
    }
}

-(BOOL)isMute{
    return self.playerLayer.player.muted;
}

-(void)setPlayURL:(NSString *)playURL{
    _playURL = playURL;
    if (playURL) {
        //预先保存volumn值 因为新的player会产生新的volumn
        float volumn = self.currentVolumn;
        BOOL isLocal = YES;
        if ([playURL hasPrefix:@"http"]) {
            //播放在线视频
            isLocal = NO;
        }
        AVPlayerItem *playerItem;
        if (self.cacheEnable) {
            if (!isLocal) {
                NSString *defaultMIMEType = @"video/mp4";
                NSString *defaultFileExtension = @"mp4";
                NSString *cacheFileName = [[NSURL URLWithString:playURL] lastPathComponent];
                NSString *cacheFileExtension = [[NSURL URLWithString:playURL] pathExtension];
                if (self.delegate && [self.delegate respondsToSelector:@selector(filePathExtensionForPlayerCompleteCache:)]) {
                    cacheFileExtension = [self.delegate filePathExtensionForPlayerCompleteCache:self];
                }
                if (!cacheFileExtension || [cacheFileExtension isEqualToString:@""]) {
                    cacheFileExtension = defaultFileExtension;
                }
                if (self.delegate && [self.delegate respondsToSelector:@selector(fileNameForPlayerCompleteCache:)]) {
                    cacheFileName = [self.delegate fileNameForPlayerCompleteCache:self];
                }else{
                    if (cacheFileName) {
                        cacheFileName = [cacheFileName stringByReplacingOccurrencesOfString:[NSString stringWithFormat:@".%@",cacheFileExtension] withString:@""];
                    }
                }
                
                NSString *cacheFilePath = [XYAVFileTool cacheFileExistsWithFileName:cacheFileName pathExtension:cacheFileExtension];
                if (cacheFilePath) {
                    //播放本地缓存
                    NSURL *fileUrl = [NSURL fileURLWithPath:cacheFilePath];
                    playerItem = [AVPlayerItem playerItemWithURL:fileUrl];
                }else{
                    self.resourceLoader = [[XYAVAssetResourceLoader alloc] init];
                    self.resourceLoader.delegate = self;
                    self.resourceLoader.acceptableMIMEType = self.currentMIMEType?self.currentMIMEType:defaultMIMEType;
                    self.resourceLoader.cacheFileName = cacheFileName;
                    self.resourceLoader.cacheFileExtension = cacheFileExtension;
                    
                    AVURLAsset *asset = [AVURLAsset URLAssetWithURL:[[NSURL URLWithString:playURL] customSchemeURL] options:nil];
                    //        AVURLAsset *asset = [AVURLAsset URLAssetWithURL:[NSURL URLWithString:playURL] options:nil];
                    [asset.resourceLoader setDelegate:self.resourceLoader queue:dispatch_get_main_queue()];
                    playerItem = [AVPlayerItem playerItemWithAsset:asset];
                }
            }else{
                playerItem = [AVPlayerItem playerItemWithURL:[NSURL fileURLWithPath:playURL]];
            }
        }else{
            if (!isLocal) {
                playerItem = [AVPlayerItem playerItemWithURL:[NSURL URLWithString:playURL]];
            }else{
                playerItem = [AVPlayerItem playerItemWithURL:[NSURL fileURLWithPath:playURL]];
            }
        }
        AVPlayer *player = [AVPlayer playerWithPlayerItem:playerItem];
        player.actionAtItemEnd = AVPlayerActionAtItemEndPause;
        self.playerLayer.player = player;
        
        [self changePlayingVolumn:volumn];
    }
}

-(void)setCurrentVolumn:(float)currentVolumn{
    [self changePlayingVolumn:currentVolumn];
}

-(float)currentVolumn{
    if (self.isMute) {
        return 0;
    }
    if (!self.playerLayer.player) {
        return 1;
    }
    return self.playerLayer.player.volume;
}

-(BOOL)isCacheEnable{
    return _cacheEnable;
}

-(void)dealloc{
    NSLog(@"XYAVMoviePlayer dealloc");
}

@end
