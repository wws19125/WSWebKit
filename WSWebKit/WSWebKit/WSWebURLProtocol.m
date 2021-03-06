//
//  WSWebURLProtocol.m
//  Pods
//
//  Created by winter on 16/8/9.
//  Copyright © 2016年 王的世界. All rights reserved.
//

#import "WSWebURLProtocol.h"
#import "WSWebKitConstant.h"
#import "WSWebController.h"
#import "UIViewController+Util.h"
#import <WSLog/WSLog.h>

const NSString *RequestHandledKey = @"RequestHandledKey";

@interface WSWebURLProtocol () <NSURLSessionDataDelegate>

@property(nonatomic,strong) NSURLSession *urlSession;
@property(nonatomic,strong) NSURLSessionTask *task;


@end

@implementation WSWebURLProtocol

+(BOOL)canInitWithRequest:(NSURLRequest *)request
{
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wincompatible-pointer-types-discards-qualifiers"
    if([WSWebURLProtocol propertyForKey:RequestHandledKey inRequest:request])
        return NO;
    if([[request allHTTPHeaderFields] valueForKey:@"_op"] || [[request.HTTPMethod uppercaseString] isEqualToString:@"OPTIONS"] || [request.URL.absoluteString containsString:KCHost])
    {
//        NSLog(@"-----------%@",[request allHTTPHeaderFields]);
        return YES;
    }
    return NO;
#pragma clang diagnositc pop
}

+ (NSURLRequest *)canonicalRequestForRequest:(NSURLRequest *)request
{
    return request;
}

- (void)startLoading
{
    NSMutableURLRequest *req = [self.request mutableCopy];
    [WSWebURLProtocol setProperty:@(YES) forKey:RequestHandledKey inRequest:req];
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithDictionary:[req allHTTPHeaderFields]];
    if([params valueForKey:@"_op"])
    {
        NSInteger op = [[params valueForKey:@"_op"] integerValue];
        if(op == KCOPOpenWindow)
        {
            UIViewController* vc = [self currentController];
            if(vc)
            {
                WSWebController *nvc = [[WSWebController alloc] init];
                nvc.evalJS = [params valueForKey:@"_evalJS"];
                if(!vc.navigationController)
                {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [vc presentViewController:nvc animated:YES completion:^{
                            [nvc.webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:[params valueForKey:@"_url"]]]];
                        }];
                    });
                }
                else
                {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [nvc loadRequest:[params valueForKey:@"_url"]];
                        [vc.navigationController pushViewController:nvc animated:YES];
                    });
                }
            }
        }
        else if(op == KCOPCloseWindow)
        {
            WSWebController* vc = (WSWebController *)[self currentController];
            //vc.evalJS = [params valueForKey:@"_evalJS"];
            if(vc)
            {
                if(vc.navigationController)
                {
                    /// 当前导航控制器里面不止vc一个时候才Pop
                    if(vc.navigationController.viewControllers.count>1)
                        dispatch_async(dispatch_get_main_queue(), ^{
                            ///注入回调
                            id prevc = vc.navigationController.viewControllers[vc.navigationController.viewControllers.count-2];
                            if([prevc isKindOfClass:[WSWebController class]])
                            {
                                ((WSWebController *)prevc).evalJS = [params valueForKey:@"_evalJS"];
                            }
                            [vc clearBeforePop];
                            [vc.navigationController popViewControllerAnimated:YES];
                            //((WSWebController *)[self currentController]).evalJS = [params valueForKey:@"_evalJS"];
                        });
                }
                else
                    if(vc.presentingViewController)
                    {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            [vc dismissViewControllerAnimated:YES completion:nil];
                        });
                    }
            }
        }
        else if(op == KCOPConsole)
        {
            NSLog(@"%@",[params objectForKey:@"_str"]);
        }
        else if(op == KCOPAjax)
        {
            ///async network request
            NSURLSessionDataTask *task = [self.urlSession dataTaskWithRequest:req];
            [task resume];
            self.task = task;
            return;
        }
    }
     
    NSDictionary *headers;
    ///crossdomain test
    if([[req.HTTPMethod uppercaseString] isEqualToString:@"OPTIONS"])
    {
        headers = @{@"Access-Control-Allow-Origin" : @"*",@"Access-Control-Allow-Methods":@"POST,GET,OPTIONS", @"Access-Control-Allow-Headers": @"_url,_op,_style,_str,_evalJS",@"Access-Control-Max-Age": @"3628800"};
    }
    else
    {
        /// er, we need add this or we get error
        headers = @{@"Access-Control-Allow-Origin" : @"*",@"Access-Control-Allow-Methods":@"POST,GET,OPTIONS", @"Access-Control-Allow-Headers": @"_url,_op,_style,_str,_evalJS",@"Access-Control-Max-Age": @"3628800",@"Content-Type":@"application/json; charset=utf-8"};
    }
    NSHTTPURLResponse *rep = [[NSHTTPURLResponse alloc] initWithURL:self.request.URL statusCode:200 HTTPVersion:@"1.1" headerFields:headers];
    [self.client URLProtocol:self didReceiveResponse:rep cacheStoragePolicy:NSURLCacheStorageNotAllowed];
    [self.client URLProtocol:self didLoadData:[@"{\"code\":200,\"msg\":\"ok\",\"data\":0}" dataUsingEncoding:NSUTF8StringEncoding]];
    [self.client URLProtocolDidFinishLoading:self];
}


