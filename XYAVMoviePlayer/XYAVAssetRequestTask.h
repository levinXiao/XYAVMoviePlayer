//
//  XYAVAssetRequestTask.h
//  XYAVCacheLoaderExample
//
//  Created by xiaoyu on 2016/10/18.
//  Copyright © 2016年 xiaoyu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "XYAVFileTool.h"

@protocol XYAVAssetRequestTaskDelegate <NSObject>

@required
- (void)requestTaskDidUpdateCache; //更新缓冲进度代理方法

@optional
- (void)requestTaskDidReceiveResponse;
- (void)requestTaskDidFinishLoadingWithCache:(BOOL)cache;
- (void)requestTaskDidFailWithError:(NSError *)error;

@end

@interface XYAVAssetRequestTask : NSObject

@property (nonatomic, weak) id<XYAVAssetRequestTaskDelegate> delegate;
@property (nonatomic, strong) NSURL * requestURL; //请求网址
@property (nonatomic, assign) NSUInteger requestOffset; //请求起始位置
@property (nonatomic, assign) NSUInteger fileLength; //文件长度
@property (nonatomic, assign) NSUInteger cacheLength; //缓冲长度
@property (nonatomic, assign) BOOL cache; //是否缓存文件
@property (nonatomic, assign) BOOL cancel; //是否取消请求

@property (nonatomic, copy) NSString *cacheFileName;
@property (nonatomic, copy) NSString *cacheFileExtension;

/**
 *  开始请求
 */
- (void)start;

@end
