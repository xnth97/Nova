//
//  NovaUI.m
//  Nova
//
//  Created by Yubo Qin on 2018/2/1.
//  Copyright © 2018 Yubo Qin. All rights reserved.
//

#import "NovaUI.h"

#import <UIKit/UIKit.h>
#import <objc/runtime.h>

#import "NovaBlockHolder.h"
#import "NovaBridge.h"
#import "NovaNavigation.h"
#import "NovaRootViewController.h"
#import "NovaUtils.h"

@implementation NovaUI

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
    if ([parameters objectForKey:@"leftBarButtons"] != nil) {
        [self constructBarButtons:parameters[@"leftBarButtons"] direction:0];
    } else if ([parameters objectForKey:@"leftBarButton"] != nil) {
        [self constructBarButton:parameters[@"leftBarButton"] direction:0];
    }
    if ([parameters objectForKey:@"rightBarButtons"] != nil) {
        [self constructBarButtons:parameters[@"rightBarButtons"] direction:1];
    } else if ([parameters objectForKey:@"rightBarButton"] != nil) {
        [self constructBarButton:parameters[@"rightBarButton"] direction:1];
    }
    if ([parameters objectForKey:@"activity"] != nil) {
        [self constructActivity:parameters[@"activity"]];
    }
}

- (void)constructAlert:(NSDictionary *)parameters style:(UIAlertControllerStyle)style {
    NSString *title = parameters[@"title"];
    NSString *message = parameters[@"message"];
    NSArray *actions = parameters[@"actions"];
    dispatch_async(dispatch_get_main_queue(), ^{
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:style];
        UIViewController *top = [NovaUtils topViewController];
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
                if ([actionParam objectForKey:@"bridge"] != nil) {
                    [[NovaBridge sharedInstance] callNativeFunction:actionParam[@"bridge"]];
                } else if ([actionParam objectForKey:@"callback"] != nil) {
                    if ([top isKindOfClass:[NovaRootViewController class]]) {
                        [((NovaRootViewController *)top) evaluateJavaScript:[actionParam objectForKey:@"callback"] completionHandler:nil];
                    }
                }
            }];
            [alert addAction:action];
        }
        [[NovaUtils topViewController] presentViewController:alert animated:YES completion:nil];
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

- (void)constructBarButtons:(NSArray<NSDictionary *> *)paramArray direction:(NSUInteger)direction {
    dispatch_async(dispatch_get_main_queue(), ^{
        NSMutableArray<UIBarButtonItem *> *barItems = [[NSMutableArray alloc] init];
        for (NSDictionary *parameters in paramArray) {
            [barItems addObject:[self buildBarButtonItem:parameters]];
        }
        if (direction == 0) {
            [[NovaUtils topViewController].navigationItem setLeftBarButtonItems:barItems];
        } else {
            [[NovaUtils topViewController].navigationItem setRightBarButtonItems:barItems];
        }
    });
}

- (void)constructBarButton:(NSDictionary *)parameters direction:(NSUInteger)direction {
    dispatch_async(dispatch_get_main_queue(), ^() {
        UIBarButtonItem *barButtonItem = [self buildBarButtonItem:parameters];
        if (direction == 0) {
            [[NovaUtils topViewController].navigationItem setLeftBarButtonItem:barButtonItem];
        } else {
            [[NovaUtils topViewController].navigationItem setRightBarButtonItem:barButtonItem];
        }
    });
}

- (UIBarButtonItem *)buildBarButtonItem:(NSDictionary *)parameters {
    NSString *title = parameters[@"title"];
    NSString *style = parameters[@"style"];
    NovaBlockHolder *blockHolder;
    if ([parameters objectForKey:@"bridge"] != nil) {
        blockHolder = [NovaBlockHolder blockHolderWithBlock:^() {
            [[NovaBridge sharedInstance] callNativeFunction:parameters[@"bridge"]];
        }];
    } else if ([parameters objectForKey:@"callback"] != nil) {
        blockHolder = [NovaBlockHolder blockHolderWithBlock:^() {
            [(NovaRootViewController *)[NovaUtils topViewController] evaluateJavaScript:parameters[@"callback"] completionHandler:nil];
        }];
    }
    
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
    
    // Note that the blockHolder instance won't be retained, therefore we use
    // ObjC's setAssociatedObject to tie the lifetime of blockHolder to the lifetime
    // of the control.
    objc_setAssociatedObject(barButtonItem, @"__block_holder__", blockHolder, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    
    return barButtonItem;
}

- (void)constructActivity:(NSDictionary *)parameters {
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        NSString *text = [parameters objectForKey:@"text"];
        NSURL *url = nil;
        if ([parameters objectForKey:@"url"] != nil) {
            url = [NSURL URLWithString:parameters[@"url"]];
        }
        UIImage *image = nil;
        if ([parameters objectForKey:@"image"] != nil) {
            NSData *imgData = [NSData dataWithContentsOfURL:[NSURL URLWithString:parameters[@"image"]]];
            image = [[UIImage alloc] initWithData:imgData];
        }
        
        NSMutableArray *activityItems = [[NSMutableArray alloc] init];
        if (text != nil) {
            [activityItems addObject:text];
        }
        if (url != nil) {
            [activityItems addObject:url];
        }
        if (image != nil) {
            [activityItems addObject:image];
        }
        
        dispatch_async(dispatch_get_main_queue(), ^() {
            UIActivityViewController *activityVC = [[UIActivityViewController alloc] initWithActivityItems:activityItems applicationActivities:nil];
            [[NovaUtils topViewController] presentViewController:activityVC animated:YES completion:nil];
        });
    });
}

@end
