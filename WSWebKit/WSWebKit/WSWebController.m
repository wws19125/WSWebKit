//
//  WSWebController.m
//  Pods
//
//  Created by winter on 16/8/9.
//
//

#import "WSWebController.h"
#import "WSWebURLProtocol.h"

@interface WSWebController () <UIWebViewDelegate>

@end

@implementation WSWebController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    [self registerProtocol:YES];
    NSLog(@"%@",self);
}

- (void)dealloc
{
    [self registerProtocol:NO];
}
- (void)registerProtocol:(BOOL)action
{
    static BOOL isRegister = NO;
    if(action)
    {
        if(isRegister)return;
        [NSURLProtocol registerClass:[WSWebURLProtocol class]];
        isRegister = YES;
    }
    else
    {
        if(self.navigationController)
        {
            NSInteger count = self.navigationController.viewControllers.count;
            if(count==0)
            {
                [NSURLProtocol unregisterClass:[WSWebURLProtocol class]];
            }
            else
            {
                if(![[self.navigationController.viewControllers firstObject] isKindOfClass:[WSWebController class]])
                {
                    [NSURLProtocol unregisterClass:[WSWebURLProtocol class]];
                }
            }
        }
        else
        {
            if(self.presentingViewController)
            {
                if([self.presentingViewController isKindOfClass:[WSWebController class]])
                {
                    [NSURLProtocol unregisterClass:[WSWebURLProtocol class]];
                }
            }
        }
    }
}
#pragma mark - uiwebviewdelegate
- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
    return YES;
}
- (void)webViewDidStartLoad:(UIWebView *)webView
{
    NSLog(@"---------load");
}
- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    /// Load and inject javascript
    NSBundle *bundle = [NSBundle bundleForClass:self.classForCoder];
    NSError *err;
    NSString *js = [NSString stringWithContentsOfFile:[bundle pathForResource:@"plus" ofType:@"js"] encoding:NSUTF8StringEncoding error:&err];
    if(err)
    {
        NSLog(@"%@ %@",err,err);
    }
}
- (void)webView:(UIWebView *)webView didFailLoadWithError:(nullable NSError *)error
{
    
    NSLog(@"---------didFailLoadWithError");
}


#pragma mark - getter && setter
- (UIWebView *)webView
{
    if(!_webView)
    {
        _webView = [[UIWebView alloc] init];
        [self.view addSubview:_webView];
        /// auto layout
        [_webView setTranslatesAutoresizingMaskIntoConstraints:NO];
        CGFloat top = 0;
        if(self.presentingViewController)
        {
            top = 22;
        }
        [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-(top)-[wv]-0-|" options:0 metrics:@{@"top":@(top)} views:@{@"wv":_webView}]];
        [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-0-[wv]-0-|" options:0 metrics:nil views:@{@"wv":_webView}]];
        _webView.delegate = self;
    }
    return _webView;
}

@end
