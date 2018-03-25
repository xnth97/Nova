//
//  NovaData.m
//  Nova
//
//  Created by Yubo Qin on 2018/3/24.
//  Copyright © 2018 Yubo Qin. All rights reserved.
//

#import "NovaData.h"
#import "NovaNavigation.h"
#import "NovaRootViewController.h"

#define NOVA_KV_STORAGE_KEY @"NOVA_KV_STORAGE"

@interface NovaData ()

@property (strong, nonatomic) NSMutableDictionary<NSString *, NSObject *> *cache;

@end

@implementation NovaData

+ (instancetype)sharedInstance {
    static id shared;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        shared = [[self alloc] init];
        ((NovaData *) shared).cache = [[NSMutableDictionary alloc] init];
    });
    return shared;
}

- (void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message {
    if (![message.name isEqualToString:@"data"]) {
        return;
    }
    
    NSDictionary *parameters = message.body;
    
    NSString *action = parameters[@"action"];
    NSString *key = parameters[@"key"];
    if ([action isEqualToString:@"save"]) {
        NSObject *value = parameters[@"value"];
        [self.cache setObject:value forKey:key];
        [[NSUserDefaults standardUserDefaults] setObject:self.cache forKey:NOVA_KV_STORAGE_KEY];
    } else if ([action isEqualToString:@"load"]) {
        NSObject *value = nil;
        
        if ([self.cache.allKeys containsObject:key]) {
            value = self.cache[key];
        } else {
            self.cache = [[[NSUserDefaults standardUserDefaults] objectForKey:NOVA_KV_STORAGE_KEY] mutableCopy];
            value = self.cache[key];
        }
        
        if (value == nil) {
            value = @"(null)";
        }
        
        NSString *callback = parameters[@"callback"];
        // currently we suppose that our target NovaRootViewController is the top view controller.
        UIViewController *topViewController = [NovaNavigation topViewController];
        if ([topViewController isKindOfClass:[NovaRootViewController class]] == NO) {
            return;
        }
        
        NovaRootViewController *top = (NovaRootViewController *)topViewController;
        
        NSString *js = @"";
        if ([value isKindOfClass:[NSString class]]) {
            NSString *paramString = [self transcodingJavaScriptMessage:(NSString *) value];
            js = [NSString stringWithFormat:@"%@('%@');", callback, paramString];
        } else {
            NSError *error;
            NSData *jsonData = [NSJSONSerialization dataWithJSONObject:value options:0 error:&error];
            NSString *paramString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
            js = [NSString stringWithFormat:@"%@(%@);", callback, paramString];
        }
        [top evaluateJavaScript:js completionHandler:nil];
        
    } else if ([action isEqualToString:@"remove"]) {
        [self.cache removeObjectForKey:key];
        [[NSUserDefaults standardUserDefaults] setObject:self.cache forKey:NOVA_KV_STORAGE_KEY];
    }
}

- (NSString *)transcodingJavaScriptMessage:(NSString *)message {
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
