//
//  NovaBridge.m
//  Nova
//
//  Created by Yubo Qin on 2018/4/25.
//  Copyright © 2018 Yubo Qin. All rights reserved.
//

#import "NovaBridge.h"
#import "NovaNavigation.h"
#import "NovaRootViewController.h"
#import <objc/runtime.h>

@implementation NovaBridge

+ (instancetype)sharedInstance {
    static id sharedInstance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

- (void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message {
    if (![message.name isEqualToString:@"bridge"]) {
        return;
    }
    
    NSDictionary *param = message.body;
    
    NSString *funcName = [param objectForKey:@"func"];
    NSObject *parameters = [param objectForKey:@"param"];
    SEL selector = NSSelectorFromString(funcName);
    NSObject *retVal = nil;
    if ([param objectForKey:@"class"] == nil) {
        // send to self
        if (parameters != nil) {
            SuppressPerformSelectorLeakWarning(
                retVal = [_selfController performSelector:selector withObject:parameters];
            );
        } else {
            SuppressPerformSelectorLeakWarning(retVal = [_selfController performSelector:selector];);
        }
        
    } else {
        NSString *className = [param objectForKey:@"class"];
        Class cls = NSClassFromString(className);
        if (parameters != nil) {
            SuppressPerformSelectorLeakWarning(retVal = [cls performSelector:selector withObject:parameters];);
        } else {
            SuppressPerformSelectorLeakWarning(retVal = [cls performSelector:selector];);
        }
    }
    
    if ([param objectForKey:@"callback"] != nil) {
        NSString *callback = [param objectForKey:@"callback"];
        [[self class] executeCallback:callback withParameter:retVal];
    }
}

+ (void)executeCallback:(NSString *)callback withParameter:(NSObject *)param {
    // currently we suppose that our target NovaRootViewController is the top view controller.
    UIViewController *topViewController = [NovaNavigation topViewController];
    if ([topViewController isKindOfClass:[NovaRootViewController class]] == NO) {
        return;
    }
    
    NovaRootViewController *top = (NovaRootViewController *)topViewController;
    
    NSString *js = @"";
    if ([param isKindOfClass:[NSString class]]) {
        NSString *paramString = [self transcodingJavaScriptMessage:(NSString *) param];
        js = [NSString stringWithFormat:@"%@('%@');", callback, paramString];
    } else {
        NSError *error;
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:param options:0 error:&error];
        NSString *paramString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
        js = [NSString stringWithFormat:@"%@(%@);", callback, paramString];
    }
    if ([[NSThread currentThread] isMainThread]) {
        [top evaluateJavaScript:js completionHandler:nil];
    } else {
        dispatch_sync(dispatch_get_main_queue(), ^{
            [top evaluateJavaScript:js completionHandler:nil];
        });
    }
}

+ (NSString *)transcodingJavaScriptMessage:(NSString *)message {
    message = [message stringByReplacingOccurrencesOfString:@"\\" withString:@"\\\\"];
    message = [message stringByReplacingOccurrencesOfString:@"\"" withString:@"\\\""];
    message = [message stringByReplacingOccurrencesOfString:@"\'" withString:@"\\\'"];
    message = [message stringByReplacingOccurrencesOfString:@"\n" withString:@"\\n"];
    message = [message stringByReplacingOccurrencesOfString:@"\r" withString:@"\\r"];
    message = [message stringByReplacingOccurrencesOfString:@"\f" withString:@"\\f"];
    message = [message stringByReplacingOccurrencesOfString:@"\u2028" withString:@"\\u2028"];
    message = [message stringByReplacingOccurrencesOfString:@"\u2029" withString:@"\\u2029"];
    
    return message;
}

@end
