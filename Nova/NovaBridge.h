//
//  NovaBridge.h
//  Nova
//
//  Bridge message handler of Nova. Handles 'bridge' messages.
//  This class provides the ability of invoking native Objective-C methods from
//  JavaScript code, serializing the return value as JSON and passing it to the
//  JavaScript callback function. 
//
//  Created by Yubo Qin on 2018/4/25.
//  Copyright © 2018 Yubo Qin. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <WebKit/WebKit.h>
#import "NovaRootViewController.h"

@interface NovaBridge : NSObject <WKScriptMessageHandler>

@property (weak, nonatomic) NovaRootViewController *selfController;

+ (instancetype)sharedInstance;

+ (void)executeCallback:(NSString *)callback withParameter:(id)param;
+ (void)executeCallback:(NSString *)callback withParameters:(NSArray<id> *)params;
+ (void)executeCallback:(NSString *)callback inViewController:(NovaRootViewController *)viewController;
+ (void)executeCallback:(NSString *)callback withParameter:(id)param inViewController:(NovaRootViewController *)viewController;
+ (void)executeCallback:(NSString *)callback withParameters:(NSArray<id> *)parameters inViewController:(NovaRootViewController *)viewController;
+ (void)handleMessageWithId:(NSString *)msgId error:(id)error data:(id)data;
+ (void)handleMessageWithId:(NSString *)msgId error:(id)error data:(id)data inViewController:(NovaRootViewController *)viewController;
+ (NSString *)transcodingJavaScriptMessage:(NSString *)message;

- (void)callNativeFunction:(NSDictionary *)param;

@end
