//
//  XYAVAssetResourceLoader.h
//  XYAVCacheLoaderExample
//
//  Created by xiaoyu on 2016/10/18.
//  Copyright © 2016年 xiaoyu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import "XYAVAssetRequestTask.h"

@class XYAVAssetResourceLoader;
@protocol XYAVAssetResourceLoaderDelegate <NSObject>

@optional
- (void)loader:(XYAVAssetResourceLoader *)loader failLoadingWithError:(NSError *)error;

@end

@interface XYAVAssetResourceLoader : NSObject <AVAssetResourceLoaderDelegate>

@property (nonatomic, weak) id<XYAVAssetResourceLoaderDelegate> delegate;

@property (atomic, assign) BOOL seekRequired; //Seek标识

@property (nonatomic, assign) BOOL cacheFinished;

@property (nonatomic, copy) NSString *acceptableMIMEType;

@property (nonatomic, copy) NSString *cacheFileName;
@property (nonatomic, copy) NSString *cacheFileExtension;

- (void)stopLoading;

@end
