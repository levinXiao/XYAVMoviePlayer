//
//  ViewController.m
//  XYAVMoviePlayerExample
//
//  Created by xiaoyu on 2016/10/14.
//  Copyright © 2016年 xiaoyu. All rights reserved.
//

#import "ViewController.h"
#import "XYAVMoviePlayer.h"
#import "XYAVMovieDownloadManager.h"

@interface ViewController () <XYAVMoviePlayerDelegate,XYAVMovieDownloadManagerDelegate>

@end

@implementation ViewController {
    XYAVMoviePlayer *avMoviePlayer;
    
    UISlider *playerDownloadGrogressSlider;
    UISlider *playerGrogressSlider;
    
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    //http://krtv.qiniudn.com/150522nextapp
    //
    UIButton *switchButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [switchButton setTitle:@"暂停/播放" forState:UIControlStateNormal];
    [switchButton setTintColor:[UIColor blueColor]];
    [switchButton addTarget:self action:@selector(switchButtonClick) forControlEvents:UIControlEventTouchUpInside];
    switchButton.frame = (CGRect){0,self.view.frame.size.height-100,80,50};
    [self.view addSubview:switchButton];
    
    avMoviePlayer = [[XYAVMoviePlayer alloc] init];
    avMoviePlayer.frame = (CGRect){0,50,self.view.frame.size.width,300};
    avMoviePlayer.delegate = self;
    [self.view addSubview:avMoviePlayer];
    avMoviePlayer.cacheEnable = YES;
    //local file PLAY
    //    NSString *localPath = [[NSBundle mainBundle] pathForResource:@"nextsmall" ofType:@"mp4"];
    //    avMoviePlayer.playURL = localPath;
    
    //playurl with extention
    //    avMoviePlayer.playURL = @"http://o7b4rtbje.bkt.clouddn.com/Sia-Chandelier.mp4";
    
    //playurl without extention
//        avMoviePlayer.playURL = @"http://krtv.qiniudn.com/150522nextapp";
    
    avMoviePlayer.playURL = @"http://o7b4rtbje.bkt.clouddn.com/Sia-Chandelier.mp4";
    [avMoviePlayer play];
    avMoviePlayer.currentVolumn = 1;
//    
    playerDownloadGrogressSlider = [[UISlider alloc] init];
    playerDownloadGrogressSlider.frame = (CGRect){15,400,self.view.frame.size.width-30,50};
    playerDownloadGrogressSlider.minimumValue = 0;
    playerDownloadGrogressSlider.maximumValue = 100;
    playerDownloadGrogressSlider.maximumTrackTintColor = [UIColor darkGrayColor];
    playerDownloadGrogressSlider.minimumTrackTintColor = [UIColor redColor];
    [playerDownloadGrogressSlider setThumbImage:[UIImage new] forState:UIControlStateNormal];
    [playerDownloadGrogressSlider setThumbImage:[UIImage new] forState:UIControlStateSelected];
    playerDownloadGrogressSlider.userInteractionEnabled = NO;
    [self.view addSubview:playerDownloadGrogressSlider];
    
    playerGrogressSlider = [[UISlider alloc] init];
    playerGrogressSlider.frame = (CGRect){15,400,self.view.frame.size.width-30,50};
    playerGrogressSlider.minimumValue = 0;
    playerGrogressSlider.maximumValue = 100;
    playerGrogressSlider.continuous = NO;
    playerGrogressSlider.maximumTrackTintColor = [UIColor clearColor];
    playerGrogressSlider.minimumTrackTintColor = [UIColor blueColor];
    [playerGrogressSlider addTarget:self action:@selector(playerGrogressSliderValueChange) forControlEvents:UIControlEventValueChanged];
    [playerGrogressSlider addTarget:self action:@selector(playerGrogressSliderTouchDown) forControlEvents:UIControlEventTouchDown];
    [playerGrogressSlider addTarget:self action:@selector(playerGrogressSliderTouchUp) forControlEvents:UIControlEventTouchCancel | UIControlEventTouchUpOutside | UIControlEventTouchUpInside];
    [self.view addSubview:playerGrogressSlider];
}

-(void)playerGrogressSliderValueChange{
    
}

-(void)playerGrogressSliderTouchDown{
    
}

-(void)playerGrogressSliderTouchUp{
    [avMoviePlayer jumpToTime:playerGrogressSlider.value/1.f/playerGrogressSlider.maximumValue];
}

NSURLSessionDownloadTask *downloadTask;
-(void)switchButtonClick{
//    if (avMoviePlayer.isPlaying) {
//        [avMoviePlayer pause];
//    }else{
//        [avMoviePlayer play];
//    }
    XYAVMovieDownloadItem *item = [[XYAVMovieDownloadItem alloc] init];
    item.identifier = [avMoviePlayer.playURL.lastPathComponent stringByDeletingPathExtension];
    item.filename = item.identifier;
    item.filePathExtension = @"mp4";
    item.downloadUrl = avMoviePlayer.playURL;
    item.timeStamp = [[NSDate date] timeIntervalSince1970];
    
    [XYAVMovieDownloadManager sharedManager].delegate = self;
    [[XYAVMovieDownloadManager sharedManager] addOrChangeItem:item];
    
}

-(void)managerDownloadWrittenBytes:(long long)writtenBytes expectedWrittenBytes:(long long)expectedWrittenBytes {
    NSLog(@"managerDownloadWrittenBytes  %lld ,%lld %02d%@",writtenBytes,expectedWrittenBytes,(int)(writtenBytes*100.f/expectedWrittenBytes),@"%");
}

-(void)managerDownloadDidFinishDownloadAtLocation:(NSString *)location {
    NSLog(@"location %@",location);
}

#pragma mark - XYAVMoviePlayerDelegate
-(NSString *)fileNameWhenPlayerCompleteCache:(XYAVMoviePlayer *)player {
    return [player.playURL.lastPathComponent stringByDeletingPathExtension];
}

-(NSString *)filePathExtensionWhenPlayerCompleteCache:(XYAVMoviePlayer *)player {
    NSString *cacheFileExtension = [[NSURL URLWithString:player.playURL] pathExtension];
    if (!cacheFileExtension || [cacheFileExtension isEqualToString:@""]) {
        cacheFileExtension = @"mp4";
    }
    return cacheFileExtension;
}

-(void)player:(XYAVMoviePlayer *)player didPlayerStateChanged:(BOOL)isPlaying {
    
}

-(void)player:(XYAVMoviePlayer *)player didPlayerTimePass:(double)pass timeTotal:(double)total{
    playerGrogressSlider.value = (pass *1.f/total)*playerGrogressSlider.maximumValue;
}

-(void)player:(XYAVMoviePlayer *)player didPlayerDownloadProgressChanged:(float)downloadProgress{
    playerDownloadGrogressSlider.value = downloadProgress*1.f*playerDownloadGrogressSlider.maximumValue;
}

-(void)didPlayerMuteStateChanged:(XYAVMoviePlayer *)player{
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
