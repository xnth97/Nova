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

NS_ASSUME_NONNULL_BEGIN

@protocol WKScriptMessageHandler;

@protocol NovaRootViewControllerDelegate <NSObject>

@optional
- (void)didFinishNavigation;
- (void)policyForLinkNavigation:(nullable NSURL *)url;

@end

@interface NovaRootViewController : UIViewController

@property (strong, nonatomic, nullable) NSString *url;
@property (strong, nonatomic) NSBundle *baseBundle;
@property (strong, nonatomic, readonly) NSMutableArray<NSString *> *initialJSScripts;
@property (weak, nonatomic, nullable) id<NovaRootViewControllerDelegate> delegate;

// Title for js alert() functions. Default is the bundle's display name.
@property (strong, nonatomic, nullable) NSString *alertTitle;

- (void)evaluateJavaScript:(NSString *)javascript completionHandler:(void(^ _Nullable)(id _Nullable, NSError *_Nullable error))completionHandler;
- (nullable NSString *)stringByEvaluatingJavaScript:(NSString *)javascript;
- (void)addMessageHandler:(id<WKScriptMessageHandler>)handler forMessage:(NSString *)message;
- (void)setUserAgent:(NSString *)userAgent;

@end

NS_ASSUME_NONNULL_END
