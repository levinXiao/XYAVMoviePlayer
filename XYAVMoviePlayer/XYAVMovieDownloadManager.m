//
//  XYAVMovieDownloadManager.m
//  XYAVMoviePlayerExample
//
//  Created by xiaoyu on 2016/10/20.
//  Copyright © 2016年 xiaoyu. All rights reserved.
//

#import "XYAVMovieDownloadManager.h"
#import "XYAVFileTool.h"

@interface XYAVMovieDownloadManager () <NSURLSessionDelegate,NSURLSessionDownloadDelegate>

@end

static NSMutableDictionary *allDownloadItemDictionary;
static NSMutableDictionary *downloadTaskDictionary;

@implementation XYAVMovieDownloadManager

#pragma mark initialize
+ (void)initialize{
    [XYAVMovieDownloadManager sharedManager];
    NSString *filePath = [XYAVMovieDownloadManager synchronizedManagerFilePath];
    NSFileManager * manager = [NSFileManager defaultManager];
    if (!filePath || ![manager fileExistsAtPath:filePath]) {
        [manager createFileAtPath:filePath contents:nil attributes:nil];
        allDownloadItemDictionary = [NSMutableDictionary dictionary];
        return;
    }
    NSData *filesData = [NSData dataWithContentsOfFile:filePath];
    NSDictionary *readdicTmp = [NSKeyedUnarchiver unarchiveObjectWithData:filesData];
    if (!readdicTmp || !([readdicTmp isKindOfClass:[NSDictionary class]] || [readdicTmp isKindOfClass:[NSMutableDictionary class]]) || readdicTmp.count == 0) {
        allDownloadItemDictionary = [NSMutableDictionary dictionary];
        return;
    }
    allDownloadItemDictionary = [NSMutableDictionary dictionaryWithDictionary:readdicTmp];
    downloadTaskDictionary = [NSMutableDictionary dictionary];
}

+ (instancetype)sharedManager {
    static XYAVMovieDownloadManager *manager;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[XYAVMovieDownloadManager alloc] init];
        manager.allowsCellularAccess = YES;
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillTerminateNotification) name:UIApplicationWillTerminateNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillResignActiveNotification) name:UIApplicationWillResignActiveNotification object:nil];
        
    });
    return manager;
}

+ (NSString *)synchronizedManagerFilePath {
    NSString *dirctory = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0] stringByAppendingPathComponent:@"com.xiaoyu.XYAVMovieDownloadManager"];
    NSString *fileName = @"XYAVMovieDownloadManagerSynchronized.sync";
    return [[dirctory stringByAppendingPathComponent:fileName] stringByReplacingOccurrencesOfString:@"file://" withString:@""];
}

- (void)addOrChangeItem:(XYAVMovieDownloadItem *)downloadItem{
    @synchronized (allDownloadItemDictionary) {
        if (!downloadItem.identifier || [downloadItem.identifier isEqualToString:@""]) {
            return;
        }
        [allDownloadItemDictionary setObject:downloadItem forKey:downloadItem.identifier];
        [self startDownloadWithItem:downloadItem];
    }
}

- (void)deleteItemWithIdentifier:(NSString *)identifier {
    if (!identifier) {
        return;
    }
    @synchronized (allDownloadItemDictionary) {
        XYAVMovieDownloadItem *downloadItem = [allDownloadItemDictionary objectForKey:identifier];
        
        NSString *fileName = downloadItem.filename;
        if (!fileName || [fileName isEqualToString:@""]) {
            fileName = downloadItem.identifier;
        }
        NSString *filePathExtension = downloadItem.filePathExtension;
        if (!filePathExtension || [filePathExtension isEqualToString:@""]) {
            filePathExtension = @"mp4";
        }
        NSString *fullFileName = [NSString stringWithFormat:@"%@.%@",fileName,filePathExtension];
        NSString *fullFilePath = [XYAVMovieDownloadManager downloadItemSavingPathWithFullFileName:fullFileName];
        NSString *partialResumeDataFilePath = [XYAVMovieDownloadManager savePathForPartialResumeDataWithFileName:identifier];
        NSError *error;
        [[NSFileManager defaultManager] removeItemAtPath:fullFilePath error:&error];
        [[NSFileManager defaultManager] removeItemAtPath:partialResumeDataFilePath error:&error];
        
        [allDownloadItemDictionary removeObjectForKey:downloadItem.identifier];
    }
}

