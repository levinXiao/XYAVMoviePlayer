//
//  ViewController.m
//  XYAVMoviePlayerExample
//
//  Created by xiaoyu on 2016/10/14.
//  Copyright © 2016年 xiaoyu. All rights reserved.
//

#import "ViewController.h"
#import "XYAVMoviePlayer.h"


@interface ViewController ()

@end

@implementation ViewController {
    XYAVMoviePlayer *avMoviePlayer;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    //http://krtv.qiniudn.com/150522nextapp
    

//    UIImageView *iamgeView = [[UIImageView alloc] init];
//    iamgeView.frame = (CGRect){0,0,self.view.frame.size.width,300};
//    iamgeView.backgroundColor = [UIColor redColor];
//    [self.view addSubview:iamgeView];
//    
//    NSURL *sourceMovieURL = [NSURL URLWithString:@"http://krtv.qiniudn.com/150522nextapp"];
//
//    //    http://7xrlqi.com1.z0.glb.clouddn.com/150522nextapp
//    
//    AVAsset *movieAsset = [AVURLAsset URLAssetWithURL:sourceMovieURL options:nil];
//    AVPlayerItem *playerItem = [AVPlayerItem playerItemWithAsset:movieAsset];
//    
//    AVPlayer *player = [AVPlayer playerWithPlayerItem:playerItem];
//    
//    playerLayer = [AVPlayerLayer playerLayerWithPlayer:player];
//    playerLayer.frame = iamgeView.layer.bounds;
//    playerLayer.videoGravity = AVLayerVideoGravityResizeAspect;
//    [iamgeView.layer addSublayer:playerLayer];
//    [player play];
//    
    UIButton *switchButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [switchButton setTitle:@"切换源" forState:UIControlStateNormal];
    [switchButton setTintColor:[UIColor blueColor]];
    [switchButton addTarget:self action:@selector(switchButtonClick) forControlEvents:UIControlEventTouchUpInside];
    switchButton.frame = (CGRect){0,self.view.frame.size.height-100,80,50};
    [self.view addSubview:switchButton];
    
    avMoviePlayer = [[XYAVMoviePlayer alloc] init];
    avMoviePlayer.frame = (CGRect){0,0,self.view.frame.size.width,300};
    [self.view addSubview:avMoviePlayer];
//    avMoviePlayer.currentVolumn = 0;
    
    avMoviePlayer.playURL = @"http://krtv.qiniudn.com/150522nextapp";
    [avMoviePlayer play];
}

-(void)switchButtonClick{
//    NSURL *sourceMovieURL = [NSURL URLWithString:@"http://7xrlqi.com1.z0.glb.clouddn.com/150522nextapp"];
//    AVAsset *movieAsset = [AVURLAsset URLAssetWithURL:sourceMovieURL options:nil];
//    AVPlayerItem *playerItem = [AVPlayerItem playerItemWithAsset:movieAsset];
//    
//    AVPlayer *player = [AVPlayer playerWithPlayerItem:playerItem];
//    
//    playerLayer.player = player;
//    [player play];
    
//    avMoviePlayer.playURL = @"http://7xrlqi.com1.z0.glb.clouddn.com/150522nextapp";
//    [avMoviePlayer play];
    avMoviePlayer.mute = !avMoviePlayer.mute;
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
