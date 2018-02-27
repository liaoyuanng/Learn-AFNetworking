//
//  ViewController.m
//  NSURLSessionDemo
//
//  Created by Ju Liaoyuan on 2018/2/6.
//  Copyright © 2018年 J. All rights reserved.
//

#import "ViewController.h"

#define BACKGROUND 1

static NSString * const baseURL = @"http://7xsgdb.com1.z0.glb.clouddn.com";

static inline NSURL *ly_urlcreate(NSString *path) {
    return [NSURL URLWithString:[NSString stringWithFormat:@"%@/%@",baseURL,path]];
}

@interface ViewController ()<NSURLSessionDelegate, NSURLSessionTaskDelegate, NSURLSessionDataDelegate>

@property (nonatomic, strong) NSURLSession *urlSession;

@property (nonatomic, strong) NSMutableDictionary *tasksAndSenders;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.tasksAndSenders = [NSMutableDictionary new];
    
#if BACKGROUND
    self.urlSession = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration backgroundSessionConfigurationWithIdentifier:@"com.liaoyuan.download.background"] delegate:self delegateQueue:[NSOperationQueue currentQueue]];
#else
    self.urlSession = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration] delegate:self delegateQueue:[NSOperationQueue currentQueue]];
#endif
    
}

#pragma mark - URL Request
#pragma mark -

- (IBAction)simpleRequestAction:(id)sender {
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:ly_urlcreate(@"session.json")];
    request.HTTPMethod = @"POST";
    
#if BACKGROUND
    NSURLSessionDataTask *dataTask = [self.urlSession dataTaskWithRequest:request];
#else
    NSURLSessionDataTask *dataTask = [self.urlSession dataTaskWithRequest:request.copy completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (!error) {
            NSError *serializationError = nil;
            NSDictionary *result = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&serializationError];
            if (serializationError) {
                [self showMessage:serializationError.description];
            } else {
                [self showMessage:result.description];
            }
        } else {
            [self showMessage:error.description];
        }
    }];
#endif
    // 启动任务
    [dataTask resume];
}

#pragma mark - download
#pragma mark -

- (IBAction)downloadByDataTask:(id)sender {
    
    UIButton *btn = (UIButton *)sender;
    btn.enabled = NO;
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:ly_urlcreate(@"sxdcq.m4a")];
    request.HTTPMethod = @"POST";
    
#if BACKGROUND
    NSURLSessionDownloadTask *dataTask = [self.urlSession downloadTaskWithRequest:request.copy];
#else
    __block NSURLSessionDataTask *dataTask = [self.urlSession dataTaskWithRequest:request.copy completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (!error) {
            NSError *writeError = nil;
            NSString *document = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).lastObject;
            BOOL result = [data writeToFile:[NSString stringWithFormat:@"%@/(data_task)%@",document,response.suggestedFilename] options:NSDataWritingAtomic error:&writeError];
            if (result) {
                [self showMessage:@"download success(DataTask)"];
            } else {
                [self showMessage:writeError.description];
            }
        } else {
            [self showMessage:error.description];
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            btn.enabled = YES;
        });
        
        [self.tasksAndSenders removeObjectForKey:@(dataTask.taskIdentifier)];
    }];
    
#endif
    self.tasksAndSenders[@(dataTask.taskIdentifier)] = sender;
    [dataTask resume];
    
}
- (IBAction)downloadByDownloadTask:(id)sender {
    
    UIButton *btn = (UIButton *)sender;
    btn.enabled = NO;
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:ly_urlcreate(@"sxdcq.m4a")];
    request.HTTPMethod = @"POST";
#if BACKGROUND
    NSURLSessionDownloadTask *downloadTask = [self.urlSession downloadTaskWithRequest:request.copy];
