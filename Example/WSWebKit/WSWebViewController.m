//
//  WSWebViewController.m
//  WSWebKit
//
//  Created by wang on 08/09/2016.
//  Copyright (c) 2016 wang. All rights reserved.
//

#import "WSWebViewController.h"
#import <WSWebKit/WSWebKit.h>
#import <sys/types.h>
@interface WSWebViewController ()

@end

@implementation WSWebViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    int a = 123;
    int *b;
    NSLog(@"%p",b);
    b = &a;
    NSLog(@"%p",b);
    uintptr_t p = (uintptr_t)b;
    NSLog(@"%ld  %d",p,*((int *)p));
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
- (IBAction)btnTaped:(id)sender {
    WSWebController *vc = [WSWebController new];
    [self presentViewController:vc animated:YES completion:^(){
        [vc.webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:@"http://172.18.5.255:8020/Environment/index.html"]]];
    }]  ;
}

@end
