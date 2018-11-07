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

@interface NovaBridge ()

@property (nonatomic) NSTimeInterval setControllerTime;
@property (nonatomic) dispatch_queue_t novaBridgeQueue;

@end

@implementation NovaBridge

+ (instancetype)sharedInstance {
    static id sharedInstance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _novaBridgeQueue = dispatch_queue_create("nova_bridge_queue", DISPATCH_QUEUE_CONCURRENT);
    }
    return self;
}

- (void)setSelfController:(NovaRootViewController *)selfController {
    _selfController = selfController;
    _setControllerTime = [[NSDate date] timeIntervalSince1970];
}

- (void)dealloc {
    self.selfController = nil;
}

- (void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message {
    if (![message.name isEqualToString:@"bridge"]) {
        return;
    }
    
    NSDictionary *param = message.body;
    [self callNativeFunction:param];
}

- (void)callNativeFunction:(NSDictionary *)param {
    NSString *funcName = [param objectForKey:@"func"];
    id parameters = [param objectForKey:@"param"];
    SEL selector = NSSelectorFromString(funcName);
    
    dispatch_async(self.novaBridgeQueue, ^{
        NSTimeInterval start = [[NSDate date] timeIntervalSince1970];
        
        id retVal = nil;
        if ([param objectForKey:@"class"] == nil) {
            // send to self
            if (![self.selfController respondsToSelector:selector]) {
                return;
            }
            
            IMP imp = [self.selfController methodForSelector:selector];
            if (parameters != nil) {
                id (*func)(id, SEL, id) = (void *)imp;
                retVal = func(self.selfController, selector, parameters);
            } else {
                id (*func)(id, SEL) = (void *)imp;
                retVal = func(self.selfController, selector);
            }
        } else {
            NSString *className = [param objectForKey:@"class"];
            Class cls = NSClassFromString(className);
            if (cls == nil) {
                return;
            }
            if (![cls respondsToSelector:selector]) {
                return;
            }
            
            IMP imp = [cls methodForSelector:selector];
            if (parameters != nil) {
                id (*func)(id, SEL, id) = (void *)imp;
                retVal = func(cls, selector, parameters);
            } else {
                id (*func)(id, SEL) = (void *)imp;
                retVal = func(cls, selector);
            }
        }
        
        if ([param objectForKey:@"callback"] != nil) {
            if (start >= self.setControllerTime) {
                // Since all containers share this one handler, we should
                // check whether this JS code is executed after the initialization
                // of current container instance. Otherwise we should cancel
                // the JS callback.
                NSString *callback = [param objectForKey:@"callback"];
                if (retVal == nil) {
                    [[self class] executeCallback:callback inViewController:self.selfController];
                } else {
                    [[self class] executeCallback:callback withParameter:retVal inViewController:self.selfController];
                }
            }
        }
    });
}

+ (void)executeCallback:(NSString *)callback inViewController:(NovaRootViewController *)viewController {
    NSString *js = [NSString stringWithFormat:@"%@();", callback];
    [viewController evaluateJavaScript:js completionHandler:nil];
}

+ (void)executeCallback:(NSString *)callback withParameter:(id)param inViewController:(NovaRootViewController *)viewController {
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
    [viewController evaluateJavaScript:js completionHandler:nil];
}

+ (void)executeCallback:(NSString *)callback withParameters:(NSArray<id> *)parameters inViewController:(NovaRootViewController *)viewController {
    NSString *js = [NSString stringWithFormat:@"%@(", callback];
    for (id param in parameters) {
        if ([param isKindOfClass:[NSString class]]) {
            NSString *paramString = [self transcodingJavaScriptMessage:(NSString *)param];
            js = [js stringByAppendingString:[NSString stringWithFormat:@"'%@', ", paramString]];
        } else {
            NSError *error;
            NSData *jsonData = [NSJSONSerialization dataWithJSONObject:param options:0 error:&error];
            NSString *paramString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
            js = [js stringByAppendingString:[NSString stringWithFormat:@"%@, ", paramString]];
        }
    }
    js = [[js substringToIndex:js.length - 2] stringByAppendingString:@");"];
    [viewController evaluateJavaScript:js completionHandler:nil];
}

+ (void)executeCallback:(NSString *)callback withParameter:(id)param {
    // currently we suppose that our target NovaRootViewController is the top view controller.
    UIViewController *topViewController = [NovaNavigation topViewController];
    if ([topViewController isKindOfClass:[NovaRootViewController class]] == NO) {
        return;
    }
    NovaRootViewController *top = (NovaRootViewController *)topViewController;
    [[self class] executeCallback:callback withParameter:param inViewController:top];
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
