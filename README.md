# XYAVMoviePlayer

使用```AVKit```播放视频

使用方法

```
    avMoviePlayer = [[XYAVMoviePlayer alloc] init];
    avMoviePlayer.frame = (CGRect){0,0,self.view.frame.size.width,300};
    [self.view addSubview:avMoviePlayer];
//    avMoviePlayer.currentVolumn = 0;
    
    avMoviePlayer.playURL = @"http://o7b4rtbje.bkt.clouddn.com/Sia-Chandelier.mp4";
    [avMoviePlayer play];
```


# 20161019 add cache

```
    avMoviePlayer = [[XYAVMoviePlayer alloc] init];
    avMoviePlayer.frame = (CGRect){0,50,self.view.frame.size.width,300};
    avMoviePlayer.delegate = self;
    [self.view addSubview:avMoviePlayer];
    avMoviePlayer.cacheEnable = YES;
    //local file PLAY  (you need add your own file)
    //    NSString *localPath = [[NSBundle mainBundle] pathForResource:@"Sia-Chandelier" ofType:@"mp4"];
    //    avMoviePlayer.playURL = localPath;
    
    //playurl with extention
    //    avMoviePlayer.playURL = @"http://o7b4rtbje.bkt.clouddn.com/Sia-Chandelier.mp4";
    
    //playurl without extention
    //    avMoviePlayer.playURL = @"http://krtv.qiniudn.com/150522nextapp";
    
    avMoviePlayer.playURL = @"http://o7b4rtbje.bkt.clouddn.com/Sia-Chandelier.mp4";
    [avMoviePlayer play];
    avMoviePlayer.currentVolumn = 1;

```

