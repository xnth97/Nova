//
//  NovaBridge.m
//  Nova
//
//  Created by Yubo Qin on 2018/4/25.
//  Copyright © 2018 Yubo Qin. All rights reserved.
//

#import "NovaBridge.h"

#import <objc/runtime.h>

#import "NovaNavigation.h"
#import "NovaRootViewController.h"
#import "NovaUtils.h"

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
    _selfController = nil;
}

- (void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message {
    if (![message.name isEqualToString:@"bridge"]) {
        return;
    }
    
    NSDictionary *param = message.body;
    [self callNativeFunction:param];
}

- (void)callNativeFunction:(nonnull NSDictionary<NSString *, id> *)param {
    NSString *msgId = param[@"id"];
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
        
        if (start >= self.setControllerTime) {
            // Since all containers share this one handler, we should
            // check whether this JS code is executed after the initialization
            // of current container instance. Otherwise we should cancel
            // the JS callback.
            if (retVal == nil) {
                [[self class] handleMessageWithId:msgId error:[NSNull null] data:[NSNull null] inViewController:self.selfController];
            } else {
                [[self class] handleMessageWithId:msgId error:[NSNull null] data:retVal inViewController:self.selfController];
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
    if (param == [NSNull null]) {
        js = [NSString stringWithFormat:@"%@(null);", callback];
    } else if ([param isKindOfClass:[NSString class]]) {
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
        if (param == [NSNull null]) {
            js = [js stringByAppendingString:@"null, "];
        } else if ([param isKindOfClass:[NSString class]]) {
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
    [[self class] executeCallback:callback withParameter:param inViewController:[[self class] getTopNovaVC]];
}

+ (void)executeCallback:(NSString *)callback withParameters:(NSArray<id> *)params {
    // currently we suppose that our target NovaRootViewController is the top view controller.
    [[self class] executeCallback:callback withParameters:params inViewController:[[self class] getTopNovaVC]];
}

+ (void)handleMessageWithId:(NSString *)msgId error:(id)error data:(id)data {
    [[self class] handleMessageWithId:msgId error:error data:data inViewController:[[self class] getTopNovaVC]];
}

+ (void)handleMessageWithId:(NSString *)msgId error:(id)error data:(id)data inViewController:(NovaRootViewController *)viewController {
    if (msgId == nil || ![msgId isKindOfClass:[NSString class]]) {
        // can't handle message without a valid message id
        return;
    }
    [[self class] executeCallback:@"new NovaBridge().handleMessage" withParameters:@[msgId, error, data] inViewController:viewController];
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

+ (nullable NovaRootViewController *)getTopNovaVC {
    UIViewController *const topViewController = [NovaUtils topViewController];
    if (!topViewController || ![topViewController isKindOfClass:[NovaRootViewController class]]) {
        return nil;
    }
    NovaRootViewController *top = (NovaRootViewController *)topViewController;
    return top;
}

@end
