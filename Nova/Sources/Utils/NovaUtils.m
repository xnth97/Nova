//
//  NovaUtils.m
//  Nova
//
//  Created by Yubo Qin on 10/4/20.
//

#import "NovaUtils.h"

@implementation NovaUtils

+ (nonnull NSBundle *)resourceBundle {
    NSBundle *const bundle = [NSBundle bundleForClass:self.classForCoder];
    NSURL *const bundleURL = [[bundle resourceURL] URLByAppendingPathComponent:@"Nova.bundle"];
    NSBundle *const resourceBundle = [NSBundle bundleWithURL:bundleURL];
    return resourceBundle;
}

+ (nullable UIViewController *)topViewController {
    UIViewController *resultVC;
    resultVC = [self _topViewController:[[UIApplication sharedApplication].keyWindow rootViewController]];
    while (resultVC.presentedViewController) {
        resultVC = [self _topViewController:resultVC.presentedViewController];
    }
    return resultVC;
}

+ (nullable UIViewController *)_topViewController:(UIViewController *)vc {
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