#else
    __block NSURLSessionDownloadTask *downloadTask = [self.urlSession downloadTaskWithRequest:request.copy completionHandler:^(NSURL * _Nullable location, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (!error) {
            NSError *moveError = nil;
            NSString *document = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).lastObject;
            NSURL *targetURL = [NSURL fileURLWithPath:[NSString stringWithFormat:@"%@/(download_task)%@",document,response.suggestedFilename]];
            BOOL result = [[NSFileManager defaultManager] moveItemAtURL:location toURL:targetURL error:&moveError];
            if (result) {
                [self showMessage:@"download success(Download Task)"];
            } else {
                [self showMessage:moveError.description];
            }
            dispatch_async(dispatch_get_main_queue(), ^{
                btn.enabled = YES;
            });
        } else {
            [self showMessage:error.description];
        }
        [self.tasksAndSenders removeObjectForKey:@(downloadTask.taskIdentifier)];
    }];
#endif
    self.tasksAndSenders[@(downloadTask.taskIdentifier)] = sender;
    [downloadTask resume];
}

#pragma mark - upload
#pragma mark -

- (IBAction)uploadAction:(id)sender {
    
    NSURL *yourURL = [NSURL new];
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:yourURL];
    
    NSURLSessionUploadTask *upload = [self.urlSession uploadTaskWithRequest:request.copy fromData:[NSData data] completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        
    }];
    
    [upload resume];
}

#pragma mark - task operation
#pragma mark -

// cancel
- (IBAction)sessionCancelAction:(id)sender {
    [self.urlSession getTasksWithCompletionHandler:^(NSArray<NSURLSessionDataTask *> * _Nonnull dataTasks, NSArray<NSURLSessionUploadTask *> * _Nonnull uploadTasks, NSArray<NSURLSessionDownloadTask *> * _Nonnull downloadTasks) {
        for (NSURLSessionDataTask *task in dataTasks) {
            [task cancel];
        }
        
        for (NSURLSessionUploadTask *uploadTask in uploadTasks) {
            [uploadTask cancel];
        }
        
        for (NSURLSessionDownloadTask *downloadTask in downloadTasks) {
            [downloadTask cancel];
        }
    }];
    
    // [self.urlSession finishTasksAndInvalidate];
}


#pragma mark - NSURLSessionDelegate
#pragma mark -

- (void)URLSession:(NSURLSession *)session didBecomeInvalidWithError:(NSError *)error {
    NSLog(@"%@",NSStringFromSelector(_cmd));
}

- (void)URLSession:(NSURLSession *)session didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition, NSURLCredential * _Nullable))completionHandler {
    NSLog(@"%@",NSStringFromSelector(_cmd));
}

- (void)URLSessionDidFinishEventsForBackgroundURLSession:(NSURLSession *)session {
    NSLog(@"%@",NSStringFromSelector(_cmd));
    [self showMessage:@"background download finish"];
}

#pragma mark - NSURLSessionDataDelegate
#pragma mark -

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error {
    NSLog(@"complete， error:%@",error);
    UIButton *sender = (UIButton *)self.tasksAndSenders[@(task.taskIdentifier)];
    sender.enabled = YES;
}

#pragma mark - NSURLSessionTaskDelegate
#pragma mark -

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveResponse:(NSURLResponse *)response completionHandler:(void (^)(NSURLSessionResponseDisposition disposition))completionHandler {
    NSLog(@"%@",NSStringFromSelector(_cmd));
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didBecomeDownloadTask:(NSURLSessionDownloadTask *)downloadTask {
    NSLog(@"%@",NSStringFromSelector(_cmd));
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didBecomeStreamTask:(NSURLSessionStreamTask *)streamTask {
    NSLog(@"%@",NSStringFromSelector(_cmd));
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data {
    NSLog(@"%@",NSStringFromSelector(_cmd));
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask willCacheResponse:(NSCachedURLResponse *)proposedResponse completionHandler:(void (^)(NSCachedURLResponse * _Nullable cachedResponse))completionHandler {
    NSLog(@"%@",NSStringFromSelector(_cmd));
}

- (void)showMessage:(NSString *)message {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Result" message:message preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        
    }]];
    [self presentViewController:alert animated:YES completion:nil];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
