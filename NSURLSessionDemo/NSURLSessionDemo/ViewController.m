//
//  ViewController.m
//  NSURLSessionDemo
//
//  Created by Ju Liaoyuan on 2018/2/6.
//  Copyright © 2018年 J. All rights reserved.
//

#import "ViewController.h"

static NSString * const baseURL = @"http://7xsgdb.com1.z0.glb.clouddn.com";

static inline NSURL *ly_urlcreate(NSString *path) {
    return [NSURL URLWithString:[NSString stringWithFormat:@"%@/%@",baseURL,path]];
}

@interface ViewController ()<NSURLSessionDelegate>

@property (nonatomic, strong) NSURLSession *urlSession;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.urlSession = [NSURLSession sharedSession];
}

#pragma mark - URL Request
#pragma mark -

- (IBAction)simpleRequestAction:(id)sender {
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:ly_urlcreate(@"session.json")];
    request.HTTPMethod = @"POST";
    
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
    // 启动任务
    [dataTask resume];
}

- (IBAction)sessionCancelAction:(id)sender {
    [self.urlSession invalidateAndCancel];
}

#pragma mark - download
#pragma mark -

- (IBAction)downloadByDataTask:(id)sender {
    
    UIButton *btn = (UIButton *)sender;
    btn.enabled = NO;
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:ly_urlcreate(@"sxdcq.m4a")];
    request.HTTPMethod = @"POST";
    
    NSURLSessionDataTask *dataTask = [self.urlSession dataTaskWithRequest:request.copy completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
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
    }];
    [dataTask resume];
}
- (IBAction)downloadByDownloadTask:(id)sender {
    
    UIButton *btn = (UIButton *)sender;
    btn.enabled = NO;

    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:ly_urlcreate(@"sxdcq.m4a")];
    request.HTTPMethod = @"POST";

    NSURLSessionDownloadTask *downloadTask = [self.urlSession downloadTaskWithRequest:request.copy completionHandler:^(NSURL * _Nullable location, NSURLResponse * _Nullable response, NSError * _Nullable error) {
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
    }];
    
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
