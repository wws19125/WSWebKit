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

const NSString const *RequestHandledKey = @"RequestHandledKey";

@interface WSWebURLProtocol () <NSURLSessionDataDelegate>

@property(nonatomic,strong) NSURLSession *urlSession;

@end

@implementation WSWebURLProtocol

+(BOOL)canInitWithRequest:(NSURLRequest *)request
{
    if([WSWebURLProtocol propertyForKey:RequestHandledKey inRequest:request])
        return NO;
    if([[request.HTTPMethod uppercaseString] isEqualToString:@"POST"]&&[request.URL.absoluteString containsString:KCHost])
    {
        return YES;
    }
    return NO;
}

+ (NSURLRequest *)canonicalRequestForRequest:(NSURLRequest *)request
{
    return request;
}

- (void)startLoading
{
    NSMutableURLRequest *req = [self.request mutableCopy];
    [WSWebURLProtocol setProperty:@(YES) forKey:RequestHandledKey inRequest:req];
    //NSURLResponse *rep = [[NSURLResponse alloc] initWithURL:self.request.URL MIMEType:@"application/json" expectedContentLength:0 textEncodingName:@"UTF8"];
    
    NSDate *body = self.request.HTTPBody;
    if(body)
    {
        NSString *str = [[NSString alloc] initWithData:body encoding:NSUTF8StringEncoding];
        str = [[str stringByReplacingOccurrencesOfString:@"=" withString:@"&"] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        NSArray<NSString *> *arr = [str componentsSeparatedByString:@"&"];
        NSMutableString *mstr = [[NSMutableString alloc] initWithString:@"{"];
        [arr enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
           if(idx%2==0)
           {
               [mstr appendString:[NSString stringWithFormat:@"\"%@\":",obj]];
           }
            else
            {
                if(idx==arr.count-1)
                {
                    [mstr appendString:[NSString stringWithFormat:@"\"%@\"}",obj]];
                }
                else
                    [mstr appendString:[NSString stringWithFormat:@"\"%@\",",obj]];
            }
        }];
        arr = nil;
        NSError *err;
        NSDictionary* params = [NSJSONSerialization JSONObjectWithData:[mstr dataUsingEncoding:NSUTF8StringEncoding] options:NSJSONReadingMutableContainers error:&err];
        if(err)
        {
            NSLog(@"%@ %@",err.localizedDescription,err.localizedFailureReason);
        }
        if([params valueForKey:@"op"])
        {
            NSInteger op = [[params valueForKey:@"op"] integerValue];
            if(op == KCOPOpenWindow)
            {
                UIViewController* vc = [self currentController];
                if(vc)
                {
                    WSWebController *nvc = [[WSWebController alloc] init];
                    if(!vc.navigationController)
                    {
                        [vc presentViewController:nvc animated:YES completion:^{
                            [nvc.webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:[params valueForKey:@"url"]]]];
                        }];
                    }
                }
            }
            else if(op == KCOPCloseWindow)
            {
                UIViewController* vc = [self currentController];
                if(vc)
                {
                    if(vc.navigationController)
                    {
                        [vc.navigationController popViewControllerAnimated:YES];
                    }
                    else
                        if(vc.presentingViewController)
                        {
                            [vc dismissViewControllerAnimated:YES completion:nil];
                        }
                }
            }
            else if(op == KCOPConsole)
            {
                NSLog(@"%@",[params objectForKey:@"str"]);
            }
        }
    }
    NSDictionary *headers = @{@"Access-Control-Allow-Origin" : @"*", @"Content-Type" : @"application/json"};
    NSHTTPURLResponse *rep = [[NSHTTPURLResponse alloc] initWithURL:self.request.URL statusCode:200 HTTPVersion:@"1.1" headerFields:headers];
    [self.client URLProtocol:self didReceiveResponse:rep cacheStoragePolicy:NSURLCacheStorageNotAllowed];
    [self.client URLProtocol:self didLoadData:[@"{\"code\":200,\"msg\":\"ok\",\"data\":0}" dataUsingEncoding:NSUTF8StringEncoding]];
    [self.client URLProtocolDidFinishLoading:self];
    /*
    NSURLSessionDataTask *dataTask = [self.urlSession dataTaskWithRequest:self.request];
     */
}


- (void)stopLoading
{
    if(_urlSession)
    {
        
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
    [self.client URLProtocol:self didReceiveResponse:response cacheStoragePolicy:NSURLCacheStorageAllowed];
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
        _urlSession = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration] delegate:self delegateQueue:dispatch_get_main_queue()];
    }
    return _urlSession;
}

@end
