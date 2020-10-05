//
//  NovaNavigation.m
//  Nova
//
//  Created by Yubo Qin on 2018/1/31.
//  Copyright © 2018 Yubo Qin. All rights reserved.
//

#import "NovaNavigation.h"

#import <objc/runtime.h>

#import "NovaRootViewController.h"
#import "NovaUtils.h"

@implementation NovaNavigation

+ (instancetype)sharedInstance {
    static id sharedInstance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

- (void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message {
    if (![message.name isEqualToString:@"navigation"]) {
        return;
    }
    NSDictionary *const parameters = message.body;
    NSString *type = [parameters objectForKey:@"type"];
    if (type == nil) {
        type = @"present";
    }
    UIViewController *const topViewController = [NovaUtils topViewController];
    if (!topViewController) {
#if DEBUG
        NSAssert(NO, @"Failed to get top most view controller.");
#endif
        return;
    }
    if ([type isEqualToString:@"show"] || [type isEqualToString:@"present"]) {
        NSString *const class = [parameters objectForKey:@"class"];
        UIViewController *controllerToPush = nil;
        if (class == nil) {
            NovaRootViewController *newRootVC = [[NovaRootViewController alloc] init];
            controllerToPush = newRootVC;
        } else {
            UIViewController *_Nullable const instance = [[NSClassFromString(class) alloc] init];
            if (!instance || ![instance isKindOfClass:[UIViewController class]]) {
#if DEBUG
                NSAssert(NO, @"Failed to initialize view controller for class: %@.", class);
#endif
                return;
            }
            controllerToPush = instance;
        }
        
        NSString *_Nullable const initJS = [parameters objectForKey:@"initJS"];
        if (initJS && [initJS isKindOfClass:[NSString class]] && [controllerToPush isKindOfClass:[NovaRootViewController class]]) {
            [((NovaRootViewController *)controllerToPush).initialJSScripts addObject:initJS];
        }
        
        for (NSString *const key in [parameters allKeys]) {
            if ([key isEqualToString:@"type"] || [key isEqualToString:@"nav"] || [key isEqualToString:@"initJS"]) {
                continue;
            }
            
            // for other keys, dynamically add them to UIViewController instance
            NSString *const selStr = [NSString stringWithFormat:@"set%@:", key.capitalizedString];
            SEL setSel = NSSelectorFromString(selStr);
            if ([controllerToPush respondsToSelector:setSel]) {
                IMP setImp = [controllerToPush methodForSelector:setSel];
                void (*func)(id, SEL, id) = (void *)setImp;
                func(controllerToPush, setSel, [parameters objectForKey:key]);
            }
        }
        
        if (topViewController.navigationController != nil && [type isEqualToString:@"show"]) {
            [topViewController.navigationController showViewController:controllerToPush sender:nil];
        } else {
            if ([parameters objectForKey:@"nav"] == nil || ![parameters[@"nav"] isEqualToString:@"true"]) {
                [topViewController presentViewController:controllerToPush animated:YES completion:nil];
            } else {
                UINavigationController *newNav = [[UINavigationController alloc] initWithRootViewController:controllerToPush];
                [topViewController presentViewController:newNav animated:YES completion:nil];
            }
        }
    } else if ([type isEqualToString:@"pop"]) {
        if (topViewController.navigationController != nil) {
            [topViewController.navigationController popViewControllerAnimated:YES];
        } else {
            [topViewController dismissViewControllerAnimated:YES completion:nil];
        }
    } else if ([type isEqualToString:@"dismiss"]) {
        if (topViewController.navigationController != nil) {
            [topViewController.navigationController dismissViewControllerAnimated:YES completion:nil];
        } else {
            [topViewController dismissViewControllerAnimated:YES completion:nil];
        }
    }
}

@end
