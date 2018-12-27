//
//  NovaData.m
//  Nova
//
//  Created by Yubo Qin on 2018/3/24.
//  Copyright © 2018 Yubo Qin. All rights reserved.
//

#import "NovaData.h"
#import "NovaBridge.h"
#import "NovaPersistentMap.h"

@interface NovaData ()

@property (strong, nonatomic) NovaPersistentMap<NSString *, id> *persistentMap;

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
        _persistentMap = [NovaPersistentMap defaultMap];
    }
    return self;
}

- (void)dealloc {
    self.selfController = nil;
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
        [self.persistentMap setObject:value forKey:key];
    } else if ([action isEqualToString:@"load"]) {
        id value = self.persistentMap[key];
        
        if (value == nil) {
            value = parameters[@"default"];
        }
        
        NSString *callback = parameters[@"callback"];
        [NovaBridge executeCallback:callback withParameter:value inViewController:_selfController];
        
    } else if ([action isEqualToString:@"remove"]) {
        [self.persistentMap removeObjectForKey:key];
    }
}

@end
