//
//  NovaRootViewController.m
//  Nova
//
//  Created by Yubo Qin on 2018/1/31.
//  Copyright © 2018 Yubo Qin. All rights reserved.
//

#import "NovaRootViewController.h"
#import <WebKit/WebKit.h>

@interface NovaRootViewController ()<UIScrollViewDelegate, WKNavigationDelegate>

@property (strong, nonatomic) WKUserContentController *rootContentController;
@property (strong, nonatomic) WKWebViewConfiguration *rootConfiguration;
@property (strong, nonatomic) WKWebView *rootWebView;

@end

@implementation NovaRootViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _rootContentController = [[WKUserContentController alloc] init];
    
    if (_initialJSScripts == nil) {
        _initialJSScripts = [[NSMutableArray alloc] init];
    }
    [_initialJSScripts addObject:@"document.documentElement.style.webkitTouchCallout='none';document.documentElement.style.webkitUserSelect='none';"];

    for (NSString *jsScript in _initialJSScripts) {
        WKUserScript *tmpScript = [[WKUserScript alloc] initWithSource:jsScript injectionTime:WKUserScriptInjectionTimeAtDocumentEnd forMainFrameOnly:YES];
        [_rootContentController addUserScript:tmpScript];
    }
    
    _rootConfiguration = [[WKWebViewConfiguration alloc] init];
    _rootConfiguration.userContentController = _rootContentController;
    _rootConfiguration.preferences.javaScriptEnabled = YES;
    _rootConfiguration.preferences.javaScriptCanOpenWindowsAutomatically = NO;
    
    _rootWebView = [[WKWebView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height) configuration:_rootConfiguration];
    _rootWebView.allowsBackForwardNavigationGestures = NO;
    _rootWebView.scrollView.delegate = self;
    _rootWebView.navigationDelegate = self;
    _rootWebView.backgroundColor = [UIColor whiteColor];
    
    self.view = _rootWebView;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dealloc {
    _rootWebView = nil;
    _rootContentController = nil;
    _rootConfiguration = nil;
}

- (void)setUrl:(NSString *)url {
    _url = url;
    if (![_url hasPrefix:@"http"] && [_url hasSuffix:@".html"]) {
        // Load local resources
        NSString *urlPath = [[NSBundle mainBundle] pathForResource:_url ofType:@""];
        [_rootWebView loadHTMLString:[NSString stringWithContentsOfFile:urlPath encoding:NSUTF8StringEncoding error:nil] baseURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] bundlePath]]];
    } else {
        // Load web request
        [_rootWebView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:_url]]];
    }
}

#pragma mark - UIScrollViewDelegate

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView {
    return nil;
}

#pragma mark - WKNavigationDelegate

- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation {
    [_delegate didFinishNavigation];
}

@end
