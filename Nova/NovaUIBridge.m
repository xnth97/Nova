//
//  NovaUIBridge.m
//  Nova
//
//  Created by Yubo Qin on 2018/2/1.
//  Copyright © 2018 Yubo Qin. All rights reserved.
//

#import "NovaUIBridge.h"
#import <UIKit/UIKit.h>
#import "NovaNavigation.h"

@implementation NovaUIBridge

+ (instancetype)sharedInstance {
    static id sharedInstance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

- (void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message {
    if (![message.name isEqualToString:@"ui"]) {
        return;
    }
    NSDictionary *parameters = message.body;
    if ([parameters objectForKey:@"alert"] != nil) {
        [self constructAlert:[parameters objectForKey:@"alert"]];
    }
}

- (void)constructAlert:(NSDictionary *)parameters {
    NSString *title = parameters[@"title"];
    NSString *message = parameters[@"message"];
    NSString *actionTitle = parameters[@"action"];
    if (actionTitle == nil) {
        actionTitle = @"OK";
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *action = [UIAlertAction actionWithTitle:actionTitle style:UIAlertActionStyleCancel handler:nil];
        [alert addAction:action];
        [[NovaNavigation topViewController] presentViewController:alert animated:YES completion:nil];
    });
}

@end
