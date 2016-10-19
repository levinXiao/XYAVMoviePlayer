//
//  XYAVFileTool.h
//  XYAVCacheLoaderExample
//
//  Created by xiaoyu on 2016/10/18.
//  Copyright © 2016年 xiaoyu. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface XYAVFileTool : NSObject
/**
 *  创建临时文件
 */
+ (BOOL)createTempFile;

/**
 *  往临时文件写入数据
 */
+ (void)writeTempFileData:(NSData *)data;

/**
 *  读取临时文件数据
 */
+ (NSData *)readTempFileDataWithOffset:(NSUInteger)offset length:(NSUInteger)length;

/**
 *  保存临时文件到缓存文件夹
 */
+ (void)cacheTempFileWithFileName:(NSString *)name;

/**
 *  是否存在缓存文件 存在：返回文件路径 不存在：返回nil
 */
+ (NSString *)cacheFileExistsWithFileName:(NSString *)fileName pathExtension:(NSString *)pathExtension;

/**
 *  清空缓存文件
 */
+ (BOOL)clearCache;

/**
 *  临时文件路径
 */
+ (NSString *)assetTempFilePath;

/**
 *  缓存文件夹路径
 */
+ (NSString *)assetCacheFolderPath;

@end

@interface NSURL (XYAVMoviePlayer)

/**
 *  自定义scheme
 */
- (NSURL *)customSchemeURL;

/**
 *  还原scheme
 */
- (NSURL *)originalSchemeURL;

@end