- (void)deleteAllDownloadItems {
    [allDownloadItemDictionary enumerateKeysAndObjectsUsingBlock:^(NSString *key, XYAVMovieDownloadItem *obj, BOOL *stop) {
        [self deleteItemWithIdentifier:obj.identifier];
    }];
}

- (void)synchnized {
    @synchronized (allDownloadItemDictionary) {
        NSData *writeData = [NSKeyedArchiver archivedDataWithRootObject:allDownloadItemDictionary];
        [writeData writeToFile:[XYAVMovieDownloadManager synchronizedManagerFilePath] atomically:YES];
    }
}

- (NSArray *)allMovieDownloadItems{
    //默认升序排列
    NSMutableDictionary *allMovieItemDicTmp = [NSMutableDictionary dictionaryWithDictionary:allDownloadItemDictionary];
    
    NSMutableArray *finishedItemArray = [NSMutableArray array];
    NSMutableArray *unFinishedItemArray = [NSMutableArray array];
    [allMovieItemDicTmp enumerateKeysAndObjectsUsingBlock:^(NSString *key, XYAVMovieDownloadItem  *obj, BOOL *stop) {
        if (obj.finished) {
            [finishedItemArray addObject:obj];
        }else{
            [unFinishedItemArray addObject:obj];
        }
    }];
    [finishedItemArray sortUsingComparator:^NSComparisonResult(XYAVMovieDownloadItem *obj1, XYAVMovieDownloadItem *obj2) {
        if (obj1.timeStamp > obj2.timeStamp)
            return NSOrderedAscending;
        if (obj1.timeStamp < obj2.timeStamp)
            return NSOrderedDescending;
        return NSOrderedSame;
    }];
    [unFinishedItemArray sortUsingComparator:^NSComparisonResult(XYAVMovieDownloadItem *obj1, XYAVMovieDownloadItem *obj2) {
        if (obj1.timeStamp > obj2.timeStamp)
            return NSOrderedAscending;
        if (obj1.timeStamp < obj2.timeStamp)
            return NSOrderedDescending;
        return NSOrderedSame;
    }];
    [finishedItemArray addObjectsFromArray:unFinishedItemArray];
    return [NSArray arrayWithArray:finishedItemArray];
}

#pragma mark - download
- (void)startAllDownloadItem{
    @synchronized (allDownloadItemDictionary) {
        [allDownloadItemDictionary enumerateKeysAndObjectsUsingBlock:^(NSString *key,XYAVMovieDownloadItem *obj, BOOL *stop) {
            [self startDownloadWithItem:obj];
        }];
    }
}

