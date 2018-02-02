//
//  NovaNavigation.m
//  Nova
//
//  Created by Yubo Qin on 2018/1/31.
//  Copyright © 2018 Yubo Qin. All rights reserved.
//

#import "NovaNavigation.h"
#import "NovaRootViewController.h"
#import <objc/runtime.h>

#define SuppressPerformSelectorLeakWarning(Stuff) \
do { \
_Pragma("clang diagnostic push") \
_Pragma("clang diagnostic ignored \"-Warc-performSelector-leaks\"") \
Stuff; \
_Pragma("clang diagnostic pop") \
} while (0)

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
    NSDictionary *parameters = message.body;
    NSString *type = [parameters objectForKey:@"type"];
    if (type == nil) {
        type = @"present";
    }
    UIViewController *topViewController = [NovaNavigation topViewController];
    if ([type isEqualToString:@"show"] || [type isEqualToString:@"present"]) {
        NSString *class = [parameters objectForKey:@"class"];
        UIViewController *controllerToPush = nil;
        if (class == nil) {
            NovaRootViewController *newRootVC = [[NovaRootViewController alloc] init];
            controllerToPush = newRootVC;
        } else {
            id instance = [[NSClassFromString(class) alloc] init];
            controllerToPush = (UIViewController *)instance;
        }
        
        if ([parameters objectForKey:@"initJS"] != nil && [controllerToPush isKindOfClass:[NovaRootViewController class]]) {
            [((NovaRootViewController *)controllerToPush).initialJSScripts addObject:[parameters objectForKey:@"initJS"]];
        }
        
        for (NSString *key in [parameters allKeys]) {
            if ([key isEqualToString:@"type"] || [key isEqualToString:@"nav"] || [key isEqualToString:@"initJS"]) {
                continue;
            }
            
            // for other keys, dynamically add them to UIViewController instance
            NSString *selStr = [NSString stringWithFormat:@"set%@:", key.capitalizedString];
            SEL setSel = NSSelectorFromString(selStr);
            if ([controllerToPush respondsToSelector:setSel]) {
                SuppressPerformSelectorLeakWarning(
                    [controllerToPush performSelector:setSel withObject:[parameters objectForKey:key]];
                );
            }
        }
        
        if (topViewController.navigationController != nil && [type isEqualToString:@"show"]) {
            [topViewController.navigationController showViewController:controllerToPush sender:nil];
        } else {
            if ([parameters objectForKey:@"nav"] == nil) {
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

+ (UIViewController *)topViewController {
    UIViewController *resultVC;
    resultVC = [self _topViewController:[[UIApplication sharedApplication].keyWindow rootViewController]];
    while (resultVC.presentedViewController) {
        resultVC = [self _topViewController:resultVC.presentedViewController];
    }
    return resultVC;
}

+ (UIViewController *)_topViewController:(UIViewController *)vc {
    if ([vc isKindOfClass:[UINavigationController class]]) {
        return [self _topViewController:[(UINavigationController *)vc topViewController]];
    } else if ([vc isKindOfClass:[UITabBarController class]]) {
        return [self _topViewController:[(UITabBarController *)vc selectedViewController]];
    } else {
        return vc;
    }
    return nil;
}

@end
