//
//  NovaRootViewController.h
//  Nova
//
//  Created by Yubo Qin on 2018/1/31.
//  Copyright © 2018 Yubo Qin. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol NovaRootViewControllerDelegate

@optional
- (void)didFinishNavigation;

@end

@interface NovaRootViewController : UIViewController

@property (strong, nonatomic, nonnull) NSString *url;
@property (strong, nonatomic, nullable) NSMutableArray<NSString *> *initialJSScripts;
@property (weak, nonatomic, nullable) id<NovaRootViewControllerDelegate> delegate;

- (void)evaluateJavaScript:(NSString *_Nonnull)javascript completionHandler:(void(^ _Nullable) (_Nullable id, NSError * _Nullable error))completionHandler;

@end