- (void)startDownloadWithItem:(XYAVMovieDownloadItem *)item{
    NSURLSessionDownloadTask *downloadTask = [downloadTaskDictionary objectForKey:item.identifier];
    if (downloadTask) {
        if (downloadTask.state == NSURLSessionTaskStateRunning || downloadTask.state == NSURLSessionTaskStateCompleted) {
            return;
        }
        if (downloadTask.state == NSURLSessionTaskStateSuspended) {
            [downloadTask resume];
            return;
        }
    }
    if (self.delegate && [self.delegate respondsToSelector:@selector(managerDownloadItemWillBegin:)]) {
        [self.delegate managerDownloadItemWillBegin:item];
    }
    NSString *identifier = item.identifier ? item.identifier : @"com.xiaoyu.XYAVMovieDownloadManagerIdentifier";
    NSString *fileName = item.filename;
    if (!fileName || [fileName isEqualToString:@""]) {
        fileName = item.identifier;
    }
    if (fileName) {
        NSString *filePathExtension = item.filePathExtension;
        if (!filePathExtension || [filePathExtension isEqualToString:@""]) {
            filePathExtension = @"mp4";
        }
        NSString *cachedFilePath = [XYAVFileTool cacheFileExistsWithFileName:fileName pathExtension:filePathExtension];
        NSString *fullFileName = [NSString stringWithFormat:@"%@.%@",fileName,filePathExtension];
        NSString *fullFilePath = [XYAVMovieDownloadManager downloadItemSavingPathWithFullFileName:fullFileName];
        if (cachedFilePath && ![cachedFilePath isEqualToString:@""]) {
            BOOL success = [XYAVFileTool copyFileAtPath:cachedFilePath toPath:fullFilePath];
            if (success) {
                item.finished = YES;
                //                item.fileSaveUrl = fullFilePath;
                BOOL deleteSuccess = [XYAVFileTool removeFileAtPath:[XYAVMovieDownloadManager savePathForPartialResumeDataWithFileName:item.identifier]];
                //            if (deleteSuccess) {
                //                item.partialResumeDataSaveUrl = nil;
                //            }
                [XYAVFileTool removeFileAtPath:cachedFilePath];
                if (self.delegate && [self.delegate respondsToSelector:@selector(managerDownloadForItem:didFinishDownloadAtLocation:)]) {
                    [self.delegate managerDownloadForItem:item didFinishDownloadAtLocation:fullFilePath];
                }
                return;
            }
        }
        if ([[NSFileManager defaultManager] fileExistsAtPath:fullFilePath]) {
            item.finished = YES;
            //            item.fileSaveUrl = fullFilePath;
            BOOL deleteSuccess = [XYAVFileTool removeFileAtPath:[XYAVMovieDownloadManager savePathForPartialResumeDataWithFileName:item.identifier]];
            //            if (deleteSuccess) {
            //                item.partialResumeDataSaveUrl = nil;
            //            }
            [XYAVFileTool removeFileAtPath:cachedFilePath];
            if (self.delegate && [self.delegate respondsToSelector:@selector(managerDownloadForItem:didFinishDownloadAtLocation:)]) {
                [self.delegate managerDownloadForItem:item didFinishDownloadAtLocation:fullFilePath];
            }
            return;
        }
    }
    NSURLSessionConfiguration *backgroundSessionConf = [NSURLSessionConfiguration backgroundSessionConfigurationWithIdentifier:identifier];
    backgroundSessionConf.allowsCellularAccess = self.allowsCellularAccess;
    NSURLSession *downloadSession = [NSURLSession sessionWithConfiguration:backgroundSessionConf delegate:self delegateQueue:[NSOperationQueue mainQueue]];
    [downloadTask cancel];
    downloadTask = nil;
    NSString *partialResumeDataPath = [XYAVMovieDownloadManager savePathForPartialResumeDataWithFileName:item.identifier];
    NSData *partialData = [NSData dataWithContentsOfFile:partialResumeDataPath];
    if (partialData && partialData.length > 0) {
        downloadTask = [downloadSession downloadTaskWithResumeData:partialData];
    }else{
        downloadTask = [downloadSession downloadTaskWithURL:[NSURL URLWithString:item.downloadUrl]];
    }
    downloadTask.taskDescription = identifier;
    [downloadTask resume];
    [downloadTaskDictionary setObject:downloadTask forKey:item.identifier];
}

- (void)suspendAllDownloadItem {
    @synchronized (allDownloadItemDictionary) {
        [allDownloadItemDictionary enumerateKeysAndObjectsUsingBlock:^(NSString *key, XYAVMovieDownloadItem *obj, BOOL *stop) {
            if (!obj.finished) {
                NSURLSessionDownloadTask *task = [downloadTaskDictionary objectForKey:obj.identifier];
                if (task && task.state == NSURLSessionTaskStateRunning) {
                    [task suspend];
                }
            }
        }];
    }
}

- (void)cancelAllDownloadItem {
    @synchronized (allDownloadItemDictionary) {
        [allDownloadItemDictionary enumerateKeysAndObjectsUsingBlock:^(NSString *key, XYAVMovieDownloadItem *obj, BOOL *stop) {
            if (!obj.finished) {
                __block NSURLSessionDownloadTask *task = [downloadTaskDictionary objectForKey:obj.identifier];
                if (task && task.state == NSURLSessionTaskStateRunning) {
                    [task cancelByProducingResumeData:^(NSData *resumeData) {
                        NSString *filePath = [XYAVMovieDownloadManager savePathForPartialResumeDataWithFileName:obj.identifier];
                        [resumeData writeToFile:filePath atomically:YES];
                        task = nil;
                        [downloadTaskDictionary removeObjectForKey:obj.identifier];
                    }];
                }
            }
        }];
    }
}

