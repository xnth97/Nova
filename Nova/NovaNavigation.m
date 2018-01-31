//
//  NovaNavigator.m
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
    UIViewController *topViewController = [self topViewController];
    if ([type isEqualToString:@"show"] || [type isEqualToString:@"present"]) {
        NSString *url = [parameters objectForKey:@"url"];
        NSString *title = [parameters objectForKey:@"title"];
        
        NovaRootViewController *newRootVC = [[NovaRootViewController alloc] init];
        newRootVC.title = title;
        newRootVC.url = url;
        if (topViewController.navigationController != nil && [type isEqualToString:@"show"]) {
            [topViewController.navigationController showViewController:newRootVC sender:nil];
        } else {
            [topViewController presentViewController:newRootVC animated:YES completion:nil];
        }
    } else if ([type isEqualToString:@"pop"]) {
        if (topViewController.navigationController != nil) {
            [topViewController.navigationController popViewControllerAnimated:YES];
        }
    } else if ([type isEqualToString:@"dismiss"]) {
        [topViewController dismissViewControllerAnimated:YES completion:nil];
    }
}

- (UIViewController *)topViewController {
    UIViewController *resultVC;
    resultVC = [self _topViewController:[[UIApplication sharedApplication].keyWindow rootViewController]];
    while (resultVC.presentedViewController) {
        resultVC = [self _topViewController:resultVC.presentedViewController];
    }
    return resultVC;
}

- (UIViewController *)_topViewController:(UIViewController *)vc {
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
