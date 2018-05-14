//
//  NovaRootViewController.h
//  Nova
//
//  The root class for Nova container.
//  It is recommended to customize Nova by using your own subclass instance of NovaRootViewController
//  and implementing NovaRootViewControllerDelegate methods.
//  All view controllers initialized by Nova framework would by default be a NovaRootViewController
//  instance.
//
//  Created by Yubo Qin on 2018/1/31.
//  Copyright © 2018 Yubo Qin. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <WebKit/WebKit.h>

@protocol NovaRootViewControllerDelegate <NSObject>

@optional
- (void)didFinishNavigation;
- (void)policyForLinkNavigation:(NSURL * _Nonnull)url;

@end

@interface NovaRootViewController : UIViewController

@property (strong, nonatomic, nonnull) NSString *url;
@property (strong, nonatomic, nullable) NSMutableArray<NSString *> *initialJSScripts;
@property (weak, nonatomic, nullable) id<NovaRootViewControllerDelegate> delegate;

// Title for js alert() functions. Default is the bundle's display name.
@property (strong, nonatomic, nullable) NSString *alertTitle;

- (void)evaluateJavaScript:(NSString * _Nonnull)javascript completionHandler:(void(^ _Nullable) (_Nullable id, NSError * _Nullable error))completionHandler;
- (NSString *_Nullable)stringByEvaluatingJavaScript:(NSString * _Nonnull)javascript;
- (void)addMessageHandler:(id <WKScriptMessageHandler> _Nonnull)handler forMessage:(NSString *_Nonnull)message;
- (void)setUserAgent:(NSString *_Nonnull)userAgent;

@end
