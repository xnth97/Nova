//
//  NovaRootViewController.m
//  Nova
//
//  Created by Yubo Qin on 2018/1/31.
//  Copyright © 2018 Yubo Qin. All rights reserved.
//

#import "NovaRootViewController.h"

#import <SafariServices/SafariServices.h>

#import "NovaBridge.h"
#import "NovaData.h"
#import "NovaNavigation.h"
#import "NovaUI.h"
#import "NovaUtils.h"

@interface NovaRootViewController ()<UIScrollViewDelegate, WKNavigationDelegate, WKUIDelegate>

@property (strong, nonatomic, nonnull, readwrite) NSMutableArray<NSString *> *initialJSScripts;
@property (strong, nonatomic, nonnull) WKUserContentController *rootContentController;
@property (strong, nonatomic, nonnull) WKWebViewConfiguration *rootConfiguration;
@property (strong, nonatomic, nonnull) WKWebView *rootWebView;

@end

@implementation NovaRootViewController

- (instancetype)init {
    self = [super init];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (void)commonInit {
    _baseBundle = [NSBundle mainBundle];
    _rootContentController = [[WKUserContentController alloc] init];
    
    _initialJSScripts = [[NSMutableArray alloc] init];
    [_initialJSScripts addObject:@"document.documentElement.style.webkitTouchCallout='none';document.documentElement.style.webkitUserSelect='none';"];
    [_initialJSScripts addObject:[NSString stringWithContentsOfURL:[[NovaUtils resourceBundle] URLForResource:@"nova" withExtension:@"js"]
                                                          encoding:NSUTF8StringEncoding
                                                             error:nil]];
    
    // Add message handlers
    [_rootContentController addScriptMessageHandler:[NovaNavigation sharedInstance] name:@"navigation"];
    [_rootContentController addScriptMessageHandler:[NovaUI sharedInstance] name:@"ui"];
    [_rootContentController addScriptMessageHandler:[NovaData sharedInstance] name:@"data"];
    [_rootContentController addScriptMessageHandler:[NovaBridge sharedInstance] name:@"bridge"];
    
    // Setup configuration
    _rootConfiguration = [[WKWebViewConfiguration alloc] init];
    _rootConfiguration.userContentController = _rootContentController;
    _rootConfiguration.preferences.javaScriptEnabled = YES;
    _rootConfiguration.preferences.javaScriptCanOpenWindowsAutomatically = NO;
    
    _rootWebView = [[WKWebView alloc] initWithFrame:CGRectZero configuration:_rootConfiguration];
    _rootWebView.allowsBackForwardNavigationGestures = NO;
    _rootWebView.scrollView.delegate = self;
    _rootWebView.navigationDelegate = self;
    _rootWebView.UIDelegate = self;
    if (@available(iOS 13.0, *)) {
        _rootWebView.backgroundColor = [UIColor systemBackgroundColor];
    } else {
        _rootWebView.backgroundColor = [UIColor whiteColor];
    }
}

- (void)loadView {
    self.view = self.rootWebView;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Add initial JS scripts. This step must be done during viewDidLoad as initial JS array can be
    // extended by other JavaScript exections.
    for (NSString *const jsScript in self.initialJSScripts) {
        WKUserScript *const tmpScript = [[WKUserScript alloc] initWithSource:jsScript
                                                               injectionTime:WKUserScriptInjectionTimeAtDocumentStart
                                                            forMainFrameOnly:YES];
        [self.rootContentController addUserScript:tmpScript];
    }
    
    [self loadUrl:self.url bundle:self.baseBundle];
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

#pragma mark - Setter/getter/helper

- (void)setUrl:(NSString *)url {
    _url = url;
    [self loadUrl:_url bundle:_baseBundle];
}

- (void)setBaseBundle:(NSBundle *)baseBundle {
    _baseBundle = baseBundle;
    [self loadUrl:_url bundle:_baseBundle];
}

- (void)loadUrl:(NSString *)url bundle:(NSBundle *)bundle {
    NSBundle *baseBundle = bundle ?: [NSBundle mainBundle];
    if (![url hasPrefix:@"http"] && [url hasSuffix:@".html"]) {
        // Load local resources
        NSString *urlPath = [baseBundle pathForResource:url ofType:@""];
        [self.rootWebView loadHTMLString:[NSString stringWithContentsOfFile:urlPath
                                                                   encoding:NSUTF8StringEncoding
                                                                      error:nil]
                                 baseURL:[NSURL fileURLWithPath:[baseBundle bundlePath]]];
    } else {
        // Load web request
        [self.rootWebView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:url]]];
    }
}

#pragma mark - Public methods

- (void)evaluateJavaScript:(nonnull NSString *)javascript completionHandler:(void (^)(id _Nullable, NSError * _Nullable))completionHandler {
    if ([[NSThread currentThread] isMainThread]) {
        [self.rootWebView evaluateJavaScript:javascript completionHandler:completionHandler];
    } else {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.rootWebView evaluateJavaScript:javascript completionHandler:completionHandler];
        });
    }
}

- (void)addMessageHandler:(nonnull id<WKScriptMessageHandler>)handler forMessage:(nonnull NSString *)message {
    [self.rootContentController addScriptMessageHandler:handler name:message];
}

- (nullable NSString *)stringByEvaluatingJavaScript:(nonnull NSString *)javascript {
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

- (void)setUserAgent:(nonnull NSString *)userAgent {
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
    if (completionHandler) {
        completionHandler();
    }
}

@end
