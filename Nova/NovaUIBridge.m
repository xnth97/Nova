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
#import "NovaRootViewController.h"
#import "NovaBlockHolder.h"
#import <objc/runtime.h>

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
        [self constructAlert:[parameters objectForKey:@"alert"] style:UIAlertControllerStyleAlert];
    }
    if ([parameters objectForKey:@"actionSheet"] != nil) {
        [self constructAlert:[parameters objectForKey:@"actionSheet"] style:UIAlertControllerStyleActionSheet];
    }
    if ([parameters objectForKey:@"orientation"] != nil) {
        [self constructOrientation:parameters[@"orientation"]];
    }
    if ([parameters objectForKey:@"leftBarButton"] != nil) {
        [self constructBarButton:parameters[@"leftBarButton"] direction:0];
    }
    if ([parameters objectForKey:@"rightBarButton"] != nil) {
        [self constructBarButton:parameters[@"rightBarButton"] direction:1];
    }
}

- (void)constructAlert:(NSDictionary *)parameters style:(UIAlertControllerStyle)style {
    NSString *title = parameters[@"title"];
    NSString *message = parameters[@"message"];
    NSArray *actions = parameters[@"actions"];
    dispatch_async(dispatch_get_main_queue(), ^{
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:style];
        UIViewController *top = [NovaNavigation topViewController];
        for (NSDictionary *actionParam in actions) {
            UIAlertActionStyle s = UIAlertActionStyleDefault;
            if ([actionParam objectForKey:@"style"] != nil) {
                NSString *actionStyle = actionParam[@"style"];
                if ([actionStyle isEqualToString:@"destructive"]) {
                    s = UIAlertActionStyleDestructive;
                } else if ([actionStyle isEqualToString:@"cancel"]) {
                    s = UIAlertActionStyleCancel;
                }
            }
            UIAlertAction *action = [UIAlertAction actionWithTitle:actionParam[@"title"] style:s handler:^(UIAlertAction *_action) {
                if ([actionParam objectForKey:@"callback"] != nil) {
                    if ([top isKindOfClass:[NovaRootViewController class]]) {
                        [((NovaRootViewController *)top) evaluateJavaScript:[actionParam objectForKey:@"callback"] completionHandler:nil];
                    }
                }
            }];
            [alert addAction:action];
        }
        [[NovaNavigation topViewController] presentViewController:alert animated:YES completion:nil];
    });
}

- (void)constructOrientation:(NSString *)orientation {
    if ([[UIDevice currentDevice] respondsToSelector:@selector(setOrientation:)]) {
        SEL selector = NSSelectorFromString(@"setOrientation:");
        NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:[UIDevice instanceMethodSignatureForSelector:selector]];
        [invocation setSelector:selector];
        [invocation setTarget:[UIDevice currentDevice]];
        int val = UIDeviceOrientationPortrait;
        if ([orientation isEqualToString:@"landscapeLeft"]) {
            val = UIDeviceOrientationLandscapeLeft;
        } else if ([orientation isEqualToString:@"landscapeRight"]) {
            val = UIDeviceOrientationLandscapeRight;
        }
        [invocation setArgument:&val atIndex:2];
        [invocation invoke];
    }
}

- (void)constructBarButton:(NSDictionary *)parameters direction:(NSUInteger)direction {
    NSString *title = parameters[@"title"];
    NSString *callback = parameters[@"callback"];
    NSString *style = parameters[@"style"];
    NovaBlockHolder *blockHolder = [NovaBlockHolder blockHolderWithBlock:^() {
        [(NovaRootViewController *)[NovaNavigation topViewController] evaluateJavaScript:callback completionHandler:nil];
    }];
    dispatch_async(dispatch_get_main_queue(), ^() {
        UIBarButtonItem *barButtonItem;
        if (title == nil && style != nil) {
            NSDictionary<NSString *, NSNumber *> *styleDict = @{@"add": @(UIBarButtonSystemItemAdd),
                                                                @"done": @(UIBarButtonSystemItemDone),
                                                                @"cancel": @(UIBarButtonSystemItemCancel),
                                                                @"edit": @(UIBarButtonSystemItemEdit),
                                                                @"save": @(UIBarButtonSystemItemSave),
                                                                @"camera": @(UIBarButtonSystemItemCamera),
                                                                @"trash": @(UIBarButtonSystemItemTrash),
                                                                @"reply": @(UIBarButtonSystemItemReply),
                                                                @"action": @(UIBarButtonSystemItemAction),
                                                                @"organize": @(UIBarButtonSystemItemOrganize),
                                                                @"compose": @(UIBarButtonSystemItemCompose),
                                                                @"refresh": @(UIBarButtonSystemItemRefresh),
                                                                @"bookmarks": @(UIBarButtonSystemItemBookmarks),
                                                                @"search": @(UIBarButtonSystemItemSearch),
                                                                @"stop": @(UIBarButtonSystemItemStop),
                                                                @"play": @(UIBarButtonSystemItemPlay),
                                                                @"pause": @(UIBarButtonSystemItemPause),
                                                                @"redo": @(UIBarButtonSystemItemRedo),
                                                                @"undo": @(UIBarButtonSystemItemUndo),
                                                                @"rewind": @(UIBarButtonSystemItemRewind),
                                                                @"fastforward": @(UIBarButtonSystemItemFastForward)
                                                                };
            barButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:styleDict[style].integerValue target:blockHolder action:@selector(invoke)];
        } else if (title != nil) {
            barButtonItem = [[UIBarButtonItem alloc] initWithTitle:title style:UIBarButtonItemStylePlain target:blockHolder action:@selector(invoke)];
        }
        if (direction == 0) {
            [[NovaNavigation topViewController].navigationItem setLeftBarButtonItem:barButtonItem];
        } else {
            [[NovaNavigation topViewController].navigationItem setRightBarButtonItem:barButtonItem];
        }
        // Note that the blockHolder instance won't be retained, therefore we use
        // ObjC's setAssociatedObject to tie the lifetime of blockHolder to the lifetime
        // of the control.
        objc_setAssociatedObject(barButtonItem, @"__block_holder__", blockHolder, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    });
}

@end
