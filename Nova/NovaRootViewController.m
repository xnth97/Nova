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
#import "NovaBridge.h"
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
    
    self.rootContentController = [[WKUserContentController alloc] init];
    
    // In case of the ViewController is initialized by storyboard instead of calling init:
    [self constructInitialJS];
    
    // Add initial JS scripts
    for (NSString *jsScript in self.initialJSScripts) {
        WKUserScript *tmpScript = [[WKUserScript alloc] initWithSource:jsScript injectionTime:WKUserScriptInjectionTimeAtDocumentStart forMainFrameOnly:YES];
        [self.rootContentController addUserScript:tmpScript];
    }
    
    // Add message handlers
    [self.rootContentController addScriptMessageHandler:[NovaNavigation sharedInstance] name:@"navigation"];
    [self.rootContentController addScriptMessageHandler:[NovaUI sharedInstance] name:@"ui"];
    [self.rootContentController addScriptMessageHandler:[NovaData sharedInstance] name:@"data"];
    [self.rootContentController addScriptMessageHandler:[NovaBridge sharedInstance] name:@"bridge"];
    
    self.rootConfiguration = [[WKWebViewConfiguration alloc] init];
    self.rootConfiguration.userContentController = _rootContentController;
    self.rootConfiguration.preferences.javaScriptEnabled = YES;
    self.rootConfiguration.preferences.javaScriptCanOpenWindowsAutomatically = NO;
    
    self.rootWebView = [[WKWebView alloc] initWithFrame:CGRectZero configuration:self.rootConfiguration];
    self.rootWebView.allowsBackForwardNavigationGestures = NO;
    self.rootWebView.scrollView.delegate = self;
    self.rootWebView.navigationDelegate = self;
    self.rootWebView.UIDelegate = self;
    self.rootWebView.backgroundColor = [UIColor whiteColor];
    
    [self loadUrl:_url];
    
    self.view = self.rootWebView;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [[NovaBridge sharedInstance] setSelfController:self];
    [[NovaData sharedInstance] setSelfController:self];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dealloc {
    self.rootWebView = nil;
    self.rootContentController = nil;
    self.rootConfiguration = nil;
}

- (void)constructInitialJS {
    if (self.initialJSScripts == nil) {
        self.initialJSScripts = [[NSMutableArray alloc] init];
        [self.initialJSScripts addObject:@"document.documentElement.style.webkitTouchCallout='none';document.documentElement.style.webkitUserSelect='none';"];
        [self.initialJSScripts addObject:@"const nova = window.webkit.messageHandlers;"];
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
        [self.rootWebView loadHTMLString:[NSString stringWithContentsOfFile:urlPath encoding:NSUTF8StringEncoding error:nil] baseURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] bundlePath]]];
    } else {
        // Load web request
        [self.rootWebView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:url]]];
    }
}

#pragma mark - Public methods

- (void)evaluateJavaScript:(NSString *_Nonnull)javascript completionHandler:(void (^)(id _Nullable, NSError * _Nullable))completionHandler {
    if ([[NSThread currentThread] isMainThread]) {
        [self.rootWebView evaluateJavaScript:javascript completionHandler:completionHandler];
    } else {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.rootWebView evaluateJavaScript:javascript completionHandler:completionHandler];
        });
    }
}

- (void)addMessageHandler:(id<WKScriptMessageHandler>)handler forMessage:(NSString *_Nonnull)message {
    [self.rootContentController addScriptMessageHandler:handler name:message];
}

- (NSString *_Nullable)stringByEvaluatingJavaScript:(NSString *_Nonnull)javascript {
    __block NSString *result = nil;
    __block BOOL finished = NO;
    
    [self.rootWebView evaluateJavaScript:javascript completionHandler:^(id result, NSError *error) {
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

- (void)setUserAgent:(NSString *_Nonnull)userAgent {
    self.rootWebView.customUserAgent = userAgent;
}

#pragma mark - UIScrollViewDelegate

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView {
    return nil;
}

#pragma mark - WKNavigationDelegate

- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation {
    [self.delegate didFinishNavigation];
    if (self.title == nil) {
        self.title = self.rootWebView.title;
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
            if (![self.delegate respondsToSelector:@selector(policyForLinkNavigation:)]) {
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
                [self.delegate policyForLinkNavigation:url];
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
    NSString *title = self.alertTitle == nil ?  [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleName"] : self.alertTitle;
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:nil];
    [alert addAction:cancel];
    [self presentViewController:alert animated:YES completion:nil];
    completionHandler();
}

@end
