//
//  WSWebController.h
//  Pods
//
//  Created by winter on 16/8/9.
//
//

#import <UIKit/UIKit.h>

@interface WSWebController : UIViewController

@property(nonatomic,strong) UIWebView *webView;
/// params for webView
@property(nonatomic,copy) NSDictionary* params;

/// load Request from string
///
/// @params strURL urlstr
- (void)loadRequest:(NSString *)strURL;

/// clear function
- (void)clearBeforePop;

@end
