//
//  NovaNavigation.h
//  Nova
//
//  Navigation message handler of Nova. Handles 'navigation' messages.
//
//  Created by Yubo Qin on 2018/1/31.
//  Copyright © 2018 Yubo Qin. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <WebKit/WebKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface NovaNavigation : NSObject <WKScriptMessageHandler>

+ (instancetype)sharedInstance;

@end

NS_ASSUME_NONNULL_END
