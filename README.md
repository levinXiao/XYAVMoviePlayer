# XYAVMoviePlayer

使用```AVKit```播放视频

使用方法

```
    avMoviePlayer = [[XYAVMoviePlayer alloc] init];
    avMoviePlayer.frame = (CGRect){0,0,self.view.frame.size.width,300};
    [self.view addSubview:avMoviePlayer];
//    avMoviePlayer.currentVolumn = 0;
    
    avMoviePlayer.playURL = @"http://krtv.qiniudn.com/150522nextapp";
    [avMoviePlayer play];
```
