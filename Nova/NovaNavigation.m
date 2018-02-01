//
//  NovaNavigation.m
//  Nova
//
//  Created by Yubo Qin on 2018/1/31.
//  Copyright © 2018 Yubo Qin. All rights reserved.
//

#import "NovaNavigation.h"
#import "NovaRootViewController.h"

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
        NSString *title = [parameters objectForKey:@"title"];
        UIViewController *controllerToPush = nil;
        if (class == nil) {
            NSString *url = [parameters objectForKey:@"url"];
            
            NovaRootViewController *newRootVC = [[NovaRootViewController alloc] init];
            newRootVC.title = title;
            newRootVC.url = url;
            controllerToPush = newRootVC;
        } else {
            id instance = [[NSClassFromString(class) alloc] init];
            controllerToPush = (UIViewController *)instance;
            controllerToPush.title = title;
        }
        
        if ([parameters objectForKey:@"initJS"] != nil && [controllerToPush isKindOfClass:[NovaRootViewController class]]) {
            [((NovaRootViewController *)controllerToPush).initialJSScripts addObject:[parameters objectForKey:@"initJS"]];
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
