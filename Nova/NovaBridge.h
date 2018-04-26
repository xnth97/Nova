//
//  NovaBridge.h
//  Nova
//
//  Created by Yubo Qin on 2018/4/25.
//  Copyright © 2018 Yubo Qin. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <WebKit/WebKit.h>
#import "NovaRootViewController.h"

#define SuppressPerformSelectorLeakWarning(Stuff) \
do { \
_Pragma("clang diagnostic push") \
_Pragma("clang diagnostic ignored \"-Warc-performSelector-leaks\"") \
Stuff; \
_Pragma("clang diagnostic pop") \
} while (0)

@interface NovaBridge : NSObject <WKScriptMessageHandler>

@property (weak, nonatomic) NovaRootViewController *selfController;

+ (instancetype)sharedInstance;

+ (void)executeCallback:(NSString *)callback withParameter:(NSObject *)param;
+ (void)executeCallback:(NSString *)callback withParameter:(NSObject *)param inViewController:(NovaRootViewController *)viewController;
+ (NSString *)transcodingJavaScriptMessage:(NSString *)message;

@end