+(NSString *)downloadItemSavingPathWithFullFileName:(NSString *)filename{
    NSString *dirctory = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0] stringByAppendingPathComponent:@"com.xiaoyu.XYAVMovieDownloadManager"];
    if (![[NSFileManager defaultManager] fileExistsAtPath:dirctory]) {
        [[NSFileManager defaultManager] createDirectoryAtPath:dirctory withIntermediateDirectories:YES attributes:nil error:nil];
    }
    return [[dirctory stringByAppendingPathComponent:filename] stringByReplacingOccurrencesOfString:@"file://" withString:@""];
}

+(BOOL)downloadFileExistForName:(NSString *)fileName{
    NSString *fullFilepath = [self downloadItemSavingPathWithFullFileName:fileName];
    return [[NSFileManager defaultManager] fileExistsAtPath:fullFilepath];
}

+ (NSString *)savePathForPartialResumeDataWithFileName:(NSString *)filename{
    NSString *dirctory = [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0] stringByAppendingPathComponent:@"com.xiaoyu.XYAVMovieDownloadManager"];
    if (![[NSFileManager defaultManager] fileExistsAtPath:dirctory]) {
        [[NSFileManager defaultManager] createDirectoryAtPath:dirctory withIntermediateDirectories:YES attributes:nil error:nil];
    }
    NSString *fileName = [filename stringByAppendingString:@".resumeData"];
    return [[dirctory stringByAppendingPathComponent:fileName] stringByReplacingOccurrencesOfString:@"file://" withString:@""];
}


#pragma mark - NSURLSessionDownloadTaskDelegate
/* Sent when a download task that has completed a download.  The delegate should
 * copy or move the file at the given location to a new location as it will be
 * removed when the delegate message returns. URLSession:task:didCompleteWithError: will
 * still be called.
 */
- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask
didFinishDownloadingToURL:(NSURL *)location {
    NSString *identifier = downloadTask.taskDescription;
    XYAVMovieDownloadItem *item = [allDownloadItemDictionary objectForKey:identifier];
    NSString *fullFileName = [NSString stringWithFormat:@"%@.%@",item.filename,item.filePathExtension];
    NSString *fullFilePath = [XYAVMovieDownloadManager downloadItemSavingPathWithFullFileName:fullFileName];
    BOOL success = [XYAVFileTool copyFileAtPath:[location.absoluteString stringByReplacingOccurrencesOfString:@"file://" withString:@""] toPath:fullFilePath];
    if (success) {
        item.finished = YES;
        //        item.fileSaveUrl = fullFilePath;
        BOOL deleteSuccess = [XYAVFileTool removeFileAtPath:[XYAVMovieDownloadManager savePathForPartialResumeDataWithFileName:identifier]];
        //        if (deleteSuccess) {
        //            item.partialResumeDataSaveUrl = nil;
        //        }
        if (self.delegate && [self.delegate respondsToSelector:@selector(managerDownloadForItem:didFinishDownloadAtLocation:)]) {
            [self.delegate managerDownloadForItem:item didFinishDownloadAtLocation:fullFilePath];
        }
    }
}

/* Sent periodically to notify the delegate of download progress. */
- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask
      didWriteData:(int64_t)bytesWritten totalBytesWritten:(int64_t)totalBytesWritten totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite {
    
    XYAVMovieDownloadItem *item = [allDownloadItemDictionary objectForKey:downloadTask.taskDescription];
    item.finished = NO;
    if (self.delegate && [self.delegate respondsToSelector:@selector(managerDownloadForItem:writtenBytes:expectedWrittenBytes:)]) {
        [self.delegate managerDownloadForItem:item writtenBytes:totalBytesWritten expectedWrittenBytes:totalBytesExpectedToWrite];
    }
}