- (void)stopLoading
{
    if(self.task)
    {
        [self.task cancel];
    }
}

#pragma mark - urlsession delegate
/* The task has received a response and no further messages will be
 * received until the completion block is called. The disposition
 * allows you to cancel a request or to turn a data task into a
 * download task. This delegate message is optional - if you do not
 * implement it, you can get the response as a property of the task.
 *
 * This method will not be called for background upload tasks (which cannot be converted to download tasks).
 */
- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask
didReceiveResponse:(NSURLResponse *)response
 completionHandler:(void (^)(NSURLSessionResponseDisposition disposition))completionHandler
{
    NSHTTPURLResponse *originRep = (NSHTTPURLResponse *)response;
    NSMutableDictionary *headers = [NSMutableDictionary dictionaryWithDictionary:[originRep allHeaderFields]];
    [headers setValuesForKeysWithDictionary: @{@"Access-Control-Allow-Origin" : @"*",@"Access-Control-Allow-Methods":@"POST,GET,OPTIONS", @"Access-Control-Allow-Headers": @"_url,_op,_style,_str,_evalJS",@"Access-Control-Max-Age": @"3628800",@"Content-Type":@"application/json; charset=utf-8"}];
    NSHTTPURLResponse *rep = [[NSHTTPURLResponse alloc] initWithURL:self.request.URL statusCode:originRep.statusCode HTTPVersion:@"1.1" headerFields:headers];
    [self.client URLProtocol:self didReceiveResponse:rep cacheStoragePolicy:NSURLCacheStorageAllowed];
    completionHandler(NSURLSessionResponseAllow);
}

/* Notification that a data task has become a download task.  No
 * future messages will be sent to the data task.
 */
//- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask
//didBecomeDownloadTask:(NSURLSessionDownloadTask *)downloadTask
//{
//    
//}

/*
 * Notification that a data task has become a bidirectional stream
 * task.  No future messages will be sent to the data task.  The newly
 * created streamTask will carry the original request and response as
 * properties.
 *
 * For requests that were pipelined, the stream object will only allow
 * reading, and the object will immediately issue a
 * -URLSession:writeClosedForStream:.  Pipelining can be disabled for
 * all requests in a session, or by the NSURLRequest
 * HTTPShouldUsePipelining property.
 *
 * The underlying connection is no longer considered part of the HTTP
 * connection cache and won't count against the total number of
 * connections per host.
 */
//- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask
//didBecomeStreamTask:(NSURLSessionStreamTask *)streamTask
//{
//    
//}

/* Sent when data is available for the delegate to consume.  It is
 * assumed that the delegate will retain and not copy the data.  As
 * the data may be discontiguous, you should use
 * [NSData enumerateByteRangesUsingBlock:] to access it.
 */
- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask
    didReceiveData:(NSData *)data
{
    [self.client URLProtocol:self didLoadData:data];
}

/* Invoke the completion routine with a valid NSCachedURLResponse to
 * allow the resulting data to be cached, or pass nil to prevent
 * caching. Note that there is no guarantee that caching will be
 * attempted for a given resource, and you should not rely on this
 * message to receive the resource data.
 */
//- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask
// willCacheResponse:(NSCachedURLResponse *)proposedResponse
// completionHandler:(void (^)(NSCachedURLResponse * __nullable cachedResponse))completionHandler
//{
//    
//}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task
didCompleteWithError:(nullable NSError *)error
{
    if(error)
    {
        [self.client URLProtocol:self didFailWithError:error];
    }
    else
    {
        [self.client URLProtocolDidFinishLoading:self];
    }
}
#pragma mark - other operation

- (UIViewController *)currentController
{
    return [UIViewController currentViewController];
}

#pragma mark - getter
- (NSURLSession *)urlSession
{
    if(!_urlSession)
    {
        _urlSession = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration] delegate:self delegateQueue:[NSOperationQueue mainQueue]];
    }
    return _urlSession;
}

@end
