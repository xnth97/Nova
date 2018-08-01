//
//  NovaData.m
//  Nova
//
//  Created by Yubo Qin on 2018/3/24.
//  Copyright © 2018 Yubo Qin. All rights reserved.
//

#import "NovaData.h"
#import "NovaBridge.h"

static NSString * const NOVA_KV_STORAGE_KEY = @"NOVA_KV_STORAGE";

@interface NovaData ()

@property (strong, nonatomic) NSMutableDictionary<NSString *, id> *cache;

@end

@implementation NovaData

+ (instancetype)sharedInstance {
    static id shared;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        shared = [[self alloc] init];
    });
    return shared;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _cache = [[NSMutableDictionary alloc] init];
    }
    return self;
}

- (void)dealloc {
    _selfController = nil;
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
            value = parameters[@"default"];
        }
        
        NSString *callback = parameters[@"callback"];
        [NovaBridge executeCallback:callback withParameter:value inViewController:_selfController];
        
    } else if ([action isEqualToString:@"remove"]) {
        [self.cache removeObjectForKey:key];
        [[NSUserDefaults standardUserDefaults] setObject:self.cache forKey:NOVA_KV_STORAGE_KEY];
    }
}

@end