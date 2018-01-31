//
//  NovaRootViewController.m
//  Nova
//
//  Created by Yubo Qin on 2018/1/31.
//  Copyright © 2018 Yubo Qin. All rights reserved.
//

#import "NovaRootViewController.h"
#import "NovaNavigation.h"
#import <WebKit/WebKit.h>

@interface NovaRootViewController ()<UIScrollViewDelegate, WKNavigationDelegate, WKUIDelegate>

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
    [_initialJSScripts addObject:@"const nova = window.webkit.messageHandlers;"];

    for (NSString *jsScript in _initialJSScripts) {
        WKUserScript *tmpScript = [[WKUserScript alloc] initWithSource:jsScript injectionTime:WKUserScriptInjectionTimeAtDocumentEnd forMainFrameOnly:YES];
        [_rootContentController addUserScript:tmpScript];
    }
    
    // message handlers
    [_rootContentController addScriptMessageHandler:[NovaNavigation sharedInstance] name:@"navigation"];
    
    _rootConfiguration = [[WKWebViewConfiguration alloc] init];
    _rootConfiguration.userContentController = _rootContentController;
    _rootConfiguration.preferences.javaScriptEnabled = YES;
    _rootConfiguration.preferences.javaScriptCanOpenWindowsAutomatically = NO;
    
    _rootWebView = [[WKWebView alloc] initWithFrame:CGRectZero configuration:_rootConfiguration];
    _rootWebView.allowsBackForwardNavigationGestures = NO;
    _rootWebView.scrollView.delegate = self;
    _rootWebView.navigationDelegate = self;
    _rootWebView.UIDelegate = self;
    _rootWebView.backgroundColor = [UIColor whiteColor];
    
    [self loadUrl:_url];
    
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
    [self loadUrl:url];
}

- (void)loadUrl:(NSString *)url {
    if (![url hasPrefix:@"http"] && [url hasSuffix:@".html"]) {
        // Load local resources
        NSString *urlPath = [[NSBundle mainBundle] pathForResource:url ofType:@""];
        [_rootWebView loadHTMLString:[NSString stringWithContentsOfFile:urlPath encoding:NSUTF8StringEncoding error:nil] baseURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] bundlePath]]];
    } else {
        // Load web request
        [_rootWebView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:url]]];
    }
}

#pragma mark - Public methods

- (void)evaluateJavaScript:(NSString *)javascript completionHandler:(void (^)(id _Nullable, NSError * _Nullable))completionHandler {
    [_rootWebView evaluateJavaScript:javascript completionHandler:completionHandler];
}

#pragma mark - UIScrollViewDelegate

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView {
    return nil;
}

#pragma mark - WKNavigationDelegate

- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation {
    [_delegate didFinishNavigation];
}

#pragma mark - WKUIDelegate

- (void)webViewDidClose:(WKWebView *)webView {
#if DEBUG
    NSLog(@"%s", __FUNCTION__);
#endif
}

- (void)webView:(WKWebView *)webView runJavaScriptAlertPanelWithMessage:(NSString *)message initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(void))completionHandler {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Alert" message:message preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:nil];
    [alert addAction:cancel];
    [self presentViewController:alert animated:YES completion:nil];
    completionHandler();
}

@end
