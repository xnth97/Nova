//
//  NovaRootViewController.m
//  Nova
//
//  Created by Yubo Qin on 2018/1/31.
//  Copyright © 2018 Yubo Qin. All rights reserved.
//

#import "NovaRootViewController.h"
#import "NovaNavigation.h"
#import "NovaUI.h"
#import "NovaData.h"
#import <SafariServices/SafariServices.h>

@interface NovaRootViewController ()<UIScrollViewDelegate, WKNavigationDelegate, WKUIDelegate>

@property (strong, nonatomic) WKUserContentController *rootContentController;
@property (strong, nonatomic) WKWebViewConfiguration *rootConfiguration;
@property (strong, nonatomic) WKWebView *rootWebView;

@end

@implementation NovaRootViewController

- (instancetype)init {
    self = [super init];
    if (self) {
        [self constructInitialJS];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _rootContentController = [[WKUserContentController alloc] init];
    
    // In case of the ViewController is initialized by storyboard instead of calling init:
    [self constructInitialJS];
    
    // Add initial JS scripts
    for (NSString *jsScript in _initialJSScripts) {
        WKUserScript *tmpScript = [[WKUserScript alloc] initWithSource:jsScript injectionTime:WKUserScriptInjectionTimeAtDocumentStart forMainFrameOnly:YES];
        [_rootContentController addUserScript:tmpScript];
    }
    
    // Add message handlers
    [_rootContentController addScriptMessageHandler:[NovaNavigation sharedInstance] name:@"navigation"];
    [_rootContentController addScriptMessageHandler:[NovaUI sharedInstance] name:@"ui"];
    [_rootContentController addScriptMessageHandler:[NovaData sharedInstance] name:@"data"];
    
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

- (void)constructInitialJS {
    if (_initialJSScripts == nil) {
        _initialJSScripts = [[NSMutableArray alloc] init];
        [_initialJSScripts addObject:@"document.documentElement.style.webkitTouchCallout='none';document.documentElement.style.webkitUserSelect='none';"];
        [_initialJSScripts addObject:@"const nova = window.webkit.messageHandlers;"];
    }
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

- (void)addMessageHandler:(id)handler forMessage:(NSString *)message {
    [_rootContentController addScriptMessageHandler:handler name:message];
}

- (NSString *)stringByEvaluatingJavaScript:(NSString *)javascript {
    __block NSString *result = nil;
    __block BOOL finished = NO;
    
    [_rootWebView evaluateJavaScript:javascript completionHandler:^(id result, NSError *error) {
        if (error == nil) {
            if (result != nil) {
                result = [NSString stringWithFormat:@"%@", result];
            }
        } else {
            NSLog(@"evaluateJavaScript error: %@", error.localizedDescription);
        }
        finished = YES;
    }];
    
    while (!finished) {
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]];
    }
    
    return result;
}

- (void)setUserAgent:(NSString *)userAgent {
    _rootWebView.customUserAgent = userAgent;
}

#pragma mark - UIScrollViewDelegate

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView {
    return nil;
}

#pragma mark - WKNavigationDelegate

- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation {
    [_delegate didFinishNavigation];
    if (self.title == nil) {
        self.title = _rootWebView.title;
    }
}

- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler {
    if (navigationAction.navigationType == WKNavigationTypeLinkActivated) {
        NSURL *url = navigationAction.request.URL;
        if ([url.description hasPrefix:@"mailto:"] || [url.description hasPrefix:@"tel:"]) {
            if (@available(iOS 10.0, *)) {
                [[UIApplication sharedApplication] openURL:url options:@{} completionHandler:nil];
            } else {
                [[UIApplication sharedApplication] openURL:url];
            }
        } else {
            if (![_delegate respondsToSelector:@selector(policyForLinkNavigation:)]) {
                if (![url.description hasPrefix:@"http"] && [url.description hasSuffix:@".html"]) {
                    NovaRootViewController *rootVC = [[NovaRootViewController alloc] init];
                    rootVC.url = url.description;
                    if (self.navigationController == nil) {
                        [self presentViewController:rootVC animated:YES completion:nil];
                    } else {
                        [self.navigationController showViewController:rootVC sender:nil];
                    }
                } else {
                    SFSafariViewController *rootVC = [[SFSafariViewController alloc] initWithURL:url];
                    [self presentViewController:rootVC animated:YES completion:nil];
                }
                
            } else {
                [_delegate policyForLinkNavigation:url];
            }
        }
        decisionHandler(WKNavigationActionPolicyCancel);
    } else {
        decisionHandler(WKNavigationActionPolicyAllow);
    }
}

#pragma mark - WKUIDelegate

- (void)webViewDidClose:(WKWebView *)webView {
#if DEBUG
    NSLog(@"%s", __FUNCTION__);
#endif
}

- (void)webView:(WKWebView *)webView runJavaScriptAlertPanelWithMessage:(NSString *)message initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(void))completionHandler {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:[[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleName"] message:message preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:nil];
    [alert addAction:cancel];
    [self presentViewController:alert animated:YES completion:nil];
    completionHandler();
}

@end