#pragma mark - notification
+ (void)applicationWillTerminateNotification{
    [[XYAVMovieDownloadManager sharedManager] cancelAllDownloadItem];
    [[XYAVMovieDownloadManager sharedManager] synchnized];
}

+ (void)applicationWillResignActiveNotification{
    [[XYAVMovieDownloadManager sharedManager] synchnized];
}

@end


@implementation XYAVMovieDownloadItem

//- (void)setFileSaveUrl:(NSString *)fileSaveUrl{
//    if (!fileSaveUrl) {
//        _fileSaveUrl = nil;
//        return;
//    }
//    _fileSaveUrl = [fileSaveUrl stringByReplacingOccurrencesOfString:@"file://" withString:@""];
//}

//-(void)setPartialResumeDataSaveUrl:(NSString *)partialResumeDataSaveUrl{
//    if (!partialResumeDataSaveUrl) {
//        _partialResumeDataSaveUrl = nil;
//        return;
//    }
//    _partialResumeDataSaveUrl = [partialResumeDataSaveUrl stringByReplacingOccurrencesOfString:@"file://" withString:@""];
//}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    if (self.identifier) {
        [aCoder encodeObject:self.identifier forKey:NSStringFromSelector(@selector(identifier))];
    }
    if (self.filename) {
        [aCoder encodeObject:self.filename forKey:NSStringFromSelector(@selector(filename))];
    }
    if (self.filePathExtension) {
        [aCoder encodeObject:self.filePathExtension forKey:NSStringFromSelector(@selector(filePathExtension))];
    }
    if (self.downloadUrl) {
        [aCoder encodeObject:self.downloadUrl forKey:NSStringFromSelector(@selector(downloadUrl))];
    }
    //    if (self.fileSaveUrl) {
    //        [aCoder encodeObject:self.fileSaveUrl forKey:NSStringFromSelector(@selector(fileSaveUrl))];
    //    }
    //    if (self.partialResumeDataSaveUrl) {
    //        [aCoder encodeObject:self.partialResumeDataSaveUrl forKey:NSStringFromSelector(@selector(partialResumeDataSaveUrl))];
    //    }
    if (self.customData) {
        [aCoder encodeObject:self.customData forKey:NSStringFromSelector(@selector(customData))];
    }
    [aCoder encodeObject:@(self.expectedWrittenBytes) forKey:NSStringFromSelector(@selector(expectedWrittenBytes))];
    
    [aCoder encodeObject:@(self.finished) forKey:NSStringFromSelector(@selector(finished))];
    
    [aCoder encodeObject:@(self.timeStamp) forKey:NSStringFromSelector(@selector(timeStamp))];
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super init];
    if (self) {
        self.identifier = [aDecoder decodeObjectForKey:NSStringFromSelector(@selector(identifier))];
        
        self.filename = [aDecoder decodeObjectForKey:NSStringFromSelector(@selector(filename))];
        
        self.filePathExtension = [aDecoder decodeObjectForKey:NSStringFromSelector(@selector(filePathExtension))];
        
        self.downloadUrl = [aDecoder decodeObjectForKey:NSStringFromSelector(@selector(downloadUrl))];
        
        //        self.fileSaveUrl = [aDecoder decodeObjectForKey:NSStringFromSelector(@selector(fileSaveUrl))];
        
        //        self.partialResumeDataSaveUrl = [aDecoder decodeObjectForKey:NSStringFromSelector(@selector(partialResumeDataSaveUrl))];
        
        self.expectedWrittenBytes = [[aDecoder decodeObjectForKey:NSStringFromSelector(@selector(expectedWrittenBytes))] longLongValue];
        
        self.finished = [[aDecoder decodeObjectForKey:NSStringFromSelector(@selector(finished))] boolValue];
        
        self.timeStamp = [[aDecoder decodeObjectForKey:NSStringFromSelector(@selector(timeStamp))] doubleValue];
        
        self.customData = [aDecoder decodeObjectForKey:NSStringFromSelector(@selector(customData))];
        
    }
    return self;
}


@end
