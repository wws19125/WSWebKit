//
//  WSWebController.m
//  Pods
//
//  Created by winter on 16/8/9.
//
//

#import "WSWebController.h"
#import "WSWebURLProtocol.h"
#import <WSLog/WSLog.h>

@interface WSWebController () <UIWebViewDelegate>

@property(nonatomic,weak) UINavigationController *weakNavVC;
@property(nonatomic,assign) BOOL navHidden;
@property(nonatomic,assign) BOOL loadFinish;
@end

@implementation WSWebController

#pragma mark - life cycle && inherit

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    [self registerProtocol:YES];
    [self setAutomaticallyAdjustsScrollViewInsets:NO];
    [self.navigationController.interactivePopGestureRecognizer setEnabled:YES];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    if(self.navigationController&&self.weakNavVC==nil)
    {
        self.navHidden = self.navigationController.navigationBar.hidden;
        [self.navigationController setNavigationBarHidden:YES];
        self.weakNavVC = self.navigationController;
    }
}
- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    if(self.evalJS&&self.loadFinish)
    {
        [self.webView stringByEvaluatingJavaScriptFromString:self.evalJS];
        self.evalJS = nil;
    }
}


- (void)dealloc
{
    
}

/// clear function
- (void)clearBeforePop
{
    [self registerProtocol:NO];
}
- (void)registerProtocol:(BOOL)action
{
    ///利用引用计数
    static NSInteger refCount = 0;
    static NSLock *lock;
    if(!lock)
    {
        lock = [NSLock new];
    }
    ///同步锁
    [lock lock];
    if(action)
    {
        refCount++;
    }
    else
    {
        refCount--;
        if(self.weakNavVC)
        {
            //NSInteger count = self.weakNavVC.viewControllers.count;
            if(![[self.weakNavVC topViewController] isKindOfClass:[WSWebController class]])
            {
                [self.weakNavVC setNavigationBarHidden:self.navHidden];
            }
        }
    }
    if(refCount==1)
    {
        [NSURLProtocol registerClass:[WSWebURLProtocol class]];
    }
    else
        if(refCount==0)
        {
            [NSURLProtocol unregisterClass:[WSWebURLProtocol class]];
            ///清理参数
            self.params = nil;
        }
    [lock unlock];
}
#pragma mark - uiwebviewdelegate
- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
    return YES;
}
- (void)webViewDidStartLoad:(UIWebView *)webView
{
    //NSLog(@"---------load");
}
- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    ///判断是不是自己写的SDK
    if(![[webView stringByEvaluatingJavaScriptFromString:@"wui!=null?1:-1"] isEqualToString:@"1"])
    {
        return;
    }
    /// Load and inject javascript
    NSBundle *bundle = [NSBundle bundleForClass:self.classForCoder];
    NSError *err;
    NSBundle *cbundle = [NSBundle bundleWithPath:[bundle pathForResource:@"WSWebKit" ofType:@"bundle"]];
    NSString *js = [NSString stringWithContentsOfFile:[cbundle pathForResource:@"plus" ofType:@"js"] encoding:NSUTF8StringEncoding error:&err];
    if(err)
    {
        WSLogError(err);
        return;
    }
    [webView stringByEvaluatingJavaScriptFromString:js];
    ///注入参数
    if(self.params)
    {
        NSError *err;
        NSData *dt = [NSJSONSerialization dataWithJSONObject:self.params options:NSJSONWritingPrettyPrinted error:&err];
        if(err)
        {
            WSLogError(err)
            return;
        }
        NSString *str = [NSString stringWithFormat:@"window.plus.params = %@",[[NSString alloc] initWithData:dt encoding:NSUTF8StringEncoding]];
        [webView stringByEvaluatingJavaScriptFromString:str];
    }
    if(self.evalJS)
    {
        [webView stringByEvaluatingJavaScriptFromString:self.evalJS];
        self.evalJS = nil;
    }
    ///加载完成
    self.loadFinish = YES;
    [self.webView stringByEvaluatingJavaScriptFromString:@"wui.OSReady()"];
}
- (void)webView:(UIWebView *)webView didFailLoadWithError:(nullable NSError *)error
{
    //NSLog(@"---------didFailLoadWithError");
    ///加载默认的错误页面
    NSBundle *bundle = [NSBundle bundleForClass:self.classForCoder];
    //NSError *err;
    NSBundle *cbundle = [NSBundle bundleWithPath:[bundle pathForResource:@"WSWebKit" ofType:@"bundle"]];
    [self loadRequest:[cbundle pathForResource:@"error" ofType:@"html"]];
    
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
        CGFloat top = 22;
        //if(self.presentingViewController)
        //{
          //  top = 22;
        //}
        [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-(top)-[wv]-0-|" options:0 metrics:@{@"top":@(top)} views:@{@"wv":_webView}]];
        [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-0-[wv]-0-|" options:0 metrics:nil views:@{@"wv":_webView}]];
        _webView.delegate = self;
        [_webView.scrollView setBounces:NO];
    }
    return _webView;
}
static NSDictionary *sharedParams;

- (void)setParams:(NSDictionary *)params
{
    sharedParams = params;
}
- (NSDictionary *)params
{
    return sharedParams;
}


- (void)loadRequest:(NSString *)strURL
{
    [self.webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:strURL]]];
}

@end
