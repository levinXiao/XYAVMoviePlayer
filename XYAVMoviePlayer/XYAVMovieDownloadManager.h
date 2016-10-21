//
//  XYAVMovieDownloadManager.h
//  XYAVMoviePlayerExample
//
//  Created by xiaoyu on 2016/10/20.
//  Copyright © 2016年 xiaoyu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@class XYAVMovieDownloadItem;

@protocol XYAVMovieDownloadManagerDelegate <NSObject>

@optional
-(void)managerDownloadItemWillBegin:(XYAVMovieDownloadItem *)item;

-(void)managerDownloadForItem:(XYAVMovieDownloadItem *)item writtenBytes:(long long)writtenBytes expectedWrittenBytes:(long long)expectedWrittenBytes;

-(void)managerDownloadForItem:(XYAVMovieDownloadItem *)item didFinishDownloadAtLocation:(NSString *)location;


@end

@interface XYAVMovieDownloadManager : NSObject

#pragma mark initialize
+ (instancetype)sharedManager;

#pragma mark static
+ (BOOL)downloadFileExistForName:(NSString *)fileName;

+ (NSString *)downloadItemSavingPathWithFullFileName:(NSString *)filename;

+ (NSString *)savePathForPartialResumeDataWithFileName:(NSString *)filename;

@property (nonatomic,assign) BOOL allowsCellularAccess;

@property (nonatomic,weak) id<XYAVMovieDownloadManagerDelegate> delegate;

#pragma mark operation
- (void)addOrChangeItem:(XYAVMovieDownloadItem *)downloadItem;

- (void)deleteItemWithIdentifier:(NSString *)identifier;

- (void)deleteAllDownloadItems;

- (void)synchnized;

- (NSArray *)allMovieDownloadItems;

#pragma mark download
- (void)startAllDownloadItem;

- (void)startDownloadWithItem:(XYAVMovieDownloadItem *)item;

- (void)suspendAllDownloadItem;

- (void)cancelAllDownloadItem;


@end

@interface XYAVMovieDownloadItem : NSObject <NSCoding>

@property (nonatomic, copy) NSString *identifier;

@property (nonatomic ,copy) NSString *filename;
@property (nonatomic ,copy) NSString *filePathExtension;

@property (nonatomic ,copy) NSString *downloadUrl;

//@property (nonatomic, copy) NSString *fileSaveUrl;

//@property (nonatomic, copy) NSString *partialResumeDataSaveUrl;

@property (nonatomic, assign) long long expectedWrittenBytes;

@property (nonatomic, assign) BOOL finished;

@property (nonatomic, assign) NSTimeInterval timeStamp;

@property (nonatomic, strong) NSMutableDictionary *customData;

//这个属性不作存储
//@property (nonatomic, strong) NSURLSessionDownloadTask *downloadTask;

@end
